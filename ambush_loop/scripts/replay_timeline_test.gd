extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("REPLAY_TIMELINE: " + message)


func _run() -> void:
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main.raid_force_alarm()
	var limit := 0
	while main.phase == main.Phase.WATCHING and limit < 3000:
		main._sim_tick()
		limit += 1
	_check(main.phase == main.Phase.SWEEP, "actual first reference wave clears")
	var first_end: int = main.battle_log.snapshots.back().get("timeline_tick", main.battle_log.snapshots.back().tick)
	var first_events: Array = main.battle_log.events.duplicate(true)
	var first_run: int = main.run_id
	main._on_sweep_commit()
	_check(main.run_id != first_run and main.sim.tick == 0, "actual next-wave transition resets the simulation clock")
	for i in 13:
		main._sim_tick()
	var log = main.battle_log
	var latest: Dictionary = log.snapshots.back()
	var latest_time: int = latest.get("timeline_tick", latest.tick)
	var player := ReplayPlayer.new()
	player.bind(log)
	_check(latest_time > first_end, "later wave has a later replay timestamp")
	_check(player.max_tick() > first_end, "scrubber includes all recorded waves")
	_check(player.snapshot_at_or_before(player.playback_time(latest)) == latest, "seek to second-wave frame cannot return a first-wave frame")
	var initial_events := first_events.filter(func(ev: Dictionary) -> bool: return int(ev.tick) == 0)
	_check(player.events_up_to(player.playback_time(log.events.front())) == initial_events, "seeking first alarm cannot reveal next-wave spawn events")
	_check(player.events_up_to(0).is_empty(),"initial SCOUT frame excludes every future battle event")
	for i in first_events.size():
		_check(log.events[i] == first_events[i], "next wave preserves historical event identity/data")
		_check(log.events[i].has("attempt_id") and log.events[i].has("wave_id") and log.events[i].has("event_id"), "event stores attempt/wave/seq identity")
	main._on_replay_pressed()
	main.replay.set_tick(main.replay.playback_time(latest))
	var before: Dictionary = main._snapshot_data().duplicate(true)
	var frame: Dictionary = ViewState.capture(main)
	_check(int(frame.get("wave_id", -1)) == 1, "3D frame gets recorded wave identity")
	_check(frame.ops == ViewState.capture(main).ops and before == main._snapshot_data(), "capture and scrub do not write live actors")
	var retained: Dictionary = frame.duplicate(true)
	main.run_id += 100
	_check(ViewState.capture(main) == retained, "historical frame does not acquire the current run identity")
	_legacy()
	_recording_contract()
	if failures == 0:
		print("REPLAY_TIMELINE_OK checks=", checks)
	else:
		print("REPLAY_TIMELINE_FAILED failures=", failures, " checks=", checks)
	quit(0 if failures == 0 else 1)


func _legacy() -> void:
	var old := BattleLog.new()
	old.snapshots = [{"tick": 0, "data": {"ops": []}}, {"tick": 6, "data": {"ops": [{"id": 1, "ammo": 3}]}}]
	old.events = [{"tick": 3, "seq": 0, "type": "fire", "actor_id": 1, "target_id": 1}]
	old.terminal_tick = 9
	var player := ReplayPlayer.new()
	player.bind(old)
	_check(player.max_tick() == 9 and player.scrub_tick == 9, "legacy terminal time supported")
	_check(player.snapshot_at_or_before(5).tick == 0 and player.snapshot_at_or_before(6).tick == 6, "legacy local tick lookup unchanged")
	_check(player.events_up_to(2).is_empty() and player.events_up_to(3).size() == 1, "legacy event time supported")
	old.snapshots.append({"tick": 0, "data": {"ops": []}})
	var retained: Array = old.snapshots.duplicate(true)
	player.bind(old)
	_check(player.legacy_ambiguous and player.snapshot_at_or_before(3).is_empty() and player.events_up_to(3).is_empty(), "ambiguous unversioned reset recording cannot mix waves")
	_check(old.snapshots == retained, "legacy source records are retained unchanged")
	var event_reset := BattleLog.new()
	event_reset.snapshots = [{"tick": 0, "data": {"ops": []}}, {"tick": 6, "data": {"ops": []}}]
	event_reset.events = [{"tick": 3, "type": "fire"}, {"tick": 0, "type": "spawn"}]
	var retained_events: Array = event_reset.events.duplicate(true)
	player.bind(event_reset)
	_check(player.legacy_ambiguous and player.snapshot_at_or_before(0).is_empty() and player.events_up_to(0).is_empty(), "event-only clock reset is also ambiguous and cannot expose the later spawn early")
	_check(event_reset.events == retained_events and event_reset.snapshots.size() == 2, "event-only ambiguous source arrays remain intact")


func _recording_contract() -> void:
	var log := BattleLog.new()
	log.begin_attempt("attempt-a")
	var state := {"ops": [{"id": 1, "ammo": 7}]}
	var payload := {"kit": "rifle"}
	log.add_snapshot(0, state)
	log.add_event(60, "kill", 1, -1, Vector2.ZERO, payload)
	log.add_snapshot(60, state)
	state.ops[0].ammo = 0
	payload.kit = "knife"
	_check(log.snapshots[0].data.ops[0].ammo == 7 and log.events[0].payload.kit == "rifle", "recorded frames and payloads do not alias live containers")
	log.begin_wave(1)
	log.add_snapshot(0, state)
	log.add_event(0, "kill", 1)
	log.mark_terminal(12, "win")
	log.add_snapshot(12, state)
	_check(log.events[0].event_id == "attempt-a:0:0" and log.events[1].event_id == "attempt-a:1:1", "reused actor IDs have independent wave event identities")
	_check(log.terminal_tick == 73 and log.max_kill_combo() == 1, "terminal uses global time and combo cannot span waves")
	var player := ReplayPlayer.new()
	player.bind(log)
	player.set_tick(61)
	_check(player.snapshot_at_or_before(player.scrub_tick).wave_id == 1, "next wave has a frame at its first timeline tick")
	_check(player.events_up_to(60).size() == 1 and player.events_up_to(61).size() == 2, "event interval boundaries respect global time")
	log.begin_attempt("attempt-b")
	log.add_event(0, "kill", 1)
	_check(log.events[0].event_id == "attempt-b:0:0" and log.snapshots.is_empty(), "retry starts a separate identity and removes prior frames")
