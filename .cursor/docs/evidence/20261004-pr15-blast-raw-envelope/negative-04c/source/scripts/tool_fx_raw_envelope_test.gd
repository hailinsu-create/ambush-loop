extends "res://scripts/tool_fx_source_test.gd"
## Actual empty blast; explicit legal one-frame record and single raw type edits.
const ToolReader := preload("res://scripts/presentation/tool_fx_frame.gd")
const LEGACY_SHA := "1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12"
var original: BattleLog
var directory := ""


func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;print("TOOL_FX_RAW_ENVELOPE_FAIL "+message)


func _log_bytes(source: BattleLog) -> PackedByteArray:
	return var_to_bytes([source.attempt_id,source.wave_id,source.events,source.snapshots,source.playback_snapshots,
		source.terminal_tick,source.terminal_reason,source.playback_schema,source.playback_terminal_tick,source.current_playback_tick()])


func _backend() -> PackedByteArray:
	return var_to_bytes([main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum,
		main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades,op.mines]),
		main.enemies.map(func(enemy:EnemyRunner)->Array:return [enemy.global_position,enemy.hp,enemy.alive]),_log_bytes(original)])


func _record(snapshot: Dictionary) -> BattleLog:
	var source:=BattleLog.new()
	source.begin_attempt(original.attempt_id)
	source.enable_continuous_playback(2)
	source.wave_id=original.wave_id
	source.events=original.events.duplicate(true)
	source.playback_snapshots=[snapshot]
	source.playback_terminal_tick=249 # Explicit fixture tail, not a real terminal.
	return source


func _consume(source: BattleLog, tick: int) -> Dictionary:
	main.replay.bind(source)
	main.replay.set_tick(tick)
	main.replay.pause()
	var frame:=ViewState.capture(main)
	main.presentation_3d.tool_fx.update_frame(frame,false)
	return {"frame":frame,"reader":ToolReader.active(frame),"pool":main.presentation_3d.tool_fx.diagnostics().active,
		"continuous":main.replay.continuous_playback,"unsupported":main.replay.playback_unsupported}


func _body(frame: Dictionary) -> PackedByteArray:
	return var_to_bytes([frame.ops,frame.enemies,frame.blocked,frame.selected_id,frame.recorded_phase,frame.wave_count,
		frame.visual_schema,frame.hud_schema,frame.wave_id,frame.frame_seq])


func _save_snapshot(label: String, snapshot: Dictionary) -> void:
	var file:=FileAccess.open(directory+"/"+label+".bin",FileAccess.WRITE)
	file.store_buffer(var_to_bytes(snapshot));file.close()


func _run() -> void:
	root.get_node("GameSettings").pending_level_id="yard"
	root.get_node("GameSettings").mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene;main.set_process(false);main.presentation_3d.set_process(false)
	directory="res://build/asset_review/pr15-runtime/tool-fx-raw-envelope-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var pair:Array=await _reset()
	var owner:OperatorUnit=pair[0]
	pair[1].global_position=Vector2(960,576)
	for op:OperatorUnit in main.operators:
		if op!=owner:op.global_position=Vector2(1024,640)
	var event_count:int=main.battle_log.events.size()
	var grenade:=_throw(owner,owner.global_position+Vector2(0,160))
	await _blast([grenade])
	var effects:=_effects()
	_check(grenade.spent() and effects.size()==1 and effects.front().victims.is_empty() and main.battle_log.events.size()==event_count and owner.hp==100.0 and pair[1].hp==100.0,"actual original empty fuse blast preserved HP/events")
	if effects.is_empty():_finish();return
	original=main.battle_log
	original.add_command_snapshot(main.sim.tick,main._snapshot_data())
	var actual:Dictionary=original.playback_snapshots.back().duplicate(true)
	_save_snapshot("actual-original-snapshot",actual)
	_check(effects.front().clock_tick==49 and effects.front().local_tick==48 and actual.playback_tick==49 and actual.data.phase==1 and actual.data.wave_count==2,"actual original confirmation49/local48 and recorded ALERT/two waves retained")
	var raw:Dictionary=actual.duplicate(true);raw.frame_seq=0 # Only control normalization.
	var backend_before:=_backend()
	var original_before:=_log_bytes(original)
	main.phase=main.Phase.REPLAY # Explicit consumer fixture; no normal input claim.
	var legal:=_record(raw.duplicate(true))
	var legal_before:=_log_bytes(legal)
	var control:=_consume(legal,49)
	_check(control.continuous and not control.unsupported and control.frame.tool_fx_schema==1 and control.reader.size()==1 and control.pool.size()==1,"actual PB2 legal one-frame control presents one original confirmed blast")
	_check(_log_bytes(legal)==legal_before and _log_bytes(original)==original_before,"legal transport/reader/pool preserve original and control bytes")
	_save_snapshot("legal-control-snapshot",raw)
	rows.append({"case":"legal-control","actual_original_snapshot_frame_seq":actual.frame_seq,"control_frame_seq":raw.frame_seq,"control":control})
	var body:=_body(control.frame)
	for field:Array in [["snapshot","schema"],["snapshot","playback_schema"],["snapshot","wave_id"],["snapshot","frame_seq"],["data","phase"],["data","wave_count"]]:
		var candidate:Dictionary=raw.duplicate(true)
		var target:Dictionary=candidate if field[0]=="snapshot" else candidate.data
		var value:Variant=target[field[1]]
		target[field[1]]=float(value)
		var copy:=_record(candidate)
		var before:=_log_bytes(copy)
		var result:=_consume(copy,49)
		_check(result.continuous and not result.unsupported and result.frame.tool_fx_schema==0 and result.reader.is_empty() and result.pool.is_empty() and _body(result.frame)==body,"single raw float "+str(field)+" neutral adjunct while original actor/world/HUD casts preserved")
		_check(typeof(value)==TYPE_INT and typeof(target[field[1]])==TYPE_FLOAT and _log_bytes(copy)==before and _log_bytes(original)==original_before,"raw/control/original byte identity and exact int-to-float edit "+str(field))
		_save_snapshot("float-"+field[0]+"-"+field[1],candidate)
		rows.append({"case":field,"raw_before":value,"raw_after":target[field[1]],"result":result,"source_read_only":_log_bytes(copy)==before})
	_check(_backend()==backend_before,"all six direct consumer/reader/pool probes keep actual original backend/inventory/events")
	var path:=OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE")
	_check(FileAccess.get_sha256(path)==LEGACY_SHA,"authentic old schema1 record present with exact original hash")
	if FileAccess.get_sha256(path)==LEGACY_SHA:
		var record:Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(path))
		var legacy:=BattleLog.new()
		for key:String in record:legacy.set(key,record[key])
		var before:=_log_bytes(legacy)
		var fallback:=_consume(legacy,0)
		_check(fallback.frame.tool_fx_schema==0 and fallback.reader.is_empty() and fallback.pool.is_empty() and not fallback.frame.ops.is_empty() and fallback.frame.blocked.size()==880,"actual old schema retains original actor/world fallback with neutral tool adjunct")
		_check(_log_bytes(legacy)==before and FileAccess.get_sha256(path)==LEGACY_SHA,"old source memory/file never upgraded or replaced")
		rows.append({"case":"actual-old-schema1","frame":fallback.frame,"original_hash":LEGACY_SHA})
	_finish()


func _finish() -> void:
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,
		"scope":"actual original empty blast, explicit grants/positions/backend clocks and one-frame/corrupt copies; no normal malformed-writer/UI route/render/performance/FINAL/device acceptance"},"  "))
	file.close()
	root.get_node("AudioDirector").pause_for_background()
	print("TOOL_FX_RAW_ENVELOPE_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
