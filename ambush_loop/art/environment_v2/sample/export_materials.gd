extends SceneTree
## Material resource export for candidate adoption; never modifies shared resources.
func _initialize() -> void:
	var material := StandardMaterial3D.new()
	material.resource_name = "environment_v2_atlas"
	material.albedo_texture = load("res://art/environment_v2/textures/environment_v2_albedo.png")
	material.normal_enabled = true
	material.normal_texture = load("res://art/environment_v2/textures/environment_v2_normal.png")
	material.normal_scale = 0.45
	material.roughness_texture = load("res://art/environment_v2/textures/environment_v2_orm.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture = material.roughness_texture
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	material.metallic = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	DirAccess.make_dir_recursive_absolute("res://art/environment_v2/materials")
	var err := ResourceSaver.save(material,"res://art/environment_v2/materials/environment_v2_atlas.tres")
	if err!=OK:
		push_error("Material save failed")
		quit(1)
		return
	var glow := StandardMaterial3D.new()
	glow.resource_name = "environment_v2_emission"
	glow.albedo_color = Color("ffd09b")
	glow.emission_enabled = true
	glow.emission = Color("ffa256")
	glow.emission_energy_multiplier = 1.4
	err = ResourceSaver.save(glow,"res://art/environment_v2/materials/environment_v2_emission.tres")
	canonicalize("res://art/environment_v2/materials/environment_v2_atlas.tres")
	canonicalize("res://art/environment_v2/materials/environment_v2_emission.tres")
	print("ENVIRONMENT_MATERIALS_EXPORTED ",err)
	quit(0 if err==OK else 1)

func canonicalize(path: String) -> void:
	# ResourceSaver creates random suffixes for external-resource labels.
	# References use exact paths; normalize these labels for byte reproducibility.
	var contents := FileAccess.get_file_as_string(path)
	var regex := RegEx.create_from_string('"[0-9]+_[a-z0-9]+"')
	var matches := regex.search_all(contents)
	for found in matches:
		var id := found.get_string()
		contents = contents.replace(id,id.get_slice("_",0)+'"')
	var out := FileAccess.open(path,FileAccess.WRITE)
	out.store_string(contents)
