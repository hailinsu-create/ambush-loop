extends "res://base_review.gd"

const ROLES = ["operator_rifle", "operator_mg", "operator_scout"]
var contacts: Array = []
var seams: Array = []
var speed_checks: Array = []

func vec(a: Array) -> Vector3:
	return Vector3(float(a[0]),float(a[1]),float(a[2]))

func palm(n: Node3D, side: String) -> Vector3:
	var sk := rig(n)
	return sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand."+side)) * Vector3(0,.035,0)

func matrices(n: Node3D) -> Array:
	var result: Array = []; var sk := rig(n)
	for i in sk.get_bone_count(): result.append(sk.get_bone_global_pose(i))
	return result

func error(a: Array,b: Array) -> float:
	var maximum := 0.0
	for i in a.size():
		maximum = maxf(maximum,a[i].origin.distance_to(b[i].origin))
		for axis in 3: maximum=maxf(maximum,a[i].basis[axis].distance_to(b[i].basis[axis]))
	return maximum

func configured(id: String, lod: int, catalog: Dictionary) -> Node3D:
	var n := load_asset(id,lod); var ap := player(n)
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for asset in catalog.assets:
		if asset.asset_id == id:
			for clip in asset.animations:
				check(ap.has_animation(clip.name),id+" missing "+clip.name)
				ap.get_animation(clip.name).loop_mode=Animation.LOOP_LINEAR if clip.loop else Animation.LOOP_NONE
	return n

func shoulder_markers(n: Node3D) -> Array:
	var result: Array = []
	for side in ["L","R"]:
		var attachment := BoneAttachment3D.new(); attachment.bone_name="upper_arm."+side
		rig(n).add_child(attachment); result.append(attachment)
	return result

func align_body(body: Node3D, marks: Array, actor: Node3D) -> float:
	var centre: Vector3 = (marks[0].global_position+marks[1].global_position)*.5
	body.global_position += (palm(actor,"L")+palm(actor,"R"))*.5-centre
	return maxf(palm(actor,"L").distance_to(marks[0].global_position),palm(actor,"R").distance_to(marks[1].global_position))

func imported_skin_floor(n: Node3D) -> float:
	var minimum := INF; var sk := rig(n)
	for mesh in descendants(n,"MeshInstance3D"):
		var first: Array=mesh.mesh.surface_get_arrays(0)
		if first[Mesh.ARRAY_BONES]==null:
			for surface in mesh.mesh.get_surface_count():
				var static_arrays: Array=mesh.mesh.surface_get_arrays(surface)
				for v in static_arrays[Mesh.ARRAY_VERTEX]:minimum=minf(minimum,(mesh.global_transform*v).y)
			continue
		var skin: Skin = mesh.skin; var deform: Array = []
		# Godot can use a generated rest skin when the imported property is null.
		if skin==null:skin=sk.create_skin_from_rest_transforms()
		for i in skin.get_bind_count():
			var name: String = skin.get_bind_name(i)
			var bone := sk.find_bone(name) if not name.is_empty() else skin.get_bind_bone(i)
			check(bone>=0,"imported bind bone "+str(i))
			deform.append(sk.global_transform*sk.get_bone_global_pose(bone)*skin.get_bind_pose(i))
		for surface in mesh.mesh.get_surface_count():
			var a: Array = mesh.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array=a[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array=a[Mesh.ARRAY_WEIGHTS]
			for vertex in vertices.size():
				var v := Vector3.ZERO
				for j in 4:
					var k := vertex*4+j
					v += (deform[bones[k]]*vertices[vertex])*weights[k]
				minimum=minf(minimum,v.y)
	return minimum

func fast_capture(name: String, context: Dictionary) -> void:
	await process_frame; await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(out.path_join(name+".png"))==OK,"capture "+name)
	context.image=name+".png"; records.append(context)

func review_actions() -> void:
	var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://utility_profiles_candidate.json"))
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/actors_manifest.json"))
	var tools := {}
	for asset in catalog.assets:
		if asset.category == "tool": tools[asset.asset_id]=asset
	var contact_rows: Array=[]; var body_rows: Array=[]; var floor_rows: Array=[]
	for lod in 3:
		var subjects: Array=[]
		for i in ROLES.size():
			var n:=configured(ROLES[i],lod,catalog)
			n.position=Vector3(cos(deg_to_rad(245)),0,-sin(deg_to_rad(245)))*(i-1)*2.4
			subjects.append(n)
		await process_frame; await process_frame
		for clip_name in contract.clips:
			var mounted: Array=[]; var body_list: Array=[]; var marker_list: Array=[]; var tool_id: String=""
			if clip_name=="knife_stab": tool_id="knife"
			if clip_name=="grenade_throw": tool_id="grenade"
			if clip_name=="decoy_place": tool_id="decoy"
			for n in subjects:
				pose(n,clip_name,0); player(n).play(clip_name)
				if not tool_id.is_empty(): mounted.append(mount_tool(n,tools[tool_id],lod))
				if clip_name in ["corpse_drag","corpse_grab","corpse_release"]:
					var body:=configured("enemy_patrol",lod,catalog); pose(body,"corpse_dragged",0)
					body_list.append(body); marker_list.append(shoulder_markers(body))
			await process_frame; await process_frame
			# Place the body at the held endpoint, then restore the actor's
			# authored entry. The body remains visible during reach/release.
			if not body_list.is_empty():
				for i in subjects.size():pose(subjects[i],"corpse_drag",0)
				await process_frame
				for i in subjects.size():align_body(body_list[i],marker_list[i],subjects[i])
				for n in subjects:pose(n,clip_name,0);player(n).play(clip_name)
			var duration:=player(subjects[0]).get_animation(clip_name).length
			var rows: Array=[]; var origins: Array=[]; var released: Array=[]
			for i in ROLES.size():
				rows.append({"role":ROLES[i],"lod":lod,"clip":clip_name,"samples":25,"max_held_grip_m":0.0,"max_paired_shoulder_m":0.0,"max_ground_error_m":0.0,"knife_forward_excursion_m":0.0,"max_tip_y_m":0.0})
				origins.append(Vector3.ZERO); released.append(false)
			for sample in 25:
				var phase:=sample/24.0
				for n in subjects:
					if sample>0: player(n).advance(duration/24.0)
					rig(n).force_update_all_bone_transforms()
					for m in matrices(n): check(m.origin.is_finite(),"finite actual pose "+clip_name)
					if sample<24: check(abs(player(n).current_animation_position-duration*phase)<.0001,"actual phase "+clip_name)
				await process_frame
				for i in subjects.size():
					var n: Node3D=subjects[i]; var row: Dictionary=rows[i]
					if not tool_id.is_empty():
						var tool: Node3D=mounted[i]
						var grip:=tool.find_child(tool_id+"__socket_grip",true,false) as Node3D
						check(grip!=null,"actual existing tool grip "+tool_id)
						if not released[i]:row.max_held_grip_m=maxf(row.max_held_grip_m,palm(n,"R").distance_to(grip.global_position))
						if clip_name=="knife_stab":
							var tip:=tool.find_child("knife__socket_tip",true,false) as Node3D
							var point: Vector3=tip.global_position-n.global_position
							if sample==0:origins[i]=point
							row.knife_forward_excursion_m=maxf(row.knife_forward_excursion_m,origins[i].z-point.z)
							row.max_tip_y_m=maxf(row.max_tip_y_m,point.y)
						if clip_name=="grenade_throw" and sample==6:row.prepare_world=[grip.global_position.x,grip.global_position.y,grip.global_position.z]
						if phase==.5 and clip_name in ["grenade_throw","decoy_place"]:
							row.release_world=[grip.global_position.x,grip.global_position.y,grip.global_position.z]
							row.release_origin_world=[tool.global_position.x,tool.global_position.y,tool.global_position.z]
							row.release_phase=phase
							if clip_name=="grenade_throw":row.prepare_to_release_m=vec(row.prepare_world).distance_to(grip.global_position)
							tool.reparent(stage,true); released[i]=true
						if clip_name=="decoy_place" and phase>=.4 and phase<=.6:
							row.max_ground_error_m=maxf(row.max_ground_error_m,abs(tool.global_position.y))
						if clip_name=="grenade_throw" and phase>.5:tool.visible=false
					if not body_list.is_empty():
						var blend: float=phase if clip_name=="corpse_grab" else 1-phase if clip_name=="corpse_release" else 1.
						if clip_name!="corpse_drag":pose(body_list[i],"corpse_lift" if clip_name=="corpse_grab" else "corpse_lower",phase)
						if blend>=.999:row.max_paired_shoulder_m=maxf(row.max_paired_shoulder_m,align_body(body_list[i],marker_list[i],n))
					if sample in [0,12,24] or clip_name=="death_prone":
						var floor:=imported_skin_floor(n)
						check(floor>-.015,"actual imported skin floor "+ROLES[i]+"/"+clip_name+": "+str(floor))
						floor_rows.append({"role":ROLES[i],"lod":lod,"clip":clip_name,"phase":phase,"min_y_m":floor})
				if lod!=1 and sample%3==0 and clip_name in ["knife_stab","grenade_throw","decoy_place","corpse_drag","corpse_grab","corpse_release","death_prone"]:
					var body_action: bool=clip_name.begins_with("corpse_") or clip_name=="death_prone"
					var target_z: float=-.65 if clip_name=="death_prone" else .75 if body_action else .35
					look(245,35,(5.6 if body_action else 4.4) if lod==0 else 9.,Vector3(0,1.0,target_z))
					await fast_capture("%s_lod%d_%02d"%[clip_name,lod,sample/3],{"clip":clip_name,"lod":lod,"phase":phase,"roles":ROLES,"tool":tool_id})
				if lod!=1 and sample==12 and clip_name in ["knife_stab","grenade_throw","decoy_place","death_prone"]:
					for yaw in [65,155,245,335]:
						look(yaw,45,6. if lod==0 else 10.,Vector3(0,.85,-.5 if clip_name=="death_prone" else -.25))
						await fast_capture("%s_lod%d_yaw%d"%[clip_name,lod,yaw],{"clip":clip_name,"lod":lod,"phase":phase,"roles":ROLES,"yaw":yaw,"tool":tool_id})
				if lod==0 and sample==12 and not tool_id.is_empty():
					for i in subjects.size():
						look(245,20,1.1,subjects[i].position+Vector3(.1,1.30,-.45) if clip_name!="decoy_place" else subjects[i].position+Vector3(.1,.36,-.5))
						await fast_capture("%s_%s_contact_close"%[clip_name,ROLES[i]],{"clip":clip_name,"role":ROLES[i],"lod":lod,"phase":phase,"sample":rows[i]})
			for row in rows:
				check(row.max_held_grip_m<.0001,"tool hand contact "+str(row))
				check(row.max_paired_shoulder_m<.015,"body shoulder contact "+str(row))
				if clip_name=="knife_stab":check(row.knife_forward_excursion_m>.20,"knife excursion "+str(row))
				if clip_name=="grenade_throw":check(row.prepare_to_release_m>.45,"throw arc "+str(row))
				if clip_name=="decoy_place":check(row.max_ground_error_m<.015,"decoy grounding "+str(row))
				contact_rows.append(row)
			for tool in mounted:tool.queue_free()
			for body in body_list:body.queue_free()
			await process_frame
		# Full20bone endpoint equivalence and actual2x/pause sampling.
		for transition in contract.transitions:
			for i in subjects.size():
				var n: Node3D=subjects[i]; var pair: Array=contract.transitions[transition]
				pose(n,pair[0],0); var before:=matrices(n)
				pose(n,transition,0); var first:=matrices(n)
				pose(n,transition,1); var last:=matrices(n)
				pose(n,pair[1],0); var after:=matrices(n)
				var delta:=maxf(error(before,first),error(last,after))
				var threshold: float=.001 if transition=="death_prone" else .0001
				check(delta<threshold,"endpoint "+transition+" "+str(delta)); seams.append({"role":ROLES[i],"lod":lod,"clip":transition,"max_transform_error":delta,"threshold":threshold,"entry_error":error(before,first),"exit_error":error(last,after)})
		for i in subjects.size():
			var n: Node3D=subjects[i]; var ap:=player(n)
			pose(n,"grenade_throw",0); ap.speed_scale=2; ap.play("grenade_throw"); ap.advance(.25)
			rig(n).force_update_all_bone_transforms()
			var actual:=matrices(n); var clock:=ap.current_animation_position
			ap.speed_scale=1; pose(n,"grenade_throw",.5); var delta:=error(actual,matrices(n))
			var frozen:=matrices(n); await process_frame; await process_frame
			var pause_error:=error(frozen,matrices(n))
			check(delta<.0001 and abs(clock-.5)<.0001 and pause_error<.0001,"2x/pause utility "+ROLES[i])
			speed_checks.append({"role":ROLES[i],"lod":lod,"clock":clock,"two_speed_error":delta,"pause_error":pause_error})
		# All7body models paired with all3roles. Skin-floor from imported binds.
		for asset in catalog.assets:
			if asset.category!="character":continue
			var body:=configured(asset.asset_id,lod,catalog); var marks:=shoulder_markers(body)
			pose(body,"corpse_dragged",0); await process_frame; await process_frame
			var relative_floor:=imported_skin_floor(body)-body.global_position.y
			for i in subjects.size():
				var n: Node3D=subjects[i]; var maximum:=0.0; var minimum:=INF
				for sample in 25:
					pose(n,"corpse_drag",sample/24.0); await process_frame
					maximum=maxf(maximum,align_body(body,marks,n))
					# Body is static; translation changes with actor breathing.
					minimum=minf(minimum,relative_floor+body.global_position.y)
				check(maximum<.015 and minimum>-.015,"allbody pair "+asset.asset_id+"/"+ROLES[i]+": "+str([maximum,minimum]))
				body_rows.append({"body":asset.asset_id,"role":ROLES[i],"lod":lod,"samples":25,"max_shoulder_error_m":maximum,"min_y_m":minimum})
			pose(subjects[0],"corpse_drag",.5); await process_frame; align_body(body,marks,subjects[0])
			for n in subjects:n.visible=false
			subjects[0].visible=true
			if lod!=1:
				for yaw in [65,155,245,335]:
					look(yaw,45,3.8 if lod==0 else 9.,subjects[0].position+Vector3(0,.55,.45))
					await fast_capture("pair_%s_lod%d_yaw%d"%[asset.asset_id,lod,yaw],{"body":asset.asset_id,"role":ROLES[0],"lod":lod,"yaw":yaw,"clip":"corpse_drag"})
			if lod==0 and asset.asset_id=="enemy_patrol":
				for yaw in [90,270]:
					look(yaw,5,3.0,subjects[0].position+Vector3(0,.75,.65))
					await fast_capture("pair_enemy_patrol_ground_side%d"%yaw,{"body":asset.asset_id,"role":ROLES[0],"lod":lod,"yaw":yaw,"pitch":5,"clip":"corpse_drag","ground_check":"actual imported skin floor, fixed body pose and25 measured translations"})
				look(245,10,.8,subjects[0].position+Vector3(0,.89,.45))
				await fast_capture("pair_enemy_patrol_contact_close",{"body":asset.asset_id,"role":ROLES[0],"lod":lod,"clip":"corpse_drag"})
			for n in subjects:n.visible=true
			body.queue_free(); await process_frame
		await clear_stage(); print("UTILITY_REVIEW_PROGRESS lod",lod)
	FileAccess.open(out.path_join("utility-report.json"),FileAccess.WRITE).store_string(JSON.stringify({"version":Engine.get_version_info(),"contacts":contact_rows,"body_pairs":body_rows,"imported_skin_floor":floor_rows,"transition_endpoints":seams,"speed_pause_checks":speed_checks,"captures":records,"failures":failures,"scope":"isolated AnimationPlayer actual advance; optional contact candidates; no historical runtime, flight, gameplay, full pickup/physics or battle approval"},"\t"))
	print("UTILITY_ENGINE_REVIEW captures=",records.size()," contacts=",contact_rows.size()," pairs=",body_rows.size()," seams=",seams.size()," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(out); root.size = Vector2i(1280, 720)
	fixture = Node3D.new(); root.add_child(fixture); stage = Node3D.new(); fixture.add_child(stage)
	material = StandardMaterial3D.new(); material.albedo_texture = load("res://art/v2/textures/actor_atlas_albedo.png")
	material.normal_enabled = true; material.normal_texture = load("res://art/v2/textures/actor_atlas_normal.png"); material.normal_scale = .4
	material.roughness_texture = load("res://art/v2/textures/actor_atlas_orm.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture = material.roughness_texture; material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE; material.metallic = 1
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var env := WorldEnvironment.new(); fixture.add_child(env); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color("25303d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b1c8e0"); env.environment.ambient_light_energy = .45
	var sun := DirectionalLight3D.new(); fixture.add_child(sun); sun.rotation_degrees = Vector3(-50, -30, 0); sun.light_energy = 1.3; sun.shadow_enabled = true
	var fill := DirectionalLight3D.new(); fixture.add_child(fill); fill.rotation_degrees = Vector3(-25, 145, 0); fill.light_color = Color("e6bd92"); fill.light_energy = .5
	var floor := MeshInstance3D.new(); fixture.add_child(floor); var plane := PlaneMesh.new(); plane.size = Vector2(40, 40); floor.mesh = plane
	var floor_mat := StandardMaterial3D.new(); floor_mat.albedo_color = Color("49545a"); floor.material_override = floor_mat
	camera = Camera3D.new(); fixture.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.current = true
	await review_actions()
