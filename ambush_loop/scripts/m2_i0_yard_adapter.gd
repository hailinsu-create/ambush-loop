extends RefCounted

const HEIGHT_METRES := 0.85
const SPACE := preload("res://scripts/presentation/world_space.gd")


static func recorded_anchor(logic_position: Vector2, tier: int, lift: float = 0.0) -> Vector3:
	# Legacy records without a tier use explicit ground fallback, never the live grid.
	if not logic_position.is_finite() or not SPACE.contains_logic(logic_position):
		return Vector3(INF, INF, INF)
	return SPACE.logic_to_world(logic_position, float(tier) * HEIGHT_METRES + lift)


static func world_anchor(grid: RefCounted, logic_position: Vector2, lift: float = 0.0) -> Vector3:
	if grid == null or not logic_position.is_finite() or not SPACE.contains_logic(logic_position):
		return Vector3(INF, INF, INF)
	var cell: Vector2i = grid.world_to_cell(logic_position)
	var tier: int = grid.get_elevation_tier(cell.x, cell.y)
	return SPACE.logic_to_world(logic_position, float(tier) * HEIGHT_METRES + lift)


static func candidate_for_surface(grid: RefCounted, world_hit: Vector3) -> Dictionary:
	if grid == null or not world_hit.is_finite():
		return {}
	var logic := SPACE.world_to_logic(world_hit)
	if not SPACE.contains_logic(logic):
		return {}
	var cell: Vector2i = grid.world_to_cell(logic)
	if not grid.in_bounds(cell.x, cell.y) or grid.is_blocked(cell.x, cell.y):
		return {}
	var tier: int = grid.get_elevation_tier(cell.x, cell.y)
	var surface_y := float(tier) * HEIGHT_METRES
	if absf(world_hit.y - surface_y) > 0.12:
		return {}
	return {
		"valid": true,
		"kind": "ground",
		"id": "cell:%d:%d" % [cell.x, cell.y],
		"cell": cell,
		"tier": tier,
		"pos": Vector2(cell) * 32.0 + Vector2.ONE * 16.0,
		"world_hit": world_hit,
		"actionable": true,
	}


static func choose_hit(candidates: Array) -> Dictionary:
	var ordered: Array[Dictionary] = []
	for raw in candidates:
		if not raw is Dictionary or not bool(raw.get("valid", false)):
			continue
		var distance: float = float(raw.get("distance", INF))
		if not is_finite(distance) or distance < 0.0:
			continue
		ordered.append(raw.duplicate(true))
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var da := float(a.get("distance", INF))
		var db := float(b.get("distance", INF))
		if not is_equal_approx(da, db):
			return da < db
		return _stable_key(a) < _stable_key(b)
	)
	if ordered.is_empty():
		return {}
	var chosen: Dictionary = ordered[0]
	if not bool(chosen.get("actionable", true)) or str(chosen.get("kind", "")) == "decoration":
		return {}
	if str(chosen.get("kind", "")) in ["ground", "operator", "stash", "cover", "loot"]:
		if not chosen.has("cell") or not chosen.has("pos"):
			return {}
	return chosen


static func pick(camera: Camera3D, screen: Vector2, grid: RefCounted, targets: Array) -> Dictionary:
	if camera == null or not screen.is_finite() or not camera.get_viewport().get_visible_rect().has_point(screen):
		return {}
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	if absf(direction.y) < 0.0001:
		return {}
	var hits: Array = []
	for target in targets:
		if not target is Dictionary or not target.get("bounds") is AABB:
			continue
		var hit: Variant = target.bounds.intersects_ray(origin, direction)
		if hit is Vector3:
			var candidate: Dictionary = target.duplicate(true)
			candidate["distance"] = origin.distance_to(hit)
			candidate["world_hit"] = hit
			hits.append(candidate)
	for tier in [0, 1]:
		var y := float(tier) * HEIGHT_METRES
		var distance := (y - origin.y) / direction.y
		if distance < 0.0:
			continue
		var surface_hit := origin + direction * distance
		var surface := candidate_for_surface(grid, surface_hit)
		if not surface.is_empty():
			surface["distance"] = distance
			hits.append(surface)
	return choose_hit(hits)


static func _stable_key(candidate: Dictionary) -> String:
	return "%s:%s:%s" % [
		str(candidate.get("kind", "")),
		str(candidate.get("id", "")),
		str(candidate.get("cell", "")),
	]
