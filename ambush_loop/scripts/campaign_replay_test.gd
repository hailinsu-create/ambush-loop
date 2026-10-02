extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const CASES := [
	["yard", [1, 2, 5], [90.0, 180.0, 180.0]],
	["warehouse", [1, 3, 5], [180.0, 0.0, 180.0]],
	["pump", [1, 4, 5], [90.0, 0.0, 180.0]],
	["railcut", [1, 4, 5], [270.0, 270.0, 180.0]],
	["depot", [1, 4, 5], [270.0, 270.0, 180.0]],
	["radio", [1, 4, 5], [270.0, 90.0, 270.0]],
]
var failures := 0
var checks := 0
var _utility_scopes := {}


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMPAIGN_REPLAY: " + message)


func _run() -> void:
	var settings = root.get_node("GameSettings")
	for case in CASES:
		settings.mark_tutorial_seen(case[0])
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	for case in CASES:
		var reference: Dictionary = await _battle(main, case, 60, 1.0, false)
		var rotating: Dictionary = await _battle(main, case, 30, 1.0, true)
		var fast: Dictionary = await _battle(main, case, 60, 2.0, true)
		_check(reference == rotating and reference == fast, case[0] + " complete multi-wave outcomes/events match at 30/60 FPS and 2x")
		print("CAMPAIGN_REPLAY_LEVEL ", case[0], " waves=", main.level.wave_count(),
			" terminal=", main.battle_log.terminal_tick, " events=", main.battle_log.events.size())
	root.get_node("AudioDirector").pause_for_background()
	print("CAMPAIGN_REPLAY_OK checks=" if failures == 0 else "CAMPAIGN_REPLAY_FAILED checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _battle(main: Node, case: Array, fps: int, speed: float, rotate: bool) -> Dictionary:
	main._load_level(case[0], false, false)
	await process_frame # Finish queued cleanup before the next fixture.
	main.raid_prepare_ref(case[1], case[2])
	if case[0] == "warehouse":
		main._play_hold_pack(1)
	if case[0] in ["depot", "radio"]:
		main._try_place_tripwire(main.grid.cell_to_world_center(Vector2i(7, 11)))
	main.raid_force_alarm()
	var utility_scope: String = main._snapshot_data().get("utility_scope_id", "")
	_check(not utility_scope.is_empty() and not _utility_scopes.has(utility_scope), "each real attempt owns a distinct SCOUT recording identity")
	_utility_scopes[utility_scope] = true
	var wave_ends := []
	for wave in main.level.wave_count():
		main.sim.set_speed(speed)
		var frames := 0
		while main.phase == main.Phase.WATCHING and frames < 12000:
			var steps: int = main.sim.steps_for_frame(1.0 / fps)
			for step in steps:
				if main.phase == main.Phase.WATCHING:
					main._sim_tick()
			if rotate and frames % 8 == 0:
				main.presentation_3d.rig.yaw_deg = frames * 3.0
				main.presentation_3d.rig.apply_pose()
				main.presentation_3d.refresh()
			frames += 1
		_check(main.phase == main.Phase.SWEEP, case[0] + " wave %d clears" % wave)
		if main.phase != main.Phase.SWEEP:
			return {"failed": case[0], "wave": wave, "reason": main.fail_reason}
		wave_ends.append(main.sim.tick)
		# Same sweep helper as the full smoke: consume authored drops, never grant
		# extra resources. This is a simulation fixture, not a physical pickup test.
		main.raid_vacuum_loot()
		main._on_sweep_commit()
	_check(main.phase == main.Phase.WON and main.raid.waves_cleared == main.level.wave_count(), case[0] + " all authored waves extract")
	var log = main.battle_log
	var previous := -1
	var seen_waves := {}
	for snap in log.snapshots:
		var t: int = BattleLog.record_tick(snap)
		_check(t >= previous, "snapshots have monotonic global time")
		_check(snap.attempt_id == log.attempt_id, "snapshot owns the recording identity")
		previous = t
		seen_waves[snap.wave_id] = true
	_check(seen_waves.size() == main.level.wave_count(), "replay contains every wave")
	var identities := {}
	previous = -1
	for i in log.events.size():
		var ev: Dictionary = log.events[i]
		_check(ev.seq == i and not identities.has(ev.event_id), "events have unique stable sequence identities")
		_check(BattleLog.record_tick(ev) >= previous, "events have monotonic global time")
		identities[ev.event_id] = true
		previous = BattleLog.record_tick(ev)
	var final: Dictionary = main._snapshot_data().duplicate(true)
	_check(log.snapshots.all(func(snap: Dictionary) -> bool: return str(snap.data.get("utility_scope_id", "")) == utility_scope), "all waves keep the original utility recording identity")
	# Like BattleLog attempt/event IDs, this identity intentionally differs
	# across attempts. Every other state value remains in the comparison.
	final.erase("utility_scope_id")
	var events: Array = log.events.duplicate(true)
	for ev in events:
		ev.erase("attempt_id")
		ev.erase("event_id")
	main._on_replay_pressed()
	var live_before: Dictionary = main._snapshot_data().duplicate(true)
	for wave in main.level.wave_count():
		var wave_frames: Array = log.snapshots.filter(func(snap: Dictionary) -> bool: return snap.wave_id == wave)
		for snap in [wave_frames.front(), wave_frames.back()]:
			main.replay.set_tick(BattleLog.record_tick(snap))
			var frame := ViewState.capture(main)
			_check(frame.wave_id == wave and frame.attempt_id == snap.attempt_id, "scrub resolves the historical wave identity")
			for ev in frame.events:
				_check(BattleLog.record_tick(ev) <= frame.tick, "scrub excludes future events")
	_check(live_before == main._snapshot_data(), "complete campaign scrub leaves live actors unchanged")
	return {"state": final, "events": events, "wave_ends": wave_ends, "terminal": log.terminal_tick}
