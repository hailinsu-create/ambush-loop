extends RefCounted

## Cutaway affects only meshes. Grid/path/LOS and picker validity remain unchanged.
static func update(camera: Camera3D, walls: Array, targets: Array) -> void:
	for wall in walls:
		var cut := false
		var bounds: AABB = wall.bounds
		for target in targets:
			var point: Vector3 = target
			var screen := camera.unproject_position(point)
			var origin := camera.project_ray_origin(screen)
			if bounds.intersects_segment(origin, point) != null:
				cut = true
				break
		var mesh: MeshInstance3D = wall.mesh
		var height: float = 0.28 if cut else bounds.size.y
		mesh.scale.y = height / bounds.size.y
		mesh.position.y = height * 0.5
