extends SceneTree

## M1-B2 integration gate: authored yard height, real click route to the SMG,
## world-space movement/follow safety, and cache invalidation.

const GridScript := preload("res://scripts/grid.gd")
const PathfinderScript := preload("res://scripts/raid/pathfinder.gd")
const LevelDefScript := preload("res://scripts/level/level_def.gd")
const MapDrawScript := preload("res://scripts/map_draw.gd")
const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const PLATFORM_MIN := Vector2i(15, 10)
const PLATFORM_MAX := Vector2i(17, 12)
const RAMP_GROUND := Vector2i(15, 13)
const RAMP_PLATFORM := Vector2i(15, 12)
const STASH_CELL := Vector2i(17, 12)


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		_fail("M1_B2_MAIN_SCENE_LOAD", 2)
		return
	for _i in 14:
		await process_frame
	var main = current_scene
	if main == null or main.level == null or str(main.level.level_id) != "yard":
		_fail("M1_B2_REAL_YARD_BOOT", 3)
		return
	main.set_process(false)
	if not _check_authored_yard(main):
		return
	if not _check_cache_signature(main):
		return
	if not _check_real_click_move_and_pickup(main):
		return
	if not _check_real_follow_crossing(main):
		return
	if not _check_no_ramp_bypass(main):
		return
	print("M1_B2_YARD_HEIGHT_GATE_OK topology=1 click_move=1 stash_pickup=1 ascend=1 descend=1 follow=1 no_bypass=1 cache=1")
	quit(0)


func _check_authored_yard(main) -> bool:
	var grid = main.grid
	var level = LevelDefScript.by_id("yard")
	if grid.layout_id != "yard" or not grid.uses_height_topology() or grid.ramp_links.size() != 1:
		return _fail("M1_B2_YARD_HEIGHT_AUTHORED_ONCE", 4)
	for x in range(PLATFORM_MIN.x, PLATFORM_MAX.x + 1):
		for y in range(PLATFORM_MIN.y, PLATFORM_MAX.y + 1):
			if grid.get_elevation_tier(x, y) != GridScript.HEIGHT_PLATFORM or grid.is_blocked(x, y):
				return _fail("M1_B2_PLATFORM_3X3_OPEN", 5)
	if grid.get_elevation_tier(RAMP_GROUND.x, RAMP_GROUND.y) != GridScript.HEIGHT_GROUND:
		return _fail("M1_B2_RAMP_FOOT_GROUND", 6)
	if not grid.has_ramp_link(RAMP_GROUND, RAMP_PLATFORM):
		return _fail("M1_B2_ONLY_AUTHORED_RAMP", 7)
	var crossings := 0
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for x in range(PLATFORM_MIN.x, PLATFORM_MAX.x + 1):
		for y in range(PLATFORM_MIN.y, PLATFORM_MAX.y + 1):
			var cell := Vector2i(x, y)
			for direction in directions:
				var neighbor: Vector2i = cell + direction
				if not grid.in_bounds(neighbor.x, neighbor.y) or grid.get_elevation_tier(neighbor.x, neighbor.y) == GridScript.HEIGHT_PLATFORM:
					continue
				var expected := cell == RAMP_PLATFORM and neighbor == RAMP_GROUND
				var allowed: bool = grid.can_traverse_height(cell, neighbor)
				if allowed != expected:
					return _fail("M1_B2_PLATFORM_PERIMETER_HAS_ONE_RAMP", 8)
				if allowed:
					crossings += 1
	if crossings != 1 or not grid.can_traverse_height(RAMP_GROUND, RAMP_PLATFORM):
		return _fail("M1_B2_UNIQUE_RAMP_IS_BIDIRECTIONAL", 9)
	var smg_found := false
	for spec in level.stashes:
		if spec is Dictionary and spec.get("cell", Vector2i(-1, -1)) == STASH_CELL and str(spec.get("kind", "")) == "smg":
			smg_found = true
	for cell_def in level.cover_defs:
		var cover_cell: Vector2i = cell_def.get("cell", Vector2i(-1, -1))
		if grid.get_elevation_tier(cover_cell.x, cover_cell.y) == GridScript.HEIGHT_PLATFORM:
			return _fail("M1_B2_NO_INSTANT_DEPLOY_PAD_ON_PLATFORM", 10)
	if not smg_found:
		return _fail("M1_B2_EXISTING_SMG_REMAINS_ON_PLATFORM", 11)
	var geometry_errors: PackedStringArray = grid.validate_level_geometry(
		level.cover_defs, level.route_cells, level.alternate_route_cells,
		level.door_blocks_route, level.barrel_cell
	)
	if not geometry_errors.is_empty():
		return _fail("M1_B2_YARD_ROUTES_COVERS_VALID %s" % ";".join(geometry_errors), 12)
	var path: Array[Vector2i] = PathfinderScript.find_path(grid, Vector2i(6, 16), STASH_CELL)
	if path.is_empty() or not _path_contains_edge(path, RAMP_GROUND, RAMP_PLATFORM):
		return _fail("M1_B2_STASH_PATH_USES_SOUTH_RAMP", 13)
	if not grid.set_ramp_link(RAMP_GROUND, RAMP_PLATFORM, false):
		return _fail("M1_B2_REMOVE_RAMP_FOR_NEGATIVE", 14)
	if not PathfinderScript.find_path(grid, Vector2i(6, 16), STASH_CELL).is_empty():
		return _fail("M1_B2_NO_RAMP_NO_STASH_PATH", 15)
	grid.set_ramp_link(RAMP_GROUND, RAMP_PLATFORM)
	return true


func _check_cache_signature(main) -> bool:
	var grid = main.grid
	var draw = MapDrawScript.new()
	main.add_child(draw)
	draw.grid = grid
	draw.atmosphere_id = "yard"
	var baseline := draw._cache_signature()
	grid.set_ramp_link(RAMP_GROUND, RAMP_PLATFORM, false)
	var without_ramp := draw._cache_signature()
	grid.set_ramp_link(RAMP_GROUND, RAMP_PLATFORM)
	if baseline == without_ramp:
		draw.free()
		return _fail("M1_B2_STATIC_CACHE_HASHES_RAMPS", 16)
	grid.set_elevation_tier(14, 13, GridScript.HEIGHT_PLATFORM)
	var changed_height := draw._cache_signature()
	grid.set_elevation_tier(14, 13, GridScript.HEIGHT_GROUND)
	draw.free()
	if baseline == changed_height:
		return _fail("M1_B2_STATIC_CACHE_HASHES_HEIGHTS", 17)
	return true


func _check_real_click_move_and_pickup(main) -> bool:
	var grid = main.grid
	var op = main.operators[0]
	var stash = null
	for candidate in main.raid_stashes:
		if is_instance_valid(candidate) and candidate.cell == STASH_CELL:
			stash = candidate
			break
	if stash == null:
		return _fail("M1_B2_REAL_SMG_STASH_SPAWNED", 18)
	op.stop_move()
	op.global_position = grid.cell_to_world_center(Vector2i(6, 16))
	main.selected = op
	if not main._command_move_op(op, stash.global_position):
		return _fail("M1_B2_CLICK_TO_STASH_ACCEPTED", 19)
	if not _world_path_is_safe(grid, op.move_path) or not _world_path_contains_edge(grid, op.move_path, RAMP_GROUND, RAMP_PLATFORM):
		return _fail("M1_B2_CLICK_ROUTE_USES_ONLY_RAMP", 20)
	var trace := _trace_to_target(main, op, STASH_CELL, RAMP_GROUND, RAMP_PLATFORM)
	if not bool(trace.get("ok", false)) or not bool(trace.get("crossed", false)):
		return _fail("M1_B2_PLAYER_ASCENDS_VIA_RAMP", 21)
	if not stash.collected:
		main.raid_advance_search(1.0)
	if not stash.collected:
		return _fail("M1_B2_PLAYER_OPENS_PLATFORM_SMG", 22)
	if not op.pack.has_kind(str(stash.kind)):
		return _fail("M1_B2_SMG_PICKUP_REACHES_INVENTORY", 23)
	var return_trace := _trace_to_target(main, op, Vector2i(6, 16), RAMP_PLATFORM, RAMP_GROUND)
	if not bool(return_trace.get("ok", false)) or not bool(return_trace.get("crossed", false)):
		return _fail("M1_B2_PLAYER_DESCENDS_VIA_RAMP", 24)
	return true


func _trace_to_target(main, op, target_cell: Vector2i, ramp_from: Vector2i, ramp_to: Vector2i) -> Dictionary:
	if not main._command_move_op(op, main.grid.cell_to_world_center(target_cell)):
		return {"ok": false, "crossed": false}
	var grid = main.grid
	var crossed := false
	var guard := 0
	while op.is_moving() and guard < 1200:
		guard += 1
		var before_world: Vector2 = op.global_position
		op.tick_move(0.20)
		var trace: Dictionary = _trace_world_segment(grid, before_world, op.global_position, ramp_from, ramp_to)
		if not bool(trace.get("ok", false)):
			return {"ok": false, "crossed": crossed}
		crossed = crossed or bool(trace.get("crossed", false))
		main._tick_command_pickups(0.20)
	if guard >= 1200 or op.grid_cell() != target_cell:
		return {"ok": false, "crossed": crossed}
	main._tick_command_pickups(0.40)
	return {"ok": true, "crossed": crossed}


func _check_real_follow_crossing(main) -> bool:
	var grid = main.grid
	var leader = main.operators[0]
	var follower = main.operators[1]
	var chosen_lead := Vector2i(-1, -1)
	var chosen_follower := Vector2i(-1, -1)
	var chosen_face := 0.0
	for lx in range(PLATFORM_MIN.x, PLATFORM_MAX.x + 1):
		for ly in range(PLATFORM_MIN.y, PLATFORM_MAX.y + 1):
			for fy in range(RAMP_GROUND.y - 3, RAMP_GROUND.y + 3):
				for fx in range(RAMP_GROUND.x - 3, RAMP_GROUND.x + 4):
					var follower_cell := Vector2i(fx, fy)
					if not grid.in_bounds(fx, fy) or grid.is_blocked(fx, fy):
						continue
					if grid.get_elevation_tier(fx, fy) != GridScript.HEIGHT_GROUND:
						continue
					for face in [0.0, 90.0, 180.0, 270.0]:
						leader.stop_move()
						follower.stop_move()
						leader.global_position = grid.cell_to_world_center(Vector2i(lx, ly))
						leader.set_facing(float(face))
						follower.global_position = grid.cell_to_world_center(follower_cell)
						follower.follow_lead = true
						main.selected = leader
						var target: Vector2i = main._follow_anchor_cell(leader, follower)
						if target.x >= 0 and grid.get_elevation_tier(target.x, target.y) == GridScript.HEIGHT_PLATFORM:
							if maxi(absi(target.x - follower_cell.x), absi(target.y - follower_cell.y)) <= 2:
								chosen_lead = Vector2i(lx, ly)
								chosen_follower = follower_cell
								chosen_face = float(face)
								break
					if chosen_lead.x >= 0:
						break
				if chosen_lead.x >= 0:
					break
			if chosen_lead.x >= 0:
				break
		if chosen_lead.x >= 0:
			break
	if chosen_lead.x < 0:
		return _fail("M1_B2_FOLLOW_CAN_TARGET_PLATFORM_FROM_GROUND", 25)
	leader.global_position = grid.cell_to_world_center(chosen_lead)
	leader.set_facing(chosen_face)
	follower.global_position = grid.cell_to_world_center(chosen_follower)
	follower.stop_move()
	main.selected = leader
	var oid := int(follower.op_id)
	main._follow_dest[oid] = chosen_follower
	main._follow_lock[oid] = chosen_follower
	main._follow_blend_t.erase(oid)
	main._follow_blend_arc.erase(oid)
	var target: Vector2i = main._follow_anchor_cell(leader, follower)
	if maxi(absi(target.x - chosen_follower.x), absi(target.y - chosen_follower.y)) > 2:
		return _fail("M1_B2_FOLLOW_HOP_SHORTCUT_TEST_SETUP", 26)
	main._tick_squad_follow(0.05)
	if not follower.is_moving():
		return _fail("M1_B2_FOLLOW_TICK_SCHEDULES_MOVE", 27)
	var trace := _trace_follow_until_target(main, follower, target, RAMP_GROUND, RAMP_PLATFORM)
	if not bool(trace.get("ok", false)) or not bool(trace.get("crossed", false)):
		return _fail("M1_B2_FOLLOWER_ASCENDS_VIA_RAMP", 29)
	return true


func _trace_follow_until_target(main, op, target_cell: Vector2i, ramp_from: Vector2i, ramp_to: Vector2i) -> Dictionary:
	var grid = main.grid
	var crossed := false
	var guard := 0
	var stalled := 0
	while op.grid_cell() != target_cell and guard < 1200:
		guard += 1
		main._tick_squad_follow(0.05)
		if op.is_moving() and not _world_path_is_safe(grid, op.move_path):
			return {"ok": false, "crossed": crossed}
		var before_world: Vector2 = op.global_position
		op.tick_move(0.20)
		var trace: Dictionary = _trace_world_segment(grid, before_world, op.global_position, ramp_from, ramp_to)
		if not bool(trace.get("ok", false)):
			return {"ok": false, "crossed": crossed}
		crossed = crossed or bool(trace.get("crossed", false))
		main._tick_command_pickups(0.20)
		if op.global_position.distance_to(before_world) < 0.1 and not op.is_moving():
			stalled += 1
		else:
			stalled = 0
		if stalled > 30:
			return {"ok": false, "crossed": crossed}
	if guard >= 1200 or op.grid_cell() != target_cell:
		return {"ok": false, "crossed": crossed}
	return {"ok": true, "crossed": crossed}


func _check_no_ramp_bypass(main) -> bool:
	var grid = main.grid
	var op = main.operators[0]
	op.stop_move()
	op.global_position = grid.cell_to_world_center(RAMP_GROUND)
	var starting_world: Vector2 = op.global_position
	if not grid.set_ramp_link(RAMP_GROUND, RAMP_PLATFORM, false):
		return _fail("M1_B2_REMOVE_RAMP_FOR_MOVE_GUARD", 30)
	# Deliberately bypass set_move_path to exercise the per-frame execution guard.
	op.move_path = PackedVector2Array([starting_world, grid.cell_to_world_center(RAMP_PLATFORM)])
	op._path_i = 1
	op.tick_move(1.0)
	if op.global_position.distance_squared_to(starting_world) > 0.01 or op.is_moving():
		return _fail("M1_B2_EXECUTION_GUARD_STOPS_UNLINKED_RAMP", 31)
	var follower = main.operators[1]
	follower.stop_move()
	follower.global_position = starting_world
	follower.set_move_path(PackedVector2Array([starting_world, grid.cell_to_world_center(RAMP_PLATFORM)]))
	if follower.is_moving():
		return _fail("M1_B2_FOLLOW_SETTER_REJECTS_NO_RAMP", 32)
	grid.set_ramp_link(RAMP_GROUND, RAMP_PLATFORM)
	return true


func _world_path_is_safe(grid, points: PackedVector2Array) -> bool:
	if points.size() < 2:
		return false
	for i in range(1, points.size()):
		if not grid.world_segment_traversable(points[i - 1], points[i]):
			return false
	return true


func _world_path_contains_edge(grid, points: PackedVector2Array, from_cell: Vector2i, to_cell: Vector2i) -> bool:
	for i in range(1, points.size()):
		var trace: Dictionary = _trace_world_segment(grid, points[i - 1], points[i], from_cell, to_cell)
		if bool(trace.get("crossed", false)):
			return true
	return false


func _trace_world_segment(grid, from_world: Vector2, to_world: Vector2, ramp_from: Vector2i, ramp_to: Vector2i) -> Dictionary:
	var from_cell: Vector2i = grid.world_to_cell(from_world)
	var previous: Vector2i = from_cell
	var crossed := false
	var samples := maxi(1, int(ceil(from_world.distance_to(to_world) / 4.0)))
	for i in range(1, samples + 1):
		var point := from_world.lerp(to_world, float(i) / float(samples))
		var current: Vector2i = grid.world_to_cell(point)
		if current == previous:
			continue
		if not grid.can_traverse_height(previous, current):
			return {"ok": false, "crossed": crossed}
		if previous == ramp_from and current == ramp_to:
			crossed = true
		previous = current
	return {"ok": true, "crossed": crossed}


func _path_contains_edge(path: Array[Vector2i], from_cell: Vector2i, to_cell: Vector2i) -> bool:
	for i in range(1, path.size()):
		if path[i - 1] == from_cell and path[i] == to_cell:
			return true
	return false


func _fail(marker: String, code: int) -> bool:
	push_error(marker)
	quit(code)
	return false
