extends RefCounted
class_name SimPathfinder

## 4-connected A* on SimGrid.
## Adapted from ambush_loop/scripts/raid/pathfinder.gd (main 0.6.28 RaidPathfinder)
## for variable-size SimGrid (yard 24×16). See PROVENANCE_VS.md.

const UNREACHED := 99999

const SimGrid := preload("res://sim/grid.gd")


static func find_path(grid: SimGrid, from: Vector2i, to: Vector2i) -> Array:
	return find_path_avoiding(grid, from, to, {})


static func find_path_avoiding(
	grid: SimGrid,
	from: Vector2i,
	to: Vector2i,
	avoid: Dictionary = {}
) -> Array:
	var empty: Array = []
	if grid == null:
		return empty
	if not _in_bounds(grid, from) or not _in_bounds(grid, to):
		return empty
	if not grid.walkable(to.x, to.y) or (avoid.has(to) and to != from):
		to = nearest_open_except(grid, to, avoid)
		if to.x < 0:
			return empty
	if not grid.walkable(from.x, from.y):
		from = nearest_open(grid, from)
		if from.x < 0:
			return empty
	if from == to:
		return [from]
	var w := grid.width
	var h := grid.height
	var cell_count := w * h
	var from_id := from.y * w + from.x
	var open: Array = [from_id]
	var came: Dictionary = {}
	var gscore := PackedInt32Array()
	gscore.resize(cell_count)
	gscore.fill(UNREACHED)
	var fscore := PackedInt32Array()
	fscore.resize(cell_count)
	gscore[from_id] = 0
	fscore[from_id] = _h(from, to)
	var closed: Dictionary = {}
	var guard := 0
	while not open.is_empty() and guard < 4000:
		guard += 1
		var cur_i := 0
		var cur_id: int = int(open[0])
		var best_f: int = int(fscore[cur_id])
		for i in range(1, open.size()):
			var candidate_id: int = int(open[i])
			var f: int = int(fscore[candidate_id])
			if f < best_f:
				best_f = f
				cur_id = candidate_id
				cur_i = i
		var cur := Vector2i(cur_id % w, int(cur_id / w))
		if cur == to:
			return _rebuild(came, cur, from)
		open.remove_at(cur_i)
		closed[cur] = true
		for n in _neighbors(grid, cur):
			if closed.has(n):
				continue
			if avoid.has(n) and n != to:
				continue
			var next_id: int = n.y * w + n.x
			var previous: int = int(gscore[next_id])
			var tg: int = int(gscore[cur_id]) + 1
			if tg < previous:
				came[n] = cur
				gscore[next_id] = tg
				fscore[next_id] = tg + _h(n, to)
				if previous == UNREACHED:
					open.append(next_id)
	return empty


static func _rebuild(came: Dictionary, cur: Vector2i, origin: Vector2i) -> Array:
	var path: Array = [cur]
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


static func _in_bounds(grid: SimGrid, c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < grid.width and c.y < grid.height


static func _neighbors(grid: SimGrid, c: Vector2i) -> Array:
	var out: Array = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for d in dirs:
		var n: Vector2i = c + d
		if _in_bounds(grid, n) and grid.walkable(n.x, n.y):
			out.append(n)
	return out


static func nearest_open(grid: SimGrid, cell: Vector2i) -> Vector2i:
	return nearest_open_except(grid, cell, {})


static func nearest_open_except(grid: SimGrid, cell: Vector2i, avoid: Dictionary) -> Vector2i:
	if _in_bounds(grid, cell) and grid.walkable(cell.x, cell.y) and not avoid.has(cell):
		return cell
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := Vector2i(cell.x + dx, cell.y + dy)
				if _in_bounds(grid, n) and grid.walkable(n.x, n.y) and not avoid.has(n):
					return n
	return Vector2i(-1, -1)
