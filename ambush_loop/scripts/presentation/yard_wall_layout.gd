extends RefCounted

## Greedy rectangles exactly partition blocked cells; never merge through a gap.
static func rectangles(grid: RefCounted, columns: int, rows: int) -> Array[Dictionary]:
	var visited := {}
	var out: Array[Dictionary] = []
	for y in rows:
		for x in columns:
			if visited.has(Vector2i(x,y)) or not grid.is_blocked(x,y): continue
			var border := _border(x,y,columns,rows)
			var width := 1
			while x + width < columns and grid.is_blocked(x+width,y) and not visited.has(Vector2i(x+width,y)) and _border(x+width,y,columns,rows) == border:
				width += 1
			var depth := 1
			while y + depth < rows:
				var extends_row := true
				for column in range(x,x+width):
					if not grid.is_blocked(column,y+depth) or visited.has(Vector2i(column,y+depth)) or _border(column,y+depth,columns,rows) != border:
						extends_row = false
						break
				if not extends_row: break
				depth += 1
			for row in range(y,y+depth):
				for column in range(x,x+width): visited[Vector2i(column,row)] = true
			out.append({"cells": Rect2i(x,y,width,depth), "height": 2.2 if border else 0.52})
	return out

static func _border(x: int,y: int,columns: int,rows: int) -> bool:
	return x == 0 or y == 0 or x == columns-1 or y == rows-1
