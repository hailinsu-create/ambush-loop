class_name C2Minimap
extends Control

## Tiny Commandos overview. Click to pan the camera.

signal pan_requested(world: Vector2)

const COLS := 40
const ROWS := 22
const TILE := 32

var _host: Node = null
var _grid = null
var _historical := false
var _history: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(184, 104)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui)


func bind(host: Node) -> void:
	_historical = false
	_history = {}
	_host = host
	if host != null:
		_grid = host.get("grid")


func bind_history(frame: Dictionary) -> void:
	_historical = true
	_history = frame
	_host = null
	_grid = null
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _on_gui(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var local: Vector2 = ev.position
		var world := Vector2(
			(local.x / maxf(size.x, 1.0)) * float(COLS * TILE),
			(local.y / maxf(size.y, 1.0)) * float(ROWS * TILE)
		)
		pan_requested.emit(world)
		if _historical:
			accept_event()
			return
		if _host != null and _host.get("operators") is Array:
			var best = null
			var best_d := 80.0
			for op in _host.operators:
				if op == null or not op.visible:
					continue
				var d: float = op.global_position.distance_to(world)
				if d < best_d:
					best_d = d
					best = op
			if best != null and _host.has_method("_select_op"):
				_host._select_op(int(best.op_id) - 1)
		accept_event()


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.04, 0.82))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.36, 0.22, 0.75), false, 1.2)
	var f := ThemeDB.fallback_font
	if f:
		draw_string(f, Vector2(size.x * 0.5 - 4, 12), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.74, 0.38, 0.9))
		draw_colored_polygon(PackedVector2Array([
			Vector2(size.x * 0.5, 2), Vector2(size.x * 0.5 - 4, 9), Vector2(size.x * 0.5 + 4, 9)
		]), Color(0.82, 0.74, 0.38, 0.85))
	if _historical:
		_draw_history()
		return
	if _grid == null or _host == null:
		return
	var sx := w / float(COLS)
	var sy := h / float(ROWS)
	if _grid.has_method("is_blocked"):
		for y in ROWS:
			for x in COLS:
				if bool(_grid.is_blocked(x, y)):
					draw_rect(Rect2(x * sx, y * sy, sx, sy), Color(0.18, 0.14, 0.10, 0.7))
	var ops = _host.get("operators")
	if ops is Array:
		for op in ops:
			if op == null or not op.visible:
				continue
			var p: Vector2 = op.global_position
			var c := Vector2(p.x / float(COLS * TILE) * w, p.y / float(ROWS * TILE) * h)
			var col := OperatorUnit.role_kit_color(int(op.role))
			if _host.get("selected") == op:
				draw_arc(c, 4.2, 0.0, TAU, 10, NightOps.OLIVE_HI, 1.2, true)
			draw_circle(c, 2.4, col)
	var c2 = _host.get("c2")
	if c2 != null and c2.get("sentries") is Array:
		for s in c2.sentries:
			if s == null or not is_instance_valid(s) or not bool(s.visible):
				continue
			var p2: Vector2 = s.global_position
			var c2p := Vector2(p2.x / float(COLS * TILE) * w, p2.y / float(ROWS * TILE) * h)
			var scol := Color(0.82, 0.22, 0.16) if int(s.state) < 3 else Color(0.45, 0.45, 0.48)
			draw_circle(c2p, 2.0, scol)
	var stashes = _host.get("raid_stashes")
	if stashes is Array:
		for st in stashes:
			if st == null or not is_instance_valid(st) or bool(st.collected):
				continue
			var p3: Vector2 = st.global_position
			var c3 := Vector2(p3.x / float(COLS * TILE) * w, p3.y / float(ROWS * TILE) * h)
			draw_rect(Rect2(c3.x - 1.6, c3.y - 1.6, 3.2, 3.2), Color(0.88, 0.72, 0.28, 0.95))


func _draw_history() -> void:
	var blocked: PackedByteArray = _history.get("blocked", PackedByteArray())
	if blocked.size() == COLS * ROWS:
		for y in ROWS:
			for x in COLS:
				if blocked[y * COLS + x] != 0:
					draw_rect(Rect2(x * size.x / COLS, y * size.y / ROWS, size.x / COLS, size.y / ROWS), Color(0.18, 0.14, 0.10, 0.7))
	for group in ["ops", "enemies", "sentries", "stashes"]:
		for item in _history.get(group, []):
			if not bool(item.get("active", true)) or not item.has("pos"):
				continue
			var pos: Vector2 = item.pos
			var point := Vector2(pos.x / float(COLS * TILE) * size.x, pos.y / float(ROWS * TILE) * size.y)
			if group == "stashes":
				draw_rect(Rect2(point - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), Color(0.88, 0.72, 0.28, 0.95))
			else:
				var color := OperatorUnit.role_kit_color(int(item.get("role", 0))) if group == "ops" else Color(0.82, 0.22, 0.16)
				if not bool(item.get("alive", true)):
					color = Color(0.45, 0.45, 0.48)
				if group == "ops" and int(item.get("id", -2)) == int(_history.get("selected_id", -1)):
					draw_arc(point, 4.2, 0.0, TAU, 10, NightOps.OLIVE_HI, 1.2, true)
				draw_circle(point, 2.4 if group == "ops" else 2.0, color)
