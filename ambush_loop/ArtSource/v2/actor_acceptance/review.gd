extends SceneTree

# Asset-only review. No live World, replay or combat state is instantiated.
var out := OS.get_environment("ACTOR_REVIEW_OUTPUT")
var fixture: Node3D
var camera: Camera3D
var material: StandardMaterial3D
var records: Array = []
var actors: Array = []
var failures: Array = []
var stage: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func descendants(n: Node, type: String) -> Array:
	var result: Array = []
	if n.is_class(type): result.append(n)
	for child in n.get_children(): result.append_array(descendants(child, type))
	return result

func apply_material(n: Node) -> void:
	for m in descendants(n, "MeshInstance3D"):
		for i in m.mesh.get_surface_count():
			var original: Material = m.mesh.surface_get_material(i)
			check(original != null and original.resource_name == "v2_actor_atlas", "material slot: " + n.name)
			m.set_surface_override_material(i, material)

func load_asset(id: String, lod: int) -> Node3D:
	var packed = load("res://art/v2/models/%s_lod%d.glb" % [id, lod]) as PackedScene
	check(packed != null, "load: %s lod%d" % [id, lod])
	var n := packed.instantiate() as Node3D
	stage.add_child(n)
	apply_material(n)
	return n

func rig(n: Node) -> Skeleton3D:
	var all := descendants(n, "Skeleton3D")
	return all[0] if not all.is_empty() else null

func player(n: Node) -> AnimationPlayer:
	var all := descendants(n, "AnimationPlayer")
	return all[0] if not all.is_empty() else null

func mount(n: Node3D, id: String, lod: int) -> Node3D:
	var gun := load_asset(id, mini(lod, 1))
	stage.remove_child(gun)
	var sk := rig(n)
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "hand.R"
	sk.add_child(attachment)
	attachment.add_child(gun)
	gun.transform = Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0, 0.035, 0))
	return gun

func mount_tool(n: Node3D, asset: Dictionary, lod: int) -> Node3D:
	var tool := mount(n, asset.asset_id, lod)
	var grip := Vector3(float(asset.sockets.grip[0]),float(asset.sockets.grip[1]),float(asset.sockets.grip[2]))
	tool.position -= tool.basis * grip
	return tool

func pose(n: Node3D, clip: String, phase: float) -> void:
	var ap := player(n)
	check(ap != null and ap.has_animation(clip), "clip: " + clip)
	ap.play(clip)
	ap.seek(ap.get_animation(clip).length * phase, true)
	ap.pause()
	rig(n).force_update_all_bone_transforms()

func clear_stage() -> void:
	for child in stage.get_children(): child.queue_free()
	actors.clear()
	await process_frame

func look(yaw: float, pitch: float, size: float, target: Vector3) -> void:
	var direction := Vector3(sin(deg_to_rad(yaw)) * cos(deg_to_rad(pitch)), sin(deg_to_rad(pitch)), cos(deg_to_rad(yaw)) * cos(deg_to_rad(pitch)))
	camera.position = target + direction * 14.0
	camera.look_at(target, Vector3.UP)
	camera.size = size

func capture(name: String, context: Dictionary) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	check(image.save_png(out.path_join(name + ".png")) == OK, "save: " + name)
	context["image"] = name + ".png"
	context["draw_calls"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	context["primitives"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	records.append(context)

func run() -> void:
	check(not out.is_empty(), "ACTOR_REVIEW_OUTPUT required")
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280, 720)
	fixture = Node3D.new(); root.add_child(fixture)
	stage = Node3D.new(); fixture.add_child(stage)
	material = StandardMaterial3D.new()
	material.albedo_texture = load("res://art/v2/textures/actor_atlas_albedo.png")
	material.normal_enabled = true
	material.normal_texture = load("res://art/v2/textures/actor_atlas_normal.png")
	material.normal_scale = 0.4
	material.roughness_texture = load("res://art/v2/textures/actor_atlas_orm.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture = material.roughness_texture
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	material.metallic = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var env := WorldEnvironment.new(); fixture.add_child(env)
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("25303d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("c6d4e5")
	env.environment.ambient_light_energy = 0.65
	var light := DirectionalLight3D.new(); fixture.add_child(light)
	light.rotation_degrees = Vector3(-50, -30, 0); light.light_energy = 1.9
	light.shadow_enabled = true
	var fill := DirectionalLight3D.new(); fixture.add_child(fill)
	fill.rotation_degrees = Vector3(-25, 145, 0); fill.light_energy = 0.7
	var ground := MeshInstance3D.new(); fixture.add_child(ground)
	var plane := PlaneMesh.new(); plane.size = Vector2(40, 40); ground.mesh = plane
	var ground_mat := StandardMaterial3D.new(); ground_mat.albedo_color = Color("49545a"); ground.material_override = ground_mat
	camera = Camera3D.new(); fixture.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.current = true
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/actors_manifest.json"))
	var imported: Array = []
	var rest_reference: Array = []
	for asset in manifest.assets:
		for level in asset.lods.size():
			var n := load_asset(asset.asset_id, level)
			var meshes := descendants(n, "MeshInstance3D")
			check(meshes.size() == 1, "one mesh: " + asset.asset_id)
			var row := {"asset": asset.asset_id, "lod": level, "surfaces": meshes[0].mesh.get_surface_count()}
			if asset.category == "character":
				var sk := rig(n); var ap := player(n)
				check(sk != null and sk.get_bone_count() == 20, "20 bones: " + asset.asset_id)
				check(meshes[0].skin != null and meshes[0].skin.get_bind_count() == 20, "20 binds: " + asset.asset_id)
				var rest: Array = []
				for i in sk.get_bone_count():
					rest.append([sk.get_bone_name(i), sk.get_bone_parent(i), sk.get_bone_rest(i)])
				if rest_reference.is_empty(): rest_reference = rest
				check(rest == rest_reference, "shared rest: " + asset.asset_id)
				row["bones"] = sk.get_bone_count(); row["clips"] = []
				for clip in asset.animations:
					check(ap.has_animation(clip.name), "import animation: " + clip.name)
					var anim := ap.get_animation(clip.name)
					# glTF cannot store looping; review applies the explicit contract.
					anim.loop_mode = Animation.LOOP_LINEAR if clip.loop else Animation.LOOP_NONE
					for sample in 25:
						pose(n, clip.name, sample / 24.0)
						var bone_root := sk.get_bone_global_pose(sk.find_bone("root"))
						check(bone_root.origin.length() < 0.00001, "root motion: " + clip.name)
						check(sk.get_bone_global_pose(sk.find_bone("hand.R")).origin.is_finite(), "hand finite: " + clip.name)
					row.clips.append({"name":clip.name,"length":anim.length,"tracks":anim.get_track_count(),"samples":25})
			else:
				check(rig(n) == null, "static asset: " + asset.asset_id)
			imported.append(row)
			await clear_stage()
	# Priority rifleman / normalenemy / firstrifle. Eight angles x three LODs.
	for level in 3:
		var op := load_asset("operator_rifle", level); op.position.x = -0.85
		var enemy := load_asset("enemy_patrol", level); enemy.position.x = 0.85
		mount(op, "m1_garand", level); mount(enemy, "kar98k", level)
		pose(op, "aim", 0.5); pose(enemy, "aim", 0.5)
		for angle in 8:
			look(angle * 45, 35, 4.6, Vector3(0, 0.9, 0))
			await capture("priority_lod%d_yaw%03d" % [level, angle*45], {"lod":level,"yaw":angle*45,"pitch":35,"clip":"aim"})
		await clear_stage()
		# Same imported priority meshes under dusk lighting, all azimuths.
		if level == 0:
			light.light_color = Color("89a9cf"); light.light_energy = 0.65
			fill.light_color = Color("ffbc77"); fill.light_energy = 1.1
			var dusk_op := load_asset("operator_rifle", level); dusk_op.position.x = -0.85
			var dusk_enemy := load_asset("enemy_patrol", level); dusk_enemy.position.x = 0.85
			mount(dusk_op, "m1_garand", level); mount(dusk_enemy,"kar98k",level)
			pose(dusk_op,"aim",0.5); pose(dusk_enemy,"aim",0.5)
			for angle in 8:
				look(angle*45,65,4.6,Vector3(0,0.9,0))
				await capture("dusk_yaw%03d" % [angle*45],{"lighting":"dusk","yaw":angle*45,"pitch":65})
			await clear_stage()
			light.light_color = Color.WHITE; light.light_energy = 1.9
			fill.light_color = Color.WHITE; fill.light_energy = 0.7
	# All claimed clips, five temporal samples, priority pair including actual guns.
	for clip in manifest.assets[0].animations:
		for sample in 25:
			var op := load_asset("operator_rifle", 0); op.position.x = -0.85
			var enemy := load_asset("enemy_patrol", 0); enemy.position.x = 0.85
			var gun := mount(op, "m1_garand", 0); var enemy_gun := mount(enemy, "kar98k", 0)
			var holds_gun: bool = clip.name not in ["haul", "pickup", "deploy", "death"]
			gun.visible = holds_gun; enemy_gun.visible = holds_gun
			pose(op, clip.name, sample / 24.0); pose(enemy, clip.name, sample / 24.0)
			await process_frame
			var sk := rig(op)
			var left := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand.L")) * Vector3(0,0.035,0)
			var support := gun.global_transform * Vector3(0,0,-0.26)
			var error := left.distance_to(support)
			var eye := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("head")) * Vector3(0.037,0.139,-0.110)
			var sight := gun.global_transform * Vector3(0,0.077,-0.055)
			var direction := -gun.global_basis.z.normalized()
			var sight_error := (eye-sight-direction*(eye-sight).dot(direction)).length()
			if clip.name in ["aim","fire"]:
				check(sight_error < 0.035,"priority sight line: %s %d error=%f" % [clip.name,sample,sight_error])
			if holds_gun:
				check(error < 0.04, "support grip: %s %d error=%f" % [clip.name,sample,error])
			look(130, 35, 4.6, Vector3(0,0.85,0))
			await capture("pose_%s_%02d" % [clip.name,sample],{"clip":clip.name,"phase":sample/24.0,"support_error_m":error,"eye_to_sight_line_m":sight_error,"holds_gun":holds_gun})
			await clear_stage()
	# All candidates, near and far incl. 65 degree pitch. Keep floor readable.
	for level in 3:
		for index in 7:
			var asset = manifest.assets[index]
			var n := load_asset(asset.asset_id, level); n.position.x = (index-3)*1.4
			pose(n, "walk", 0.25)
		for angle in 8:
			look(angle*45, 65, 11, Vector3(0,0.8,0))
			await capture("characters_lod%d_yaw%03d" % [level,angle*45],{"lod":level,"yaw":angle*45,"pitch":65})
		look(0, 50, 24, Vector3(0,0.8,0))
		await capture("characters_far_lod%d" % level,{"lod":level,"pitch":50,"camera_size_m":24})
		await clear_stage()
	# Asset fit samples. Runtime pickup/release/stow events are outside this fixture.
	var tool_clips := {"knife":"idle","grenade":"pickup","mine":"deploy","decoy":"idle","ammo_pack":"haul"}
	for level in 2:
		for asset in manifest.assets:
			if asset.category != "tool": continue
			for sample in 5:
				var subject := load_asset("operator_rifle",level)
				var item := mount_tool(subject,asset,level)
				var clip: String = tool_clips[asset.asset_id]
				pose(subject,clip,sample/4.0)
				await process_frame
				var sk := rig(subject)
				var wrist := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand.R")) * Vector3(0,0.035,0)
				var marker := item.find_child(asset.asset_id+"__socket_grip",true,false) as Node3D
				check(marker != null,"tool grip marker: "+asset.asset_id)
				var grip_error := marker.global_position.distance_to(wrist) if marker != null else INF
				check(grip_error < 0.0001,"tool grip fit: "+asset.asset_id)
				var support_error := 0.0
				if asset.asset_id == "ammo_pack":
					var support := item.find_child("ammo_pack__socket_support_hand",true,false) as Node3D
					var left := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand.L")) * Vector3(0,0.035,0)
					support_error = support.global_position.distance_to(left)
					check(support_error < 0.02,"ammo pack support fit")
				if sample == 2 and asset.asset_id in ["mine","grenade"]:
					check(abs(item.global_position.y)<0.015,"tool ground contact: "+asset.asset_id)
				look(130,35,3.4,Vector3(0,0.65,0))
				await capture("tool_%s_lod%d_%02d" % [asset.asset_id,level,sample],{"asset":asset.asset_id,"clip":clip,"phase":sample/4.0,"lod":level,"grip_error_m":grip_error,"support_error_m":support_error,"ground_origin_y_m":item.global_position.y,"scope":"fit only; no runtime events"})
				await clear_stage()
	# Every character/LOD in every declared action at its middle sample.
	for level in 3:
		for clip in manifest.assets[0].animations:
			for index in 7:
				var n := load_asset(manifest.assets[index].asset_id,level)
				n.position.x = (index-3)*1.4; pose(n,clip.name,0.5)
			look(135,35,11,Vector3(0,0.8,0))
			await capture("all_%s_lod%d" % [clip.name,level],{"clip":clip.name,"lod":level,"phase":0.5})
			await clear_stage()
	for level in 2:
		for index in 15:
			var asset = manifest.assets[index+7]
			var n := load_asset(asset.asset_id, level)
			n.position = Vector3((index%5-2)*1.65, 0.45, -floori(index/5.0)*1.55)
		for angle in 8:
			look(angle*45, 65, 9, Vector3(0,0,-1.55))
			await capture("equipment_lod%d_yaw%03d" % [level,angle*45],{"lod":level,"yaw":angle*45,"pitch":65})
		await clear_stage()
	# Reference asset load (3 operators + 13 enemies + guns), no gameplay claim.
	for i in 16:
		var n := load_asset("operator_rifle" if i<3 else "enemy_patrol",0 if i<3 else 1)
		n.position = Vector3((i%8-3.5)*1.3,0,-floori(i/8.0)*2)
		mount(n,"m1_garand" if i<3 else "kar98k",0 if i<3 else 1);pose(n,"aim",0.5)
	look(0,50,13,Vector3(0,.8,-1))
	await capture("reference_16_actor_load",{"scenario":"asset fixture: 3 hero LOD0 + 13 enemy LOD1 + 16 guns"})
	await clear_stage()
	# Pause and 2x only exercise AnimationPlayer, not game simulation.
	var subject := load_asset("operator_rifle", 0); var ap := player(subject)
	pose(subject,"walk",0.25)
	var paused := rig(subject).get_bone_global_pose(0)
	for i in 5: await process_frame
	check(paused == rig(subject).get_bone_global_pose(0), "paused pose drift")
	ap.speed_scale = 2; ap.play("walk"); ap.advance(0.1); ap.pause()
	var doubled := ap.current_animation_position
	check(abs(doubled - 0.425) < 0.001, "2x animation advance")
	await clear_stage()
	FileAccess.open(out.path_join("engine-report.json"), FileAccess.WRITE).store_string(JSON.stringify({"version":Engine.get_version_info(),"imported":imported,"captures":records,"failures":failures,"pause_2x":"fixture only"},"\t"))
	print("ACTOR_ENGINE_REVIEW assets=22 lods=51 captures=",records.size()," failures=",failures.size())
	# Release autoload playback before Dummy audio shutdown.
	var audio := root.get_node_or_null("AudioDirector")
	if audio != null:
		for stream in descendants(audio,"AudioStreamPlayer"): stream.stop()
	quit(0 if failures.is_empty() else 1)
