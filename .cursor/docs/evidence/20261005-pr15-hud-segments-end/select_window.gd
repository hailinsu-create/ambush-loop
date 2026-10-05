extends SceneTree
const Guard = preload("res://scripts/test_storage_guard.gd")
const View = preload("res://scripts/presentation/view_state.gd")
const FIELDS = ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]
class Host extends Node:
	enum Phase { REPLAY = 4 }
	var phase = 4
	var replay: ReplayPlayer
func _init() -> void:
	if not Guard.check(): quit(91); return
	call_deferred("_run")
func _run() -> void:
	var path: String = OS.get_environment("HUD_RECORD")
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	assert(FileAccess.get_sha256(path)=="e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5")
	var raw: Dictionary = bytes_to_var(bytes)
	var log := BattleLog.new()
	for key: String in FIELDS: log.set(key,raw[key])
	var host := Host.new()
	host.replay = ReplayPlayer.new();host.replay.bind(log)
	assert(host.replay.continuous_playback)
	var tick: int = int(round(log.playback_terminal_tick*0.5))
	assert(log.playback_terminal_tick-tick>=40*60)
	host.replay.set_tick(tick)
	var snap: Dictionary = host.replay.snapshot_at_or_before(tick)
	var frame: Dictionary = View.capture(host)
	var scan: Array = []
	for record: Dictionary in log.playback_snapshots:
		if record.playback_tick>=tick and record.playback_tick<=tick+40*60:
			scan.append({"pb":record.playback_tick,"seq":record.frame_seq,"wave":record.wave_id,"phase":record.data.phase})
	var sig: Dictionary = {"attempt":log.attempt_id,"tick":tick,"frame_seq":snap.frame_seq,"wave_id":snap.wave_id,"recorded_phase":snap.data.phase,"events":host.replay.events_up_to(tick),"actors":[],"remaining_record_s":float(log.playback_terminal_tick-tick)/60,"window_frames":scan,"schema":log.playback_schema,"terminal":log.playback_terminal_tick,"scope":"readonly source selection, no renderer/performance claim"}
	for group: String in ["ops","enemies","sentries"]:
		for actor: Dictionary in frame[group]: sig.actors.append({"group":group,"id":actor.id,"weapon":actor.weapon,"saved_pose":actor.get("pose",{})})
	assert(var_to_bytes(raw)==bytes)
	var output := FileAccess.open(OS.get_environment("HUD_SELECTION_OUTPUT"),FileAccess.WRITE)
	output.store_string(JSON.stringify(sig,"\t")+"\n");output.close();host.free()
	print("HUD_SELECTION_GUARD_OK tick=",tick," remaining=",sig.remaining_record_s," frame=",sig.frame_seq," phase=",sig.recorded_phase)
	quit(0)
