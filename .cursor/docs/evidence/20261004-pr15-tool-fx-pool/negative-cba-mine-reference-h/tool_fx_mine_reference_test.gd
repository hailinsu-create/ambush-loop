extends "res://scripts/tool_fx_source_test.gd"
## One actual original mine plus explicit duplicated saved-reference fixture.
const Reader := preload("res://scripts/presentation/tool_fx_frame.gd")

func _state(log: BattleLog) -> PackedByteArray:
	return var_to_bytes([log.events,log.snapshots,log.playback_snapshots,log.attempt_id,log.wave_id,log.wave_offset,log.terminal_tick,log.terminal_reason,log.playback_schema,log.playback_terminal_tick,log.current_playback_tick()])

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
	var pair: Array=await _reset()
	var op: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	op.receive_item("mine",1)
	main._select_op(0)
	var inventory:=op.mines
	var events: int=main.battle_log.events.size()
	main._try_place_inventory_mine(enemy.global_position)
	main._tick_raid_mines()
	var frame:=ViewState.capture(main)
	var legal: Array=Reader.active(frame)
	_check(enemy.hp==-20.0 and not enemy.alive and op.mines==inventory-1 and main.battle_log.events.size()==events+2 and main.battle_log.events.back().type=="mine" and legal.size()==1,"actual original mine/120HP delta/inventory/kill+mine event and legal saved reference accepted")
	var original:=_state(main.battle_log)
	var frame_bytes:=var_to_bytes(frame)
	var actual_backend:=var_to_bytes([enemy.hp,op.hp,op.ammo,op.mines,main.sim.tick,main.sim.paused])
	var corrupt:=frame.duplicate(true)
	var second: Dictionary=corrupt.tool_fx.front().duplicate(true)
	second.seq+=1
	second.effect_id=frame.attempt_id+":tool_fx:"+str(second.seq)
	second.tool_id=frame.attempt_id+":tool:1"
	corrupt.tool_fx.append(second)
	var corrupt_bytes:=var_to_bytes(corrupt)
	var result: Array=Reader.active(corrupt)
	_check(result.is_empty(),"two distinct saved tool/effect identities referencing one actual mine event are neutral")
	_check(_state(main.battle_log)==original and var_to_bytes(frame)==frame_bytes and var_to_bytes(corrupt)==corrupt_bytes and var_to_bytes([enemy.hp,op.hp,op.ammo,op.mines,main.sim.tick,main.sim.paused])==actual_backend,"rejection/read only does not change original or corrupt bytes/sim/HP/inventory")
	root.get_node("AudioDirector").pause_for_background()
	var directory: String="res://build/asset_review/pr15-runtime/tool-fx-mine-reference-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"actual_mine_event":main.battle_log.events.back(),"legal":legal,"corrupt_saved":corrupt.tool_fx,"corrupt_return_count":result.size(),"scope":"actual original mine with inventory grant/placement/directtick, then explicit cloned corrupt saved reference; normal writer/UI duplicate path not demonstrated; no render/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("TOOL_FX_MINE_REFERENCE_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
