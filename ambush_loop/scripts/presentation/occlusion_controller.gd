extends RefCounted

## Cutaway affects only meshes. Grid/path/LOS and picker validity remain unchanged.
static func update(camera: Camera3D, walls: Array, targets: Array) -> void:
	for wall in walls:
		var cut := false
		if bool(wall.get("moving", false)):
			wall.bounds = wall.mesh.global_transform * wall.mesh.get_aabb()
		var bounds: AABB = wall.bounds
		for target in targets:
			var point: Vector3 = target
			var screen := camera.unproject_position(point)
			if not camera.get_viewport().get_visible_rect().has_point(screen):
				continue
			var origin := camera.project_ray_origin(screen)
			if bounds.intersects_segment(origin, point) != null:
				cut = true
				break
		var mesh: GeometryInstance3D = wall.mesh
		if str(wall.get("mode", "")) == "hide":
			mesh.visible = not cut
			continue
		var height: float = 0.28 if cut else bounds.size.y
		mesh.scale.y = height / bounds.size.y
		mesh.position.y = height * 0.5
