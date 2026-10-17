extends Control
class_name GreyboxMap

## Thin orthographic top-down view over sim state. No gameplay logic.

const SimGeom := preload("res://sim/geom.gd")
const SimConstants := preload("res://sim/constants.gd")
const G1AssetsScript := preload("res://view/g1_assets.gd")
const G2AssetsScript := preload("res://view/g2_assets.gd")
const G3AssetsScript := preload("res://view/g3_assets.gd")
const CombatFxScript := preload("res://view/combat_fx.gd")
const GestureRouterScript := preload("res://view/gesture_router.gd")

signal cell_tapped(cell: Vector2i)
signal cell_dragged(cell: Vector2i, world_dir: Vector2)
signal unit_selected(op_id: String)
signal cell_long_pressed(cell: Vector2i)
signal aim_drag_started(op_id: String, pos: Vector2)
signal aim_drag_updated(op_id: String, world_dir: Vector2, preview_deg: float)
signal aim_drag_ended(op_id: String, world_dir: Vector2, preview_deg: float, cancelled: bool)

enum ArtMode { G3, G2, G1 }

## World-space UV: texture spans this many cells (seamless, no cell grid).
## Cobble atlas dominant ~43px stones → period 0.7 ⇒ ~7–8 stones/cell.
const G3_TEX_CELLS := 6.0 ## mud/planks — longer period reduces cell-scale wash seams
const G3_COBBLE_CELLS := 0.7 ## ~8–9 stones/cell (atlas dominant period ≈43px)
const G3_ROOF_CELLS := 4.5 ## larger shingle texel so roofs read
const G3_UNIT_SCALE := 1.6
const G3_WALL_STRIP := 0.36 ## ~1/3 cell dry-stone wall width

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
var highlight_high_slots: bool = false ## SETUP: gold wash on high_slots
var op_display_names: Dictionary = {} ## op_id → Chinese label (never show raw ids)
var supply_states: Dictionary = {} ## supply_id → {revealed, opened, opening, state, x, y}
var combat_fx = null ## GreyboxCombatFx
var shake_offset: Vector2 = Vector2.ZERO
var _high_cells: Dictionary = {} ## "x,y" → high_slot id
var _out_of_yard: Dictionary = {} ## "x,y" → border-touching wall mass (not a building)
var _inner_wall: Dictionary = {} ## "x,y" → interior low-wall cells (stone strips)
var searched_bodies: Dictionary = {} ## enemy_id → true (PLAY-5)
var body_search_enabled: bool = false

var _dragging_op: String = ""
var _drag_start: Vector2 = Vector2.ZERO
var gesture = null ## GestureRouter
## Hit radius in cells (PLAY-UX PR-2): nearest unit within this range.
var unit_hit_radius_cells: float = 0.8
## Selection ring metrics (for tests).
var sel_ring_width: float = 4.0
var unsel_ring_width: float = 1.6
var aim_preview_deg: float = NAN
var aim_preview_op: String = ""
## Counts for headless tests.
var tap_emit_count: int = 0
var drag_emit_count: int = 0


func _ready() -> void:
	assets = G1AssetsScript.new()
	assets.load_all()
	g2 = G2AssetsScript.new()
	g2.load_all()
	combat_fx = CombatFxScript.new()
	g3 = G3AssetsScript.new()
	g3.load_all()
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(grid_w * cell_px, grid_h * cell_px)
	_init_gesture_router()


func _init_gesture_router() -> void:
	gesture = GestureRouterScript.new()
	gesture.bounds = Rect2(Vector2.ZERO, size)
	gesture.tapped.connect(_on_gesture_tapped)
	gesture.long_pressed.connect(_on_gesture_long_pressed)
	gesture.drag_started.connect(_on_gesture_drag_started)
	gesture.drag_moved.connect(_on_gesture_drag_moved)
	gesture.drag_ended.connect(_on_gesture_drag_ended)


func configure(level_data: Dictionary, sim_grid, weapons_table: Dictionary) -> void:
	level = level_data
	grid = sim_grid
	weapons = weapons_table
	grid_w = int(level.get("grid", {}).get("width", 24))
	grid_h = int(level.get("grid", {}).get("height", 16))
	night = bool(level.get("night", true))
	_collect_threat_slots()
	_index_high_cells()
	_index_wall_classes()
	_fit_cell_px()
	queue_redraw()


func _index_high_cells() -> void:
	_high_cells.clear()
	for hs in level.get("high_slots", []):
		for c in hs.get("cells", []):
			_high_cells["%d,%d" % [int(c["x"]), int(c["y"])]] = str(hs.get("id", ""))


func _index_wall_classes() -> void:
	## Border-touching wall components = out-of-yard (dark ground). Interior wall cells = low stone strips.
	## Buildings are high/structure only — never the border wall masses.
	_out_of_yard.clear()
	_inner_wall.clear()
	if grid == null:
		return
	var visited: Dictionary = {}
	for y in range(grid_h):
		for x in range(grid_w):
			var key := "%d,%d" % [x, y]
			if visited.has(key):
				continue
			var cell: Dictionary = grid.get_cell(x, y)
			var kind := str(cell.get("kind", ""))
			if not _is_wall_kind(kind, cell):
				continue
			var blob := _flood_wall_mass(x, y)
			var touches_border := false
			for bkey in blob:
				visited[bkey] = true
				var parts := str(bkey).split(",")
				var bx := int(parts[0])
				var by := int(parts[1])
				if bx <= 0 or by <= 0 or bx >= grid_w - 1 or by >= grid_h - 1:
					touches_border = true
			for bkey in blob:
				if touches_border:
					_out_of_yard[bkey] = true
				else:
					_inner_wall[bkey] = true


func _flood_wall_mass(sx: int, sy: int) -> Dictionary:
	var out: Dictionary = {}
	var stack: Array = [Vector2i(sx, sy)]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var key := "%d,%d" % [p.x, p.y]
		if out.has(key):
			continue
		if p.x < 0 or p.y < 0 or p.x >= grid_w or p.y >= grid_h:
			continue
		var cell: Dictionary = grid.get_cell(p.x, p.y)
		var kind := str(cell.get("kind", ""))
		if not _is_wall_kind(kind, cell):
			continue
		out[key] = true
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	return out


func _is_building_cell(kind: String, tier: String, x: int, y: int) -> bool:
	if kind == "structure" or kind == "high":
		return true
	if tier == SimConstants.TIER_HIGH:
		return true
	return _high_cells.has("%d,%d" % [x, y])


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		if gesture != null:
			gesture.bounds = Rect2(Vector2.ZERO, size)
		_fit_cell_px()
		queue_redraw()


func _fit_cell_px() -> void:
	if grid_w <= 0 or grid_h <= 0:
		return
	# Prefer MapHost size (outside SubViewportContainer).
	var avail := Vector2.ZERO
	var sv: SubViewport = get_viewport() as SubViewport
	if sv != null:
		var svc := sv.get_parent()
		if svc is Control and svc.get_parent() is Control:
			avail = (svc.get_parent() as Control).size
		elif svc is Control:
			avail = (svc as Control).size
	if avail.x < 8.0 or avail.y < 8.0:
		avail = get_parent_area_size() if get_parent() else Vector2(960, 640)
	if avail.x < 8.0 or avail.y < 8.0:
		avail = Vector2(960, 640)
	cell_px = minf(avail.x / float(grid_w), avail.y / float(grid_h))
	var map_size := Vector2(grid_w * cell_px, grid_h * cell_px)
	custom_minimum_size = map_size
	size = map_size
	position = Vector2.ZERO
	clip_contents = true
	# SubViewport size == map pixels: container cannot show anything outside the map.
	if sv != null:
		sv.size = Vector2i(maxi(1, int(round(map_size.x))), maxi(1, int(round(map_size.y))))
		var svc2 := sv.get_parent()
		if svc2 is Control:
			(svc2 as Control).size = map_size
			(svc2 as Control).position = Vector2(
				maxf(0.0, (avail.x - map_size.x) * 0.5),
				maxf(0.0, (avail.y - map_size.y) * 0.5)
			)
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(Vector2.ZERO, map_size))
	RenderingServer.canvas_item_set_clip(get_canvas_item(), true)


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
	highlight_high_slots = bool(snap.get("highlight_high_slots", false))
	op_display_names = snap.get("op_display_names", {}) as Dictionary
	supply_states = snap.get("supply_states", {}) as Dictionary
	searched_bodies = snap.get("searched_bodies", {}) as Dictionary
	body_search_enabled = bool(snap.get("body_search_enabled", false))
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
	var map_size := Vector2(grid_w * cell_px, grid_h * cell_px)
	RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true, Rect2(Vector2.ZERO, map_size))
	RenderingServer.canvas_item_set_clip(get_canvas_item(), true)
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
	_draw_high_slot_highlights()
	# G1 readability overlays always on top of terrain/props.
	if show_cones:
		_draw_enemy_cones()
	if show_sectors:
		_draw_weapon_sectors()
	_draw_aim_preview()
	_draw_threat_slots()
	_draw_marker_and_mines()
	_draw_preview()
	# Shake is visual-only (presentation); draw world under offset.
	if shake_offset != Vector2.ZERO:
		draw_set_transform(shake_offset, 0.0, Vector2.ONE)
	_draw_bodies()
	_draw_units()
	_draw_combat_fx()
	if shake_offset != Vector2.ZERO:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_alert_badge()


func _supply_is_hidden(s: Dictionary) -> bool:
	return str(s.get("visibility", "")) == "hidden" or bool(s.get("hidden", false))


func _supply_should_draw(s: Dictionary, sid: String) -> bool:
	## Scout/setup: honor supply_states.revealed; otherwise skip visibility:hidden.
	if supply_states.has(sid):
		return bool(supply_states[sid].get("revealed", false))
	return not _supply_is_hidden(s)


func _draw_supply_state_badge(sid: String, x: int, y: int) -> void:
	if not supply_states.has(sid):
		return
	var st: Dictionary = supply_states[sid]
	var state := str(st.get("state", ""))
	var p := cell_to_screen(float(x), float(y)) + Vector2(-cell_px * 0.35, cell_px * 0.35)
	var label := ""
	var col := Color(0.85, 0.9, 1.0, 0.95)
	match state:
		"unsearched":
			label = "未搜"
			col = Color(1.0, 0.92, 0.45, 0.95)
		"searching":
			label = "搜%d%%" % int(float(st.get("open_progress", 0.0)) * 100.0)
			col = Color(0.55, 0.95, 1.0, 0.95)
		"searched":
			label = "已搜"
			col = Color(0.55, 0.9, 0.55, 0.95)
		_:
			return
	draw_string(ThemeDB.fallback_font, p, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, col)


func _draw_high_slot_highlights() -> void:
	if not highlight_high_slots:
		return
	for hs in level.get("high_slots", []):
		for c in hs.get("cells", []):
			var x := int(c.get("x", -1))
			var y := int(c.get("y", -1))
			if x < 0:
				continue
			var r := Rect2(Vector2(x * cell_px, (grid_h - 1 - y) * cell_px), Vector2(cell_px, cell_px))
			draw_rect(r, Color(1.0, 0.82, 0.25, 0.22), true)
			draw_rect(r.grow(-1.0), Color(1.0, 0.88, 0.35, 0.55), false, 1.5)


func _draw_tiles() -> void:
	if art_mode == ArtMode.G3 and g3 != null:
		_draw_g3_terrain()
		_draw_g3_stone_walls()
		_draw_g3_roof_footprints()
		return
	for y in range(grid_h):
		for x in range(grid_w):
			var cell: Dictionary = grid.get_cell(x, y)
			var kind := str(cell.get("kind", "wall"))
			var tier := str(cell.get("tier", ""))
			var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
			var tex: Texture2D = _tile_tex_for(cell, kind, tier, x, y)
			if tex:
				draw_texture_rect(tex, Rect2(p, Vector2(cell_px, cell_px)), false)


func _g3_period(surf: String) -> float:
	match surf:
		"cobble":
			return G3_COBBLE_CELLS
		"roof_slate", "roof_shingle":
			return G3_ROOF_CELLS
		"grass":
			return 6.5 ## long period — avoids cell-scale checker in grass plots
		"mud", "outside":
			return G3_TEX_CELLS
		"stonewall":
			return 2.5
		_:
			return G3_TEX_CELLS


func _g3_ground_mod(surf: String) -> Color:
	## Single moonlight modulate per surface (grass/mud nearly identical value to kill cell tint).
	match surf:
		"cobble":
			return Color(0.70, 0.74, 0.86, 1.0)
		"grass":
			return Color(0.48, 0.50, 0.47, 1.0)
		"mud":
			return Color(0.49, 0.47, 0.45, 1.0)
		"planks":
			return Color(0.60, 0.56, 0.48, 1.0)
		_:
			return Color(0.58, 0.58, 0.62, 1.0)


func _yard_surf_at(x: int, y: int) -> String:
	## Visual ground class for open yard cells (buildings/outside/inner walls excluded).
	if x < 0 or y < 0 or x >= grid_w or y >= grid_h:
		return ""
	if _out_of_yard.has("%d,%d" % [x, y]) or _inner_wall.has("%d,%d" % [x, y]):
		return ""
	var cell: Dictionary = grid.get_cell(x, y)
	var kind := str(cell.get("kind", ""))
	var tier := str(cell.get("tier", ""))
	if _is_building_cell(kind, tier, x, y) or _is_wall_kind(kind, cell):
		return ""
	if kind in ["road", "gate_n", "gate_s", "gate_e"]:
		return "cobble"
	if kind == "alley":
		return "mud"
	if kind in ["ramp", "slope"]:
		return "planks"
	return _yard_ground_key(x, y)


func _draw_g3_terrain() -> void:
	## Continuous world-UV fills + soft noisy edges (no per-cell tint checkerboard).
	var map_rect := Rect2(Vector2.ZERO, Vector2(grid_w * cell_px, grid_h * cell_px))
	_draw_g3_world_rect(
		g3.tile_mud, 0.0, 0.0, float(grid_w), float(grid_h), map_rect, _g3_ground_mod("mud"), G3_TEX_CELLS
	)
	# Outside: dark night earth.
	for y in range(grid_h):
		for x in range(grid_w):
			if not _out_of_yard.has("%d,%d" % [x, y]):
				continue
			var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
			var rect := Rect2(p - Vector2(1.0, 1.0), Vector2(cell_px + 2.0, cell_px + 2.0))
			_draw_g3_world_sample(g3.tile_mud, x, y, rect, Color(0.40, 0.44, 0.38, 1.0), G3_TEX_CELLS)
			_draw_g3_world_sample(g3.tile_grass, x, y, rect, Color(0.32, 0.40, 0.36, 0.55), 3.2)
			draw_rect(rect, Color(0.02, 0.04, 0.09, 0.58), true)
	# Cobble / planks as horizontal runs; grass as continuous zone bboxes (kills square tint).
	for y in range(grid_h):
		var x := 0
		while x < grid_w:
			var surf := _yard_surf_at(x, y)
			if surf != "cobble" and surf != "planks":
				x += 1
				continue
			var x0 := x
			while x < grid_w and _yard_surf_at(x, y) == surf:
				x += 1
			var x1 := x - 1
			var px := float(x0) * cell_px
			var py := float(grid_h - 1 - y) * cell_px
			var w := float(x1 - x0 + 1) * cell_px
			var dest := Rect2(px - 0.75, py - 0.75, w + 1.5, cell_px + 1.5)
			_draw_g3_world_rect(
				_g3_tex(surf), float(x0), float(y), float(x1 - x0 + 1), 1.0, dest, _g3_ground_mod(surf), _g3_period(surf)
			)
	for z in [
		[4, 7, 2, 7],
		[12, 16, 2, 4],
		[15, 18, 11, 13],
	]:
		_fill_g3_surf_zone(z[0], z[1], z[2], z[3], "grass")
	# One continuous east-yard grass veil (not per-zone boxes) to kill cell/box tint.
	_wash_g3_yard_grass_veil()
	# Building underlays.
	for y in range(grid_h):
		for x in range(grid_w):
			var cell: Dictionary = grid.get_cell(x, y)
			var kind := str(cell.get("kind", ""))
			var tier := str(cell.get("tier", ""))
			if _is_building_cell(kind, tier, x, y):
				var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
				draw_rect(Rect2(p, Vector2(cell_px, cell_px)), Color(0.22, 0.22, 0.26, 1.0), true)
	_blend_g3_ground_edges()


func _fill_g3_surf_zone(min_x: int, max_x: int, min_y: int, max_y: int, surf: String) -> void:
	## One continuous world-UV rect for a ground zone (uniform modulate).
	var x0 := 999
	var x1 := -1
	var y0 := 999
	var y1 := -1
	var any := false
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _yard_surf_at(x, y) != surf:
				continue
			any = true
			x0 = mini(x0, x)
			x1 = maxi(x1, x)
			y0 = mini(y0, y)
			y1 = maxi(y1, y)
	if not any:
		return
	var px := float(x0) * cell_px
	var py := float(grid_h - 1 - y1) * cell_px
	var w := float(x1 - x0 + 1) * cell_px
	var h := float(y1 - y0 + 1) * cell_px
	var dest := Rect2(px - 1.0, py - 1.0, w + 2.0, h + 2.0)
	_draw_g3_world_rect(
		_g3_tex(surf), float(x0), float(y0), float(x1 - x0 + 1), float(y1 - y0 + 1), dest, _g3_ground_mod(surf), _g3_period(surf)
	)


func _wash_g3_yard_grass_veil() -> void:
	## Single low-alpha grass veil over open yard (mud+grass) — unifies value, no box edges.
	if g3 == null or g3.tile_grass == null:
		return
	var x0 := 3.0
	var y0 := 1.0
	var x1 := float(grid_w) - 2.0
	var y1 := float(grid_h) - 1.0
	var px := x0 * cell_px
	var py := float(grid_h) * cell_px - y1 * cell_px
	var dest := Rect2(px, py, (x1 - x0) * cell_px, (y1 - y0) * cell_px)
	# Long UV period so veil doesn't invent a cell-scale checker.
	_draw_g3_world_rect(g3.tile_grass, x0, y0, x1 - x0, y1 - y0, dest, Color(0.46, 0.48, 0.45, 0.18), 7.5)
	# East yard slightly stronger (right-side mud/grass read).
	var ex0 := 13.0
	var ey0 := 2.0
	var ex1 := float(grid_w) - 1.5
	var ey1 := 14.0
	var edest := Rect2(ex0 * cell_px, float(grid_h) * cell_px - ey1 * cell_px, (ex1 - ex0) * cell_px, (ey1 - ey0) * cell_px)
	_draw_g3_world_rect(g3.tile_grass, ex0, ey0, ex1 - ex0, ey1 - ey0, edest, Color(0.47, 0.49, 0.46, 0.16), 8.0)


func _blend_g3_ground_edges() -> void:
	## Soft feather at cobble/plank boundaries only — grass↔mud uses zone washes (no square strips).
	var dirs := [[1, 0, "e"], [-1, 0, "w"], [0, 1, "n"], [0, -1, "s"]]
	for y in range(grid_h):
		for x in range(grid_w):
			var surf := _yard_surf_at(x, y)
			if surf == "" or surf in ["grass", "mud"]:
				continue
			var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
			for d in dirs:
				var nx: int = x + int(d[0])
				var ny: int = y + int(d[1])
				var nsurf := _yard_surf_at(nx, ny)
				if nsurf == "" or nsurf == surf:
					continue
				var n := float(((x * 17 + y * 31 + int(d[0]) * 7) % 10)) / 10.0
				var t := 0.20 + n * 0.16
				var strip: Rect2
				match str(d[2]):
					"e":
						strip = Rect2(p + Vector2(cell_px * (1.0 - t), cell_px * (0.05 + n * 0.1)), Vector2(cell_px * t, cell_px * (0.85 - n * 0.1)))
					"w":
						strip = Rect2(p + Vector2(0, cell_px * (0.05 + n * 0.1)), Vector2(cell_px * t, cell_px * (0.85 - n * 0.1)))
					"n":
						strip = Rect2(p + Vector2(cell_px * (0.05 + n * 0.1), 0), Vector2(cell_px * (0.85 - n * 0.1), cell_px * t))
					_:
						strip = Rect2(p + Vector2(cell_px * (0.05 + n * 0.1), cell_px * (1.0 - t)), Vector2(cell_px * (0.85 - n * 0.1), cell_px * t))
				var mod := _g3_ground_mod(nsurf)
				mod.a = 0.28 + n * 0.14
				_draw_g3_world_sample(_g3_tex(nsurf), nx, ny, strip, mod, _g3_period(nsurf))


func _is_wall_kind(kind: String, cell: Dictionary) -> bool:
	return kind == "wall" or (bool(cell.get("blocks_all_los", false)) and kind != "structure" and kind != "high")


func _surface_key(cell: Dictionary, kind: String, tier: String, x: int, y: int) -> String:
	## Roofs only on compact interior buildings (high / structure). Border walls = outside earth.
	if _is_building_cell(kind, tier, x, y):
		var hid := str(_high_cells.get("%d,%d" % [x, y], ""))
		if kind == "structure":
			return "roof_shingle"
		return "roof_shingle" if hid == "low_wall_pad" else "roof_slate"
	var key := "%d,%d" % [x, y]
	if _out_of_yard.has(key) or (_is_wall_kind(kind, cell) and not _inner_wall.has(key)):
		return "outside"
	if _inner_wall.has(key):
		# Ground under the low wall strip (strip drawn later).
		return _yard_ground_key(x, y)
	if kind in ["ramp", "slope"]:
		return "planks"
	if kind in ["road", "gate_n", "gate_s", "gate_e"]:
		return "cobble"
	if kind == "alley":
		return "mud"
	return _yard_ground_key(x, y)


func _yard_ground_key(x: int, y: int) -> String:
	## Large coherent zones (not per-cell checker): cobble courtyard, mud tracks, grass plots.
	# Vertical cobble court around the road spine.
	if x >= 8 and x <= 13 and y >= 1 and y <= 14:
		return "cobble"
	# East court toward alley / east pad.
	if x >= 14 and x <= 17 and y >= 5 and y <= 10:
		return "cobble"
	# Grass plots west of barn / between inner walls (concept enclosed greens).
	if x >= 4 and x <= 7 and y >= 2 and y <= 7:
		return "grass"
	if x >= 12 and x <= 16 and y >= 2 and y <= 4:
		return "grass"
	if x >= 15 and x <= 18 and y >= 11 and y <= 13:
		return "grass"
	# Mud paths: south approach + west track beside barn.
	if y <= 3 and x >= 5 and x <= 14:
		return "mud"
	if x >= 5 and x <= 7 and y >= 8 and y <= 12:
		return "mud"
	return "mud"


func _near_building(x: int, y: int, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var nx := x + dx
			var ny := y + dy
			if nx < 0 or ny < 0 or nx >= grid_w or ny >= grid_h:
				continue
			var ncell: Dictionary = grid.get_cell(nx, ny)
			var nk := str(ncell.get("kind", ""))
			var nt := str(ncell.get("tier", ""))
			if _is_building_cell(nk, nt, nx, ny):
				return true
	return false


func _near_high(x: int, y: int, radius: int) -> bool:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if _high_cells.has("%d,%d" % [x + dx, y + dy]):
				return true
	return false


func _g3_tex(surface: String) -> Texture2D:
	match surface:
		"grass", "outside":
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
	if surf.begins_with("roof"):
		# Underlay only — continuous footprint fill draws the seamless roof face.
		draw_rect(rect, Color(0.22, 0.22, 0.26, 1.0), true)
		return
	if surf == "outside":
		# Dark night grass/earth beyond the dry-stone perimeter (vignette finishes the read).
		var night_earth := Color(0.42, 0.46, 0.40, 1.0)
		_draw_g3_world_sample(g3.tile_mud if g3.tile_mud else _g3_tex("outside"), x, y, rect, night_earth)
		_draw_g3_world_sample(_g3_tex("outside"), x, y, rect, Color(0.35, 0.42, 0.38, 0.55))
		draw_rect(rect, Color(0.03, 0.05, 0.10, 0.55), true)
		return
	# Yard ground — cool blue-grey moonlight (no per-cell edge wash → no checker seams).
	var ground_mod := Color(0.62, 0.68, 0.82, 1.0)
	if surf == "grass":
		ground_mod = Color(0.48, 0.58, 0.55, 1.0)
	elif surf == "mud":
		ground_mod = Color(0.55, 0.52, 0.48, 1.0)
	elif surf == "cobble":
		ground_mod = Color(0.68, 0.72, 0.84, 1.0)
	_draw_g3_world_sample(_g3_tex(surf), x, y, rect, ground_mod)


func _draw_g3_stone_walls() -> void:
	## Continuous dry-stone perimeter runs (~1/3 cell) + inner plot dividers as narrow strips.
	_draw_g3_perimeter_runs()
	for y in range(grid_h):
		for x in range(grid_w):
			if _inner_wall.has("%d,%d" % [x, y]):
				var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
				_draw_g3_wall_strip(x, y, Rect2(p, Vector2(cell_px, cell_px)))


func _perimeter_edge(x: int, y: int, dir: String) -> bool:
	## True when out-of-yard cell (x,y) faces yard in dir (e/w/n/s in grid space).
	if not _out_of_yard.has("%d,%d" % [x, y]):
		return false
	var nx := x
	var ny := y
	match dir:
		"e":
			nx += 1
		"w":
			nx -= 1
		"n":
			ny += 1
		"s":
			ny -= 1
	return _cell_yard(nx, ny)


func _draw_g3_perimeter_runs() -> void:
	## Merge adjacent perimeter edges into long strips so the wall reads continuous (concept outer wall).
	var t := G3_WALL_STRIP
	var visited_h: Dictionary = {} ## horizontal runs keyed by "y,dir,x"
	var visited_v: Dictionary = {}
	# Horizontal runs (along x) for north/south faces.
	for dir in ["n", "s"]:
		for y in range(grid_h):
			var x := 0
			while x < grid_w:
				if not _perimeter_edge(x, y, dir):
					x += 1
					continue
				var x0 := x
				while x < grid_w and _perimeter_edge(x, y, dir):
					x += 1
				var x1 := x - 1
				var key := "%s,%d,%d-%d" % [dir, y, x0, x1]
				if visited_h.has(key):
					continue
				visited_h[key] = true
				var px := float(x0) * cell_px
				var py := float(grid_h - 1 - y) * cell_px
				var w := float(x1 - x0 + 1) * cell_px
				var strip: Rect2
				if dir == "n":
					strip = Rect2(Vector2(px + 1.0, py), Vector2(w - 2.0, cell_px * t))
				else:
					strip = Rect2(Vector2(px + 1.0, py + cell_px * (1.0 - t)), Vector2(w - 2.0, cell_px * t))
				_stroke_stone_strip(strip, x0, y)
	# Vertical runs (along y) for east/west faces.
	for dir in ["e", "w"]:
		for x in range(grid_w):
			var y := 0
			while y < grid_h:
				if not _perimeter_edge(x, y, dir):
					y += 1
					continue
				var y0 := y
				while y < grid_h and _perimeter_edge(x, y, dir):
					y += 1
				var y1 := y - 1
				var key2 := "%s,%d,%d-%d" % [dir, x, y0, y1]
				if visited_v.has(key2):
					continue
				visited_v[key2] = true
				var px2 := float(x) * cell_px
				# Screen y: higher grid y → smaller screen y; span from y1 down to y0.
				var py2 := float(grid_h - 1 - y1) * cell_px
				var h := float(y1 - y0 + 1) * cell_px
				var strip2: Rect2
				if dir == "e":
					strip2 = Rect2(Vector2(px2 + cell_px * (1.0 - t), py2 + 1.0), Vector2(cell_px * t, h - 2.0))
				else:
					strip2 = Rect2(Vector2(px2, py2 + 1.0), Vector2(cell_px * t, h - 2.0))
				_stroke_stone_strip(strip2, x, y0)


func _draw_g3_wall_strip(x: int, y: int, rect: Rect2) -> void:
	## Narrow raised stone strip + cast shadow toward open neighbors.
	var t := G3_WALL_STRIP
	var strip := Rect2(
		rect.position + Vector2(rect.size.x * (1.0 - t) * 0.5, rect.size.y * (1.0 - t) * 0.35),
		Vector2(rect.size.x * t, rect.size.y * t * 1.15)
	)
	var open_e := _cell_yard(x + 1, y)
	var open_w := _cell_yard(x - 1, y)
	var open_n := _cell_yard(x, y + 1)
	var open_s := _cell_yard(x, y - 1)
	if open_e and not open_w:
		strip = Rect2(rect.position + Vector2(rect.size.x * (1.0 - t), rect.size.y * 0.08), Vector2(rect.size.x * t, rect.size.y * 0.84))
	elif open_w and not open_e:
		strip = Rect2(rect.position + Vector2(0, rect.size.y * 0.08), Vector2(rect.size.x * t, rect.size.y * 0.84))
	elif open_s and not open_n:
		strip = Rect2(rect.position + Vector2(rect.size.x * 0.08, rect.size.y * (1.0 - t)), Vector2(rect.size.x * 0.84, rect.size.y * t))
	elif open_n and not open_s:
		strip = Rect2(rect.position + Vector2(rect.size.x * 0.08, 0), Vector2(rect.size.x * 0.84, rect.size.y * t))
	_stroke_stone_strip(strip, x, y)


func _stroke_stone_strip(strip: Rect2, x: int, y: int) -> void:
	# Prefer continuous UV along the long axis of the strip.
	var cells_w := maxf(0.25, strip.size.x / cell_px)
	var cells_h := maxf(0.25, strip.size.y / cell_px)
	_draw_g3_world_rect(g3.tile_stonewall, float(x), float(y), cells_w, cells_h, strip, Color(1, 1, 1, 1), 2.5)
	# Drop shadow at base (south) + soft east bias (concept wall depth).
	draw_rect(
		Rect2(strip.position + Vector2(1.5, strip.size.y * 0.55), Vector2(strip.size.x + 3.0, strip.size.y * 0.55)),
		Color(0, 0, 0, 0.48),
		true
	)
	# Top-edge highlight.
	draw_rect(Rect2(strip.position, Vector2(strip.size.x, maxf(2.0, strip.size.y * 0.16))), Color(0.62, 0.64, 0.68, 0.70), true)
	# Thin dark lip.
	draw_rect(Rect2(strip.position + Vector2(0, strip.size.y - 2.0), Vector2(strip.size.x, 2.0)), Color(0.06, 0.06, 0.08, 0.80), true)


func _cell_yard(x: int, y: int) -> bool:
	## True for playable yard cells (not out-of-yard border mass).
	if x < 0 or y < 0 or x >= grid_w or y >= grid_h:
		return false
	return not _out_of_yard.has("%d,%d" % [x, y])


func _draw_g3_roof_footprints() -> void:
	## Ridge + eaves only for actual houses/sheds (high + structure), never border walls.
	var drawn: Dictionary = {}
	for y in range(grid_h):
		for x in range(grid_w):
			var key := "%d,%d" % [x, y]
			if drawn.has(key):
				continue
			var cell: Dictionary = grid.get_cell(x, y)
			var kind := str(cell.get("kind", ""))
			var tier := str(cell.get("tier", ""))
			if not _is_building_cell(kind, tier, x, y):
				continue
			var blob := _flood_building_mass(x, y)
			if blob.is_empty():
				continue
			var min_x := 999
			var max_x := -1
			var min_y := 999
			var max_y := -1
			for bkey in blob:
				drawn[bkey] = true
				var parts := str(bkey).split(",")
				var bx := int(parts[0])
				var by := int(parts[1])
				min_x = mini(min_x, bx)
				max_x = maxi(max_x, bx)
				min_y = mini(min_y, by)
				max_y = maxi(max_y, by)
			_stroke_roof_footprint(min_x, max_x, min_y, max_y)


func _flood_building_mass(sx: int, sy: int) -> Dictionary:
	var out: Dictionary = {}
	var stack: Array = [Vector2i(sx, sy)]
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var key := "%d,%d" % [p.x, p.y]
		if out.has(key):
			continue
		if p.x < 0 or p.y < 0 or p.x >= grid_w or p.y >= grid_h:
			continue
		var cell: Dictionary = grid.get_cell(p.x, p.y)
		var kind := str(cell.get("kind", ""))
		var tier := str(cell.get("tier", ""))
		if not _is_building_cell(kind, tier, p.x, p.y):
			continue
		out[key] = true
		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))
	return out


func _stroke_roof_footprint(min_x: int, max_x: int, min_y: int, max_y: int) -> void:
	var x0 := float(min_x) * cell_px
	var y0 := float(grid_h - 1 - max_y) * cell_px
	var w := float(max_x - min_x + 1) * cell_px
	var h := float(max_y - min_y + 1) * cell_px
	var footprint := Rect2(x0 - 0.5, y0 - 0.5, w + 1.0, h + 1.0)
	# Continuous roof face (one world-UV sample across the whole mass — no cell seams).
	var surf := "roof_slate"
	var mid_cell: Dictionary = grid.get_cell(int((min_x + max_x) / 2), int((min_y + max_y) / 2))
	var mk := str(mid_cell.get("kind", ""))
	var mt := str(mid_cell.get("tier", ""))
	surf = _surface_key(mid_cell, mk, mt, int((min_x + max_x) / 2), int((min_y + max_y) / 2))
	if not surf.begins_with("roof"):
		surf = "roof_slate"
	# Row strips (correct grid-y ↔ screen-y) with larger shingle texel.
	var cells_w := float(max_x - min_x + 1)
	var roof_period := _g3_period(surf)
	for gy in range(max_y, min_y - 1, -1):
		var row_py := float(grid_h - 1 - gy) * cell_px
		var row := Rect2(x0 - 0.5, row_py - 0.5, w + 1.0, cell_px + 1.0)
		_draw_g3_world_rect(_g3_tex(surf), float(min_x), float(gy), cells_w, 1.0, row, Color(1, 1, 1, 1), roof_period)
	# Visible south wall face under eaves (concept house mass).
	var wall_h := cell_px * 0.28
	var wall_face := Rect2(footprint.position + Vector2(cell_px * 0.04, h - wall_h * 0.15), Vector2(w - cell_px * 0.08, wall_h))
	_draw_g3_world_rect(g3.tile_stonewall, float(min_x), float(min_y), cells_w, 0.35, wall_face, Color(0.72, 0.72, 0.76, 1.0), 2.5)
	draw_rect(Rect2(wall_face.position, Vector2(wall_face.size.x, 2.0)), Color(0.55, 0.56, 0.60, 0.65), true)
	# Soft shadow on ground just south of the building (outside the roof face).
	var eaves := Rect2(footprint.position + Vector2(cell_px * 0.02, h + wall_h * 0.55), Vector2(w * 1.02, cell_px * 0.48))
	draw_rect(eaves, Color(0, 0, 0, 0.50), true)
	if g3.drop_shadow:
		draw_texture_rect(
			g3.drop_shadow,
			Rect2(eaves.position, Vector2(eaves.size.x, cell_px * 0.60)),
			false,
			Color(1, 1, 1, 0.90)
		)
	# Eaves darken south roof lip.
	draw_rect(Rect2(footprint.position + Vector2(0, h - cell_px * 0.16), Vector2(w, cell_px * 0.16)), Color(0, 0, 0, 0.40), true)
	# Ridge along long axis.
	var long_h := w >= h
	if long_h:
		var mid_y := footprint.position.y + h * 0.48
		draw_line(Vector2(footprint.position.x + 3, mid_y), Vector2(footprint.position.x + w - 3, mid_y), Color(0.07, 0.08, 0.10, 0.95), 3.5)
		draw_line(Vector2(footprint.position.x + 3, mid_y - 2), Vector2(footprint.position.x + w - 3, mid_y - 2), Color(0.42, 0.44, 0.50, 0.55), 1.5)
	else:
		var mid_x := footprint.position.x + w * 0.5
		draw_line(Vector2(mid_x, footprint.position.y + 3), Vector2(mid_x, footprint.position.y + h - 3), Color(0.07, 0.08, 0.10, 0.95), 3.5)
		draw_line(Vector2(mid_x - 2, footprint.position.y + 3), Vector2(mid_x - 2, footprint.position.y + h - 3), Color(0.42, 0.44, 0.50, 0.55), 1.5)
	# Soft building lip.
	draw_rect(footprint.grow(-0.5), Color(0.05, 0.05, 0.07, 0.65), false, 1.8)


func _draw_g3_world_sample(
	tex: Texture2D, cell_x: int, cell_y: int, dest: Rect2, modulate: Color = Color(1, 1, 1, 1), period: float = -1.0
) -> void:
	## One logical cell of world UV into dest (dest may overlap neighbors for seam kill).
	if tex == null:
		return
	var p := period if period > 0.0 else G3_TEX_CELLS
	_draw_g3_world_rect(tex, float(cell_x), float(cell_y), 1.0, 1.0, dest, modulate, p)


func _draw_g3_world_rect(
	tex: Texture2D,
	cell_x: float,
	cell_y: float,
	cells_w: float,
	cells_h: float,
	dest: Rect2,
	modulate: Color = Color(1, 1, 1, 1),
	period: float = -1.0
) -> void:
	## World-space UV; `period` = cells spanned by one texture repeat.
	## Tiles in ≤0.95-of-atlas chunks so wrap helper never stretches across >1 period.
	if tex == null:
		return
	var tex_cells := period if period > 0.0 else G3_TEX_CELLS
	if tex_cells < 0.05:
		tex_cells = 0.05
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	# Max cells per chunk so source UV width/height stays ≤ 0.95 * atlas.
	var max_chunk := tex_cells * 0.95
	var x_cells := 0.0
	while x_cells < cells_w - 0.001:
		var cw := minf(max_chunk, cells_w - x_cells)
		var y_cells := 0.0
		while y_cells < cells_h - 0.001:
			var ch := minf(max_chunk, cells_h - y_cells)
			var sub := Rect2(
				dest.position + Vector2(dest.size.x * (x_cells / cells_w), dest.size.y * (y_cells / cells_h)),
				Vector2(dest.size.x * (cw / cells_w), dest.size.y * (ch / cells_h))
			)
			var uw := tw / tex_cells * cw
			var vh := th / tex_cells * ch
			var u0 := fposmod((cell_x + x_cells) * (tw / tex_cells), tw)
			var v0 := fposmod((cell_y + y_cells) * (th / tex_cells), th)
			# If we still straddle the atlas edge, split once more along U then V.
			_draw_region_wrapped(tex, sub, u0, v0, uw, vh, tw, th, modulate)
			y_cells += ch
		x_cells += cw


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
		if nsurf == surf or nsurf in ["stonewall", "roof_slate", "roof_shingle", "outside"]:
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
	## Cool moonlit night + warm lantern pools on roofs and ground by eaves (yard_concept).
	if not night:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(grid_w * cell_px, grid_h * cell_px)), Color(0.08, 0.12, 0.26, 0.12), true)
	if g3.vignette:
		draw_texture_rect(g3.vignette, Rect2(Vector2.ZERO, Vector2(grid_w * cell_px, grid_h * cell_px)), false, Color(1, 1, 1, 0.55))
	if g3.lantern_glow:
		# Roof accent + ground pool south of each house (west barn, north pad, east pad).
		var houses := [
			[Vector2i(4, 10), Vector2i(5, 8)],
			[Vector2i(8, 13), Vector2i(8, 12)],
			[Vector2i(14, 6), Vector2i(14, 5)],
		]
		for hpair in houses:
			var roof_c: Vector2i = hpair[0]
			var ground_c: Vector2i = hpair[1]
			var pr := Vector2(roof_c.x * cell_px, (grid_h - 1 - roof_c.y) * cell_px)
			var sz_r := cell_px * 1.55
			draw_texture_rect(
				g3.lantern_glow,
				Rect2(pr + Vector2(cell_px * 0.5 - sz_r * 0.5, cell_px * 0.5 - sz_r * 0.5), Vector2(sz_r, sz_r)),
				false,
				Color(1.0, 0.62, 0.22, 0.88)
			)
			var pg := Vector2(ground_c.x * cell_px, (grid_h - 1 - ground_c.y) * cell_px)
			var sz_g := cell_px * 2.35
			draw_texture_rect(
				g3.lantern_glow,
				Rect2(pg + Vector2(cell_px * 0.5 - sz_g * 0.5, cell_px * 0.15 - sz_g * 0.25), Vector2(sz_g, sz_g)),
				false,
				Color(1.0, 0.55, 0.18, 0.78)
			)


func _draw_g3_props() -> void:
	if g3 == null:
		return
	# No per-cell shed_roof props — continuous footprint roofs already read as houses.
	_draw_g3_sandbag_runs()
	for s in level.get("supplies", []):
		var sid := str(s.get("id", ""))
		var x := int(s.get("x", -1))
		var y := int(s.get("y", -1))
		if x < 0:
			continue
		if not _supply_should_draw(s, sid):
			continue
		var tex: Texture2D = g3.props.get("crate_stack", null)
		if tex:
			_draw_g3_prop_sprite(x, y, tex, 0.70)
		_draw_supply_state_badge(sid, x, y)
	var accents := [
		[Vector2i(9, 2), "barrel"],
		[Vector2i(14, 3), "barrel"],
		[Vector2i(16, 4), "cart"],
	]
	for a in accents:
		var c: Vector2i = a[0]
		var pname: String = a[1]
		var tex: Texture2D = g3.props.get(pname, null)
		if tex == null:
			continue
		_draw_g3_prop_sprite(c.x, c.y, tex, 0.62)


func _draw_g3_prop_sprite(x: int, y: int, tex: Texture2D, scale: float) -> void:
	## Prop on ground — no cell backing; tiny soft contact under footprint only.
	var base := Vector2(float(x) * cell_px, float(grid_h - 1 - y) * cell_px)
	var sz := cell_px * scale
	var dest := Rect2(base + Vector2((cell_px - sz) * 0.5, (cell_px - sz) * 0.42), Vector2(sz, sz))
	if g3 != null and g3.drop_shadow:
		var sh := Rect2(dest.position + Vector2(sz * 0.2, sz * 0.7), Vector2(sz * 0.6, sz * 0.25))
		draw_texture_rect(g3.drop_shadow, sh, false, Color(1, 1, 1, 0.30))
	draw_texture_rect(tex, dest, false, Color(1.0, 1.0, 1.0, 1.0))


func _cover_at(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= grid_w or y >= grid_h:
		return false
	return bool(grid.get_cell(x, y).get("low_cover", false))


func _g3_bag(name: String) -> Texture2D:
	return g3.props.get(name, null) as Texture2D


func _draw_g3_sandbag_runs() -> void:
	## All cover cells → longest H/V runs of straight tiles; pile only for isolates.
	if _g3_bag("sandbag_straight_m") == null and _g3_bag("sandbag_straight") == null:
		return
	var remaining: Dictionary = {}
	for y in range(grid_h):
		for x in range(grid_w):
			if _cover_at(x, y):
				remaining["%d,%d" % [x, y]] = true
	# Greedy: repeatedly claim the longest unvisited axis-aligned run.
	while not remaining.is_empty():
		var best_len := 0
		var best_x := 0
		var best_y := 0
		var best_h := true
		for key in remaining.keys():
			var parts := str(key).split(",")
			var x := int(parts[0])
			var y := int(parts[1])
			# Horizontal span through (x,y).
			var x0 := x
			while remaining.has("%d,%d" % [x0 - 1, y]):
				x0 -= 1
			var x1 := x
			while remaining.has("%d,%d" % [x1 + 1, y]):
				x1 += 1
			var lh := x1 - x0 + 1
			if lh > best_len:
				best_len = lh
				best_x = x0
				best_y = y
				best_h = true
			# Vertical span.
			var y0 := y
			while remaining.has("%d,%d" % [x, y0 - 1]):
				y0 -= 1
			var y1 := y
			while remaining.has("%d,%d" % [x, y1 + 1]):
				y1 += 1
			var lv := y1 - y0 + 1
			if lv > best_len:
				best_len = lv
				best_x = x
				best_y = y0
				best_h = false
		if best_len <= 1:
			break
		if best_h:
			for i in range(best_len):
				remaining.erase("%d,%d" % [best_x + i, best_y])
			_draw_g3_bag_straight(best_x, best_y, best_len, true)
		else:
			for i in range(best_len):
				remaining.erase("%d,%d" % [best_x, best_y + i])
			_draw_g3_bag_straight(best_x, best_y, best_len, false)
	# Isolated singles → round pile only.
	for key in remaining.keys():
		var parts2 := str(key).split(",")
		_draw_g3_bag_pile(int(parts2[0]), int(parts2[1]))


func _g3_bag_night_mod() -> Color:
	## Sprites are already night-graded in the pipeline; keep readable (not near-black rings).
	return Color(1.0, 1.0, 1.02, 1.0)


func _draw_g3_soft_contact(rect: Rect2) -> void:
	## Tiny soft oval under sprite — never a filled dark cell square.
	if g3 != null and g3.drop_shadow:
		var sh := Rect2(
			rect.position + Vector2(rect.size.x * 0.15, rect.size.y * 0.62),
			Vector2(rect.size.x * 0.70, rect.size.y * 0.28)
		)
		draw_texture_rect(g3.drop_shadow, sh, false, Color(1, 1, 1, 0.35))


func _draw_g3_bag_pile(x: int, y: int) -> void:
	var pile: Texture2D = _g3_bag("sandbag_pile_round")
	if pile == null:
		pile = _g3_bag("sandbag_end_cap")
	if pile == null:
		return
	var base := Vector2(float(x) * cell_px, float(grid_h - 1 - y) * cell_px)
	var sz := cell_px * 0.92
	var dest := Rect2(base + Vector2((cell_px - sz) * 0.5, (cell_px - sz) * 0.30), Vector2(sz, sz))
	draw_texture_rect(pile, dest, false, _g3_bag_night_mod())


func _draw_g3_bag_joint(x: int, y: int) -> void:
	## L / T only for true 2-neighbor elbows or 3-neighbor T (skip thick-pad interiors).
	var n := _cover_at(x, y + 1)
	var s := _cover_at(x, y - 1)
	var e := _cover_at(x + 1, y)
	var w := _cover_at(x - 1, y)
	var count := int(n) + int(s) + int(e) + int(w)
	if count != 2 and count != 3:
		return
	if count == 2 and not ((n or s) and (e or w)):
		return
	var tex: Texture2D = _g3_bag("sandbag_junction_t") if count == 3 else _g3_bag("sandbag_corner_l")
	if tex == null:
		tex = _g3_bag("sandbag_corner_l") if count == 3 else _g3_bag("sandbag_junction_t")
	if tex == null:
		return
	var base := Vector2(float(x) * cell_px, float(grid_h - 1 - y) * cell_px)
	var sz := cell_px * 0.92
	var dest := Rect2(base + Vector2((cell_px - sz) * 0.5, (cell_px - sz) * 0.28), Vector2(sz, sz))
	draw_texture_rect(tex, dest, false, _g3_bag_night_mod())


func _draw_g3_bag_straight(ox: int, oy: int, length: int, horizontal: bool) -> void:
	## Continuous run: tile straight segments with heavy overlap (no per-cell gaps / backings).
	var tex: Texture2D = _g3_bag("sandbag_straight_m")
	if tex == null:
		tex = _g3_bag("sandbag_straight_s")
	if tex == null:
		tex = _g3_bag("sandbag_straight")
	if tex == null:
		return
	var mod := _g3_bag_night_mod()
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var aspect := tw / maxf(1.0, th)
	## Fill cell width along the run; thickness ~0.72 cell (mild aspect squeeze OK for wall read).
	var thick := cell_px * 0.72
	var tile_along := thick * aspect ## ~2.25 cells for M
	var run_len := float(length) * cell_px
	var base := Vector2(float(ox) * cell_px, float(grid_h - 1 - oy) * cell_px)
	if not horizontal:
		base = Vector2(float(ox) * cell_px, float(grid_h - 1 - (oy + length - 1)) * cell_px)
	var along := -cell_px * 0.08
	while along < run_len + cell_px * 0.08:
		var seg_w := tile_along
		if horizontal:
			var dest := Rect2(
				base + Vector2(along, (cell_px - thick) * 0.38),
				Vector2(seg_w, thick)
			)
			draw_texture_rect(tex, dest, false, mod)
		else:
			var cx := base.x + cell_px * 0.5
			var cy := base.y + along + seg_w * 0.5
			var xform := Transform2D(Vector2(0.0, -1.0), Vector2(1.0, 0.0), Vector2(cx, cy))
			draw_set_transform_matrix(xform)
			draw_texture_rect(tex, Rect2(Vector2(-seg_w * 0.5, -thick * 0.5), Vector2(seg_w, thick)), false, mod)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		along += seg_w * 0.72 ## heavy overlap → continuous burlap wall
	# Caps / joints only at true elbows.
	if length < 2:
		return
	var cap: Texture2D = _g3_bag("sandbag_end_cap")
	var ends: Array = [[ox, oy], [ox + length - 1, oy]] if horizontal else [[ox, oy], [ox, oy + length - 1]]
	for e in ends:
		var ex: int = e[0]
		var ey: int = e[1]
		var n := _cover_at(ex, ey + 1)
		var s := _cover_at(ex, ey - 1)
		var ee := _cover_at(ex + 1, ey)
		var w := _cover_at(ex - 1, ey)
		var count := int(n) + int(s) + int(ee) + int(w)
		if count == 2 and ((n or s) and (ee or w)):
			_draw_g3_bag_joint(ex, ey)
			continue
		if count == 3:
			_draw_g3_bag_joint(ex, ey)
			continue
		if cap == null:
			continue
		var base2 := Vector2(float(ex) * cell_px, float(grid_h - 1 - ey) * cell_px)
		var cap_sz := cell_px * 0.48
		draw_texture_rect(
			cap,
			Rect2(base2 + Vector2((cell_px - cap_sz) * 0.5, (cell_px - cap_sz) * 0.40), Vector2(cap_sz, cap_sz)),
			false,
			mod
		)


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
		var sid := str(s.get("id", ""))
		var x := int(s.get("x", -1))
		var y := int(s.get("y", -1))
		if x < 0:
			continue
		if not _supply_should_draw(s, sid):
			continue
		var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
		var tex: Texture2D = g2.prop_crate
		if tex:
			draw_texture_rect(tex, Rect2(p + Vector2(cell_px * 0.1, cell_px * 0.1), Vector2(cell_px * 0.8, cell_px * 0.8)), false)
		_draw_supply_state_badge(sid, x, y)
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
	var map_rect := Rect2(Vector2.ZERO, Vector2(grid_w * cell_px, grid_h * cell_px))
	var pts := PackedVector2Array()
	pts.append(origin.clamp(map_rect.position, map_rect.end))
	var steps := maxi(8, int(half * 2.0))
	for i in range(steps + 1):
		var a := facing - half + (2.0 * half) * (float(i) / float(steps))
		var rad := deg_to_rad(a)
		# Screen: +x east, +y screen-down = -world-y; world 0°=east CCW.
		var wx := (ox + 0.5) + rng * cos(rad)
		var wy := (oy + 0.5) + rng * sin(rad)
		var p := Vector2(wx * cell_px, (float(grid_h) - wy) * cell_px)
		pts.append(p.clamp(map_rect.position, map_rect.end))
	if outline_only:
		for i in range(1, pts.size()):
			_draw_line_clipped(pts[i - 1] if i > 1 else pts[0], pts[i], col, 2.0, map_rect)
		if pts.size() > 1:
			_draw_line_clipped(pts[0], pts[1], col, 2.0, map_rect)
			_draw_line_clipped(pts[0], pts[pts.size() - 1], col, 2.0, map_rect)
	else:
		draw_colored_polygon(pts, col)


func _draw_line_clipped(a: Vector2, b: Vector2, col: Color, width: float, rect: Rect2) -> void:
	## Cohen–Sutherland-ish clamp: skip if both ends outside same half-plane after clamp.
	var aa := a.clamp(rect.position, rect.end)
	var bb := b.clamp(rect.position, rect.end)
	if aa.distance_squared_to(bb) < 0.25:
		return
	draw_line(aa, bb, col, width)


func _draw_aim_preview() -> void:
	## Ghost cone + tip handle while re-aim dragging (WAIT / SETUP preview).
	if aim_preview_op == "" or is_nan(aim_preview_deg):
		# Still draw aim handle on selected unit tip when idle-selected.
		if selected_op_id == "":
			return
		var sop := {}
		for o in operators:
			if str(o.get("id", "")) == selected_op_id and bool(o.get("alive", true)):
				sop = o
				break
		if sop.is_empty():
			return
		var wid0 := str(sop.get("weapon_id", ""))
		var w0: Dictionary = weapons.get(wid0, {})
		var rng0 := float(w0.get("max_range", 6.0))
		var tip0 := cell_to_screen(
			float(sop["x"]) + cos(deg_to_rad(float(sop["facing_deg"]))) * minf(rng0, 3.0),
			float(sop["y"]) + sin(deg_to_rad(float(sop["facing_deg"]))) * minf(rng0, 3.0)
		)
		draw_circle(tip0, 10.0, Color(0.95, 0.9, 0.35, 0.85))
		draw_arc(tip0, 14.0, 0, TAU, 20, Color(1.0, 0.95, 0.4, 0.7), 2.0)
		return
	var op := {}
	for o in operators:
		if str(o.get("id", "")) == aim_preview_op:
			op = o
			break
	if op.is_empty():
		return
	var wid := str(op.get("weapon_id", ""))
	var w: Dictionary = weapons.get(wid, {})
	var half := float(w.get("sector_deg", 40)) * 0.5
	var rng := float(w.get("max_range", 8.0))
	var ox := float(op["x"])
	var oy := float(op["y"])
	_draw_wedge(ox, oy, aim_preview_deg, half, rng, Color(0.55, 0.85, 1.0, 0.14), false)
	_draw_wedge(ox, oy, aim_preview_deg, half, rng, Color(0.6, 0.9, 1.0, 0.85), true)
	var tip := cell_to_screen(
		ox + cos(deg_to_rad(aim_preview_deg)) * minf(rng, 3.0),
		oy + sin(deg_to_rad(aim_preview_deg)) * minf(rng, 3.0)
	)
	draw_circle(tip, 12.0, Color(0.55, 0.9, 1.0, 0.95))
	var cur := float(op.get("facing_deg", 0.0))
	var delta := SimGeom.abs_angle_delta_deg(cur, aim_preview_deg)
	var steps := int(ceil(delta / 45.0 - 1e-9))
	var cost_s := float(steps) * SimConstants.TURN_COST_S_PER_45
	draw_string(
		ThemeDB.fallback_font,
		tip + Vector2(14, -8),
		"转向 %.0fs" % cost_s,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color(0.75, 0.95, 1.0, 0.98)
	)


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
	## G3: no red debug X squares — cover/props carry the read.
	if art_mode == ArtMode.G3:
		return
	if assets.threat_slot == null:
		return
	for c in threat_slot_cells:
		var p := Vector2(c.x * cell_px, (grid_h - 1 - c.y) * cell_px)
		draw_texture_rect(assets.threat_slot, Rect2(p, Vector2(cell_px, cell_px)), false)


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


func _draw_bodies() -> void:
	## Killed enemies leave a body sprite on the map (PLAY-3).
	if combat_fx == null:
		return
	var base_xform := shake_offset
	for id in combat_fx.bodies.keys():
		var b: Dictionary = combat_fx.bodies[id]
		var x := float(b.get("x", 0.0))
		var y := float(b.get("y", 0.0))
		var facing := float(b.get("facing_deg", 0.0))
		var age := float(b.get("age", 0.0))
		var fall := clampf(age / CombatFxScript.BODY_FALL_S, 0.0, 1.0)
		var p := cell_to_screen(x, y)
		var etex: Texture2D = assets.enemy
		if art_mode == ArtMode.G3 and g3 != null:
			etex = g3.units.get("enemy_rifle", etex)
		var sz := cell_px * (0.95 if art_mode == ArtMode.G3 else 0.85)
		# Lie flat: squash + darken.
		var rot := deg_to_rad(facing + 90.0 * fall)
		var col := Color(0.35, 0.32, 0.30, 0.92)
		draw_circle(p + Vector2(0, cell_px * 0.12), cell_px * 0.18, Color(0.35, 0.05, 0.05, 0.45))
		if etex:
			draw_set_transform(base_xform + p, rot, Vector2(1.0, 0.55 + 0.45 * (1.0 - fall)))
			draw_texture_rect(etex, Rect2(Vector2(-sz * 0.5, -sz * 0.5), Vector2(sz, sz)), false, col)
			draw_set_transform(base_xform, 0.0, Vector2.ONE)
		else:
			draw_circle(p, cell_px * 0.28, col)
		# PLAY-5: lootable body marker until searched.
		if body_search_enabled and not searched_bodies.has(str(id)):
			var pulse := 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.006))
			draw_arc(p, cell_px * 0.55, 0, TAU, 24, Color(1.0, 0.85, 0.3, pulse), 2.4)
			draw_string(
				ThemeDB.fallback_font,
				p + Vector2(-14, cell_px * 0.7),
				"搜尸",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				12,
				Color(1.0, 0.9, 0.4, 0.95)
			)


func _draw_combat_fx() -> void:
	if combat_fx == null:
		return
	for tr in combat_fx.tracers:
		var a := cell_to_screen(float(tr["x0"]), float(tr["y0"]))
		var b := cell_to_screen(float(tr["x1"]), float(tr["y1"]))
		var t := 1.0 - float(tr["age"]) / maxf(0.001, float(tr["life"]))
		var wid := str(tr.get("weapon_id", ""))
		# Phone-readable tracers: thicker core + short soft glow halo.
		var col := Color(1.0, 0.92, 0.45, 0.95 * t)
		var glow_col := Color(1.0, 0.75, 0.25, 0.42 * t)
		var width := 4.5
		var glow_w := 9.0
		if wid == "mg42":
			col = Color(1.0, 0.62, 0.22, 0.98 * t)
			glow_col = Color(1.0, 0.4, 0.1, 0.5 * t)
			width = 5.5
			glow_w = 11.0
		elif wid == "mp40":
			col = Color(1.0, 0.82, 0.48, 0.92 * t)
			glow_col = Color(1.0, 0.65, 0.3, 0.4 * t)
			width = 4.0
			glow_w = 8.0
		elif wid == "enemy_rifle":
			col = Color(1.0, 0.35, 0.28, 0.95 * t)
			glow_col = Color(0.95, 0.2, 0.15, 0.45 * t)
			width = 3.8
			glow_w = 8.0
		draw_line(a, b, glow_col, glow_w)
		draw_line(a, b, col, width)
		draw_circle(b, 4.0, Color(1.0, 0.98, 0.82, 0.95 * t))
		draw_circle(b, 7.0, Color(1.0, 0.85, 0.4, 0.35 * t))
	for fl in combat_fx.flashes:
		var p := cell_to_screen(float(fl["x"]), float(fl["y"]))
		var facing := float(fl.get("facing_deg", 0.0))
		# Screen: +x east, +y south-screen = -world-y → convert facing to screen angle.
		var ang := deg_to_rad(-facing)
		var t := 1.0 - float(fl["age"]) / maxf(0.001, float(fl["life"]))
		var wid := str(fl.get("weapon_id", ""))
		var reach := cell_px * (0.85 if wid == "mg42" else 0.62)
		var tip := p + Vector2(cos(ang), sin(ang)) * reach
		var side := Vector2(-sin(ang), cos(ang))
		var hw := cell_px * (0.38 if wid == "mg42" else 0.26)
		var poly := PackedVector2Array([
			tip,
			p + side * hw * 0.45,
			p - Vector2(cos(ang), sin(ang)) * cell_px * 0.12,
			p - side * hw * 0.45,
		])
		var glow := Color(1.0, 0.55, 0.15, 0.85 * t) if wid == "mg42" else Color(1.0, 0.82, 0.35, 0.8 * t)
		# Soft bloom behind the flash cone (phone-readable).
		draw_circle(p + Vector2(cos(ang), sin(ang)) * reach * 0.35, cell_px * 0.42, Color(glow.r, glow.g, glow.b, 0.35 * t))
		draw_colored_polygon(poly, glow)
		draw_circle(tip, cell_px * 0.16, Color(1.0, 0.97, 0.8, 0.98 * t))
		draw_circle(tip, cell_px * 0.28, Color(1.0, 0.85, 0.4, 0.4 * t))
	for h in combat_fx.hits:
		var p := cell_to_screen(float(h["x"]), float(h["y"]))
		var t := 1.0 - float(h["age"]) / maxf(0.001, float(h["life"]))
		var r := cell_px * 0.35 * (0.5 + 0.5 * t)
		for i in range(6):
			var a := deg_to_rad(float(i) * 60.0 + 10.0)
			var tip2 := p + Vector2(cos(a), sin(a)) * r
			draw_line(p, tip2, Color(1.0, 0.9, 0.45, 0.9 * t), 1.8)
		draw_circle(p, cell_px * 0.1, Color(1.0, 1.0, 0.85, 0.85 * t))
	for bl in combat_fx.blasts:
		var p := cell_to_screen(float(bl["x"]), float(bl["y"]))
		var t := 1.0 - float(bl["age"]) / maxf(0.001, float(bl["life"]))
		var R := cell_px * (1.6 if str(bl.get("kind", "")) == "mine" else 1.3) * (0.4 + 0.6 * t)
		draw_circle(p, R, Color(1.0, 0.45, 0.12, 0.35 * t))
		draw_circle(p, R * 0.55, Color(1.0, 0.85, 0.3, 0.55 * t))
		draw_circle(p, R * 0.2, Color(1.0, 0.98, 0.9, 0.85 * t))


func _draw_units() -> void:
	for e in enemies:
		if not e.get("alive", true) or not e.get("entered", false) or e.get("escaped", false):
			continue
		# Skip living draw if already a body (shouldn't happen) 
		if combat_fx != null and combat_fx.bodies.has(str(e.get("id", ""))):
			continue
		var etex: Texture2D = assets.enemy
		if art_mode == ArtMode.G3 and g3 != null:
			etex = g3.units.get("enemy_rifle", etex)
		var efacing := 0.0
		if str(e.get("mode", "")) != "march":
			# Face nearest living operator while in combat.
			var best_d := 1e9
			for op2 in operators:
				if not op2.get("alive", true):
					continue
				var d2 := Vector2(float(op2["x"]) - float(e["x"]), float(op2["y"]) - float(e["y"])).length()
				if d2 < best_d:
					best_d = d2
					efacing = rad_to_deg(atan2(float(op2["y"]) - float(e["y"]), float(op2["x"]) - float(e["x"])))
		_draw_unit_tex(etex, float(e["x"]), float(e["y"]), efacing, false)
		if bool(e.get("in_cover", false)):
			var ep := cell_to_screen(float(e["x"]), float(e["y"]))
			draw_arc(ep, cell_px * 0.62, 0, TAU, 20, Color(0.35, 0.75, 1.0, 0.85), 2.2)
			draw_string(
				ThemeDB.fallback_font,
				ep + Vector2(-10, cell_px * 0.7),
				"掩体",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color(0.55, 0.85, 1.0, 0.95)
			)
		elif str(e.get("mode", "")) == "flee":
			var ep2 := cell_to_screen(float(e["x"]), float(e["y"]))
			draw_string(
				ThemeDB.fallback_font,
				ep2 + Vector2(-10, cell_px * 0.7),
				"逃",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color(1.0, 0.55, 0.35, 0.95)
			)
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
		# Selection: thick pulsing ring; unselected faint.
		var hp := cell_to_screen(float(op["x"]), float(op["y"]))
		if is_sel:
			var pulse := 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() * 0.007))
			var rw := sel_ring_width
			draw_arc(hp, cell_px * 0.82, 0, TAU, 36, Color(1.0, 0.95, 0.35, pulse), rw)
			draw_arc(hp, cell_px * 0.95, 0, TAU, 36, Color(1.0, 0.85, 0.2, 0.55 * pulse), rw * 0.6)
		else:
			draw_arc(hp, cell_px * 0.72, 0, TAU, 24, Color(1.0, 0.88, 0.25, 0.35), unsel_ring_width)
		if high:
			draw_arc(hp, cell_px * (1.05 if is_sel else 0.88), 0, TAU, 28, Color(1.0, 0.82, 0.16, 0.7 if is_sel else 0.35), 1.6)
		# PLAY-6 wounded: orange ring + label.
		if bool(op.get("wounded", false)):
			draw_arc(hp, cell_px * 0.68, 0, TAU, 24, Color(1.0, 0.45, 0.2, 0.95), 2.6)
			draw_string(
				ThemeDB.fallback_font,
				hp + Vector2(-14, cell_px * 0.85),
				"负伤",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				11,
				Color(1.0, 0.55, 0.3, 0.95)
			)
		# WAIT re-aim: turning indicator while turn_ticks_left > 0 (can't fire).
		var turn_left := int(op.get("turn_ticks_left", 0))
		if turn_left > 0:
			var spin := Time.get_ticks_msec() * 0.008
			var r := cell_px * (0.95 if art_mode == ArtMode.G3 else 0.62)
			draw_arc(hp, r, spin, spin + TAU * 0.72, 32, Color(0.55, 0.85, 1.0, 0.9), 3.0)
			draw_arc(hp, r * 0.82, -spin, -spin + TAU * 0.45, 24, Color(0.35, 0.7, 1.0, 0.55), 2.0)
			draw_string(
				ThemeDB.fallback_font,
				hp + Vector2(-14, cell_px * 0.72),
				"转向",
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				12,
				Color(0.7, 0.9, 1.0, 0.95)
			)
		# Name only on selected (avoid overlap clutter).
		if is_sel:
			var label := str(op_display_names.get(str(op["id"]), op.get("display_name", "队员")))
			draw_string(
				ThemeDB.fallback_font,
				hp + Vector2(-22, -cell_px * 0.7),
				label,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				14,
				Color(1.0, 0.98, 0.75, 0.98)
			)


func _draw_unit_tex(tex: Texture2D, x: float, y: float, facing_deg: float, selected: bool) -> void:
	if tex == null:
		return
	var p := cell_to_screen(x, y)
	var scale := G3_UNIT_SCALE if art_mode == ArtMode.G3 else 0.85
	var sz := Vector2(cell_px * scale, cell_px * scale)
	if art_mode == ArtMode.G3 and g3 != null and g3.drop_shadow:
		var sh := sz * 0.95
		draw_texture_rect(g3.drop_shadow, Rect2(p - sh * 0.5 + Vector2(3, 5), sh), false, Color(1, 1, 1, 0.85))
	# Rotate around center: draw via transform (restore shake_offset after).
	draw_set_transform(shake_offset + p, deg_to_rad(-facing_deg), Vector2.ONE) # screen y flip ⇒ negate angle
	draw_texture_rect(tex, Rect2(Vector2(-sz.x * 0.5, -sz.y * 0.5), sz), false)
	draw_set_transform(shake_offset, 0.0, Vector2.ONE)
	if selected and art_mode != ArtMode.G3:
		draw_arc(p, cell_px * 0.55, 0, TAU, 24, Color(1, 1, 0.4, 0.9), 2.0)


func _draw_alert_badge() -> void:
	var tex: Texture2D = assets.alert_icons.get(alert, null)
	if tex == null:
		return
	draw_texture_rect(tex, Rect2(Vector2(8, 8), Vector2(40, 40)), false)


func _gui_input(event: InputEvent) -> void:
	if gesture == null:
		_init_gesture_router()
	gesture.bounds = Rect2(Vector2.ZERO, size)
	if gesture.feed(event):
		accept_event()


func _on_gesture_tapped(pos: Vector2) -> void:
	tap_emit_count += 1
	var cell := screen_to_cell(pos)
	var hit := nearest_op_at(pos)
	if hit != "":
		selected_op_id = hit
		unit_selected.emit(hit)
		queue_redraw()
		return
	cell_tapped.emit(cell)


func _on_gesture_long_pressed(pos: Vector2) -> void:
	cell_long_pressed.emit(screen_to_cell(pos))


func _on_gesture_drag_started(pos: Vector2, start_pos: Vector2) -> void:
	var hit := nearest_op_at(start_pos)
	if hit == "":
		hit = nearest_op_at(pos)
	_dragging_op = hit
	_drag_start = start_pos
	aim_preview_op = hit
	if hit != "":
		selected_op_id = hit
		unit_selected.emit(hit)
		var origin := cell_to_screen(_op_pos(hit).x, _op_pos(hit).y)
		var dir := pos - origin
		aim_preview_deg = rad_to_deg(atan2(-dir.y, dir.x)) if dir.length() >= 1.0 else NAN
		aim_drag_started.emit(hit, pos)
	queue_redraw()


func _on_gesture_drag_moved(pos: Vector2, start_pos: Vector2) -> void:
	if _dragging_op == "":
		return
	drag_emit_count += 1
	var origin := cell_to_screen(_op_pos(_dragging_op).x, _op_pos(_dragging_op).y)
	var dir := pos - origin
	var cell := screen_to_cell(pos)
	cell_dragged.emit(cell, dir)
	if dir.length() >= 1.0:
		aim_preview_deg = rad_to_deg(atan2(-dir.y, dir.x))
		aim_drag_updated.emit(_dragging_op, dir, aim_preview_deg)
	queue_redraw()


func _on_gesture_drag_ended(pos: Vector2, start_pos: Vector2, cancelled: bool) -> void:
	var op_id := _dragging_op
	var origin := cell_to_screen(_op_pos(op_id).x, _op_pos(op_id).y) if op_id != "" else start_pos
	var dir := pos - origin
	var preview := aim_preview_deg
	# Cancel if released near the unit center (drag back).
	if op_id != "" and pos.distance_to(origin) < gesture.slop_px:
		cancelled = true
	if op_id != "":
		aim_drag_ended.emit(op_id, dir, preview, cancelled)
	_dragging_op = ""
	aim_preview_op = ""
	aim_preview_deg = NAN
	queue_redraw()


## Nearest living operator within unit_hit_radius_cells (0 = exact cell match).
func nearest_op_at(screen_pos: Vector2) -> String:
	if unit_hit_radius_cells <= 1e-9:
		return _op_at_cell(screen_to_cell(screen_pos))
	var best := ""
	var best_d := unit_hit_radius_cells + 1e-9
	# Continuous world cell space (Y flipped vs screen).
	var local := screen_pos - shake_offset
	var cx := local.x / maxf(cell_px, 1.0) - 0.5
	var cy := float(grid_h) - local.y / maxf(cell_px, 1.0) - 0.5
	for op in operators:
		if not bool(op.get("alive", true)):
			continue
		var d := Vector2(float(op["x"]) - cx, float(op["y"]) - cy).length()
		if d < best_d:
			best_d = d
			best = str(op["id"])
	return best


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


## Inject raw events for headless tests (bypasses Viewport).
func inject_input(event: InputEvent) -> void:
	_gui_input(event)
