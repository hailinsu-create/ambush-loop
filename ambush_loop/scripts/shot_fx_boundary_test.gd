extends SceneTree
## Explicit original backend fixtures; no normal/player or rendered claim.
const Guard := preload("res://scripts/test_storage_guard.gd")
const Weapons := preload("res://scripts/raid/weapon_catalog.gd")
var main: Node
var checks := 0
var failures := 0
var rows := []

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("SHOT_FX_BOUNDARY_FAIL " + message)

func _reset(role: int = 0) -> Array:
	main._load_level("yard", false, false)
	await process_frame
	main.presentation_3d.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0], {"grenades": 0, "mines": 0})
	main.raid_force_alarm()
	main._spawn_one(main.pending_spawns[0])
	var op: OperatorUnit = main.operators[role]
	var enemy: EnemyRunner = main.enemies.back()
	op.slot = null
	op.global_position = main.grid.cell_to_world_center(Vector2i(2, 2))
	op.set_facing(90.0)
	op.fire_permitted = true
	op.shot_cd = 0.0
	op.auto_grenade = false
	enemy.global_position = op.global_position + Vector2(0, 32)
	main.all_spawns_done = false
	return [op, enemy]

func _event(op: OperatorUnit, enemy: EnemyRunner) -> Dictionary:
	# Explicit PRE-try event seam, same original payload as the sim caller.
	main.battle_log.add_event(main.sim.tick, "fire", op.op_id, enemy.label_id, op.global_position,
		{"animation_schema": 2, "visual_weapon": Weapons.resolve_crate_kind(op.weapon_id, "yard", op.op_id),
		"weapon": op.weapon_id, "shot_interval_s": op.shot_interval, "reload_s": op.reload_s})
	return main.battle_log.events.back()

func _fire_cases() -> void:
	for label in ["ordinary", "last-pack", "last-pistol", "lethal", "knife"]:
		var pair: Array = await _reset()
		var op: OperatorUnit = pair[0]
		var enemy: EnemyRunner = pair[1]
		op.apply_weapon("knife" if label == "knife" else "kar98k", true)
		op.ammo = 1 if label in ["last-pack", "last-pistol"] else 3
		op.ammo_pool["rifle"] = op.ammo
		op.has_ammo_pack = label == "last-pack"
		op.ammo_pack_used = false
		op.ammo_pool["pistol"] = 3 if label == "last-pistol" else 0
		if label == "lethal": enemy.hp = 10.0
		var hp_before := enemy.hp
		var ammo_before := op.ammo
		var tick_before: int = main.sim.tick
		var event := _event(op, enemy)
		var original: Dictionary = event.duplicate(true)
		var fired: bool = main._try_fire_with_recorded_fx(op, enemy, event)
		var fx: Dictionary = event.payload.get("fx", {})
		_check(fired and not fx.is_empty(), label+" original backend fired and source descriptor recorded")
		if fx.is_empty(): continue
		_check(fx.visual_weapon == original.payload.visual_weapon and fx.source_pos == original.position, label+" keeps original gun and origin")
		_check(is_equal_approx(float(fx.hp_before), hp_before) and is_equal_approx(float(fx.hp_after), enemy.hp) and is_equal_approx(float(fx.damage), hp_before-enemy.hp), label+" exact actual HP before/after/delta")
		_check(main.sim.tick == tick_before, label+" metadata does not advance sim")
		var stripped: Dictionary = event.duplicate(true)
		stripped.payload.erase("fx")
		_check(stripped == original, label+" every original event field/payload retained")
		if label == "last-pack":
			_check(op.weapon_id == "kar98k" and op.ammo_pack_used and op.ammo == op.start_ammo, "actual original same-gun pack refilled")
		elif label == "last-pistol":
			_check(op.weapon_id == "pistol" and op.ammo == 3 and fx.visual_weapon == "kar98k", "actual automatic pistol keeps fired rifle descriptor")
		elif label == "knife":
			_check(not fx.projectile and fx.visual_weapon == "knife", "real knife success cannot become firearm FX")
		elif label == "lethal":
			_check(not enemy.alive and enemy.hp < 0.0 and is_equal_approx(fx.damage, op.damage_per_shot), "lethal actual HP delta retains overkill, not clamp or nominal substitution")
		else:
			_check(op.ammo == ammo_before-1, "ordinary original ammo decrement preserved")
		rows.append({"case":label,"event":event.duplicate(true),"current_weapon":op.weapon_id,"current_ammo":op.ammo,"target_hp":enemy.hp})

func _false_and_scope_cases() -> void:
	var pair: Array = await _reset()
	var op: OperatorUnit = pair[0]
	var enemy: EnemyRunner = pair[1]
	op.fire_permitted = false
	var event := _event(op, enemy)
	var preserved := var_to_bytes(main.battle_log.events)
	var state := [op.ammo, op.shot_cd, enemy.hp]
	_check(not main._try_fire_with_recorded_fx(op, enemy, event), "explicit pre-log false original try_fire returns false")
	_check(not event.payload.has("fx") and var_to_bytes(main.battle_log.events) == preserved and [op.ammo, op.shot_cd, enemy.hp] == state, "false try produces no success/impact and changes no backend or event")
	main._on_op_fired_shot(op, enemy.global_position) # Explicit stray callback fixture.
	_check(not event.payload.has("fx") and var_to_bytes(main.battle_log.events) == preserved, "callback after cleared context cannot annotate last event")
	for label in ["old-wave", "foreign-log"]:
		pair = await _reset()
		op = pair[0]
		enemy = pair[1]
		event = _event(op, enemy)
		var origin: BattleLog = main.battle_log
		var original := var_to_bytes(event)
		main.shot_fx_recording.begin(main, op, enemy, "ops", event)
		if label == "old-wave": origin.begin_wave(origin.wave_id+1)
		else:
			var foreign := BattleLog.new()
			foreign.begin_attempt("foreign-shot-boundary")
			foreign.enable_continuous_playback(2)
			main.battle_log = foreign
		_check(op.try_fire(enemy, main.grid), label+" actual original success callback reached")
		main.shot_fx_recording.finish()
		_check(var_to_bytes(event) == original and not event.payload.has("fx"), label+" refuses source change without rebinding old identity")

func _return_cases() -> void:
	for label in ["cooldown", "mg-exposed", "cover"]:
		var pair: Array = await _reset(1 if label == "mg-exposed" else 0)
		var op: OperatorUnit = pair[0]
		var enemy: EnemyRunner = pair[1]
		if label == "cover":
			op.slot = main.cover_slots[1]
			op.global_position = op.slot.global_position
			var angle := deg_to_rad(op.slot.protect_facing_deg)
			enemy.global_position = op.global_position+Vector2(cos(angle), sin(angle))*32.0
			_check(op.slot.protects_from(enemy.global_position) and main.grid.has_los(op.global_position, enemy.global_position), "actual authored cover protection/LOS fixture reached")
		enemy.focus_target = op
		enemy.alerted = true
		enemy.return_cd = 0.1 if label == "cooldown" else 0.0
		var hp_before := op.hp
		var count_before: int = main.battle_log.events.size()
		main._resolve_return_with_recorded_fx(enemy)
		if label == "cooldown":
			_check(enemy.returning_fire and main.battle_log.events.size() == count_before and op.hp == hp_before, "cooldown aiming state cannot generate shot or damage descriptor")
			continue
		var event: Dictionary = main.battle_log.events.back()
		var fx: Dictionary = event.payload.get("fx", {})
		_check(event.type == "return_fire" and not fx.is_empty(), label+" actual return signal logged once and confirmed")
		if fx.is_empty(): continue
		_check(is_equal_approx(float(fx.damage), hp_before-op.hp) and not is_equal_approx(float(fx.damage), EnemyRunner.RETURN_DAMAGE), label+" uses actual modified HP delta, not nominal return damage")
		_check(fx.source_group == "enemies" and fx.target_group == "ops" and fx.source_id == enemy.label_id and fx.target_id == op.op_id, label+" actual shooter/victim groups preserved")
		rows.append({"case":label,"event":event.duplicate(true),"actual_target_hp":op.hp})

func _run() -> void:
	var settings = root.get_node("GameSettings")
	settings.pending_level_id = "yard"
	settings.mark_tutorial_seen("yard")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	await _fire_cases()
	await _false_and_scope_cases()
	await _return_cases()
	root.get_node("AudioDirector").pause_for_background()
	var directory := "res://build/asset_review/pr15-runtime/shot-fx-boundary-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(directory+"/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":rows,"scope":"Explicit original backend fixtures with reference resources/snap and direct APIs. No native normal or renderedFX/final/A3/device acceptance."}, "  "))
	file.close()
	print("SHOT_FX_BOUNDARY_TEST checks=%d failures=%d output=%s" % [checks, failures, directory])
	quit(0 if failures == 0 else 1)
