extends RefCounted

## Manifest paths are the accepted library boundary. Actor and yard slots have
## distinct shared materials; a model never silently acquires the wrong atlas.
const MANIFESTS := ["res://art/v2/manifest.json", "res://art/v2/static_equipment_manifest.json"]
static var _atlas: StandardMaterial3D
static var _emission: StandardMaterial3D
static var _actor_atlas: StandardMaterial3D
static var _catalog: Dictionary = {}
static var _catalog_loaded := false


static func release_materials() -> void:
	_atlas = null
	_emission = null
	_actor_atlas = null
	_catalog.clear()
	_catalog_loaded = false


static func asset_record(asset_id: String) -> Dictionary:
	_read_catalog()
	return _catalog.get(asset_id, {}).duplicate(true)


static func has_asset(asset_id: String, lod: int = 0) -> bool:
	return not model_path(asset_id, lod).is_empty()


static func model_path(asset_id: String, lod: int = 0) -> String:
	var entry := asset_record(asset_id)
	var lods: Array = entry.get("lods", [])
	if lod < 0 or lod >= lods.size():
		return ""
	return "res://" + str(lods[lod].path)


static func _read_catalog() -> void:
	if _catalog_loaded:
		return
	_catalog_loaded = true
	var path_rule := RegEx.create_from_string("^art/v2/models/[a-z0-9_]+_lod[0-2]\\.glb$")
	for path in MANIFESTS:
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not doc is Dictionary or int(doc.get("schema", 0)) != 1:
			push_error("ASSET_MANIFEST_INVALID " + path)
			continue
		for entry in doc.get("assets", []):
			var id := str(entry.get("asset_id", ""))
			if id.is_empty() or _catalog.has(id):
				push_error("ASSET_ID_INVALID " + id)
				continue
			var valid: bool = not entry.get("lods", []).is_empty()
			for i in entry.get("lods", []).size():
				var model := str(entry.lods[i].get("path", ""))
				valid = valid and path_rule.search(model) != null and model == "art/v2/models/%s_lod%d.glb" % [id, i]
			if valid:
				_catalog[id] = entry.duplicate(true)
			else:
				push_error("ASSET_PATH_INVALID " + id)


static func material_for_slot(slot: String) -> StandardMaterial3D:
	match slot:
		"", "v2_shared_atlas":
			if _atlas == null:
				_atlas = _atlas_material("YardSharedAtlas", "yard", 0.45)
			return _atlas
		"v2_actor_atlas":
			if _actor_atlas == null:
				_actor_atlas = _atlas_material("ActorSharedAtlas", "actor", 0.4)
			return _actor_atlas
		"v2_lamp_emission":
			if _emission == null:
				_emission = StandardMaterial3D.new()
				_emission.albedo_color = Color("ffd5a2")
				_emission.emission_enabled = true
				_emission.emission = Color("ff9b47")
				_emission.emission_energy_multiplier = 2.0
			return _emission
		_:
			return null


static func _atlas_material(name: String, prefix: String, normal_scale: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = name
	material.albedo_texture = load("res://art/v2/textures/%s_atlas_albedo.png" % prefix)
	material.normal_enabled = true
	material.normal_texture = load("res://art/v2/textures/%s_atlas_normal.png" % prefix)
	material.normal_scale = normal_scale
	material.roughness_texture = load("res://art/v2/textures/%s_atlas_orm.png" % prefix)
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture = material.roughness_texture
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	material.metallic = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material


static func instantiate(asset_id: String, lod: int = 0) -> Node3D:
	var path := model_path(asset_id, lod)
	if path.is_empty():
		push_error("ASSET_NOT_REGISTERED %s lod=%d" % [asset_id, lod])
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("ASSET_NOT_FOUND " + path)
		return null
	var node := packed.instantiate() as Node3D
	if node == null:
		push_error("ASSET_ROOT_INVALID " + path)
		return null
	node.set_meta("asset_id", asset_id)
	node.set_meta("asset_lod", lod)
	if not _apply(node):
		node.free()
		return null
	return node


static func _apply(node: Node) -> bool:
	var valid := true
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			var original: Material = node.mesh.surface_get_material(surface)
			var slot := original.resource_name if original != null else ""
			var mapped := material_for_slot(slot)
			if mapped == null:
				push_error("ASSET_MATERIAL_UNMAPPED " + slot)
				valid = false
			else:
				node.set_surface_override_material(surface, mapped)
	for child in node.get_children():
		valid = _apply(child) and valid
	return valid
