extends "res://scripts/shot_fx_boundary_test.gd"
## Explicit original backend fixture / saved consumer. Not native normal play.
const ViewState := preload("res://scripts/presentation/view_state.gd")
const ActorVisual := preload("res://scripts/presentation/actor_visual.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const FirearmPose := preload("res://scripts/presentation/firearm_pose.gd")
const POOL_PATH := "res://scripts/presentation/shot_fx_pool.gd"
var pool: Node3D
var captures := []
var directory := ""
const LEGACY_SHA := "1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12"
const INITIAL := {"yard":"4e27b9af88ad72199489ee11e987e1ab0e8200c47bc963e831f4c9eb1883c164","warehouse":"cba97cc34446a384d1853a6b7c7224afbd32c5c456ee215fbf5afffdc0015cfd","pump":"e0faee3000b85ae795737dfd7b39e510e4a0670560d40a0a01890e5acfba2b46","railcut":"19919a17225308894332b5cf9a849b4bc004792afa02f3c5e27d25b0f08f9628","depot":"1720fe0dc83bfa2647d22c0dcc74b5bea35ac11db2ce25a141e3fb734d156d6d","radio":"69926921f672c941f66bc2885ba15e0484f37923e7addae0670047cae0653d22"}

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("SHOT_FX_POOL_FAIL "+message)

func _diag() -> Dictionary:
	return pool.diagnostics()

func _state(log: BattleLog) -> PackedByteArray:
	return var_to_bytes([log.attempt_id,log.wave_id,log.wave_offset,log.events,log.snapshots,log.playback_snapshots,log.terminal_tick,log.terminal_reason,log.playback_schema,log.playback_terminal_tick,log.current_playback_tick()])

func _bind_pool() -> void:
	pool = main.presentation_3d.get_node_or_null("ShotFx")
	_check(pool != null and pool == main.presentation_3d.shot_fx,"original presenter owns finite pool")

func _sample_socket(fx: Dictionary, lod: int) -> Vector3:
	var sampler := ActorVisual.new()
	sampler.visible = false
	root.add_child(sampler)
	sampler.position = Space.logic_to_world(fx.source_pos)
	sampler.rotation.y = Space.facing_yaw(float(fx.pose.get("visual_facing",fx.source_facing)))
	_check(sampler.set_asset(fx.visual_model,lod,fx.actor_asset_revision) and sampler.mount_item(fx.visual_weapon) and sampler.sample_layers(fx.pose),"original saved R5 model/gun/pose accepts LOD"+str(lod))
	var socket := sampler.item_socket("muzzle")
	_check(socket.has("transform") and socket.transform.origin.is_finite(),"actual original muzzle marker finite LOD"+str(lod))
	var point: Vector3 = socket.transform.origin if socket.has("transform") else Vector3.INF
	sampler.free()
	return point

func _capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path := directory+"/"+label+"-%02d.png" % captures.size()
	_check(image.save_png(path)==OK,"actual Window capture "+label)
	captures.append({"id":label,"path":path,"sha256":FileAccess.get_sha256(path),"capture_source":"Native DisplayServer Window crop","pool":_diag()})

func _original_shots() -> Dictionary:
	var retained := {}
	for label in ["ordinary","last-pack","last-pistol","lethal","knife","enemy-mg","enemy-cover","false-hold","enemy-cooldown"]:
		var pair: Array = await _reset(1 if label=="enemy-mg" else 0)
		_bind_pool()
		var op: OperatorUnit = pair[0]
		var enemy: EnemyRunner = pair[1]
		op.apply_weapon("knife" if label=="knife" else "kar98k",true)
		op.ammo = 1 if label in ["last-pack","last-pistol"] else 3
		op.ammo_pool["rifle"] = op.ammo
		op.has_ammo_pack = label=="last-pack"
		op.ammo_pack_used = false
		op.ammo_pool["pistol"] = 3 if label=="last-pistol" else 0
		if label=="lethal": enemy.hp=10.0
		var event: Dictionary = {}
		if label.begins_with("enemy-"):
			if label=="enemy-cover":
				op.slot = main.cover_slots[1]
				op.global_position = op.slot.global_position
				var angle := deg_to_rad(op.slot.protect_facing_deg)
				enemy.global_position = op.global_position+Vector2(cos(angle),sin(angle))*32.0
				_check(op.slot.protects_from(enemy.global_position) and main.grid.has_los(op.global_position,enemy.global_position),"original cover/LOS fixture is reached")
			enemy.focus_target=op
			enemy.alerted=true
			enemy.return_cd=0.1 if label=="enemy-cooldown" else 0.0
			main._resolve_return_with_recorded_fx(enemy)
			if label!="enemy-cooldown": event=main.battle_log.events.back()
		else:
			op.fire_permitted = label!="false-hold"
			event=_event(op,enemy)
			var fired: bool=main._try_fire_with_recorded_fx(op,enemy,event)
			_check(fired == (label!="false-hold"),label+" actual original attack result")
		var frame := ViewState.capture(main)
		var before := _state(main.battle_log)
		var live_before: Dictionary=main._snapshot_data()
		var sim_before := [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,op.hp,enemy.hp]
		main.presentation_3d.refresh()
		var active: Array=_diag().active
		var neutral: bool = label in ["knife","false-hold","enemy-cooldown"]
		_check(active.is_empty() if neutral else active.size()==1,label+" actual presenter shot visibility / knife and failed/cooldown neutral")
		if not neutral and active.size()==1:
			var fx: Dictionary=event.payload.fx
			var lods := []
			for lod in [0,1,2]: lods.append(_sample_socket(fx,lod))
			_check(active[0].muzzle.is_equal_approx(lods[0]) and active[0].target==Space.logic_to_world(fx.target_pos,1.05) and active[0].event_id==event.event_id and active[0].damage==fx.damage,label+" exact saved LOD0 original muzzle/target/identity/actual HP cue")
			if label=="last-pistol": _check(op.weapon_id=="pistol" and active[0].visual_weapon=="kar98k","post-success pistol cannot replace original fired rifle muzzle")
			if label=="last-pack": _check(op.ammo_pack_used and op.ammo==op.start_ammo,"original same-gun pack refill retained")
			if label=="lethal": _check(not enemy.alive and enemy.hp<0.0 and active[0].impact_visible,"original lethal actual negative HP still gives only actual hit cue")
			rows.append({"case":label,"original_event":event,"current_gun":op.weapon_id,"pool":_diag(),"muzzles_lod012":lods,"lod1_delta_m":lods[0].distance_to(lods[1]),"lod2_delta_m":lods[0].distance_to(lods[2]),"scope":"explicit grant/position/HP/pre-log and original attack/return API fixture"})
			if label=="ordinary":
				retained={"frame":frame,"event":event.duplicate(true)}
				main.presentation_3d.rig.focus=Space.logic_to_world(fx.source_pos)
				main.presentation_3d.rig.view_size=12.0
				main.presentation_3d.rig.apply_pose()
				await _capture("ordinary-age0")
				main.sim.paused=true
				var clock_before: int = main.battle_log.current_playback_tick()
				var stable: Array=_diag().active
				for index in 30:
					await process_frame
					main.presentation_3d.refresh()
				_check(_diag().active==stable and main.battle_log.current_playback_tick()==clock_before,"paused ALERT uses saved tick through actual draw frames")
				await _capture("paused-alert-age0")
				main.handle_app_focus_out()
				main.handle_app_focus_in()
				main.presentation_3d.refresh()
				_check(main.sim.paused and _diag().active==stable and main.battle_log.current_playback_tick()==clock_before,"actual focus lifecycle callbacks keep ALERT paused and original FX clock")
				main.sim.paused=sim_before[2]
		_check(_state(main.battle_log)==before and main._snapshot_data()==live_before and [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,op.hp,enemy.hp]==sim_before,label+" rendered/saved sampler keeps original log/live/sim/ammo/HP")
	return retained

func _copies(frame: Dictionary, count: int, start: int=100) -> Dictionary:
	var result := frame.duplicate(true)
	var shot: Dictionary=frame.events.filter(func(e:Dictionary)->bool:return e.get("payload",{}).has("fx")).back()
	result.events.clear()
	for index in count:
		var event := shot.duplicate(true)
		event.seq=start+index
		event.event_id="%s:%d:%d" % [event.attempt_id,event.wave_id,event.seq]
		event.position+=Vector2(index+start,0)
		event.payload.fx.merge({"seq":event.seq,"event_id":event.event_id,"source_pos":event.position},true)
		result.events.append(event)
	return result

func _boundary_cases(original: Dictionary) -> void:
	var frame: Dictionary=original.frame
	var event: Dictionary=original.event
	var baseline := var_to_bytes([frame,event])
	for age in [0,2,3,5,6,8,9,-1,0,5,0]:
		var copy := frame.duplicate(true)
		copy.playback_tick=event.playback_tick+age
		pool.update_frame(copy)
		var active: Array=_diag().active
		var alive: bool=age>=0 and age<9
		_check(active.size()==1 if alive else active.is_empty(),"finite saved playback lifetime age="+str(age))
		if alive: _check(active[0].muzzle_visible==(age<3) and active[0].tracer_visible==(age<6) and active[0].impact_visible,"independent flash3/tracer6/hit9 saved ticks age="+str(age))
		if age in [0,5,8,9]: await _capture("fixture-age"+str(age))
	var copy := frame.duplicate(true)
	copy.events.back().payload.fx.hp_after=copy.events.back().payload.fx.hp_before
	copy.events.back().payload.fx.damage=0.0
	pool.update_frame(copy)
	_check(_diag().active.size()==1 and not _diag().active[0].impact_visible and _diag().active[0].muzzle_visible,"confirmed shot with zero actual HP delta has no impact")
	for field in ["phase","recorded_phase"]:
		for phase in [0,2,3,5]:
			copy=frame.duplicate(true)
			copy[field]=phase
			pool.update_frame(frame)
			pool.update_frame(copy)
			_check(_diag().active.is_empty() and _diag().cache_size==0,"SCOUT/SWEEP/terminal clears cached/visible FX "+field+str(phase))
	for row in [["wave_id",1],["attempt_id","foreign"],["shot_fx_schema",0],["animation_supported",false],["visual_unsupported",true],["actor_asset_revision","unknown"]]:
		copy=frame.duplicate(true)
		copy[row[0]]=row[1]
		pool.update_frame(frame)
		pool.update_frame(copy)
		_check(_diag().active.is_empty() and _diag().cache_size==0,"source boundary cannot keep old FX "+str(row))
	pool.update_frame(frame)
	var first: Vector3=_diag().active[0].muzzle
	var samples_before: int=_diag().sample_calls
	copy=frame.duplicate(true)
	copy.shot_fx_source_token=123
	copy.events.back().position+=Vector2(64,0)
	copy.events.back().payload.fx.source_pos=copy.events.back().position
	pool.update_frame(copy)
	_check(_diag().sample_calls==samples_before+1 and _diag().active[0].event_id==event.event_id and _diag().active[0].muzzle.is_equal_approx(first+Vector3(2,0,0)),"same factual identity on a different bound log cannot borrow old muzzle")
	copy.events.back().position+=Vector2(32,0)
	copy.events.back().payload.fx.source_pos=copy.events.back().position
	samples_before=_diag().sample_calls
	pool.update_frame(copy)
	_check(_diag().sample_calls==samples_before+1 and _diag().active[0].muzzle.is_equal_approx(first+Vector3(3,0,0)),"same source/identity changed complete descriptor cannot reuse cached muzzle")
	copy.events.back().payload.visual_weapon="m1911"
	copy.events.back().payload.fx.visual_weapon="m1911"
	copy.events.back().payload.fx.pose.upper_action=FirearmPose.profile("m1911").clips.fire
	samples_before=_diag().sample_calls
	pool.update_frame(copy)
	_check(_diag().sample_calls==samples_before+1 and _diag().active.size()==1 and _diag().active[0].visual_weapon=="m1911" and _diag().active[0].muzzle.is_equal_approx(_sample_socket(copy.events.back().payload.fx,0)),"same identity changed saved gun/pose samples exact new descriptor without stale rifle socket")
	copy=frame.duplicate(true)
	copy.events.back().payload.fx.target_pos=Vector2(1e38,-1e38)
	var malformed_delta: Vector3=Space.logic_to_world(copy.events.back().payload.fx.target_pos,1.05)-first
	pool.update_frame(copy)
	_check(copy.events.back().payload.fx.target_pos.is_finite() and not is_finite(malformed_delta.length()) and _diag().active.is_empty(),"finite saved coordinate with overflowed derived tracer length fails closed")
	rows.append({"case":"explicit-finite-derived-overflow","input_vector_is_finite":copy.events.back().payload.fx.target_pos.is_finite(),"derived_length":str(malformed_delta.length()),"pool":_diag(),"scope":"synthetic corrupt saved target, not an actual gameplay position"})
	pool.update_frame(frame)
	pool._cache.clear() # Explicit missing saved-asset marker fixture, no production mutation.
	var marker: Node3D=pool._sampler.equipped.find_child(event.payload.fx.visual_weapon+"__socket_muzzle",true,false)
	var original_name := marker.name
	marker.name="MISSING_MARKER_FIXTURE"
	pool.update_frame(frame)
	_check(_diag().active.is_empty() and _diag().rejected_sockets>0,"missing original saved muzzle fails closed after a previous valid shot")
	marker.name=original_name
	pool.update_frame(frame)
	_check(_diag().active.size()==1,"restored saved marker gives original muzzle again")
	var ids := []
	var meshes := {}
	var materials := {}
	for slot: Dictionary in pool._slots:
		for mesh: MeshInstance3D in slot.values():
			ids.append(mesh.get_instance_id())
			meshes[mesh.mesh.get_instance_id()]=true
			materials[mesh.material_override.get_instance_id()]=true
			_check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"pooled mesh casts no shadow")
	copy=_copies(frame,20)
	pool.update_frame(copy)
	_check(_diag().active.size()==12 and _diag().active[0].seq==108 and _diag().active.back().seq==119,"fixed standard pool keeps latest12 of explicit same-clock20-shot fixture")
	pool.update_frame(copy,true)
	var saving: Array=_diag().active
	var no_tracer:=true
	for shot: Dictionary in saving: no_tracer=no_tracer and not shot.tracer_visible
	_check(saving.size()==4 and saving[0].seq==116 and no_tracer,"existing power-saving tier keeps latest4 and disables every tracer")
	await _capture("saving-four-slots-fixture")
	for index in 60: pool.update_frame(_copies(frame,1,1000+index))
	_check(_diag().cache_size==48,"pure recent muzzle cache caps at48 after60 distinct saved descriptors")
	var cached_calls: int=_diag().sample_calls
	var node_before := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	for index in 180: pool.update_frame(_copies(frame,1,1059))
	var after_ids := []
	for slot: Dictionary in pool._slots:
		for mesh: MeshInstance3D in slot.values(): after_ids.append(mesh.get_instance_id())
	_check(ids==after_ids and ids.size()==36 and meshes.size()==3 and materials.size()==3 and _diag().sample_calls==cached_calls and Performance.get_monitor(Performance.OBJECT_NODE_COUNT)==node_before,"180 repeat frames preserve fixed36 mesh instances/three mesh+material resources/no new samples or nodes")
	rows.append({"case":"bounded-explicit-fixtures","pool":_diag(),"unique_mesh_resources":meshes.size(),"unique_material_resources":materials.size(),"steady_repeat_frames":180,"scope":"explicit saved event copies, missing-marker fixture, not normal battle/performance acceptance"})
	_check(var_to_bytes([frame,event])==baseline,"all boundary/capacity/marker fixtures retain original event and frame bytes")

func _history_cases() -> void:
	var pair: Array=await _reset()
	_bind_pool()
	var op: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	op.apply_weapon("kar98k",true)
	var event:=_event(op,enemy)
	_check(main._try_fire_with_recorded_fx(op,enemy,event),"actual source shot for original ReplayPlayer fixture")
	main.battle_log.add_snapshot(main.sim.tick,main._snapshot_data())
	for index in 12:
		main.battle_log.advance_simulation_playback() # Explicit clock fixture, no claimed simulation.
		main.battle_log.add_snapshot(main.sim.tick,main._snapshot_data())
	main.battle_log.mark_terminal(main.sim.tick,"shot-fx-consumer-fixture")
	var saved: BattleLog=main.battle_log
	var before:=_state(saved)
	var live: Dictionary=main._snapshot_data()
	var sim_tuple := [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,enemy.hp]
	main._on_replay_pressed()
	_check(main.phase==main.Phase.REPLAY and main.replay.log==saved and main.replay.continuous_playback,"original REPLAY entry binds actual source fixture")
	live=main._snapshot_data() # Original entry intentionally changes phase/visibility.
	for speed in [1.0,2.0]:
		main.replay.set_tick(event.playback_tick)
		main.replay.set_speed(speed)
		main.replay.play()
		main.replay.advance(1.0/60.0)
		main.presentation_3d.refresh()
		_check(_diag().active.size()==1 and _diag().active[0].age_ticks==int(speed),"original1x/2x advances saved FX age by exact playback ticks "+str(speed))
	main.replay.set_tick(event.playback_tick)
	main.replay.pause()
	main.presentation_3d.refresh()
	var stable: Array=_diag().active
	for index in 30:
		await process_frame
		main.replay.advance(1.0/60.0)
		main.presentation_3d.refresh()
	_check(_diag().active==stable and main.replay.scrub_tick==event.playback_tick,"original paused REPLAY keeps same saved muzzle and lifetime through30 actual draw frames")
	main.presentation_3d.rig.focus=Space.logic_to_world(event.payload.fx.source_pos)
	main.presentation_3d.rig.view_size=12.0
	main.presentation_3d.rig.apply_pose()
	await _capture("replay-paused-original-shot")
	for age in [8,9,0,5,0,-1,0]:
		main.replay.set_tick(event.playback_tick+age)
		main.presentation_3d.refresh()
		_check(_diag().active.size()==1 if age>=0 and age<9 else _diag().active.is_empty(),"original seek forward/back/end/before-shot age="+str(age))
	main.handle_app_focus_out()
	main.handle_app_focus_in()
	main.presentation_3d.refresh()
	_check(not main.replay.playing and _diag().active==stable,"original focus lifecycle keeps replay paused and saved FX unchanged")
	_check(_state(saved)==before and main._snapshot_data()==live and [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,enemy.hp]==sim_tuple,"original transport/seek/cold samples do not mutate saved source/live/sim/HP/ammo")
	pair=await _reset()
	_bind_pool()
	var foreign_op: OperatorUnit=pair[0]
	var foreign_enemy: EnemyRunner=pair[1]
	foreign_op.apply_weapon("pistol",true)
	var foreign_event:=_event(foreign_op,foreign_enemy)
	_check(main._try_fire_with_recorded_fx(foreign_op,foreign_enemy,foreign_event) and foreign_event.payload.has("fx"),"foreign current log has an actual new successful pistol shot")
	var foreign: BattleLog=main.battle_log
	var foreign_before:=_state(foreign)
	main.phase=main.Phase.REPLAY # Explicit old-record consumer over actual foreign live shot.
	main.replay.bind(saved)
	main.replay.set_tick(event.playback_tick)
	main.presentation_3d.refresh()
	_check(_diag().active==stable and main.replay.log==saved and foreign.attempt_id!=saved.attempt_id and foreign_op.weapon_id=="pistol","foreign current live shot/gun cannot replace bound original history")
	for id: String in ["schema1"]+INITIAL.keys():
		var path: String=OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE") if id=="schema1" else OS.get_environment("AMBUSH_INITIAL_RECORD_ROOT")+"/native-player-"+id+"-record.bin"
		var expected: String=LEGACY_SHA if id=="schema1" else INITIAL[id]
		var hash_before:=FileAccess.get_sha256(path)
		_check(hash_before==expected,"authentic original raw fixture exists unchanged "+id)
		if hash_before!=expected: continue
		var raw: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
		var source:=BattleLog.new()
		for key in raw: source.set(key,raw[key])
		var raw_before:=var_to_bytes(raw)
		var source_before:=_state(source)
		main.replay.bind(source)
		var actual_shots: Array=source.events.filter(func(e:Dictionary)->bool:return e.get("type") in ["fire","return_fire"])
		_check(not actual_shots.is_empty(),id+" actual old raw contains original shots")
		for old: Dictionary in [actual_shots.front(),actual_shots.back()]:
			main.replay.set_tick(old.get("playback_tick",BattleLog.record_tick(old)))
			main.presentation_3d.refresh()
			_check(_diag().active.is_empty() and _diag().cache_size==0 and not old.payload.has("fx"),id+" old source stays neutral without borrowing foreign current live shot")
		_check(_state(source)==source_before and var_to_bytes(raw)==raw_before and FileAccess.get_sha256(path)==expected,id+" original source memory and raw file hash never upgrade")
		rows.append({"case":"actual-old-raw-"+id,"sha256":expected,"events":source.events.size(),"source_unchanged":true,"producer":"874d350 schema1" if id=="schema1" else "a05fa959 INITIAL native normal"})
		if id=="schema1": await _capture("actual-schema1-neutral")
	main.replay.bind(saved)
	main.replay.set_tick(event.playback_tick)
	main.presentation_3d.refresh()
	_check(_diag().active==stable and _state(saved)==before and _state(foreign)==foreign_before,"restoring original modern bound log restores exact saved shot after all old sources and preserves actual foreign live shot")
	main.phase=main.Phase.WATCHING # Explicit cold consumer phase restoration fixture.
	main.battle_log=saved
	main.presentation_3d.refresh()
	main._on_abort_pressed()
	main.presentation_3d.refresh()
	_check(main.phase==main.Phase.FAILED and _diag().active.is_empty() and _diag().cache_size==0,"original abort callback clears FX and saved sampler model")
	_check(pool._sampler.asset_id.is_empty(),"abort releases saved model instead of holding per-source resources")

func _run_cases() -> void:
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	root.content_scale_factor=1.0
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	settings.set_force_touch_hud(false)
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	var original:=await _original_shots()
	if not original.is_empty(): await _boundary_cases(original)
	await _history_cases()
	var saved_pool_id:=pool.get_instance_id()
	var mesh_rids:=[]
	var resources:=[]
	for slot: Dictionary in pool._slots:
		for mesh: MeshInstance3D in slot.values():
			mesh_rids.append(mesh.get_instance_id())
			resources.append(weakref(mesh.mesh))
			resources.append(weakref(mesh.material_override))
	var model_id: int=pool._sampler.get_instance_id()
	main._return_to_title()
	await process_frame
	await process_frame
	var all_freed:=not is_instance_id_valid(saved_pool_id) and not is_instance_id_valid(model_id)
	for id: int in mesh_rids: all_freed=all_freed and not is_instance_id_valid(id)
	_check(all_freed,"original return-to-title frees pool/one sampler/all36 mesh nodes")
	var resources_freed:=true
	for ref: WeakRef in resources: resources_freed=resources_freed and ref.get_ref()==null
	_check(resources_freed,"pool owns three meshes/materials and releases them on actual scene leave")
	rows.append({"case":"actual-scene-leave","pool_and_sampler_and36_mesh_ids_freed":all_freed,"mesh_material_weakrefs_released":resources_freed})

func _run() -> void:
	directory = "res://build/asset_review/pr15-runtime/shot-fx-pool-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	_check(ResourceLoader.exists(POOL_PATH),"planned finite saved-shot 3D pool interface exists")
	if ResourceLoader.exists(POOL_PATH):
		await _run_cases()
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"captures":captures,"scope":"Bounded saved-shot 3D consumer / explicit backend and corrupt history fixtures. No native normal/full13/final/A3/device acceptance."},"  "))
	file.close()
	print("SHOT_FX_POOL_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
