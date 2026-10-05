extends SceneTree

## M2-T1: real screen-touch events stage world commands; only explicit HUD
## confirmation executes. Gesture endings must never issue world commands.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")

var failures: Array[String] = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	create_timer(180.0).timeout.connect(func():
		push_error("M2_T1_WALL_CLOCK_GUARD")
		quit(3)
	)
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		quit(2)
		return
	await _frames(14)
	var main = current_scene
	if main == null or not main.has_method("_start_setup"):
		push_error("M2_T1_MAIN_SCRIPT_REQUIRED")
		quit(2)
		return
	if main.level == null or str(main.level.level_id) != "yard":
		push_error("M2_T1_REAL_YARD_REQUIRED")
		quit(2)
		return
	if main.tutorial_overlay != null and main.tutorial_overlay.is_open():
		for _page in 3:
			main.tutorial_overlay._on_next()
		await _frames(2)
	var settings = root.get_node_or_null("GameSettings")
	if settings == null:
		push_error("M2_T1_GAME_SETTINGS_REQUIRED")
		quit(2)
		return
	settings.force_touch_hud = true
	main._ensure_touch_hud()
	main._start_setup(false, false)
	main.set_process(false)
	for op in main.operators:
		op.set_process(false)
		op.stop_move()
	for sentry in main.c2.sentries if main.c2 != null else []:
		if sentry != null and is_instance_valid(sentry):
			sentry.set_process(false)
			sentry.global_position = Vector2(2000.0, 2000.0)
	main._select_op(0)
	var op = main.selected
	var op_home: Vector2 = op.global_position
	var ground := _find_open_move_target(main, op)
	_expect(ground != Vector2.INF, "M2_T1_OPEN_REACHABLE_GROUND_FIXTURE")
	if ground == Vector2.INF:
		quit(2)
		return

	# Tap stages a visible intent. Position, cover, inventory, and simulation stay still.
	var start_pos: Vector2 = op.global_position
	var start_slot = op.slot
	var start_ammo := int(op.ammo)
	var start_tick := int(main.sim.tick)
	_tap(main, ground)
	_expect(main.touch_intent_pending() and main.touch_intent_preview_active(), "M2_T1_TAP_HAS_PREVIEW")
	_expect(str(main._touch_intent.get("kind", "")) == "move", "M2_T1_GROUND_TAP_CLASSIFIES_MOVE")
	_expect(op.global_position == start_pos and op.slot == start_slot and not op.is_moving(), "M2_T1_PREVIEW_DOES_NOT_MOVE_OR_DEPLOY")
	_expect(int(op.ammo) == start_ammo and int(main.sim.tick) == start_tick, "M2_T1_PREVIEW_DOES_NOT_CHANGE_RESOURCES_OR_SIM")
	_expect(main.touch_hud._world_intent_panel.visible, "M2_T1_CONFIRM_CANCEL_VISIBLE_ONLY_WHILE_PENDING")
	await _assert_intent_panel_safe_area(main)
	var confirm: Button = main.touch_hud._btns.get("world_confirm") as Button
	_expect(confirm != null and confirm.text == "确认", "M2_T1_EXPLICIT_CONFIRM_BUTTON")
	if confirm != null:
		confirm.pressed.emit()
	_expect(not main.touch_intent_pending() and op.is_moving(), "M2_T1_CONFIRM_EXECUTES_MOVE")
	op.stop_move()
	var stale_release := _screen_touch(0, false, Vector2(900.0, 500.0))
	main._unhandled_input(stale_release)
	_expect(not op.is_moving(), "M2_T1_CONFIRM_FOLLOWED_BY_RELEASE_DOES_NOT_REPLAY")
	op.global_position = op_home

	# Cover placement is also preview-first; its authored arc is the visible target preview.
	var cover = _free_slot(main, op)
	_expect(cover != null, "M2_T1_FREE_COVER_FIXTURE")
	if cover == null:
		quit(2)
		return
	var before_deployed := int(main._deployed_count())
	var before_cover_pos: Vector2 = op.global_position
	_tap(main, cover.global_position)
	_expect(main.touch_intent_pending() and str(main._touch_intent.get("kind", "")) == "cover", "M2_T1_COVER_TAP_PREVIEWS_DEPLOY")
	_expect(op.slot == null and op.global_position == before_cover_pos and int(main._deployed_count()) == before_deployed, "M2_T1_COVER_PREVIEW_HAS_NO_WORLD_MUTATION")
	_expect(main._touch_preview_slot == cover, "M2_T1_COVER_PREVIEW_HIGHLIGHTS_AUTHORED_ARC")
	confirm.pressed.emit()
	_expect(op.slot == cover and cover.occupied_by == op, "M2_T1_COVER_CONFIRM_DEPLOYS_ONCE")

	# Cancel a move intent and verify nothing changes.
	var move_target := _find_open_move_target(main, op)
	var cover_before = op.slot
	var pos_before: Vector2 = op.global_position
	var path_before: PackedVector2Array = op.move_path.duplicate()
	_tap(main, move_target)
	_expect(main.touch_intent_pending(), "M2_T1_CANCEL_FIXTURE_PENDING")
	var cancel: Button = main.touch_hud._btns.get("world_cancel") as Button
	if cancel != null:
		cancel.pressed.emit()
	_expect(not main.touch_intent_pending() and op.slot == cover_before and op.global_position == pos_before and op.move_path == path_before, "M2_T1_CANCEL_NO_POSITION_OR_PLAN_CHANGE")

	# Drag pans the camera, not the selected operator; release is inert.
	var pan_start := _find_open_move_target(main, op)
	var pan_pos := _world_to_screen(main, pan_start)
	var pan0: Vector2 = main._cam_pan
	pos_before = op.global_position
	cover_before = op.slot
	main._unhandled_input(_screen_touch(0, true, pan_pos))
	main._unhandled_input(_screen_drag(0, pan_pos + Vector2(56.0, 4.0), Vector2(56.0, 4.0)))
	main._unhandled_input(_screen_touch(0, false, pan_pos + Vector2(56.0, 4.0)))
	_expect(str(main._last_touch_gesture) == "pan" and main._cam_pan != pan0, "M2_T1_ONE_FINGER_DRAG_PANS_CAMERA")
	_expect(not main.touch_intent_pending() and op.global_position == pos_before and op.slot == cover_before and not op.is_moving(), "M2_T1_PAN_RELEASE_HAS_NO_WORLD_COMMAND")

	# Two-finger movement pans and zooms only.
	var pinch_center := _world_to_screen(main, main.grid.cell_to_world_center(Vector2i(20, 12)))
	var p1 := pinch_center - Vector2(28.0, 0.0)
	var p2 := pinch_center + Vector2(28.0, 0.0)
	var zoom0 := float(main._cam_zoom)
	pan0 = main._cam_pan
	pos_before = op.global_position
	cover_before = op.slot
	main._unhandled_input(_screen_touch(0, true, p1))
	main._unhandled_input(_screen_touch(1, true, p2))
	main._unhandled_input(_screen_drag(1, p2 + Vector2(26.0, 0.0), Vector2(26.0, 0.0)))
	main._unhandled_input(_screen_touch(1, false, p2 + Vector2(26.0, 0.0)))
	main._unhandled_input(_screen_touch(0, false, p1))
	_expect(not is_equal_approx(float(main._cam_zoom), zoom0) and main._cam_pan != pan0, "M2_T1_PINCH_CHANGES_CAMERA_ONLY")
	_expect(not main.touch_intent_pending() and op.global_position == pos_before and op.slot == cover_before and not op.is_moving(), "M2_T1_PINCH_RELEASE_HAS_NO_WORLD_COMMAND")

	# Facing drag stays immediate, but it cannot also issue a world command on release.
	var facing_before := float(op.facing_deg)
	pos_before = op.global_position
	cover_before = op.slot
	var facing_screen := _world_to_screen(main, op.global_position)
	main._unhandled_input(_screen_touch(0, true, facing_screen))
	main._unhandled_input(_screen_drag(0, facing_screen + Vector2(64.0, 8.0), Vector2(64.0, 8.0)))
	main._unhandled_input(_screen_touch(0, false, facing_screen + Vector2(64.0, 8.0)))
	_expect(not is_equal_approx(float(op.facing_deg), facing_before), "M2_T1_FACING_DRAG_APPLIES_IMMEDIATELY")
	_expect(not main.touch_intent_pending() and op.global_position == pos_before and op.slot == cover_before and not op.is_moving(), "M2_T1_FACING_RELEASE_IS_INERT")

	# A camera or facing gesture invalidates an earlier, still-unconfirmed intent.
	_tap(main, _find_open_move_target(main, op))
	_expect(main.touch_intent_pending(), "M2_T1_STALE_CAMERA_FIXTURE_PENDING")
	var pan_clear := _world_to_screen(main, _find_open_move_target(main, op))
	main._unhandled_input(_screen_touch(0, true, pan_clear))
	main._unhandled_input(_screen_drag(0, pan_clear + Vector2(52.0, 0.0), Vector2(52.0, 0.0)))
	main._unhandled_input(_screen_touch(0, false, pan_clear + Vector2(52.0, 0.0)))
	_expect(not main.touch_intent_pending() and not op.is_moving(), "M2_T1_CAMERA_GESTURE_CLEARS_STALE_INTENT")
	_tap(main, _find_open_move_target(main, op))
	_expect(main.touch_intent_pending(), "M2_T1_STALE_FACING_FIXTURE_PENDING")
	facing_screen = _world_to_screen(main, op.global_position)
	main._unhandled_input(_screen_touch(0, true, facing_screen))
	main._unhandled_input(_screen_drag(0, facing_screen + Vector2(60.0, 0.0), Vector2(60.0, 0.0)))
	main._unhandled_input(_screen_touch(0, false, facing_screen + Vector2(60.0, 0.0)))
	_expect(not main.touch_intent_pending() and not op.is_moving(), "M2_T1_FACING_GESTURE_CLEARS_STALE_INTENT")

	# Long-pressing a cover shows its arc, never deploys on release.
	var second_cover = _free_slot(main, op, cover)
	_expect(second_cover != null, "M2_T1_LONGPRESS_COVER_FIXTURE")
	if second_cover != null:
		pos_before = op.global_position
		cover_before = op.slot
		main._unhandled_input(_screen_touch(0, true, _world_to_screen(main, second_cover.global_position)))
		main._cover_hold_msec = Time.get_ticks_msec() - int(main.COVER_LONGPRESS_MS) - 1
		main._tick_cover_long_press()
		_expect(main._touch_preview_slot == second_cover, "M2_T1_LONGPRESS_COVER_ARC_PREVIEW")
		main._unhandled_input(_screen_touch(0, false, _world_to_screen(main, second_cover.global_position)))
		_expect(not main.touch_intent_pending() and op.slot == cover_before and op.global_position == pos_before, "M2_T1_LONGPRESS_RELEASE_DID_NOT_DEPLOY")

	# Tool actions share the same gate: preview/cancel is free; explicit confirm consumes once.
	op.decoys = 1
	main.tool = main.Tool.DECOY
	var decoys_before: int = main.raid_decoys.size()
	var decoy_target := _find_open_move_target(main, op)
	_tap(main, decoy_target)
	_expect(main.touch_intent_pending() and str(main._touch_intent.get("kind", "")) == "decoy", "M2_T1_TOOL_TAP_PREVIEWS")
	_expect(int(op.decoys) == 1 and main.raid_decoys.size() == decoys_before, "M2_T1_TOOL_PREVIEW_DOES_NOT_CONSUME")
	if cancel != null:
		cancel.pressed.emit()
	_expect(int(op.decoys) == 1 and main.raid_decoys.size() == decoys_before, "M2_T1_TOOL_CANCEL_IS_FREE")
	_tap(main, decoy_target)
	confirm.pressed.emit()
	_expect(int(op.decoys) == 0 and main.raid_decoys.size() == decoys_before + 1, "M2_T1_TOOL_CONFIRM_EXECUTES_ONCE")
	op.decoys = 1 # Sentinel: a stale release would create a second decoy.
	main._unhandled_input(_screen_touch(0, false, decoy_target))
	_expect(int(op.decoys) == 1 and main.raid_decoys.size() == decoys_before + 1, "M2_T1_TOOL_CONFIRM_RELEASE_NOT_REPLAYED")
	main.tool = main.Tool.DEPLOY

	# Selection change, modal open, and phase departure invalidate any staged intent.
	_tap(main, _find_open_move_target(main, op))
	main._select_op(1)
	_expect(not main.touch_intent_pending(), "M2_T1_SELECTION_CHANGE_CLEARS_INTENT")
	main._select_op(0)
	_tap(main, _find_open_move_target(main, op))
	main._toggle_pause_menu()
	main._process(0.0)
	_expect(not main.touch_intent_pending(), "M2_T1_MODAL_OPEN_CLEARS_INTENT")
	main._toggle_pause_menu()
	_tap(main, _find_open_move_target(main, op))
	var old_phase = main.phase
	main.phase = main.Phase.WATCHING
	main._process(0.0)
	_expect(not main.touch_intent_pending(), "M2_T1_PHASE_CHANGE_CLEARS_INTENT")
	main.phase = old_phase
	main._cancel_touch_intent()
	main._touch_preview_slot = null
	main._update_cover_previews()

	if not failures.is_empty():
		quit(1)
		return
	print("M2_TOUCH_INTENT_OK preview_first=1 explicit_confirm=1 no_double_command=1 pan_pinch_facing_inert=1 longpress_preview=1 cancel_stale=1")
	quit(0)


func _tap(main, world: Vector2) -> void:
	var screen := _world_to_screen(main, world)
	main._unhandled_input(_screen_touch(0, true, screen))
	main._unhandled_input(_screen_touch(0, false, screen))


func _world_to_screen(main, world: Vector2) -> Vector2:
	return main.get_viewport().get_canvas_transform() * world


func _screen_touch(index: int, pressed: bool, position: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	return event


func _screen_drag(index: int, position: Vector2, relative: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	return event


func _find_open_move_target(main, op) -> Vector2:
	for y in range(AmbushGrid.ROWS):
		for x in range(AmbushGrid.COLS):
			var cell := Vector2i(x, y)
			if main.grid.is_blocked(x, y):
				continue
			var world: Vector2 = main.grid.cell_to_world_center(cell)
			if world.distance_to(op.global_position) < 80.0 or main._nearest_slot(world, 14.0) != null:
				continue
			var near_stash := false
			for stash in main.raid_stashes:
				if stash != null and is_instance_valid(stash) and not bool(stash.collected) and stash.global_position.distance_to(world) < 34.0:
					near_stash = true
					break
			if near_stash:
				continue
			if not main._resolve_move_cells(op, world).is_empty():
				return world
	return Vector2.INF


func _free_slot(main, op, except = null):
	for slot in main.cover_slots:
		if slot == null or not is_instance_valid(slot) or slot == except:
			continue
		if slot.occupied_by == null or slot.occupied_by == op:
			return slot
	return null


func _expect(ok: bool, label: String) -> void:
	if ok:
		print("PASS ", label)
	else:
		failures.append(label)
		push_error("FAIL " + label)


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _assert_intent_panel_safe_area(main) -> void:
	var hud = main.touch_hud
	var panel: Control = hud._world_intent_panel
	var was_visible := panel.visible
	var prior_label := str(hud._world_intent_label.text)
	var viewport_size: Vector2 = main.get_viewport().get_visible_rect().size
	var safe_left := 28.0
	var safe_top := 20.0
	var safe_right := 44.0
	var safe_bottom := 32.0
	hud._position_world_intent_panel(safe_right, safe_bottom)
	hud.set_world_intent_pending(true, "safe-area geometry check")
	await _frames(2)
	var panel_rect: Rect2 = panel.get_global_rect()
	var setup_row_rect: Rect2 = hud._row_setup.get_global_rect()
	_expect(
		panel_rect.position.x >= safe_left
		and panel_rect.position.y >= safe_top
		and panel_rect.end.x <= viewport_size.x - safe_right + 0.5
		and panel_rect.end.y <= viewport_size.y - safe_bottom + 0.5,
		"M2_T1_CONFIRM_PANEL_INSIDE_SAFE_RECT"
	)
	_expect(not panel_rect.intersects(setup_row_rect), "M2_T1_CONFIRM_PANEL_CLEAR_OF_SETUP_ROW")
	hud._position_world_intent_panel(8.0, 8.0)
	hud._apply_safe_area()
	hud.set_world_intent_pending(was_visible, prior_label)
