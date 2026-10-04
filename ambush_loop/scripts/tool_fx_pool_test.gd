extends "res://scripts/tool_fx_source_test.gd"
## Original tools plus explicit saved reader/age/corrupt/capacity fixtures.
const Space := preload("res://scripts/presentation/world_space.gd")
const OldSources := preload("res://scripts/shot_fx_pool_test.gd")
const READER_PATH := "res://scripts/presentation/tool_fx_frame.gd"
var reader: Script
var pool: Node3D
var captures: Array=[]
var directory := ""

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("TOOL_FX_POOL_FAIL "+message)

func _state(log: BattleLog) -> PackedByteArray:
	return var_to_bytes([log.attempt_id,log.wave_id,log.wave_offset,log.events,log.snapshots,log.playback_snapshots,log.terminal_tick,log.terminal_reason,log.playback_schema,log.playback_terminal_tick,log.current_playback_tick()])

func _diag() -> Dictionary:
	return pool.diagnostics()

func _capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image:=DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path:=directory+"/"+label+"-%02d.png" % captures.size()
	_check(image.save_png(path)==OK,"actual Window capture "+label)
	captures.append({"id":label,"path":path,"sha256":FileAccess.get_sha256(path),"capture_source":"Native DisplayServer Window crop","pool":_diag()})

func _bad(frame: Dictionary, target: String, key: String, value: Variant, remove: bool=false) -> void:
	var copy:=frame.duplicate(true)
	var container: Dictionary=copy if target=="frame" else (copy.tool_fx.front().victims.front() if target=="victim" else copy.tool_fx.front())
	if remove: container.erase(key)
	else: container[key]=value
	var before:=var_to_bytes(copy)
	_check(reader.active(copy).is_empty() and var_to_bytes(copy)==before,"neutral read-only explicit corrupt "+target+"."+key+"="+str(value)+" remove="+str(remove))

func _reader_cases(frame: Dictionary) -> void:
	var effect: Dictionary=frame.tool_fx.front()
	var bytes_before:=var_to_bytes(frame)
	var valid: Array=reader.active(frame)
	_check(valid.size()==1 and valid.front().effect_id==effect.effect_id and valid.front().age_ticks==0 and valid.front().victims==effect.victims,"actual original blast accepted before corrupt reader matrix")
	for age in [-1,0,7,17,60,179,180]:
		var copy:=frame.duplicate(true)
		copy.playback_tick=effect.clock_tick+age
		var active: Array=reader.active(copy)
		_check(active.is_empty() if age<0 or age>=180 else active.size()==1 and active.front().age_ticks==age,"saved confirmation lifetime uses exact playback age="+str(age))
	var other_clocks:=frame.duplicate(true)
	other_clocks.tick+=100000
	other_clocks.local_tick+=100000
	other_clocks.pose_clock_s+=100000.0
	_check(reader.active(other_clocks)==valid,"unrelated domain/pose clocks do not age saved blast")
	var foreign_bodies:=frame.duplicate(true)
	foreign_bodies.ops.clear()
	foreign_bodies.enemies.clear()
	_check(reader.active(foreign_bodies)==valid,"saved victims/owner/position do not borrow current bodies")
	for row in [["tool_fx_schema",0],["tool_fx_schema",99],["tool_fx_schema",1.0],["tool_fx_schema",true],["tool_fx_playback_schema",1],["tool_fx_source_token",0],["tool_fx_source_token",true],["schema",1],["attempt_id","foreign"],["wave_id",99],["wave_id",float(frame.wave_id)],["wave_count",0],["level_id","radio"],["visual_unsupported",true],["playback_tick",float(frame.playback_tick)],["playback_tick",-1]]:
		_bad(frame,"frame",row[0],row[1])
	for row in [["schema",99],["confirmed",false],["confirmed","true"],["kind","tripwire"],["variant","unknown"],["level_id","radio"],["attempt_id","foreign"],["wave_id",99],["seq",true],["seq",1.0],["effect_id","foreign"],["tool_id","foreign"],["tool_id",frame.attempt_id+":tool:01"],["created_wave_id",-1],["created_wave_id",int(effect.wave_id)+1],["created_clock_tick",int(effect.clock_tick)+1],["created_pos",Vector2.INF],["owner_group","enemies"],["owner_id",true],["owner_id",4],["clock_domain","simulation"],["playback_schema",1],["clock_tick",float(effect.clock_tick)],["phase",4],["phase",true],["position",Vector2.INF],["radius",INF],["radius",0.0],["radius",true],["local_tick",-1],["victims",{}],["original_event",{"event_id":"invented"}]]:
		_bad(frame,"effect",row[0],row[1])
	for key in ["schema","confirmed","effect_id","tool_id","created_wave_id","created_clock_tick","owner_id","position","radius","victims","original_event"]:
		_bad(frame,"effect",key,null,true)
	if not effect.victims.is_empty():
		for row in [["group","sentries"],["id",true],["id",0],["pos",Vector2.INF],["hp_before",INF],["hp_after",NAN],["damage",-1.0],["damage",true],["damage",float(effect.victims.front().damage)+1.0]]:
			_bad(frame,"victim",row[0],row[1])
	var duplicate:=frame.duplicate(true)
	duplicate.tool_fx.append(duplicate.tool_fx.front().duplicate(true))
	_check(reader.active(duplicate).is_empty(),"explicit duplicate identity is not rendered twice or selected arbitrarily")
	_check(var_to_bytes(frame)==bytes_before,"reader does not mutate actual immutable source")
	rows.append({"case":"actual-source-and-explicit-corrupt-reader","source":effect,"sample":valid,"read_only":true})

func _pool_cases(frame: Dictionary, label: String) -> void:
	pool=main.presentation_3d.get_node("ToolFx")
	main.presentation_3d.refresh()
	var source_before:=_state(main.battle_log)
	var backend:=var_to_bytes([main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum,main.operators.map(func(op:OperatorUnit)->Array:return [op.hp,op.ammo,op.grenades,op.mines]),main.enemies.map(func(enemy:EnemyRunner)->Array:return [enemy.hp,enemy.alive])])
	var effect: Dictionary=frame.tool_fx.front()
	main.presentation_3d.rig.focus=Space.logic_to_world(effect.position)
	main.presentation_3d.rig.view_size=12.0
	for age in [0,6,17,60,179,180,-1,0]:
		var copy:=frame.duplicate(true)
		copy.playback_tick=effect.clock_tick+age
		pool.update_frame(copy,false)
		var diag:=_diag()
		var active: Array=diag.active
		_check(active.is_empty() if age<0 or age>=180 else active.size()==1 and active.front().age_ticks==age and active.front().center==Space.logic_to_world(effect.position),label+" original saved source world point/lifetime age="+str(age))
		if active.is_empty(): continue
		_check(active.front().flash_visible==(age<8) and active.front().ring_visible==(age<18) and active.front().smoke_count==(3 if age>=5 else 0),label+" finite flash/ring/smoke contract age="+str(age))
		var ring: MeshInstance3D=pool._slots[0].ring
		var vertices: PackedVector3Array=ring.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var extent:=0.0
		for vertex: Vector3 in vertices: extent=maxf(extent,vertex.length())
		_check(is_equal_approx(extent*ring.scale.x,float(effect.radius)/Space.PIXELS_PER_METRE*minf(float(age+1)/12.0,1.0)),label+" actual ring vertex extent/scale follows saved radius age="+str(age))
		if age in [0,6,60]:
			main.presentation_3d.rig.yaw_deg=35.0
			main.presentation_3d.rig.apply_pose()
			await _capture(label+"-age"+str(age))
	var capacity:=frame.duplicate(true)
	capacity.tool_fx.clear()
	for index in 48:
		var record:=effect.duplicate(true)
		record.seq=index
		record.effect_id=frame.attempt_id+":tool_fx:"+str(index)
		record.tool_id=frame.attempt_id+":tool:"+str(index)
		capacity.tool_fx.append(record)
	if effect.kind=="grenade":
		pool.update_frame(capacity,false)
		_check(_diag().capacity==8 and _diag().mesh_nodes==40 and _diag().active.size()==8 and _diag().active.front().seq==40,"explicit48 saved copies choose latest8 without growing40 fixed meshes")
		var ordered: Array=_diag().active
		capacity.tool_fx.reverse()
		pool.update_frame(capacity,false)
		_check(_diag().active==ordered,"explicit reordered saved copies still choose latest confirmation seq deterministically")
		pool.update_frame(capacity,true)
		_check(_diag().active.size()==2 and _diag().active.front().seq==46 and _diag().active.all(func(item:Dictionary)->bool:return item.smoke_count<=1),"explicit capacity fixture power saving limits2 sources/1 puff")
	else:
		pool.update_frame(frame,true)
		_check(_diag().active.size()==1 and _diag().active.front().smoke_count<=1,"actual one mine remains one saved source in power saving")
	var enormous:=frame.duplicate(true)
	enormous.tool_fx.front().position=Vector2(1e38,-1e38)
	pool.update_frame(enormous,false)
	_check(_diag().active.is_empty(),"finite components with nonfinite derived world length cannot enter render transform")
	for index in 100: pool.update_frame(frame,false)
	_check(_diag().mesh_nodes==40 and _diag().active.size()==1,"repeated saved seek/refresh does not grow pool nodes/resources")
	pool.clear()
	_check(_diag().active.is_empty() and pool.get_children().all(func(node:Node)->bool:return not node.visible),"explicit clear removes every visible old effect")
	pool.update_frame(frame,false)
	_check(_state(main.battle_log)==source_before and var_to_bytes([main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum,main.operators.map(func(op:OperatorUnit)->Array:return [op.hp,op.ammo,op.grenades,op.mines]),main.enemies.map(func(enemy:EnemyRunner)->Array:return [enemy.hp,enemy.alive])])==backend,label+" render/corrupt/capacity/seek never changes original source/sim/HP/ammo/inventory")
	rows.append({"case":label+"-pool","source":effect,"pool":_diag(),"scope":"actual original source plus explicit playback-age/capacity copies; no normal-player/performance claim"})

func _history_cases() -> void:
	await _terminal()
	var saved: BattleLog=main.battle_log
	var saved_before:=_state(saved)
	main._on_replay_pressed()
	main.replay.set_tick(saved.playback_terminal_tick)
	main.replay.pause()
	main.presentation_3d.refresh()
	pool=main.presentation_3d.get_node("ToolFx")
	var original: Dictionary=_diag()
	_check(original.active.size()==1 and original.active.front().age_ticks==1,"original wipe terminal REPLAY retains saved completed blast atage1")
	for index in 30:
		await process_frame
		main.replay.advance(1.0/60.0)
		main.presentation_3d.refresh()
	_check(_diag().active==original.active and _state(saved)==saved_before,"30 paused REPLAY draw frames keep exact source-age geometry and original bytes")
	await _capture("actual-wipe-replay-age1")
	main.battle_log=BattleLog.new() # Detach saved source before original reset.
	await _empty_and_duplicate()
	var foreign: BattleLog=main.battle_log
	var foreign_before:=_state(foreign)
	main.phase=main.Phase.REPLAY # Explicit bound-history consumer over actual foreign blast.
	main.replay.bind(saved)
	main.replay.set_tick(saved.playback_terminal_tick)
	main.presentation_3d.refresh()
	pool=main.presentation_3d.get_node("ToolFx")
	_check(_diag().active==original.active and _state(saved)==saved_before and _state(foreign)==foreign_before,"foreign actual live blast cannot replace bound saved terminal source")
	for id: String in ["schema1"]+OldSources.INITIAL.keys():
		var path: String=OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE") if id=="schema1" else OS.get_environment("AMBUSH_INITIAL_RECORD_ROOT")+"/native-player-"+id+"-record.bin"
		var expected: String=OldSources.LEGACY_SHA if id=="schema1" else OldSources.INITIAL[id]
		_check(FileAccess.get_sha256(path)==expected,"authentic old raw present unchanged "+id)
		if FileAccess.get_sha256(path)!=expected: continue
		var raw: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
		var source:=BattleLog.new()
		for key in raw: source.set(key,raw[key])
		var before:=_state(source)
		main.replay.bind(source)
		for tick in [0,main.replay.max_tick()]:
			main.replay.set_tick(tick)
			main.presentation_3d.refresh()
			_check(_diag().active.is_empty(),"actual old record neutral over foreign current blast "+id+":"+str(tick))
		_check(_state(source)==before and FileAccess.get_sha256(path)==expected,"old source memory/file never upgraded "+id)
	main.phase=main.Phase.WATCHING # Explicit source restoration to reach original abort API.
	main.battle_log=foreign
	main.presentation_3d.refresh()
	main._on_abort_pressed()
	main.presentation_3d.refresh()
	_check(main.phase==main.Phase.FAILED and _diag().active.is_empty(),"original abort clears saved blast visuals")
	var nodes:=pool.get_children().map(func(node:Node)->WeakRef:return weakref(node))
	var pool_ref: WeakRef=weakref(pool)
	main._return_to_title()
	await process_frame
	await process_frame
	_check(pool_ref.get_ref()==null and nodes.all(func(ref:WeakRef)->bool:return ref.get_ref()==null),"original Title exit releases pool and all fixed mesh nodes")

func _run() -> void:
	directory="res://build/asset_review/pr15-runtime/tool-fx-pool-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	await _empty_and_duplicate()
	_check(ResourceLoader.exists(READER_PATH),"planned strict saved blast reader exists")
	pool=main.presentation_3d.get_node_or_null("ToolFx")
	_check(pool!=null,"planned presenter owns fixed blast/smoke pool")
	if ResourceLoader.exists(READER_PATH) and pool!=null:
		reader=load(READER_PATH)
		await _pool_cases(ViewState.capture(main),"actual-empty-grenade")
		await _damage()
		_reader_cases(ViewState.capture(main))
		await _pool_cases(ViewState.capture(main),"actual-damage-grenade")
		await _mine()
		var frame:=ViewState.capture(main)
		_check(reader.active(frame).size()==1,"actual mine canonical victim event accepted")
		var corrupted:=frame.duplicate(true)
		corrupted.tool_fx.front().original_event.actor_id+=1
		_check(reader.active(corrupted).is_empty(),"explicit wrong mine victim event rejected without treating actor as owner")
		await _pool_cases(frame,"actual-mine")
		await _history_cases()
	root.get_node("AudioDirector").pause_for_background()
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"captures":captures,"scope":"actual original tool sources; explicit backend grants/placement/clock/reader/capacity/corrupt copies/consumer fixtures. Real Window crops only in render mode; not normal13/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("TOOL_FX_POOL_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
