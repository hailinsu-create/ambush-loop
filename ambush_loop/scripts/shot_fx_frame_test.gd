extends "res://scripts/shot_fx_boundary_test.gd"
## Real backend source + explicit corrupt immutable reader fixtures; no rendered claim.
const ViewState := preload("res://scripts/presentation/view_state.gd")
const ActorVisual := preload("res://scripts/presentation/actor_visual.gd")
const READER_PATH := "res://scripts/presentation/shot_fx_frame.gd"
var reader: Script

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("SHOT_FX_FRAME_FAIL " + message)

func _bad(frame: Dictionary, event: Dictionary, target: String, key: String, value: Variant, remove: bool = false) -> void:
	var f := frame.duplicate(true)
	var e := event.duplicate(true)
	var container: Dictionary = f if target == "frame" else (e if target == "event" else (e.payload.fx.pose if target == "pose" else e.payload.fx))
	if remove: container.erase(key)
	else: container[key] = value
	var preserved := var_to_bytes([f,e])
	_check(reader.sample(f,e).is_empty() and var_to_bytes([f,e])==preserved, "neutral read-only %s.%s=%s remove=%s" % [target,key,str(value),str(remove)])

func _reader_cases(frame: Dictionary, event: Dictionary) -> void:
	var retained := var_to_bytes([frame,event])
	var domain := {}
	for key in ["shot_fx_schema","shot_fx_playback_schema","shot_fx_source_token","schema","recorded_phase","animation_schema","animation_supported","actor_asset_revision","visual_unsupported","level_id","attempt_id","wave_id","playback_tick"]: domain[key] = frame.get(key)
	print("SHOT_FX_FRAME_DOMAIN "+JSON.stringify(domain))
	var descriptor: Dictionary = event.payload.fx
	var actual: Dictionary = reader.sample(frame,event)
	_check(not actual.is_empty() and actual.event_id == event.event_id and actual.age_ticks == 0 and actual.visual_weapon == descriptor.visual_weapon and actual.pose == descriptor.pose and actual.target_pos == descriptor.target_pos, "real successful source/pose/old gun/target retained at playback tick")
	_optional_bool_cases(frame,event)
	for age in [0,2,5,8,9,-1]:
		var copy := frame.duplicate(true)
		copy.playback_tick = int(event.playback_tick)+age
		var sample: Dictionary = reader.sample(copy,event)
		_check(sample.is_empty() if age<0 or age>=9 else not sample.is_empty() and sample.age_ticks==age,"source playback lifetime age="+str(age))
	var different_clocks := frame.duplicate(true)
	different_clocks.tick += 100000
	different_clocks.local_tick += 100000
	different_clocks.pose_clock_s += 100000.0
	_check(reader.sample(different_clocks,event)==actual,"simulation/pose/wall clocks cannot age playback FX")
	var foreign_actors := frame.duplicate(true)
	foreign_actors.ops[0].visual_weapon = "pistol"
	foreign_actors.ops[0].pos += Vector2(200,200)
	foreign_actors.enemies.clear()
	_check(reader.sample(foreign_actors,event)==actual,"current bodies/weapon/targets cannot replace saved original source")
	var repeated := true
	for index in 100: repeated = repeated and reader.sample(frame,event)==actual
	_check(repeated and var_to_bytes([frame,event])==retained,"repeat reads/seek-back return original result without spawning/upgrading or mutating frames/events")
	for row in [["shot_fx_schema",0],["shot_fx_schema",99],["shot_fx_playback_schema",1],["shot_fx_playback_schema",99],["shot_fx_source_token",0],["playback_tick",-1],["playback_tick",float(frame.playback_tick)],["attempt_id","foreign"],["wave_id",int(frame.wave_id)+1],["wave_count",0],["level_id","radio"],["recorded_phase",0],["recorded_phase",2],["recorded_phase",3],["animation_supported",false],["actor_asset_revision","unknown"],["animation_schema",99],["visual_unsupported",true]]:
		_bad(frame,event,"frame",row[0],row[1])
	for row in [["schema",1],["schema",99],["playback_schema",1],["playback_schema",99],["event_id","foreign"],["actor_id",999],["target_id",999],["type","kill"],["position",Vector2.INF]]:
		_bad(frame,event,"event",row[0],row[1])
	for key in ["schema","playback_schema"]: _bad(frame,event,"event",key,null,true)
	_bad(frame,event,"event","wave_id",float(event.wave_id))
	_bad(frame,event,"fx","wave_id",float(event.wave_id))
	_bad(frame,event,"fx","seq",float(event.seq))
	for row in [["schema",99],["confirmed",false],["confirmed","true"],["level_id","radio"],["attempt_id","foreign"],["wave_id",99],["seq",99],["event_id","foreign"],["clock_domain","simulation"],["playback_schema",1],["clock_tick",int(event.playback_tick)+1],["source_group","sentries"],["source_id",999],["target_group","ops"],["target_id",999],["source_pos",Vector2.INF],["target_pos",Vector2.INF],["source_facing",NAN],["actor_asset_revision","unknown"],["animation_schema",99],["visual_model","unknown"],["visual_weapon","unknown"],["projectile",false],["damage",-1.0],["damage",INF],["hp_before",INF],["hp_after",INF],["hp_after",float(event.payload.fx.hp_after)+1.0],["pose",{}]]:
		_bad(frame,event,"fx",row[0],row[1])
	for row in [["action","unknown"],["seconds",NAN],["seconds",-1.0],["upper_action","unknown"],["upper_seconds",INF],["base_seconds",-1.0],["visual_facing",NAN]]:
		_bad(frame,event,"pose",row[0],row[1])
	for key in ["schema","confirmed","playback_schema","clock_tick","pose"]: _bad(frame,event,"fx",key,null,true)
	var old := event.duplicate(true)
	old.payload.erase("fx")
	var before := var_to_bytes(old)
	_check(reader.sample(frame,old).is_empty() and var_to_bytes(old)==before,"old missing descriptor stays neutral and bytes are never upgraded")
	rows.append({"scope":"actual original backend shot plus explicit reader version/identity/time/corrupt fixtures, not rendered/native/fullrecord","frame_domain":domain,"source_event":event,"reader_sample":actual,"original_bytes_unchanged":var_to_bytes([frame,event])==retained})

func _optional_bool_cases(frame: Dictionary, event: Dictionary) -> void:
	var original := var_to_bytes([frame,event])
	var body := ActorVisual.new()
	body.visible = false
	root.add_child(body)
	_check(body.set_asset(event.payload.fx.visual_model,0,event.payload.fx.actor_asset_revision) and body.mount_item(event.payload.fx.visual_weapon),"original R5 hidden sampler loads saved model/gun for boolean compatibility")
	var absent := event.duplicate(true)
	absent.payload.fx.pose.erase("preserve_upper_world_basis")
	_check(not reader.sample(frame,absent).is_empty() and body.sample_layers(absent.payload.fx.pose),"missing optional flag retains original default-true pose compatibility")
	var baseline := []
	for index in body.skeleton.get_bone_count(): baseline.append(body.skeleton.get_bone_pose(index))
	for flag in [true,false]:
		var copy := absent.duplicate(true)
		copy.payload.fx.pose.preserve_upper_world_basis = flag
		var decoded: Dictionary = reader.sample(frame,copy)
		_check(not decoded.is_empty() and typeof(decoded.pose.preserve_upper_world_basis)==TYPE_BOOL and decoded.pose.preserve_upper_world_basis==flag and body.sample_layers(decoded.pose),"actual boolean flag is preserved and original sampler accepts "+str(flag))
		if flag:
			var equivalent := true
			for index in body.skeleton.get_bone_count(): equivalent = equivalent and baseline[index].is_equal_approx(body.skeleton.get_bone_pose(index))
			_check(equivalent,"absent default and explicit true retain all original20 bone transforms")
	for value in ["false","true",0,1,null,{},[]]:
		_bad(frame,event,"pose","preserve_upper_world_basis",value)
	var legacy_casts := {"integer_zero":bool(0),"integer_one":bool(1)}
	rows.append({"scope":"explicit optional flag compatibility/corrupt fixtures; original R5 sample_layers actual hidden sampler, no rendered claim","original_saved_flag_present":event.payload.fx.pose.has("preserve_upper_world_basis"),"original_legacy_bool_casts":legacy_casts,"all20_absent_true_bones_compared":true})
	_check(var_to_bytes([frame,event])==original,"optional boolean checks never rewrite original saved event/frame")
	body.free()

func _run() -> void:
	_check(ResourceLoader.exists(READER_PATH),"planned pure frame decoder interface exists")
	if ResourceLoader.exists(READER_PATH):
		reader = load(READER_PATH)
		var settings = root.get_node("GameSettings")
		settings.pending_level_id = "yard"
		settings.mark_tutorial_seen("yard")
		change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
		await process_frame
		await process_frame
		main = current_scene
		main.set_process(false)
		main.presentation_3d.set_process(false)
		var pair: Array = await _reset()
		var op: OperatorUnit = pair[0]
		var enemy: EnemyRunner = pair[1]
		op.apply_weapon("kar98k",true)
		var event := _event(op,enemy)
		_check(main._try_fire_with_recorded_fx(op,enemy,event) and event.payload.has("fx"),"actual existing original attack produces successful descriptor")
		var frame := ViewState.capture(main)
		var sim_state := [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,enemy.hp]
		var source_bytes := var_to_bytes(main.battle_log.events)
		_reader_cases(frame,event)
		_check([main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,enemy.hp]==sim_state and var_to_bytes(main.battle_log.events)==source_bytes,"pure reader preserves original log/ammo/HP/sim tuple")
	root.get_node("AudioDirector").pause_for_background()
	var directory := "res://build/asset_review/pr15-runtime/shot-fx-frame-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"scope":"Pure reader plus explicit original attack fixture; no 3D pool/native/new battles/FX integrated/A3/FINAL/device acceptance."},"  "))
	file.close()
	print("SHOT_FX_FRAME_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
