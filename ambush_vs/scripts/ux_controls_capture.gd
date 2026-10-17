extends SceneTree

## One-shot evidence shots for PLAY-UX controls (setup toolbar, re-aim ghost, phone layout).

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
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	if err != OK:
		printerr("UX_CAPTURE scene err=", err)
		quit(1)
		return
	for _i in range(180):
		await process_frame
		var scene = current_scene
		if scene == null or scene.map_view == null or scene.plan.is_empty():
			continue
		DisplayServer.window_set_size(Vector2i(1280, 720))
		await process_frame
		await process_frame
		# 1) Setup + toolbar + legal highlights (mine tool).
		scene._on_tool_chip("mine")
		scene._update_legal_highlights()
		scene._push_map_snapshot()
		await process_frame
		await process_frame
		_shot(out, "setup_toolbar_highlights")
		# 2) Wait re-aim ghost cone.
		scene._load_preset("A")
		scene._start_wait()
		await process_frame
		scene.paused = true
		var map = scene.map_view
		var op = scene.sim.operators[1]
		var oid := str(op["id"])
		scene.selected_op_id = oid
		map.selected_op_id = oid
		var origin: Vector2 = map.cell_to_screen(float(op["x"]), float(op["y"]))
		var facing0 := float(op["facing_deg"])
		map.inject_input(_touch(origin, true))
		var ang := deg_to_rad(facing0 + 70.0)
		var p := origin + Vector2(cos(ang), -sin(ang)) * 90.0
		map.gesture.inject_move(p)
		map.aim_preview_op = oid
		map.aim_preview_deg = facing0 + 70.0
		map.queue_redraw()
		scene._push_map_snapshot()
		await process_frame
		await process_frame
		_shot(out, "wait_reaim_ghost")
		map.inject_input(_touch(origin + Vector2(5, 0), false)) ## cancel
		# 3) Phone-size layout 844×390.
		DisplayServer.window_set_size(Vector2i(844, 390))
		await process_frame
		await process_frame
		await process_frame
		scene._set_ui_phase(scene.UiPhase.SETUP)
		scene._on_tool_chip("op")
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


func _touch(pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	e.index = 0
	return e


func _shot(dir: String, tag: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img == null:
		printerr("UX_CAPTURE no image for ", tag)
		return
	var path := "%s/%s.png" % [dir, tag]
	img.save_png(path)
	print("UX_CAPTURE ", path)
