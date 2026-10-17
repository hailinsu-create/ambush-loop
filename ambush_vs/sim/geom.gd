extends RefCounted
class_name SimGeom

## Angle 0° = east, CCW positive. Grid-center Euclidean. Cone inclusive.

const SimConstants := preload("res://sim/constants.gd")


static func cell_center(x: float, y: float) -> Vector2:
	return Vector2(x + 0.5, y + 0.5)


static func dist_centers(ax: float, ay: float, bx: float, by: float) -> float:
	return cell_center(ax, ay).distance_to(cell_center(bx, by))


static func bearing_deg(from_x: float, from_y: float, to_x: float, to_y: float) -> float:
	var a := cell_center(from_x, from_y)
	var b := cell_center(to_x, to_y)
	var d := b - a
	# atan2(y, x): x east, y north → 0=east, CCW+
	return rad_to_deg(atan2(d.y, d.x))


static func angle_delta_deg(a: float, b: float) -> float:
	var d := fmod(b - a + 180.0, 360.0) - 180.0
	if d < -180.0:
		d += 360.0
	return d


static func abs_angle_delta_deg(a: float, b: float) -> float:
	return absf(angle_delta_deg(a, b))


static func in_cone(
	origin_x: float,
	origin_y: float,
	facing_deg: float,
	half_angle_deg: float,
	range_cells: float,
	target_x: float,
	target_y: float
) -> bool:
	var dist := dist_centers(origin_x, origin_y, target_x, target_y)
	if dist > range_cells + 1e-9:
		return false
	if dist <= 1e-9:
		return true
	var bearing := bearing_deg(origin_x, origin_y, target_x, target_y)
	return abs_angle_delta_deg(facing_deg, bearing) <= half_angle_deg + 1e-9


static func range_band(dist: float) -> String:
	if dist <= SimConstants.RANGE_NEAR_MAX:
		return "near"
	if dist <= SimConstants.RANGE_MID_MAX:
		return "mid"
	return "far"


static func weapon_max_range(shots_near: int, shots_mid: int, shots_far: int) -> float:
	if shots_far < 99:
		return SimConstants.RANGE_FAR_MAX
	if shots_mid < 99:
		return SimConstants.RANGE_MID_MAX
	if shots_near < 99:
		return SimConstants.RANGE_NEAR_MAX
	return 0.0
