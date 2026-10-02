extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
const Geometry := preload("res://scripts/presentation/graybox_geometry.gd")
var checks := 0
var failures := 0
var studio: Node3D
var camera: Camera3D


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ASSET_LIBRARY: " + message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/static_equipment_manifest.json"))
	_check(doc.assets.size() == 15 and doc.source_commit == "0242c983e8ae972b58b4f7afe9d08084b8f421c6", "static subset has frozen provenance")
	_check(not Assets.has_asset("operator_rifle") and not Assets.has_asset("enemy_heavy"), "unaccepted characters are outside the runtime catalog")
	_check(not Assets.has_asset("../main") and not Assets.has_asset("m1_garand", 2) and not Assets.has_asset("m1_garand", -1), "unknown paths and unsupported LODs are refused")
	var actor := Assets.material_for_slot("v2_actor_atlas")
	var yard := Assets.material_for_slot("")
	_check(actor != yard and yard == Assets.material_for_slot("v2_shared_atlas"), "actor atlas and legacy unnamed yard slots remain distinct")
	_check(Assets.material_for_slot("v2_lamp_emission").emission_enabled and Assets.material_for_slot("unknown") == null, "emission is routed explicitly and unknown slots have no fallback")
	_check(is_equal_approx(actor.normal_scale, 0.4) and actor.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN and actor.metallic_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_BLUE, "actor normal and ORM channels match the contract")
	_check(actor.metallic_texture == actor.roughness_texture and actor.albedo_texture.resource_path.ends_with("actor_atlas_albedo.png"), "actor textures are shared external resources")
	for tex in doc.textures:
		_check(FileAccess.get_sha256("res://" + tex.path) == tex.sha256, "migrated texture has the exact candidate bytes")
	studio = Node3D.new()
	root.add_child(studio)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202833")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b6c5de")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	studio.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_color = Color("c5d1e4")
	sun.shadow_enabled = true
	studio.add_child(sun)
	Geometry.box(studio, Vector3(15, 0.1, 10), Vector3(0, -0.1, 0), Geometry.material(Color("535b5c")))
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12
	studio.add_child(camera)
	camera.current = true
	var display := Node3D.new()
	studio.add_child(display)
	for lod in [0, 1]:
		for i in doc.assets.size():
			var entry: Dictionary = doc.assets[i]
			_check(FileAccess.get_sha256("res://" + entry.lods[lod].path) == entry.lods[lod].sha256, "GLB bytes match the fixed candidate")
			var node := Assets.instantiate(entry.asset_id, lod)
			_check(node != null, "registered equipment imports through the runtime loader")
			if node == null:
				continue
			display.add_child(node)
			node.position = Vector3((i % 5 - 2) * 2.4, 0.05, (i / 5 - 1) * 2.7)
			_check(_triangles(node) == int(entry.lods[lod].triangles), "engine geometry matches the binary triangle count")
			_check(_materials(node, actor), "every migrated surface uses the shared actor material")
			_check(_visual_only(node), "static models cannot add collision or navigation")
			for socket in entry.get("sockets", {}):
				if entry.sockets[socket] != null:
					_check(node.find_child(entry.asset_id + "__socket_" + socket, true, false) != null, "engine preserves the authored socket marker")
		var copy := Assets.asset_record("m1_garand")
		copy.lods.clear()
		_check(Assets.has_asset("m1_garand"), "caller metadata cannot mutate the accepted catalog")
		if DisplayServer.get_name() != "headless":
			for pitch in [35, 65]:
				for yaw in range(0, 360, 45):
					var y := deg_to_rad(float(yaw))
					var p := deg_to_rad(float(pitch))
					camera.position = Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * 25.0
					camera.look_at(Vector3.ZERO, Vector3.UP)
					await process_frame
					await RenderingServer.frame_post_draw
					var dir := "res://build/asset_review/pr15-static-equipment"
					DirAccess.make_dir_recursive_absolute(dir)
					var path := dir.path_join("lod%d_pitch%d_yaw%03d.png" % [lod, pitch, yaw])
					_check(root.get_texture().get_image().save_png(path) == OK, "equipment library render saved")
		for child in display.get_children():
			child.free()
	# Ensure the expanded loader preserves actual imported yard geometry/materials.
	for id in ["supply_crate", "yard_lamp", "warehouse_fragment"]:
		var node := Assets.instantiate(id, 1)
		_check(node != null and _triangles(node) > 0 and _yard_materials(node, yard), "old yard imports retain their atlas and emission mapping")
		if node != null:
			node.free()
	root.get_node("AudioDirector")._stop_music_hard()
	studio.free()
	Assets.release_materials()
	await process_frame
	print("ASSET_LIBRARY_OK" if failures == 0 else "ASSET_LIBRARY_FAILED", " checks=", checks, " failures=", failures, " assets=15 lods=30")
	quit(0 if failures == 0 else 1)


func _triangles(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		count = node.mesh.get_faces().size() / 3
	for child in node.get_children():
		count += _triangles(child)
	return count


func _materials(node: Node, shared: Material) -> bool:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			if node.get_surface_override_material(surface) != shared:
				return false
	for child in node.get_children():
		if not _materials(child, shared):
			return false
	return true


func _yard_materials(node: Node, shared: Material) -> bool:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_surface_override_material(surface)
			if material != shared and material != Assets.material_for_slot("v2_lamp_emission"):
				return false
	for child in node.get_children():
		if not _yard_materials(child, shared):
			return false
	return true


func _visual_only(node: Node) -> bool:
	if node is CollisionObject3D or node is NavigationRegion3D:
		return false
	for child in node.get_children():
		if not _visual_only(child):
			return false
	return true
