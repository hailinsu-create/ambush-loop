extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const OUTPUT := "res://build/asset_review/a0"


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	if DisplayServer.get_name() == "headless":
		push_error("CAPTURE_REQUIRES_RENDERED_RUN")
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(true)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	await create_timer(1.0).timeout
	var view = main.presentation_3d
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for yaw in range(0, 360, 45):
		view.rig.yaw_deg = yaw
		view.rig.apply_pose()
		view.refresh()
		await _save("yard_yaw_%03d.png" % yaw)
	for pitch in [35, 65]:
		view.rig.yaw_deg = 35
		view.rig.pitch_deg = pitch
		view.rig.apply_pose()
		view.refresh()
		await _save("yard_pitch_%d.png" % pitch)
	view.rig.reset_view()
	view.refresh()
	await _save("yard_default.png")
	print("PRESENTATION_RENDER renderer=", RenderingServer.get_video_adapter_name(),
		" draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	# Actual running combat with a continuously rotating camera for video capture.
	main.raid_force_alarm()
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < 12000:
		view.rig.yaw_deg = 35.0 + float(Time.get_ticks_msec() - start) * 0.03
		view.rig.apply_pose()
		await process_frame
	view.refresh()
	await _save("yard_alert.png")
	print("PRESENTATION_CAPTURE_OK output=", ProjectSettings.globalize_path(OUTPUT))
	quit(0)


func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png(OUTPUT.path_join(name))
	if result != OK:
		push_error("CAPTURE_SAVE_FAILED " + name)
		quit(1)
	print("CAPTURE_IMAGE ", name)
