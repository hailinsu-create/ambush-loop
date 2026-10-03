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
	var start := Vector2(640, 350)
	var second := Vector2(800, 350)
	await _send(_touch(0, true, start))
	await _send(_touch(1, true, second))
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
