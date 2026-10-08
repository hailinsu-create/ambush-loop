extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Actor := preload("res://scripts/presentation/actor_visual.gd")
const Pose := preload("res://scripts/presentation/actor_pose.gd")
const Corpse := preload("res://scripts/presentation/corpse_pose.gd")
const BodyVisual := preload("res://scripts/presentation/corpse_visual.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var main: Node
var view: Node3D
var checks := 0
var failures := 0
var completed := 0
var captures := []
var pair_rows := []

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("CORPSE_RUNTIME: " + message)

func _reset(level_id: String = "yard") -> void:
	main._load_level(level_id, false, false)
	main.raid_prepare_ref([1,2,5], [90.0,180.0,180.0], {"grenades":2,"mines":0})
	main._select_op(0)
	view.refresh()

func _actor() -> Actor:
	view.refresh()
	return view.actors["ops:%d" % main.selected.op_id].get_node("Body") as Actor

func _signature(body: Actor) -> Array:
	var value := [body.global_transform, body.sampled_action, body.sampled_time]
	for index in body.skeleton.get_bone_count():
		value.append(body.skeleton.get_bone_pose(index))
	return value

func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	view.rig.focus = Space.logic_to_world(main.selected.global_position)
	view.rig.view_size = 10.0
	view.rig.yaw_deg = 65.0
	view.rig.apply_pose()
	main._update_hud()
	view.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://build/asset_review/pr15-runtime/corpse_" + name + ".png"
	_check(root.get_texture().get_image().save_png(path) == OK, "capture " + name)
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path)})

func _actual() -> void:
	_reset()
	var op = main.selected
	var sentry = main.c2.sentries.front()
	op.global_position = sentry.backstab_world()
	op.facing_deg = sentry.facing_deg
	_check(main.c2._skill_knife(op), "production C2 knockout succeeds")
	view.refresh()
	var loot = main.loot_piles.back()
	var source: Dictionary = main._snapshot_data().duplicate(true)
	_check(source.corpses.size() == 1 and source.corpses[0].source_group == "sentries" and loot.kind == "ammo", "body links only actual successful source without changing loot kind")
	var id: String = source.corpses[0].id
	_check(not view.actors["sentries:%d" % sentry.label_id].visible, "linked source proxy is replaced once")
	main._toggle_haul_corpse()
	_check(op.hauled_loot == loot and loot.global_position == op.global_position + Vector2(0,14), "original instantaneous haul and screen-axis follow are preserved")
	_check(_actor().sampled_action == "corpse_grab", "successful H records grab")
	var grab: Dictionary = main._snapshot_data().duplicate(true)
	var event: String = grab.corpses[0].transition.event_id
	# Explicit presentation-clock fixture: ordinary loose ammo auto-pickup is
	# deliberately not ticked during this pairing matrix; checked separately below.
	main._pose_command_clock_s += 0.5
	view.refresh()
	_check(_actor().sampled_action == "corpse_grab" and is_equal_approx(_actor().sampled_time,0.5), "copied command clock samples half grab")
	await _capture("grab_half")
	main._pose_command_clock_s += 0.5
	view.refresh()
	_check(_actor().sampled_action == "corpse_drag", "grab reaches hold endpoint")
	var visual = view.corpses[id]
	var palms: Vector3 = (_actor().bone_socket("support_hand").position + _actor().bone_socket("weapon_hand").position)*0.5
	var shoulders: Vector3 = (visual.body.shoulder("L")+visual.body.shoulder("R"))*0.5
	_check(palms.distance_to(shoulders)<0.0001, "actual imported shoulders match actual palms")
	_check(visual.position == Space.logic_to_world(loot.global_position), "body proxy retains original loot root")
	var held: Dictionary = main._snapshot_data().duplicate(true)
	var held_sig := _signature(visual.body)
	for repeat in 8:
		view.refresh()
	_check(_signature(visual.body)==held_sig, "eight refreshes apply embedded backshift only once")
	await _capture("hold")
	main._toggle_pause_menu()
	var paused := _signature(visual.body)
	main._process(0.4)
	_check(_signature(view.corpses[id].body)==paused, "paused command has no corpse advancement")
	main.pause_overlay.dismiss()
	main.handle_app_focus_out()
	main._process(0.4)
	_check(_signature(view.corpses[id].body)==paused, "background command has no corpse advancement")
	main.handle_app_focus_in()
	var original_pos: Vector2 = loot.global_position
	main._toggle_haul_corpse()
	_check(not op.is_hauling() and loot.global_position==original_pos and _actor().sampled_action=="corpse_release", "real drop records release without moving gameplay loot")
	main._pose_command_clock_s += 0.35
	view.refresh()
	await _capture("release_half")
	main._pose_command_clock_s += 0.35
	view.refresh()
	_check(view.corpses[id].body.sampled_action=="corpse_prone" and _actor().sampled_action!="corpse_release", "release reaches ground and restores actor pose")
	await _capture("ground")
	# Read-only seek with poisoned live actor/clock and a later unrelated wave.
	var log := BattleLog.new()
	# Replay envelope and copied corpse transition must share the source attempt;
	# only the live host identity is poisoned below.
	log.attempt_id = str(grab.corpses[0].transition.attempt_id)
	log.wave_id = 0
	log.add_snapshot(0,grab)
	log.add_snapshot(60,held)
	log.mark_terminal(60,"fixture")
	main.replay.bind(log)
	main.phase = main.Phase.REPLAY
	op.global_position += Vector2(160,96)
	op.facing_deg += 91.0
	op.apply_weapon("knife",false)
	main.battle_log.attempt_id = "poisoned-live-attempt"
	main.run_id += 900
	main._pose_command_clock_s = 999.0
	main.battle_log.wave_id += 9
	var live_before: Dictionary = main.visual_snapshot.corpses.records.duplicate(true)
	main.replay.set_tick(0)
	view.refresh()
	_check(_actor().sampled_action=="corpse_grab" and view.frame.corpses[0].transition.event_id==event, "historical grab retains original identity with poisoned live inputs")
	var start := _signature(view.corpses[id].body)
	main.replay.set_tick(60)
	view.refresh()
	_check(_actor().sampled_action=="corpse_drag", "forward seek samples copied held state")
	main.replay.set_tick(0)
	view.refresh()
	_check(_signature(view.corpses[id].body)==start and main.visual_snapshot.corpses.records==live_before, "backward seek is exact and leaves recorder untouched")
	for field in ["scope_id","event_id","attempt_id","wave_id","phase","actor_id","weapon"]:
		var probe: Dictionary = view.frame.duplicate(true)
		if field=="scope_id":
			probe.corpses[0][field]="foreign"
		else:
			probe.corpses[0].transition[field]="foreign" if field in ["event_id","attempt_id","weapon"] else 99
		_check(Pose.sample(probe.ops[0],probe,"ops").action!="corpse_grab","foreign body event refuses "+field)
	for schema in [0,2,99]:
		var probe: Dictionary = view.frame.duplicate(true)
		probe.corpse_schema=schema
		_check(not Corpse.supported(probe) and Pose.sample(probe.ops[0],probe,"ops").action!="corpse_grab", "unknown/missing corpse schema never borrows new action")
	_reset()
	_check(main._snapshot_data().corpses.is_empty() and main._snapshot_data().utility_scope_id!=source.utility_scope_id, "new level clears corpse IDs and creates independent scope")
	# Ordinary runtime auto-pickup must interrupt the decorative action normally.
	op=main.selected
	sentry=main.c2.sentries.front()
	op.global_position=sentry.backstab_world()
	main.c2._skill_knife(op)
	loot=main.loot_piles.back()
	main._toggle_haul_corpse()
	main._tick_command_pickups(0.01)
	view.refresh()
	_check(loot.collected and _actor().sampled_action!="corpse_grab" and view.frame.corpses[0].mode=="ground", "original loose-ammo auto-pickup cancels grab without blocking collection")
	completed += 1

func _floor(actor: Actor) -> float:
	var minimum := INF
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
			minimum = minf(minimum,vertex.y)
	return minimum

func _matrix() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var carrier := Actor.new()
	stage.add_child(carrier)
	var visual := BodyVisual.new()
	stage.add_child(visual)
	var frame := {"corpse_schema":1,"animation_schema":3,"actor_asset_revision":Pose.ASSET_REVISION,"utility_scope_id":"fixture","pose_clock_s":1.2,"pose_snapshot_delta_s":0.0,"wave_id":0,"recorded_phase":0,"attempt_id":"fixture-attempt"}
	for lod in 3:
		for role in ["operator_rifle","operator_mg","operator_scout"]:
			carrier.set_asset(role,lod,Pose.ASSET_REVISION)
			for stance in [0,1]:
				var pose := {"action":"corpse_drag","seconds":0.0}
				if stance==1:
					pose.merge({"base_action":"crouch","base_seconds":0.0,"upper_action":"corpse_drag","upper_seconds":0.0,"preserve_upper_world_basis":false})
				carrier.sample_layers(pose)
				for model in ["enemy_patrol","enemy_flank","enemy_sneak","enemy_radio"]:
					var item := {"schema":1,"id":"fixture:body:0","scope_id":"fixture","asset_revision":Pose.ASSET_REVISION,"model":model,"pos":Vector2(640,366),"source_group":"enemies","source_wave_id":0,"facing":90.0,"mode":"hold","carrier_id":0,"pairing":true,"ever_grabbed":true,"active":true,"transition_age_s":0.0,"carrier":{"id":0,"pos":Vector2(640,352),"model":role,"facing":90.0,"stance":stance},"ground_anchor":{}}
					carrier.position=Space.logic_to_world(item.carrier.pos)
					carrier.rotation.y=Space.facing_yaw(90.0)
					_check(visual.sync(item,frame,lod,carrier),"pair model loads")
					var palms: Vector3 = (carrier.bone_socket("support_hand").position+carrier.bone_socket("weapon_hand").position)*0.5
					_check(((visual.body.shoulder("L")+visual.body.shoulder("R"))*0.5).distance_to(palms)<0.0001,"pair midpoint survives role/LOD/stance")
					_check(visual.body.shoulder("L").distance_to(carrier.bone_socket("support_hand").position)<0.015 and visual.body.shoulder("R").distance_to(carrier.bone_socket("weapon_hand").position)<0.015,"both shoulder markers remain within15mm")
					var floor := _floor(visual.body)
					_check(floor>=-0.015,"imported pair floor "+role+"/"+model+"/"+str(lod)+"/"+str(stance)+": "+str(floor))
					pair_rows.append({"role":role,"model":model,"lod":lod,"stance":stance,"min_y_m":floor})
					for cycle in [0.3,0.6,0.9]:
						var moving_pose: Dictionary = pose.duplicate(true)
						moving_pose.seconds=cycle
						if stance==1:
							moving_pose.base_action="crouch_walk"
							moving_pose.base_seconds=cycle
							moving_pose.upper_seconds=cycle
						carrier.sample_layers(moving_pose)
						visual.sync(item,frame,lod,carrier)
						_check(visual.body.shoulder("L").distance_to(carrier.bone_socket("support_hand").position)<0.015 and visual.body.shoulder("R").distance_to(carrier.bone_socket("weapon_hand").position)<0.015,"moving cycle retains both actual contacts")
						_check(_floor(visual.body)>=-0.015,"moving cycle imported skin floor")
					carrier.sample_layers(pose)
					for mode in ["grab","release"]:
						item.mode=mode
						item.transition={"event_id":"fixture:corpse:0:0","seq":0,"attempt_id":"fixture-attempt","wave_id":0,"phase":0,"actor_id":0,"weapon":"rifle"}
						for phase in [0.0,0.5,1.0]:
							item.transition_age_s=phase*(1.0 if mode=="grab" else 0.7)
							visual.sync(item,frame,lod,carrier)
							_check(_floor(visual.body)>=-0.015,"imported transition floor "+mode+"/"+str(phase)+"/"+str(stance))
	stage.free()
	completed += 1

func _ko(level_id: String = "yard") -> Node:
	_reset(level_id)
	var op=main.selected
	var sentry=main.c2.sentries.front()
	op.global_position=sentry.backstab_world()
	op.facing_deg=sentry.facing_deg
	_check(main.c2._skill_knife(op),"cancel fixture uses successful original knockout")
	main._toggle_haul_corpse()
	_check(_actor().sampled_action=="corpse_grab","cancel fixture begins successful grab")
	return main.loot_piles.back()

func _cancellations() -> void:
	var moving_loot = _ko()
	var moving_op = main.selected
	main._command_move_selected(moving_op.global_position + Vector2(96,0))
	_check(moving_op.is_moving() and _actor().sampled_action=="corpse_drag" and view.frame.corpses[0].transition.is_empty(),"actual new move cancels grab to ongoing original haul")
	var initial: Vector2 = moving_op.global_position
	main._pose_command_clock_s += 0.05
	main._tick_command_moves(0.05)
	view.refresh()
	_check(moving_op.global_position!=initial and moving_loot.global_position==moving_op.global_position+Vector2(0,14),"original movement/follow advance immediately during drag")
	var moving_id: String = view.frame.corpses[0].id
	var moving_body = view.corpses[moving_id].body
	_check(moving_body.shoulder("L").distance_to(_actor().bone_socket("support_hand").position)<0.015 and moving_body.shoulder("R").distance_to(_actor().bone_socket("weapon_hand").position)<0.015,"actual moving carrier pairs imported palms with imported shoulders")
	var loot=_ko()
	var op=main.selected
	var before: int = main.visual_snapshot.corpses._seq
	var original: String = op.weapon_id
	op.pack.add_item("mg42",1)
	op.pack.add_item(original,1)
	main._on_pack_equip("mg42")
	main._on_pack_equip(original)
	_check(op.is_hauling() and _actor().sampled_action=="corpse_drag" and main.visual_snapshot.corpses._seq==before,"same-frame real equip roundtrip cancels grab once, keeps actual haul")
	var id: String = view.frame.corpses[0].id
	main._select_op(1)
	_check(view.frame.corpses[0].carrier_id==op.op_id,"changing selection keeps original physical carrier")
	var other=main.selected
	other.global_position=loot.global_position
	other.haul_loot(loot)
	main._tick_haul_follow(op)
	main._tick_haul_follow(other)
	view.refresh()
	_check(op.hauled_loot==loot and other.hauled_loot==loot and view.frame.corpses[0].carrier_id==other.op_id and loot.global_position==other.global_position+Vector2(0,14),"shared original references keep last follow operator ownership without adding lock")
	_check(view.frame.corpses[0].transition.is_empty(),"handoff cannot attach original grab event to a new carrier")
	other._die()
	main._tick_haul_follow(op)
	view.refresh()
	_check(other.is_hauling() and op.is_hauling() and view.frame.corpses[0].carrier_id==op.op_id,"dead carrier is visual cancel only, original hauling references unchanged")
	main._select_op(0)
	main._drop_hauled(op)
	_actor()
	_check(view.frame.corpses[0].mode=="release","real drop begins release")
	op.pack.add_item("mg42",1)
	main._on_pack_equip("mg42")
	_check(_actor().sampled_action!="corpse_release" and view.frame.corpses[0].mode=="ground","actual equip interrupts release to ground")
	loot=_ko("warehouse")
	op=main.selected
	var source_wave: int = view.frame.wave_id
	id=view.frame.corpses[0].id
	main.raid_force_alarm()
	view.refresh()
	_check(op.is_hauling() and view.frame.corpses[0].id==id and view.frame.corpses[0].source_wave_id==source_wave and view.frame.corpses[0].transition.is_empty() and _actor().sampled_action not in ["corpse_grab","corpse_drag"],"ALERT preserves original haul and source identity while cancelling command pairing")
	_check(main.level.wave_count() > 1, "cross-wave fixture uses an authored multi-wave mission")
	main._begin_next_wave()
	view.refresh()
	_check(view.frame.wave_id==source_wave+1 and view.frame.corpses[0].id==id and view.frame.corpses[0].source_wave_id==source_wave and view.frame.corpses[0].transition.is_empty(),"cross-wave cannot rebind old body/event to new wave")
	# Actual EnemyRunner.kill signal, without introducing a synthetic body item.
	_check(not main.pending_spawns.is_empty(), "authored next wave supplies a real enemy")
	if main.pending_spawns.is_empty(): return
	main._spawn_one(main.pending_spawns.front())
	var enemy=main.enemies.front()
	enemy.kill()
	view.refresh()
	_check(view.frame.corpses.size()==2 and view.frame.corpses.back().source_group=="enemies" and view.frame.corpses.back().source_wave_id==view.frame.wave_id,"actual normal enemy death records distinct current-wave source")
	_reset()
	op=main.selected
	before=main.visual_snapshot.corpses._seq
	op.global_position=Vector2(640,352)
	main._toggle_haul_corpse()
	_check(not op.is_hauling() and main.visual_snapshot.corpses._seq==before and view.frame.corpses.is_empty(),"failed nearest selection adds no corpse event")
	var ordinary=main._spawn_loot_at(op.global_position,1,"ammo")
	main._toggle_haul_corpse()
	_check(op.hauled_loot==ordinary and _actor().sampled_action not in ["corpse_grab","corpse_drag"] and view.frame.corpses.is_empty(),"ordinary unlinked loot retains gameplay haul without fabricated corpse source")
	completed += 1

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
	await _actual()
	_matrix()
	_cancellations()
	_check(completed==3,"actual stage reaches completion")
	root.get_node("AudioDirector").pause_for_background()
	var report={"checks":checks,"failures":failures,"captures":captures,"pairs":pair_rows,"scope":"actual C2/H/drop/normal auto-pickup and copied history; manually advanced command clock during paired fixture, not full campaign or device"}
	var file=FileAccess.open("res://build/asset_review/pr15-runtime/corpse-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("CORPSE_RUNTIME_OK" if failures==0 else "CORPSE_RUNTIME_FAILED"," checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
