extends "res://scripts/corpse_contact_test.gd"

var quality_rows := []

func _measure(id: String, label: String, paired: bool) -> void:
	var visual: Node3D = view.corpses[id]
	var carrier: Actor = view.actors["ops:%d" % main.selected.op_id].get_node("Body")
	var floor := INF
	for point in _vertices(visual.body):
		floor=minf(floor,point.y)
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
	quality_rows.append({"label":label,"mode":visual.get_meta("mode"),"floor_m":floor,"contacts_m":distances,"reaches":reaches,"wall_vertices":_penetrations(visual.body),"body_transform":visual.body.global_transform})
	_check(floor>=-0.015 and floor<=0.015,"quality ground contact within15mm "+label+": "+str(floor))
	_check(_penetrations(visual.body)==0,"quality skin remains outside original brickwall "+label)
	if paired:
		_check(distances.max()<0.015,"quality both actual palms/shoulders within15mm "+label+": "+str(distances))
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
	main.set_process(false)
	view.set_process(false)
	await _qa_exact()
	_check(completed,"original native MG journey completes")
	if not completed:
		quit(1)
		return
	var id: String = rows.back().body_id
	_measure(id,"hold",true)
	for mode in ["release","grab"]:
		await _native_key(KEY_H)
		var duration := 0.7 if mode=="release" else 1.0
		var start: float = main._pose_command_clock_s
		for step in 9:
			main._pose_command_clock_s=start+duration*float(step)/8.0
			view.refresh()
			_measure(id,mode+"_"+str(step),step<8 or mode=="grab")
			if step==4:
				await _capture(id,"quality_"+mode+"_half")
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/corpse-pose-quality-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":quality_rows,"native_rows":rows,"captures":captures},"  "))
	print("CORPSE_POSE_QUALITY_OK" if failures==0 else "CORPSE_POSE_QUALITY_FAILED"," checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
