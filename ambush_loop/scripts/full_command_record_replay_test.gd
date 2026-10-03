extends "res://scripts/command_record_replay_test.gd"
## Production SCOUT samples must survive the ordinary first alarm.

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
	var attempt: String=main.battle_log.attempt_id
	_check(not attempt.is_empty(),"SCOUT starts its stored attempt identity before any alarm")
	_check(not _frames(main.battle_log).is_empty(),"production SCOUT retains its real initial frame")
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	main._select_op(2)
	var from: Vector2=main.selected.global_position
	main._command_move_selected(main.grid.cell_to_world_center(Vector2i(32,16)))
	_check(main.selected.is_moving(),"ordinary SCOUT command starts a real legal move")
	var scout_samples := []
	for i in 48:
		main._process(1.0/60.0)
		view.refresh()
		if (i+1)%6==0:
			var clock: float=main._pose_command_clock_s
			var matching: Array=_frames(main.battle_log).filter(func(record: Dictionary) -> bool: return int(record.data.phase)==main.Phase.SETUP and is_equal_approx(float(record.data.pose_clock_s),clock))
			_check(not matching.is_empty(),"production retains actual SCOUT movement sample "+str(i+1))
			scout_samples.append({"clock":clock,"record":matching.back().duplicate(true) if not matching.is_empty() else {},"position":main.selected.global_position,"bones":_bones(view.actors["ops:3"].get_node("Body") as Actor)})
	_check(main.selected.global_position!=from and main.sim.tick==0,"SCOUT advances actual command movement while battle time stays zero")
	await _capture_record(main,"full_scout_live_0800")
	var retained: Array=_frames(main.battle_log).duplicate(true)
	main._toggle_pause_menu()
	main._process(0.2)
	_check(_frames(main.battle_log)==retained,"paused SCOUT adds no clock or frame")
	main.pause_overlay.dismiss()
	main.handle_app_focus_out()
	main._process(0.2)
	_check(_frames(main.battle_log)==retained,"background SCOUT adds no clock or frame")
	main.handle_app_focus_in()
	main._process(0.05)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	var boundary: Dictionary=main._snapshot_data().duplicate(true)
	main.raid_force_alarm()
	var source: BattleLog=main.battle_log
	_check(source.attempt_id==attempt and not attempt.is_empty(),"first original alarm retains the SCOUT attempt identity")
	_check(int(source.playback_schema)==2,"complete production recording declares playback schema2")
	_check(source.events.front().seq==0 and BattleLog.record_tick(source.events.front())==0,"first alarm keeps original domain event sequence and battle tick zero")
	var partial: Array=_frames(source).filter(func(record: Dictionary) -> bool: return int(record.data.phase)==main.Phase.SETUP and is_equal_approx(float(record.data.pose_clock_s),float(boundary.pose_clock_s)))
	_check(not partial.is_empty() and partial.back().data.ops==boundary.ops,"alarm saves the real unsampled final SCOUT command boundary")
	var alarm: Dictionary=source.snapshots.front()
	_check(not partial.is_empty() and int(alarm.get("playback_tick",0))>int(partial.back().get("playback_tick",0)),"SCOUT boundary and first alarm have independently seekable presentation ticks")
	for i in 13: main._sim_tick()
	retained=_frames(source).duplicate(true)
	main._on_replay_pressed()
	_check(main.phase==main.Phase.REPLAY,"normal production REPLAY opens the retained full attempt")
	main._pose_command_clock_s+=123.0
	main._night_timer+=123.0
	main.run_id+=100
	main.operators[2].global_position+=Vector2(2000,2000)
	var poisoned: Dictionary=main._snapshot_data().duplicate(true)
	var actual_seeks := 0
	for index in [0,1,2,3,4,5,6,7,6,5,4,3,2,1,0,7]:
		var checkpoint: Dictionary=scout_samples[index]
		if checkpoint.record.is_empty(): continue
		actual_seeks+=1
		main.replay.set_tick(int(checkpoint.record.playback_tick))
		main._apply_replay_scrub()
		view.refresh()
		var frame: Dictionary=ViewState.capture(main)
		_check(frame.recorded_phase==main.Phase.SETUP and frame.attempt_id==attempt and frame.wave_id==0,"back/forward resolves original SCOUT phase and attempt")
		_check(frame.ops[2].pos==checkpoint.position and _bones(view.actors["ops:3"].get_node("Body") as Actor)==checkpoint.bones,"SCOUT replay reproduces copied actual moving root and20 bones")
		_check(frame.events.is_empty(),"SCOUT history cannot reveal future alarm or battle events")
		_check(_frames(source)==retained and main._snapshot_data()==poisoned,"SCOUT seek preserves full recording and poisoned live state")
	await _capture_record(main,"full_scout_history_0800")
	rows.append({"stage":"scout_prelude","actual_samples":scout_samples.filter(func(item: Dictionary) -> bool: return not item.record.is_empty()).size(),"seek_checks":actual_seeks,"alarm_playback_tick":alarm.get("playback_tick",0),"boundary_clock":boundary.pose_clock_s,"attempt_survives_alarm":source.attempt_id==attempt})
	# This inherited production journey also checks all actual SWEEP samples,
	# original WON/FAILED/abort terminals, copied bones, pause, fallback and seeks.
	await super._run()
