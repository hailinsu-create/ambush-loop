extends RefCounted

## Shared pure ramp geometry. Pixel topology, metre heights; no nodes or live state.
static func ramps(tiers: PackedByteArray, links: Dictionary) -> Array:
	var out := []
	if tiers.size() != 880:
		return out
	for edge in links:
		if not edge is Vector2i or edge.x < 0 or edge.y >= 880 or edge.x >= edge.y:
			continue
		var a := Vector2i(edge.x % 40, edge.x / 40)
		var b := Vector2i(edge.y % 40, edge.y / 40)
		if absi(a.x-b.x)+absi(a.y-b.y) != 1 or tiers[edge.x] == tiers[edge.y]:
			continue
		var low := a if tiers[edge.x] < tiers[edge.y] else b
		var high := b if low == a else a
		out.append({"low": Vector2(low)*32.0+Vector2(16,16), "high": Vector2(high)*32.0+Vector2(16,16), "high_index": high.y*40+high.x})
	return out

static func height_at(tiers: PackedByteArray, links: Dictionary, pos: Vector2) -> float:
	return height_on_ramps(tiers,ramps(tiers,links),pos)

static func height_on_ramps(tiers: PackedByteArray, geometry: Array, pos: Vector2) -> float:
	if tiers.size() != 880 or not pos.is_finite() or not Rect2(0,0,1280,704).has_point(pos):
		return 0.0
	for ramp in geometry:
		var axis: Vector2 = ramp.high-ramp.low
		var relative: Vector2 = pos-ramp.low
		var t := relative.dot(axis)/axis.length_squared()
		if t >= 0.0 and t <= 1.0 and absf(relative.cross(axis.normalized())) <= 16.0:
			return t
	return float(tiers[floori(pos.y/32.0)*40+floori(pos.x/32.0)])
