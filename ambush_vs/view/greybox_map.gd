extends Control
class_name GreyboxMap

## Thin orthographic top-down view over sim state. No gameplay logic.

const SimGeom := preload("res://sim/geom.gd")
const SimConstants := preload("res://sim/constants.gd")
const G1AssetsScript := preload("res://view/g1_assets.gd")
const G2AssetsScript := preload("res://view/g2_assets.gd")
const G3AssetsScript := preload("res://view/g3_assets.gd")

signal cell_tapped(cell: Vector2i)
signal cell_dragged(cell: Vector2i, world_dir: Vector2)
signal unit_selected(op_id: String)

enum ArtMode { G3, G2, G1 }

## World-space UV: texture spans this many cells (keeps native detail).
const G3_TEX_CELLS := 4.0
const G3_UNIT_SCALE := 1.6

var assets: G1Assets
var g2: G2Assets
var g3: G3Assets
var cell_px: float = 36.0
var grid_w: int = 24
var grid_h: int = 16
var level: Dictionary = {}
var grid = null ## SimGrid
var weapons: Dictionary = {}

## Snapshot from controller / sim (view-only).
var operators: Array = []
var enemies: Array = []
var sentries: Array = []
var patrols: Array = []
var mines: Array = []
var grenade_plans: Array = []
var trigger: Dictionary = {}
var alert: String = "quiet"
var phase: String = "setup"
var preview_cell: Vector2i = Vector2i(-1, -1)
var preview_seers: Array = []
var show_sectors: bool = true
var show_cones: bool = true
var art_mode: ArtMode = ArtMode.G3 ## default G3; cycle G3→G2→G1
var use_g2_art: bool = false ## legacy; derived from art_mode
var selected_op_id: String = ""
var threat_slot_cells: Array = [] ## Vector2i
var night: bool = true
var _high_cells: Dictionary = {} ## "x,y" → true

var _dragging_op: String = ""
var _drag_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	assets = G1AssetsScript.new()
	assets.load_all()
	g2 = G2AssetsScript.new()
	g2.load_all()
	g3 = G3AssetsScript.new()
	g3.load_all()
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(grid_w * cell_px, grid_h * cell_px)


func configure(level_data: Dictionary, sim_grid, weapons_table: Dictionary) -> void:
	level = level_data
	grid = sim_grid
	weapons = weapons_table
	grid_w = int(level.get("grid", {}).get("width", 24))
	grid_h = int(level.get("grid", {}).get("height", 16))
	night = bool(level.get("night", true))
	_collect_threat_slots()
	_index_high_cells()
	_fit_cell_px()
	queue_redraw()


func _index_high_cells() -> void:
	_high_cells.clear()
	for hs in level.get("high_slots", []):
		for c in hs.get("cells", []):
			_high_cells["%d,%d" % [int(c["x"]), int(c["y"])]] = str(hs.get("id", ""))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_cell_px()
		queue_redraw()


func _fit_cell_px() -> void:
	if grid_w <= 0 or grid_h <= 0:
		return
	var avail := size
	if avail.x < 8.0 or avail.y < 8.0:
		avail = get_parent_area_size() if get_parent() else Vector2(960, 640)
	if avail.x < 8.0 or avail.y < 8.0:
		avail = Vector2(960, 640)
	cell_px = minf(avail.x / float(grid_w), avail.y / float(grid_h))
	custom_minimum_size = Vector2(grid_w * cell_px, grid_h * cell_px)


func apply_snapshot(snap: Dictionary) -> void:
	operators = snap.get("operators", [])
	enemies = snap.get("enemies", [])
	sentries = snap.get("sentries", [])
	patrols = snap.get("patrols", [])
	mines = snap.get("mines", [])
	grenade_plans = snap.get("grenade_plans", [])
	trigger = snap.get("trigger", {})
	alert = str(snap.get("alert", "quiet"))
	phase = str(snap.get("phase", "setup"))
	preview_cell = snap.get("preview_cell", Vector2i(-1, -1))
	preview_seers = snap.get("preview_seers", [])
	selected_op_id = str(snap.get("selected_op_id", selected_op_id))
	queue_redraw()


func cell_to_screen(x: float, y: float) -> Vector2:
	## origin x0_west_y0_south → screen y flips.
	return Vector2((x + 0.5) * cell_px, (float(grid_h) - y - 0.5) * cell_px)


func screen_to_cell(pos: Vector2) -> Vector2i:
	var gx := int(floor(pos.x / cell_px))
	var gy_screen := int(floor(pos.y / cell_px))
	var gy := grid_h - 1 - gy_screen
	return Vector2i(gx, gy)


func _collect_threat_slots() -> void:
	## threatens_slots are ambush_slot ids (ADR-ALERT F3); resolve to cells.
	threat_slot_cells.clear()
	var slot_to_cells: Dictionary = {} ## id → Array[Vector2i]
	for slot in level.get("ambush_slots", []):
		var sid := str(slot.get("id", ""))
		slot_to_cells[sid] = [Vector2i(int(slot["x"]), int(slot["y"]))]
	for hs in level.get("high_slots", []):
		var sid := str(hs.get("id", ""))
		if sid.is_empty():
			continue
		var arr: Array = []
		for c in hs.get("cells", []):
			arr.append(Vector2i(int(c["x"]), int(c["y"])))
		if not arr.is_empty():
			slot_to_cells[sid] = arr
	for src in [level.get("sentries", []), level.get("patrols", [])]:
		for obs in src:
			for sid in obs.get("threatens_slots", []):
				for cell in slot_to_cells.get(str(sid), []):
					threat_slot_cells.append(cell)


func set_use_g2_art(on: bool) -> void:
	## Legacy bridge: true → G2, false → G1 (does not select G3).
	art_mode = ArtMode.G2 if on else ArtMode.G1
	use_g2_art = on
	queue_redraw()


func set_art_mode(mode: ArtMode) -> void:
	art_mode = mode
	use_g2_art = mode == ArtMode.G2
	queue_redraw()


func cycle_art_mode() -> ArtMode:
	match art_mode:
		ArtMode.G3:
			art_mode = ArtMode.G2
		ArtMode.G2:
			art_mode = ArtMode.G1
		_:
			art_mode = ArtMode.G3
	use_g2_art = art_mode == ArtMode.G2
	queue_redraw()
	return art_mode


func art_mode_label() -> String:
	match art_mode:
		ArtMode.G3:
			return "G3"
		ArtMode.G2:
			return "G2"
		_:
			return "G1"


func _draw() -> void:
	if grid == null:
		return
	_draw_tiles()
	match art_mode:
		ArtMode.G3:
			_draw_g3_props()
			_draw_g3_grade()
		ArtMode.G2:
			_draw_night_dim()
			_draw_g2_props()
		_:
			pass
	# G1 readability overlays always on top of terrain/props.
	if show_cones:
		_draw_enemy_cones()
	if show_sectors:
		_draw_weapon_sectors()
	_draw_threat_slots()
	_draw_marker_and_mines()
	_draw_preview()
	_draw_units()
	_draw_alert_badge()


func _draw_tiles() -> void:
	for y in range(grid_h):
		for x in range(grid_w):
			var cell: Dictionary = grid.get_cell(x, y)
			var kind := str(cell.get("kind", "wall"))
			var tier := str(cell.get("tier", ""))
			var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
			var rect := Rect2(p, Vector2(cell_px, cell_px))
			if art_mode == ArtMode.G3 and g3 != null:
				_draw_g3_cell(cell, kind, tier, x, y, rect)
			else:
				var tex: Texture2D = _tile_tex_for(cell, kind, tier, x, y)
				if tex:
					draw_texture_rect(tex, rect, false)


func _surface_key(cell: Dictionary, kind: String, tier: String, x: int, y: int) -> String:
	if kind == "wall" or (bool(cell.get("blocks_all_los", false)) and kind != "structure"):
		return "stonewall"
	if kind == "structure":
		return "stonewall"
	if kind in ["ramp", "slope"]:
		return "planks"
	if tier == SimConstants.TIER_HIGH or kind == "high" or _high_cells.has("%d,%d" % [x, y]):
		var hid := str(_high_cells.get("%d,%d" % [x, y], ""))
		return "roof_shingle" if hid == "low_wall_pad" else "roof_slate"
	if kind in ["road", "gate_n", "gate_s", "gate_e"]:
		return "cobble"
	if kind == "alley":
		return "mud"
	if ((x + y * 3) % 5) == 0:
		return "grass"
	if ((x * 2 + y) % 7) == 0:
		return "planks"
	return "mud"


func _g3_tex(surface: String) -> Texture2D:
	match surface:
		"grass":
			return g3.tile_grass
		"cobble":
			return g3.tile_cobble
		"planks":
			return g3.tile_planks
		"stonewall":
			return g3.tile_stonewall
		"roof_slate":
			return g3.tile_roof_slate
		"roof_shingle":
			return g3.tile_roof_shingle
		_:
			return g3.tile_mud


func _draw_g3_cell(cell: Dictionary, kind: String, tier: String, x: int, y: int, rect: Rect2) -> void:
	var surf := _surface_key(cell, kind, tier, x, y)
	# Structures: ground under shed, not a grey wall fill.
	if kind == "structure":
		_draw_g3_world_sample(g3.tile_planks, x, y, rect)
		return
	if surf == "stonewall":
		_draw_g3_world_sample(g3.tile_stonewall, x, y, rect)
		# Height / thickness shadow along south edge (screen-bottom).
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.72), Vector2(rect.size.x, rect.size.y * 0.28)), Color(0, 0, 0, 0.35), true)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), Color(0, 0, 0, 0.25), true)
		return
	if surf.begins_with("roof"):
		# Drop shadow first so roof sits above neighbors.
		if g3.drop_shadow:
			draw_texture_rect(g3.drop_shadow, Rect2(rect.position + Vector2(3, 5), rect.size), false)
		_draw_g3_world_sample(_g3_tex(surf), x, y, rect)
		# Ridge line (gable) for concept readability.
		var mid_x := rect.position.x + rect.size.x * 0.5
		draw_line(Vector2(mid_x, rect.position.y + 2), Vector2(mid_x, rect.position.y + rect.size.y - 2), Color(0.12, 0.13, 0.16, 0.95), 2.0)
		# Eaves shadow along south.
		draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.78), Vector2(rect.size.x, rect.size.y * 0.22)), Color(0, 0, 0, 0.28), true)
		if g3.high_edge:
			draw_texture_rect(g3.high_edge, rect, false)
		return
	# Ground types — world-space UV + soft neighbor blend.
	_draw_g3_world_sample(_g3_tex(surf), x, y, rect)
	if surf in ["mud", "grass", "cobble", "planks"]:
		_blend_g3_edges(x, y, surf, rect)


func _draw_g3_world_sample(tex: Texture2D, cell_x: int, cell_y: int, dest: Rect2, modulate: Color = Color(1, 1, 1, 1)) -> void:
	if tex == null:
		return
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var uw := tw / G3_TEX_CELLS
	var vh := th / G3_TEX_CELLS
	var u0 := fposmod(float(cell_x) * uw, tw)
	var v0 := fposmod(float(cell_y) * vh, th)
	_draw_region_wrapped(tex, dest, u0, v0, uw, vh, tw, th, modulate)


func _draw_region_wrapped(
	tex: Texture2D, dest: Rect2, u0: float, v0: float, uw: float, vh: float, tw: float, th: float, modulate: Color
) -> void:
	## Seamless textures: split dest if the source region wraps the atlas edge.
	var u1 := u0 + uw
	var v1 := v0 + vh
	if u1 <= tw and v1 <= th:
		draw_texture_rect_region(tex, dest, Rect2(u0, v0, uw, vh), modulate)
		return
	var u_right := maxf(0.0, u1 - tw)
	var u_left := uw - u_right
	var v_bot := maxf(0.0, v1 - th)
	var v_top := vh - v_bot
	var x_split := dest.size.x * (u_left / uw) if u_right > 0.0 else dest.size.x
	var y_split := dest.size.y * (v_top / vh) if v_bot > 0.0 else dest.size.y
	# TL
	draw_texture_rect_region(
		tex,
		Rect2(dest.position, Vector2(x_split, y_split)),
		Rect2(u0, v0, u_left if u_right > 0.0 else uw, v_top if v_bot > 0.0 else vh),
		modulate
	)
	# TR
	if u_right > 0.0:
		draw_texture_rect_region(
			tex,
			Rect2(dest.position + Vector2(x_split, 0), Vector2(dest.size.x - x_split, y_split)),
			Rect2(0, v0, u_right, v_top if v_bot > 0.0 else vh),
			modulate
		)
	# BL
	if v_bot > 0.0:
		draw_texture_rect_region(
			tex,
			Rect2(dest.position + Vector2(0, y_split), Vector2(x_split, dest.size.y - y_split)),
			Rect2(u0, 0, u_left if u_right > 0.0 else uw, v_bot),
			modulate
		)
	# BR
	if u_right > 0.0 and v_bot > 0.0:
		draw_texture_rect_region(
			tex,
			Rect2(dest.position + Vector2(x_split, y_split), Vector2(dest.size.x - x_split, dest.size.y - y_split)),
			Rect2(0, 0, u_right, v_bot),
			modulate
		)


func _blend_g3_edges(x: int, y: int, surf: String, rect: Rect2) -> void:
	var dirs = [
		[0, 1, "n"],
		[0, -1, "s"],
		[-1, 0, "w"],
		[1, 0, "e"],
	]
	for d in dirs:
		var nx: int = x + int(d[0])
		var ny: int = y + int(d[1])
		if nx < 0 or ny < 0 or nx >= grid_w or ny >= grid_h:
			continue
		var ncell: Dictionary = grid.get_cell(nx, ny)
		var nkind := str(ncell.get("kind", "wall"))
		var ntier := str(ncell.get("tier", ""))
		var nsurf := _surface_key(ncell, nkind, ntier, nx, ny)
		if nsurf == surf or nsurf in ["stonewall", "roof_slate", "roof_shingle"]:
			continue
		if nsurf not in ["mud", "grass", "cobble", "planks"]:
			continue
		var ntex := _g3_tex(nsurf)
		if ntex == null:
			continue
		# Soft strip along shared edge only (not full-cell wash).
		var strip := rect
		var t := 0.32
		match str(d[2]):
			"n":
				strip = Rect2(rect.position, Vector2(rect.size.x, rect.size.y * t))
			"s":
				strip = Rect2(rect.position + Vector2(0, rect.size.y * (1.0 - t)), Vector2(rect.size.x, rect.size.y * t))
			"w":
				strip = Rect2(rect.position, Vector2(rect.size.x * t, rect.size.y))
			"e":
				strip = Rect2(rect.position + Vector2(rect.size.x * (1.0 - t), 0), Vector2(rect.size.x * t, rect.size.y))
		_draw_g3_world_sample(ntex, nx, ny, strip, Color(1, 1, 1, 0.40))


func _tile_tex_for(cell: Dictionary, kind: String, tier: String, x: int, y: int) -> Texture2D:
	if art_mode == ArtMode.G2 and g2 != null:
		if kind == "wall" or (bool(cell.get("blocks_all_los", false)) and kind != "structure"):
			return g2.tile_wall if g2.tile_wall else assets.tile_wall
		if kind == "structure":
			return g2.tile_wall if g2.tile_wall else assets.tile_wall
		if kind in ["ramp", "slope"]:
			return g2.tile_ramp if g2.tile_ramp else assets.tile_ramp
		if bool(cell.get("low_cover", false)):
			return g2.tile_low_cover if g2.tile_low_cover else assets.tile_low_cover
		if tier == SimConstants.TIER_HIGH or kind == "high":
			return g2.tile_high if g2.tile_high else assets.tile_high
		if kind in ["road", "gate_n", "gate_s", "gate_e"]:
			return g2.tile_cobble if g2.tile_cobble else assets.tile_ground
		if kind == "alley":
			return g2.tile_mud if g2.tile_mud else assets.tile_ground
		if ((x + y * 3) % 5) == 0:
			return g2.tile_grass if g2.tile_grass else assets.tile_ground
		return g2.tile_dirt if g2.tile_dirt else assets.tile_ground
	if kind in ["wall", "structure"] or bool(cell.get("blocks_all_los", false)):
		return assets.tile_wall
	if kind in ["ramp", "slope"]:
		return assets.tile_ramp
	if bool(cell.get("low_cover", false)):
		return assets.tile_low_cover
	if tier == SimConstants.TIER_HIGH or kind == "high":
		return assets.tile_high
	return assets.tile_ground


func _draw_night_dim() -> void:
	if not night:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(grid_w * cell_px, grid_h * cell_px)), Color(0.02, 0.04, 0.1, 0.22), true)


func _draw_g3_grade() -> void:
	## Moonlit but readable — very light cool wash (yard_concept), keep mud/grass/cobble hues.
	if not night:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(grid_w * cell_px, grid_h * cell_px)), Color(0.12, 0.16, 0.26, 0.05), true)
	if g3.vignette:
		draw_texture_rect(g3.vignette, Rect2(Vector2.ZERO, Vector2(grid_w * cell_px, grid_h * cell_px)), false, Color(1, 1, 1, 0.32))
	if g3.lantern_glow:
		# Few small warm lamps (shed / barn / crates) — not map-washing discs.
		for c in [Vector2i(5, 10), Vector2i(14, 7), Vector2i(11, 1)]:
			var p := Vector2(c.x * cell_px, (grid_h - 1 - c.y) * cell_px)
			var sz := cell_px * 0.85
			draw_texture_rect(
				g3.lantern_glow,
				Rect2(p + Vector2(cell_px * 0.5 - sz * 0.5, cell_px * 0.5 - sz * 0.5), Vector2(sz, sz)),
				false,
				Color(1.0, 0.72, 0.35, 0.95)
			)


func _draw_g3_props() -> void:
	if g3 == null:
		return
	for y in range(grid_h):
		for x in range(grid_w):
			var cell: Dictionary = grid.get_cell(x, y)
			var kind := str(cell.get("kind", ""))
			var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
			var rect := Rect2(p, Vector2(cell_px, cell_px))
			if kind == "structure":
				var shed: Texture2D = g3.props.get("shed_roof", null)
				if shed:
					if g3.drop_shadow:
						draw_texture_rect(g3.drop_shadow, Rect2(rect.position + Vector2(2, 4), rect.size), false)
					draw_texture_rect(shed, Rect2(rect.position - Vector2(cell_px * 0.05, cell_px * 0.08), rect.size * 1.1), false)
			if bool(cell.get("low_cover", false)):
				var bag_name := "sandbag_straight" if ((x + y) % 2) == 0 else "sandbag_curve"
				var bag: Texture2D = g3.props.get(bag_name, null)
				if bag == null:
					bag = g3.props.get("sandbag_straight", null)
				if bag:
					draw_texture_rect(bag, Rect2(p + Vector2(cell_px * 0.05, cell_px * 0.1), Vector2(cell_px * 0.9, cell_px * 0.8)), false)
	for s in level.get("supplies", []):
		var x := int(s.get("x", -1))
		var y := int(s.get("y", -1))
		if x < 0:
			continue
		var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
		var hid := bool(s.get("hidden", false))
		var tex: Texture2D = g3.props.get("ammo_crate" if hid else "crate_stack", null)
		if tex:
			draw_texture_rect(tex, Rect2(p + Vector2(cell_px * 0.1, cell_px * 0.1), Vector2(cell_px * 0.8, cell_px * 0.8)), false)
	var accents := [
		[Vector2i(9, 2), "barrel"],
		[Vector2i(14, 3), "barrel"],
		[Vector2i(8, 5), "hay_bale"],
		[Vector2i(16, 4), "cart"],
	]
	for a in accents:
		var c: Vector2i = a[0]
		var pname: String = a[1]
		var tex: Texture2D = g3.props.get(pname, null)
		if tex == null:
			continue
		var p := Vector2(c.x * cell_px, (grid_h - 1 - c.y) * cell_px)
		draw_texture_rect(tex, Rect2(p + Vector2(cell_px * 0.15, cell_px * 0.15), Vector2(cell_px * 0.7, cell_px * 0.7)), false)


func _draw_g2_props() -> void:
	if g2 == null:
		return
	for cell in level.get("cells", []):
		var kind := str(cell.get("kind", ""))
		var x := int(cell.get("x", -1))
		var y := int(cell.get("y", -1))
		if kind == "structure" and g2.prop_shed:
			var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
			draw_texture_rect(g2.prop_shed, Rect2(p, Vector2(cell_px, cell_px)), false)
	for s in level.get("supplies", []):
		var x := int(s.get("x", -1))
		var y := int(s.get("y", -1))
		if x < 0:
			continue
		var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
		var hid := bool(s.get("hidden", false))
		var tex: Texture2D = g2.prop_ammo_box if hid else g2.prop_crate
		if tex:
			draw_texture_rect(tex, Rect2(p + Vector2(cell_px * 0.1, cell_px * 0.1), Vector2(cell_px * 0.8, cell_px * 0.8)), false)
	if g2.prop_barrel:
		for c in [Vector2i(9, 2), Vector2i(14, 3)]:
			var p := Vector2(c.x * cell_px, (grid_h - 1 - c.y) * cell_px)
			draw_texture_rect(g2.prop_barrel, Rect2(p + Vector2(cell_px * 0.2, cell_px * 0.2), Vector2(cell_px * 0.6, cell_px * 0.6)), false)


func _observer_xy(obs: Dictionary) -> Vector2:
	if obs.has("x") and obs.has("y"):
		return Vector2(float(obs["x"]), float(obs["y"]))
	var wps: Array = obs.get("waypoints", [])
	if wps.size() > 0 and typeof(wps[0]) == TYPE_DICTIONARY:
		return Vector2(float(wps[0]["x"]), float(wps[0]["y"]))
	return Vector2.ZERO


func _draw_enemy_cones() -> void:
	for s in sentries:
		var sp := _observer_xy(s)
		var cone_s: Dictionary = s.get("cone", {})
		var ca := 0.11 if art_mode == ArtMode.G3 else 0.28
		var ce := 0.12 if art_mode == ArtMode.G3 else 0.35
		_draw_one_cone(
			sp.x, sp.y,
			float(cone_s.get("facing_deg", 0)),
			float(cone_s.get("angle_deg", 50)) * 0.5,
			float(cone_s.get("range_cells", 8)),
			str(s.get("tier", "ground")),
			Color(1.0, 0.55, 0.15, ca),
			Color(0.85, 0.3, 0.85, ce)
		)
	for p in patrols:
		var cone: Dictionary = p.get("cone", {})
		var facing := float(cone.get("facing_deg", 0))
		if alert == "area_alert" and p.has("alert_route") and typeof(p["alert_route"]) == TYPE_DICTIONARY:
			var ar: Dictionary = p["alert_route"]
			if ar.has("facing_deg"):
				facing = float(ar["facing_deg"])
		var pp := _observer_xy(p)
		var pa := 0.09 if art_mode == ArtMode.G3 else 0.22
		var pe := 0.11 if art_mode == ArtMode.G3 else 0.35
		_draw_one_cone(
			pp.x, pp.y, facing,
			float(cone.get("angle_deg", 50)) * 0.5,
			float(cone.get("range_cells", 6)),
			SimConstants.TIER_GROUND,
			Color(1.0, 0.55, 0.15, pa),
			Color(0.85, 0.3, 0.85, pe)
		)


func _draw_one_cone(
	ox: float, oy: float, facing: float, half: float, rng: float, otier: String,
	col_ground: Color, col_ext: Color
) -> void:
	## Ground-length wedge + distinct ×1.5 high-target extension outline.
	_draw_wedge(ox, oy, facing, half, rng, col_ground, false)
	if art_mode == ArtMode.G3:
		# Readable outline so light fill does not rely on opaque blocks.
		var outline := Color(col_ground.r, col_ground.g, col_ground.b, minf(0.85, col_ground.a + 0.55))
		_draw_wedge(ox, oy, facing, half, rng, outline, true)
	if night:
		_draw_wedge(ox, oy, facing, half, rng * SimConstants.SILHOUETTE_MUL, col_ext, true)


func _draw_wedge(ox: float, oy: float, facing: float, half: float, rng: float, col: Color, outline_only: bool) -> void:
	var origin := cell_to_screen(ox, oy)
	var pts := PackedVector2Array()
	pts.append(origin)
	var steps := maxi(8, int(half * 2.0))
	for i in range(steps + 1):
		var a := facing - half + (2.0 * half) * (float(i) / float(steps))
		var rad := deg_to_rad(a)
		# Screen: +x east, +y screen-down = -world-y; world 0°=east CCW.
		var wx := (ox + 0.5) + rng * cos(rad)
		var wy := (oy + 0.5) + rng * sin(rad)
		pts.append(Vector2(wx * cell_px, (float(grid_h) - wy) * cell_px))
	if outline_only:
		for i in range(1, pts.size()):
			draw_line(pts[i - 1] if i > 1 else pts[0], pts[i], col, 2.0)
		if pts.size() > 1:
			draw_line(pts[0], pts[1], col, 2.0)
			draw_line(pts[0], pts[pts.size() - 1], col, 2.0)
	else:
		draw_colored_polygon(pts, col)


func _draw_weapon_sectors() -> void:
	if grid == null:
		return
	for op in operators:
		if not op.get("alive", true):
			continue
		var wid := str(op.get("weapon_id", ""))
		if wid in ["grenade", "mine"]:
			continue
		var w: Dictionary = weapons.get(wid, {})
		if w.is_empty():
			continue
		var half := float(w.get("sector_deg", 0)) * 0.5
		var rng := float(w.get("max_range", 0))
		if half <= 0.0 or rng <= 0.0:
			continue
		var ox := float(op["x"])
		var oy := float(op["y"])
		var facing := float(op["facing_deg"])
		var tier := str(op.get("tier", "ground"))
		if art_mode == ArtMode.G3:
			# No per-cell green/grey fills — outline + soft wedge tint only (≤15%).
			_draw_wedge(ox, oy, facing, half, rng, Color(0.40, 0.90, 0.50, 0.10), false)
			_draw_wedge(ox, oy, facing, half, rng, Color(0.45, 0.95, 0.55, 0.72), true)
			continue
		# G1/G2: cell fills show clear vs blocked (preview = sim).
		var r_ceil := int(ceil(rng)) + 1
		var oxi := int(floor(ox))
		var oyi := int(floor(oy))
		for y in range(oyi - r_ceil, oyi + r_ceil + 1):
			for x in range(oxi - r_ceil, oxi + r_ceil + 1):
				if x < 0 or y < 0 or x >= grid_w or y >= grid_h:
					continue
				if not SimGeom.in_cone(ox, oy, facing, half, rng, float(x), float(y)):
					continue
				var tt: String = grid.tier_at(float(x), float(y))
				var clear: bool = grid.los_clear(ox, oy, tier, float(x), float(y), tt)
				var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
				var rect := Rect2(p, Vector2(cell_px, cell_px))
				if clear:
					draw_rect(rect, Color(0.3, 0.8, 0.45, 0.22), true)
				else:
					draw_rect(rect, Color(0.45, 0.45, 0.45, 0.45), true)


func _draw_threat_slots() -> void:
	if assets.threat_slot == null:
		return
	var mod := Color(1, 1, 1, 0.55) if art_mode == ArtMode.G3 else Color(1, 1, 1, 1)
	for c in threat_slot_cells:
		var p := Vector2(c.x * cell_px, (grid_h - 1 - c.y) * cell_px)
		draw_texture_rect(assets.threat_slot, Rect2(p, Vector2(cell_px, cell_px)), false, mod)


func _draw_marker_and_mines() -> void:
	var ttype := str(trigger.get("type", ""))
	if ttype == "cross_marker" and trigger.has("a") and trigger.has("b"):
		var a: Dictionary = trigger["a"]
		var b: Dictionary = trigger["b"]
		var pa := cell_to_screen(float(a["x"]), float(a["y"]))
		var pb := cell_to_screen(float(b["x"]), float(b["y"]))
		draw_line(pa, pb, Color(1.0, 0.86, 0.3, 0.95), 3.0)
		# dashes
		var mid := (pa + pb) * 0.5
		if assets.marker_line:
			draw_texture_rect(assets.marker_line, Rect2(mid - Vector2(24, 6), Vector2(48, 12)), false)
	for m in mines:
		if not m.get("alive", true):
			continue
		var p := cell_to_screen(float(m["x"]), float(m["y"]))
		var mine_tex: Texture2D = null
		if art_mode == ArtMode.G3 and g3 != null:
			mine_tex = g3.weapon_sprites.get("mine", null)
		elif art_mode == ArtMode.G2 and g2 != null:
			mine_tex = g2.weapon_sprites.get("mine", null)
		if mine_tex == null:
			mine_tex = assets.mine
		if mine_tex:
			draw_texture_rect(mine_tex, Rect2(p - Vector2(cell_px * 0.4, cell_px * 0.4), Vector2(cell_px * 0.8, cell_px * 0.8)), false)
	for g in grenade_plans:
		var p := cell_to_screen(float(g["aim_x"]), float(g["aim_y"]))
		var gt: Texture2D = null
		if art_mode == ArtMode.G3 and g3 != null:
			gt = g3.weapon_sprites.get("grenade", null)
		elif art_mode == ArtMode.G2 and g2 != null:
			gt = g2.weapon_sprites.get("grenade", null)
		if gt:
			draw_texture_rect(gt, Rect2(p - Vector2(cell_px * 0.35, cell_px * 0.35), Vector2(cell_px * 0.7, cell_px * 0.7)), false)
		else:
			draw_circle(p, cell_px * 0.35, Color(0.9, 0.7, 0.2, 0.5))
		draw_arc(p, cell_px * 2.0, 0, TAU, 32, Color(0.9, 0.7, 0.2, 0.35), 2.0)


func _draw_preview() -> void:
	if preview_cell.x < 0:
		return
	var p := Vector2(preview_cell.x * cell_px, (grid_h - 1 - preview_cell.y) * cell_px)
	if assets.click_preview:
		draw_texture_rect(assets.click_preview, Rect2(p, Vector2(cell_px, cell_px)), false)
	for s in preview_seers:
		var sp := cell_to_screen(float(s["x"]), float(s["y"]))
		var tp := cell_to_screen(float(preview_cell.x), float(preview_cell.y))
		draw_line(sp, tp, Color(0.4, 0.8, 1.0, 0.85), 2.0)


func _draw_units() -> void:
	for e in enemies:
		if not e.get("alive", true) or not e.get("entered", false) or e.get("escaped", false):
			continue
		var etex: Texture2D = assets.enemy
		if art_mode == ArtMode.G3 and g3 != null:
			etex = g3.units.get("enemy_rifle", etex)
		_draw_unit_tex(etex, float(e["x"]), float(e["y"]), 0.0, false)
	for s in sentries:
		var sp := _observer_xy(s)
		var stex: Texture2D = assets.sentry
		if art_mode == ArtMode.G3 and g3 != null:
			stex = g3.units.get("enemy_officer", stex)
		_draw_unit_tex(stex, sp.x, sp.y, float(s.get("cone", {}).get("facing_deg", 0)), false)
	for p in patrols:
		var pp := _observer_xy(p)
		var ptex: Texture2D = assets.sentry
		if art_mode == ArtMode.G3 and g3 != null:
			ptex = g3.units.get("enemy_smg", ptex)
		_draw_unit_tex(ptex, pp.x, pp.y, float(p.get("cone", {}).get("facing_deg", 0)), false)
	for op in operators:
		if not op.get("alive", true):
			continue
		var high := str(op.get("tier", "ground")) == SimConstants.TIER_HIGH
		var tex: Texture2D = assets.friendly_high if high else assets.friendly
		var wid := str(op.get("weapon_id", ""))
		if art_mode == ArtMode.G3 and g3 != null:
			var g3u: Texture2D = g3.friendly_unit_for_weapon(wid)
			if g3u != null:
				tex = g3u
		elif art_mode == ArtMode.G2 and g2 != null:
			var g2u: Texture2D = g2.weapon_units.get(wid, null)
			if g2u != null:
				tex = g2u
		var is_sel := str(op["id"]) == selected_op_id
		_draw_unit_tex(tex, float(op["x"]), float(op["y"]), float(op["facing_deg"]), is_sel)
		# Team ring on every friendly (selected = brighter); high keeps gold accent.
		if art_mode == ArtMode.G3:
			var hp := cell_to_screen(float(op["x"]), float(op["y"]))
			var ring_col := Color(1.0, 0.95, 0.35, 0.95) if is_sel else Color(1.0, 0.88, 0.25, 0.72)
			draw_arc(hp, cell_px * 0.78, 0, TAU, 28, ring_col, 2.2 if is_sel else 1.8)
			if high:
				draw_arc(hp, cell_px * 0.92, 0, TAU, 28, Color(1.0, 0.82, 0.16, 0.85), 1.6)
		elif high:
			var hp2 := cell_to_screen(float(op["x"]), float(op["y"]))
			draw_arc(hp2, cell_px * 0.5, 0, TAU, 24, Color(1.0, 0.82, 0.16, 0.95), 2.0)
		var sp := cell_to_screen(float(op["x"]), float(op["y"]))
		draw_string(ThemeDB.fallback_font, sp + Vector2(-10, -cell_px * 0.55), str(op["id"]).substr(0, 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.95, 1.0))


func _draw_unit_tex(tex: Texture2D, x: float, y: float, facing_deg: float, selected: bool) -> void:
	if tex == null:
		return
	var p := cell_to_screen(x, y)
	var scale := G3_UNIT_SCALE if art_mode == ArtMode.G3 else 0.85
	var sz := Vector2(cell_px * scale, cell_px * scale)
	if art_mode == ArtMode.G3 and g3 != null and g3.drop_shadow:
		var sh := sz * 0.95
		draw_texture_rect(g3.drop_shadow, Rect2(p - sh * 0.5 + Vector2(3, 5), sh), false, Color(1, 1, 1, 0.85))
	# Rotate around center: draw via transform
	draw_set_transform(p, deg_to_rad(-facing_deg), Vector2.ONE) # screen y flip ⇒ negate angle
	draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if selected and art_mode != ArtMode.G3:
		draw_arc(p, cell_px * 0.55, 0, TAU, 24, Color(1, 1, 0.4, 0.9), 2.0)


func _draw_alert_badge() -> void:
	var tex: Texture2D = assets.alert_icons.get(alert, null)
	if tex == null:
		return
	draw_texture_rect(tex, Rect2(Vector2(8, 8), Vector2(40, 40)), false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		_handle_pointer(st.position, st.pressed, false)
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		_handle_pointer(sd.position, true, true)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_pointer(mb.position, mb.pressed, false)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_handle_pointer(mm.position, true, true)


func _handle_pointer(pos: Vector2, pressed: bool, dragging: bool) -> void:
	var cell := screen_to_cell(pos)
	if not pressed:
		if _dragging_op != "" and dragging == false:
			pass
		_dragging_op = ""
		return
	if dragging and _dragging_op != "":
		var origin := cell_to_screen(
			_op_pos(_dragging_op).x, _op_pos(_dragging_op).y
		)
		var dir := pos - origin
		cell_dragged.emit(cell, dir)
		return
	# tap: select unit or preview cell
	var hit := _op_at_cell(cell)
	if hit != "":
		selected_op_id = hit
		_dragging_op = hit
		unit_selected.emit(hit)
		queue_redraw()
		return
	cell_tapped.emit(cell)


func _op_at_cell(cell: Vector2i) -> String:
	for op in operators:
		if int(floor(float(op["x"]))) == cell.x and int(floor(float(op["y"]))) == cell.y:
			return str(op["id"])
	return ""


func _op_pos(op_id: String) -> Vector2:
	for op in operators:
		if str(op["id"]) == op_id:
			return Vector2(float(op["x"]), float(op["y"]))
	return Vector2.ZERO
