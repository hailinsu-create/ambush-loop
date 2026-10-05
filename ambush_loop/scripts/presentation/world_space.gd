extends RefCounted

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


static func contains_logic(pos: Vector2) -> bool:
	return pos.is_finite() and Rect2(Vector2.ZERO, MAP_SIZE * PIXELS_PER_METRE).has_point(pos)


static func facing_direction(degrees: float) -> Vector3:
	var angle := deg_to_rad(degrees)
	return Vector3(cos(angle), 0.0, sin(angle))


static func facing_yaw(degrees: float) -> float:
	var direction := facing_direction(degrees)
	return atan2(-direction.x, -direction.z)
