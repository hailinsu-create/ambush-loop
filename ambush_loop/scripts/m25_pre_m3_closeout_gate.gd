extends "res://scripts/m1_yard_visual_evidence_gate.gd"

func _run() -> void:
	var main = await _open_yard("CLOSEOUT")
	if main == null: _finish_failed(); return
	main.open_yard_3d()
	await _frames(3)
	var presenter = main._active_i0_presenter()
	_expect(presenter != null, "M25_CLOSEOUT_3D_ACTIVE")
	if presenter == null: _finish_failed(); return
	var handle = presenter._facing_handle
	var original_facing: float = main.selected.facing_deg
	var down := InputEventScreenTouch.new()
	down.index = 91
	down.pressed = true
	down.position = handle.size * 0.5
	handle._gui_input(down)
	_expect(handle.pointer == 91, "M25_REAL_HANDLE_GUI_CAPTURES")
	var drag := InputEventScreenDrag.new()
	drag.index = 91
	drag.position = down.position + Vector2(80, -40)
	handle._gui_input(drag)
	_expect(main.selected.facing_deg == original_facing and not main._yard_facing_preview.is_empty(), "M25_HANDLE_GUI_PREVIEW_ONLY")
	var magnify := InputEventMagnifyGesture.new()
	magnify.factor = 1.1
	main._handle_touch_gestures(magnify)
	_expect(main._yard_facing_preview.is_empty() and main._facing_touch == -1, "M25_MAGNIFY_CANCELS_FACING")
	down.pressed = false
	handle._gui_input(down)
	_expect(main.selected.facing_deg == original_facing, "M25_MAGNIFY_LATE_RELEASE_NO_COMMIT")
	_expect(presenter._quality_button.size.y >= 48 and presenter._handed_button.size.y >= 48, "M25_TOUCH_TARGET_MINIMUM_48")
	var original_window_size := DisplayServer.window_get_size()
	DisplayServer.window_set_size(Vector2i(960, 540))
	await _frames(4)
	var logical_size: Vector2 = root.get_visible_rect().size
	_expect(DisplayServer.window_get_size() == Vector2i(960, 540), "M25_960_PHYSICAL_WINDOW")
	_expect(presenter._quality_button.get_global_rect().end.x <= logical_size.x and presenter._quality_button.size.y >= 48, "M25_960_TOUCH_TARGET_LAYOUT")
	await _capture(main, "3d-960-layout")
	DisplayServer.window_set_size(original_window_size)
	await _frames(3)
	var covered := {}
	var rectangles = preload("res://scripts/presentation/yard_wall_layout.gd").rectangles(main.grid, 40, 22)
	for rectangle in rectangles:
		var cells: Rect2i = rectangle.cells
		for y in range(cells.position.y, cells.end.y):
			for x in range(cells.position.x, cells.end.x):
				var cell := Vector2i(x, y)
				_expect(main.grid.is_blocked(x, y) and not covered.has(cell), "M25_WALL_PARTITION_BLOCKED_ONLY")
				covered[cell] = true
	var blocked := 0
	for y in 22:
		for x in 40:
			if main.grid.is_blocked(x, y): blocked += 1
	_expect(covered.size() == blocked and rectangles.size() < blocked, "M25_WALL_EXACT_PARTITION_FEWER_INSTANCES")
	var old_events: Array = main.battle_log.events.duplicate(true)
	main.battle_log.events.clear()
	for tick in 3000:
		main.battle_log.events.append({"tick": tick, "type": "probe"})
		main.battle_log.events.append({"tick": tick, "type": "probe_duplicate"})
	for tick in [0, 11, 2999, 50, 50, 0]:
		var expected: Array = []
		for event in main.battle_log.events:
			if int(event.tick) >= tick - 11 and int(event.tick) <= tick: expected.append(event)
		_expect(presenter.event_window(tick) == expected, "M25_EVENT_WINDOW_REWIND_DUPLICATE_EXACT")
	main.battle_log.events.assign(old_events)
	var ammo: int = main.selected.ammo
	var facing: float = main.selected.facing_deg
	_expect(presenter.open_readiness() and main._modal_blocks_input(), "M25_READINESS_BLOCKS_WORLD_INPUT")
	_expect(main.selected.ammo == ammo and main.selected.facing_deg == facing, "M25_READINESS_READ_ONLY")
	await _capture(main, "3d-readiness")
	_expect(presenter._readiness_sheet.candidate.size.y >= 48, "M25_READINESS_CANDIDATE_TARGET_48")
	DisplayServer.window_set_size(Vector2i(960, 540))
	await _frames(3)
	_expect(presenter._readiness_sheet.candidate.size.y >= 48 and presenter._readiness_sheet.candidate.get_global_rect().end.x <= root.get_visible_rect().size.x, "M25_READINESS_CANDIDATE_SMALL_LAYOUT")
	DisplayServer.window_set_size(original_window_size)
	await _frames(3)
	presenter.close_readiness()
	_expect(not presenter.readiness_open(), "M25_READINESS_DISMISS")
	var saved_snapshots: Array = main.battle_log.snapshots.duplicate(true)
	var saved_phase = main.phase
	var saved_scrub: int = main.replay.scrub_tick
	var historical_position: Vector2 = main.selected.global_position + Vector2(64, 0)
	var record := {"id": main.selected.op_id, "pos": historical_position, "tier": 0, "facing": 90.0, "alive": true}
	main.battle_log.snapshots.assign([{ "tick": 10, "data": {"ops": [record]} }, { "tick": 20, "data": {"ops": [{"id": main.selected.op_id, "pos": main.selected.global_position}]} }])
	main.phase = main.Phase.FAILED
	main._focus_battle_event({"tick": 10, "type": "fire", "actor_id": main.selected.op_id, "target_id": 1})
	_expect(main.focus_ring.global_position.is_equal_approx(historical_position), "M25_TERMINAL_EVENT_FOCUS_HISTORICAL_NOT_LIVE")
	_expect(main.replay.scrub_tick == saved_scrub, "M25_TERMINAL_FOCUS_DOES_NOT_SEEK_REPLAY")
	_expect(main._event_snapshot_at_or_before(9).is_empty(), "M25_EVENT_BEFORE_FIRST_SNAPSHOT_NO_FUTURE")
	presenter._sync_recorded({"ops": [record]})
	var recorded_body = presenter._actor_nodes[str(main.selected.op_id)]
	_expect(is_zero_approx(recorded_body.get_node("LeftArm").rotation.x) and "复盘静态姿态" in recorded_body.get_node("OcclusionIdentity").text, "M25_REPLAY_NEUTRAL_POSE_EXPLICIT")
	main.battle_log.snapshots.assign(saved_snapshots)
	main.phase = saved_phase
	main._gs().set_yard_3d_candidate(true)
	main._load_level("yard", false, false)
	await _frames(4)
	presenter = main._active_i0_presenter()
	_expect(presenter != null, "M25_CANDIDATE_PREFERENCE_RELOAD_3D")
	main._gs().set_yard_3d_candidate(false)
	for label in ["A", "B"]:
		main = await _open_yard("3D_PLAN_" + label)
		if main == null or not await _prepare_plan(main, label): _finish_failed(); return
		main.open_yard_3d()
		await _frames(3)
		presenter = main._active_i0_presenter()
		await _capture(main, "3d-plan-" + label)
		main.raid_force_alarm()
		var guard := 0
		while main.phase not in [main.Phase.WON, main.Phase.FAILED] and guard < MAX_SIM_TICKS:
			guard += 1
			if main.phase == main.Phase.SWEEP: main._on_sweep_commit()
			else: main._sim_tick()
			if guard % 120 == 0: presenter.sync_presentation()
		_expect(main.phase == main.Phase.WON, "M25_3D_PLAN_" + label + "_WINS_AUTHORITY")
		_expect(presenter.active, "M25_3D_NO_IMPLICIT_2D_FALLBACK")
		presenter.focus_recorded_event(Vector2(496, 400), main.sim.tick, "测试定位")
		_expect(presenter._focus_marker.visible, "M25_3D_EVENT_MARKER_VISIBLE")
		await _capture(main, "3d-terminal-" + label)
	if not failures.is_empty(): _finish_failed(); return
	print("M25_PRE_M3_CLOSEOUT_OK walls=1 indexed_events=1 readiness=1 candidate=1 plans_ab=1 screenshots=1")
	quit(0)
