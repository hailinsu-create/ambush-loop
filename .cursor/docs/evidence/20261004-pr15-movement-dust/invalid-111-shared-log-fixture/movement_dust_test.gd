extends SceneTree
## Original command movement, followed by explicit saved-pose reader fixtures.
const Guard := preload("res://scripts/test_storage_guard.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const READER_PATH := "res://scripts/presentation/movement_dust_frame.gd"
const Reader := preload("res://scripts/presentation/movement_dust_frame.gd")
const OldSources := preload("res://scripts/shot_fx_pool_test.gd")
var main: Node
var checks:=0
var failures:=0
var rows: Array=[]
var captures: Array=[]
var directory: String
var pool: Node3D

func _init() -> void:
	if not Guard.check():quit(91);return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;print("MOVEMENT_DUST_FAIL "+message)

func _state() -> PackedByteArray:
	return var_to_bytes([main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum,_log_state(main.battle_log),main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades,op.mines,op.stance,op.sprinting,op.move_path,op._path_i]),main.enemies.map(func(enemy:EnemyRunner)->Array:return [enemy.global_position,enemy.hp,enemy.alive] if is_instance_valid(enemy) else [])])

func _log_state(log: BattleLog) -> PackedByteArray:
	return var_to_bytes([log.attempt_id,log.wave_id,log.wave_offset,log.events,log.snapshots,log.playback_snapshots,log.terminal_tick,log.terminal_reason,log.playback_schema,log.playback_terminal_tick,log.current_playback_tick()])

func _reader_cases(frame: Dictionary) -> void:
	var one:=frame.duplicate(true)
	one.movement_fx_actors=one.movement_fx_actors.filter(func(actor:Dictionary)->bool:return actor.group=="ops" and actor.id==1)
	var control:Array=Reader.active(one)
	_check(control.size()==1 and control.front().position==main.operators[0].global_position,"actual raw moving pose accepted before corrupt matrix")
	for row in [["movement_fx_schema",0],["movement_fx_schema",99],["movement_fx_schema",1.0],["movement_fx_schema",true],["movement_fx_playback_schema",1],["movement_fx_source_token",0],["movement_fx_source_token",true],["schema",1],["animation_schema",99],["actor_asset_revision","foreign"],["visual_unsupported",true],["phase",2],["phase",3],["phase",true],["recorded_phase",1],["attempt_id",""],["wave_id",99],["wave_id",0.0],["wave_count",0],["level_id","foreign"],["movement_fx_clock_s",-1.0],["movement_fx_clock_s",NAN],["movement_fx_clock_s",true],["movement_fx_clock_domain","simulation"],["movement_fx_clock_domain",StringName("command")]]:
		var copy:=one.duplicate(true);copy[row[0]]=row[1]
		var before:=var_to_bytes(copy)
		_check(Reader.active(copy).is_empty() and var_to_bytes(copy)==before,"neutral immutable explicit frame corrupt "+str(row))
	for row in [["group","sentries"],["group",StringName("ops")],["id",0],["id",true],["id",1.0],["id",4],["pos",Vector2.INF],["facing",INF],["facing",true],["active",false],["active","true"],["alive",false],["moving",false],["moving",1],["stance",true],["stance",2],["sprinting",true],["sprinting","false"],["action","idle"],["action","haul"],["action","pickup"],["action","fire"],["action","death"],["action",StringName("walk")]]:
		var copy:=one.duplicate(true);copy.movement_fx_actors.front()[row[0]]=row[1]
		var before:=var_to_bytes(copy)
		_check(Reader.active(copy).is_empty() and var_to_bytes(copy)==before,"neutral immutable explicit actor corrupt "+str(row))
	for key in ["id","pos","facing","active","alive","moving","stance","sprinting","action"]:
		var copy:=one.duplicate(true);copy.movement_fx_actors.front().erase(key)
		_check(Reader.active(copy).is_empty(),"missing saved actor field remains neutral "+key)
	var duplicate:=one.duplicate(true);duplicate.movement_fx_actors.append(duplicate.movement_fx_actors.front().duplicate(true))
	_check(Reader.active(duplicate).is_empty(),"duplicate saved actor identity neutral")
	var clock:=one.duplicate(true);clock.pose_clock_s+=999.0;clock.tick+=999;clock.local_tick+=999
	_check(Reader.active(clock)==control,"cue ignores unrelated live/domain defaults in favor of dedicated saved clock")
	var historical:=one.duplicate(true);historical.phase=4;historical.replay=true
	_check(Reader.active(historical)==control,"explicit bound REPLAY preserves saved moving facts")
	rows.append({"case":"raw-reader-matrix","actual_control":control,"scope":"actual moving source then explicit cloned field controls"})

func _pool_cases(frame: Dictionary) -> void:
	var original:=_state()
	var one:=frame.duplicate(true)
	one.movement_fx_actors=one.movement_fx_actors.filter(func(actor:Dictionary)->bool:return actor.group=="ops" and actor.id==1)
	pool.update_frame(one,false)
	var first:Dictionary=pool.diagnostics()
	for index in 100:pool.update_frame(one,false)
	_check(pool.diagnostics().active==first.active and pool.get_child_count()==48 and first.shared_meshes==1 and first.materials==24,"100 deterministic redraws retain finite48 nodes/shared mesh/24materials")
	var many:=one.duplicate(true);many.movement_fx_actors.clear()
	for index in 64:
		var actor:Dictionary=one.movement_fx_actors.front().duplicate(true)
		actor.group="enemies";actor.id=index+1;actor.erase("stance");actor.erase("sprinting")
		many.movement_fx_actors.append(actor)
	pool.update_frame(many,false)
	_check(Reader.active(many).size()==64 and pool.diagnostics().active.size()==24 and pool.diagnostics().active.front().id==1 and pool.diagnostics().active.back().id==24,"explicit64 moving actor fixture bounded to24 stable identities")
	var ordered:Array=pool.diagnostics().active
	many.movement_fx_actors.reverse();pool.update_frame(many,false)
	_check(pool.diagnostics().active==ordered,"explicit source reorder does not alter actor priority")
	pool.update_frame(many,true)
	_check(pool.diagnostics().active.size()==6 and pool.diagnostics().active.all(func(item:Dictionary)->bool:return item.puff_count==1),"saving6 identities uses one puff each")
	many.movement_fx_actors.append(many.movement_fx_actors.front().duplicate(true));pool.update_frame(many,false)
	_check(pool.diagnostics().active.is_empty(),"over64 raw envelope rejected before rendering")
	for row in [["pos",Vector2(1.0e38,1.0e38)],["clock",1.0e308]]:
		var copy:=one.duplicate(true)
		if row[0]=="pos":copy.movement_fx_actors.front().pos=row[1]
		else:copy.movement_fx_clock_s=row[1]
		pool.update_frame(copy,false)
		_check(Reader.active(copy).size()==1 and pool.diagnostics().active.is_empty(),"finite raw with overflow derived geometry is neutral "+str(row[0]))
	for phase in [2,3]:
		var copy:=one.duplicate(true);copy.phase=phase;copy.recorded_phase=phase;pool.update_frame(copy,false)
		_check(pool.diagnostics().active.is_empty(),"terminal moving cue cancels phase="+str(phase))
	pool.clear()
	_check(pool.get_children().all(func(node:MeshInstance3D)->bool:return not node.visible),"clear hides every fixed dust node")
	_check(_state()==original,"pool/corrupt/capacity fixtures preserve original backend and log bytes")

func _pixels(before: Image, after: Image, center: Vector2, radius: int) -> int:
	var changed:=0
	for y in range(maxi(0,int(center.y)-radius),mini(after.get_height(),int(center.y)+radius+1)):
		for x in range(maxi(0,int(center.x)-radius),mini(after.get_width(),int(center.x)+radius+1)):
			var left:=before.get_pixel(x,y);var right:=after.get_pixel(x,y)
			if maxf(absf(left.r-right.r),maxf(absf(left.g-right.g),absf(left.b-right.b)))>0.025:changed+=1
	return changed

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image:=DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path:=directory+"/"+label+"-%02d.png" % captures.size()
	_check(image.save_png(path)==OK,"actual Window "+label)
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"capture_source":"original DisplayServer Window crop","diagnostics":pool.diagnostics()})

func _visual(frame: Dictionary, label: String, yaws: Array) -> void:
	if DisplayServer.get_name()=="headless":return
	for index in 30:await process_frame
	main._update_hud()
	var before:=_state()
	var view:Node3D=main.presentation_3d
	view.rig.focus=Space.logic_to_world(main.selected.global_position)
	view.rig.view_size=12.0
	for yaw in yaws:
		view.rig.yaw_deg=yaw;view.rig.apply_pose();view.refresh()
		pool.update_frame(frame,false)
		var active:Array=pool.diagnostics().active
		_check(not active.is_empty(),"actual moving cue admitted "+label+" yaw="+str(yaw))
		if active.is_empty():continue
		var screen:Vector2=view.rig.camera.unproject_position(active.front().puffs.front().position)
		_check(screen.x>32 and screen.x<1248 and screen.y>32 and screen.y<688,"moving cue source ROI inside actual Window")
		pool._hide();await _capture(label+"-yaw"+str(int(yaw))+"-off0")
		pool.update_frame(frame,false);await _capture(label+"-yaw"+str(int(yaw))+"-on")
		pool._hide();await _capture(label+"-yaw"+str(int(yaw))+"-off1")
		var off0:=Image.load_from_file(captures[-3].path);var on:=Image.load_from_file(captures[-2].path);var off1:=Image.load_from_file(captures[-1].path)
		var visible:=_pixels(off0,on,screen,20);var stable:=_pixels(off0,off1,screen,20)
		_check(visible>4,"real dust changes source ROI "+label+" yaw="+str(yaw)+" pixels="+str(visible))
		_check(stable<=2,"dust off control stable "+label+" yaw="+str(yaw)+" pixels="+str(stable))
		rows.append({"case":"actual-Window-dust-ROI","action":label,"yaw_deg":yaw,"screen_point":screen,"on_changed_pixels":visible,"off_changed_pixels":stable,"source_frame":frame})
	_check(_state()==before,"Window draw controls preserve original movement and recording")

func _freeze_cases(command: bool) -> void:
	if command:main._toggle_pause_menu()
	else:main._on_pause_pressed()
	main.presentation_3d.refresh()
	var original:=_state()
	var visible:Array=pool.diagnostics().active
	for index in 30:
		main._process(1.0/60.0)
		main.presentation_3d.refresh()
	_check(_state()==original and pool.diagnostics().active==visible,"original paused "+("SCOUT" if command else "ALERT")+" freezes saved clock/geometry/source/backend for30 draws")
	if command:main.pause_overlay.dismiss()
	else:main._on_pause_pressed()
	main.handle_app_focus_out()
	main.presentation_3d.refresh()
	original=_state();visible=pool.diagnostics().active
	for index in 30:
		main._process(1.0/60.0)
		main.presentation_3d.refresh()
	_check(_state()==original and pool.diagnostics().active==visible,"original background holds saved moving cue and state")
	main.handle_app_focus_in()

func _history_and_phases() -> void:
	main._load_level("yard",false,false)
	await process_frame
	main.presentation_3d.set_process(false)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0]) # Explicit original reference kits/setup.
	main.raid_force_alarm()
	var enemy_source:Dictionary={}
	for index in 120:
		main._sim_tick()
		var sample:=ViewState.capture(main)
		if Reader.active(sample).any(func(actor:Dictionary)->bool:return actor.group=="enemies"):
			enemy_source=sample;break
	_check(main.phase==main.Phase.WATCHING and not enemy_source.is_empty(),"actual original ALERT enemy sim movement reaches saved walking source")
	main.presentation_3d.refresh()
	_check(pool.diagnostics().active.any(func(actor:Dictionary)->bool:return actor.group=="enemies"),"original presenter renders actual moving ALERT enemy cue")
	await _freeze_cases(false)
	var count:=0
	while main.phase==main.Phase.WATCHING and count<5000:
		main._sim_tick();count+=1
	_check(main.phase==main.Phase.SWEEP,"reference original first yard wave naturally reaches legal SWEEP")
	if main.phase!=main.Phase.SWEEP:return
	var tick:int=main.sim.tick
	main._select_op(2)
	var scout:OperatorUnit=main.selected
	var start:=scout.global_position
	main._command_move_selected(main.grid.cell_to_world_center(Vector2i(32,16)))
	for index in 24:main._process(1.0/60.0)
	main.presentation_3d.refresh()
	_check(scout.is_moving() and scout.global_position!=start and main.sim.tick==tick and pool.diagnostics().active.any(func(actor:Dictionary)->bool:return actor.group=="ops" and actor.id==3),"actual legal SWEEP move advances saved command clock/cue while battle tick stays frozen")
	var saved:BattleLog=main.battle_log
	main._on_replay_pressed() # Original available history entry, not injected phase.
	_check(main.phase==main.Phase.REPLAY and main.replay.log==saved and main.replay.continuous_playback,"original REPLAY entry binds actual version2 record")
	var moving_snaps:Array=saved.playback_snapshots.filter(func(snap:Dictionary)->bool:return snap.data.phase==5 and snap.data.ops.any(func(actor:Dictionary)->bool:return actor.id==3 and actor.moving))
	_check(not moving_snaps.is_empty(),"actual recorded moving SWEEP frame retained")
	if moving_snaps.is_empty():return
	var target:int=moving_snaps.back().playback_tick
	main.replay.set_tick(target);main._apply_replay_scrub();main.presentation_3d.refresh()
	var saved_bytes:=_log_state(saved)
	var original:=_state()
	var signature:Array=pool.diagnostics().active
	_check(signature.any(func(actor:Dictionary)->bool:return actor.group=="ops" and actor.id==3),"actual selected historical moving frame renders despite live actors hidden")
	for index in 30:
		main._process(1.0/60.0);main.presentation_3d.refresh()
	_check(_state()==original and _log_state(saved)==saved_bytes and pool.diagnostics().active==signature,"paused original REPLAY30 draws does not advance saved dust/backend/record")
	for seek in [0,target,0,target]:
		main.replay.set_tick(seek);main._apply_replay_scrub();main.presentation_3d.refresh()
		_check(pool.diagnostics().active==signature if seek==target else pool.diagnostics().active.is_empty(),"actual backward/restore seek deterministic tick="+str(seek))
	rows.append({"case":"actual-reference-ALERT-SWEEP-REPLAY","domain_tick":tick,"seek_playback_tick":target,"source":moving_snaps.back(),"cue":signature,"scope":"original reference first wave and legal command/API transport, not normal13/fullautoplay"})
	root.get_node("GameSettings").mark_tutorial_seen("warehouse")
	main._load_level("warehouse",false,false)
	await process_frame
	main.presentation_3d.set_process(false)
	main._select_op(0)
	main._command_move_selected(main.grid.cell_to_world_center(Vector2i(32,17)))
	for index in 20:main._process(1.0/60.0)
	main.presentation_3d.refresh()
	var foreign:BattleLog=main.battle_log
	_check(foreign!=saved and foreign.attempt_id!=saved.attempt_id and not pool.diagnostics().active.is_empty(),"actual fresh warehouse source has its own original moving cue")
	var foreign_bytes:=_log_state(foreign)
	main.phase=main.Phase.REPLAY # Explicit foreign-source consumer boundary.
	main.replay.bind(saved);main.replay.set_tick(target);main._apply_replay_scrub();main.presentation_3d.refresh()
	_check(pool.diagnostics().active==signature and _log_state(saved)==saved_bytes and _log_state(foreign)==foreign_bytes,"actual current foreign moving bodies cannot replace bound old cue")
	for id:String in ["schema1"]+OldSources.INITIAL.keys():
		var path:String=OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE") if id=="schema1" else OS.get_environment("AMBUSH_INITIAL_RECORD_ROOT")+"/native-player-"+id+"-record.bin"
		var expected:String=OldSources.LEGACY_SHA if id=="schema1" else OldSources.INITIAL[id]
		_check(FileAccess.get_sha256(path)==expected,"authentic old record present and hash exact "+id)
		if FileAccess.get_sha256(path)!=expected:continue
		var raw:Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
		var source:=BattleLog.new()
		for key in raw:source.set(key,raw[key])
		var before:=_log_state(source)
		main.replay.bind(source)
		for seek in [0,main.replay.max_tick()]:
			main.replay.set_tick(seek);main.presentation_3d.refresh()
			_check(pool.diagnostics().active.is_empty(),"authentic old missing movement version stays neutral over real foreign bodies "+id+":"+str(seek))
		_check(_log_state(source)==before and FileAccess.get_sha256(path)==expected,"old source memory/file never upgraded "+id)
	main.phase=main.Phase.WATCHING # Explicit restore to original abort API.
	main._on_abort_pressed();main.presentation_3d.refresh()
	_check(main.phase==main.Phase.FAILED and pool.diagnostics().active.is_empty(),"original abort cancels all moving cue")
	var ref:WeakRef=weakref(pool)
	var nodes:Array=pool.get_children().map(func(node:Node)->WeakRef:return weakref(node))
	main._return_to_title()
	await process_frame
	await process_frame
	_check(ref.get_ref()==null and nodes.all(func(node:WeakRef)->bool:return node.get_ref()==null),"original Title releases pool and all48 nodes")

func _run() -> void:
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	root.content_scale_factor=1.0
	directory="res://build/asset_review/pr15-runtime/movement-dust-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
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
	main._select_op(0)
	var op:OperatorUnit=main.selected
	var start:=op.global_position
	var original_hp:=op.hp
	var original_inventory:=var_to_bytes([op.ammo,op.grenades,op.mines,op.pack.items()])
	var event_count:int=main.battle_log.events.size()
	var destination:Vector2=main.grid.cell_to_world_center(Vector2i(25,17))
	_check(main.phase==main.Phase.SETUP and not main.grid.is_blocked(25,17),"actual original SCOUT and open destination reached")
	main._command_move_selected(destination)
	_check(op.is_moving(),"original SCOUT command path accepted without granting position or inventory")
	for index in 20:main._process(1.0/60.0)
	var data:Dictionary=main._snapshot_data()
	var moving:Dictionary=data.ops.filter(func(item:Dictionary)->bool:return item.id==op.op_id).front()
	_check(op.global_position!=start and op.is_moving() and moving.moving and moving.action=="walk" and moving.pos==op.global_position,"actual original command ticks move and save exact walk pose/position")
	_check(op.hp==original_hp and var_to_bytes([op.ammo,op.grenades,op.mines,op.pack.items()])==original_inventory and main.battle_log.events.size()==event_count,"original command movement retains HP/inventory/event statistics")
	var original:=_state()
	var frame:=ViewState.capture(main)
	_check(data.get("movement_fx_schema")==1 and frame.get("movement_fx_schema")==1,"planned versioned saved movement cue interface exists")
	pool=main.presentation_3d.get_node_or_null("MovementDust")
	_check(pool!=null and ResourceLoader.exists(READER_PATH),"planned strict saved movement reader and presenter pool exist")
	if pool!=null and ResourceLoader.exists(READER_PATH):
		pool.update_frame(frame,false)
		var active:Array=pool.diagnostics().active
		_check(active.any(func(item:Dictionary)->bool:return item.group=="ops" and item.id==op.op_id and item.center==Space.logic_to_world(op.global_position)),"actual moving source reaches original reader/pool world point")
		rows.append({"case":"actual-SCOUT-command-walk","from":start,"current":op.global_position,"source":moving,"diagnostics":pool.diagnostics()})
		_reader_cases(frame)
		_pool_cases(frame)
		await _visual(frame,"actual-walk",[0.0,35.0,125.0,215.0,305.0])
	_check(_state()==original,"capture and presentation never mutate original movement/backend/log")
	if pool!=null:
		op.set_sprint(true)
		for index in 4:main._process(1.0/60.0)
		var sprint:=ViewState.capture(main);pool.update_frame(sprint,false)
		_check(op.is_moving() and op.sprinting and pool.diagnostics().active.any(func(actor:Dictionary)->bool:return actor.id==1 and actor.sprinting),"actual original sprint updates saved cue without metadata changing movement")
		await _visual(sprint,"actual-sprint",[0.0])
		op.toggle_crouch()
		for index in 4:main._process(1.0/60.0)
		var crouch:=ViewState.capture(main);pool.update_frame(crouch,false)
		_check(op.is_moving() and op.stance==1 and not op.sprinting and pool.diagnostics().active.any(func(actor:Dictionary)->bool:return actor.id==1 and actor.stance==1 and not actor.sprinting),"actual original crouch walk retains stance/sprint exclusivity and cue")
		await _visual(crouch,"actual-crouch",[0.0])
		await _freeze_cases(true)
		op.stop_move();main.presentation_3d.refresh()
		_check(pool.diagnostics().active.is_empty(),"actual original stop movement hides cue immediately")
		await _history_and_phases()
	root.get_node("AudioDirector").pause_for_background()
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"captures":captures,"scope":"actual original SCOUT command movement; explicit saved-pose/backend/corrupt fixtures later. Not native/full13/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("MOVEMENT_DUST_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
