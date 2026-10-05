extends "res://scripts/shot_fx_boundary_test.gd"
## Actual original tool callbacks; grants/positions/direct ticks are explicit.
const ViewState := preload("res://scripts/presentation/view_state.gd")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("TOOL_FX_SOURCE_FAIL "+message)

func _effects() -> Array:
	var data: Dictionary=main._snapshot_data()
	return data.get("tool_fx",[])

func _blast(grenades: Array) -> void:
	for index in 180:
		main._tick_raid_grenades(1.0/60.0)
		if grenades.all(func(g: RaidGrenade) -> bool: return g.spent()): return
		main.sim.advance() # Explicit original backend clock fixture; no normal-player claim.
		main.battle_log.advance_simulation_playback()
	_check(false,"original tool fixture actually reaches real detonation")

func _throw(op: OperatorUnit, destination: Vector2) -> RaidGrenade:
	op.receive_item("grenade",1)
	var count_before:=op.grenades
	var event_count: int=main.battle_log.events.size()
	_check(main._throw_grenade_from(op,destination),"real original throw succeeded")
	_check(op.grenades==count_before-1 and main.battle_log.events.size()==event_count,"real throw consumes original inventory without BattleLog blast invention")
	return main.raid_grenades.back()

func _common(effect: Dictionary, kind: String, position: Vector2, owner_id: int) -> void:
	_check(effect.schema==1 and effect.confirmed and effect.kind==kind,"known actually confirmed source "+kind)
	_check(effect.level_id=="yard" and effect.attempt_id==main.battle_log.attempt_id and effect.wave_id==main.battle_log.wave_id,"actual source level/attempt/wave retained")
	_check(effect.clock_domain=="playback" and effect.playback_schema==2 and effect.clock_tick<=main.battle_log.current_playback_tick(),"actual original confirmation uses explicit continuous playback2 clock")
	_check(effect.position==position and effect.position.is_finite() and effect.radius>0.0,"actual blast position/radius preserved")
	_check(effect.owner_group=="ops" and effect.owner_id==owner_id and not str(effect.tool_id).is_empty() and not str(effect.effect_id).is_empty(),"creation owner and stable tool/effect identities retained")

func _empty_and_duplicate() -> void:
	var pair: Array=await _reset()
	var op: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	enemy.global_position=Vector2(960,576)
	for other: OperatorUnit in main.operators:
		if other!=op: other.global_position=Vector2(1024,640)
	var grenade:=_throw(op,op.global_position+Vector2(0,160))
	_check(_effects().is_empty(),"throw/flight is not actual blast confirmation")
	var count_before: int=main.battle_log.events.size()
	await _blast([grenade])
	_check(grenade.spent() and grenade.bounced and grenade.global_position==grenade.target,"real grenade fuse/bounce emitted actual final-position confirmation")
	_check(main.battle_log.events.size()==count_before and op.hp==100.0 and enemy.hp==100.0,"actual no-victim explosion keeps original event count/HP")
	var effects:=_effects()
	_check(effects.size()==1,"real no-victim blast saves one descriptor after object removal")
	if effects.is_empty(): return
	_common(effects.front(),"grenade",grenade.global_position,op.op_id)
	_check(effects.front().victims.is_empty() and effects.front().original_event.is_empty(),"actual empty blast has no invented victim or BattleLog event")
	var bytes_before:=var_to_bytes(effects)
	grenade.detonated.emit(grenade.global_position,grenade.radius,grenade.damage) # Explicit duplicate-signal fixture.
	_check(var_to_bytes(_effects())==bytes_before and main.battle_log.events.size()==count_before,"duplicate original signal does not repeat metadata identity")
	rows.append({"case":"actual-empty-and-explicit-duplicate","effect":effects.front(),"original_event_count":count_before,"scope":"real fuse/bounce then explicit duplicate signal; no native player route"})

func _damage() -> void:
	var pair: Array=await _reset(2)
	var owner: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	var cover: OperatorUnit=main.operators[0]
	var mg: OperatorUnit=main.operators[1]
	cover.slot=main.cover_slots[1]
	cover.global_position=cover.slot.global_position
	var angle:=deg_to_rad(cover.slot.protect_facing_deg)
	var blast_position:=cover.global_position+Vector2(cos(angle),sin(angle))*32.0
	owner.global_position=blast_position+Vector2(0,-100)
	enemy.global_position=blast_position
	enemy.hp=10.0
	mg.slot=null
	mg.global_position=blast_position
	_check(cover.slot.protects_from(blast_position),"actual authored cover protection fixture reached")
	var grenade:=_throw(owner,blast_position-Vector2(8,6))
	main._select_op(1) # Original damage attribution stays actual selected, distinct from creation owner.
	var count_before: int=main.battle_log.events.size()
	await _blast([grenade])
	_check(enemy.hp==-68.0 and not enemy.alive and is_equal_approx(cover.hp,89.08) and is_equal_approx(mg.hp,68.605),"original enemy overkill and actual cover/MG friendly HP modifiers retained")
	_check(main.battle_log.events.size()==count_before+1 and main.battle_log.events.back().type=="kill" and enemy.focus_target==mg,"original only kill event and selected damage attribution retained")
	var effects:=_effects()
	_check(effects.size()==1,"real damaging grenade records one confirmed source")
	if effects.is_empty(): return
	var effect: Dictionary=effects.front()
	_common(effect,"grenade",blast_position,owner.op_id)
	_check(effect.victims.size()==3,"actual three victims copied separately")
	for victim: Dictionary in effect.victims:
		var node: Node=enemy if victim.group=="enemies" else main.operators[int(victim.id)-1]
		var before: float=10.0 if victim.group=="enemies" else 100.0
		_check(victim.hp_before==before and is_equal_approx(float(victim.hp_after),node.hp) and is_equal_approx(float(victim.damage),before-node.hp),"actual individual HP delta/overkill copied "+str(victim.group)+str(victim.id))
	rows.append({"case":"actual-overkill-cover-mg-selected","effect":effect,"original_selected_id":mg.op_id,"original_event_count":main.battle_log.events.size()})

func _mine() -> void:
	var pair: Array=await _reset()
	var op: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	op.receive_item("mine",1)
	main._select_op(0)
	var before:=op.mines
	main._try_place_inventory_mine(enemy.global_position)
	_check(op.mines==before-1 and main.raid_mines.size()==1,"original inventory mine actually placed")
	_check(_effects().is_empty(),"mine placement/armed state cannot invent blast")
	var mine: RaidMine=main.raid_mines.back()
	var count_before: int=main.battle_log.events.size()
	main._tick_raid_mines()
	_check(mine.spent and not mine.armed and enemy.hp==-20.0 and not enemy.alive,"original real mine trigger/120 damage/overkill preserved")
	var event: Dictionary=main.battle_log.events.back()
	_check(main.battle_log.events.size()==count_before+2 and event.type=="mine" and event.actor_id==enemy.label_id and event.target_id==-1 and event.position==mine.global_position and event.payload.is_empty(),"original kill/mine count and victim actor/-1 target/payload kept")
	var effects:=_effects()
	_check(effects.size()==1,"real spent mine saves one descriptor after removal")
	if effects.is_empty(): return
	var effect: Dictionary=effects.front()
	_common(effect,"mine",mine.global_position,op.op_id)
	_check(effect.original_event.event_id==event.event_id and effect.original_event.seq==event.seq and effect.original_event.actor_id==enemy.label_id,"mine explicitly references actual victim event, distinct from owner")
	_check(effect.victims.size()==1 and effect.victims.front().group=="enemies" and effect.victims.front().id==enemy.label_id and effect.victims.front().damage==120.0,"mine actual victim HP delta120, no firearm muzzle fiction")
	var effect_bytes:=var_to_bytes(effects)
	main._tick_raid_mines()
	_check(var_to_bytes(_effects())==effect_bytes and main.battle_log.events.size()==count_before+2 and enemy.hp==-20.0,"spent mine cannot record twice or change original damage")
	rows.append({"case":"actual-mine","effect":effect,"original_event":event})

func _terminal() -> void:
	var pair: Array=await _reset()
	var owner: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	enemy.global_position=Vector2(960,576)
	for op: OperatorUnit in main.operators:
		op.slot=null
		op.global_position=Vector2(80,80)
		op.hp=1.0
	var grenade:=_throw(owner,Vector2(80,80))
	await _blast([grenade])
	_check(main.phase==main.Phase.FAILED and main.battle_log.terminal_reason=="wipe" and main.pending_result=="fail","actual grenade wipe synchronously marks terminal before final snapshot")
	main._finish_sim_tick()
	var data: Dictionary=main.battle_log.playback_snapshots.back().data
	var effects: Array=data.get("tool_fx",[])
	_check(effects.size()==1 and effects.front().victims.size()==3,"actual terminal snapshot retains completed blast and all three original HP deltas")
	if effects.is_empty(): return
	_check(effects.front().phase==main.Phase.WATCHING and effects.front().clock_tick<main.battle_log.playback_terminal_tick,"source confirmation retains original phase/clock across synchronous wipe boundary")
	rows.append({"case":"actual-terminal-wipe","effect":effects.front(),"terminal_playback_tick":main.battle_log.playback_terminal_tick,"snapshot_tick":main.battle_log.playback_snapshots.back().playback_tick})

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
	await _empty_and_duplicate()
	await _damage()
	await _mine()
	await _terminal()
	root.get_node("AudioDirector").pause_for_background()
	var directory: String="res://build/asset_review/pr15-runtime/tool-fx-source-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"scope":"real original tool callbacks/HP/inventory/stats with grants/positions/direct ticks and explicit duplicate signal; source-only, no native normal/blast render/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("TOOL_FX_SOURCE_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
