extends Node3D

const Assets := preload("res://scripts/presentation/asset_library.gd")
var asset_id := ""
var lod := -1
var model: Node3D
var pivot: Node3D


func set_asset(id: String, detail: int) -> bool:
	if asset_id == id and lod == detail and model != null:
		return true
	if model != null:
		model.free()
	model = Assets.instantiate(id, detail)
	asset_id = id
	lod = detail
	pivot = null
	if model == null:
		return false
	add_child(model)
	var entry := Assets.asset_record(id)
	var moving: Dictionary = entry.get("moving_nodes", {})
	if moving.has("lid_pivot"):
		pivot = model.find_child(str(moving.lid_pivot.node), true, false) as Node3D
	return true


func set_lid(progress: float) -> void:
	if pivot == null:
		return
	var entry := Assets.asset_record(asset_id)
	var motion: Dictionary = entry.moving_nodes.lid_pivot
	pivot.rotation_degrees.x = lerpf(float(motion.range[0]), float(motion.range[1]), clampf(progress, 0.0, 1.0))


static func model_for(group: String, item: Dictionary) -> String:
	match group:
		"stashes", "environment_objects":
			var kind := str(item.get("kind", ""))
			if WeaponCatalog.is_firearm(kind):
				return "env_gun_case"
			if kind == "ammo":
				return "env_ammo_can"
			return "env_rations_crate" if kind == "decoy" else "env_yard_crate"
		"covers": return "sandbag_stack"
		"barrels": return "oil_drum"
		"mines", "tripwires": return "mine"
		"grenades": return "grenade"
		"decoys": return "decoy"
		"loot":
			var kind := str(item.get("kind", "ammo"))
			if kind == "body":
				return "" # Paired corpse presentation belongs to the R5 slice.
			if WeaponCatalog.is_firearm(kind):
				return WeaponCatalog.resolve_crate_kind(kind, "yard", 0)
			return "ammo_pack" if kind == "ammo" else (kind if Assets.has_asset(kind) else "ammo_pack")
	return ""
