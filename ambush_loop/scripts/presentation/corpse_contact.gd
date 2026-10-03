extends RefCounted

## Pure visual placement. Inputs come from the copied frame and immutable rigs;
## no tactical positions, facing, blockers, paths or hauled references are edited.
const FORMAT := 1
const CLEARANCE := 0.015


static func choose(bounds: AABB, shoulders: Vector3, palms: Vector3, anchor: Vector3, facing: float, walls: Array) -> Dictionary:
	var turns := [0.0]
	for step in range(1,13):
		turns.append(float(step)*15.0)
		if step != 12:
			turns.append(-float(step)*15.0)
	for turn: float in turns:
		var basis := Basis(Vector3.UP, preload("res://scripts/presentation/world_space.gd").facing_yaw(facing+turn))
		var transform := Transform3D(basis,anchor+basis*(palms-shoulders))
		var envelope := (transform*bounds).grow(CLEARANCE)
		var free := true
		for wall: AABB in walls:
			if envelope.intersects(wall):
				free = false
				break
		if free:
			return {"transform":transform,"facing":facing+turn,"resolved":true}
	return {"resolved":false}


static func skin_bounds(actor: Node3D) -> AABB:
	var mesh := preload("res://scripts/presentation/actor_visual.gd").find_type(actor.model,"MeshInstance3D") as MeshInstance3D
	var transforms := []
	var inverse := actor.global_transform.affine_inverse()
	for index in mesh.skin.get_bind_count():
		var name: String = mesh.skin.get_bind_name(index)
		var bone: int = actor.skeleton.find_bone(name) if not name.is_empty() else mesh.skin.get_bind_bone(index)
		transforms.append(inverse*actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(index))
	var bounds := AABB()
	var first := true
	for surface in mesh.mesh.get_surface_count():
		var arrays: Array = mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		for index in vertices.size():
			var point := Vector3.ZERO
			for slot in 4:
				var offset := index*4+slot
				point += (transforms[bones[offset]]*vertices[index])*weights[offset]
			if first:
				bounds = AABB(point,Vector3.ZERO)
				first = false
			else:
				bounds = bounds.expand(point)
	return bounds
