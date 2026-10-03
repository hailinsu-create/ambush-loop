extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Rig := preload("res://scripts/presentation/camera_rig_3d.gd")
const Gestures := preload("res://scripts/input/camera_input.gd")
var failures := 0
var checks := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CAMERA_INPUT: " + message)


func _touch(id: int, pressed: bool, pos: Vector2, cancelled: bool = false) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.pressed = pressed
	event.position = pos
	event.canceled = cancelled
	return event


func _drag(id: int, pos: Vector2) -> InputEventScreenDrag:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = pos
	return event


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var rig = Rig.new()
	root.add_child(rig)
	var input = Gestures.new()
	var a := Vector2(540, 350)
	var b := Vector2(740, 350)
	var result: Dictionary = input.touch(_touch(0, true, a), rig, false)
	_check(result.handled and not result.tap, "press defers tactical command")
	result = input.touch(_touch(0, false, a), rig, false)
	_check(result.tap, "single release commits one tap")
	result = input.touch(_touch(0, false, a), rig, false)
	_check(not result.tap, "duplicate release cannot repeat command")
	input.touch(_touch(1, true, a), rig, false)
	input.touch(_touch(2, true, b), rig, false)
	var yaw: float = rig.yaw_deg
	var size: float = rig.view_size
	input.touch(_drag(2, b + Vector2(70, 80)), rig, false)
	_check(not is_equal_approx(yaw, rig.yaw_deg), "two-finger twist rotates")
	_check(rig.view_size < size, "pinch outward zooms in")
	result = input.touch(_touch(2, false, b + Vector2(70, 80)), rig, false)
	_check(not result.tap, "first finger release after pinch has no command")
	input.touch(_drag(1, a + Vector2(0, 20)), rig, false)
	result = input.touch(_touch(1, false, a + Vector2(0, 20)), rig, false)
	_check(not result.tap and input.contacts.is_empty(), "remaining finger cannot become a tap")
	input.touch(_touch(0, true, a), rig, false)
	result = input.touch(_touch(0, false, a), rig, false)
	_check(result.tap, "next independent gesture may tap again")
	yaw = rig.yaw_deg
	input.touch(_touch(0, true, a), rig, false)
	input.touch(_touch(1, true, b), rig, true)
	input.touch(_drag(1, b + Vector2(50, 80)), rig, true)
	_check(is_equal_approx(yaw, rig.yaw_deg), "UI-owned finger cannot steer camera")
	result = input.touch(_touch(0, false, a), rig, false)
	_check(not result.tap, "UI second finger cancels world tap")
	input.touch(_touch(1, false, b), rig, false)
	input.touch(_touch(0, true, a), rig, true)
	result = input.touch(_touch(0, false, a), rig, false)
	_check(not result.tap, "UI-started contact cannot click world on release")
	input.touch(_touch(0, true, a), rig, false)
	result = input.touch(_touch(0, false, a), rig, true)
	_check(not result.tap and input.contacts.is_empty(), "release over UI cleans ownership without command")
	input.touch(_touch(0, true, a), rig, false)
	result = input.touch(_touch(0, false, a, true), rig, false)
	_check(not result.tap, "cancelled touch cannot commit")
	input.touch(_touch(0, true, a), rig, false)
	input.touch(_drag(0, a + Vector2(40, 0)), rig, false)
	result = input.touch(_touch(0, false, a + Vector2(40, 0)), rig, false)
	_check(not result.tap, "single drag cannot issue accidental move")
	input.touch(_touch(0, true, a), rig, false)
	input.cancel()
	result = input.touch(_touch(0, false, a), rig, false)
	_check(not result.tap, "focus loss cancels pending command")
	input.touch(_touch(0, true, a), rig, false)
	input.cancel()
	result = input.touch(_touch(1, true, b), rig, false)
	_check(not result.tap, "cancelled contact quarantines additional fingers")
	input.touch(_touch(1, false, b), rig, false)
	result = input.touch(_touch(0, false, a), rig, false)
	_check(not result.tap and input.suppressed_contacts.is_empty(), "cancelled gesture ends only after all contacts release")
	input.touch(_touch(0, true, a), rig, false)
	input.cancel(true)
	input.touch(_touch(1, true, b), rig, false)
	result = input.touch(_touch(1, false, b), rig, false)
	_check(result.tap, "background reset allows new touches when old releases were lost")
	rig.reset_view()
	var anchor: Vector3 = rig.ground_at(a)
	rig.zoom_at(a, 1.4)
	_check(anchor.distance_to(rig.ground_at(a)) < 0.001, "zoom preserves ground under pointer")
	rig.yaw_deg = 359.0
	rig.apply_pose()
	var position: Vector3 = rig.camera.position
	rig.yaw_deg += 2.0
	rig.apply_pose()
	_check(is_equal_approx(rig.yaw_deg, 1.0) and position.distance_to(rig.camera.position) < 2.0, "yaw crosses north continuously")
	rig.pitch_deg = 0.0
	rig.view_size = 1.0
	rig.apply_pose()
	_check(rig.pitch_deg == 35.0 and rig.view_size == 12.0, "near/lower limits clamp")
	rig.pitch_deg = 90.0
	rig.view_size = 100.0
	rig.apply_pose()
	_check(rig.pitch_deg == 65.0 and rig.view_size == 36.0, "far/upper limits clamp")
	rig.reset_view()
	_check(rig.focus == Vector3.ZERO and rig.view_size == 24.0 and rig.pitch_deg == 55.0, "reset restores known framing")
	print("CAMERA_INPUT_OK checks=" if failures == 0 else "CAMERA_INPUT_FAILED checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
