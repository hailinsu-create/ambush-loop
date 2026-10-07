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
	body.set_meta("uniform", uniform)
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
	var label := Label3D.new()
	label.name = "OcclusionIdentity"
	label.position = Vector3(0, 0.72, 0)
	label.font_size = 24
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color("ffd098") if hostile else Color("a9ded3")
	body.add_child(label)
	var shadow := MeshInstance3D.new()
	shadow.name = "FootContact"
	var disk := CylinderMesh.new()
	disk.top_radius = 0.27
	disk.bottom_radius = 0.27
	disk.height = 0.01
	disk.radial_segments = 12
	shadow.mesh = disk
	shadow.position.y = -0.665
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shade := StandardMaterial3D.new()
	shade.albedo_color = Color("1a2223", 0.38)
	shade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = shade
	body.add_child(shadow)


static func pose(body: MeshInstance3D, title: String, alive: bool, moving: bool, searching: bool, aiming: bool, tick: int) -> void:
	## Pose only; no timers, gameplay mutation, or per-frame resources.
	var stride := sin(float(tick) * 0.45) * 0.45 if moving and alive else 0.0
	body.get_node("LeftBoot").rotation.x = stride
	body.get_node("RightBoot").rotation.x = -stride
	body.get_node("LeftArm").rotation.x = -0.7 if searching else (-0.3 if aiming else -stride * 0.5)
	body.get_node("RightArm").rotation.x = -0.7 if searching else (-0.3 if aiming else stride * 0.5)
	body.get_node("Helmet").rotation.x = 0.3 if searching else 0.0
	body.rotation.z = 1.35 if not alive else 0.0
	body.get_node("FootContact").visible = alive
	var label: Label3D = body.get_node("OcclusionIdentity")
	label.text = title + (" · 开匣…" if searching else (" · 倒地" if not alive else ""))
	var weapon: MeshInstance3D = body.get_node("Weapon")
	weapon.visible = not searching
	var fire_age := tick - int(body.get_meta("fire_tick", -1000))
	weapon.rotation.x = -0.15 * (1.0 - float(fire_age) / 6.0) if fire_age >= 0 and fire_age < 6 else 0.0
	var hit_age := tick - int(body.get_meta("hit_tick", -1000))
	(body.material_override as StandardMaterial3D).albedo_color = Color("f2c6a8") if hit_age >= 0 and hit_age < 6 else body.get_meta("uniform")


static func _part(body: MeshInstance3D, title: String, size: Vector3, at: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = at
	part.material_override = material
	body.add_child(part)
