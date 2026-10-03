extends SceneTree

## M1-F: compare immediate fire with hold-for-ambush through the real yard,
## crate search, alert transition, enemy movement, and authoritative sim ticks.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const WeaponCatalogScript := preload("res://scripts/raid/weapon_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		_fail("M1_F_LOAD_MAIN")
		return
	await _frames(14)
	var main = current_scene
	if main == null or main.level == null or str(main.level.level_id) != "yard":
		_fail("M1_F_NOT_REAL_YARD")
		return
	main.set_process(false)
	if main.operators.size() < 3:
		_fail("M1_F_FIXTURE_SHORT operators=%d" % main.operators.size())
		return
	for index in main.operators.size():
		var unit = main.operators[index]
		unit.set_process(false)
		unit.visible = index == 0
	
	var immediate: Dictionary = await _run_trial(main, OperatorUnit.FireMode.ENGAGE_ON_SIGHT, "IMMEDIATE", "")
	if immediate.is_empty():
		_finish_failed()
		return
	_expect(not bool(immediate.get("armed", false)), "M1_F_IMMEDIATE_NO_AMBUSH_ARMED")
	_expect(not bool(main.level.ambush_zone.has_point(immediate.get("fire_position", Vector2.INF))), "M1_F_IMMEDIATE_FIRES_OUTSIDE_ZONE")
	_expect(int(immediate.get("fire_count", 0)) == 1, "M1_F_IMMEDIATE_ONE_AUTHORITATIVE_FIRE")
	if not failures.is_empty():
		_finish_failed()
		return

	# Reset through the actual abort -> continue path, then reacquire the same
	# authored rifle crate. This guarantees both trials start from equal inventory.
	main._on_abort_pressed()
	_expect(int(main.phase) == int(main.Phase.FAILED), "M1_F_REAL_ABORT_BETWEEN_TRIALS")
	main._on_continue_pressed()
	await _frames(3)
	_expect(int(main.phase) == int(main.Phase.SETUP), "M1_F_REAL_CONTINUE_RESETS_SETUP")
	_expect(_squad_inventory_empty(main), "M1_F_RETRY_RESETS_INVENTORY")
	if not failures.is_empty():
		_finish_failed()
		return

	var hold: Dictionary = await _run_trial(
		main,
		OperatorUnit.FireMode.HOLD_FOR_AMBUSH,
		"HOLD",
		str(immediate.get("weapon_id", ""))
	)
	if hold.is_empty():
		_finish_failed()
		return
	_expect(bool(hold.get("armed", false)), "M1_F_HOLD_HAS_AUTHORITATIVE_ARM_EVENT")
	_expect(int(hold.get("fire_count", 0)) == 1, "M1_F_HOLD_ONE_AUTHORITATIVE_FIRE")
	_expect(int(hold.get("armed_tick", -1)) == int(hold.get("fire_tick", -2)), "M1_F_ARMED_BEFORE_FIRE_SAME_TICK")
	_expect(int(hold.get("armed_seq", 999999)) < int(hold.get("fire_seq", -1)), "M1_F_ARMED_EVENT_PRECEDES_FIRE_EVENT")
	_expect(bool(main.level.ambush_zone.has_point(hold.get("fire_position", Vector2.INF))), "M1_F_HOLD_FIRES_INSIDE_ZONE")
	_expect(int(hold.get("ammo_spent", 0)) == 1, "M1_F_HOLD_SPENDS_ONE_ROUND_AFTER_ARM")
	_expect(is_equal_approx(float(hold.get("damage", -1.0)), float(immediate.get("damage", -2.0))), "M1_F_DAMAGE_UNCHANGED_BETWEEN_MODES")
	_expect(str(hold.get("weapon_id", "")) == str(immediate.get("weapon_id", "!")), "M1_F_SAME_ACQUIRED_WEAPON")
	_expect(is_equal_approx(float(hold.get("range", -1.0)), float(immediate.get("range", -2.0))), "M1_F_RANGE_UNCHANGED_BETWEEN_MODES")
	_expect(int(hold.get("fire_tick", -1)) > int(immediate.get("fire_tick", 999999)), "M1_F_HOLD_FIRST_SHOT_IS_LATER")
	_expect(int(hold.get("start_ammo", -1)) == int(immediate.get("start_ammo", -2)), "M1_F_SAME_STARTING_AMMO")
	_expect(is_equal_approx(float(hold.get("start_hp", -1.0)), float(immediate.get("start_hp", -2.0))), "M1_F_SAME_TARGET_STARTING_HP")
	_expect(int(hold.get("actor_id", -1)) == int(immediate.get("actor_id", -2)), "M1_F_SAME_OPERATOR")
	_expect(int(hold.get("target_id", -1)) == int(immediate.get("target_id", -2)), "M1_F_SAME_TARGET")
	_expect((hold.get("operator_position", Vector2.INF) as Vector2).is_equal_approx(immediate.get("operator_position", Vector2.ZERO) as Vector2), "M1_F_SAME_OPERATOR_POSITION")
	_expect(is_equal_approx(float(hold.get("facing", -1.0)), float(immediate.get("facing", -2.0))), "M1_F_SAME_OPERATOR_FACING")
	_expect((hold.get("route_start", Vector2.INF) as Vector2).is_equal_approx(immediate.get("route_start", Vector2.ZERO) as Vector2), "M1_F_SAME_ENEMY_ROUTE_START")
	_expect((hold.get("route_end", Vector2.INF) as Vector2).is_equal_approx(immediate.get("route_end", Vector2.ZERO) as Vector2), "M1_F_SAME_ENEMY_ROUTE_END")

	if not failures.is_empty():
		_finish_failed()
		return
	print("M1_YARD_TIMING_CAUSALITY_OK real_crate=1 same_weapon=1 same_geometry=1 outside_immediate=1 hold_waits=1 armed_before_fire=1 equal_damage=1 equal_range=1 real_retry=1")
	quit(0)


func _run_trial(main, mode: int, label: String, expected_weapon_id: String) -> Dictionary:
	var op = main.operators[0]
	var stash = _find_rifle_stash(main)
	if stash == null:
		_fail("M1_F_%s_REAL_RIFLE_STASH_MISSING" % label)
		return {}
	var stash_instance_id: int = stash.get_instance_id()
	op.stop_move()
	op.global_position = stash.global_position
	main.selected = op
	main._try_pickup_near_selected()
	if not op.is_searching() or op.search_stash != stash:
		_fail("M1_F_%s_REAL_CRATE_SEARCH_NOT_STARTED" % label)
		return {}
	main.raid_advance_search(0.8)
	await process_frame
	if WeaponCatalogScript.family_of(str(op.weapon_id)) != WeaponCatalogScript.family_of("rifle") or is_instance_id_valid(stash_instance_id):
		_fail("M1_F_%s_REAL_RIFLE_PICKUP_FAILED weapon=%s stash_still_valid=%s" % [label, str(is_instance_id_valid(stash_instance_id))])
		return {}
	if expected_weapon_id != "" and str(op.weapon_id) != expected_weapon_id:
		_fail("M1_F_RETRY_WEAPON_MISMATCH expected=%s actual=%s" % [expected_weapon_id, str(op.weapon_id)])
		return {}
	var weapon_id := str(op.weapon_id)
	var damage := float(op.damage_per_shot)
	var range_px := float(op.range_px)
	var initial_ammo := int(op.ammo)
	_expect(initial_ammo > 0, "M1_F_%s_HAS_ACQUIRED_AMMO" % label)
	
	var outside_cell := Vector2i(9, 12)
	var inside_cell := Vector2i(10, 12)
	var outside_pos: Vector2 = main.grid.cell_to_world_center(outside_cell)
	var inside_pos: Vector2 = main.grid.cell_to_world_center(inside_cell)
	op.global_position = main.grid.cell_to_world_center(Vector2i(6, 12))
	op.set_facing(0.0)
	op.set_fire_mode(mode)
	_expect(not main.level.ambush_zone.has_point(outside_pos), "M1_F_%s_OUTSIDE_POINT_IS_OUTSIDE_ZONE" % label)
	_expect(main.level.ambush_zone.has_point(inside_pos), "M1_F_%s_INSIDE_POINT_IS_IN_ZONE" % label)
	_expect(op.in_fire_geometry(outside_pos, main.grid) and op.in_fire_geometry(inside_pos, main.grid), "M1_F_%s_REAL_YARD_POINTS_ARE_IN_FIRE_GEOMETRY" % label)
	if failures.size() > 0:
		return {}

	main.raid_force_alarm()
	_expect(int(main.phase) == int(main.Phase.WATCHING), "M1_F_%s_REAL_ALARM_TRANSITION" % label)
	main.pending_spawns.clear()
	var enemy_id := 981
	var enemy = main._make_enemy(enemy_id)
	main.entities.add_child(enemy)
	var route := PackedVector2Array([outside_pos, inside_pos])
	enemy.setup(enemy_id, route, main.grid, 0, "m1_f_timing")
	enemy.global_position = outside_pos
	enemy.route_index = 1
	enemy.active = true
	enemy.alerted = true
	enemy.return_cd = 999.0
	enemy.set_process(false)
	main.enemies.append(enemy)
	op.shot_cd = 0.0
	_expect(op.locked, "M1_F_%s_ALARM_LOCKS_SELECTED_PLAN" % label)
	_expect(op.fire_permitted == (mode == OperatorUnit.FireMode.ENGAGE_ON_SIGHT), "M1_F_%s_SELECTED_FIRE_MODE_IS_AUTHORITATIVE" % label)
	main.battle_log.clear()
	var start_ammo := int(op.ammo)
	var start_hp := float(enemy.hp)
	var operator_position: Vector2 = op.global_position
	var operator_facing := float(op.facing_deg)
	var saw_armed := false
	var no_side_effects_before_arm := true
	var first_fire: Dictionary = {}
	for _tick in 80:
		var old_hp := float(enemy.hp)
		var old_ammo := int(op.ammo)
		main._sim_tick()
		var armed_now: Dictionary = main.battle_log.first_of_type("ambush_armed")
		saw_armed = not armed_now.is_empty()
		first_fire = main.battle_log.first_of_type("fire")
		if first_fire.is_empty() and not saw_armed:
			if int(op.ammo) != old_ammo or not is_equal_approx(float(enemy.hp), old_hp):
				no_side_effects_before_arm = false
		if not first_fire.is_empty():
			break
	if first_fire.is_empty():
		print("M1_F_DEBUG mode=%d phase=%d sim_tick=%d enemy_count=%d active=%s alive=%s route_index=%d pos=%s zone=%s permitted=%s events=%s" % [mode, int(main.phase), int(main.sim.tick), main.enemies.size(), str(enemy.active), str(enemy.alive), enemy.route_index, str(enemy.global_position), str(main.level.ambush_zone.has_point(enemy.global_position)), str(op.fire_permitted), JSON.stringify(main.battle_log.events)])
		_fail("M1_F_%s_NO_FIRE_WITHIN_ROUTE" % label)
		return {}
	if mode == OperatorUnit.FireMode.HOLD_FOR_AMBUSH:
		_expect(no_side_effects_before_arm, "M1_F_HOLD_NO_SHOT_OR_SIDE_EFFECT_BEFORE_ARM")
	var armed_event: Dictionary = main.battle_log.first_of_type("ambush_armed")
	var all_fire_count := _count_type(main.battle_log.events, "fire")
	var fire_pos: Vector2 = enemy.global_position
	var hp_after := float(enemy.hp)
	var result := {
		"weapon_id": weapon_id,
		"range": range_px,
		"damage": start_hp - hp_after,
		"start_ammo": start_ammo,
		"start_hp": start_hp,
		"actor_id": int(first_fire.get("actor_id", -1)),
		"target_id": int(first_fire.get("target_id", -1)),
		"operator_position": operator_position,
		"facing": operator_facing,
		"route_start": outside_pos,
		"route_end": inside_pos,
		"fire_count": all_fire_count,
		"fire_tick": int(first_fire.get("tick", -1)),
		"fire_seq": int(first_fire.get("seq", -1)),
		"fire_position": fire_pos,
		"armed": not armed_event.is_empty(),
		"armed_tick": int(armed_event.get("tick", -1)),
		"armed_seq": int(armed_event.get("seq", 999999)),
		"ammo_spent": start_ammo - int(op.ammo),
		"ammo_after": int(op.ammo),
	}
	_expect(int(first_fire.get("actor_id", -1)) == int(op.op_id), "M1_F_%s_FIRE_ACTOR_MATCHES" % label)
	_expect(int(first_fire.get("target_id", -1)) == enemy_id, "M1_F_%s_FIRE_TARGET_MATCHES" % label)
	_expect(int(op.ammo) == start_ammo - 1, "M1_F_%s_ONE_ROUND_SPENT" % label)
	_expect(is_equal_approx(float(enemy.hp), start_hp - damage), "M1_F_%s_DAMAGE_MEASURED" % label)
	_expect(is_equal_approx(damage, float(op.damage_per_shot)), "M1_F_%s_ONE_SHOT_DAMAGE_MATCHES_WEAPON" % label)
	return result


func _find_rifle_stash(main):
	var wanted_family := WeaponCatalogScript.family_of("rifle")
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var kind := str(stash.kind)
		if kind == "rifle" or WeaponCatalogScript.family_of(kind) == wanted_family:
			return stash
	return null


func _squad_inventory_empty(main) -> bool:
	for op in main.operators:
		if str(op.weapon_id) != "knife" or int(op.ammo) != 0 or int(op.pack.occupied()) != 0:
			return false
		if int(op.grenades) != 0 or int(op.mines) != 0 or int(op.decoys) != 0 or not op.ammo_pool.is_empty():
			return false
	return true


func _count_type(events: Array, wanted: String) -> int:
	var count := 0
	for event in events:
		if str(event.get("type", "")) == wanted:
			count += 1
	return count


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _expect(ok: bool, marker: String) -> void:
	if not ok:
		_fail(marker)
	else:
		print(marker)


func _fail(marker: String) -> void:
	failures.append(marker)
	push_error(marker)


func _finish_failed() -> void:
	for failure in failures:
		push_error(failure)
	print("M1_YARD_TIMING_CAUSALITY_FAILED count=%d" % failures.size())
	quit(2)
