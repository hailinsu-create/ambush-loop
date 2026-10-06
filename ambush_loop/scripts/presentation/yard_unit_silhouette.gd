extends RefCounted

## Original procedural miniature kit; presentation only. Forward is local -Z.
static func build(body: MeshInstance3D, role: int, hostile: bool = false) -> void:
	var torso := BoxMesh.new()
	torso.size = Vector3(0.42 if role != 1 else 0.50, 0.50, 0.26)
	body.mesh = torso
	var uniform: Color = Color("b15e4e") if hostile else [Color("86936e"), Color("65776f"), Color("738391")][clampi(role, 0, 2)]
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = uniform
	cloth.roughness = 0.94
	body.material_override = cloth
	var equipment := StandardMaterial3D.new()
	equipment.albedo_color = Color("303c3d")
	equipment.roughness = 0.88
	var helmet := MeshInstance3D.new()
	helmet.name = "Helmet"
	var head := SphereMesh.new()
	head.radius = 0.18
	head.height = 0.32
	head.radial_segments = 12
	head.rings = 6
	helmet.mesh = head
	helmet.position = Vector3(0.0, 0.40, 0.0)
	helmet.material_override = cloth
	body.add_child(helmet)
	_part(body, "LeftBoot", Vector3(0.15, 0.37, 0.20), Vector3(-0.12, -0.42, -0.02), equipment)
	_part(body, "RightBoot", Vector3(0.15, 0.37, 0.20), Vector3(0.12, -0.42, -0.02), equipment)
	_part(body, "LeftArm", Vector3(0.13, 0.30, 0.15), Vector3(-0.25, -0.02, -0.06), cloth)
	_part(body, "RightArm", Vector3(0.13, 0.30, 0.15), Vector3(0.25, -0.02, -0.06), cloth)
	var weapon_length := 0.65 if role == 2 else (0.48 if role == 1 or hostile else 0.24)
	_part(body, "Weapon", Vector3(0.08, 0.08, weapon_length), Vector3(0.21, 0.04, -0.22 - weapon_length * 0.25), equipment)
	_part(body, "Backpack", Vector3(0.32 if role == 1 else 0.22, 0.34, 0.15), Vector3(0.0, 0.0, 0.20), equipment)


static func _part(body: MeshInstance3D, title: String, size: Vector3, at: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = at
	part.material_override = material
	body.add_child(part)
