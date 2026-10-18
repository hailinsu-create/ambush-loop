extends RefCounted
class_name AimSnap

## P0-2: facing snap for aim-handle drag. Landmarks use neutral labels only
## (北门 / 南门 / 巷口 / 杀伤区) — never high-slot / barn hints.

const SimGeom := preload("res://sim/geom.gd")

const STEP_DEG := 5.0
const SNAP_HALF_DEG := 7.5 ## within this of a landmark → snap


static func normalize_deg(deg: float) -> float:
	var d := fmod(deg, 360.0)
	if d < 0.0:
		d += 360.0
	return d


static func round_to_step(deg: float, step: float = STEP_DEG) -> float:
	return normalize_deg(roundf(deg / step) * step)


## Landmark bearings from an operator cell. Yard exits: 北门=y≈0 gate, 南门=y≈14–15 approach, 巷口≈(18,8).
static func landmark_bearings(op_x: float, op_y: float, level: Dictionary = {}) -> Array:
	var out: Array = []
	var north := Vector2(11.0, 0.0)
	var south := Vector2(11.0, 14.0)
	var alley := Vector2(18.0, 8.0)
	var cross := Vector2(11.0, 7.0) ## main-road kill cross — neutral「路口」
	## Prefer explicit exit centroids when present.
	for ex in level.get("exits", []):
		var id := str(ex.get("id", ""))
		var cells: Array = ex.get("cells", [])
		if cells.is_empty():
			continue
		var sx := 0.0
		var sy := 0.0
		for c in cells:
			sx += float(c["x"])
			sy += float(c["y"])
		var n := float(cells.size())
		var cx := sx / n
		var cy := sy / n
		if id == "south_gate":
			north = Vector2(cx, cy) ## cells at y=0 → 北门
		elif id == "road_tail" or id == "gate_n":
			south = Vector2(cx, cy)
		elif id == "east_alley":
			## Mouth sits west of the exit cells; use classic (18,8) 巷口.
			pass
	out.append({"deg": SimGeom.bearing_deg(op_x, op_y, north.x, north.y), "label": "北门"})
	out.append({"deg": SimGeom.bearing_deg(op_x, op_y, south.x, south.y), "label": "南门"})
	out.append({"deg": SimGeom.bearing_deg(op_x, op_y, alley.x, alley.y), "label": "巷口"})
	out.append({"deg": SimGeom.bearing_deg(op_x, op_y, cross.x, cross.y), "label": "路口"})
	return out


## Kill-zone edge bearings: sector left/right rim at half-angle for current weapon.
static func kill_zone_edge_bearings(facing_deg: float, sector_deg: float) -> Array:
	var half := float(sector_deg) * 0.5
	if half <= 1e-6:
		return []
	return [
		{"deg": normalize_deg(facing_deg - half), "label": "杀伤区"},
		{"deg": normalize_deg(facing_deg + half), "label": "杀伤区"},
	]


## Snap raw aim degrees. Returns {deg, label, snapped:bool}.
## `sector_deg` / `base_facing` optional for kill-zone rim hints relative to current cone.
static func nearest_landmark(raw_deg: float, op_x: float, op_y: float, level: Dictionary = {}) -> Dictionary:
	## Always pick the closest of 北门/南门/巷口 (no half-angle gate).
	var raw := normalize_deg(raw_deg)
	var best_label := ""
	var best_deg := raw
	var best_delta := 999.0
	for c in landmark_bearings(op_x, op_y, level):
		var d := SimGeom.abs_angle_delta_deg(raw, float(c["deg"]))
		if d < best_delta - 1e-9:
			best_delta = d
			best_deg = normalize_deg(float(c["deg"]))
			best_label = str(c["label"])
	return {"deg": best_deg, "label": best_label, "delta": best_delta}


static func snap_facing(
	raw_deg: float,
	op_x: float,
	op_y: float,
	level: Dictionary = {},
	sector_deg: float = 0.0,
	base_facing: float = NAN
) -> Dictionary:
	var raw := normalize_deg(raw_deg)
	var candidates: Array = landmark_bearings(op_x, op_y, level)
	if sector_deg > 1e-6 and not is_nan(base_facing):
		candidates.append_array(kill_zone_edge_bearings(base_facing, sector_deg))
	var best_label := ""
	var best_deg := raw
	var best_delta := SNAP_HALF_DEG + 1.0
	for c in candidates:
		var d := SimGeom.abs_angle_delta_deg(raw, float(c["deg"]))
		if d < best_delta - 1e-9:
			best_delta = d
			best_deg = normalize_deg(float(c["deg"]))
			best_label = str(c["label"])
	if best_delta <= SNAP_HALF_DEG + 1e-9:
		return {"deg": best_deg, "label": best_label, "snapped": true}
	var stepped := round_to_step(raw, STEP_DEG)
	return {"deg": stepped, "label": "", "snapped": false}
