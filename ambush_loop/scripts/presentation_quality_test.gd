extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
var main: Node
var view: Node3D
var checks := 0
var failures := 0
var captures := []
var rows := []
var completed := 0
var _checked_lods := {}

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
		var free: bool = not view.pointer_over_ui(screen) and not view.pointer_over_ui(foot)
		rows.append({"level":"depot","phase":"SWEEP","tick":main.sim.tick,"id":op.op_id,"screen":screen,"foot":foot,"unobscured":free})
		_check(free,"depot low-angle actor and lower body unobscured "+str(op.op_id))
		var pick: Dictionary = view.pick_at(screen)
		_check(pick.get("kind","")=="op" and pick.get("id",-1)==op.op_id,"depot actual actor remains valid pick target")
		main._select_op((index+1)%main.operators.size())
		await _mouse(screen)
		_check(main.selected==op,"native mouse selects exact depot actor through visible world target")
		targets+=1
	_check(targets>0,"depot has actual living click targets")
	main._select_op(0)
	main._update_hud()
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
				var lod: int = view._environment_lod
				if not _checked_lods.has(lod):
					var reference := Assets.instantiate("env_radio_antenna",lod)
					_check(_triangles(landmark)==_triangles(reference),"radio split preserves every original triangle/vertex/normal/UV/tangent at LOD"+str(lod))
					var imported := []
					_meshes(reference,imported)
					_check(meshes.all(func(mesh: MeshInstance3D) -> bool: return mesh.get_active_material(0)==imported[0].get_active_material(0)),"radio solids retain original atlas material at LOD"+str(lod))
					reference.free()
					_checked_lods[lod]=true
				if yaw==345 and ((pitch==35 and size==14) or (pitch==55 and size==30)):
					await _capture("radio_yaw345_pitch%d_size%d" % [pitch,size])
	completed+=1
	await _history_radio(source)
	_cutaway_compatibility(source)
	await _layout_matrix()

func _append_triangles(node: Node, transform: Transform3D, result: PackedStringArray, attribute: String) -> void:
	if node is Node3D:
		transform=transform*node.transform
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for index in vertices.size():
					indices.append(index)
			for offset in range(0,indices.size(),3):
				var triangle := []
				for corner in 3:
					var index := indices[offset+corner]
					if attribute in ["all","position"]:
						triangle.append(transform*vertices[index])
					for slot in [Mesh.ARRAY_NORMAL,Mesh.ARRAY_TEX_UV,Mesh.ARRAY_TANGENT]:
						if attribute!="all" and attribute!=({Mesh.ARRAY_NORMAL:"normal",Mesh.ARRAY_TEX_UV:"uv",Mesh.ARRAY_TANGENT:"tangent"}[slot]):
							continue
						var values: Variant = arrays[slot]
						if values!=null and values.size()>0:
							var width: int = values.size()/vertices.size()
							for sub in width:
								triangle.append(values[index*width+sub])
				result.append(var_to_bytes(triangle).hex_encode())
	for child in node.get_children():
		_append_triangles(child,transform,result,attribute)

func _triangles(asset: Node, attribute: String = "all") -> PackedStringArray:
	var value := PackedStringArray()
	# Ignore only the caller's asset-root placement; all imported mesh-local
	# transforms and exact unquantized attributes remain in this oracle.
	for child in asset.get_children():
		_append_triangles(child,Transform3D.IDENTITY,value,attribute)
	value.sort()
	return value

func _history_radio(source: Dictionary) -> void:
	var log := BattleLog.new()
	log.attempt_id=main.battle_log.attempt_id
	log.wave_id=main.battle_log.wave_id
	log.add_snapshot(0,source)
	var later: Dictionary = source.duplicate(true)
	later.ops[0].pos+=Vector2(32,0)
	log.add_snapshot(60,later)
	log.mark_terminal(60,"copied-radio-layout")
	var original: Array = log.snapshots.duplicate(true)
	main.phase=main.Phase.REPLAY
	main.replay.bind(log)
	main.grid.blocked.fill(0)
	main.level.level_id="live-only"
	main.selected.global_position+=Vector2(256,224)
	var live: Dictionary = main._snapshot_data().duplicate(true)
	var signature := []
	for tick in [0,60,0]:
		main.replay.set_tick(tick)
		_pose(345,35,14)
		var landmark := _find(view.geometry,"env_radio_antenna")
		var meshes := []
		_meshes(landmark,meshes)
		var shown := []
		for mesh: MeshInstance3D in meshes:
			shown.append([mesh.global_transform,mesh.visible])
		_check(meshes.any(func(mesh: MeshInstance3D) -> bool: return mesh.visible),"historical radio retains landmark using copied layout")
		_check(main._snapshot_data()==live and log.snapshots==original,"radio history never borrows/mutates poisoned live world or records")
		if tick==0:
			if signature.is_empty():
				signature=shown
			else:
				_check(shown==signature,"radio backward seek restores exact partial cutaway")
	await _capture("radio_history")

func _cutaway_compatibility(source: Dictionary) -> void:
	for schema in [0,99,1]:
		var data: Dictionary = source.duplicate(true)
		if schema==0:
			data.erase("environment_cutaway_schema")
		else:
			data.environment_cutaway_schema=schema
		var log := BattleLog.new()
		log.add_snapshot(0,data)
		var original: Array = log.snapshots.duplicate(true)
		var live: Dictionary = main._snapshot_data().duplicate(true)
		main.replay.bind(log)
		_pose(345,35,14)
		var landmark := _find(view.geometry,"env_radio_antenna")
		var meshes := []
		_meshes(landmark,meshes)
		_check(view.frame.environment_cutaway_schema==schema,"cutaway policy comes only from copied record")
		_check((meshes.size()>1)==(schema==1),"missing/unknown cutaway version retains original unsplit geometry")
		_check(main._snapshot_data()==live and log.snapshots==original,"cutaway version changes do not modify live world or old records")

func _layout_matrix() -> void:
	for touch in [false,true,false]:
		root.get_node("GameSettings").set_force_touch_hud(touch)
		main._update_hud()
		await process_frame
		_check(main.c2.portraits.is_visible_in_tree()==touch,"3D historical desktop uses one role rail, phone keeps original portraits")
		_check(main.role_box.is_visible_in_tree()==(not touch),"historical role rail switches with input mode")
		_check(main._snapshot_data().phase==main.Phase.REPLAY,"layout changes preserve replay phase")
		var before: Dictionary = main._snapshot_data().duplicate(true)
		if touch:
			var at: Vector2 = main.c2.portraits.card_global_rect(0).get_center()
			await _mouse(at)
		else:
			await _mouse(main.role_cards[0].get_global_rect().get_center())
		_check(main._snapshot_data()==before,"native historical card click is read-only")
	for size in [Vector2i(1280,720),Vector2i(1600,720)]:
		root.size=size
		await process_frame
		_pose(345,55,30)
		_check(main.role_box.get_global_rect().end.y<root.get_visible_rect().size.y-100,"desktop rail stays above command region across landscape ratios")
		var landmark := _find(view.geometry,"env_radio_antenna")
		var meshes := []
		_meshes(landmark,meshes)
		_check(meshes.any(func(mesh: MeshInstance3D) -> bool: return mesh.visible),"landscape resize keeps historical radio recognizable")
	root.size=Vector2i(1280,720)

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
	if main==null or not main.has_method("_snapshot_data"):
		_check(false,"production scene compiles and loads")
		quit(1)
		return
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
