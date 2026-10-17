extends RefCounted
class_name G3Assets

## Loads G3 high-detail yard / unit / weapon textures from assets/g3/ (WebP).

const BASE := "res://assets/g3/"

var tile_mud: Texture2D
var tile_grass: Texture2D
var tile_cobble: Texture2D
var tile_planks: Texture2D
var tile_stonewall: Texture2D
var tile_roof_slate: Texture2D
var tile_roof_shingle: Texture2D
var props: Dictionary = {} ## name → Texture2D
var units: Dictionary = {} ## name → Texture2D
var weapon_icons: Dictionary = {} ## id → Texture2D
var weapon_sprites: Dictionary = {} ## id → Texture2D
var lantern_glow: Texture2D
var drop_shadow: Texture2D
var high_edge: Texture2D
var vignette: Texture2D
var moonlight_tint: Texture2D
var edge_masks: Dictionary = {} ## n/e/s/w → Texture2D


func load_all() -> void:
	tile_mud = _load("tiles/mud.webp")
	tile_grass = _load("tiles/grass.webp")
	tile_cobble = _load("tiles/cobble.webp")
	tile_planks = _load("tiles/planks.webp")
	tile_stonewall = _load("tiles/stonewall.webp")
	tile_roof_slate = _load("tiles/roof_slate.webp")
	tile_roof_shingle = _load("tiles/roof_shingle.webp")
	for name in [
		"sandbag_curve", "sandbag_straight", "ammo_crate", "crate_stack",
		"barrel", "hay_bale", "cart", "shed_roof",
	]:
		props[name] = _load("props/%s.webp" % name)
	for name in [
		"friendly_kar98k", "friendly_mp40", "friendly_mg42", "friendly_grenade",
		"enemy_rifle", "enemy_smg", "enemy_mg", "enemy_officer",
	]:
		units[name] = _load("units/%s.webp" % name)
	for wid in ["kar98k", "mp40", "mg42", "grenade", "mine"]:
		weapon_icons[wid] = _load("weapons/icons/%s.webp" % wid)
		weapon_sprites[wid] = _load("weapons/sprites/%s.webp" % wid)
	lantern_glow = _load("fx/lantern_glow.webp")
	drop_shadow = _load("fx/drop_shadow.webp")
	high_edge = _load("fx/high_edge.webp")
	vignette = _load("fx/vignette.webp")
	moonlight_tint = _load("fx/moonlight_tint.webp")
	for d in ["n", "s", "e", "w"]:
		edge_masks[d] = _load("masks/edge_%s.webp" % d)


static func referenced_texture_paths() -> Array:
	var out: Array = []
	for rel in [
		"tiles/mud.webp", "tiles/grass.webp", "tiles/cobble.webp", "tiles/planks.webp",
		"tiles/stonewall.webp", "tiles/roof_slate.webp", "tiles/roof_shingle.webp",
		"fx/lantern_glow.webp", "fx/drop_shadow.webp", "fx/high_edge.webp",
		"fx/vignette.webp", "fx/moonlight_tint.webp",
		"masks/edge_n.webp", "masks/edge_s.webp", "masks/edge_e.webp", "masks/edge_w.webp",
	]:
		out.append(BASE + rel)
	for name in [
		"sandbag_curve", "sandbag_straight", "ammo_crate", "crate_stack",
		"barrel", "hay_bale", "cart", "shed_roof",
	]:
		out.append(BASE + "props/%s.webp" % name)
	for name in [
		"friendly_kar98k", "friendly_mp40", "friendly_mg42", "friendly_grenade",
		"enemy_rifle", "enemy_smg", "enemy_mg", "enemy_officer",
	]:
		out.append(BASE + "units/%s.webp" % name)
	for wid in ["kar98k", "mp40", "mg42", "grenade", "mine"]:
		out.append(BASE + "weapons/icons/%s.webp" % wid)
		out.append(BASE + "weapons/sprites/%s.webp" % wid)
	return out


func all_textures_ok() -> bool:
	if tile_mud == null or tile_roof_slate == null or tile_stonewall == null:
		return false
	if lantern_glow == null or vignette == null:
		return false
	for wid in ["kar98k", "mp40", "mg42", "grenade", "mine"]:
		if weapon_icons.get(wid) == null:
			return false
	for name in ["friendly_kar98k", "enemy_rifle", "sandbag_straight", "shed_roof"]:
		if name.begins_with("friendly") or name.begins_with("enemy"):
			if units.get(name) == null:
				return false
		elif props.get(name) == null and units.get(name) == null:
			# props check separately
			pass
	if props.get("sandbag_straight") == null or props.get("shed_roof") == null:
		return false
	return true


func friendly_unit_for_weapon(weapon_id: String) -> Texture2D:
	match weapon_id:
		"kar98k":
			return units.get("friendly_kar98k", null)
		"mp40":
			return units.get("friendly_mp40", null)
		"mg42":
			return units.get("friendly_mg42", null)
		"grenade":
			return units.get("friendly_grenade", null)
		_:
			return units.get("friendly_kar98k", null)


func _load(rel: String) -> Texture2D:
	var path := BASE + rel
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("G3Assets missing: %s" % path)
	return tex
