extends RefCounted
class_name G1Assets

## Loads G1 readability textures once for the greybox view.

const BASE := "res://assets/g1/"

var tile_ground: Texture2D
var tile_high: Texture2D
var tile_wall: Texture2D
var tile_low_cover: Texture2D
var tile_ramp: Texture2D
var friendly: Texture2D
var friendly_high: Texture2D
var enemy: Texture2D
var sentry: Texture2D
var occlusion: Texture2D
var marker_line: Texture2D
var mine: Texture2D
var threat_slot: Texture2D
var click_preview: Texture2D
var alert_icons: Dictionary = {}
var trigger_icons: Dictionary = {}


func load_all() -> void:
	tile_ground = _load("tiles/tile_ground.png")
	tile_high = _load("tiles/tile_high.png")
	tile_wall = _load("tiles/tile_wall.png")
	tile_low_cover = _load("tiles/tile_low_cover.png")
	tile_ramp = _load("tiles/tile_ramp.png")
	friendly = _load("units/friendly.png")
	friendly_high = _load("units/friendly_high.png")
	enemy = _load("units/enemy.png")
	sentry = _load("units/sentry.png")
	occlusion = _load("cones/occlusion_gap.png")
	marker_line = _load("markers/marker_line.png")
	mine = _load("markers/mine.png")
	threat_slot = _load("markers/threat_slot.png")
	click_preview = _load("markers/click_preview.png")
	alert_icons = {
		"quiet": _load("icons/alert_quiet.png"),
		"suspicious": _load("icons/alert_suspicious.png"),
		"area_alert": _load("icons/alert_area.png"),
		"global_alert": _load("icons/alert_global.png"),
	}
	trigger_icons = {
		"see_first_enemy": _load("icons/trigger_see_first_enemy.png"),
		"mine_detonate": _load("icons/trigger_mine.png"),
		"cross_marker": _load("icons/trigger_cross_marker.png"),
		"manual": _load("icons/trigger_manual.png"),
	}


func _load(rel: String) -> Texture2D:
	var path := BASE + rel
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("G1Assets missing: %s" % path)
	return tex
