extends "res://scripts/tool_fx_source_test.gd"
## Original tool callbacks; command APIs and clock/placement fixtures are explicit.
const OldSources := preload("res://scripts/shot_fx_pool_test.gd")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("TOOL_FX_SOURCE_BOUNDARY_FAIL "+message)

func _quiet() -> Array:
	var pair: Array=await _reset()
	pair[1].global_position=Vector2(960,576)
	for op: OperatorUnit in main.operators:
		op.slot=null
		op.stop_move()
		op.global_position=Vector2(80,80)
	return pair

func _log_state(log: BattleLog) -> PackedByteArray:
	return var_to_bytes([log.events,log.snapshots,log.playback_snapshots,log.attempt_id,log.wave_id,log.wave_offset,log.terminal_tick,log.terminal_reason,log.playback_schema,log.playback_terminal_tick,log.current_playback_tick()])

func _capacity() -> void:
	var pair: Array=await _quiet()
	var grenades: Array=[]
	var original_events: int=main.battle_log.events.size()
	for index in 66: grenades.append(_throw(pair[0],Vector2(80,240)))
	_check(main.visual_snapshot.tool_fx._tools.size()==64 and main.raid_grenades.size()==66,"metadata registry caps64 while all66 original throws remain real")
	await _blast(grenades)
	var effects:=_effects()
	_check(grenades.all(func(g: RaidGrenade)->bool:return g.spent()) and effects.size()==48 and main.visual_snapshot.tool_fx._tools.is_empty(),"all actual tools detonate; recent48 and spent weak-link cleanup bounded")
	_check(main.battle_log.events.size()==original_events and pair[1].hp==100.0 and main.operators.all(func(op:OperatorUnit)->bool:return op.hp==100.0),"overcapacity affects metadata only, original empty attacks retain HP/event behavior")
	var identities: Array=[]
	for effect: Dictionary in effects:
		_check(not identities.has(effect.effect_id) and effect.seq==16+identities.size() and effect.tool_id=="%s:tool:%d" % [main.battle_log.attempt_id,effect.seq],"same-tick real tools keep unique stable sequence "+str(effect.seq))
		identities.append(effect.effect_id)
	_check(effects.all(func(effect:Dictionary)->bool:return effect.clock_tick==effects.front().clock_tick),"actual same-fuse tools confirm on same playback tick")
	var next:=_throw(pair[0],Vector2(80,240))
	await _blast([next])
	var latest: Dictionary=_effects().back()
	_check(latest.seq==64 and latest.tool_id=="%s:tool:64" % main.battle_log.attempt_id,"metadata capacity recovers after real tool settlement without reusing admitted IDs")
	for index in 180: main.battle_log.advance_simulation_playback() # Explicit retention boundary clock fixture.
	_check(_effects().size()==1 and _effects().back().effect_id==latest.effect_id,"actual latest descriptor retained exactly at180 playback ticks")
	main.battle_log.advance_simulation_playback()
	_check(_effects().is_empty(),"actual descriptor expires at181 playback ticks; no wall clock timer")
	rows.append({"case":"actual66-tools-same-tick","admitted":64,"retained":48,"first_seq":16,"last_seq":63,"next_seq":latest.seq,"original_events":original_events,"scope":"actual throws/fuses; granted inventory, explicit positions and retention clock fixture; no performance claim"})

func _wave_and_source() -> void:
	var pair: Array=await _quiet()
	var grenade:=_throw(pair[0],Vector2(80,240))
	var created_wave: int=main.battle_log.wave_id
	var attempt: String=main.battle_log.attempt_id
	var run: int=main.run_id
	main._begin_next_wave() # Original API; no claim that fixture cleared authored wave.
	await _blast([grenade])
	var effects:=_effects()
	_check(main.run_id==run+1 and main.battle_log.attempt_id==attempt and main.battle_log.wave_id==created_wave+1 and effects.size()==1,"actual next-wave API retains unspent original tool and stable attempt despite run token increment")
	if not effects.is_empty():
		_check(effects.front().created_wave_id==created_wave and effects.front().wave_id==main.battle_log.wave_id and effects.front().tool_id==attempt+":tool:0","actual cross-wave tool separates creation wave from confirmation wave")
		rows.append({"case":"actual-unspent-tool-next-wave-api","effect":effects.front(),"run_before":run,"run_after":main.run_id,"scope":"original next-wave API fixture, not completed full battle"})
	main.battle_log.begin_wave(main.battle_log.wave_id+1) # Explicit phase identity boundary.
	_check(_effects().is_empty(),"recent descriptor cancels on next wave rather than replaying old confirmation")
	for same_attempt in [true,false]:
		pair=await _quiet()
		grenade=_throw(pair[0],Vector2(80,240))
		var previous: BattleLog=main.battle_log
		var previous_bytes:=_log_state(previous)
		var replacement:=BattleLog.new()
		replacement.begin_attempt(previous.attempt_id if same_attempt else "foreign-tool-source")
		replacement.enable_continuous_playback(2)
		main.battle_log=replacement
		await _blast([grenade])
		_check(grenade.spent() and _effects().is_empty() and main.visual_snapshot.tool_fx._tools.is_empty(),"actual pending tool cannot rebind to foreign log even with same attempt="+str(same_attempt))
		_check(_log_state(previous)==previous_bytes and replacement.events.is_empty() and pair[1].hp==100.0,"foreign-source rejection preserves old log bytes and original empty attack="+str(same_attempt))

func _command_and_pause() -> void:
	for wanted in [main.Phase.SETUP,main.Phase.SWEEP]:
		var pair: Array=await _quiet()
		if wanted==main.Phase.SETUP:
			main._start_setup(false,false) # Actual original reset; explicitly grant/place the tool afterward.
			for op: OperatorUnit in main.operators:
				op.stop_move()
				op.slot=null
				op.global_position=Vector2(80,80)
		else:
			main._enter_sweep() # Original phase API fixture, no natural wave-clear claim.
		var owner: OperatorUnit=main.operators[0]
		var grenade:=_throw(owner,Vector2(80,240))
		var sim_tick: int=main.sim.tick
		for index in 180:
			main._process(1.0/60.0)
			if grenade.spent(): break
		var effects:=_effects()
		_check(grenade.spent() and effects.size()==1 and main.sim.tick==sim_tick,"actual command _process advances tool without advancing simulation tick phase="+str(wanted))
		if not effects.is_empty():
			_check(effects.front().phase==wanted and effects.front().clock_tick>effects.front().created_clock_tick and effects.front().local_tick==sim_tick,"actual command confirmation uses continuous playback clock phase="+str(wanted))
	var pair: Array=await _quiet()
	var grenade:=_throw(pair[0],Vector2(80,240))
	main._on_pause_pressed()
	var before:=var_to_bytes([grenade._flight,grenade._t,grenade.global_position,pair[0].hp,pair[1].hp,_effects(),_log_state(main.battle_log)])
	for index in 30: main._process(0.25)
	_check(main.sim.paused and not grenade.spent() and var_to_bytes([grenade._flight,grenade._t,grenade.global_position,pair[0].hp,pair[1].hp,_effects(),_log_state(main.battle_log)])==before,"actual paused ALERT _process cannot progress fuse/flight/HP/events/descriptors through30 explicit calls")
	main._on_pause_pressed()
	await _blast([grenade])
	_check(not main.sim.paused and grenade.spent() and _effects().size()==1,"unpaused real tool can confirm after original pause toggle")

func _history() -> void:
	await _terminal()
	var saved: BattleLog=main.battle_log
	var before:=_log_state(saved)
	var expected: Array=saved.playback_snapshots.back().data.tool_fx.duplicate(true)
	main._on_replay_pressed()
	main.replay.set_tick(saved.playback_terminal_tick)
	main.replay.pause()
	var frame:=ViewState.capture(main)
	_check(frame.replay and frame.tool_fx_schema==1 and frame.tool_fx==expected and frame.tool_fx.is_read_only() and frame.tool_fx.front().victims.is_read_only(),"original REPLAY exposes immutable saved terminal descriptors")
	var saved_token: int=frame.tool_fx_source_token
	main.battle_log=BattleLog.new() # Detach before original setup clears the current recording.
	var pair: Array=await _quiet()
	var grenade:=_throw(pair[0],Vector2(80,240))
	await _blast([grenade])
	var foreign: BattleLog=main.battle_log
	var foreign_before:=_log_state(foreign)
	_check(_effects().size()==1 and foreign.attempt_id!=saved.attempt_id,"actual foreign live log has its own confirmed original blast")
	main.phase=main.Phase.REPLAY # Explicit bound-history fixture over actual foreign blast.
	main.replay.bind(saved)
	main.replay.set_tick(saved.playback_terminal_tick)
	frame=ViewState.capture(main)
	_check(frame.tool_fx==expected and frame.tool_fx_source_token==saved_token and frame.tool_fx.front().attempt_id==saved.attempt_id,"bound saved descriptors never borrow actual foreign live blast")
	var raw: Dictionary=saved.playback_snapshots.back().duplicate(true)
	# This explicit one-frame fixture must be a valid continuous record before
	# testing the adjunct gate, rather than failing the transport sequence gate.
	raw.frame_seq=0
	var control:=BattleLog.new()
	control.begin_attempt(saved.attempt_id)
	control.enable_continuous_playback(2)
	control.playback_snapshots=[raw.duplicate(true)]
	main.replay.bind(control)
	main.replay.set_tick(raw.playback_tick)
	frame=ViewState.capture(main)
	_check(main.replay.continuous_playback and not main.replay.playback_unsupported and frame.tool_fx_schema==1 and frame.tool_fx==expected,"legal explicit one-frame control retains actual saved descriptor before corrupt adjunct cases")
	for schema: Variant in [null,0,2,true,"1",1.0]:
		var copy:=BattleLog.new()
		copy.begin_attempt(saved.attempt_id)
		copy.enable_continuous_playback(2)
		var snap:=raw.duplicate(true)
		if schema==null: snap.data.erase("tool_fx_schema")
		else: snap.data.tool_fx_schema=schema
		copy.playback_snapshots=[snap]
		main.replay.bind(copy)
		main.replay.set_tick(snap.playback_tick)
		frame=ViewState.capture(main)
		_check(main.replay.continuous_playback and not main.replay.playback_unsupported and frame.tool_fx_schema==0 and frame.tool_fx.is_empty(),"explicit corrupt adjunct version is structurally neutral with valid transport "+str(schema))
	for malformed: Variant in [{},null,"bad"]:
		var copy:=BattleLog.new()
		copy.begin_attempt(saved.attempt_id)
		copy.enable_continuous_playback(2)
		var snap:=raw.duplicate(true)
		snap.data.tool_fx=malformed
		copy.playback_snapshots=[snap]
		main.replay.bind(copy)
		main.replay.set_tick(snap.playback_tick)
		frame=ViewState.capture(main)
		_check(main.replay.continuous_playback and not main.replay.playback_unsupported and frame.tool_fx_schema==0 and frame.tool_fx.is_empty(),"explicit corrupt adjunct container is structurally neutral with valid transport "+str(malformed))
	for id: String in ["schema1"]+OldSources.INITIAL.keys():
		var path: String=OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE") if id=="schema1" else OS.get_environment("AMBUSH_INITIAL_RECORD_ROOT")+"/native-player-"+id+"-record.bin"
		var expected_hash: String=OldSources.LEGACY_SHA if id=="schema1" else OldSources.INITIAL[id]
		_check(FileAccess.get_sha256(path)==expected_hash,"authentic original raw fixture exists unchanged "+id)
		if FileAccess.get_sha256(path)!=expected_hash: continue
		var record: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
		var old:=BattleLog.new()
		for key in record: old.set(key,record[key])
		var raw_bytes:=var_to_bytes(record)
		var old_bytes:=_log_state(old)
		main.replay.bind(old)
		for tick in [0,main.replay.max_tick()]:
			main.replay.set_tick(tick)
			frame=ViewState.capture(main)
			_check(frame.tool_fx_schema==0 and frame.tool_fx.is_empty(),"actual old source neutral over foreign live blast "+id+":"+str(tick))
		_check(_log_state(old)==old_bytes and var_to_bytes(record)==raw_bytes and FileAccess.get_sha256(path)==expected_hash,"actual old source memory/raw remains unchanged "+id)
		rows.append({"case":"actual-old-raw-neutral-"+id,"sha256":expected_hash,"events":old.events.size(),"raw_unchanged":true})
	_check(_log_state(saved)==before and _log_state(foreign)==foreign_before,"all saved/foreign recordings retain exact memory after immutable history reads")

func _run() -> void:
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	await _capacity()
	await _wave_and_source()
	await _command_and_pause()
	await _history()
	root.get_node("AudioDirector").pause_for_background()
	var directory: String="res://build/asset_review/pr15-runtime/tool-fx-source-boundary-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"scope":"actual original tool callbacks with granted inventory/placed actors/direct APIs and explicit clock/corrupt-container fixtures; read-only authentic old logs. Structural source interface only; no full renderer/native normal/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("TOOL_FX_SOURCE_BOUNDARY_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
