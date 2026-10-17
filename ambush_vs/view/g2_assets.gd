extends RefCounted
class_name G2Assets

## Loads G2 yard / weapon / SFX paths once. Original procedural assets under assets/g2/.

const BASE := "res://assets/g2/"
const SFX_BASE := "res://assets/g2/sfx/"

var tile_dirt: Texture2D
var tile_mud: Texture2D
var tile_cobble: Texture2D
var tile_grass: Texture2D
var tile_wall: Texture2D
var tile_fence: Texture2D
var tile_high: Texture2D
var tile_ramp: Texture2D
var tile_low_cover: Texture2D
var prop_shed: Texture2D
var prop_crate: Texture2D
var prop_sandbag: Texture2D
var prop_barrel: Texture2D
var prop_ammo_box: Texture2D
var weapon_icons: Dictionary = {} ## id → Texture2D
var weapon_sprites: Dictionary = {} ## id → Texture2D
var weapon_units: Dictionary = {} ## id → Texture2D
var sfx_streams: Dictionary = {} ## cue → AudioStream


func load_all() -> void:
	tile_dirt = _load_tex("tiles/dirt.png")
	tile_mud = _load_tex("tiles/mud.png")
	tile_cobble = _load_tex("tiles/cobble.png")
	tile_grass = _load_tex("tiles/grass.png")
	tile_wall = _load_tex("tiles/wall.png")
	tile_fence = _load_tex("tiles/fence.png")
	tile_high = _load_tex("tiles/high.png")
	tile_ramp = _load_tex("tiles/ramp.png")
	tile_low_cover = _load_tex("tiles/tile_low_cover.png")
	prop_shed = _load_tex("props/shed.png")
	prop_crate = _load_tex("props/crate.png")
	prop_sandbag = _load_tex("props/sandbag.png")
	prop_barrel = _load_tex("props/barrel.png")
	prop_ammo_box = _load_tex("props/ammo_box.png")
	for wid in ["kar98k", "mp40", "mg42", "grenade", "mine"]:
		weapon_icons[wid] = _load_tex("weapons/icons/%s.png" % wid)
		weapon_sprites[wid] = _load_tex("weapons/sprites/%s.png" % wid)
		weapon_units[wid] = _load_tex("weapons/units/%s.png" % wid)
	for cue in referenced_sfx_cues():
		sfx_streams[cue] = _load_sfx("%s.wav" % cue)


static func referenced_sfx_cues() -> Array:
	return [
		"weapon_kar98k",
		"weapon_mp40",
		"weapon_mg42",
		"weapon_grenade_throw",
		"weapon_grenade_detonate",
		"weapon_mine_detonate",
		"foot_dirt",
		"foot_mud",
		"foot_cobble",
		"foot_grass",
		"alert_quiet",
		"alert_suspicious",
		"alert_area",
		"alert_global",
		"ui_tap",
		"ambush_trigger",
	]


static func referenced_texture_paths() -> Array:
	var out: Array = []
	for rel in [
		"tiles/dirt.png", "tiles/mud.png", "tiles/cobble.png", "tiles/grass.png",
		"tiles/wall.png", "tiles/fence.png", "tiles/high.png", "tiles/ramp.png",
		"tiles/tile_ground.png", "tiles/tile_high.png", "tiles/tile_wall.png",
		"tiles/tile_low_cover.png", "tiles/tile_ramp.png",
		"props/shed.png", "props/crate.png", "props/sandbag.png",
		"props/barrel.png", "props/ammo_box.png",
	]:
		out.append(BASE + rel)
	for wid in ["kar98k", "mp40", "mg42", "grenade", "mine"]:
		out.append(BASE + "weapons/icons/%s.png" % wid)
		out.append(BASE + "weapons/sprites/%s.png" % wid)
		out.append(BASE + "weapons/units/%s.png" % wid)
	return out


func all_textures_ok() -> bool:
	if tile_dirt == null or tile_high == null or tile_wall == null:
		return false
	for wid in ["kar98k", "mp40", "mg42", "grenade", "mine"]:
		if weapon_icons.get(wid) == null or weapon_units.get(wid) == null:
			return false
	return true


func all_sfx_ok() -> bool:
	for cue in referenced_sfx_cues():
		if sfx_streams.get(cue) == null:
			return false
	return true


func _load_tex(rel: String) -> Texture2D:
	var path := BASE + rel
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("G2Assets missing tex: %s" % path)
	return tex


func _load_sfx(rel: String) -> AudioStream:
	var path := SFX_BASE + rel
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("G2Assets missing sfx: %s" % path)
	return stream
