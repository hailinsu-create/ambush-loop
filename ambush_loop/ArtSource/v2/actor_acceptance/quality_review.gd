extends "res://base_review.gd"

# Same cameras/lights for old and new GLBs. Asset study, no game state.
var context: Node3D

func textured_atlas(prefix: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://art/v2/textures/%s_atlas_albedo.png" % prefix)
	mat.normal_enabled = true
	mat.normal_texture = load("res://art/v2/textures/%s_atlas_normal.png" % prefix)
	mat.normal_scale = 0.4
	mat.roughness_texture = load("res://art/v2/textures/%s_atlas_orm.png" % prefix)
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.metallic_texture = mat.roughness_texture
	mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	mat.metallic = 1.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat

func yard(id: String, at: Vector3, mat: Material) -> Node3D:
	var packed := load("res://art/v2/models/%s_lod0.glb" % id) as PackedScene
	check(packed != null,"context load: "+id)
	var n := packed.instantiate() as Node3D;context.add_child(n);n.position=at
	for m in descendants(n,"MeshInstance3D"):
		for i in m.mesh.get_surface_count():m.set_surface_override_material(i,mat)
	return n

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1280,720)
	fixture=Node3D.new();root.add_child(fixture);stage=Node3D.new();fixture.add_child(stage)
	material=textured_atlas("actor")
	var env := WorldEnvironment.new();fixture.add_child(env);env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("25303d")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("c6d4e5");env.environment.ambient_light_energy=0.65
	var sun := DirectionalLight3D.new();fixture.add_child(sun);sun.rotation_degrees=Vector3(-50,-30,0);sun.light_energy=1.9;sun.shadow_enabled=true
	var fill := DirectionalLight3D.new();fixture.add_child(fill);fill.rotation_degrees=Vector3(-25,145,0);fill.light_energy=0.7
	var ground := MeshInstance3D.new();fixture.add_child(ground)
	var plane := PlaneMesh.new();plane.size=Vector2(40,40);ground.mesh=plane
	var floor_mat := StandardMaterial3D.new();floor_mat.albedo_color=Color("49545a");ground.material_override=floor_mat
	camera=Camera3D.new();fixture.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/actors_manifest.json"))
	# Face and gun contact close-ups at matching cameras, two priority identities.
	for id in ["operator_rifle","enemy_patrol"]:
		for clip in ["idle","aim"]:
			var n:=load_asset(id,0);mount(n,"m1_garand" if id=="operator_rifle" else "kar98k",0);pose(n,clip,0.5)
			for yaw in [180,225,270,315]:
				look(yaw,12,0.72,Vector3(0.04,1.65,-0.08))
				await capture("face_%s_%s_yaw%d" % [id,clip,yaw],{"subject":id,"clip":clip,"yaw":yaw,"size_m":0.72})
			if clip=="aim":
				for yaw in [180,245,315]:
					look(yaw,22,0.72,Vector3(0.12,1.54,-0.43))
					await capture("grip_%s_yaw%d" % [id,yaw],{"subject":id,"clip":clip,"yaw":yaw,"size_m":0.72})
			await clear_stage()
		for clip in ["walk","run","crouch_walk"]:
			var n:=load_asset(id,0);mount(n,"m1_garand" if id=="operator_rifle" else "kar98k",0)
			for sample in 16:
				pose(n,clip,sample/16.0);look(245,20,2.25,Vector3(0,0.9,0))
				await capture("gait_%s_%s_%02d" % [id,clip,sample],{"subject":id,"clip":clip,"phase":sample/16.0,"yaw":245})
			await clear_stage()
		for clip in ["pickup","deploy","death","haul"]:
			var n:=load_asset(id,0);pose(n,clip,0.5);look(245,25,2.25,Vector3(0,.75,0))
			await capture("joint_%s_%s" % [id,clip],{"subject":id,"clip":clip,"phase":0.5})
			await clear_stage()
	var foot_subject:=load_asset("operator_rifle",0)
	for sample in 16:
		pose(foot_subject,"walk",sample/16.0);look(245,12,0.90,Vector3(0,.21,0))
		await capture("foot_walk_%02d" % sample,{"clip":"walk","phase":sample/16.0,"size_m":0.90})
	await clear_stage()
	# Compare the two priority actors, all LODs and yaw values at neutral light.
	for lod in 3:
		var op:=load_asset("operator_rifle",lod);op.position.x=-.65;mount(op,"m1_garand",lod);pose(op,"aim",0.5)
		var enemy:=load_asset("enemy_patrol",lod);enemy.position.x=.65;mount(enemy,"kar98k",lod);pose(enemy,"aim",0.5)
		for yaw in range(0,360,45):
			look(yaw,35,4,Vector3(0,.9,0))
			await capture("neutral_lod%d_yaw%d" % [lod,yaw],{"lod":lod,"yaw":yaw,"size_m":4})
		await clear_stage()
	# Fixed pre-existing yard GLBs/textures provide industrial context only.
	context=Node3D.new();fixture.add_child(context);var yard_mat:=textured_atlas("yard")
	for x in range(-5,6):
		for z in range(-4,7):yard("ground_concrete",Vector3(x,-.025,z),yard_mat)
	yard("warehouse_fragment",Vector3(3.5,0,4),yard_mat)
	yard("oil_drum",Vector3(-2,0,2.7),yard_mat);yard("sandbag_stack",Vector3(1.5,0,2.6),yard_mat)
	yard("yard_lamp",Vector3(-2,0,3),yard_mat)
	var lamp:=OmniLight3D.new();context.add_child(lamp);lamp.position=Vector3(-2,2.8,3);lamp.light_color=Color("ffbd79");lamp.light_energy=2.8;lamp.omni_range=7;lamp.shadow_enabled=true
	ground.visible=false;env.environment.background_color=Color("172231")
	env.environment.ambient_light_color=Color("7391b5");env.environment.ambient_light_energy=.23
	sun.light_color=Color("8cadd9");sun.light_energy=.65;fill.light_color=Color("efb681");fill.light_energy=.35
	for lod in 3:
		var op:=load_asset("operator_rifle",lod);op.position.x=-.65;mount(op,"m1_garand",lod);pose(op,"aim",0.5)
		var enemy:=load_asset("enemy_patrol",lod);enemy.position.x=.65;mount(enemy,"kar98k",lod);pose(enemy,"aim",0.5)
		for yaw in [180,225,270,315]:
			for size in [4,10]:
				look(yaw,50,size,Vector3(0,.8,0))
				await capture("industrial_lod%d_yaw%d_size%d" % [lod,yaw,size],{"lod":lod,"yaw":yaw,"size_m":size,"lighting":"dusk industrial fixture; no full game claim"})
		await clear_stage()
	FileAccess.open(out.path_join("quality-report.json"),FileAccess.WRITE).store_string(JSON.stringify({"version":Engine.get_version_info(),"captures":records,"failures":failures,"scope":"priority asset quality; same cameras and lights for baseline/new; no gameplay"},"\t"))
	print("ACTOR_QUALITY_REVIEW captures=",records.size()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
