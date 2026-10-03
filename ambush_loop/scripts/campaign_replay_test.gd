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
var report_rows := []
var capture_rows := []


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
		var scope := OS.get_environment("AMBUSH_CAMPAIGN_LEVEL")
		if not scope.is_empty() and scope != str(case[0]):
			continue
		var reference: Dictionary = await _battle(main, case, 60, 1.0, false)
		var rotating: Dictionary = await _battle(main, case, 30, 1.0, true)
		var fast: Dictionary = await _battle(main, case, 60, 2.0, true)
		if reference != rotating:
			_report_difference(reference, rotating, str(case[0]) + ":30fps")
		if reference != fast:
			_report_difference(reference, fast, str(case[0]) + ":2x")
		_check(reference == rotating and reference == fast, case[0] + " complete multi-wave outcomes/events match at 30/60 FPS and 2x")
		print("CAMPAIGN_REPLAY_LEVEL ", case[0], " waves=", main.level.wave_count(),
			" terminal=", main.battle_log.terminal_tick, " events=", main.battle_log.events.size())
	root.get_node("AudioDirector").pause_for_background()
	var scope:=OS.get_environment("AMBUSH_CAMPAIGN_LEVEL")
	var file:=FileAccess.open("res://build/asset_review/pr15-runtime/full-campaign-"+(scope if not scope.is_empty() else "all")+"-record-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"runs":report_rows,"captures":capture_rows},"  "))
	print("CAMPAIGN_REPLAY_OK checks=" if failures == 0 else "CAMPAIGN_REPLAY_FAILED checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _battle(main: Node, case: Array, fps: int, speed: float, rotate: bool) -> Dictionary:
	main._load_level(case[0], false, false)
	await process_frame # Finish queued cleanup before the next fixture.
	main.presentation_3d.set_process(false)
	var scout_attempt: String=main.battle_log.attempt_id
	for i in 4: main._process(0.1)
	_check(not scout_attempt.is_empty() and main.battle_log.playback_snapshots.any(func(snap: Dictionary) -> bool: return int(snap.data.phase)==main.Phase.SETUP),"actual SCOUT prelude is recorded before alarm")
	main.raid_prepare_ref(case[1], case[2])
	if case[0] == "warehouse":
		main._play_hold_pack(1)
	if case[0] in ["depot", "radio"]:
		main._try_place_tripwire(main.grid.cell_to_world_center(Vector2i(7, 11)))
	main.raid_force_alarm()
	_check(main.battle_log.attempt_id==scout_attempt,"first alarm keeps recorded SCOUT identity")
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
		for i in 2: main._process(0.1)
		_check(main.battle_log.playback_snapshots.any(func(snap: Dictionary) -> bool: return int(snap.data.phase)==main.Phase.SWEEP and int(snap.wave_id)==wave),"actual unpaused SWEEP interval records each authored wave")
		# Same sweep helper as the full smoke: consume authored drops, never grant
		# extra resources. This is a simulation fixture, not a physical pickup test.
		main.raid_vacuum_loot()
		main._on_sweep_commit()
	_check(main.phase == main.Phase.WON and main.raid.waves_cleared == main.level.wave_count(), case[0] + " all authored waves extract")
	var log = main.battle_log
	var expected_terminals := {"yard":[1283,34],"warehouse":[1191,67],"pump":[907,34],"railcut":[719,38],"depot":[957,35],"radio":[1413,51]}
	_check([log.terminal_tick,log.events.size()]==expected_terminals[case[0]],"original fixed baseline battle terminal/event count preserved "+case[0])
	var playback_previous := -1
	for i in log.playback_snapshots.size():
		var snap: Dictionary=log.playback_snapshots[i]
		_check(snap.playback_tick>=playback_previous and snap.frame_seq==i and snap.attempt_id==scout_attempt,"full real playback has monotonic time/stable attempt/frame_seq")
		playback_previous=snap.playback_tick
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
	_normalize_identity(final, utility_scope, main.battle_log.attempt_id)
	var events: Array = log.events.duplicate(true)
	for ev in events:
		ev.erase("attempt_id")
		ev.erase("event_id")
	main._on_replay_pressed()
	var live_before: Dictionary = main._snapshot_data().duplicate(true)
	var stream_before: Array=log.playback_snapshots.duplicate(true)
	main.replay.set_tick(0)
	var scout_frame := ViewState.capture(main)
	_check(scout_frame.recorded_phase==main.Phase.SETUP and scout_frame.events.is_empty() and scout_frame.attempt_id==scout_attempt,"complete campaign can seek real SCOUT before future alarm events")
	for wave in main.level.wave_count():
		var wave_frames: Array = log.snapshots.filter(func(snap: Dictionary) -> bool: return snap.wave_id == wave)
		for snap in [wave_frames.front(), wave_frames.back()]:
			main.replay.set_tick(main.replay.playback_time(snap))
			var frame := ViewState.capture(main)
			_check(frame.wave_id == wave and frame.attempt_id == snap.attempt_id and frame.recorded_phase==snap.data.phase and frame.frame_seq==snap.frame_seq, "scrub resolves the exact historical wave/phase/frame identity")
			for ev in frame.events:
				_check(BattleLog.record_tick(ev) <= frame.tick, "scrub excludes future events")
	_check(live_before == main._snapshot_data(), "complete campaign scrub leaves live actors unchanged")
	_check(log.playback_snapshots==stream_before,"complete campaign seeks preserve the entire continuous source")
	report_rows.append({"level":case[0],"fps":fps,"speed":speed,"camera_rotate":rotate,"waves":wave_ends,"battle_terminal_tick":log.terminal_tick,"playback_terminal_tick":log.playback_terminal_tick,"events":log.events.size(),"fingerprint":log.fingerprint(),"playback_frames":log.playback_snapshots.size(),"schema":log.playback_schema,"attempt_id":log.attempt_id})
	if fps==60 and speed==1.0 and DisplayServer.get_name()!="headless":
		await _capture_history(main,case[0]+"_scout",0)
		for wave in main.level.wave_count():
			var alert: Array=log.playback_snapshots.filter(func(snap: Dictionary) -> bool: return int(snap.wave_id)==wave and int(snap.data.phase)==main.Phase.WATCHING)
			var sweep: Array=log.playback_snapshots.filter(func(snap: Dictionary) -> bool: return int(snap.wave_id)==wave and int(snap.data.phase)==main.Phase.SWEEP)
			await _capture_history(main,case[0]+"_wave"+str(wave)+"_alert",int(alert[alert.size()/2].playback_tick))
			await _capture_history(main,case[0]+"_wave"+str(wave)+"_sweep",int(sweep.back().playback_tick))
		await _capture_history(main,case[0]+"_won",main.replay.max_tick())
	return {"state": final, "events": events, "wave_ends": wave_ends, "terminal": log.terminal_tick}


func _capture_history(main: Node,label: String,tick: int) -> void:
	main.replay.set_tick(tick)
	main._apply_replay_scrub()
	main.presentation_3d.rig.reset_view()
	main.presentation_3d.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path: String="res://build/asset_review/pr15-runtime/full_record_"+label+".png"
	_check(image.save_png(path)==OK,"save actual complete history framebuffer "+label)
	capture_rows.append({"id":label,"path":path,"sha256":FileAccess.get_sha256(path),"image_size":[image.get_width(),image.get_height()],"source":"native Window crop"})


func _normalize_identity(value: Variant, scope: String, attempt: String) -> void:
	# Retain every body field and relative ID while normalizing only deliberately
	# random attempt/scope prefixes across independent FPS/2x runs.
	if value is Dictionary:
		for key in value:
			if value[key] is String:
				value[key] = value[key].replace(scope, "<scope>") if not scope.is_empty() else value[key]
				if not attempt.is_empty():
					value[key] = value[key].replace(attempt, "<attempt>")
			else:
				_normalize_identity(value[key], scope, attempt)
	elif value is Array:
		for item in value:
			_normalize_identity(item, scope, attempt)


func _report_difference(left: Variant, right: Variant, path: String) -> void:
	if left == right:
		return
	if left is Dictionary and right is Dictionary:
		for key in left:
			_report_difference(left[key], right.get(key), path+"."+str(key))
	elif left is Array and right is Array and left.size() == right.size():
		for index in left.size():
			_report_difference(left[index],right[index],path+"["+str(index)+"]")
	else:
		print("CAMPAIGN_DIFFERENCE ",path," left=",left," right=",right)
