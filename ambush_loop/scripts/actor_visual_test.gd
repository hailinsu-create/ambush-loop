extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
var checks := 0
var failures := 0
var stage: Node3D
var _rest: Array = []
var _binds: Array = []


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ACTOR_VISUAL: " + message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("AudioDirector").pause_for_background()
	stage = Node3D.new()
	root.add_child(stage)
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/actors_manifest.json"))
	_check(doc.schema == 2 and doc.source_commit == "00b270863ba5a2cd5425abf2a31e78965c72ae45" and doc.assets.size() == 22, "R3 is the sole current character/equipment catalog")
	_check(not FileAccess.file_exists("res://art/v2/static_equipment_manifest.json"), "retired R1 hashes cannot masquerade as the active catalog")
	for texture in doc.textures:
		_check(FileAccess.get_sha256("res://" + texture.path) == texture.sha256, "R3 atlas bytes match the fixed candidate")
	for entry in doc.assets:
		for lod in entry.lods.size():
			_check(FileAccess.get_sha256("res://" + entry.lods[lod].path) == entry.lods[lod].sha256, "R3 GLB exact bytes: %s/%d" % [entry.asset_id, lod])
			if entry.category == "character":
				var actor := Actor.new()
				stage.add_child(actor)
				_check(actor.set_asset(entry.asset_id, lod), "runtime loader binds actual character %s/%d" % [entry.asset_id, lod])
				if actor.skeleton != null:
					_rig_contract(actor, entry)
				actor.free()
	_check(not Assets.has_asset("enemy_heavy") and not Assets.has_asset("operator_rifle", 3), "retired identity and unsupported LOD refuse")
	await _priority_contract()
	stage.free()
	Assets.release_materials()
	root.get_node("AudioDirector")._stop_music_hard()
	await process_frame
	await create_timer(0.1).timeout
	print("ACTOR_VISUAL_OK" if failures == 0 else "ACTOR_VISUAL_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _rig_contract(actor: Node3D, entry: Dictionary) -> void:
	var skeleton: Skeleton3D = actor.skeleton
	var mesh := Actor.find_type(actor.model, "MeshInstance3D") as MeshInstance3D
	_check(skeleton.get_bone_count() == 20 and mesh.skin.get_bind_count() == 20, "actual imported skin has twenty bones/binds")
	_check(mesh.mesh.get_surface_count() == 1 and mesh.get_surface_override_material(0) == Assets.material_for_slot("v2_actor_atlas"), "character uses one surface and the shared actor material")
	_check(_visual_only(actor.model), "character cannot introduce physics/navigation")
	var rest := []
	var binds := []
	for bone in skeleton.get_bone_count():
		rest.append([skeleton.get_bone_name(bone), skeleton.get_bone_parent(bone), skeleton.get_bone_rest(bone)])
		binds.append([mesh.skin.get_bind_name(bone), mesh.skin.get_bind_bone(bone), mesh.skin.get_bind_pose(bone)])
	if _rest.is_empty():
		_rest = rest
		_binds = binds
	_check(rest == _rest and binds == _binds, "all characters and LODs retain the exact shared rest/inverse binds")
	_check(actor.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL, "animation clock belongs only to the caller")
	for clip in entry.animations:
		_check(actor.player.has_animation(clip.name) and is_equal_approx(actor.player.get_animation(clip.name).length, clip.duration), "actual imported clip name and duration %s" % clip.name)
		for phase in [0.0, 0.125, 0.5, 1.0, 2.0]:
			_check(actor.sample_pose(clip.name, float(clip.duration) * phase), "manual clip sample %s" % clip.name)
			_check(skeleton.get_bone_global_pose(skeleton.find_bone("root")).origin.length() < 0.00001, "manual animation cannot move the logical root")
			_check(actor.bone_socket("weapon_hand").position.is_finite() and actor.bone_socket("sight_eye").position.is_finite(), "actual bone sockets remain finite at clip boundaries")
	_check(not actor.sample_pose("unknown", 0.0) and not actor.sample_pose("walk", INF), "unknown clip/nonfinite time refuse without inventing a pose")


func _priority_contract() -> void:
	var actor := Actor.new()
	stage.add_child(actor)
	_check(actor.set_asset("operator_rifle", 0) and actor.mount_item("m1_garand"), "priority firearm binds to the actual hand")
	actor.position = Vector3(3, 0, 4)
	actor.rotation.y = 0.6
	var authoritative: Transform3D = actor.transform
	for action in ["idle", "walk", "run", "aim", "fire", "crouch", "crouch_walk", "hit"]:
		var duration: float = actor.player.get_animation(action).length
		for phase in [0.0, 0.25, 0.5, 0.75, 1.0]:
			actor.sample_pose(action, duration * phase)
			await process_frame
			var support: Vector3 = actor.item_socket("support_hand").transform.origin
			_check(actor.bone_socket("support_hand").position.distance_to(support) < 0.002, "R3 shared priority support remains within 2mm: %s" % action)
			_check(actor.transform == authoritative and actor.item_socket("muzzle").transform.origin.is_finite(), "pose sampling preserves caller world transform and actual muzzle")
			if action in ["aim", "fire"]:
				var forward: Vector3 = actor.equipped.global_basis * Vector3.FORWARD
				var dot: float = forward.normalized().dot((actor.global_basis * Vector3.FORWARD).normalized())
				if phase == 0.5:
					print("ACTOR_VISUAL_AIM_DIRECTION action=", action, " dot=", dot, " forward=", forward)
				_check(dot > 0.98, "aim/fire gun axis follows the authoritative ground heading")
	actor.sample_pose("walk", 0.31)
	await process_frame
	var pose := _pose(actor.skeleton)
	var muzzle: Transform3D = actor.item_socket("muzzle").transform
	await process_frame
	await process_frame
	_check(_pose(actor.skeleton) == pose and actor.item_socket("muzzle").transform == muzzle, "render frames cannot advance manual animation time")
	for lod in [1, 2, 0]:
		_check(actor.set_asset("operator_rifle", lod), "LOD replacement preserves the controller")
		await process_frame
		_check(actor.transform == authoritative and actor.sampled_action == "walk" and is_equal_approx(actor.sampled_time, 0.31), "LOD preserves authoritative root/action/time")
		_check(_pose(actor.skeleton) == pose and actor.item_socket("muzzle").transform.is_equal_approx(muzzle), "LOD preserves skeleton pose and muzzle transform")
	actor.sample_pose("fire", 99.0)
	_check(_pose(actor.skeleton) != pose, "one-shot fire clamps to terminal pose rather than old walk")
	for action in ["pickup", "deploy", "haul", "death"]:
		actor.sample_pose(action, 0.4)
		_check(not actor.equipped.visible, "fixture stows firearm for %s; not a gameplay tool event" % action)
	actor.sample_pose("aim", 0.4)
	_check(actor.equipped.visible, "resuming a firearm pose restores the mounted visual")
	_check(actor.mount_item("mine"), "R3 mine uses its real grip marker")
	actor.sample_pose("deploy", 0.63)
	await process_frame
	_check(actor.item_socket("grip").transform.origin.distance_to(actor.bone_socket("weapon_hand").position) < 0.00001, "R3 raised mine grip meets the palm without R2 hardcoding")
	_check(Assets.asset_record("operator_rifle").sockets.sight_eye.position_bone_local_m[2] == -0.106, "R3 eye coordinate is recorded, not the old -0.110")
	if DisplayServer.get_name() != "headless":
		await _capture(actor)
	actor.free()


func _capture(actor: Node3D) -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("202833")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_energy = 0.7
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	stage.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	ground.position = actor.position
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("454b4e")
	ground.material_override = material
	stage.add_child(ground)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.5
	stage.add_child(camera)
	camera.current = true
	actor.mount_item("m1_garand")
	actor.sample_pose("aim", 0.5)
	DirAccess.make_dir_recursive_absolute("res://build/asset_review/pr15-runtime")
	for pitch in [35, 65]:
		for yaw in range(0, 360, 45):
			var y := deg_to_rad(float(yaw))
			var p := deg_to_rad(float(pitch))
			var target := actor.position + Vector3(0, 0.9, 0)
			camera.position = target + Vector3(sin(y) * cos(p), sin(p), cos(y) * cos(p)) * 8.0
			camera.look_at(target, Vector3.UP)
			await process_frame
			await RenderingServer.frame_post_draw
			var path := "res://build/asset_review/pr15-runtime/r3_priority_yaw%03d_pitch%d.png" % [yaw, pitch]
			_check(root.get_texture().get_image().save_png(path) == OK, "runtime controller fixture screenshot saves")
			print("ACTOR_VISUAL_CAPTURE ", path)


func _pose(skeleton: Skeleton3D) -> Array:
	var result := []
	for i in skeleton.get_bone_count():
		result.append(skeleton.get_bone_pose(i))
	return result


func _visual_only(node: Node) -> bool:
	if node is CollisionObject3D or node is NavigationRegion3D:
		return false
	for child in node.get_children():
		if not _visual_only(child):
			return false
	return true
