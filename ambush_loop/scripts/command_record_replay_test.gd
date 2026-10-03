extends "res://scripts/command_pose_clock_test.gd"

const ViewState := preload("res://scripts/presentation/view_state.gd")
var rows := []
var checkpoints := []
var captures := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("COMMAND_RECORD_FAIL " + message)

func _frames(log: BattleLog) -> Array:
	var raw = log.get("playback_snapshots")
	return raw if raw is Array else log.snapshots

func _command_frame(log: BattleLog, clock: float) -> Dictionary:
	for record: Dictionary in _frames(log):
		if int(record.data.get("phase", -1)) == 5 and is_equal_approx(float(record.data.get("pose_clock_s", -1.0)), clock):
			return record
	return {}

func _capture_record(main: Node, label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	main._update_hud()
	var view=main.presentation_3d
	var actors: Array=ViewState.capture(main).ops.filter(func(item: Dictionary) -> bool: return item.id==3)
	if not actors.is_empty():
		view.rig.focus=Space.logic_to_world(actors[0].pos)
		view.rig.view_size=12.0
		view.rig.yaw_deg=180.0
		view.rig.pitch_deg=65.0
		view.rig.apply_pose()
	view.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://build/asset_review/pr15-runtime/command_record_" + label + ".png"
	_check(root.get_texture().get_image().save_png(path) == OK, "save actual command record frame " + label)
	captures.append({"path":path,"sha256":FileAccess.get_sha256(path)})

func _run() -> void:
	root.size=Vector2i(1280,720)
	var settings=root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main=current_scene
	main.set_process(false)
	var view=main.presentation_3d
	view.set_process(false)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	main.raid_force_alarm()
	var steps := 0
	while main.phase==main.Phase.WATCHING and steps<5000:
		main._sim_tick()
		steps+=1
	_check(main.phase==main.Phase.SWEEP,"actual original first wave reaches SWEEP")
	if main.phase!=main.Phase.SWEEP: quit(2); return
	var battle_tick: int=main.sim.tick
	var original_events: Array=main.battle_log.events.duplicate(true)
	var original_wave_offset: int=main.battle_log.wave_offset
	main._select_op(2)
	var from: Vector2=main.selected.global_position
	main._command_move_selected(main.grid.cell_to_world_center(Vector2i(32,16)))
	_check(main.selected.is_moving(),"ordinary command API accepts original legal scout path")
	for i in 48:
		main._process(1.0/60.0)
		view.refresh()
		if (i+1)%6==0:
			var clock: float=main._pose_command_clock_s
			var stored := _command_frame(main.battle_log,clock)
			_check(not stored.is_empty(),"actual process retains SWEEP sample "+str(i+1))
			checkpoints.append({"clock":clock,"record":stored.duplicate(true),"position":main.selected.global_position,"bones":_bones(view.actors["ops:3"].get_node("Body") as Actor)})
	_check(main.selected.global_position!=from,"real command movement occurred")
	_check(main.sim.tick==battle_tick and main.battle_log.events==original_events and main.battle_log.wave_offset==original_wave_offset,"continuous record preserves original battle clock/events/offset")
	await _capture_record(main,"live_sweep_0800")
	var before_frames: Array=_frames(main.battle_log).duplicate(true)
	main._toggle_pause_menu()
	main._process(0.5)
	_check(_frames(main.battle_log)==before_frames,"actual pause produces no additional command records")
	main.pause_overlay.dismiss()
	main._process(0.4)
	_check(_frames(main.battle_log).size()>before_frames.size(),"normal resume records new command state")
	main.handle_app_focus_out()
	before_frames=_frames(main.battle_log).duplicate(true)
	main._process(0.5)
	_check(_frames(main.battle_log)==before_frames,"actual background produces no new records")
	main.handle_app_focus_in()
	main._process(0.2)
	_check(main.sim.tick==battle_tick,"command resume keeps original frozen simulation tick")
	main.raid_vacuum_loot()
	main._on_sweep_commit()
	steps=0
	while main.phase==main.Phase.WATCHING and steps<5000:
		main._sim_tick()
		steps+=1
	_check(main.phase==main.Phase.SWEEP and main.raid.waves_cleared==2,"actual original second wave reaches final SWEEP")
	if main.phase==main.Phase.SWEEP:
		main._process(0.8)
		main.raid_vacuum_loot()
		main._on_sweep_commit()
	_check(main.phase==main.Phase.WON,"ordinary extraction reaches WON")
	var source: BattleLog=main.battle_log
	var retained: Array=_frames(source).duplicate(true)
	var chronological := true
	var previous := -1
	for i in retained.size():
		var record: Dictionary=retained[i]
		chronological=chronological and int(record.get("frame_seq",-1))==i and int(record.get("playback_tick",-1))>=previous and str(record.attempt_id)==source.attempt_id
		previous=int(record.get("playback_tick",-1))
	_check(chronological,"actual cross-wave records retain monotonic playback time and stable attempt/frame sequence")
	rows.append({"terminal":"won","battle_terminal_tick":source.terminal_tick,"events":source.events.size(),"fingerprint":source.fingerprint(),"frame_count":retained.size()})
	_check(int(source.get("playback_schema") if source.get("playback_schema")!=null else 0)==1,"actual recording declares supported continuous playback version")
	if source.get("playback_terminal_tick")!=null:
		_check(int(source.get("playback_terminal_tick"))==source.terminal_tick+132,"2.2 actual unpaused SWEEP seconds add 132 playback ticks without altering battle terminal")
	main._on_replay_pressed()
	_check(main.phase==main.Phase.REPLAY,"normal production REPLAY entry")
	main.battle_log=BattleLog.new()
	main._pose_command_clock_s+=50.0
	main._night_timer+=50.0
	main.sim.tick+=5000
	main.run_id+=123
	main.operators[2].global_position+=Vector2(3000,3000)
	var live: Dictionary=main._snapshot_data().duplicate(true)
	for index in [0,1,2,3,4,5,6,7,6,5,4,3,2,1,0,7]:
		var checkpoint: Dictionary=checkpoints[index]
		var record: Dictionary=checkpoint.record
		if record.is_empty(): continue
		main.replay.set_tick(int(record.get("playback_tick",record.get("timeline_tick",record.tick))))
		main._apply_replay_scrub()
		view.refresh()
		var frame: Dictionary=ViewState.capture(main)
		_check(frame.recorded_phase==main.Phase.SWEEP and frame.wave_id==0,"back/forward resolves recorded command phase and wave")
		_check(frame.ops[2].pos==checkpoint.position,"historical actual moving position is recorded, not borrowed from current actor")
		_check(_bones(view.actors["ops:3"].get_node("Body") as Actor)==checkpoint.bones,"same actual command record reproduces exact root and 20 bone poses")
		_check(_frames(source)==retained and main._snapshot_data()==live,"command scrub preserves complete source and poisoned live state")
		rows.append({"command_clock":checkpoint.clock,"playback_tick":main.replay.scrub_tick,"battle_tick":frame.tick,"position":str(frame.ops[2].pos)})
	await _capture_record(main,"history_sweep_0800")
	if not checkpoints[0].record.is_empty():
		var sample_record: Dictionary=checkpoints[0].record
		main.replay.set_tick(int(sample_record.playback_tick)+3)
		var between: Dictionary=ViewState.capture(main)
		_check(is_equal_approx(between.pose_clock_s,checkpoints[0].clock+0.05) and is_equal_approx(between.pose_snapshot_delta_s,0.05),"between actual command records the copied pose clock advances by the playback interval")
		_check(between.tick==battle_tick and between.events.all(func(ev: Dictionary) -> bool: return int(ev.wave_id)==0),"between command records battle time stays frozen and next-wave events remain excluded")
		rows.append({"between_record_delta":between.pose_snapshot_delta_s,"battle_tick":between.tick,"playback_tick":main.replay.scrub_tick})
	main._process(0.5)
	_check(_frames(source)==retained,"REPLAY process cannot append recording frames")
	if source.get("playback_schema")!=null:
		var event: Dictionary=source.last_of_type("fire")
		main._focus_battle_event(event)
		_check(main.replay.scrub_tick==int(event.get("playback_tick",-1)),"normal event click seeks the saved playback time across SWEEP")
		var legacy:=BattleLog.new()
		legacy.snapshots=source.snapshots.duplicate(true)
		legacy.events=source.events.duplicate(true)
		legacy.terminal_tick=source.terminal_tick
		var player:=ReplayPlayer.new()
		player.bind(legacy)
		_check(player.max_tick()==source.terminal_tick,"missing playback schema retains original battle time and source records")
		legacy.set("playback_schema",99)
		legacy.set("playback_snapshots",retained.duplicate(true))
		player.bind(legacy)
		_check(player.max_tick()==source.terminal_tick,"unknown playback schema refuses command expansion and retains original battle fallback")
		var malformed:=BattleLog.new()
		malformed.attempt_id=source.attempt_id
		malformed.snapshots=source.snapshots.duplicate(true)
		malformed.events=source.events.duplicate(true)
		malformed.terminal_tick=source.terminal_tick
		malformed.set("playback_schema",1)
		var broken: Array=retained.duplicate(true)
		broken[1].playback_tick=-1
		malformed.set("playback_snapshots",broken)
		var before: Array=broken.duplicate(true)
		player.bind(malformed)
		_check(player.max_tick()==source.terminal_tick and player.playback_unsupported and malformed.get("playback_snapshots")==before,"malformed copied playback clock falls back without changing its source")
	# A fresh actual SWEEP verifies the entry boundary before the next 0.1s sample.
	main._load_level("yard",false,false)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	main.raid_force_alarm()
	steps=0
	while main.phase==main.Phase.WATCHING and steps<5000:
		main._sim_tick()
		steps+=1
	main._select_op(2)
	main._command_move_selected(main.grid.cell_to_world_center(Vector2i(32,16)))
	main._process(0.05)
	var partial: Dictionary=main._snapshot_data().duplicate(true)
	main._on_replay_pressed()
	var entered: Dictionary=ViewState.capture(main)
	_check(entered.recorded_phase==main.Phase.SWEEP and is_equal_approx(entered.pose_clock_s,float(partial.pose_clock_s)) and entered.ops[2].pos==partial.ops[2].pos,"normal SWEEP replay entry saves the final unsampled partial interval")
	for aborted in [false,true]:
		main._load_level("yard",false,false)
		main.raid_prepare_ref([],[])
		main.raid_force_alarm()
		if aborted: main._on_abort_pressed()
		else:
			steps=0
			while main.phase==main.Phase.WATCHING and steps<5000:
				main._sim_tick()
				steps+=1
		_check(main.phase==main.Phase.FAILED and main.fail_reason==("abort" if aborted else "escape"),"actual normal FAILED route "+str(aborted))
		var terminal: Dictionary=_frames(main.battle_log).back()
		_check(int(terminal.data.phase)==main.Phase.FAILED,"continuous recording retains real FAILED terminal boundary "+str(aborted))
		rows.append({"terminal":main.fail_reason,"battle_terminal_tick":main.battle_log.terminal_tick,"events":main.battle_log.events.size(),"recorded_phase":terminal.data.phase})
	root.get_node("AudioDirector").pause_for_background()
	# Retain an actual production stream, including typed copied values, for
	# compatibility checks against later supported playback revisions.
	var stream_path := "res://build/asset_review/pr15-runtime/command-record-source-v%d.bin" % source.playback_schema
	var stream_file := FileAccess.open(stream_path,FileAccess.WRITE)
	stream_file.store_buffer(var_to_bytes({"attempt_id":source.attempt_id,"events":source.events,"snapshots":source.snapshots,"terminal_tick":source.terminal_tick,"terminal_reason":source.terminal_reason,"playback_schema":source.playback_schema,"playback_snapshots":source.playback_snapshots,"playback_terminal_tick":source.playback_terminal_tick}))
	stream_file.close()
	var file:=FileAccess.open("res://build/asset_review/pr15-runtime/command-record-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures,"source_binary":{"path":stream_path,"sha256":FileAccess.get_sha256(stream_path)}},"  "))
	print("COMMAND_RECORD_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
