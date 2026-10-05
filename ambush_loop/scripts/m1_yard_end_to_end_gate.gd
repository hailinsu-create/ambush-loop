extends SceneTree

## M1-H retained after M2-B2: real crate search through single-contact
## combat, speed equivalence, read-only replay, a real flank escape, and retry.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const WeaponCatalogScript := preload("res://scripts/raid/weapon_catalog.gd")
const GridScript := preload("res://scripts/grid.gd")
const RAMP_GROUND := Vector2i(15, 13)
const MAX_SETUP_MOVE_STEPS := 1600
const MAX_SIM_TICKS := 6000
const FRAME_DT := 1.0 / 60.0

var failures: Array[String] = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var normal_1x: Dictionary = await _run_success(1.0)
	if normal_1x.is_empty() or not failures.is_empty():
		_finish_failed()
		return
	var normal_2x: Dictionary = await _run_success(2.0)
	if normal_2x.is_empty() or not failures.is_empty():
		_finish_failed()
		return

	_expect(str(normal_1x.get("event_signature", "")) == str(normal_2x.get("event_signature", "!")), "M1_H_1X_2X_IDENTICAL_AUTHORITATIVE_EVENTS")
	_expect(str(normal_1x.get("crew_signature", "")) == str(normal_2x.get("crew_signature", "!")), "M1_H_1X_2X_IDENTICAL_HEALTH_AND_AMMO")
	_expect(str(normal_1x.get("health_change_signature", "")) == str(normal_2x.get("health_change_signature", "!")), "M1_H_1X_2X_IDENTICAL_MEASURED_HEALTH_CHANGE")
	_expect(str(normal_1x.get("result_signature", "")) == str(normal_2x.get("result_signature", "!")), "M1_H_1X_2X_IDENTICAL_WAVE_RESULT")
	_expect(int(normal_1x.get("sim_ticks", -1)) == int(normal_2x.get("sim_ticks", -2)), "M1_H_1X_2X_SAME_FIXED_TICK_COUNT")
	_expect(int(normal_2x.get("frame_count", 999999)) < int(normal_1x.get("frame_count", -1)), "M1_H_2X_REACHES_SAME_RESULT_IN_FEWER_REAL_FRAMES")

	var failure_retry: Dictionary = await _run_failure_and_retry()
	_expect(bool(failure_retry.get("escaped", false)), "M1_H_REAL_FLANK_ESCAPE_RESULT")
	_expect(bool(failure_retry.get("retry_reset", false)), "M1_H_REAL_CONTINUE_RESETS_RESOURCES_AND_STASHES")
	if not failures.is_empty():
		_finish_failed()
		return

	print("M1_YARD_END_TO_END_OK real_crates=1 legal_ramp=1 preview=1 authoritative_fire=1 ammo_damage=1 single_contact_win=1 speed_equivalent=1 replay_read_only=1 real_escape=1 real_retry=1")
	quit(0)


func _run_success(speed: float) -> Dictionary:
	var label := "1X" if speed < 1.5 else "2X"
	var main = await _open_yard("SUCCESS_" + label)
	if main == null:
		return {}
	if not await _acquire_and_deploy_plan_a(main, "SUCCESS_" + label):
		return {}
	var initial_ammo := _total_ammo(main)
	var initial_hp: Dictionary = _crew_hp_map(main)
	var preview_by_op := _capture_coverage(main, "SUCCESS_" + label)
	if preview_by_op.is_empty():
		return {}

	main.raid_force_alarm()
	_expect(int(main.phase) == int(main.Phase.WATCHING), "M1_H_%s_REAL_ALARM_FREEZES_PLAN" % label)
	_set_test_speed(main, speed, label)
	_expect(main.frozen_plan != null and _all_visible_operators_locked(main), "M1_H_%s_LIVE_PLAN_FROZEN_BY_ALARM" % label)
	_expect(not main.battle_log.events.is_empty() and str(main.battle_log.events[0].get("type", "")) == "door", "M1_H_%s_ALARM_RECORDED_IN_BATTLELOG" % label)

	var simulated_ticks := 0
	var real_frames := 0
	var clock_steps_valid := true
	var event_cursor := 0
	var guard := 0
	while int(main.phase) != int(main.Phase.WON) and int(main.phase) != int(main.Phase.FAILED) and guard < MAX_SIM_TICKS:
		guard += 1
		if int(main.phase) == int(main.Phase.SWEEP):
			main._on_sweep_commit()
			if int(main.phase) == int(main.Phase.WATCHING):
				_set_test_speed(main, speed, label + "_AFTER_WAVE")
			continue
		if int(main.phase) != int(main.Phase.WATCHING):
			break
		var expected_steps := 1 if speed < 1.5 else 2
		var steps := int(main.sim.steps_for_frame(FRAME_DT))
		clock_steps_valid = clock_steps_valid and steps == expected_steps
		real_frames += 1
		for _step in steps:
			if int(main.phase) != int(main.Phase.WATCHING):
				break
			main._sim_tick()
			simulated_ticks += 1
			_assert_new_fire_events(main, event_cursor, preview_by_op, label)
			event_cursor = main.battle_log.events.size()
	if guard >= MAX_SIM_TICKS:
		_fail("M1_H_%s_SIM_GUARD_EXHAUSTED" % label)
		return {}

	var summary := _summarize_events(main)
	_expect(int(main.phase) == int(main.Phase.WON), "M1_H_%s_WINS_AUTHORED_TWO_WAVES" % label)
	_expect(clock_steps_valid, "M1_H_%s_FIXED_CLOCK_USES_%d_TICKS_PER_FRAME" % [label, 1 if speed < 1.5 else 2])
	_expect(str(main.battle_log.terminal_reason) == "win", "M1_H_%s_WIN_TERMINAL_REASON" % label)
	_expect(bool(summary.get("all_killed", false)) and int(summary.get("escape_count", -1)) == 0, "M1_H_%s_ALL_AUTHORED_THREATS_KILLED_ZERO_ESCAPES" % label)
	_expect(int(summary.get("fire_count", 0)) > 0, "M1_H_%s_AUTHORITATIVE_FIRE_EVENTS" % label)
	_expect(int(summary.get("fire_count", -1)) == initial_ammo - _total_ammo(main), "M1_H_%s_EACH_FIRE_CONSUMES_EXACTLY_ONE_ROUND" % label)
	_expect(_crew_health_valid(main), "M1_H_%s_CREW_HEALTH_REMAINS_IN_VALID_RANGE" % label)
	_expect(int(main.raid.wave_index) == 1, "M1_H_%s_BOTH_AUTHORED_WAVES_REACHED" % label)

	var event_signature := _events_signature(main.battle_log.events)
	var crew_signature := _crew_signature(main)
	var health_change_signature := _crew_health_change_signature(main, initial_hp)
	var result_signature := "%s|%s|%d|%d|%d" % [
		str(main.battle_log.terminal_reason),
		str(summary.get("kill_ids", [])),
		int(summary.get("escape_count", -1)),
		int(main.raid.wave_index),
		int(summary.get("fire_count", -1)),
	]
	var before_replay_phase := int(main.phase)
	var before_replay_events := event_signature
	var before_replay_crew := crew_signature
	main._on_replay_pressed()
	_expect(int(main.phase) == int(main.Phase.REPLAY), "M1_H_%s_REAL_REPLAY_ENTRY" % label)
	_expect(main.replay.log == main.battle_log, "M1_H_%s_REPLAY_BINDS_AUTHORITATIVE_BATTLELOG" % label)
	var replay_events: Array = main.replay.events_up_to(main.replay.max_tick())
	var replay_has_win_terminal := false
	for event in replay_events:
		if str(event.get("type", "")) == "terminal" and str(event.get("payload", {}).get("reason", "")) == "win":
			replay_has_win_terminal = true
	_expect(replay_has_win_terminal, "M1_H_%s_REPLAY_CONTAINS_AUTHORITATIVE_WIN_TERMINAL" % label)
	_expect(_events_signature(main.battle_log.events) == before_replay_events, "M1_H_%s_REPLAY_DOES_NOT_MUTATE_EVENT_LOG" % label)
	_expect(_crew_signature(main) == before_replay_crew, "M1_H_%s_REPLAY_DOES_NOT_MUTATE_COMBAT_RESOURCES" % label)
	main._exit_replay_to_setup()
	_expect(int(main.phase) == before_replay_phase, "M1_H_%s_REPLAY_EXIT_RESTORES_WIN_RESULT" % label)
	_expect(_events_signature(main.battle_log.events) == before_replay_events and _crew_signature(main) == before_replay_crew, "M1_H_%s_REPLAY_EXIT_PRESERVES_SETTLEMENT" % label)

	print("M1_H_SUCCESS speed=%s frames=%d ticks=%d fires=%d kills=%s escapes=%d result=%s" % [label, real_frames, simulated_ticks, int(summary.get("fire_count", 0)), str(summary.get("kill_ids", [])), int(summary.get("escape_count", -1)), result_signature])
	return {
		"event_signature": event_signature,
		"crew_signature": crew_signature,
		"health_change_signature": health_change_signature,
		"result_signature": result_signature,
		"sim_ticks": simulated_ticks,
		"frame_count": real_frames,
	}


func _run_failure_and_retry() -> Dictionary:
	var main = await _open_yard("FAILURE_RETRY")
	if main == null:
		return {}
	var initial_stashes := _stash_signature(main)
	if not await _acquire_weapons(main, "FAILURE_RETRY"):
		return {}
	var assignments := {
		1: {"cell": Vector2i(13, 10), "facing": 90.0},
		2: {"cell": Vector2i(13, 11), "facing": 90.0},
		3: {"cell": Vector2i(13, 12), "facing": 90.0},
	}
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var assignment: Dictionary = assignments[op_id]
		if not bool((await _walk_to_cell(main, op, assignment["cell"])).get("ok", false)):
			_fail("M1_H_FAILURE_RETRY_LEGAL_DEPLOYMENT_OP%d" % op_id)
			return {}
		op.set_facing(float(assignment["facing"]))
		op.set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)

	main.raid_force_alarm()
	_expect(int(main.phase) == int(main.Phase.WATCHING), "M1_H_FAILURE_RETRY_REAL_ALARM")
	var tick_guard := 0
	while int(main.phase) != int(main.Phase.FAILED) and int(main.phase) != int(main.Phase.WON) and tick_guard < MAX_SIM_TICKS:
		tick_guard += 1
		if int(main.phase) == int(main.Phase.SWEEP):
			main._on_sweep_commit()
		else:
			main._sim_tick()
	if tick_guard >= MAX_SIM_TICKS:
		_fail("M1_H_FAILURE_RETRY_GUARD_EXHAUSTED")
		return {}
	var before_continue := _summarize_events(main)
	var escaped := int(main.phase) == int(main.Phase.FAILED) and str(main.fail_reason) == "escape" and bool(before_continue.get("flank_escaped", false))
	_expect(escaped, "M1_H_FAILURE_RETRY_REAL_FLANK_ESCAPE_NOT_SCRIPTED")
	_expect(not main.battle_log.last_of_type("escape").is_empty(), "M1_H_FAILURE_RETRY_ESCAPE_EVENT_RECORDED")
	main._on_continue_pressed()
	await _frames(3)
	var reset_ok: bool = int(main.phase) == int(main.Phase.SETUP) and main.enemies.is_empty() and _inventory_empty(main) and _stash_signature(main) == initial_stashes and _stash_kinds_unique(main)
	_expect(reset_ok, "M1_H_FAILURE_RETRY_REAL_CONTINUE_RESTORES_SETUP_AND_RESOURCES")
	return {"escaped": escaped, "retry_reset": reset_ok}


func _open_yard(label: String):
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		_fail("M1_H_%s_LOAD_MAIN_SCENE" % label)
		return null
	await _frames(14)
	var main = current_scene
	if main == null or main.level == null:
		_fail("M1_H_%s_MAIN_SCENE_HAS_LEVEL" % label)
		return null
	if str(main.level.level_id) != "yard":
		main._load_level("yard", false, false)
		await _frames(2)
	if main.level == null or str(main.level.level_id) != "yard":
		_fail("M1_H_%s_LOADS_AUTHORED_YARD" % label)
		return null
	main.set_process(false)
	for op in main.operators:
		op.set_process(false)
		op.visible = true
	return main


func _acquire_and_deploy_plan_a(main, label: String) -> bool:
	if not await _acquire_weapons(main, label):
		return false
	var assignments := {
		1: {"cell": Vector2i(30, 11), "facing": 0.0, "weapon": "rifle"},
		2: {"cell": Vector2i(12, 14), "facing": 45.0, "weapon": "mg"},
		3: {"cell": Vector2i(15, 10), "facing": 153.4, "weapon": "scout"},
	}
	var highpoint_via_ramp := false
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var assignment: Dictionary = assignments[op_id]
		var move: Dictionary = await _walk_to_cell(main, op, assignment["cell"])
		if not bool(move.get("ok", false)):
			_fail("M1_H_%s_MOVE_OP%d_TO_PLAN_CELL" % [label, op_id])
			return false
		if main.grid.get_elevation_tier(assignment["cell"].x, assignment["cell"].y) == GridScript.HEIGHT_PLATFORM:
			highpoint_via_ramp = bool(move.get("used_ramp", false))
			op.set_meta("m1_h_used_ramp", highpoint_via_ramp)
		op.set_facing(float(assignment["facing"]))
		op.set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
		_expect(WeaponCatalogScript.family_of(str(op.weapon_id)) == WeaponCatalogScript.family_of(str(assignment["weapon"])), "M1_H_%s_OP%d_CRATE_WEAPON_FAMILY" % [label, op_id])
	_expect(highpoint_via_ramp and bool(_operator_by_id(main, 3).get_meta("m1_h_used_ramp", false)), "M1_H_%s_HIGHPOINT_ACCESSED_VIA_AUTHORED_RAMP" % label)
	return failures.is_empty()


func _acquire_weapons(main, label: String) -> bool:
	var kinds := {1: "rifle", 2: "mg", 3: "scout"}
	for op_id in [1, 2, 3]:
		var op = _operator_by_id(main, op_id)
		var kind := str(kinds[op_id])
		var stash = _find_stash(main, kind)
		if stash == null:
			_fail("M1_H_%s_REAL_STASH_%s_EXISTS" % [label, kind])
			return false
		var move: Dictionary = await _walk_to_cell(main, op, stash.cell)
		if not bool(move.get("ok", false)):
			_fail("M1_H_%s_WALK_TO_STASH_%s" % [label, kind])
			return false
		var stash_id: int = stash.get_instance_id()
		main.selected = op
		main._try_pickup_near_selected()
		if not op.is_searching() or op.search_stash != stash:
			_fail("M1_H_%s_REAL_SEARCH_STARTS_%s" % [label, kind])
			return false
		main.raid_advance_search(0.8)
		await process_frame
		if is_instance_id_valid(stash_id) or WeaponCatalogScript.family_of(str(op.weapon_id)) != WeaponCatalogScript.family_of(kind):
			_fail("M1_H_%s_REAL_PICKUP_%s" % [label, kind])
			return false
		_expect(int(op.ammo) > 0, "M1_H_%s_PICKUP_HAS_REAL_AMMO_%s" % [label, kind])
		print("M1_H_PICKUP scenario=%s owner=%d kind=%s weapon=%s ammo=%d" % [label, op_id, kind, str(op.weapon_id), int(op.ammo)])
	return true


func _capture_coverage(main, label: String) -> Dictionary:
	var by_op: Dictionary = {}
	for op in main.operators:
		main.selected = op
		main._refresh_selected_coverage()
		var points: Array[Vector2] = []
		for marker in main.selected_coverage_draw.get_children():
			points.append(marker.global_position)
		by_op[int(op.op_id)] = points
		_expect(not points.is_empty(), "M1_H_%s_OP%d_HAS_SELECTED_COVERAGE_PREVIEW" % [label, int(op.op_id)])
		_expect(bool(main.selected_coverage_draw.visible), "M1_H_%s_OP%d_PREVIEW_VISIBLE_IN_SETUP" % [label, int(op.op_id)])
	_expect(not by_op.is_empty(), "M1_H_%s_COVERAGE_CAPTURED" % label)
	return by_op


func _set_test_speed(main, speed: float, label: String) -> void:
	var wants_2x := speed >= 1.5
	if wants_2x != (float(main.sim.speed) >= 1.5):
		main._on_speed_pressed()
	var expected_text := "速度 2×" if wants_2x else "速度 1×"
	_expect(is_equal_approx(float(main.sim.speed), 2.0 if wants_2x else 1.0), "M1_H_%s_SPEED_CALLBACK_SETS_%s" % [label, expected_text])
	if main.speed_button != null:
		_expect(str(main.speed_button.text) == expected_text, "M1_H_%s_SPEED_BUTTON_LABEL_MATCHES" % label)


func _assert_new_fire_events(main, start_index: int, preview_by_op: Dictionary, label: String) -> void:
	for index in range(start_index, main.battle_log.events.size()):
		var event: Dictionary = main.battle_log.events[index]
		if str(event.get("type", "")) != "fire":
			continue
		var shooter = _operator_by_id(main, int(event.get("actor_id", -1)))
		var target = _enemy_by_id(main, int(event.get("target_id", -1)))
		if shooter == null or target == null:
			_fail("M1_H_%s_FIRE_EVENT_LINKS_REAL_SHOOTER_AND_TARGET" % label)
			continue
		var target_pos: Vector2 = target.global_position
		_expect(bool(shooter.in_fire_geometry(target_pos, main.grid)), "M1_H_%s_AUTH_FIRE_TARGET_MATCHES_REAL_FIRE_GEOMETRY" % label)
		var points: Array = preview_by_op.get(int(shooter.op_id), [])
		var preview_distance := _nearest_preview_distance(points, target_pos)
		if preview_distance > 17.0:
			print("M1_H_PREVIEW_TRACE speed=%s shooter=%d target=%d target_pos=%s nearest_marker=%.2f" % [label, int(shooter.op_id), int(target.label_id), str(target_pos), preview_distance])
		_expect(preview_distance <= 17.0, "M1_H_%s_AUTH_FIRE_TARGET_MATCHES_SELECTED_ROUTE_PREVIEW" % label)


func _nearest_preview_distance(points: Array, world_pos: Vector2) -> float:
	var nearest := INF
	for point in points:
		nearest = minf(nearest, (point as Vector2).distance_to(world_pos))
	return nearest


func _summarize_events(main) -> Dictionary:
	var kill_ids: Array[int] = []
	var escape_ids: Array[int] = []
	var flank_spawned := false
	var fire_count := 0
	for event in main.battle_log.events:
		match str(event.get("type", "")):
			"kill":
				kill_ids.append(int(event.get("actor_id", -1)))
			"escape":
				escape_ids.append(int(event.get("actor_id", -1)))
			"fire":
				fire_count += 1
			"spawn":
				if int(event.get("actor_id", -1)) == 3 and str(event.get("payload", {}).get("route", "")) == "flank":
					flank_spawned = true
	return {
		"kill_ids": kill_ids,
		"escape_ids": escape_ids,
		"escape_count": escape_ids.size(),
		"flank_escaped": flank_spawned and escape_ids.has(3),
		"fire_count": fire_count,
		"all_killed": kill_ids.count(1) == 1 and kill_ids.count(2) == 1 and kill_ids.count(3) == 1,
	}


func _events_signature(events: Array) -> String:
	var parts: Array[String] = []
	for event in events:
		parts.append(var_to_str(event))
	return "\n".join(parts)


func _crew_signature(main) -> String:
	var parts: Array[String] = []
	for op in main.operators:
		parts.append("%d:%s:%d:%.3f:%s" % [int(op.op_id), str(op.weapon_id), int(op.ammo), float(op.hp), JSON.stringify(op.ammo_pool)])
	return ";".join(parts)


func _crew_hp_signature(main) -> String:
	var parts: Array[String] = []
	for op in main.operators:
		parts.append("%d:%.3f" % [int(op.op_id), float(op.hp)])
	return ";".join(parts)


func _crew_hp_map(main) -> Dictionary:
	var health: Dictionary = {}
	for op in main.operators:
		health[int(op.op_id)] = float(op.hp)
	return health


func _crew_health_change_signature(main, initial_hp: Dictionary) -> String:
	var parts: Array[String] = []
	for op in main.operators:
		var before := float(initial_hp.get(int(op.op_id), float(op.hp)))
		parts.append("%d:%.3f" % [int(op.op_id), float(op.hp) - before])
	return ";".join(parts)


func _crew_health_valid(main) -> bool:
	for op in main.operators:
		if float(op.hp) <= 0.0 or float(op.hp) > float(OperatorUnit.MAX_HP):
			return false
	return true


func _all_visible_operators_locked(main) -> bool:
	for op in main.operators:
		if op.visible and op.alive and not op.locked:
			return false
	return true


func _total_ammo(main) -> int:
	var total := 0
	for op in main.operators:
		total += int(op.ammo)
	return total


func _operator_by_id(main, op_id: int):
	for op in main.operators:
		if int(op.op_id) == op_id:
			return op
	return null


func _enemy_by_id(main, enemy_id: int):
	for enemy in main.enemies:
		if is_instance_valid(enemy) and int(enemy.label_id) == enemy_id:
			return enemy
	return null


func _find_stash(main, kind: String):
	var wanted_family := WeaponCatalogScript.family_of(kind)
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		if WeaponCatalogScript.family_of(str(stash.kind)) == wanted_family:
			return stash
	return null


func _walk_to_cell(main, op, destination: Vector2i) -> Dictionary:
	if op.grid_cell() == destination:
		return {"ok": true, "used_ramp": false}
	main.selected = op
	if not main._command_move_op(op, main.grid.cell_to_world_center(destination)):
		return {"ok": false, "used_ramp": false}
	var path: PackedVector2Array = op.move_path.duplicate()
	if not _world_path_is_safe(main.grid, path):
		return {"ok": false, "used_ramp": false}
	var used_ramp := _world_path_contains_edge(main.grid, path)
	var guard := 0
	while op.is_moving() and guard < MAX_SETUP_MOVE_STEPS:
		guard += 1
		var before: Vector2 = op.global_position
		op.tick_move(0.20)
		if not _trace_world_segment(main.grid, before, op.global_position):
			return {"ok": false, "used_ramp": used_ramp}
		main._tick_command_pickups(0.20)
	if guard >= MAX_SETUP_MOVE_STEPS or op.grid_cell() != destination:
		return {"ok": false, "used_ramp": used_ramp}
	return {"ok": true, "used_ramp": used_ramp}


func _world_path_is_safe(grid, points: PackedVector2Array) -> bool:
	if points.size() < 2:
		return false
	for index in range(1, points.size()):
		if not grid.world_segment_traversable(points[index - 1], points[index]):
			return false
	return true


func _world_path_contains_edge(grid, points: PackedVector2Array) -> bool:
	for index in range(1, points.size()):
		var previous: Vector2i = grid.world_to_cell(points[index - 1])
		var current: Vector2i = grid.world_to_cell(points[index])
		if previous == RAMP_GROUND and current == Vector2i(15, 12):
			return true
	return false


func _trace_world_segment(grid, from_world: Vector2, to_world: Vector2) -> bool:
	var previous: Vector2i = grid.world_to_cell(from_world)
	var count := maxi(1, int(ceil(from_world.distance_to(to_world) / 4.0)))
	for step in range(1, count + 1):
		var point := from_world.lerp(to_world, float(step) / float(count))
		var current: Vector2i = grid.world_to_cell(point)
		if current != previous and not grid.can_traverse_height(previous, current):
			return false
		previous = current
	return true


func _stash_signature(main) -> String:
	var counts: Dictionary = {}
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var kind := str(stash.kind)
		counts[kind] = int(counts.get(kind, 0)) + 1
	var kinds: Array = counts.keys()
	kinds.sort()
	var parts: Array[String] = []
	for kind in kinds:
		parts.append("%s:%d" % [str(kind), int(counts[kind])])
	return ";".join(parts)


func _stash_kinds_unique(main) -> bool:
	var seen: Dictionary = {}
	for stash in main.raid_stashes:
		if stash == null or not is_instance_valid(stash) or stash.collected:
			continue
		var kind := str(stash.kind)
		if seen.has(kind):
			return false
		seen[kind] = true
	return true


func _inventory_empty(main) -> bool:
	for op in main.operators:
		if str(op.weapon_id) != "knife" or int(op.ammo) != 0 or int(op.pack.occupied()) != 0:
			return false
		if int(op.grenades) != 0 or int(op.mines) != 0 or int(op.decoys) != 0 or not op.ammo_pool.is_empty():
			return false
	return true


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
	print("M1_YARD_END_TO_END_FAILED count=%d" % failures.size())
	quit(2)
