extends SceneTree

## Evidence shots for PLAY-UX controls (path preview, zoom, info card, phone).

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var out := str(OS.get_environment("AMBUSH_UX_CAPTURE_DIR"))
	if out == "":
		out = "user://ux_controls_capture"
	DirAccess.make_dir_recursive_absolute(out)
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	if err != OK:
		printerr("UX_CAPTURE scene err=", err)
		quit(1)
		return
	for _i in range(240):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null:
			continue
		if scene.scout == null and scene.ui_phase != scene.UiPhase.SETUP:
			continue
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await process_frame
		# 1) Scout path preview.
		if scene.scout != null and scene.ui_phase == scene.UiPhase.SCOUT:
			var oid := str(scene.scout.operators[0]["id"])
			scene.selected_op_id = oid
			scene.map_view.selected_op_id = oid
			var goal := Vector2i(11, 2)
			if not scene.grid.walkable(goal.x, goal.y):
				goal = Vector2i(10, 2)
			scene._scout_hover_from_mouse = false
			scene._set_scout_preview(goal)
			scene._push_map_snapshot()
			await process_frame
			await process_frame
			_shot(out, "scout_path_preview")
			scene.begin_setup_from_scout()
			await process_frame
		elif scene.ui_phase != scene.UiPhase.SETUP:
			OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
			change_scene_to_file("res://scenes/greybox.tscn")
			continue
		# 2) Zoomed-in view.
		scene._load_preset("A")
		scene.map_view.set_camera(2.0, Vector2(80, 60))
		scene._push_map_snapshot()
		await process_frame
		await process_frame
		_shot(out, "zoomed_in_view")
		# 3) Info card.
		scene.map_view.reset_camera()
		scene._show_info_card_at(Vector2i(5, 9))
		scene._push_map_snapshot()
		await process_frame
		await process_frame
		_shot(out, "info_card")
		scene._hide_info_card()
		# 4) Phone 844×390.
		DisplayServer.window_set_size(Vector2i(844, 390))
		await process_frame
		await process_frame
		scene._on_tool_chip("mine")
		scene._update_legal_highlights()
		scene._push_map_snapshot()
		await process_frame
		await process_frame
		_shot(out, "phone_844x390")
		print("UX_CAPTURE_DONE dir=", out)
		quit(0)
		return
	printerr("UX_CAPTURE scene not ready")
	quit(1)


func _shot(dir: String, tag: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("UX_CAPTURE no image for ", tag)
		return
	var path := "%s/%s.png" % [dir, tag]
	img.save_png(path)
	print("UX_CAPTURE ", path)
