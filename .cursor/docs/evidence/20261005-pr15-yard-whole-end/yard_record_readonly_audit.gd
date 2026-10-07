extends SceneTree
const Guard = preload("res://scripts/test_storage_guard.gd")
const View = preload("res://scripts/presentation/view_state.gd")
const Pose = preload("res://scripts/presentation/actor_pose.gd")
const RECORD_FIELDS = ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]
class Host extends Node:
	enum Phase { REPLAY = 4 }
	var phase = 4
	var replay: ReplayPlayer
var checks := 0
var failures: Array = []
func _init() -> void:
	if not Guard.check(): quit(91); return
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
func _source(history: BattleLog) -> Dictionary:
	var out: Dictionary = {}
	for field in RECORD_FIELDS: out[field] = history.get(field)
	return out
func _run() -> void:
	var path := OS.get_environment("YARD_AUDIT_RECORD")
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("YARD_AUDIT_META")))
	var expected: String = meta.record.sha256
	check(FileAccess.get_sha256(path) == expected, "original archived SHA")
	var bytes := FileAccess.get_file_as_bytes(path)
	var raw: Dictionary = bytes_to_var(bytes)
	check(bytes.size() == int(meta.record.bytes) and raw.size() == RECORD_FIELDS.size(), "original eight fields and bytes")
	var history := BattleLog.new()
	for field in RECORD_FIELDS: history.set(field, raw[field])
	check(var_to_bytes(_source(history)) == bytes, "load preserves exact original serialization")
	check(history.attempt_id == str(meta.record.attempt) and history.playback_schema == 2, "source identity/schema")
	check(history.playback_terminal_tick == int(meta.record.terminal) and history.terminal_reason == "win", "original terminal")
	check(history.events.size() == int(meta.record.validation.events) and history.playback_snapshots.size() == int(meta.record.validation.frames), "original counts")
	var host := Host.new()
	host.replay = ReplayPlayer.new()
	host.replay.bind(history)
	check(host.replay.continuous_playback and not host.replay.playback_unsupported and not host.replay.legacy_ambiguous, "supported continuous stream")
	var last_event_tick := -1
	var event_waves: Dictionary = {}
	var event_types: Dictionary = {}
	var loot_events: Array = []
	var fire_actor_counts: Dictionary = {}
	for i in history.events.size():
		var ev: Dictionary = history.events[i]
		check(ev.attempt_id == history.attempt_id and ev.seq == i and ev.event_id == "%s:%d:%d" % [history.attempt_id,ev.wave_id,i], "event identity " + str(i))
		check(ev.wave_id in [0,1] and BattleLog.record_tick(ev) >= last_event_tick, "event chronology " + str(i))
		last_event_tick = BattleLog.record_tick(ev)
		event_waves[str(ev.wave_id)] = int(event_waves.get(str(ev.wave_id),0)) + 1
		event_types[str(ev.type)] = int(event_types.get(str(ev.type),0)) + 1
		if ev.type == "loot": loot_events.append({"seq":ev.seq,"wave_id":ev.wave_id,"payload":ev.payload})
		if ev.type == "fire": fire_actor_counts[str(ev.actor_id)] = int(fire_actor_counts.get(str(ev.actor_id),0)) + 1
	var latest := -1
	var local_previous := -1
	var local_regressions := 0
	var wave_phases: Dictionary = {}
	for i in history.playback_snapshots.size():
		var rec: Dictionary = history.playback_snapshots[i]
		check(rec.attempt_id == history.attempt_id and rec.frame_seq == i and rec.playback_schema == 2, "frame identity " + str(i))
		check(rec.playback_tick >= latest and rec.wave_id in [0,1], "global chronology " + str(i))
		latest = rec.playback_tick
		if rec.tick < local_previous: local_regressions += 1
		local_previous = rec.tick
		check(rec.data.level_id == "yard" and rec.data.wave_count == 2 and rec.data.phase in [0,1,3,5], "authored level/phase " + str(i))
		check(Pose.supported(rec.data), "saved supported actor envelope " + str(i))
		var key := "%d:%d" % [rec.wave_id,rec.data.phase]
		wave_phases[key] = int(wave_phases.get(key,0)) + 1
		# Offline pure artifact selection only, separate from actual whole playback.
		host.replay.set_tick(rec.playback_tick)
		var snap: Dictionary = host.replay.snapshot_at_or_before(rec.playback_tick)
		var frame: Dictionary = View.capture(host)
		check(frame.attempt_id == history.attempt_id and frame.level_id == "yard" and frame.wave_id == snap.wave_id and frame.frame_seq == snap.frame_seq, "selected saved identity " + str(i))
		check(frame.playback_tick == rec.playback_tick and frame.recorded_phase == snap.data.phase, "selected clock/phase " + str(i))
		var expected_events: Array = history.events.filter(func(ev: Dictionary) -> bool: return host.replay.playback_time(ev) <= rec.playback_tick)
		check(frame.events == expected_events, "event cutoff " + str(i))
		check(frame.is_read_only() and frame.ops.is_read_only(), "immutable frame " + str(i))
		for group: String in ["ops","enemies","sentries"]:
			check(frame[group].size() == snap.data.get(group,[]).size(), "saved actor count " + group + str(i))
			for j in frame[group].size():
				var actor: Dictionary = frame[group][j]
				var source: Dictionary = snap.data[group][j]
				check(actor.id == source.id and actor.pos == source.pos and actor.weapon == str(source.get("weapon","")) and actor.facing == source.facing and actor.alive == source.alive, "saved actor values " + group + str(i) + ":" + str(j))
	check(local_regressions == 1, "actual local tick reset exists while global monotonic")
	check(wave_phases.has("0:0") and wave_phases.has("0:1") and wave_phases.has("0:5") and wave_phases.has("1:1") and wave_phases.has("1:5") and wave_phases.has("1:3"), "actual two-wave command battle sweep terminal phases")
	check(event_waves.has("0") and event_waves.has("1"), "all two original event waves")
	check(var_to_bytes(_source(history)) == bytes and FileAccess.get_sha256(path) == expected, "all offline selections preserve source original bytes")
	var result := {"checks":checks,"failures":failures,"source":"1ec3198e9c0db367af96fc264604c5a286003b5e","record_sha256":expected,"frames":history.playback_snapshots.size(),"events":history.events.size(),"terminal":history.playback_terminal_tick,"wave_phase_counts":wave_phases,"event_wave_counts":event_waves,"event_type_counts":event_types,"original_loot_events":loot_events,"fire_actor_counts":fire_actor_counts,"local_tick_regressions":local_regressions,"scope":"non-destructive original archived binary and pure reader/ViewState contract audit; offline selections are not whole playback or actual 3D renderer checks"}
	var output := FileAccess.open(OS.get_environment("YARD_AUDIT_OUTPUT"),FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"\t") + "\n");output.close()
	host.free()
	print("YARD_ORIGINAL_READONLY_AUDIT ", JSON.stringify(result))
	quit(0 if failures.is_empty() else 1)
