extends RefCounted

## Temporary, reusable primitives. Replace through the asset pipeline after A0.
static func material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED if color.a < 1.0 else BaseMaterial3D.CULL_BACK
	return mat


static func box(parent: Node3D, size: Vector3, position: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = position
	parent.add_child(node)
	return node


static func cylinder(parent: Node3D, radius: float, height: float, position: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	node.mesh = mesh
	node.material_override = mat
	node.position = position
	parent.add_child(node)
	return node


static func actor(parent: Node3D, mat: Material, equipment: Material) -> Node3D:
	var body := Node3D.new()
	body.name = "Body"
	parent.add_child(body)
	box(body, Vector3(0.45, 0.62, 0.3), Vector3(0, 1.05, 0), mat)
	cylinder(body, 0.19, 0.27, Vector3(0, 1.55, -0.015), mat)
	box(body, Vector3(0.15, 0.65, 0.2), Vector3(-0.14, 0.36, 0), mat)
	box(body, Vector3(0.15, 0.65, 0.2), Vector3(0.14, 0.36, 0), mat)
	box(body, Vector3(0.33, 0.37, 0.16), Vector3(0, 1.1, 0.23), equipment)
	box(body, Vector3(0.11, 0.12, 0.75), Vector3(0.25, 1.14, -0.4), equipment)
	# Share two surfaces per actor instead of submitting each temporary primitive.
	for material in [mat, equipment]:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for child in body.get_children():
			if child is MeshInstance3D and child.material_override == material:
				surface.append_from(child.mesh, 0, child.transform)
				child.free()
		var merged := MeshInstance3D.new()
		merged.mesh = surface.commit()
		merged.material_override = material
		body.add_child(merged)
	return body


static func blocked_rectangles(blocked: PackedByteArray) -> Array[Rect2i]:
	var used := PackedByteArray()
	used.resize(880)
	var out: Array[Rect2i] = []
	for y in 22:
		for x in 40:
			var index := y * 40 + x
			if used[index] != 0 or blocked[index] == 0:
				continue
			var width := 1
			while x + width < 40 and blocked[index + width] != 0 and used[index + width] == 0:
				width += 1
			var height := 1
			while y + height < 22:
				var full := true
				for dx in width:
					var next := (y + height) * 40 + x + dx
					if used[next] != 0 or blocked[next] == 0:
						full = false
						break
				if not full:
					break
				height += 1
			for dy in height:
				for dx in width:
					used[(y + dy) * 40 + x + dx] = 1
			out.append(Rect2i(x, y, width, height))
	return out
