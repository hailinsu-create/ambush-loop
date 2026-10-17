extends SceneTree

## P0-2 evidence: aim magnifier at 1280×720 and 844×390 while dragging Kar toward 巷口.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var out := str(OS.get_environment("AMBUSH_UX_CAPTURE_DIR"))
	if out == "":
		out = "user://ux_aim_magnifier_capture"
	DirAccess.make_dir_recursive_absolute(out)
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	if err != OK:
		printerr("AIM_CAPTURE scene err=", err)
		quit(1)
		return
	for _i in range(260):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null:
			continue
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await process_frame
		for size_pair in [Vector2i(1280, 720), Vector2i(844, 390)]:
			var tag := "%dx%d" % [size_pair.x, size_pair.y]
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			scene._load_preset("A")
			scene._start_wait()
			await process_frame
			if scene.sim == null:
				continue
			scene.paused = true
			var map = scene.map_view
			map.reset_camera()
			map._fit_cell_px()
			await process_frame
			var op = scene.sim.operators[1] ## Kar
			var oid := str(op["id"])
			scene.selected_op_id = oid
			map.selected_op_id = oid
			var origin: Vector2 = map.cell_to_screen(float(op["x"]), float(op["y"]))
			var drag_px: float = maxf(90.0, map.cell_px * 3.0)
			var alley_ang := deg_to_rad(11.0)
			## Hold aim mid-drag so magnifier is painted.
			map.inject_input(_touch(origin, true))
			var mid := origin + Vector2(cos(alley_ang), -sin(alley_ang)) * drag_px
			map.gesture.inject_move(mid)
			map.aim_finger_screen = mid
			map.queue_redraw()
			scene.apply_layout_size(size_pair.x, size_pair.y)
			await process_frame
			await process_frame
			await process_frame
			_shot(out, "aim_magnifier_%s" % tag)
			map.inject_input(_touch(mid, false))
			await process_frame
		print("AIM_CAPTURE_DONE dir=", out, " show=", scene.map_view.aim_magnifier_show_count)
		quit(0)
		return
	printerr("AIM_CAPTURE scene not ready")
	quit(1)


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	e.index = 0
	return e


func _shot(dir: String, tag: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("AIM_CAPTURE no image for ", tag)
		return
	var scene = current_scene
	if scene != null and scene.get("layout_size_override") != null:
		var want: Vector2 = scene.layout_size_override
		if want.x > 8.0 and want.y > 8.0:
			if img.get_width() >= int(want.x) and img.get_height() >= int(want.y):
				img = img.get_region(Rect2i(0, 0, int(want.x), int(want.y)))
	var path := "%s/%s.png" % [dir, tag]
	img.save_png(path)
	print("AIM_CAPTURE wrote ", path)
