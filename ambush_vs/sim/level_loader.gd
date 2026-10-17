extends RefCounted
class_name SimLevelLoader

## Load level JSON into a Dictionary + SimGrid. Light validation against required fields.


static func load_path(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("SimLevelLoader: cannot open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SimLevelLoader: root must be object")
		return {}
	var err := validate(parsed)
	if not err.is_empty():
		push_error("SimLevelLoader: %s" % err)
		return {}
	return parsed


static func validate(level: Dictionary) -> String:
	for k in ["id", "version", "grid", "cells", "exits", "enemies", "sentries", "supplies", "ambush_targets", "night"]:
		if not level.has(k):
			return "missing required field: %s" % k
	var grid: Dictionary = level["grid"]
	for k in ["width", "height", "meters_per_cell"]:
		if not grid.has(k):
			return "grid missing %s" % k
	if int(grid["meters_per_cell"]) != 1:
		return "meters_per_cell must be 1"
	if typeof(level["ambush_targets"]) != TYPE_ARRAY or level["ambush_targets"].is_empty():
		return "ambush_targets must be non-empty array"
	if typeof(level["cells"]) != TYPE_ARRAY or level["cells"].is_empty():
		return "cells must be non-empty array"
	var enemies: Dictionary = level["enemies"]
	if not enemies.has("spawns") or not enemies.has("march_speed_cells_per_s"):
		return "enemies missing spawns or speed"
	return ""


static func build_grid(level: Dictionary) -> SimGrid:
	var grid := SimGrid.new()
	var g: Dictionary = level["grid"]
	grid.configure(int(g["width"]), int(g["height"]))
	for cell in level["cells"]:
		var c: Dictionary = cell
		var kind := str(c.get("kind", "ground"))
		var tier := str(c.get("tier", "ground"))
		var low := false
		if c.has("cover") and typeof(c["cover"]) == TYPE_DICTIONARY:
			var cov: Dictionary = c["cover"]
			low = str(cov.get("height", "")) == "low" or bool(cov.get("blocks_los_same_level", false))
		grid.set_cell(int(c["x"]), int(c["y"]), kind, tier, low)
	return grid


static func route_waypoints(level: Dictionary, route_id: String) -> Array:
	var enemies: Dictionary = level["enemies"]
	for r in enemies.get("routes", []):
		if str(r.get("id", "")) == route_id:
			return r.get("waypoints", [])
	return []
