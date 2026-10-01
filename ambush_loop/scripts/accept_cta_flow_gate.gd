extends SceneTree

## Exercises the real title -> mission select -> briefing -> Accept signal path.
## This verifies the GDScript callback and scene transition, not Android touch delivery.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var err := change_scene_to_file("res://scenes/title.tscn")
	if err != OK:
		_fail("ACCEPT_GATE_TITLE_LOAD err=%s" % err, 1)
		return
	await _frames(12)
	var title = current_scene
	if title == null or not title.has_method("mission_select_visible"):
		_fail("ACCEPT_GATE_NO_TITLE")
		return

	title._on_start()
	await _frames(2)
	if not bool(title.mission_select_visible()) or int(title.mission_row_count()) < 1:
		_fail("ACCEPT_GATE_NO_MISSION_SELECT")
		return
	title._on_mission_picked(0)
	await _frames(4)
	if not bool(title.briefing_visible()) or str(title.pending_mission_id()) != "yard":
		_fail("ACCEPT_GATE_NO_YARD_BRIEFING id=%s" % title.pending_mission_id())
		return

	var accept := title.get("_brief_go") as Button
	if accept == null or not accept.is_visible_in_tree() or accept.disabled:
		_fail("ACCEPT_GATE_CTA_NOT_INTERACTIVE")
		return
	accept.pressed.emit()

	var transition_frames := 0
	for frame in 120:
		await process_frame
		transition_frames = frame + 1
		if current_scene != title:
			break
	if current_scene == title:
		_fail("ACCEPT_GATE_NO_SCENE_TRANSITION")
		return
	var main = current_scene
	var level = main.get("level") if main != null else null
	if level == null or str(level.level_id) != "yard":
		_fail("ACCEPT_GATE_WRONG_SCENE level=%s" % (level.level_id if level else "null"))
		return
	print("ACCEPT_CTA_FLOW_OK level=yard frames=%d" % transition_frames)
	quit(0)


func _frames(count: int) -> void:
	for frame in count:
		await process_frame


func _fail(message: String, code: int = 2) -> void:
	push_error(message)
	quit(code)
