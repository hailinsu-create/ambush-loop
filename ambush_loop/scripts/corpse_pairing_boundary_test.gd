extends "res://scripts/corpse_pose_quality_test.gd"
## Internal contact boundaries, with actual native event sources and a named
## 3-role x 3-LOD x 2-stance fixture. No endpoint-only continuity oracle.
var boundary_rows := []
var legacy_rows := []

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		print("CORPSE_BOUNDARY_FAIL "+message)

func _sample_signature(carrier: Actor, visual: Node3D) -> Dictionary:
	var bones := [carrier.global_transform,visual.body.global_transform]
	for actor: Actor in [carrier,visual.body]:
		for index in actor.skeleton.get_bone_count(): bones.append(actor.skeleton.get_bone_global_pose(index))
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(var_to_bytes(bones))
	return {"left":carrier.bone_socket("support_hand").position,"right":carrier.bone_socket("weapon_hand").position,"skin":_vertices(carrier),"body_skin":_vertices(visual.body),"body":visual.body.global_transform,"bones":bones,"pose_sha256":hash.finish().hex_encode()}

func _delta(previous: Dictionary, current: Dictionary) -> Dictionary:
	var skin := 0.0
	var body_skin := 0.0
	var bones := 0.0
	var angle := 0.0
	for index in current.skin.size(): skin=maxf(skin,current.skin[index].distance_to(previous.skin[index]))
	for index in current.body_skin.size(): body_skin=maxf(body_skin,current.body_skin[index].distance_to(previous.body_skin[index]))
	for index in current.bones.size():
		bones=maxf(bones,current.bones[index].origin.distance_to(previous.bones[index].origin))
		angle=maxf(angle,current.bones[index].basis.get_rotation_quaternion().angle_to(previous.bones[index].basis.get_rotation_quaternion()))
	return {"left_m":current.left.distance_to(previous.left),"right_m":current.right.distance_to(previous.right),"carrier_skin_m":skin,"body_skin_m":body_skin,"bone_position_m":bones,"bone_angle_rad":angle,"body_root_m":current.body.origin.distance_to(previous.body.origin)}

func _boundary_matrix(id: String) -> void:
	var stage := Node3D.new()
	stage.visible=false
	root.add_child(stage)
	var carrier := Actor.new()
	stage.add_child(carrier)
	var visual := preload("res://scripts/presentation/corpse_visual.gd").new()
	stage.add_child(visual)
	for lod in 3:
		for role in ["operator_rifle","operator_mg","operator_scout"]:
			carrier.set_asset(role,lod,view.frame.actor_asset_revision)
			for stance in 2:
				for source: Dictionary in phases:
					var frame: Dictionary = source.duplicate(true)
					var item: Dictionary = frame.corpses.filter(func(value: Dictionary) -> bool: return value.id==id)[0].duplicate(true)
					item.carrier.model=role
					item.carrier.stance=stance
					item.ground_anchor=item.carrier.duplicate(true)
					var op: Dictionary = frame.ops.filter(func(value: Dictionary) -> bool: return int(value.id)==int(item.carrier.id))[0].duplicate(true)
					op.visual_model=role
					op.stance=stance
					frame.ops=[op]
					frame.corpses=[item]
					frame.pose_snapshot_delta_s=0.0
					var mode: String = item.mode
					var ages := [0.1999,0.2] if mode=="grab" else [0.5,0.5001]
					for schema in [int(source.corpse_pairing_schema),1]:
						frame.corpse_pairing_schema=schema
						var previous := {}
						var digests := []
						for age: float in ages:
							item.transition_age_s=age
							carrier.transform=Transform3D(Basis(Vector3.UP,Space.facing_yaw(item.carrier.facing)),Space.logic_to_world(item.carrier.pos))
							carrier.sample_layers(preload("res://scripts/presentation/actor_pose.gd").sample(op,frame,"ops"))
							visual.sync(item,frame,lod,carrier,view._environment_scene.contact_bounds())
							var current := _sample_signature(carrier,visual)
							digests.append(current.pose_sha256)
							if not previous.is_empty():
								var delta := _delta(previous,current)
								var row := {"role":role,"lod":lod,"stance":stance,"mode":mode,"ages":ages,"schema":schema,"delta":delta,"pose_sha256":digests}
								if schema==int(source.corpse_pairing_schema):
									boundary_rows.append(row)
									_check(maxf(delta.left_m,delta.right_m)<0.001,"both palms continuous within1mm "+str(row))
									_check(delta.carrier_skin_m<0.001 and delta.body_skin_m<0.001,"both actual LOD skins continuous within1mm "+str(row))
									_check(delta.bone_position_m<0.001 and delta.bone_angle_rad<0.01,"all40 bones continuous within1mm/0.01rad "+str(row))
									_check(delta.body_root_m<0.001,"body root never jumps at internal contact boundary")
								else: legacy_rows.append(row)
							previous=current
	stage.free()

func _run() -> void:
	root.size=Vector2i(1280,720)
	var settings=root.get_node("GameSettings")
	settings.mark_tutorial_seen("yard")
	settings.set_force_touch_hud(true)
	settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	view=main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	await _qa_exact()
	_check(completed,"actual original two-wave native MG source completes")
	if not completed:
		quit(1)
		return
	var id: String = rows.back().body_id
	for mode in ["release","grab"]:
		await _native_key(KEY_H)
		view.refresh()
		phases.append(view.frame.duplicate(true))
		var previous := {}
		var ages := [0.5,0.5001] if mode=="release" else [0.1999,0.2]
		var previous_age := 0.0
		var tactical: Vector2 = main.selected.global_position
		for age: float in ages:
			var clock: float = main._pose_command_clock_s
			main._process(age-previous_age)
			_check(absf(main._pose_command_clock_s-clock-(age-previous_age))<0.000000001 and main.selected.global_position==tactical,"ordinary command clock advances exact dt with unchanged tactical position")
			previous_age=age
			view.refresh()
			var carrier: Actor = view.actors["ops:%d" % main.selected.op_id].get_node("Body")
			var signature := _sample_signature(carrier,view.corpses[id])
			if not previous.is_empty():
				var delta := _delta(previous,signature)
				_check(maxf(delta.left_m,delta.right_m)<0.001 and delta.carrier_skin_m<0.001,"actual native internal "+mode+" continuity "+str(delta))
			previous=signature
			copied_frames.append(main._snapshot_data().duplicate(true))
			copied_signatures.append(_pose_signature(id))
			_measure(id,"boundary_"+mode+"_"+str(age),age<=0.5 if mode=="release" else age>=0.2)
			_freeze_current(id,mode+"_"+str(age))
			await _capture(id,"boundary_"+mode+"_"+str(age))
		main._process((0.7 if mode=="release" else 1.0)-previous_age+0.001)
		view.refresh()
	_boundary_matrix(id)
	await _history(id)
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/corpse-boundary-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"boundary_rows":boundary_rows,"legacy_rows":legacy_rows,"native_quality_rows":quality_rows,"captures":captures},"  "))
	print("CORPSE_BOUNDARY_TEST checks=%d failures=%d cases=%d" % [checks,failures,boundary_rows.size()])
	quit(0 if failures==0 else 1)
