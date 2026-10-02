extends Node3D
## Standalone exhibition. No game scripts, autoloads, state or user saves.
var catalog: Dictionary
var records: Dictionary = {}
var mats: Dictionary = {}
var stage := Node3D.new()
var camera := Camera3D.new()
var sun := DirectionalLight3D.new()
var env := Environment.new()
var lamps: Array[OmniLight3D] = []
var caption := Label.new()
var issues: Array[String] = []
var checks := 0
var output := ""
var counts: Array = []

func _ready() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://art/environment_v2/catalog_sample.json"))
	for record in catalog.new_assets + catalog.reuse_assets:
		records[str(record.asset_id)] = record
	add_child(stage)
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.current = true
	camera.near = 0.01
	camera.far = 150
	add_child(sun)
	sun.rotation_degrees = Vector3(-48,-32,0)
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 35
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var ui := CanvasLayer.new()
	add_child(ui)
	caption.position = Vector2(20,16)
	caption.add_theme_font_size_override("font_size",18)
	caption.add_theme_color_override("font_color",Color("e5e6df"))
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",1)
	caption.add_theme_constant_override("shadow_offset_y",1)
	ui.add_child(caption)
	output = OS.get_environment("ENV_REVIEW_OUTPUT")
	if output.is_empty():
		output = "user://environment_review"
	DirAccess.make_dir_recursive_absolute(output)
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		issues.append(message)
		push_error(message)

func atlas(prefix: String, path: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.resource_name = prefix
	m.albedo_texture = load(path + "albedo.png")
	m.normal_enabled = true
	m.normal_texture = load(path + "normal.png")
	m.normal_scale = 0.45
	m.roughness_texture = load(path + "orm.png")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.metallic_texture = m.roughness_texture
	m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	m.metallic = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return m

func material(slot: String) -> StandardMaterial3D:
	if mats.has(slot):
		return mats[slot]
	var m: StandardMaterial3D
	match slot:
		"environment_v2_atlas": m = atlas(slot,"res://art/environment_v2/textures/environment_v2_")
		"v2_shared_atlas": m = atlas(slot,"res://art/v2/textures/yard_atlas_")
		"environment_v2_emission", "v2_lamp_emission":
			m = StandardMaterial3D.new()
			m.resource_name = slot
			m.albedo_color = Color("ffd09b")
			m.emission_enabled = true
			m.emission = Color("ffa256")
			m.emission_energy_multiplier = 1.4
		_:
			check(false,"Unknown material slot: "+slot)
			m = StandardMaterial3D.new()
	mats[slot] = m
	return m

func bind(n: Node, id: String) -> void:
	if n is MeshInstance3D:
		for i in n.mesh.get_surface_count():
			var original: Material = n.mesh.surface_get_material(i)
			var slot := str(original.resource_name) if original != null else ""
			if slot.is_empty() and not id.begins_with("env_"):
				# Frozen baseline GLBs only export placeholder material names. Godot
				# imports null material resources; explicit legacy slot order is audited.
				slot = "v2_lamp_emission" if id=="yard_lamp" and i==1 else "v2_shared_atlas"
			n.set_surface_override_material(i,material(slot))
	for child in n.get_children(): bind(child,id)

func instantiate(id: String, lod: int = 0) -> Node3D:
	var packed := load("res://" + str(records[id].lods[lod].path)) as PackedScene
	check(packed != null,"PackedScene missing: "+id)
	var n := packed.instantiate() as Node3D
	n.set_meta("asset_id",id)
	bind(n,id)
	return n

func mesh_report(n: Node, transform: Transform3D = Transform3D.IDENTITY) -> Dictionary:
	var points: Array[Vector3] = []
	var triangles := 0
	var surfaces := 0
	if n is Node3D: transform = transform * n.transform
	if n is MeshInstance3D:
		surfaces += n.mesh.get_surface_count()
		for s in n.mesh.get_surface_count():
			var arrays: Array = n.mesh.surface_get_arrays(s)
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			triangles += indices.size()/3
			for vertex in arrays[Mesh.ARRAY_VERTEX]: points.append(transform * vertex)
	for child in n.get_children():
		var r := mesh_report(child,transform)
		points.append_array(r.points)
		triangles += int(r.triangles)
		surfaces += int(r.surfaces)
	return {"points":points,"triangles":triangles,"surfaces":surfaces}

func validate() -> void:
	for id in records:
		var record: Dictionary = records[id]
		for lod in range(2):
			var n := instantiate(id,lod)
			var r := mesh_report(n)
			check(int(r.triangles)==int(record.lods[lod].triangles),"Triangle mismatch: %s/%d %s"%[id,lod,r.triangles])
			check(int(r.surfaces)==int(record.lods[lod].surfaces),"Surface mismatch: %s/%d"%[id,lod])
			var lo: Vector3 = r.points[0]
			var hi := lo
			for v: Vector3 in r.points:
				lo = lo.min(v)
				hi = hi.max(v)
			var dims := hi-lo
			var expected: Array = record.dimensions_m
			# LOD1 intentionally changes minor profiles; the authoring bound is LOD0.
			if lod==0:
				check(dims.distance_to(Vector3(expected[0],expected[1],expected[2]))<0.025,"Dimensions mismatch: %s actual=%s expected=%s"%[id,dims,expected])
			for socket_name in record.get("sockets",{}):
				if not str(id).begins_with("env_"): continue # old sample has manifest-only anchors
				var socket := n.find_child(str(id)+"__socket_"+socket_name,true,false) as Node3D
				check(socket!=null,"Socket missing: "+str(id)+"/"+socket_name)
				if socket!=null:
					var pos: Array = record.sockets[socket_name].position_m
					check(socket.position.distance_to(Vector3(pos[0],pos[1],pos[2]))<0.002,"Socket transform mismatch: "+str(id)+"/"+socket_name)
			for key in record.get("moving_nodes",{}):
				var motion: Dictionary = record.moving_nodes[key]
				var joint := n.find_child(str(motion.node),true,false) as Node3D
				check(joint!=null,"Moving pivot missing: "+str(motion.node))
				if joint!=null:
					var pos: Array = motion.position_m
					check(joint.position.distance_to(Vector3(pos[0],pos[1],pos[2]))<0.002,"Pivot transform mismatch: "+str(motion.node))
			check(n.find_children("*","CollisionObject3D",true,false).is_empty(),"Unexpected collision: "+str(id))
			counts.append({"id":id,"lod":lod,"dimensions_m":[dims.x,dims.y,dims.z],"triangles":r.triangles,"surfaces":r.surfaces,"min_y":lo.y})
			n.free()
	for slot in ["environment_v2_atlas","environment_v2_emission"]:
		var persisted := load("res://art/environment_v2/materials/"+slot+".tres") as StandardMaterial3D
		check(persisted!=null,"Persisted candidate material missing "+slot)
		if persisted!=null:
			check(persisted.resource_name==slot,"Persisted material name "+slot)
			var constructed := material(slot)
			check(persisted.normal_enabled==constructed.normal_enabled,"Persisted normal mode "+slot)
			check(persisted.emission_enabled==constructed.emission_enabled,"Persisted emission mode "+slot)
			if slot=="environment_v2_atlas":
				check(persisted.albedo_texture.resource_path==constructed.albedo_texture.resource_path,"Persisted albedo path")
				check(persisted.normal_texture.resource_path==constructed.normal_texture.resource_path,"Persisted normal path")
				check(persisted.metallic_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_BLUE and persisted.roughness_texture_channel==BaseMaterial3D.TEXTURE_CHANNEL_GREEN,"Persisted ORM channels")
				check(is_equal_approx(persisted.normal_scale,constructed.normal_scale),"Persisted normal strength")
	print("ENVIRONMENT_GODOT_CHECKS ",checks," issues=",issues.size())

func clear_stage() -> void:
	for n in stage.get_children(): n.free()
	lamps.clear()

func study_floor(span: float) -> void:
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(span*3,0.02,span*3)
	floor_mesh.mesh = box
	floor_mesh.position.y = -0.02
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("42494d")
	m.roughness = 0.95
	floor_mesh.material_override = m
	stage.add_child(floor_mesh)

func place(id: String, p: Vector3, yaw: float=0.0, lod: int=0) -> Node3D:
	var n := instantiate(id,lod)
	stage.add_child(n)
	n.position = p
	n.rotation_degrees.y = yaw
	return n

func lighting(dusk: bool, clay: bool=false) -> void:
	env.background_color = Color("242b34") if dusk else Color("343b43")
	env.ambient_light_color = Color("b4c5dd") if dusk else Color.WHITE
	env.ambient_light_energy = 0.62 if dusk else 0.70
	sun.light_color = Color("b3c5df") if dusk else Color("fff5e6")
	sun.light_energy = 0.75 if dusk else 1.05
	for light in lamps: light.visible = dusk
	if clay:
		var clay_mat := StandardMaterial3D.new()
		clay_mat.albedo_color = Color("b0b1ad")
		clay_mat.roughness = 0.92
		for n in stage.find_children("*","MeshInstance3D",true,false): n.material_override = clay_mat

func pose(yaw: float,pitch: float,span: float,focus: Vector3) -> void:
	camera.size = span
	var a := deg_to_rad(yaw)
	var p := deg_to_rad(pitch)
	camera.position = focus + Vector3(sin(a)*cos(p),sin(p),cos(a)*cos(p))*35
	camera.look_at(focus,Vector3.UP)

func build_theme(theme: String,lod: int=0,open_roofs: bool=false) -> void:
	clear_stage()
	var recipe: Dictionary = catalog.themes[theme]
	for x in range(-3,3):
		for z in range(-3,3):
			var id: String = recipe.grounds[0 if z<0 else 1]
			place(id,Vector3(x*2+1,0,z*2+1),0,lod)
	for p in recipe.placements:
		if open_roofs and p.get("occlusion_group","")=="roof":continue
		var v: Array = p.position_m
		var n := place(p.asset_id,Vector3(v[0],v[1],v[2]),float(p.yaw_degrees),lod)
		if open_roofs:
			for mesh in n.find_children("*roof*","MeshInstance3D",true,false): mesh.visible = false
		if p.asset_id=="env_wall_lamp" or p.asset_id=="yard_lamp":
			var light := OmniLight3D.new()
			var anchor: Variant = records[p.asset_id].sockets.warm_light
			var coords: Array = anchor if anchor is Array else anchor.position_m
			n.add_child(light)
			light.position = Vector3(coords[0],coords[1],coords[2])
			light.light_color = Color("ffb76c")
			light.light_energy = 2.6
			light.omni_range = 4.5
			light.shadow_enabled = false
			lamps.append(light)

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var im := get_viewport().get_texture().get_image()
	var err := im.save_png(output.path_join(name+".png"))
	check(err==OK,"Capture failed "+name)

func _run() -> void:
	validate()
	var args := OS.get_cmdline_user_args()
	if "--validate" in args:
		write_report()
		get_tree().quit(0 if issues.is_empty() else 1)
		return
	if "--capture" in args:
		await capture()
		write_report()
		get_tree().quit(0 if issues.is_empty() else 1)
		return
	build_theme("yard")
	lighting(true)
	pose(35,55,14,Vector3(0,1,0))
	caption.text = "ENVIRONMENT CANDIDATE / YARD\nStandalone asset exhibition. No combat or performance acceptance."

func write_report() -> void:
	var f := FileAccess.open(output.path_join("godot_report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"engine":Engine.get_version_info(),"checks":checks,"issues":issues,"models":counts,"device":"cloud llvmpipe compatibility, not Android","screenshots":"rendered frames, require pixel review"},"\t"))

func capture() -> void:
	var asset_filter := ""
	var theme_filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--asset-only="): asset_filter = arg.get_slice("=",1)
		if arg.begins_with("--theme-only="): theme_filter = arg.get_slice("=",1)
	if "--themes-only" not in OS.get_cmdline_user_args():
		# Actual model pixels for each new and reused core asset: eight directions,
		# both pitch limits, close LOD0 and distant LOD1, neutral/dusk and clay.
		for id in records:
			if not asset_filter.is_empty() and id != asset_filter: continue
			var dims: Array = records[id].dimensions_m
			var span := maxf(1.25,maxf(float(dims[1]),maxf(float(dims[0]),float(dims[2])))*1.65)
			for lod in range(2):
				for mode in ["neutral","dusk"]:
					clear_stage()
					place(id,Vector3.ZERO,0,lod)
					if records[id].category != "ground": study_floor(span)
					lighting(mode=="dusk")
					for pitch in [35,65]:
						for yaw in range(0,360,45):
							pose(yaw,pitch,span*(1.5 if lod==1 else 1.0),Vector3(0,float(dims[1])/2,0))
							caption.text = "%s / LOD%d %s / yaw%d pitch%d"%[id,lod,mode,yaw,pitch]
							await snap("asset_%s_l%d_%s_p%d_y%d"%[id,lod,mode,pitch,yaw])
			# Clay front/side/rear exposes the actual geometry independently of atlas.
			clear_stage()
			place(id,Vector3.ZERO)
			if records[id].category != "ground": study_floor(span)
			lighting(false,true)
			for yaw in [0,90,180]:
				pose(yaw,35,span,Vector3(0,float(dims[1])/2,0))
				caption.text = "%s / CLAY yaw%d"%[id,yaw]
				await snap("clay_%s_y%d"%[id,yaw])
			print("CAPTURE_ASSET ",id)
	# Themes at all camera extremes. These are compositions, not live levels.
	for theme in catalog.themes:
		if not theme_filter.is_empty() and theme != theme_filter: continue
		for lod in range(2):
			for mode in ["neutral","dusk"]:
				build_theme(theme,lod)
				lighting(mode=="dusk")
				for pitch in [35,65]:
					for yaw in range(0,360,45):
						pose(yaw,pitch,13 if lod==0 else 20,Vector3(0,1,0))
						caption.text = "%s EXHIBITION / LOD%d %s yaw%d pitch%d\nCandidate composition; no gameplay mapping"%[str(theme).to_upper(),lod,mode,yaw,pitch]
						await snap("theme_%s_l%d_%s_p%d_y%d"%[theme,lod,mode,pitch,yaw])
		build_theme(theme,0,true)
		lighting(true)
		pose(145,65,13,Vector3(0,1,0))
		caption.text = str(theme).to_upper()+" / ROOFS REMOVED / candidate display"
		await snap("theme_"+str(theme)+"_roof_removed")
		print("CAPTURE_THEME ",theme)
	# Native smaller viewport, not a resized desktop image.
	get_tree().root.size = Vector2i(800,450)
	caption.add_theme_font_size_override("font_size",12)
	build_theme("yard")
	lighting(true)
	pose(0,55,14,Vector3(0,1,0))
	caption.text = "YARD / native 800x450 cloud viewport / no device test"
	await snap("phone_yard_800x450")
	get_tree().root.size = Vector2i(1280,720)
	caption.add_theme_font_size_override("font_size",18)
	if "--skip-motion" in OS.get_cmdline_user_args(): return
	# Door, gate, sliding leaf, and every new container lid move at their actual pivots.
	clear_stage()
	var ids := ["env_yard_crate","env_ammo_can","env_gun_case","env_rations_crate","env_door_leaf","env_gate_leaf","env_loading_leaf"]
	var actors: Array[Node3D] = []
	for i in ids.size():actors.append(place(ids[i],Vector3((i-3)*1.65,0,0)))
	lighting(false)
	pose(160,45,10,Vector3(0,1,0))
	for frame in range(180):
		var phase := (1.0-cos(float(frame)/179.0*TAU))/2
		for i in ids.size():
			var record: Dictionary = records[ids[i]]
			for key in record.moving_nodes:
				var motion: Dictionary = record.moving_nodes[key]
				var joint := actors[i].find_child(motion.node,true,false) as Node3D
				if motion.motion=="rotate":
					joint.rotation_degrees.x = phase*float(motion.range[1]) if motion.axis=="X" else 0.0
					joint.rotation_degrees.y = phase*float(motion.range[1]) if motion.axis=="Y" else 0.0
				else:joint.position.x = float(motion.position_m[0])+phase*float(motion.range[1])
		caption.text = "ACTUAL GODOT DISPLAY MOTION / %03d\nFour hinged lids, door, gate and sliding leaf. Visual only."%frame
		await snap("motion_%03d"%frame)
	print("ENVIRONMENT_CAPTURE_COMPLETE")
