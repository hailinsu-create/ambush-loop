extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("ASSET_PACK: " + message)


func _run() -> void:
	var physical_root := OS.get_env("AMBUSH_ASSET_PACK_ROOT")
	_check(not physical_root.is_empty() and DirAccess.get_files_at(physical_root).is_empty(), "probe has no physical project files to conceal missing packed resources")
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/v2/static_equipment_manifest.json"))
	_check(doc.assets.size() == 15, "equipment manifest is included in the pack")
	_check(FileAccess.file_exists("res://art/v2/manifest.json"), "yard manifest is included in the pack")
	var actor := Assets.material_for_slot("v2_actor_atlas")
	_check(actor.albedo_texture != null and actor.normal_texture != null and actor.roughness_texture != null, "external shared atlas textures load from the pack")
	for entry in doc.assets:
		for lod in entry.lods.size():
			var model := Assets.instantiate(entry.asset_id, lod)
			_check(model != null and _meshes(model) > 0, "accepted equipment scene loads through the packaged manifest")
			if model != null:
				model.free()
	var yard := Assets.instantiate("supply_crate")
	_check(yard != null and _meshes(yard) > 0 and not Assets.has_asset("operator_rifle"), "pack retains the old yard and excludes unaccepted characters")
	if yard != null:
		yard.free()
	Assets.release_materials()
	root.get_node("AudioDirector")._stop_music_hard()
	await process_frame
	print("ASSET_PACK_OK" if failures == 0 else "ASSET_PACK_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)


func _meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	if node == null:
		return 0
	for child in node.get_children():
		count += _meshes(child)
	return count
