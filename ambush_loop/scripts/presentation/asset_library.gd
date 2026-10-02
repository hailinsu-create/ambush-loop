extends RefCounted

## One shared atlas resource across all GLBs; source meshes contain UVs and named
## slots only, so textures are not duplicated in each model or in GPU memory.
static var _atlas: StandardMaterial3D
static var _emission: StandardMaterial3D


static func release_materials() -> void:
	_atlas = null
	_emission = null


static func _materials() -> void:
	if _atlas != null:
		return
	_atlas = StandardMaterial3D.new()
	_atlas.resource_name = "YardSharedAtlas"
	_atlas.albedo_texture = load("res://art/v2/textures/yard_atlas_albedo.png")
	_atlas.normal_enabled = true
	_atlas.normal_texture = load("res://art/v2/textures/yard_atlas_normal.png")
	_atlas.normal_scale = 0.45
	_atlas.roughness_texture = load("res://art/v2/textures/yard_atlas_orm.png")
	_atlas.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	_atlas.metallic_texture = _atlas.roughness_texture
	_atlas.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	_atlas.metallic = 1.0
	_atlas.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_emission = StandardMaterial3D.new()
	_emission.albedo_color = Color("ffd5a2")
	_emission.emission_enabled = true
	_emission.emission = Color("ff9b47")
	_emission.emission_energy_multiplier = 2.0


static func instantiate(asset_id: String, lod: int = 0) -> Node3D:
	_materials()
	var path := "res://art/v2/models/%s_lod%d.glb" % [asset_id, lod]
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("ASSET_NOT_FOUND " + path)
		return Node3D.new()
	var node := packed.instantiate() as Node3D
	node.set_meta("asset_id", asset_id)
	_apply(node)
	return node


static func _apply(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(surface)
			node.set_surface_override_material(surface, _emission if original != null and original.resource_name == "v2_lamp_emission" else _atlas)
	for child in node.get_children():
		_apply(child)
