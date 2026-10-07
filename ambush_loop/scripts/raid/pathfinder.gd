class_name RaidPathfinder
extends RefCounted

## 4-connected A* on AmbushGrid. Small map (40x22).

const UNREACHED := 99999


static func find_path(grid: AmbushGrid, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	return find_path_avoiding(grid, from, to, {}, {})


static func find_path_avoiding(
	grid: AmbushGrid,
	from: Vector2i,
	to: Vector2i,
	avoid: Dictionary = {},
	soft: Dictionary = {}
) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if grid == null:
		return empty
	if not grid.in_bounds(from.x, from.y) or not grid.in_bounds(to.x, to.y):
		return empty
	if grid.is_blocked(to.x, to.y) or (avoid.has(to) and to != from):
		to = nearest_open_except(grid, to, avoid)
		if to.x < 0:
			return empty
	if grid.is_blocked(from.x, from.y):
		from = nearest_open(grid, from)
		if from.x < 0:
			return empty
	if from == to:
		return [from]
	# Dense cell IDs avoid hashing Vector2i scores in the frontier scan. Keep the
	# stable linear scan: equal f scores must retain the original route ordering.
	var from_id := grid.idx(from.x, from.y)
	var open: Array[int] = [from_id]
	var came := {}
	var gscore := PackedInt32Array()
	gscore.resize(AmbushGrid.COLS * AmbushGrid.ROWS)
	gscore.fill(UNREACHED)
	var fscore := PackedInt32Array()
	fscore.resize(gscore.size())
	gscore[from_id] = 0
	fscore[from_id] = _h(from, to)
	var closed := {}
	var guard := 0
	while not open.is_empty() and guard < 1600:
		guard += 1
		var cur_i := 0
		var cur_id := open[0]
		var best_f := fscore[cur_id]
		for i in range(1, open.size()):
			var candidate_id := open[i]
			var f := fscore[candidate_id]
			if f < best_f:
				best_f = f
				cur_id = candidate_id
				cur_i = i
		@warning_ignore("integer_division")
		var cur := Vector2i(cur_id % AmbushGrid.COLS, cur_id / AmbushGrid.COLS)
		if cur == to:
			return _rebuild(came, cur, from)
		open.remove_at(cur_i)
		closed[cur] = true
		for n in _neighbors(grid, cur):
			if closed.has(n):
				continue
			if avoid.has(n) and n != to:
				continue
			var step := 1 + int(soft.get(n, 0))
			var next_id := grid.idx(n.x, n.y)
			var previous := gscore[next_id]
			var tg := gscore[cur_id] + step
			if tg < previous:
				came[n] = cur
				gscore[next_id] = tg
				fscore[next_id] = tg + _h(n, to)
				# Closed nodes were skipped above; an unreached node is exactly a
				# first insertion. Improved nodes keep their existing queue position.
				if previous == UNREACHED:
					open.append(next_id)
	return empty


static func _rebuild(came: Dictionary, cur: Vector2i, origin: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [cur]
	var guard := 0
	while came.has(cur) and guard < 400:
		guard += 1
		cur = came[cur]
		path.append(cur)
	path.reverse()
	if path.is_empty() or path[0] != origin:
		path.insert(0, origin)
	return path


static func _h(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _neighbors(grid: AmbushGrid, c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d in dirs:
		var n: Vector2i = c + d
		if grid.can_traverse_height(c, n):
			out.append(n)
	return out


static func nearest_open(grid: AmbushGrid, cell: Vector2i) -> Vector2i:
	return nearest_open_except(grid, cell, {})


static func nearest_open_except(grid: AmbushGrid, cell: Vector2i, avoid: Dictionary) -> Vector2i:
	if grid.in_bounds(cell.x, cell.y) and not grid.is_blocked(cell.x, cell.y) and not avoid.has(cell):
		return cell
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := Vector2i(cell.x + dx, cell.y + dy)
				if grid.in_bounds(n.x, n.y) and not grid.is_blocked(n.x, n.y) and not avoid.has(n):
					return n
	return Vector2i(-1, -1)


static func walkable(grid: AmbushGrid, cell: Vector2i) -> bool:
	return grid != null and grid.in_bounds(cell.x, cell.y) and not grid.is_blocked(cell.x, cell.y)
