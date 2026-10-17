extends SceneTree

## P0-3 evidence: opening briefing at 1280×720 and 844×390.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var out := str(OS.get_environment("AMBUSH_UX_CAPTURE_DIR"))
	if out == "":
		out = "user://ux_briefing_capture"
	DirAccess.make_dir_recursive_absolute(out)
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_BRIEF", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	if err != OK:
		printerr("BRIEF_CAPTURE scene err=", err)
		quit(1)
		return
	for _i in range(280):
		await process_frame
		var scene = current_scene
		if scene == null or scene.briefing_card == null:
			continue
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await process_frame
		for size_pair in [Vector2i(1280, 720), Vector2i(844, 390)]:
			var tag := "%dx%d" % [size_pair.x, size_pair.y]
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			scene._show_briefing_card()
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			await process_frame
			await process_frame
			_shot(out, "briefing_%s" % tag)
		print("BRIEF_CAPTURE_DONE dir=", out, " show=", scene.briefing_show_count)
		quit(0)
		return
	printerr("BRIEF_CAPTURE scene not ready")
	quit(1)


func _shot(dir: String, tag: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("BRIEF_CAPTURE no image for ", tag)
		return
	var scene = current_scene
	if scene != null and scene.get("layout_size_override") != null:
		var want: Vector2 = scene.layout_size_override
		if want.x > 8.0 and want.y > 8.0:
			if img.get_width() >= int(want.x) and img.get_height() >= int(want.y):
				img = img.get_region(Rect2i(0, 0, int(want.x), int(want.y)))
	var path := "%s/%s.png" % [dir, tag]
	img.save_png(path)
	print("BRIEF_CAPTURE wrote ", path)
