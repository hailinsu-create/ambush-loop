extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const OUTPUT := "res://build/asset_review/a1"


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	if DisplayServer.get_name() == "headless":
		quit(2)
		return
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	change_scene_to_file("res://scenes/presentation/asset_review.tscn")
	await process_frame
	await process_frame
	var view = current_scene
	# Fail before producing apparently successful blank evidence if import failed.
	var mesh_count := _mesh_count(view)
	if mesh_count < 40:
		push_error("ASSET_REVIEW_MISSING_MESHES count=" + str(mesh_count))
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for lighting in ["neutral", "dusk"]:
		view.set_lighting(lighting == "dusk")
		for yaw in range(0,360,45):
			view.yaw = yaw
			view.apply_pose()
			await _save("%s_%03d.png" % [lighting, yaw])
		view.yaw = 35
		view.focus = Vector3(0,0.5,1.5)
		view.size = 7
		view.apply_pose()
		await _save(lighting + "_props.png")
		view.focus = Vector3.ZERO
		view.size = 14
	view.show_roof(false)
	view.apply_pose()
	await _save("dusk_cutaway.png")
	view.show_roof(true)
	for pitch in [35,65]:
		view.pitch = pitch
		view.apply_pose()
		await _save("dusk_pitch_%d.png" % pitch)
	view.pitch = 55
	view.yaw = 35
	view.size = 18
	view.apply_pose()
	await _save("dusk_far_lod0.png")
	view.show_lod(1)
	await _save("dusk_far_lod1.png")
	print("ASSET_REVIEW_RENDER draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		" primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print("ASSET_REVIEW_CAPTURE_OK")
	# The project autoload starts its old 2D music bed even in this asset studio.
	# Detach playback before quitting a rendered run with a Dummy audio driver.
	root.get_node("AudioDirector")._stop_music_hard()
	await process_frame
	quit(0)


func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUTPUT.path_join(name))
	if result != OK:
		push_error("CAPTURE_SAVE_FAILED " + name)
		quit(1)
	print("ASSET_IMAGE ", name)


func _mesh_count(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _mesh_count(child)
	return count
