extends "res://scripts/shot_fx_pool_test.gd"
## Real original throw/sim_step and saved-frame consumer fixtures, no normal-play claim.
var saved_samples: Array = []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("GRENADE_FLIGHT_FAIL " + message)

func _grenade_state(grenade: RaidGrenade) -> PackedByteArray:
	return var_to_bytes([main.sim.tick,main.sim.paused,main.sim._accum,
		grenade.global_position,grenade.target,grenade._origin,grenade._flight,
		grenade._flight_t,grenade.fuse,grenade.bounced,grenade._done,
		main.operators.map(func(op: OperatorUnit) -> Array: return [op.op_id,op.ammo,op.grenades,op.hp]),
		_state(main.battle_log)])

func _height(item: Dictionary, label: String) -> float:
	var key := "grenades:%s" % item.id
	var view: Node3D = main.presentation_3d
	var proxy: Node3D = view.objects.get(key)
	var visual: Node3D = proxy.get_node_or_null("EnvironmentVisual") if proxy != null else null
	_check(proxy != null and visual != null, label + " actual authored grenade proxy exists")
	if visual == null: return NAN
	var expected := sin(clampf(float(item.flight),0.0,1.0)*PI)*1.25
	_check(is_equal_approx(visual.position.y,expected), label + " normalized saved progress determines original 1.25m arc without duration division")
	_check(proxy.position.is_equal_approx(Space.logic_to_world(item.pos)), label + " original saved tactical position maps unchanged")
	return visual.position.y

func _sample(grenade: RaidGrenade, label: String, expected_progress: float, dt: float = 0.0, capture: bool = true) -> void:
	if dt > 0.0:
		main._tick_raid_grenades(dt) # Actual original sim_step; explicit dt fixture.
		main.battle_log.advance_command_playback(dt) # Explicit presentation clock fixture, not natural gameplay.
	var data: Dictionary = main._snapshot_data()
	var items: Array = data.grenades
	_check(items.size()==1 and is_equal_approx(grenade._flight,expected_progress),label+" actual original progress reached")
	if items.is_empty(): return
	var item: Dictionary=items.front()
	_check(item.flight==grenade._flight and item.flight_duration==grenade._flight_t and item.pos==grenade.global_position,label+" actual snapshot copies normalized progress/duration/original position")
	main.battle_log.add_snapshot(main.sim.tick,data)
	var before:=_grenade_state(grenade)
	var source_bytes:=var_to_bytes(data)
	main.presentation_3d.refresh()
	var height:=_height(item,label)
	_check(_grenade_state(grenade)==before and var_to_bytes(data)==source_bytes,label+" presentation retains actual grenade/sim/ammo/HP/log/source bytes")
	saved_samples.append({"label":label,"tick":main.battle_log.current_playback_tick(),"item":item.duplicate(true),"actual_y":height})
	rows.append({"case":label,"phase":int(main.phase),"actual_progress":grenade._flight,"actual_duration_s":grenade._flight_t,"actual_logic_pos":grenade.global_position,"actual_y":height,"expected_y":sin(expected_progress*PI)*1.25,"scope":"original real throw/sim_step with explicit dt and presentation-clock fixture"})
	main.presentation_3d.rig.focus=Space.logic_to_world(grenade.global_position)
	main.presentation_3d.rig.view_size=12.0
	main.presentation_3d.rig.apply_pose()
	if capture: await _capture(label)

func _saved_history(grenade: RaidGrenade) -> void:
	main.battle_log.mark_terminal(main.sim.tick,"grenade-flight-consumer-fixture")
	var saved: BattleLog=main.battle_log
	var source_before:=_state(saved)
	main._on_replay_pressed()
	_check(main.phase==main.Phase.REPLAY and main.replay.log==saved and main.replay.continuous_playback,"original REPLAY entry binds real saved flight samples")
	var live_before:=_grenade_state(grenade)
	for sample: Dictionary in saved_samples:
		main.replay.set_tick(sample.tick)
		main.presentation_3d.refresh()
		var items: Array=main.presentation_3d.frame.grenades
		var latest: Dictionary=sample
		for candidate: Dictionary in saved_samples:
			if candidate.tick==sample.tick: latest=candidate
		_check(items.size()==1 and items.front().flight==latest.item.flight,"original seek retains latest exact saved frame at tick "+str(sample.tick))
		if not items.is_empty(): _height(items.front(),"replay-"+sample.label)
	main.replay.set_tick(saved_samples[2].tick)
	main.presentation_3d.refresh()
	var fixed: Dictionary=main.presentation_3d.frame.grenades.front()
	var proxy: Node3D=main.presentation_3d.objects["grenades:%s" % fixed.id]
	var visual: Node3D=proxy.get_node("EnvironmentVisual")
	var paused_height:=visual.position.y
	for index in 30:
		await process_frame
		main.replay.advance(1.0/60.0)
		main.presentation_3d.refresh()
	_check(visual.position.y==paused_height and main.replay.scrub_tick==saved_samples[2].tick,"paused actual30 draw frames keep same saved height and playback tick")
	_check(_state(saved)==source_before and _grenade_state(grenade)==live_before,"history seeks/pause retain original source and actual live grenade/sim/ammo/HP")
	await _capture("replay-saved-midpoint")
	for variant: String in ["missing-duration","different-duration"]:
		var frame: Dictionary=main.presentation_3d.frame.duplicate(true)
		if variant=="missing-duration": frame.grenades.front().erase("flight_duration")
		else: frame.grenades.front().flight_duration=9.0
		var before:=var_to_bytes(frame)
		main.presentation_3d.frame=frame
		main.presentation_3d._sync_objects() # Explicit compatible saved-field fixture, not a real old raw.
		_height(frame.grenades.front(),variant)
		_check(var_to_bytes(frame)==before and _state(saved)==source_before,variant+" ignores duration without rewriting saved fields/source")

func _authentic_old_records() -> void:
	var total_samples:=0
	for id: String in INITIAL:
		var path:=OS.get_environment("AMBUSH_INITIAL_RECORD_ROOT")+"/native-player-"+id+"-record.bin"
		var hash_before:=FileAccess.get_sha256(path)
		_check(hash_before==INITIAL[id],"authentic INITIAL raw exists with exact producer a05 hash "+id)
		if hash_before!=INITIAL[id]: continue
		var raw: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
		var log:=BattleLog.new()
		for key in raw: log.set(key,raw[key])
		var source_before:=_state(log)
		var raw_before:=var_to_bytes(raw)
		main.replay.bind(log)
		var found:=0
		for snapshot: Dictionary in log.playback_snapshots:
			var items: Array=snapshot.data.get("grenades",[])
			if items.is_empty(): continue
			var item: Dictionary=items.front()
			if float(item.flight)<=0.0 or float(item.flight)>=1.0: continue
			main.replay.set_tick(snapshot.playback_tick)
			main.presentation_3d.refresh()
			_height(item,"authentic-a05-"+id)
			found+=1
			break
		total_samples+=found
		_check(_state(log)==source_before and var_to_bytes(raw)==raw_before and FileAccess.get_sha256(path)==hash_before,"authentic old record file/memory remain exact "+id)
		rows.append({"case":"authentic-a05-"+id,"sha256":hash_before,"actual_midflight_samples_checked":found,"scope":"original native producer bytes consumed read-only; no new battle/new record"})
	rows.append({"case":"authentic-old-coverage","actual_midflight_samples_checked":total_samples,"scope":"zero means no old-flight height claim for that file; never regenerate old records"})

func _run_cases() -> void:
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0],{"grenades":2,"mines":0})
	pool=main.presentation_3d.shot_fx
	var op: OperatorUnit=main.operators[0]
	var inventory_before:=op.grenades
	var event_count: int=main.battle_log.events.size()
	_check(main._throw_grenade_from(op,op.global_position+Vector2(160,0)),"actual original SCOUT throw succeeds")
	_check(main.raid_grenades.size()==1 and op.grenades==inventory_before-1 and main.battle_log.events.size()==event_count,"actual released object and original inventory/log statistics preserved")
	if main.raid_grenades.is_empty(): return
	var grenade: RaidGrenade=main.raid_grenades.back()
	await _sample(grenade,"launch",0.0)
	await _sample(grenade,"quarter-flight",0.25,0.045)
	await _sample(grenade,"mid-flight",0.5,0.045)
	await _sample(grenade,"first-land",1.0,0.09)
	await _sample(grenade,"bounce-start",0.55,0.001)
	_check(grenade.bounced and grenade.target==grenade._origin+Vector2(168,6) and is_equal_approx(grenade._flight_t,0.1),"actual original bounce offset8,6 and duration0.1 retained")
	await _sample(grenade,"bounce-flight",0.8,0.025)
	await _sample(grenade,"bounce-land",1.0,0.025)
	await _sample(grenade,"settled",1.0,0.001)
	_check(grenade.global_position==grenade.target and not grenade.spent(),"original settled grenade waits for real fuse; disappearance is not blast proof")
	await _saved_history(grenade)
	await _authentic_old_records()

func _run() -> void:
	directory="res://build/asset_review/pr15-runtime/grenade-flight-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	await _run_cases()
	root.get_node("AudioDirector").pause_for_background()
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"captures":captures,"scope":"actual original SCOUT throw/sim_step + explicit dt/clock/snapshot/consumer fixtures; no normal native battle, blast FX, FINAL/A3/device acceptance"},"  "))
	file.close()
	print("GRENADE_FLIGHT_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
