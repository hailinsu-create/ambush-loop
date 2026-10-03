extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var main: Node
var view: Node3D
var checks := 0
var failures := 0
var completed := false
var rows := []
var captures := []


func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CORPSE_CONTACT: " + message)


func _vertices(actor: Actor) -> PackedVector3Array:
	var result := PackedVector3Array()
	var mesh := Actor.find_type(actor.model,"MeshInstance3D") as MeshInstance3D
	var skin: Skin = mesh.skin
	var transforms := []
	for index in skin.get_bind_count():
		var name: String = skin.get_bind_name(index)
		var bone: int = actor.skeleton.find_bone(name) if not name.is_empty() else skin.get_bind_bone(index)
		transforms.append(actor.skeleton.global_transform * actor.skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(index))
	for surface in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for index in vertices.size():
			var vertex := Vector3.ZERO
			for slot in 4:
				var offset := index*4+slot
				vertex += (transforms[bones[offset]]*vertices[index])*weights[offset]
			result.append(vertex)
	return result


func _penetrations(actor: Actor) -> int:
	var count := 0
	for point in _vertices(actor):
		for wall in view.walls:
			var mesh: Node3D = wall.mesh
			if mesh is MeshInstance3D and str(mesh.name).contains("wall_brick") and wall.bounds.has_point(point):
				count += 1
				break
	return count


func _journey() -> void:
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	main.raid_force_alarm()
	for wave in 2:
		var ticks := 0
		while main.phase == main.Phase.WATCHING and ticks < 12000:
			main._sim_tick()
			ticks += 1
		_check(main.phase == main.Phase.SWEEP,"real yard wave %d reaches SWEEP" % wave)
		if main.phase != main.Phase.SWEEP:
			return
		if wave == 0:
			main.raid_vacuum_loot() # Same explicit first-wave equipment fixture as campaign regression.
			main._on_sweep_commit()
	view.refresh()
	var loot: Node2D
	for candidate in main.loot_piles:
		if not candidate.collected and candidate.kind != "ammo":
			loot = candidate
	_check(loot != null,"second wave creates original non-ammo haulable loot")
	if loot == null:
		return
	# Explicit full-pack fixture: ordinary guns can otherwise be automatically
	# collected, terminating drag before contact. Ammo remains always collectable.
	for op in main.operators:
		op.pack.remove_kind(loot.kind)
		for kind in ["rifle","mg42","luger","sten","mosin","garand","thompson","pistol"]:
			if kind != loot.kind and not op.pack.is_full():
				op.pack.add_item(kind,1)
	for op in main.operators:
		if op.alive and op.visible:
			main._select_op(op.op_id)
			break
	_check(main.selected.alive and main.selected.visible,"native haul uses surviving original operator")
	_check(not main.selected.pack_can_fit(loot.kind),"full-pack fixture blocks original automatic gun collection")
	# Initial proximity fixture only; thereafter use the native mouse/H input
	# and original movement, load and 14px follow. No synthetic body or loot.
	main.selected.global_position = loot.global_position
	view.rig.focus = Space.logic_to_world(main.selected.global_position)
	view.rig.view_size = 18.0
	view.rig.apply_pose()
	view.refresh()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_H
	key.pressed = true
	main._unhandled_input(key)
	_check(main.selected.hauled_loot == loot,"native H grabs real second-wave corpse")
	var id: String = main.visual_snapshot.corpses.id_for_loot(loot)
	_check(not id.is_empty(),"real drop has original body identity")
	if id.is_empty():
		return
	var at := Vector2(592,176)
	view.rig.focus = Space.logic_to_world(at)
	view.rig.view_size = 24.0
	view.rig.apply_pose()
	view.refresh()
	var steps := 0
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	# A distant waypoint avoids clicking the selected actor's projected body.
	for waypoint in [Vector2(592,112),at]:
		mouse.position = view.rig.project_logic(waypoint)
		mouse.global_position = mouse.position
		main._unhandled_input(mouse)
		_check(main.selected.is_moving(),"native projected mouse issues original path to "+str(waypoint))
		while main.selected.is_moving() and steps < 2400:
			main._process(0.1)
			steps += 1
		view.refresh()
		_check(main.selected.global_position.distance_to(waypoint)<3.0,"native original path reaches original snap tolerance at "+str(waypoint))
	_check(main.selected.global_position.distance_to(at)<3.0,"original path reaches original snap tolerance at (592,176)")
	_check(main.selected.hauled_loot == loot and loot.global_position == main.selected.global_position+Vector2(0,14),"original haul reference and 14px follow persist")
	_check(not loot.collected,"original full pack retains actual haulable corpse")
	mouse.button_index = MOUSE_BUTTON_RIGHT
	mouse.position = view.rig.project_logic(main.selected.global_position+Vector2(0,96))
	mouse.global_position = mouse.position
	main._unhandled_input(mouse)
	_check(is_equal_approx(main.selected.facing_deg,90.0),"native right mouse turns gameplay facing toward +Y")
	main._process(1.2)
	view.refresh()
	var visual: Node3D = view.corpses[id]
	var penetrations := _penetrations(visual.body)
	rows.append({"level":"yard","wave":main.battle_log.wave_id,"pos":main.selected.global_position,"kind":loot.kind,"body_id":id,"vertices_inside_brickwall":penetrations,"path_steps":steps,"visual_facing":visual.get_meta("contact_facing",90.0)})
	_check(penetrations==0,"actual imported corpse skin stays outside brickwall; vertices="+str(penetrations))
	if OS.get_environment("AMBUSH_CONTACT_SCOPE") != "negative":
		await _validate(id,loot)
	completed = true


func _signature(id: String) -> Array:
	var actor: Actor = view.actors["ops:%d" % view.frame.corpses.filter(func(item: Dictionary) -> bool: return item.id==id)[0].carrier.id].get_node("Body")
	return [view.corpses[id].body.global_transform,actor.global_transform]


func _skin_contract(id: String, paired: bool) -> void:
	var visual: Node3D = view.corpses[id]
	_check(bool(visual.get_meta("contact_supported",false)) and bool(visual.get_meta("contact_resolved",false)),"copied contact schema resolves visual placement")
	_check(_penetrations(visual.body)==0,"actual skinned vertices avoid brickwall")
	var floor := INF
	for point in _vertices(visual.body):
		floor=minf(floor,point.y)
	_check(floor>=-0.015,"visual turn preserves original floor allowance")
	if paired:
		var carrier: Actor = view.actors["ops:%d" % main.selected.op_id].get_node("Body")
		_check(visual.body.shoulder("L").distance_to(carrier.bone_socket("support_hand").position)<0.015 and visual.body.shoulder("R").distance_to(carrier.bone_socket("weapon_hand").position)<0.015,"both imported shoulders remain within 15mm of actual palms")
	_check(visual.position==Space.logic_to_world(view.frame.corpses.filter(func(item: Dictionary) -> bool: return item.id==id)[0].pos),"proxy root remains historical gameplay loot position")


func _capture(id: String, name: String) -> void:
	if DisplayServer.get_name()=="headless":
		return
	view.rig.focus=Space.logic_to_world(view.frame.corpses.filter(func(item: Dictionary) -> bool: return item.id==id)[0].carrier.pos)
	view.rig.view_size=8.0
	view.rig.yaw_deg=65.0
	view.rig.pitch_deg=55.0
	view.rig.apply_pose()
	main._update_hud()
	view.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://build/asset_review/pr15-runtime/contact_"+name+".png"
	_check(root.get_texture().get_image().save_png(path)==OK,"capture "+name)
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path)})


func _validate(id: String, loot: Node2D) -> void:
	var initial: Dictionary = main._snapshot_data().duplicate(true)
	var held_signature := _signature(id)
	for repeat in 8:
		view.refresh()
	_check(_signature(id)==held_signature and main._snapshot_data()==initial,"repeated wall contact refresh never accumulates placement or changes gameplay")
	var canonical: Array = view._environment_scene.contact_bounds().duplicate()
	for stance in 2:
		if int(main.selected.stance)!=stance:
			main.selected.toggle_crouch()
		for size in [10.0,24.0,50.0]:
			view.rig.view_size=size
			view.rig.apply_pose()
			for face in range(0,360,30):
				var mouse := InputEventMouseButton.new()
				mouse.button_index=MOUSE_BUTTON_RIGHT
				mouse.pressed=true
				var direction := Vector2(cos(deg_to_rad(float(face))),sin(deg_to_rad(float(face))))
				mouse.position=view.rig.project_logic(main.selected.global_position+direction*96.0)
				main._unhandled_input(mouse)
				var before: Dictionary = main._snapshot_data().duplicate(true)
				view.refresh()
				_skin_contract(id,true)
				_check(main._snapshot_data()==before and main.selected.hauled_loot==loot and loot.global_position==main.selected.global_position+Vector2(0,14),"camera and contact turn preserve original facing/position/load/ref/follow/events")
				_check(view._environment_scene.contact_bounds()==canonical,"camera LOD keeps canonical contact surfaces")
				rows.append({"stance":stance,"view_size":size,"body_lod":view.corpses[id].body.lod,"gameplay_facing":main.selected.facing_deg,"visual_facing":view.corpses[id].get_meta("contact_facing"),"vertices_inside_brickwall":_penetrations(view.corpses[id].body)})
	# Restore the exact recorded contact direction through the original input.
	main.selected.set_facing(90.0)
	if int(main.selected.stance)!=0:
		main.selected.toggle_crouch()
	view.rig.view_size=24.0
	view.rig.apply_pose()
	view.refresh()
	var held: Dictionary = main._snapshot_data().duplicate(true)
	await _capture(id,"held")
	main._drop_hauled(main.selected)
	for age in [0.0,0.35,0.7]:
		main._pose_command_clock_s += age-float(view.frame.corpses.filter(func(item: Dictionary) -> bool: return item.id==id)[0].transition_age_s)
		view.refresh()
		_skin_contract(id,false)
		await _capture(id,"release_%d" % roundi(age*100.0))
	_check(not main.selected.is_hauling() and loot.global_position==held.corpses.filter(func(item: Dictionary) -> bool: return item.id==id)[0].pos,"actual release preserves original game loot position")
	var key := InputEventKey.new()
	key.physical_keycode=KEY_H
	key.pressed=true
	main._unhandled_input(key)
	_check(main.selected.hauled_loot==loot,"native H re-grabs the same actual body next to wall")
	for delta in [0.0,0.5,0.5]:
		main._pose_command_clock_s+=delta
		view.refresh()
		_skin_contract(id,float(view.frame.corpses.filter(func(item: Dictionary) -> bool: return item.id==id)[0].transition_age_s)>=1.0)
	var paused := _signature(id)
	main._toggle_pause_menu()
	main._process(0.4)
	view.refresh()
	_check(_signature(id)==paused,"paused wall contact is stationary")
	main.pause_overlay.dismiss()
	main.handle_app_focus_out()
	main._process(0.4)
	view.refresh()
	_check(_signature(id)==paused,"background wall contact is stationary")
	main.handle_app_focus_in()
	main._drop_hauled(main.selected)
	main._pose_command_clock_s+=0.7
	view.refresh()
	var grounded: Dictionary = main._snapshot_data().duplicate(true)
	var log := BattleLog.new()
	log.attempt_id=main.battle_log.attempt_id
	log.wave_id=main.battle_log.wave_id
	log.add_snapshot(0,held)
	log.add_snapshot(60,grounded)
	log.mark_terminal(60,"copied-contact-fixture")
	var original: Array = log.snapshots.duplicate(true)
	main.replay.bind(log)
	main.phase=main.Phase.REPLAY
	main.grid.blocked.fill(0)
	main.selected.global_position+=Vector2(320,224)
	main.selected.set_facing(181.0)
	main.run_id+=900
	main._pose_command_clock_s=999.0
	var live: Dictionary = main._snapshot_data().duplicate(true)
	var start := []
	for tick in [0,60,0]:
		main.replay.set_tick(tick)
		view.refresh()
		_skin_contract(id,tick==0)
		_check(main._snapshot_data()==live and log.snapshots==original,"read-only contact seek ignores poisoned live inputs and never modifies source")
		if tick==0:
			if start.is_empty():
				start=_signature(id)
			else:
				_check(_signature(id)==start,"backward seek restores exact contact placement")
	await _capture(id,"history")
	for version in [0,99]:
		var legacy: Dictionary = held.duplicate(true)
		legacy.corpse_contact_schema=version
		var old := BattleLog.new()
		old.attempt_id=log.attempt_id
		old.wave_id=log.wave_id
		old.add_snapshot(0,legacy)
		main.replay.bind(old)
		view.refresh()
		_check(not bool(view.corpses[id].get_meta("contact_supported",true)) and _penetrations(view.corpses[id].body)>0,"old/unknown contact schema preserves original recorded placement")


func _run() -> void:
	root.size=Vector2i(1280,720)
	var settings=root.get_node("GameSettings")
	settings.mark_tutorial_seen("yard")
	settings.set_force_touch_hud(false)
	settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	view=main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	await _journey()
	_check(completed,"native second-wave regression completes")
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/corpse-contact-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures,"scope":"actual two-wave yard kills and native H/mouse path, first-wave vacuum/full-pack/proximity fixture; copied contact history; cloud only"},"  "))
	print("CORPSE_CONTACT_OK" if failures==0 else "CORPSE_CONTACT_FAILED"," checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
