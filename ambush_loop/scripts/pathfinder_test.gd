extends SceneTree

## Pure pathfinding regression: no scenes, saves, or timing-dependent movement.
## The fingerprint pins exact legacy routes, including equal-cost tie breaking.

const Pathfinder := preload("res://scripts/raid/pathfinder.gd")
const StorageGuard := preload("res://scripts/test_storage_guard.gd")
# Captured with unmodified pathfinder.gd from 0859577be3d83efafb5e6082112c1dac53dd90d4.
const EXPECTED_FINGERPRINT := "0b77fff7d2d836cb1eccb589891c1c5f3a6bf5c63b25ea3a8a369e2d6e3aad45"
const SEED := 20261002
const CASES_PER_MAP := 72
const BENCHMARK_SAMPLES := 5

var _failures: PackedStringArray = []


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	_check_boundaries()
	var cases := _build_cases()
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	var oracle_cases := 0
	for i in cases.size():
		var test: Dictionary = cases[i]
		var grid: AmbushGrid = test.grid
		var before := grid.blocked.duplicate()
		var avoid_before: Dictionary = test.avoid.duplicate()
		var soft_before: Dictionary = test.soft.duplicate()
		var path: Array[Vector2i] = _search(test)
		var encoded := "%d:" % i
		for cell in path:
			encoded += "%d,%d;" % [cell.x, cell.y]
		digest.update((encoded + "\n").to_utf8_buffer())
		_check(grid.blocked == before and test.avoid == avoid_before and test.soft == soft_before,
			"case %d changed its inputs" % i)
		for j in path.size():
			var cell := path[j]
			_check(not grid.is_blocked(cell.x, cell.y), "case %d enters a wall" % i)
			if j > 0:
				var previous := path[j - 1]
				_check(absi(cell.x - previous.x) + absi(cell.y - previous.y) == 1,
					"case %d contains a non-adjacent step" % i)
				_check(not test.avoid.has(cell), "case %d enters an avoided cell" % i)
		# Built-in AStarGrid2D independently verifies reachability and weighted cost.
		# Endpoint relocation is covered by explicit cases and the legacy fingerprint.
		var from: Vector2i = test.from
		var to: Vector2i = test.to
		if not grid.is_blocked(from.x, from.y) and not grid.is_blocked(to.x, to.y) and \
			not test.avoid.has(from) and not test.avoid.has(to):
			var optimal := _native_path(test)
			_check(path.is_empty() == optimal.is_empty(), "case %d reachability differs" % i)
			_check(_cost(path, test.soft) == _cost(optimal, test.soft),
				"case %d is not a minimum-cost path" % i)
			oracle_cases += 1
	var fingerprint := digest.finish().hex_encode()
	print("PATHFINDER_FINGERPRINT ", fingerprint)
	_check(fingerprint == EXPECTED_FINGERPRINT, "legacy route fingerprint changed")
	if not _failures.is_empty():
		for failure in _failures:
			push_error("PATHFINDER_FAIL " + failure)
		quit(1)
		return
	print("PATHFINDER_OK cases=%d oracle=%d seed=%d" % [cases.size(), oracle_cases, SEED])
	if OS.get_environment("AMBUSH_PATHFINDER_BENCHMARK") == "1":
		_benchmark(cases)
	quit(0)


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _check_boundaries() -> void:
	var grid := AmbushGrid.new()
	grid.blocked.fill(0)
	var from := Vector2i(1, 1)
	var to := Vector2i(3, 1)
	_check(Pathfinder.find_path(null, from, to).is_empty(), "null grid")
	_check(Pathfinder.find_path(grid, Vector2i(-1, 1), to).is_empty(), "invalid start")
	_check(Pathfinder.find_path(grid, from, Vector2i(40, 1)).is_empty(), "invalid goal")
	_check(Pathfinder.find_path(grid, from, from) == [from], "same start and goal")
	_check(Pathfinder.find_path(grid, from, Vector2i(3, 3)) == [
		from, Vector2i(2, 1), to, Vector2i(3, 2), Vector2i(3, 3)
	], "equal-cost paths must keep legacy direction order")
	_check(Pathfinder.find_path_avoiding(grid, from, to, {from: true}) == [
		from, Vector2i(2, 1), to
	], "an avoided start may still be exited")
	var penalty := {Vector2i(2, 1): 5}
	var detour := Pathfinder.find_path_avoiding(grid, from, to, {}, penalty)
	_check(detour.size() == 5 and _cost(detour, penalty) == 4,
		"weighted route should take a longer but cheaper detour")
	var hard := Pathfinder.find_path_avoiding(grid, from, to, {Vector2i(2, 1): true})
	_check(hard.size() == 5 and not hard.has(Vector2i(2, 1)), "hard avoidance")
	grid.set_blocked(to.x, to.y, true)
	var relocated := Pathfinder.find_path(grid, from, to)
	_check(not relocated.is_empty() and relocated[-1] == Vector2i(2, 0), "blocked goal relocation")
	grid.set_blocked(to.x, to.y, false)
	relocated = Pathfinder.find_path_avoiding(grid, from, to, {to: true, Vector2i(2, 0): true})
	_check(not relocated.is_empty() and relocated[-1] == Vector2i(2, 1), "avoided goal relocation")
	grid.set_blocked(from.x, from.y, true)
	relocated = Pathfinder.find_path(grid, from, to)
	_check(not relocated.is_empty() and relocated[0] == Vector2i(0, 0), "blocked start relocation")
	grid.blocked.fill(1)
	_check(Pathfinder.find_path(grid, from, to).is_empty(), "no open endpoint")
	grid.blocked.fill(0)
	for y in AmbushGrid.ROWS:
		grid.set_blocked(2, y, true)
	_check(Pathfinder.find_path(grid, from, to).is_empty(), "unreachable goal")
	grid.set_blocked(2, 1, false)
	_check(Pathfinder.find_path(grid, from, to) == [from, Vector2i(2, 1), to],
		"a second search must see changed geometry")
	grid.rebuild("pump")
	var door := Vector2i(28, 6)
	var west := Vector2i(27, 6)
	var east := Vector2i(29, 6)
	grid.set_door_state(door, false)
	_check(Pathfinder.find_path(grid, west, east).has(door), "open door route")
	grid.set_door_state(door, true)
	var locked := Pathfinder.find_path(grid, west, east)
	_check(not locked.is_empty() and not locked.has(door), "closed door detour")
	grid.set_door_state(door, false)
	_check(Pathfinder.find_path(grid, west, east).has(door), "reopened door route")


static func _build_cases() -> Array[Dictionary]:
	var cases: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for level in ["yard", "warehouse", "pump", "pump_closed", "railcut", "depot", "radio"]:
		var grid := AmbushGrid.new()
		grid.rebuild("pump" if level == "pump_closed" else level)
		if level == "pump_closed":
			grid.set_door_state(Vector2i(28, 6), true)
		for i in CASES_PER_MAP:
			var from := Vector2i(rng.randi_range(1, 38), rng.randi_range(1, 20))
			var to := Vector2i(rng.randi_range(1, 38), rng.randi_range(1, 20))
			var avoid := {}
			var soft := {}
			if i % 4 == 1 or i % 4 == 3:
				for j in 12:
					avoid[Vector2i(rng.randi_range(1, 38), rng.randi_range(1, 20))] = true
			if i % 4 == 2 or i % 4 == 3:
				for j in 24:
					var cell := Vector2i(rng.randi_range(1, 38), rng.randi_range(1, 20))
					soft[cell] = rng.randi_range(1, 18)
			cases.append({"grid": grid, "from": from, "to": to, "avoid": avoid, "soft": soft,
				"kind": ["plain", "avoid", "weighted", "mixed"][i % 4]})
	return cases


static func _search(test: Dictionary) -> Array[Vector2i]:
	return Pathfinder.find_path_avoiding(test.grid, test.from, test.to, test.avoid, test.soft)


static func _cost(path: Array[Vector2i], soft: Dictionary) -> int:
	if path.is_empty():
		return -1
	var total := 0
	for i in range(1, path.size()):
		total += 1 + int(soft.get(path[i], 0))
	return total


static func _native_path(test: Dictionary) -> Array[Vector2i]:
	var oracle := AStarGrid2D.new()
	oracle.region = Rect2i(0, 0, AmbushGrid.COLS, AmbushGrid.ROWS)
	oracle.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	oracle.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	oracle.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	oracle.update()
	var grid: AmbushGrid = test.grid
	for y in AmbushGrid.ROWS:
		for x in AmbushGrid.COLS:
			var cell := Vector2i(x, y)
			oracle.set_point_solid(cell, grid.is_blocked(x, y) or test.avoid.has(cell))
			oracle.set_point_weight_scale(cell, 1 + int(test.soft.get(cell, 0)))
	return oracle.get_id_path(test.from, test.to)


static func _benchmark(cases: Array[Dictionary]) -> void:
	# Correctness above warms up the same queries. Only searches are timed here.
	for kind in ["plain", "avoid", "weighted", "mixed"]:
		var selected: Array[Dictionary] = []
		for test in cases:
			if test.kind == kind:
				selected.append(test)
		var samples: Array[int] = []
		var path_cells := 0
		for repeat in BENCHMARK_SAMPLES:
			var start := Time.get_ticks_usec()
			for test in selected:
				path_cells += _search(test).size()
			samples.append(Time.get_ticks_usec() - start)
		samples.sort()
		print("PATHFINDER_BENCH kind=%s queries=%d samples=%d median_us=%d path_cells=%d" % [
			kind, selected.size(), BENCHMARK_SAMPLES, samples[BENCHMARK_SAMPLES >> 1], path_cells
		])
