extends RefCounted
class_name SimGrid

## Single-layer grid: tier ground/high, wall/structure block all LOS,
## low cover blocks same-tier only (ADR-HEIGHT-01).

var width: int = 0
var height: int = 0
## cell key "x,y" → {kind, tier, walkable, blocks_all_los, low_cover}
var _cells: Dictionary = {}


func configure(w: int, h: int) -> void:
	width = w
	height = h
	_cells.clear()


func set_cell(x: int, y: int, kind: String, tier: String = "ground", low_cover: bool = false) -> void:
	var walkable := kind not in ["wall", "structure"]
	var blocks_all := kind in ["wall", "structure"]
	_cells[_key(x, y)] = {
		"x": x,
		"y": y,
		"kind": kind,
		"tier": tier if not blocks_all else "",
		"walkable": walkable,
		"blocks_all_los": blocks_all,
		"low_cover": low_cover,
	}


func has_cell(x: int, y: int) -> bool:
	return _cells.has(_key(x, y))


func get_cell(x: int, y: int) -> Dictionary:
	var k := _key(x, y)
	if _cells.has(k):
		return _cells[k]
	# Default: wall outside known cells
	return {
		"x": x,
		"y": y,
		"kind": "wall",
		"tier": "",
		"walkable": false,
		"blocks_all_los": true,
		"low_cover": false,
	}


func tier_at(x: float, y: float) -> String:
	var c := get_cell(int(floor(x)), int(floor(y)))
	var t: String = str(c.get("tier", "ground"))
	return t if not t.is_empty() else SimConstants.TIER_GROUND


func walkable(x: int, y: int) -> bool:
	return bool(get_cell(x, y).get("walkable", false))


func los_clear(
	ax: float,
	ay: float,
	a_tier: String,
	bx: float,
	by: float,
	b_tier: String
) -> bool:
	## Sample along segment between cell centers; walls/structure always block;
	## low cover blocks only when both ends are ground.
	var a := SimGeom.cell_center(ax, ay)
	var b := SimGeom.cell_center(bx, by)
	var dist := a.distance_to(b)
	if dist <= 1e-9:
		return true
	var steps := maxi(2, int(ceil(dist * 4.0)))
	var same_ground := (
		a_tier == SimConstants.TIER_GROUND and b_tier == SimConstants.TIER_GROUND
	)
	for i in range(1, steps):
		var t := float(i) / float(steps)
		var p := a.lerp(b, t)
		var cx := int(floor(p.x))
		var cy := int(floor(p.y))
		# Skip endpoints' own cells
		if (cx == int(floor(ax)) and cy == int(floor(ay))) or (cx == int(floor(bx)) and cy == int(floor(by))):
			continue
		var cell := get_cell(cx, cy)
		if bool(cell.get("blocks_all_los", false)):
			return false
		if same_ground and bool(cell.get("low_cover", false)):
			# Shooter may brace on/behind adjacent low cover without self-blocking
			# the first ring (yard plan B Kar@west_cover / MP@east_cover).
			var cheb := maxi(absi(cx - int(floor(ax))), absi(cy - int(floor(ay))))
			if cheb >= 2:
				return false
	return true


func cells_in_sector(
	ox: float,
	oy: float,
	facing_deg: float,
	half_angle_deg: float,
	range_cells: float,
	observer_tier: String
) -> Array:
	## Return integer cell coords (as Vector2i) inside sector with LOS.
	var out: Array = []
	var r_ceil := int(ceil(range_cells)) + 1
	var oxi := int(floor(ox))
	var oyi := int(floor(oy))
	for y in range(oyi - r_ceil, oyi + r_ceil + 1):
		for x in range(oxi - r_ceil, oxi + r_ceil + 1):
			if x < 0 or y < 0 or x >= width or y >= height:
				continue
			if not SimGeom.in_cone(ox, oy, facing_deg, half_angle_deg, range_cells, float(x), float(y)):
				continue
			var t := tier_at(float(x), float(y))
			if not los_clear(ox, oy, observer_tier, float(x), float(y), t):
				continue
			out.append(Vector2i(x, y))
	return out


func _key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]
