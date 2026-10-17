extends Control
class_name GreyboxMap

## Thin orthographic top-down view over sim state. No gameplay logic.

const SimGeom := preload("res://sim/geom.gd")
const SimConstants := preload("res://sim/constants.gd")
const G1AssetsScript := preload("res://view/g1_assets.gd")

signal cell_tapped(cell: Vector2i)
signal cell_dragged(cell: Vector2i, world_dir: Vector2)
signal unit_selected(op_id: String)

var assets: G1Assets
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
var selected_op_id: String = ""
var threat_slot_cells: Array = [] ## Vector2i
var night: bool = true

var _dragging_op: String = ""
var _drag_start: Vector2 = Vector2.ZERO


func _ready() -> void:
	assets = G1AssetsScript.new()
	assets.load_all()
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
	_fit_cell_px()
	queue_redraw()


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


func _draw() -> void:
	if grid == null:
		return
	_draw_tiles()
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
			var tex: Texture2D = assets.tile_wall
			if kind in ["wall", "structure"] or bool(cell.get("blocks_all_los", false)):
				tex = assets.tile_wall
			elif kind in ["ramp", "slope"]:
				tex = assets.tile_ramp
			elif bool(cell.get("low_cover", false)):
				tex = assets.tile_low_cover
			elif tier == SimConstants.TIER_HIGH or kind == "high":
				tex = assets.tile_high
			else:
				tex = assets.tile_ground
			var p := Vector2(x * cell_px, (grid_h - 1 - y) * cell_px)
			if tex:
				draw_texture_rect(tex, Rect2(p, Vector2(cell_px, cell_px)), false)


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
		_draw_one_cone(
			sp.x, sp.y,
			float(cone_s.get("facing_deg", 0)),
			float(cone_s.get("angle_deg", 50)) * 0.5,
			float(cone_s.get("range_cells", 8)),
			str(s.get("tier", "ground")),
			Color(1.0, 0.55, 0.15, 0.28),
			Color(0.85, 0.3, 0.85, 0.35)
		)
	for p in patrols:
		var cone: Dictionary = p.get("cone", {})
		var facing := float(cone.get("facing_deg", 0))
		if alert == "area_alert" and p.has("alert_route") and typeof(p["alert_route"]) == TYPE_DICTIONARY:
			var ar: Dictionary = p["alert_route"]
			if ar.has("facing_deg"):
				facing = float(ar["facing_deg"])
		var pp := _observer_xy(p)
		_draw_one_cone(
			pp.x, pp.y, facing,
			float(cone.get("angle_deg", 50)) * 0.5,
			float(cone.get("range_cells", 6)),
			SimConstants.TIER_GROUND,
			Color(1.0, 0.55, 0.15, 0.22),
			Color(0.85, 0.3, 0.85, 0.35)
		)


func _draw_one_cone(
	ox: float, oy: float, facing: float, half: float, rng: float, otier: String,
	col_ground: Color, col_ext: Color
) -> void:
	## Ground-length wedge + distinct ×1.5 high-target extension outline.
	_draw_wedge(ox, oy, facing, half, rng, col_ground, false)
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
		# Use sim geometry for clear vs blocked (preview = sim).
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
		if assets.mine:
			draw_texture_rect(assets.mine, Rect2(p - Vector2(cell_px * 0.4, cell_px * 0.4), Vector2(cell_px * 0.8, cell_px * 0.8)), false)
	for g in grenade_plans:
		var p := cell_to_screen(float(g["aim_x"]), float(g["aim_y"]))
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
		_draw_unit_tex(assets.enemy, float(e["x"]), float(e["y"]), 0.0, false)
	for s in sentries:
		var sp := _observer_xy(s)
		_draw_unit_tex(assets.sentry, sp.x, sp.y, float(s.get("cone", {}).get("facing_deg", 0)), false)
	for p in patrols:
		var pp := _observer_xy(p)
		_draw_unit_tex(assets.sentry, pp.x, pp.y, float(p.get("cone", {}).get("facing_deg", 0)), false)
	for op in operators:
		if not op.get("alive", true):
			continue
		var high := str(op.get("tier", "ground")) == SimConstants.TIER_HIGH
		var tex := assets.friendly_high if high else assets.friendly
		_draw_unit_tex(tex, float(op["x"]), float(op["y"]), float(op["facing_deg"]), str(op["id"]) == selected_op_id)
		# id label
		var sp := cell_to_screen(float(op["x"]), float(op["y"]))
		draw_string(ThemeDB.fallback_font, sp + Vector2(-10, -cell_px * 0.55), str(op["id"]).substr(0, 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.95, 1.0))


func _draw_unit_tex(tex: Texture2D, x: float, y: float, facing_deg: float, selected: bool) -> void:
	if tex == null:
		return
	var p := cell_to_screen(x, y)
	var sz := Vector2(cell_px * 0.85, cell_px * 0.85)
	var rect := Rect2(p - sz * 0.5, sz)
	# Rotate around center: draw via transform
	draw_set_transform(p, deg_to_rad(-facing_deg), Vector2.ONE) # screen y flip ⇒ negate angle
	draw_texture_rect(tex, Rect2(-sz * 0.5, sz), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if selected:
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
