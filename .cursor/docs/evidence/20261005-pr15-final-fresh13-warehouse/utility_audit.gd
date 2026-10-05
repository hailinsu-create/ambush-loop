extends SceneTree
const Guard = preload("res://scripts/test_storage_guard.gd")
const View = preload("res://scripts/presentation/view_state.gd")
const Pose = preload("res://scripts/presentation/actor_pose.gd")
const Utility = preload("res://scripts/presentation/utility_pose.gd")
class Host extends Node:
	enum Phase { REPLAY = 4 }
	var phase = 4
	var replay: ReplayPlayer
var failures: Array = []
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _init() -> void:
	if not Guard.check(): quit(91); return
	call_deferred("_run")
func _run() -> void:
	var path := OS.get_environment("FINAL_AUDIT_RECORD")
	var before := FileAccess.get_file_as_bytes(path)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("FINAL_AUDIT_META")))
	check(FileAccess.get_sha256(path) == str(meta.record.sha256), "original SHA")
	var raw: Dictionary = bytes_to_var(before)
	var history := BattleLog.new()
	for field in raw: history.set(field, raw[field])
	var host := Host.new()
	host.replay = ReplayPlayer.new()
	host.replay.bind(history)
	var throws: Dictionary = {}
	for rec: Dictionary in history.playback_snapshots:
		for actor: Dictionary in rec.data.get("ops", []):
			var utility: Dictionary = actor.get("utility_pose", {})
			if utility.get("action", "") != "grenade_throw": continue
			host.replay.set_tick(rec.playback_tick)
			var frame: Dictionary = View.capture(host)
			var id := str(utility.event_id)
			if not throws.has(id): throws[id] = {"original_state": utility, "first_playback": rec.playback_tick, "last_playback": rec.playback_tick, "saved_frames": 0, "selected_pose_samples": []}
			throws[id].last_playback = rec.playback_tick
			throws[id].saved_frames += 1
			check(utility.attempt_id == history.attempt_id and utility.actor_id == actor.id and utility.wave_id == rec.wave_id, "saved actual utility identity")
			for selected: Dictionary in frame.ops:
				if selected.id != actor.id: continue
				check(Utility.valid(utility, selected, frame), "actual saved utility admission")
				var pose: Dictionary = Pose.sample(selected, frame, "ops")
				check(pose.get("action", "") == "grenade_throw" and pose.get("event_id", "") == id and pose.get("utility", false), "actual selected throw clip identity")
				throws[id].selected_pose_samples.append({"playback_tick":rec.playback_tick,"actor_id":selected.id,"weapon":selected.weapon,"pose":pose})
	check(not throws.is_empty(), "natural saved throw exists")
	check(FileAccess.get_file_as_bytes(path) == before and var_to_bytes(raw) == before, "original immutable bytes")
	var result := {"scope":"original saved utility identity and pure pose selection; no BattleLog throw fabrication, renderer/whole UNRUN", "checks":checks,"failures":failures,"attempt":history.attempt_id,"throws":throws}
	var f := FileAccess.open(OS.get_environment("FINAL_AUDIT_OUTPUT"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"\t"));f.close()
	host.free()
	print("UTILITY_ORIGINAL_AUDIT ", checks, "/", failures.size())
	quit(0 if failures.is_empty() else 1)
