extends SceneTree

## Evidence shots: setup / wait / scout / result at 1280×720 and 844×390.

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
	for _i in range(260):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null:
			continue
		if scene.scout == null and scene.ui_phase != scene.UiPhase.SETUP:
			continue

		## Keep a large window buffer; chrome is laid out in logical coords then cropped.
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await process_frame
		for size_pair in [Vector2i(1280, 720), Vector2i(844, 390)]:
			var tag := "%dx%d" % [size_pair.x, size_pair.y]
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			await process_frame
			await process_frame

			# Scout
			if scene.ui_phase != scene.UiPhase.SCOUT or scene.scout == null:
				scene._start_scout_phase()
				await process_frame
			var oid := str(scene.scout.operators[0]["id"])
			scene.selected_op_id = oid
			scene.map_view.selected_op_id = oid
			var goal := Vector2i(11, 2)
			if not scene.grid.walkable(goal.x, goal.y):
				goal = Vector2i(10, 2)
			scene._scout_hover_from_mouse = false
			scene._set_scout_preview(goal)
			scene._push_map_snapshot()
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			await process_frame
			_shot(out, "scout_%s" % tag)

			# Setup
			scene.begin_setup_from_scout()
			await process_frame
			scene._load_preset("A")
			scene._on_tool_chip("mine")
			scene._update_legal_highlights()
			scene._push_map_snapshot()
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			await process_frame
			_shot(out, "setup_%s" % tag)

			# Wait
			scene._start_wait()
			await process_frame
			if scene.sim:
				scene.paused = true
			scene._push_map_snapshot()
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			await process_frame
			_shot(out, "wait_%s" % tag)

			# Result
			scene._set_ui_phase(scene.UiPhase.RESULT)
			if scene.outcome_label:
				scene.outcome_label.text = "全歼"
			if scene.grade_label:
				scene.grade_label.text = "S"
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			await process_frame
			_shot(out, "result_%s" % tag)

			# Reset to scout for next size via fresh scene state.
			scene._start_scout_phase()
			await process_frame

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
	var scene = current_scene
	if scene != null and scene.get("layout_size_override") != null:
		var want: Vector2 = scene.layout_size_override
		if want.x > 8.0 and want.y > 8.0:
			## Chrome is painted in logical coords at top-left; crop from a larger buffer.
			if img.get_width() >= int(want.x) and img.get_height() >= int(want.y):
				img = img.get_region(Rect2i(0, 0, int(want.x), int(want.y)))
			else:
				printerr("UX_CAPTURE buffer too small for ", tag, " got=", img.get_width(), "x", img.get_height())
	var path := "%s/%s.png" % [dir, tag]
	img.save_png(path)
	print("UX_CAPTURE ", path, " ", img.get_width(), "x", img.get_height())
