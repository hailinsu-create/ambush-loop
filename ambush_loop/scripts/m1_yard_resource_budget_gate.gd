extends SceneTree

## M1-E: prove real yard crate acquisition, optional-resource value, ammo
## depletion, and retry restocking through isolated game paths.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const WeaponCatalogScript := preload("res://scripts/raid/weapon_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		_fail("M1_E_LOAD_MAIN err=%d" % err)
		return
	await _frames(14)
	var main = current_scene
	if main == null or main.level == null or str(main.level.level_id) != "yard":
		_fail("M1_E_NOT_YARD")
		return
	main.set_process(false)
	for op in main.operators:
		op.set_process(false)
	if main.operators.size() < 3:
		_fail("M1_E_FIXTURE_SHORT operators=%d" % main.operators.size())
		return

	var initial_crates := _stash_signature(main)
	print("M1_E_INITIAL_CRATES %s" % initial_crates)
	_expect(not initial_crates.is_empty(), "M1_E_REAL_YARD_CRATES_SPAWNED")
	_expect(_stash_kinds_unique(main), "M1_E_NO_DUPLICATE_CRATE_KINDS")
	_expect(_squad_has_no_optional_resources(main), "M1_E_NO_DEFAULT_OPTIONAL_RESOURCES")
	if not _has_stash(main, "rifle") or not _has_stash(main, "grenade"):
		_fail("M1_E_CORE_OR_OPTIONAL_CRATE_MISSING")
		return

	# Baseline: acquire the actual role firearm through the crate search path;
	# no helper grants ammunition or throwables.
	var rifle_op = main.operators[0]
	if not await _pick_stash(main, rifle_op, "rifle"):
		return
	_expect(WeaponCatalogScript.family_of(str(rifle_op.weapon_id)) == WeaponCatalogScript.family_of("rifle"), "M1_E_CORE_FIREARM_EQUIPPED_FROM_CRATE")
	var ammo_before := int(rifle_op.ammo)
	_expect(ammo_before > 0 and int(rifle_op.ammo_pool.get("rifle", 0)) == ammo_before, "M1_E_CORE_AMMO_OWNED_AND_TRACKED")
	_expect(rifle_op.grenades == 0 and rifle_op.mines == 0, "M1_E_BASELINE_HAS_NO_THROWABLES")

	var fire_solution := _find_fire_solution(main, rifle_op)
	if fire_solution.is_empty():
		_fail("M1_E_NO_VALID_CORE_FIRE_GEOMETRY")
		return
	main.raid_force_alarm()
	_expect(int(main.phase) == int(main.Phase.WATCHING), "M1_E_CORE_PLAN_ACCEPTED_WITHOUT_OPTIONALS")
	var target_pos: Vector2 = fire_solution.get("point", Vector2.INF)
	var target = _spawn_test_enemy(main, 911, target_pos, 10000.0)
	if target == null:
		_fail("M1_E_CORE_TARGET_FIXTURE_MISSING")
		return
	var hp_before := float(target.hp)
	var fired_count := 0
	for _shot in ammo_before:
		rifle_op.shot_cd = 0.0
		if not rifle_op.try_fire(target, main.grid):
			break
		fired_count += 1
	_expect(fired_count == ammo_before, "M1_E_BASELINE_FIRES_ALL_ACQUIRED_ROUNDS")
	_expect(float(target.hp) < hp_before, "M1_E_BASELINE_HAS_AUTHORITATIVE_DAMAGE")
	_expect(int(rifle_op.ammo) == 0, "M1_E_LAST_ROUND_EXHAUSTS_MAGAZINE")
	_expect(str(rifle_op.engage_block_reason(target.global_position, main.grid)) == "ammo", "M1_E_EMPTY_WEAPON_DENIES_NEXT_SHOT")
	rifle_op.shot_cd = 0.0
	_expect(not rifle_op.try_fire(target, main.grid) and int(rifle_op.ammo) == 0, "M1_E_NO_PHANTOM_SHOT_OR_RELOAD")
	_expect(not rifle_op.has_ammo_pack and not rifle_op.ammo_pack_used, "M1_E_NO_HIDDEN_AMMO_PACK")

	# Real abort -> continue retry must restore the mission baseline and exactly
	# one authored copy of each crate kind.
	main._on_abort_pressed()
	_expect(int(main.phase) == int(main.Phase.FAILED), "M1_E_REAL_ABORT_FAILURE")
	main._on_continue_pressed()
	await _frames(3)
	_expect(int(main.phase) == int(main.Phase.SETUP), "M1_E_REAL_CONTINUE_RETRY")
	_expect(_squad_has_no_optional_resources(main), "M1_E_RETRY_CLEARS_OPTIONAL_INVENTORY")
	_expect(_squad_inventory_empty(main), "M1_E_RETRY_RESETS_ALL_PERSONAL_INVENTORY")
	_expect(_stash_signature(main) == initial_crates, "M1_E_RETRY_RESTOCKS_EXACT_BASELINE")
	_expect(_stash_kinds_unique(main), "M1_E_RETRY_HAS_NO_DUPLICATE_CRATES")

	# Optional path: pick a real grenade crate, preserve the basic firearm gate,
	# then compare its authoritative area damage with unchanged targets.
	var grenade_op = main.operators[0]
	var support_op = main.operators[1]
	if not await _pick_stash(main, grenade_op, "grenade"):
		return
	if not await _pick_stash(main, support_op, "rifle"):
		return
	var grenade_count := int(grenade_op.grenades)
	_expect(grenade_count > 0 and grenade_op.pack.count_of("grenade") == grenade_count, "M1_E_OPTIONAL_GRENADE_OWNERSHIP")
	var grenade_stash = _find_stash(main, "grenade")
	if grenade_stash != null:
		_fail("M1_E_PICKED_GRENADE_CRATE_REMAINS")
		return
	var grenade_origin: Vector2 = grenade_op.global_position
	var grenade_target: Vector2 = grenade_origin + Vector2(68.0, 0.0)
	main.raid_force_alarm()
	_expect(int(main.phase) == int(main.Phase.WATCHING), "M1_E_OPTIONAL_PLAN_ACCEPTED")
	var blast_center: Vector2 = grenade_target + Vector2(8.0, 6.0)
	var area_a = _spawn_test_enemy(main, 912, blast_center, 500.0)
	var area_b = _spawn_test_enemy(main, 913, blast_center + Vector2(42.0, 0.0), 500.0)
	if area_a == null or area_b == null:
		_fail("M1_E_OPTIONAL_TARGET_FIXTURE_MISSING")
		return
	var area_a_hp := float(area_a.hp)
	var area_b_hp := float(area_b.hp)
	main.selected = grenade_op
	_expect(main._throw_grenade_from(grenade_op, grenade_target), "M1_E_REAL_GRENADE_THROW_ACCEPTED")
	_expect(int(grenade_op.grenades) == grenade_count - 1, "M1_E_GRENADE_RESOURCE_CONSUMED_ON_THROW")
	_expect(grenade_op.pack.count_of("grenade") == int(grenade_op.grenades), "M1_E_GRENADE_PACK_AND_COUNTER_MATCH")
	if main.raid_grenades.is_empty():
		_fail("M1_E_GRENADE_ENTITY_MISSING")
		return
	var thrown = main.raid_grenades[0]
	for _step in 10:
		if thrown.spent():
			break
		thrown.sim_step(0.2)
	_expect(thrown.spent(), "M1_E_GRENADE_DETONATES_IN_SIMULATION")
	_expect(float(area_a.hp) < area_a_hp and float(area_b.hp) < area_b_hp, "M1_E_OPTIONAL_GRENADE_HAS_AREA_DAMAGE_EFFECT")

	main._on_abort_pressed()
	main._on_continue_pressed()
	await _frames(3)
	_expect(int(main.phase) == int(main.Phase.SETUP), "M1_E_OPTIONAL_RETRY_RETURNS_TO_SETUP")
	print("M1_E_POST_RETRY_INVENTORY %s" % _inventory_signature(main))
	_expect(_squad_inventory_empty(main), "M1_E_OPTIONAL_RETRY_CLEARS_WEAPONS_AND_THROWABLES")
	_expect(_stash_signature(main) == initial_crates, "M1_E_OPTIONAL_RETRY_DOES_NOT_DUPLICATE_STASHES")
	_expect(_stash_kinds_unique(main), "M1_E_FINAL_STASH_KINDS_UNIQUE")

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		print("M1_YARD_RESOURCE_BUDGET_FAILED count=%d" % failures.size())
		quit(2)
		return
	print("M1_YARD_RESOURCE_BUDGET_OK real_crates=1 core_without_optional=1 ownership=1 ammo_exhaustion=1 grenade_area_effect=1 retry_reset=1 no_duplicate_stashes=1")
	quit(0)


func _pick_stash(main, op, kind: String) -> bool:
	var stash = _find_stash(main, kind)
	if stash == null:
		_fail("M1_E_STASH_NOT_FOUND kind=%s" % kind)
		return false
	var stash_id: int = stash.get_instance_id()
	op.stop_move()
	op.global_position = stash.global_position
	main.selected = op
	main._try_pickup_near_selected()
	if not op.is_searching() or op.search_stash != stash:
		_fail("M1_E_REAL_SEARCH_NOT_STARTED kind=%s" % kind)
		return false
	main.raid_advance_search(0.8)
	await process_frame
	var stash_removed := not is_instance_id_valid(stash_id)
	var stash_still_listed := false
	for candidate in main.raid_stashes:
		if candidate != null and is_instance_valid(candidate) and int(candidate.get_instance_id()) == stash_id:
			stash_still_listed = true
	if not stash_removed or stash_still_listed:
		_fail("M1_E_REAL_SEARCH_DID_NOT_COLLECT kind=%s" % kind)
		return false
	print("M1_E_REAL_CRATE_PICKUP kind=%s owner=%d" % [kind, int(op.op_id)])
	return true


func _find_stash(main, kind: String):
	var wanted_family := WeaponCatalogScript.family_of(kind)
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var actual_kind := str(stash.kind)
		if actual_kind == kind or WeaponCatalogScript.family_of(actual_kind) == wanted_family:
			return stash
	return null


func _has_stash(main, kind: String) -> bool:
	return _find_stash(main, kind) != null


func _stash_signature(main) -> String:
	var counts: Dictionary = {}
	var cells: Dictionary = {}
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var kind := str(stash.kind)
		var cell_key := "%d,%d" % [int(stash.cell.x), int(stash.cell.y)]
		counts[kind] = int(counts.get(kind, 0)) + 1
		cells[cell_key] = int(cells.get(cell_key, 0)) + 1
	var kinds: Array = counts.keys()
	kinds.sort()
	var parts: Array[String] = []
	for kind in kinds:
		parts.append("%s:%d" % [str(kind), int(counts[kind])])
	var unique_cells := true
	for cell_key in cells:
		unique_cells = unique_cells and int(cells[cell_key]) == 1
	_expect(unique_cells, "M1_E_STASH_CELLS_UNIQUE")
	return ";".join(parts)


func _stash_kinds_unique(main) -> bool:
	var counts: Dictionary = {}
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var kind := str(stash.kind)
		counts[kind] = int(counts.get(kind, 0)) + 1
	for kind in counts:
		if int(counts[kind]) != 1:
			return false
	return true


func _squad_has_no_optional_resources(main) -> bool:
	for op in main.operators:
		if int(op.grenades) != 0 or int(op.mines) != 0 or int(op.decoys) != 0:
			return false
	return true


func _squad_inventory_empty(main) -> bool:
	for op in main.operators:
		if str(op.weapon_id) != "knife" or int(op.ammo) != 0 or op.pack.occupied() != 0:
			return false
		if int(op.grenades) != 0 or int(op.mines) != 0 or int(op.decoys) != 0 or not op.ammo_pool.is_empty():
			return false
		if bool(op.has_ammo_pack) or bool(op.ammo_pack_used):
			return false
	return true


func _inventory_signature(main) -> String:
	var parts: Array[String] = []
	for op in main.operators:
		parts.append("op%d:%s:%d:%s:%d,%d,%d:%s" % [
			int(op.op_id), str(op.weapon_id), int(op.ammo), JSON.stringify(op.ammo_pool),
			int(op.grenades), int(op.mines), int(op.decoys), JSON.stringify(op.pack.slots)
		])
	return ";".join(parts)


func _find_fire_solution(main, op) -> Dictionary:
	var directions := [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	for direction in directions:
		op.set_facing(rad_to_deg(direction.angle()))
		for distance in [32.0, 48.0, 64.0, 80.0, 96.0, 112.0, 128.0, 144.0, 160.0]:
			var point: Vector2 = op.global_position + direction * float(distance)
			if op.in_fire_geometry(point, main.grid):
				return {"point": point, "facing": float(op.facing_deg)}
	return {}


func _spawn_test_enemy(main, enemy_id: int, world_pos: Vector2, health: float):
	main._spawn_one({"id": enemy_id, "route": "main", "delay": 0.0, "loot": 0, "kit": "", "teaching_note": ""})
	if main.enemies.is_empty():
		return null
	var enemy = main.enemies.back()
	enemy.set_process(false)
	enemy.global_position = world_pos
	enemy.hp = health
	enemy.alive = true
	enemy.active = true
	return enemy


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _expect(ok: bool, marker: String) -> void:
	if not ok:
		failures.append(marker)
		push_error(marker)
	else:
		print(marker)


func _fail(marker: String) -> void:
	push_error(marker)
	quit(2)
