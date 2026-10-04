extends "res://scripts/movement_dust_test.gd"
## Actual saved SCOUT pose placed in explicit one-frame historical records.

func _record(data: Dictionary) -> BattleLog:
	var source:=BattleLog.new()
	source.begin_attempt(main.battle_log.attempt_id)
	source.enable_continuous_playback(2)
	source.add_command_snapshot(0,data)
	return source

func _sample(source: BattleLog) -> Dictionary:
	main.replay.bind(source)
	main.replay.set_tick(0)
	var frame:=ViewState.capture(main)
	pool.update_frame(frame,false)
	return {"frame":frame,"active":pool.diagnostics().active}

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
	main._select_op(0)
	var op:OperatorUnit=main.selected
	var position:=op.global_position
	main._command_move_selected(main.grid.cell_to_world_center(Vector2i(25,17)))
	for index in 20:main._process(1.0/60.0)
	var data:Dictionary=main._snapshot_data()
	var actual:=_state()
	pool=main.presentation_3d.get_node("MovementDust")
	main.phase=main.Phase.REPLAY # Explicit transport fixture, not normal input.
	var legal:=_record(data)
	var legal_bytes:=var_to_bytes(legal.playback_snapshots)
	var control:=_sample(legal)
	_check(op.global_position!=position and op.is_moving() and control.active.size()==1 and control.frame.movement_fx_schema==1,"actual original moving pose accepted through legal one-frame historical control")
	var bad_data:=data.duplicate(true)
	bad_data.phase=float(data.phase)
	var bad:=_record(bad_data)
	var bad_bytes:=var_to_bytes(bad.playback_snapshots)
	var result:=_sample(bad)
	_check(result.active.is_empty(),"explicit non-int raw saved phase is neutral before ViewState coerces it")
	_check(_state()==actual and var_to_bytes(legal.playback_snapshots)==legal_bytes and var_to_bytes(bad.playback_snapshots)==bad_bytes,"legal/corrupt historical controls keep original source and backend bytes")
	root.get_node("AudioDirector").pause_for_background()
	directory="res://build/asset_review/pr15-runtime/movement-dust-source-boundary-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"control":control,"corrupt_result":result,"scope":"actual original SCOUT move then explicit one-frame saved-phase corruption; normal writer/UI malformed phase not demonstrated; no render/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("MOVEMENT_DUST_SOURCE_BOUNDARY_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
