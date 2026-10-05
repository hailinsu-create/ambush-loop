extends SceneTree

## M1-G: verify two authored tactical plans and a real main-road-only failure
## against the actual yard, crate searches, movement routes, one B2 contact, and
## authoritative combat/escape events.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const WeaponCatalogScript := preload("res://scripts/raid/weapon_catalog.gd")
const GridScript := preload("res://scripts/grid.gd")
const RAMP_GROUND := Vector2i(15, 13)
const RAMP_PLATFORM := Vector2i(15, 12)
const MAX_SETUP_MOVE_STEPS := 1600
const MAX_SIM_TICKS := 6000

var failures: Array[String] = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var plan_a: Dictionary = await _run_scenario("A", {
		1: {"weapon": "rifle", "cell": Vector2i(30, 11), "facing": 0.0},
		2: {"weapon": "mg", "cell": Vector2i(12, 14), "facing": 45.0},
		3: {"weapon": "scout", "cell": Vector2i(15, 10), "facing": 153.4},
	})
	var plan_b: Dictionary = await _run_scenario("B", {
		1: {"weapon": "rifle", "cell": Vector2i(15, 13), "facing": 180.0},
		2: {"weapon": "mg", "cell": Vector2i(15, 10), "facing": 153.4},
		3: {"weapon": "scout", "cell": Vector2i(29, 15), "facing": 0.0},
	})
	var main_only: Dictionary = await _run_scenario("MAIN_ONLY_NEGATIVE", {
		1: {"weapon": "rifle", "cell": Vector2i(13, 10), "facing": 90.0},
		2: {"weapon": "mg", "cell": Vector2i(13, 11), "facing": 90.0},
		3: {"weapon": "scout", "cell": Vector2i(13, 12), "facing": 90.0},
	})

	_expect(bool(plan_a.get("won", false)), "M1_G_PLAN_A_WINS_B2_CONTACT")
	_expect(_has_all_kills(plan_a), "M1_G_PLAN_A_KILLS_ALL_THREE_AUTHORED_ENEMIES")
	_expect(int(plan_a.get("escape_count", -1)) == 0, "M1_G_PLAN_A_NO_ESCAPE")
	_expect(bool(plan_b.get("won", false)), "M1_G_PLAN_B_WINS_B2_CONTACT")
	_expect(_has_all_kills(plan_b), "M1_G_PLAN_B_KILLS_ALL_THREE_AUTHORED_ENEMIES")
	_expect(int(plan_b.get("escape_count", -1)) == 0, "M1_G_PLAN_B_NO_ESCAPE")
	_expect(str(plan_a.get("weapon_ids", "")) == str(plan_b.get("weapon_ids", "!")), "M1_G_A_B_SAME_CRATE_WEAPON_FAMILIES")
	_expect(bool(plan_a.get("high_role_valid", false)), "M1_G_PLAN_A_PRECISION_ROLE_TAKES_HIGHPOINT")
	_expect(bool(plan_b.get("high_role_valid", false)), "M1_G_PLAN_B_SUPPORT_ROLE_TAKES_HIGHPOINT")
	_expect(str(main_only.get("terminal_reason", "")) == "escape", "M1_G_MAIN_ONLY_FAILS_BY_ESCAPE_NOT_SQUAD_WIPE")
	_expect(bool(main_only.get("flank_escaped", false)), "M1_G_MAIN_ONLY_FLANK_ID3_ESCAPES_ON_REAL_ROUTE")
	_expect(bool(main_only.get("flank_denied", false)), "M1_G_MAIN_ONLY_LOGS_WHY_FLANK_WAS_UNCOVERED")

	if not failures.is_empty():
		_finish_failed()
		return
	print("M1_YARD_TACTICAL_SOLUTIONS_OK real_weapons=1 real_ramp=1 plan_a_win=1 plan_b_win=1 same_budget=1 flank_counterexample=1 explained_escape=1 single_contact=1")
	quit(0)


func _run_scenario(name: String, assignments: Dictionary) -> Dictionary:
	var main = await _open_yard()
	if main == null:
		return {}
	if not await _acquire_role_weapons(main, name):
		return {}
	var ramp_used_by_highpoint_role := false
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var assignment: Dictionary = assignments[op_id]
		var destination: Vector2i = assignment["cell"]
		var trace: Dictionary = await _walk_to_cell(main, op, destination)
		if not bool(trace.get("ok", false)):
			_fail("M1_G_%s_MOVE_ROLE%d_TO_%s" % [name, op_id, str(destination)])
			return {}
		if main.grid.get_elevation_tier(destination.x, destination.y) == GridScript.HEIGHT_PLATFORM:
			ramp_used_by_highpoint_role = bool(trace.get("used_ramp", false))
			if not ramp_used_by_highpoint_role:
				_fail("M1_G_%s_HIGHPOINT_REACHED_ONLY_VIA_RAMP_ROLE%d" % [name, op_id])
				return {}
		op.set_facing(float(assignment["facing"]))
		op.set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
		_expect(op.grid_cell() == destination, "M1_G_%s_ROLE%d_AT_AUTHORED_CELL" % [name, op_id])
		_expect(WeaponCatalogScript.family_of(str(op.weapon_id)) == WeaponCatalogScript.family_of(str(assignment["weapon"])), "M1_G_%s_ROLE%d_HAS_CRATE_FAMILY_%s" % [name, op_id, str(assignment["weapon"])])
	
	var high_role_valid := false
	if name == "A":
		var high_cell_a: Vector2i = main.operators[2].grid_cell()
		high_role_valid = main.grid.get_elevation_tier(high_cell_a.x, high_cell_a.y) == GridScript.HEIGHT_PLATFORM and main.grid.get_elevation_tier(main.operators[1].grid_cell().x, main.operators[1].grid_cell().y) == GridScript.HEIGHT_GROUND
	elif name == "B":
		var high_cell_b: Vector2i = main.operators[1].grid_cell()
		high_role_valid = main.grid.get_elevation_tier(high_cell_b.x, high_cell_b.y) == GridScript.HEIGHT_PLATFORM and main.operators[0].grid_cell() == RAMP_GROUND and main.grid.get_elevation_tier(main.operators[2].grid_cell().x, main.operators[2].grid_cell().y) == GridScript.HEIGHT_GROUND
	var initial_weapon_signature := _weapon_signature(main)

	main.raid_force_alarm()
	_expect(int(main.phase) == int(main.Phase.WATCHING), "M1_G_%s_REAL_ALARM_STARTS_WAVE_ONE" % name)
	var guard := 0
	while guard < MAX_SIM_TICKS:
		guard += 1
		if int(main.phase) == int(main.Phase.SWEEP):
			main._on_sweep_commit()
			if int(main.phase) == int(main.Phase.WON):
				break
		elif int(main.phase) != int(main.Phase.WATCHING):
			break
		if int(main.phase) == int(main.Phase.WATCHING):
			main._sim_tick()
	if guard >= MAX_SIM_TICKS:
		_fail("M1_G_%s_SIMULATION_GUARD_EXHAUSTED" % name)
		return {}

	var result := _summarize_result(main)
	result["name"] = name
	result["high_role_valid"] = high_role_valid
	result["weapon_ids"] = initial_weapon_signature
	print("M1_G_SCENARIO name=%s phase=%d terminal=%s kills=%s escapes=%s flank_escape=%s denies=%s weapons=%s" % [
		name,
		int(main.phase),
		str(result.get("terminal_reason", "")),
		str(result.get("kill_ids", [])),
		str(result.get("escape_ids", [])),
		str(result.get("flank_escaped", false)),
		str(result.get("flank_deny_reasons", [])),
		str(result["weapon_ids"]),
	])
	return result


func _open_yard():
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		_fail("M1_G_LOAD_REAL_MAIN_SCENE")
		return null
	await _frames(14)
	var main = current_scene
	if main == null or main.level == null:
		_fail("M1_G_SCENARIO_HAS_MAIN_LEVEL")
		return null
	if str(main.level.level_id) != "yard":
		main._load_level("yard", false, false)
		await _frames(2)
	if main.level == null or str(main.level.level_id) != "yard":
		_fail("M1_G_SCENARIO_STARTS_IN_REAL_YARD")
		return null
	main.set_process(false)
	for op in main.operators:
		op.set_process(false)
		op.visible = true
	return main


func _acquire_role_weapons(main, name: String) -> bool:
	var required := {1: "rifle", 2: "mg", 3: "scout"}
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var wanted := str(required[op_id])
		var stash = _find_stash(main, wanted)
		if stash == null:
			_fail("M1_G_%s_REAL_STASH_MISSING_%s" % [name, wanted])
			return false
		var target_cell: Vector2i = stash.cell
		var move: Dictionary = await _walk_to_cell(main, op, target_cell)
		if not bool(move.get("ok", false)):
			_fail("M1_G_%s_MOVE_TO_REAL_STASH_%s" % [name, wanted])
			return false
		var stash_id: int = stash.get_instance_id()
		main.selected = op
		main._try_pickup_near_selected()
		if not op.is_searching() or op.search_stash != stash:
			_fail("M1_G_%s_REAL_SEARCH_STARTS_%s" % [name, wanted])
			return false
		main.raid_advance_search(0.8)
		await process_frame
		if is_instance_id_valid(stash_id) or WeaponCatalogScript.family_of(str(op.weapon_id)) != WeaponCatalogScript.family_of(wanted):
			_fail("M1_G_%s_REAL_CRATE_PICKUP_%s" % [name, wanted])
			return false
		print("M1_G_PICKUP scenario=%s owner=%d kind=%s weapon=%s ammo=%d" % [name, op_id, wanted, str(op.weapon_id), int(op.ammo)])
	return true


func _walk_to_cell(main, op, destination: Vector2i) -> Dictionary:
	var from_cell: Vector2i = op.grid_cell()
	if from_cell == destination:
		return {"ok": true, "used_ramp": false}
	main.selected = op
	var destination_world: Vector2 = main.grid.cell_to_world_center(destination)
	if not main._command_move_op(op, destination_world):
		return {"ok": false, "used_ramp": false}
	var requested_path: PackedVector2Array = op.move_path.duplicate()
	if not _world_path_is_safe(main.grid, requested_path):
		return {"ok": false, "used_ramp": false}
	var used_ramp := _world_path_contains_edge(main.grid, requested_path, RAMP_GROUND, RAMP_PLATFORM)
	var guard := 0
	while op.is_moving() and guard < MAX_SETUP_MOVE_STEPS:
		guard += 1
		var before_world: Vector2 = op.global_position
		op.tick_move(0.20)
		var trace: Dictionary = _trace_world_segment(main.grid, before_world, op.global_position)
		if not bool(trace.get("ok", false)):
			return {"ok": false, "used_ramp": used_ramp}
		used_ramp = used_ramp or bool(trace.get("used_ramp", false))
		main._tick_command_pickups(0.20)
	if guard >= MAX_SETUP_MOVE_STEPS or op.grid_cell() != destination:
		return {"ok": false, "used_ramp": used_ramp}
	return {"ok": true, "used_ramp": used_ramp}


func _summarize_result(main) -> Dictionary:
	var kill_ids: Array[int] = []
	var escape_ids: Array[int] = []
	var flank_routes: Array[String] = []
	var flank_deny_reasons: Array[String] = []
	for event in main.battle_log.events:
		var typ := str(event.get("type", ""))
		if typ == "kill":
			kill_ids.append(int(event.get("actor_id", -1)))
		elif typ == "escape":
			escape_ids.append(int(event.get("actor_id", -1)))
		elif typ == "spawn" and int(event.get("actor_id", -1)) == 3:
			flank_routes.append(str(event.get("payload", {}).get("route", "")))
		elif typ == "no_engage" and int(event.get("target_id", -1)) == 3:
			flank_deny_reasons.append(str(event.get("payload", {}).get("reason", "")))
	return {
		"won": int(main.phase) == int(main.Phase.WON),
		"terminal_reason": str(main.battle_log.terminal_reason),
		"escape_count": escape_ids.size(),
		"kill_ids": kill_ids,
		"escape_ids": escape_ids,
		"flank_spawned_on_route": flank_routes.has("flank"),
		"flank_escaped": escape_ids.has(3) and flank_routes.has("flank"),
		"flank_deny_reasons": flank_deny_reasons,
		"flank_denied": not flank_deny_reasons.is_empty(),
	}


func _has_all_kills(result: Dictionary) -> bool:
	var ids: Array = result.get("kill_ids", [])
	return ids.count(1) == 1 and ids.count(2) == 1 and ids.count(3) == 1


func _weapon_signature(main) -> String:
	var parts: Array[String] = []
	for op in main.operators:
		parts.append("%d:%s:%d" % [int(op.op_id), str(WeaponCatalogScript.family_of(str(op.weapon_id))), int(op.ammo)])
	return ";".join(parts)


func _find_stash(main, family: String):
	var wanted_family := WeaponCatalogScript.family_of(family)
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		if WeaponCatalogScript.family_of(str(stash.kind)) == wanted_family:
			return stash
	return null


func _operator_by_id(main, op_id: int):
	for op in main.operators:
		if int(op.op_id) == op_id:
			return op
	return null


func _world_path_is_safe(grid, points: PackedVector2Array) -> bool:
	if points.size() < 2:
		return false
	for index in range(1, points.size()):
		if not grid.world_segment_traversable(points[index - 1], points[index]):
			return false
	return true


func _world_path_contains_edge(grid, points: PackedVector2Array, ramp_from: Vector2i, ramp_to: Vector2i) -> bool:
	for index in range(1, points.size()):
		var trace: Dictionary = _trace_world_segment(grid, points[index - 1], points[index])
		if bool(trace.get("used_ramp", false)):
			return true
	return false


func _trace_world_segment(grid, from_world: Vector2, to_world: Vector2) -> Dictionary:
	var previous: Vector2i = grid.world_to_cell(from_world)
	var used_ramp := false
	var sample_count := maxi(1, int(ceil(from_world.distance_to(to_world) / 4.0)))
	for step in range(1, sample_count + 1):
		var point := from_world.lerp(to_world, float(step) / float(sample_count))
		var current: Vector2i = grid.world_to_cell(point)
		if current == previous:
			continue
		if not grid.can_traverse_height(previous, current):
			return {"ok": false, "used_ramp": used_ramp}
		if previous == RAMP_GROUND and current == RAMP_PLATFORM:
			used_ramp = true
		previous = current
	return {"ok": true, "used_ramp": used_ramp}


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
	print("M1_YARD_TACTICAL_SOLUTIONS_FAILED count=%d" % failures.size())
	quit(2)
