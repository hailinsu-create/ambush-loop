extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ENVIRONMENT_ASSETS: " + message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("AudioDirector").pause_for_background()
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/environment_v2/manifest.json"))
	_check(doc.assets.size() == 40 and doc.runtime_files.size() == 85 and doc.reuse_dependencies.size() == 11, "exact adoption boundary")
	_check(doc.source_commit == Assets.ENVIRONMENT_REVISION and doc.delivery_commit == "9c06f04cf7795faf69d9d69d0f853f30ccf80838", "fixed provenance")
	for row in doc.runtime_files + doc.reuse_dependencies:
		_check(_source_sha256(str(row.path)) == row.sha256, "canonical source bytes " + row.path)
	_check(not Assets.has_asset("env_ammo_can", 2) and not Assets.has_asset("env_ammo_can", -1) and not Assets.has_asset("env_ammo_can", 0, "unknown"), "bad LOD/revision refused")
	_check(not Assets.has_asset("env_../main") and not Assets.has_asset("m1_garand", 0, Assets.ENVIRONMENT_REVISION), "namespace and revision are not interchangeable")
	var material := Assets.material_for_slot("environment_v2_atlas")
	_check(material != null and material != Assets.material_for_slot("v2_shared_atlas") and material != Assets.material_for_slot("v2_actor_atlas"), "three atlas namespaces distinct")
	_check(material.normal_enabled and material.albedo_texture.resource_path.ends_with("environment_v2_albedo.png") and material.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN and material.metallic_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_BLUE, "external PBR channel binding")
	_check(Assets.material_for_slot("environment_v2_emission").emission_enabled and Assets.material_for_slot("unknown") == null, "emission explicit, unknown slots refuse")
	var studio := Node3D.new()
	root.add_child(studio)
	var world := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202833")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_energy = 0.65
	world.environment = settings
	studio.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_color = Color("c5d1e4")
	studio.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 38
	studio.add_child(camera)
	camera.current = true
	var display := Node3D.new()
	studio.add_child(display)
	for lod in [0, 1]:
		for i in doc.assets.size():
			var entry: Dictionary = doc.assets[i]
			var node := Assets.instantiate(entry.asset_id, lod, Assets.ENVIRONMENT_REVISION)
			_check(node != null, "actual imported runtime scene " + entry.asset_id)
			if node == null:
				continue
			display.add_child(node)
			node.position = Vector3((i % 8 - 3.5) * 4.5, 0, (i / 8 - 2) * 5.5)
			_check(_triangles(node) == int(entry.lods[lod].triangles), "actual triangles " + entry.asset_id)
			_check(_visual_only(node), "no gameplay physics/navigation " + entry.asset_id)
			_check(_materials(node), "actual named surfaces " + entry.asset_id)
			for key in entry.get("sockets", {}):
				var socket := node.find_child(entry.asset_id + "__socket_" + key, true, false) as Node3D
				var spec: Dictionary = entry.sockets[key]
				_check(socket != null, "actual socket " + entry.asset_id + ":" + key)
				if socket != null:
					_check(socket.get_parent().name == spec.parent_node, "socket attached to authored parent")
					_check(socket.position.distance_to(Vector3(spec.position_m[0], spec.position_m[1], spec.position_m[2])) < 0.001, "socket parent-local position")
			for key in entry.get("moving_nodes", {}):
				var spec: Dictionary = entry.moving_nodes[key]
				var pivot := node.find_child(spec.node, true, false) as Node3D
				_check(pivot != null, "real moving pivot " + entry.asset_id + ":" + key)
				if pivot != null:
					var before := node.global_transform
					if spec.motion == "rotate":
						pivot.rotation_degrees.x = 100 if spec.axis == "X" else 0
						pivot.rotation_degrees.y = 80 if spec.axis == "Y" else 0
					else:
						pivot.position.x += 0.5
					_check(node.global_transform == before, "visual child motion cannot move root")
		if DisplayServer.get_name() != "headless":
			for yaw in [35, 125, 215, 305]:
				var angle := deg_to_rad(float(yaw))
				camera.position = Vector3(sin(angle) * 50, 40, cos(angle) * 50)
				camera.look_at(Vector3(0, 0.5, 0), Vector3.UP)
				await process_frame
				await RenderingServer.frame_post_draw
				var dir := "res://build/asset_review/pr15-environment"
				DirAccess.make_dir_recursive_absolute(dir)
				_check(root.get_texture().get_image().save_png(dir.path_join("library_lod%d_yaw%d.png" % [lod, yaw])) == OK, "actual framebuffer saved")
		for child in display.get_children():
			child.free()
	for lod in [0, 1]:
		var lamp := Assets.instantiate("yard_lamp", lod)
		_check(lamp != null and _count_emissive(lamp) == 1, "frozen unnamed lamp surface binds actual emission")
		if lamp != null:
			lamp.free()
	var copy := Assets.asset_record("env_ammo_can")
	copy.lods.clear()
	_check(Assets.has_asset("env_ammo_can"), "returned catalog copy cannot mutate loader")
	studio.free()
	Assets.release_materials()
	await create_timer(0.1).timeout
	print("ENVIRONMENT_ASSETS_OK" if failures == 0 else "ENVIRONMENT_ASSETS_FAILED", " checks=", checks, " failures=", failures, " assets=40 lods=80")
	quit(0 if failures == 0 else 1)


func _source_sha256(path: String) -> String:
	var uri := "res://" + path
	var ext := path.get_extension().to_lower()
	if ext in ["cfg", "gd", "gdshader", "json", "md", "tres", "tscn", "txt"]:
		# The adoption manifest records Git-source LF bytes. core.autocrlf may
		# materialize those same tracked text assets with CRLF on Windows.
		return FileAccess.get_file_as_string(uri).replace("\r\n", "\n").sha256_text()
	return FileAccess.get_sha256(uri)


func _triangles(node: Node) -> int:
	var count: int = node.mesh.get_faces().size() / 3 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _triangles(child)
	return count


func _visual_only(node: Node) -> bool:
	if node is CollisionObject3D or node is NavigationRegion3D or node is Skeleton3D or node is AnimationPlayer:
		return false
	for child in node.get_children():
		if not _visual_only(child):
			return false
	return true


func _materials(node: Node) -> bool:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var material: Material = node.get_surface_override_material(surface)
			if material not in [Assets.material_for_slot("environment_v2_atlas"), Assets.material_for_slot("environment_v2_emission")]:
				return false
	for child in node.get_children():
		if not _materials(child):
			return false
	return true


func _count_emissive(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var material := node.get_surface_override_material(surface) as StandardMaterial3D
			if material != null and material.emission_enabled:
				count += 1
	for child in node.get_children():
		count += _count_emissive(child)
	return count
