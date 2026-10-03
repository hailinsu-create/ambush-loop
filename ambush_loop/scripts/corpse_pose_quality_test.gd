extends "res://scripts/corpse_contact_test.gd"

var quality_rows := []
var matrix_rows := []
var raw_reference := Actor.new()
var transition_rows := []
var phases := []
var copied_frames := []
var copied_signatures := []

func _held_matrix() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var carrier := Actor.new()
	stage.add_child(carrier)
	var visual := preload("res://scripts/presentation/corpse_visual.gd").new()
	stage.add_child(visual)
	var legacy := preload("res://scripts/presentation/corpse_visual.gd").new()
	stage.add_child(legacy)
	var frame: Dictionary = view.frame.duplicate(true)
	for lod in 3:
		for role in ["operator_rifle","operator_mg","operator_scout"]:
			carrier.set_asset(role,lod,frame.actor_asset_revision)
			for stance in 2:
				var pose := {"action":"corpse_drag","seconds":0.0}
				if stance==1:
					pose.merge({"base_action":"crouch","base_seconds":0.0,"upper_action":"corpse_drag","upper_seconds":0.0,"preserve_upper_world_basis":false})
				for model in ["enemy_patrol","enemy_flank","enemy_sneak","enemy_radio"]:
					carrier.transform=Transform3D.IDENTITY
					carrier.sample_layers(pose)
					var item: Dictionary = frame.corpses.filter(func(value: Dictionary) -> bool: return value.id==rows.back().body_id)[0].duplicate(true)
					item.model=model
					item.mode="hold"
					item.carrier.model=role
					item.carrier.stance=stance
					item.carrier.facing=90.0
					item.carrier.pos=Vector2(640,352)
					item.pos=Vector2(640,366)
					carrier.position=Space.logic_to_world(item.carrier.pos)
					carrier.rotation.y=Space.facing_yaw(90.0)
					var old: Dictionary = frame.duplicate(true)
					old.corpse_pairing_schema=0
					legacy.sync(item,old,lod,carrier)
					var old_floor := INF
					for point in _vertices(legacy.body): old_floor=minf(old_floor,point.y)
					visual.sync(item,frame,lod,carrier)
					var floor := INF
					for point in _vertices(visual.body):
						floor=minf(floor,point.y)
					matrix_rows.append({"role":role,"model":model,"stance":stance,"lod":lod,"legacy_floor_m":old_floor,"floor_m":floor,"left_m":visual.body.shoulder("L").distance_to(carrier.bone_socket("support_hand").position),"right_m":visual.body.shoulder("R").distance_to(carrier.bone_socket("weapon_hand").position)})
					_check(floor>=-0.015 and floor<=0.015,"fixture actual LOD floor within15mm "+role+"/"+model+"/"+str(stance)+"/"+str(lod)+": "+str(floor))
					_check(visual.body.shoulder("L").distance_to(carrier.bone_socket("support_hand").position)<0.015 and visual.body.shoulder("R").distance_to(carrier.bone_socket("weapon_hand").position)<0.015,"fixture floor normalization keeps both contacts")
	stage.free()

func _pose_signature(id: String) -> Array:
	var item: Dictionary = view.frame.corpses.filter(func(value: Dictionary) -> bool: return value.id==id)[0]
	var carrier: Actor = view.actors["ops:%d" % int(item.carrier.id)].get_node("Body")
	var value := [view.corpses[id].body.global_transform,carrier.global_transform]
	for actor: Actor in [view.corpses[id].body,carrier]:
		for index in actor.skeleton.get_bone_count():
			value.append(actor.skeleton.get_bone_global_pose(index))
	return value

func _freeze_current(id: String, label: String) -> void:
	var before := _pose_signature(id)
	var clock: float = main._pose_command_clock_s
	main._toggle_pause_menu()
	main._process(0.4)
	view.refresh()
	_check(main._pose_command_clock_s==clock and _pose_signature(id)==before,"paused middle "+label+" freezes both actors and command age")
	main.pause_overlay.dismiss()
	main.handle_app_focus_out()
	main._process(0.4)
	view.refresh()
	_check(main._pose_command_clock_s==clock and _pose_signature(id)==before,"background middle "+label+" freezes both actors and command age")
	main.handle_app_focus_in()
	view.refresh()
	_check(_pose_signature(id)==before,"foreground middle "+label+" resumes without pose jump")

func _endpoint_continuity(previous: Array, current: Array, label: String) -> void:
	var positions := 0.0
	var angles := 0.0
	for index in current.size():
		positions=maxf(positions,previous[index].origin.distance_to(current[index].origin))
		angles=maxf(angles,previous[index].basis.get_rotation_quaternion().angle_to(current[index].basis.get_rotation_quaternion()))
	_check(positions<0.001 and angles<0.01,"near endpoint remains continuous "+label+": "+str([positions,angles]))

func _detail_capture(id: String, label: String, yaw: float) -> void:
	if DisplayServer.get_name()=="headless":
		return
	var before: Dictionary = main._snapshot_data().duplicate(true)
	var settings=root.get_node("GameSettings")
	# Additional actual desktop HUD/camera views expose hands and feet. The
	# original touch-HUD captures above remain part of the required evidence.
	settings.set_force_touch_hud(false)
	view.rig.view_size=4.0
	view.rig.yaw_deg=yaw
	view.rig.pitch_deg=35.0
	view.rig.apply_pose()
	main._update_hud()
	view.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://build/asset_review/pr15-runtime/contact_"+label+".png"
	_check(root.get_texture().get_image().save_png(path)==OK,"capture "+label)
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"hud":"actual desktop","view_size":4.0,"yaw":yaw,"pitch":35.0})
	settings.set_force_touch_hud(true)
	view.rig.view_size=8.0
	view.rig.yaw_deg=65.0
	view.rig.pitch_deg=55.0
	view.rig.apply_pose()
	main._update_hud()
	view.refresh()
	_check(main._snapshot_data()==before,"inspection camera and HUD mode preserve complete gameplay "+label)

func _history(id: String) -> void:
	var log := BattleLog.new()
	# Preserve the real command events' scope. A new empty-attempt/wave0 log
	# would correctly reject these wave1 transitions rather than replay them.
	log.attempt_id=main.battle_log.attempt_id
	log.wave_id=main.battle_log.wave_id
	for index in copied_frames.size(): log.add_snapshot(index*60,copied_frames[index])
	log.mark_terminal((copied_frames.size()-1)*60,"copied-native-pairing")
	var original: Array = log.snapshots.duplicate(true)
	main.phase=main.Phase.REPLAY
	main.replay.bind(log)
	main.grid.blocked.fill(0)
	main.selected.global_position+=Vector2(320,224)
	main.selected.set_facing(191.0)
	main.run_id+=900
	main._pose_command_clock_s=999.0
	var live: Dictionary = main._snapshot_data().duplicate(true)
	var order := range(copied_frames.size())
	var backward := order.duplicate()
	backward.reverse()
	order.append_array(backward)
	for index in order:
		main.replay.set_tick(index*60)
		view.refresh()
		_check(_pose_signature(id)==copied_signatures[index],"history restores exact actual native roots and40 bone poses "+str(index))
		_check(main._snapshot_data()==live and log.snapshots==original,"history ignores poisoned live state and never modifies records")
	main.replay.set_tick(3*60)
	view.refresh()
	await _capture(id,"quality_history")
	await _detail_capture(id,"quality_history_desktop",65.0)
	for schema in [0,99]:
		var data: Dictionary = copied_frames.filter(func(value: Dictionary) -> bool: return value.corpses.filter(func(body: Dictionary) -> bool: return body.id==id)[0].mode=="grab")[0].duplicate(true)
		data.corpse_pairing_schema=schema
		var old := BattleLog.new()
		old.attempt_id=log.attempt_id
		old.wave_id=log.wave_id
		old.add_snapshot(0,data)
		var retained: Array = old.snapshots.duplicate(true)
		main.replay.bind(old)
		view.refresh()
		_check(not bool(view.corpses[id].get_meta("pairing_supported",true)),"old/unknown pairing version retains original pose policy")
		_check(old.snapshots==retained and main._snapshot_data()==live,"old/unknown pairing does not upgrade source or borrow live")

func _lengths(actor: Actor, side: String) -> Vector2:
	var a := actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("upper_arm."+side)).origin
	var b := actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("forearm."+side)).origin
	var c := actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("hand."+side)).origin
	return Vector2(a.distance_to(b),b.distance_to(c))

func _transition_matrix() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var carrier := Actor.new()
	stage.add_child(carrier)
	var visual := preload("res://scripts/presentation/corpse_visual.gd").new()
	stage.add_child(visual)
	for lod in 3:
		for role in ["operator_rifle","operator_mg","operator_scout"]:
			carrier.set_asset(role,lod,view.frame.actor_asset_revision)
			for stance in 2:
				for model in ["enemy_patrol","enemy_flank","enemy_sneak","enemy_radio"]:
					for source: Dictionary in phases:
						var frame: Dictionary = source.duplicate(true)
						var item: Dictionary = frame.corpses.filter(func(value: Dictionary) -> bool: return value.id==rows.back().body_id)[0].duplicate(true)
						item.model=model
						item.carrier.model=role
						item.carrier.stance=stance
						item.carrier.facing=90.0
						item.carrier.pos=Vector2(640,352)
						item.ground_anchor=item.carrier.duplicate(true)
						item.pos=Vector2(640,366)
						var op: Dictionary = frame.ops.filter(func(value: Dictionary) -> bool: return int(value.id)==int(item.carrier.id))[0].duplicate(true)
						op.visual_model=role
						op.stance=stance
						op.pos=item.carrier.pos
						op.facing=90.0
						frame.ops=[op]
						frame.corpses=[item]
						frame.pose_snapshot_delta_s=0.0
						var mode: String = item.mode
						for age in ([0.0,0.1,0.2,0.5,0.8,0.999999] if mode=="grab" else [0.0,0.2,0.35,0.5,0.6,0.699999]):
							item.transition_age_s=age
							carrier.transform=Transform3D(Basis(Vector3.UP,Space.facing_yaw(90.0)),Space.logic_to_world(item.carrier.pos))
							carrier.sample_layers(preload("res://scripts/presentation/actor_pose.gd").sample(op,frame,"ops"))
							visual.sync(item,frame,lod,carrier)
							var floor := INF
							var carrier_floor := INF
							for point in _vertices(visual.body): floor=minf(floor,point.y)
							for point in _vertices(carrier): carrier_floor=minf(carrier_floor,point.y)
							var left := visual.body.shoulder("L").distance_to(carrier.bone_socket("support_hand").position)
							var right := visual.body.shoulder("R").distance_to(carrier.bone_socket("weapon_hand").position)
							var gripping: bool = age>=0.2 if mode=="grab" else age<=0.5
							var label := "%s/%s/%d/%d/%s/%.6f" % [role,model,lod,stance,mode,age]
							_check(floor>=-0.015 and floor<=0.015,"fixture transition body floor "+label+": "+str(floor))
							_check(carrier_floor>=-0.015 and carrier_floor<=0.015,"fixture transition carrier floor "+label+": "+str(carrier_floor))
							if gripping:
								_check(left<0.015 and right<0.015 and bool(visual.get_meta("pairing_resolved",false)),"fixture both unstretched hands resolve "+label)
							transition_rows.append({"role":role,"model":model,"lod":lod,"stance":stance,"mode":mode,"age":age,"floor_m":floor,"carrier_floor_m":carrier_floor,"left_m":left,"right_m":right,"gripped":gripping,"resolved":visual.get_meta("pairing_resolved",false)})
	stage.free()

func _sampler_cache() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var used := Actor.new()
	var fresh := Actor.new()
	stage.add_child(used)
	stage.add_child(fresh)
	for lod in 3:
		for role in ["operator_rifle","operator_mg","operator_scout"]:
			used.set_asset(role,lod,view.frame.actor_asset_revision)
			fresh.set_asset(role,lod,view.frame.actor_asset_revision)
			used.sample_layers({"action":"corpse_drag","seconds":0.0,"base_action":"crouch","base_seconds":0.0,"upper_action":"corpse_drag","upper_seconds":0.0,"preserve_upper_world_basis":false})
			used.sample_pose("corpse_drag",0.0)
			fresh.sample_pose("corpse_drag",0.0)
			var same := true
			for index in used.skeleton.get_bone_count():
				same=same and used.skeleton.get_bone_pose(index)==fresh.skeleton.get_bone_pose(index)
			_check(same,"full pose after layered pose equals fresh rig "+role+"/"+str(lod))
	stage.free()

func _measure(id: String, label: String, paired: bool) -> void:
	var visual: Node3D = view.corpses[id]
	var carrier: Actor = view.actors["ops:%d" % main.selected.op_id].get_node("Body")
	var floor := INF
	for point in _vertices(visual.body):
		floor=minf(floor,point.y)
	var carrier_floor := INF
	for point in _vertices(carrier):
		carrier_floor=minf(carrier_floor,point.y)
	var distances := []
	var reaches := []
	for pair in [["L","support_hand"],["R","weapon_hand"]]:
		var shoulder: Vector3 = visual.body.shoulder(pair[0])
		distances.append(shoulder.distance_to(carrier.bone_socket(pair[1]).position))
		var arm: int = carrier.skeleton.find_bone("upper_arm."+pair[0])
		var forearm: int = carrier.skeleton.find_bone("forearm."+pair[0])
		var hand: int = carrier.skeleton.find_bone("hand."+pair[0])
		var a: Vector3 = carrier.skeleton.global_transform*carrier.skeleton.get_bone_global_pose(arm).origin
		var b: Vector3 = carrier.skeleton.global_transform*carrier.skeleton.get_bone_global_pose(forearm).origin
		var c: Vector3 = carrier.skeleton.global_transform*carrier.skeleton.get_bone_global_pose(hand).origin
		reaches.append({"shoulder_to_target_m":a.distance_to(shoulder),"arm_length_m":a.distance_to(b)+b.distance_to(c),"palm":carrier.bone_socket(pair[1]).position,"target":shoulder})
	quality_rows.append({"label":label,"mode":visual.get_meta("mode"),"floor_m":floor,"carrier_floor_m":carrier_floor,"contacts_m":distances,"reaches":reaches,"wall_vertices":_penetrations(visual.body),"carrier_wall_vertices":_penetrations(carrier),"body_transform":visual.body.global_transform})
	_check(floor>=-0.015 and floor<=0.015,"quality ground contact within15mm "+label+": "+str(floor))
	_check(carrier_floor>=-0.015 and carrier_floor<=0.015,"quality carrier also remains grounded "+label+": "+str(carrier_floor))
	_check(_penetrations(visual.body)==0,"quality skin remains outside original brickwall "+label)
	_check(_penetrations(carrier)==0,"quality leaning carrier skin remains outside original brickwall "+label)
	if paired:
		_check(distances.max()<0.015,"quality both actual palms/shoulders within15mm "+label+": "+str(distances))
		_check(bool(visual.get_meta("pairing_resolved",false)),"quality pose resolves both arms without fallback "+label)
		raw_reference.set_asset(carrier.asset_id,carrier.lod,carrier.asset_revision)
		var recorded: Dictionary = view.frame.ops.filter(func(value: Dictionary) -> bool: return int(value.id)==main.selected.op_id)[0]
		raw_reference.sample_layers(preload("res://scripts/presentation/actor_pose.gd").sample(recorded,view.frame,"ops"))
		_check(_lengths(carrier,"L").distance_to(_lengths(raw_reference,"L"))<0.0001 and _lengths(carrier,"R").distance_to(_lengths(raw_reference,"R"))<0.0001,"quality preserves both original arm segment lengths "+label)
	var before: Dictionary = main._snapshot_data().duplicate(true)
	view.refresh()
	_check(main._snapshot_data()==before,"quality rendering preserves complete gameplay "+label)

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
	if main==null or not main.has_method("_snapshot_data"):
		_check(false,"production scene compiles and loads")
		quit(1)
		return
	view=main.presentation_3d
	raw_reference.visible=false
	root.add_child(raw_reference)
	main.set_process(false)
	view.set_process(false)
	await _qa_exact()
	_check(completed,"original native MG journey completes")
	if not completed:
		quit(1)
		return
	var id: String = rows.back().body_id
	_measure(id,"hold",true)
	_held_matrix()
	for mode in ["release","grab"]:
		await _native_key(KEY_H)
		view.refresh()
		_check(view.frame.corpses.filter(func(value: Dictionary) -> bool: return value.id==id)[0].mode==mode,"matrix source copies actual new native "+mode+" event")
		phases.append(view.frame.duplicate(true))
		var duration := 0.7 if mode=="release" else 1.0
		var start: float = main._pose_command_clock_s
		var times := [0.0,0.1,0.2,0.25,0.5,0.75,0.999999,1.0] if mode=="grab" else [0.0,0.1,0.35,0.499999,0.5,0.6,0.699999,0.7]
		for step in times.size():
			var age: float = times[step]
			main._pose_command_clock_s=start+age
			view.refresh()
			# Explicit contact contract: approach0..0.2 and return0.5..0.7
			# are ungripped. Do not infer success from the renderer's own flag.
			var gripped: bool = age>=0.2 if mode=="grab" else age<=0.5
			_measure(id,mode+"_"+str(age),gripped)
			copied_frames.append(main._snapshot_data().duplicate(true))
			copied_signatures.append(_pose_signature(id))
			if step==times.size()-1:
				_endpoint_continuity(copied_signatures[-2],copied_signatures[-1],mode)
			if (mode=="grab" and age==0.5) or (mode=="release" and age==0.35):
				_freeze_current(id,mode)
				await _capture(id,"quality_"+mode+"_half")
				await _detail_capture(id,"quality_"+mode+"_desktop_front",65.0)
				await _detail_capture(id,"quality_"+mode+"_desktop_rear",245.0)
	_transition_matrix()
	_sampler_cache()
	await _history(id)
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/corpse-pose-quality-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":quality_rows,"matrix_rows":matrix_rows,"transition_rows":transition_rows,"native_rows":rows,"captures":captures},"  "))
	print("CORPSE_POSE_QUALITY_OK" if failures==0 else "CORPSE_POSE_QUALITY_FAILED"," checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
