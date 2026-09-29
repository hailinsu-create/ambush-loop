extends SceneTree

## M1-B verifies A* honors explicit elevation transitions while legacy flat
## levels retain their existing paths.

const GridScript := preload("res://scripts/grid.gd")
const PathfinderScript := preload("res://scripts/raid/pathfinder.gd")
const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var grid = GridScript.new()
	var ground := Vector2i(7, 6)
	var platform := Vector2i(8, 6)
	var from := Vector2i(6, 6)
	var to := Vector2i(10, 6)

	var legacy_path: Array[Vector2i] = PathfinderScript.find_path(grid, from, to)
	if legacy_path.size() != 5 or legacy_path[0] != from or legacy_path[-1] != to:
		_fail("M1_FLAT_PATHFINDING_REMAINS_COMPATIBLE", 2)
		return
	if not grid.set_elevation_tier(platform.x, platform.y, GridScript.HEIGHT_PLATFORM):
		_fail("M1_PLATFORM_SETUP", 3)
		return
	if not PathfinderScript.find_path(grid, ground, platform).is_empty():
		_fail("M1_ASTAR_REJECTS_UNLINKED_HEIGHT_CHANGE", 4)
		return
	if not grid.set_ramp_link(ground, platform):
		_fail("M1_RAMP_SETUP", 5)
		return

	var ramp_path: Array[Vector2i] = PathfinderScript.find_path(grid, ground, platform)
	if ramp_path != [ground, platform]:
		_fail("M1_ASTAR_USES_AUTHORED_RAMP", 6)
		return
	var reverse_ramp_path: Array[Vector2i] = PathfinderScript.find_path(grid, platform, ground)
	if reverse_ramp_path != [platform, ground]:
		_fail("M1_ASTAR_USES_RAMP_IN_BOTH_DIRECTIONS", 11)
		return
	var approach_path: Array[Vector2i] = PathfinderScript.find_path(grid, from, platform)
	if approach_path.is_empty() or approach_path[0] != from or approach_path[-1] != platform:
		_fail("M1_ASTAR_REACHES_PLATFORM_THROUGH_RAMP", 7)
		return
	for i in range(1, approach_path.size()):
		if not grid.can_traverse_height(approach_path[i - 1], approach_path[i]):
			_fail("M1_ASTAR_PATH_ONLY_USES_VALID_HEIGHT_EDGES", 8)
			return

	if not grid.set_ramp_link(ground, platform, false):
		_fail("M1_RAMP_REMOVAL", 9)
		return
	if not PathfinderScript.find_path(grid, ground, platform).is_empty():
		_fail("M1_ASTAR_STOPS_USING_REMOVED_RAMP", 10)
		return

	if not _check_legacy_neighbors():
		return
	if not _check_avoiding_and_blocked_ramps():
		return

	print("M1_RAMP_PATHFINDER_GATE_OK flat=1 legacy_maps=6 unlinked=1 ramp=1 reverse=1 avoid=1 alternate=1 soft=1 blocked_endpoints=1 removal=1")
	quit(0)


func _check_legacy_neighbors() -> bool:
	var grid = GridScript.new()
	var level_ids: Array[String] = ["yard", "warehouse", "pump", "railcut", "depot", "radio"]
	var dirs: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for level_id in level_ids:
		grid.rebuild(level_id)
		for y in range(GridScript.ROWS):
			for x in range(GridScript.COLS):
				if grid.is_blocked(x, y):
					continue
				if grid.get_elevation_tier(x, y) != GridScript.HEIGHT_GROUND:
					_fail("M1_EXISTING_LEVELS_KEEP_DEFAULT_GROUND_HEIGHT", 22)
					return false
				var cell := Vector2i(x, y)
				for direction in dirs:
					var neighbor: Vector2i = cell + direction
					var legacy_allowed := grid.in_bounds(neighbor.x, neighbor.y) and not grid.is_blocked(neighbor.x, neighbor.y)
					if grid.can_traverse_height(cell, neighbor) != legacy_allowed:
						_fail("M1_EXISTING_LEVEL_NEIGHBORS_MATCH_LEGACY", 23)
						return false
	return true


func _check_avoiding_and_blocked_ramps() -> bool:
	var grid = GridScript.new()
	var start := Vector2i(6, 6)
	var primary_ground := Vector2i(7, 6)
	var primary_platform := Vector2i(8, 6)
	var goal := Vector2i(9, 6)
	var alternate_ground := Vector2i(7, 7)
	var alternate_platform := Vector2i(8, 7)
	var alternate_tail := Vector2i(9, 7)
	for cell in [primary_platform, goal, alternate_platform, alternate_tail]:
		if not grid.set_elevation_tier(cell.x, cell.y, GridScript.HEIGHT_PLATFORM):
			_fail("M1_AVOID_PLATFORM_SETUP", 12)
			return false
	if not grid.set_ramp_link(primary_ground, primary_platform):
		_fail("M1_AVOID_PRIMARY_RAMP_SETUP", 13)
		return false
	if not grid.set_ramp_link(alternate_ground, alternate_platform):
		_fail("M1_AVOID_ALTERNATE_RAMP_SETUP", 14)
		return false

	var via_alternate: Array[Vector2i] = PathfinderScript.find_path_avoiding(
		grid, start, goal, {primary_platform: true}, {}
	)
	if via_alternate.is_empty() or via_alternate.has(primary_platform) or not via_alternate.has(alternate_platform):
		_fail("M1_AVOIDING_ONE_RAMP_SELECTS_ALTERNATE", 15)
		return false
	if not _path_uses_valid_height_edges(grid, via_alternate):
		_fail("M1_AVOID_ALTERNATE_PATH_USES_VALID_HEIGHT_EDGES", 16)
		return false

	var soft_alternate: Array[Vector2i] = PathfinderScript.find_path_avoiding(
		grid, start, goal, {}, {primary_platform: 10}
	)
	if soft_alternate.is_empty() or soft_alternate.has(primary_platform) or not soft_alternate.has(alternate_platform):
		_fail("M1_SOFT_COST_PRESERVES_LEGAL_RAMP_ROUTE", 17)
		return false
	if not grid.set_ramp_link(alternate_ground, alternate_platform, false):
		_fail("M1_AVOID_ALTERNATE_RAMP_REMOVAL", 18)
		return false
	if not PathfinderScript.find_path_avoiding(grid, start, goal, {primary_platform: true}, {}).is_empty():
		_fail("M1_AVOIDING_ONLY_RAMP_REJECTS_ROUTE", 19)
		return false

	grid.set_blocked(primary_platform.x, primary_platform.y, true)
	if grid.can_traverse_height(primary_ground, primary_platform) or not PathfinderScript.find_path(grid, start, goal).is_empty():
		_fail("M1_BLOCKED_RAMP_PLATFORM_ENDPOINT_REJECTS_ROUTE", 20)
		return false
	grid.set_blocked(primary_platform.x, primary_platform.y, false)
	grid.set_blocked(primary_ground.x, primary_ground.y, true)
	if grid.can_traverse_height(primary_ground, primary_platform) or not PathfinderScript.find_path(grid, start, goal).is_empty():
		_fail("M1_BLOCKED_RAMP_GROUND_ENDPOINT_REJECTS_ROUTE", 21)
		return false

	return true


func _path_uses_valid_height_edges(grid, path: Array[Vector2i]) -> bool:
	for i in range(1, path.size()):
		if not grid.can_traverse_height(path[i - 1], path[i]):
			return false
	return true


func _fail(marker: String, code: int) -> void:
	push_error(marker)
	quit(code)
