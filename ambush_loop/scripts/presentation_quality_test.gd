extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var main: Node
var view: Node3D
var checks := 0
var failures := 0
var captures := []
var rows := []
var completed := 0

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("PRESENTATION_QUALITY: "+message)

func _meshes(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_meshes(child,result)

func _find(node: Node, id: String) -> Node:
	if node.get_meta("asset_id","")==id:
		return node
	for child in node.get_children():
		var result := _find(child,id)
		if result!=null:
			return result
	return null

func _pose(yaw: float, pitch: float, size: float) -> void:
	view.rig.focus=Vector3.ZERO
	view.rig.yaw_deg=yaw
	view.rig.pitch_deg=pitch
	view.rig.view_size=size
	view.rig.apply_pose()
	view._occlusion_acc=0.2
	main._update_hud()
	view.refresh()

func _capture(name: String) -> void:
	if DisplayServer.get_name()=="headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://build/asset_review/pr15-runtime/quality_"+name+".png"
	_check(root.get_texture().get_image().save_png(path)==OK,"capture "+name)
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path)})

func _mouse(at: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		event.position=at
		event.global_position=at
		Input.parse_input_event(event)
		await process_frame

func _depot() -> void:
	main._load_level("depot",false,false)
	await process_frame
	main.raid_prepare_ref([1,4,5],[270.0,270.0,180.0])
	main._try_place_tripwire(main.grid.cell_to_world_center(Vector2i(7,11)))
	main.raid_force_alarm()
	var ticks := 0
	while main.phase==main.Phase.WATCHING and ticks<12000:
		main._sim_tick()
		ticks+=1
	_check(main.phase==main.Phase.SWEEP and main.sim.tick==566,"actual depot first wave reaches original SWEEP566")
	_pose(270,35,24)
	await process_frame
	var targets := 0
	for index in main.operators.size():
		var op=main.operators[index]
		if not op.alive or not op.visible:
			continue
		var screen: Vector2 = view.rig.project_logic(op.global_position,0.9)
		var foot: Vector2 = view.rig.project_logic(op.global_position,0.15)
		var free := not view.pointer_over_ui(screen) and not view.pointer_over_ui(foot)
		rows.append({"level":"depot","phase":"SWEEP","tick":main.sim.tick,"id":op.op_id,"screen":screen,"foot":foot,"unobscured":free})
		_check(free,"depot low-angle actor and lower body unobscured "+str(op.op_id))
		var pick: Dictionary = view.pick_at(screen)
		_check(pick.get("kind","")=="op" and pick.get("id",-1)==op.op_id,"depot actual actor remains valid pick target")
		main._select_op((index+1)%main.operators.size())
		await _mouse(screen)
		_check(main.selected==op,"native mouse selects exact depot actor through visible world target")
		targets+=1
	_check(targets>0,"depot has actual living click targets")
	await _capture("depot_sweep_low")
	completed+=1

func _radio() -> void:
	main._load_level("radio",false,false)
	await process_frame
	main.raid_prepare_ref([1,4,5],[270.0,90.0,270.0])
	var source: Dictionary = main._snapshot_data().duplicate(true)
	for yaw in [330.0,345.0,0.0]:
		for pitch in [35.0,55.0]:
			for size in [14.0,24.0,30.0]:
				_pose(yaw,pitch,size)
				var landmark := _find(view.geometry,"env_radio_antenna")
				_check(landmark!=null,"actual radio landmark exists")
				var meshes := []
				_meshes(landmark,meshes)
				var visible := meshes.filter(func(mesh: MeshInstance3D) -> bool: return mesh.is_visible_in_tree()).size()
				rows.append({"level":"radio","yaw":yaw,"pitch":pitch,"size":size,"meshes":meshes.size(),"visible":visible})
				_check(visible>0,"radio landmark retains visible geometry yaw/pitch/size %d/%d/%d" % [yaw,pitch,size])
				_check(main._snapshot_data()==source,"radio cutaway/camera never mutates gameplay")
				if yaw==345 and ((pitch==35 and size==14) or (pitch==55 and size==30)):
					await _capture("radio_yaw345_pitch%d_size%d" % [pitch,size])
	completed+=1

func _run() -> void:
	root.size=Vector2i(1280,720)
	var settings=root.get_node("GameSettings")
	for level in ["yard","depot","radio"]:
		settings.mark_tutorial_seen(level)
	settings.set_force_touch_hud(false)
	settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	view=main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	await _depot()
	await _radio()
	_check(completed==2,"both actual stages complete")
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/quality-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures},"  "))
	print("PRESENTATION_QUALITY_OK" if failures==0 else "PRESENTATION_QUALITY_FAILED"," checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
