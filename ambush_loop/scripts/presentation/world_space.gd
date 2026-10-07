extends RefCounted
const Surface := preload("res://scripts/terrain_surface.gd")

## Tactical coordinates stay in pixels. Presentation uses metres, +Y up, -Z forward.
const CELL_METRES := 1.0
const PIXELS_PER_METRE := 32.0
const MAP_SIZE := Vector2(40.0, 22.0)
const HALF_MAP := MAP_SIZE * 0.5


static func logic_to_world(pos: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(pos.x / PIXELS_PER_METRE - HALF_MAP.x, height,
		pos.y / PIXELS_PER_METRE - HALF_MAP.y)


static func world_to_logic(pos: Vector3) -> Vector2:
	return Vector2(pos.x + HALF_MAP.x, pos.z + HALF_MAP.y) * PIXELS_PER_METRE


## Missing terrain in legacy recordings means explicitly flat, never live terrain.
static func height_at(frame: Dictionary, pos: Vector2) -> float:
	if int(frame.get("height_schema", 0)) not in [1,2] or not contains_logic(pos):
		return 0.0
	var tiers: PackedByteArray = frame.get("elevation_tier", PackedByteArray())
	if tiers.size() != 880:
		return 0.0
	if int(frame.height_schema) == 2:
		if frame.has("surface_ramps"):
			return Surface.height_on_ramps(tiers,frame.surface_ramps,pos)
		return Surface.height_at(tiers, frame.get("ramp_links", {}), pos)
	var cell := Vector2i(floori(pos.x / 32.0), floori(pos.y / 32.0))
	return float(tiers[cell.y * 40 + cell.x])


static func logic_to_surface(frame: Dictionary, pos: Vector2, offset: float = 0.0) -> Vector3:
	return logic_to_world(pos, height_at(frame, pos) + offset)


static func terrain_supported(data: Dictionary) -> bool:
	if not data.has("height_schema"):
		return true
	if typeof(data.height_schema) != TYPE_INT or data.height_schema not in [1,2]:
		return false
	for field in ["elevation_tier", "occlusion_kind", "blocked"]:
		if not data.get(field) is PackedByteArray or data[field].size() != 880:
			return false
	for tier in data.elevation_tier:
		if tier > 1:
			return false
	for kind in data.occlusion_kind:
		if kind > 3:
			return false
	if not data.get("ramp_links") is Dictionary:
		return false
	for edge in data.ramp_links:
		if not edge is Vector2i or edge.x < 0 or edge.y >= 880 or edge.x >= edge.y:
			return false
		var a := Vector2i(edge.x % 40, edge.x / 40)
		var b := Vector2i(edge.y % 40, edge.y / 40)
		if absi(a.x-b.x)+absi(a.y-b.y) != 1 or data.ramp_links[edge] != true:
			return false
	return true


static func contains_logic(pos: Vector2) -> bool:
	return pos.is_finite() and Rect2(Vector2.ZERO, MAP_SIZE * PIXELS_PER_METRE).has_point(pos)


static func facing_direction(degrees: float) -> Vector3:
	var angle := deg_to_rad(degrees)
	return Vector3(cos(angle), 0.0, sin(angle))


static func facing_yaw(degrees: float) -> float:
	var direction := facing_direction(degrees)
	return atan2(-direction.x, -direction.z)
