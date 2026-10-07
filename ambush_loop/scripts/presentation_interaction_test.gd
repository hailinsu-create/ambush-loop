extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
var failures := 0
var checks := 0
var main: Node
var view: Node3D


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PRESENTATION_INPUT: " + message)


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _touch(id: int, pressed: bool, at: Vector2) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = at
	event.pressed = pressed
	return event


func _mouse(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	return event


func _north_layout_matrix(settings: Node) -> void:
	var before: Dictionary = main._snapshot_data().duplicate(true)
	for touch in [false, true]:
		settings.set_force_touch_hud(touch)
		for viewport_size in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(960, 540), Vector2i(640, 360)]:
			root.size = viewport_size
			main._update_hud()
			view.refresh()
			await process_frame
			await process_frame
			_check(main.phase_chip.is_visible_in_tree() and main.checklist_strip.is_visible_in_tree(),
				"north matrix keeps phase and readiness available: %s touch=%s" % [viewport_size, touch])
			_check(not main.phase_chip.get_global_rect().intersects(main.checklist_strip.get_global_rect()),
				"north phase/readiness do not overlap: %s touch=%s" % [viewport_size, touch])
	_check(main._snapshot_data() == before, "north layout matrix leaves tactical state unchanged")
	root.size = Vector2i(1280, 720)
	settings.set_force_touch_hud(true)
	main._update_hud()
	view.refresh()
	await process_frame
	await process_frame


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(true)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	main.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	view = main.presentation_3d
	await process_frame
	await _north_layout_matrix(settings)
	view.refresh()
	_check(view._camera_toggle.visible and not view._camera_panel.visible,
		"camera tools start collapsed while the compact entry remains available")
	var camera_state: Dictionary = main._snapshot_data().duplicate(true)
	var camera_toggle_at: Vector2 = view._camera_toggle.get_global_rect().get_center()
	_check(view.pointer_over_ui(camera_toggle_at), "camera entry owns its visible hit target")
	await _send(_mouse(true, camera_toggle_at))
	await _send(_mouse(false, camera_toggle_at))
	_check(view._camera_panel.visible, "camera entry opens detailed controls")
	_check(main._snapshot_data() == camera_state, "opening camera controls does not mutate gameplay")
	await _send(_mouse(true, camera_toggle_at))
	await _send(_mouse(false, camera_toggle_at))
	_check(not view._camera_panel.visible, "camera entry closes detailed controls")
	_check(main._snapshot_data() == camera_state, "closing camera controls does not mutate gameplay")
	for yaw in range(0, 360, 45):
		view.rig.yaw_deg = yaw
		view.rig.focus = Vector3.ZERO
		view.rig.view_size = 30.0
		view.rig.apply_pose()
		main._select_op(0)
		view.refresh()
		var op = main.operators[1]
		var at: Vector2 = view.rig.project_logic(op.global_position, 1.1)
		_check(not view.pointer_over_ui(at), "body test target clear of HUD at yaw %d" % yaw)
		await _send(_mouse(true, at))
		await _send(_mouse(false, at))
		_check(main.selected == op, "desktop body click at yaw %d" % yaw)
		main._select_op(0)
		await _send(_touch(0, true, at))
		_check(main.selected == main.operators[0], "native press does not commit")
		await _send(_touch(0, false, at))
		_check(main.selected == op, "native release selects at yaw %d" % yaw)
	view.rig.reset_view()
	view.refresh()
	main._select_op(0)
	var intent: Node = view.touch_intent
	var target: Vector2 = main.grid.cell_to_world_center(Vector2i(12, 13))
	var intent_before: Dictionary = main._snapshot_data().duplicate(true)
	var target_screen: Vector2 = view.rig.project_logic(target)
	_check(not view.pointer_over_ui(target_screen), "native intent target is clear of HUD")
	await _send(_touch(0, true, target_screen))
	await _send(_touch(0, false, target_screen))
	_check(not intent.pending.is_empty() and main._snapshot_data() == intent_before,
		"native world release previews without issuing a gameplay command")
	intent.cancel()
	_check(intent.stage({"valid": true, "pos": target, "kind": "ground"}), "world intent stages")
	_check(intent.panel.visible and intent.marker.visible and main._snapshot_data() == intent_before,
		"preview is visible without tactical mutation")
	_check(view.pointer_over_ui(intent.confirm_button.get_global_rect().get_center()), "confirmation owns input")
	intent.cancel()
	_check(intent.pending.is_empty() and not intent.panel.visible and main._snapshot_data() == intent_before,
		"cancel discards instruction without tactical mutation")
	intent.stage({"valid": true, "pos": target, "kind": "ground"})
	main._select_op(1)
	intent.confirm()
	_check(intent.pending.is_empty() and not main.selected.is_moving(), "changed actor rejects stale intent")
	main._select_op(0)
	intent.stage({"valid": true, "pos": target, "kind": "ground"})
	view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(intent.pending.is_empty(), "focus loss cancels world intent")
	intent.stage({"valid": true, "pos": target, "kind": "ground"})
	var confirm_at: Vector2 = intent.confirm_button.get_global_rect().get_center()
	await _send(_mouse(true, confirm_at))
	await _send(_mouse(false, confirm_at))
	_check(intent.pending.is_empty() and main.selected.is_moving(), "actual confirmation executes movement")
	main.selected.stop_move()
	intent.confirm()
	_check(not main.selected.is_moving(), "duplicate confirmation cannot execute twice")
	intent.stage({"valid": true, "pos": target, "kind": "ground"})
	main.selected.locked = true
	intent.confirm()
	_check(intent.pending.is_empty() and not main.selected.is_moving(), "locked actor rejects confirmation")
	main.selected.locked = false
	intent.stage({"valid": true, "pos": target, "kind": "covers", "id": "missing-cover"})
	intent.confirm()
	_check(intent.pending.is_empty() and not main.selected.is_moving(), "missing target rejects confirmation")
	intent.stage({"valid": true, "pos": target, "kind": "ground"})
	main.tool = main.Tool.GRENADE
	intent.confirm()
	_check(intent.pending.is_empty(), "tool change invalidates pending instruction")
	main.tool = main.Tool.DEPLOY
	var start := Vector2(640, 350)
	var second := Vector2(800, 350)
	var focus_before: Vector3 = view.rig.focus
	intent.stage({"valid": true, "pos": target, "kind": "ground"})
	await _send(_touch(0, true, start))
	await _send(_touch(1, true, second))
	_check(intent.pending.is_empty(), "second finger cancels pending instruction")
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = second + Vector2(50, 80)
	drag.relative = Vector2(50, 80)
	var yaw_before: float = view.rig.yaw_deg
	var before: Dictionary = main._snapshot_data().duplicate(true)
	await _send(drag)
	await _send(_touch(1, false, drag.position))
	await _send(_touch(0, false, start))
	_check(not is_equal_approx(yaw_before, view.rig.yaw_deg), "native two-finger event pipeline rotates")
	_check(focus_before.distance_to(view.rig.focus) > 0.001, "native two-finger event pipeline pans")
	_check(before == main._snapshot_data() and not main.selected.is_moving(), "camera gesture emits no command")
	# A real GUI button must own its click, without issuing a world command.
	var button := Button.new()
	button.position = Vector2(500, 280)
	button.size = Vector2(150, 80)
	var clicked := [0]
	button.pressed.connect(func() -> void: clicked[0] += 1)
	main.get_node("HUD/Root").add_child(button)
	await process_frame
	var at := button.get_global_rect().get_center()
	_check(view.pointer_over_ui(at), "UI hit test captures actual button")
	await _send(_mouse(true, at))
	await _send(_mouse(false, at))
	_check(clicked[0] == 1 and not main.selected.is_moving(), "GUI click does not leak through to movement")
	button.queue_free()
	await process_frame
	main.phase = main.Phase.WATCHING
	var face_before: float = main.selected.facing_deg
	await _send(_touch(0, true, start))
	await _send(_touch(0, false, start))
	_check(not main.selected.is_moving() and main.selected.facing_deg == face_before, "ALERT rejects touch placement")
	var original_yaw: float = view.rig.yaw_deg
	view._probe.start(view.rig)
	view.rig.yaw_deg += 20.0
	view.rig.apply_pose()
	view._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not view._probe.active and is_equal_approx(view.rig.yaw_deg, original_yaw), "background cancels probe and restores camera")
	print("PRESENTATION_INTERACTION_OK checks=" if failures == 0 else "PRESENTATION_INTERACTION_FAILED checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
