extends RefCounted

const Space := preload("res://scripts/presentation/world_space.gd")
const Surface := preload("res://scripts/terrain_surface.gd")

## Presentation-only ray tests, independent of simulation collision and frame rate.
## Proxy bounds cover whole bodies so clicking a head still selects its ground anchor.
static func pick(camera: Camera3D, screen: Vector2, frame: Dictionary) -> Dictionary:
	var invalid := {"valid": false}
	if not screen.is_finite() or not camera.get_viewport().get_visible_rect().has_point(screen):
		return invalid
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	if absf(direction.y) < 0.0001:
		return invalid
	var point: Variant = surface_at(camera, screen, frame)
	var nearest := INF
	var target := {}
	for group in ["ops", "sentries", "stashes", "covers", "loot"]:
		for item in frame.get(group, []):
			if not bool(item.get("active", true)) or not bool(item.get("alive", true)):
				continue
			var actor: bool = group in ["ops", "sentries"]
			var height := 1.8 if actor else (0.75 if group == "stashes" else 0.2)
			var radius := 0.42 if actor else 0.45
			var at := Space.logic_to_surface(frame, item.pos)
			var bounds := AABB(at - Vector3(radius, 0.0, radius), Vector3(radius * 2.0, height, radius * 2.0))
			var hit: Variant = bounds.intersects_ray(origin, direction)
			if hit is Vector3:
				var t: float = origin.distance_squared_to(hit)
				if t < nearest:
					nearest = t
					target = {"valid": true, "pos": item.pos,
						"kind": "op" if group == "ops" else group, "id": item.id}
	if not target.is_empty():
		return target
	if point == null:
		return invalid
	var logic := Space.world_to_logic(point)
	if not Space.contains_logic(logic):
		return invalid
	var cell := Vector2i(floori(logic.x / 32.0), floori(logic.y / 32.0))
	var blocked: PackedByteArray = frame.get("blocked", PackedByteArray())
	if blocked.size() != 880 or blocked[cell.y * 40 + cell.x] != 0:
		return invalid
	return {"valid": true, "pos": logic, "kind": "ground", "id": -1}


static func surface_at(camera: Camera3D, screen: Vector2, frame: Dictionary) -> Variant:
	var origin := camera.project_ray_origin(screen)
	var direction := camera.project_ray_normal(screen)
	if absf(direction.y) < 0.0001:
		return null
	var nearest := INF
	var result: Variant = null
	for height in [0.0, 1.0]:
		var distance: float = (height - origin.y) / direction.y
		if distance < 0.0 or distance >= nearest:
			continue
		var point := origin + direction * distance
		var logic := Space.world_to_logic(point)
		if Space.contains_logic(logic) and is_equal_approx(Space.height_at(frame, logic), height):
			nearest = distance
			result = point
	if int(frame.get("height_schema",0)) == 2:
		for ramp in Surface.ramps(frame.elevation_tier, frame.ramp_links):
			var axis: Vector2 = (ramp.high-ramp.low).normalized()
			var low := Space.logic_to_world(ramp.low)
			var normal := Vector3(-axis.x,1.0,-axis.y).normalized()
			var hit: Variant = Plane(normal,normal.dot(low)).intersects_ray(origin,direction)
			if not hit is Vector3:
				continue
			var logic := Space.world_to_logic(hit)
			var distance: float = origin.distance_to(hit)
			if distance < nearest and hit.y >= 0.0 and hit.y <= 1.0 and Space.contains_logic(logic) and is_equal_approx(Space.height_at(frame,logic),hit.y):
				nearest = distance
				result = hit
	return result
