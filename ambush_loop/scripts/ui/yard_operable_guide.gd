extends Label

## Observer only: never issues a gameplay command or serializes preparation state.
signal completed
var steps: Array[bool] = [false, false, false, false]
var move_requests: Dictionary = {}
var moved: Dictionary = {}
var facing_edited := false
var combat_started := false
var terminal_seen := false
var _completion_emitted := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 15)
	add_theme_color_override("font_color", Color("d5cfac"))
	add_theme_color_override("font_shadow_color", Color("101915"))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	refresh_copy()

func note_supply(kind: String, amount: int) -> void:
	if kind in ["rifle_ammo", "mg_ammo", "scout_ammo"] and amount > 0:
		steps[0] = true

func note_move(op: Node2D, destination: Vector2) -> void:
	if op.global_position.distance_to(destination) >= 24.0:
		move_requests[int(op.op_id)] = {"origin": op.global_position, "destination": destination}

func note_facing() -> void:
	facing_edited = true

func reset_session() -> void:
	steps.assign([false, false, false, false])
	move_requests.clear()
	moved.clear()
	facing_edited = false
	combat_started = false
	terminal_seen = false
	_completion_emitted = false
	refresh_copy()

func observe(main: Node) -> void:
	if main.level == null or str(main.level.level_id) != "yard": return
	if main.phase == main.Phase.SETUP:
		for op in main.operators:
			var key := int(op.op_id)
			if not move_requests.has(key) or not op.alive or not op.visible or op.is_moving(): continue
			var request: Dictionary = move_requests[key]
			var cell: Vector2i = op.grid_cell()
			if op.global_position.distance_to(request["destination"]) <= 4.0 and op.global_position.distance_to(request["origin"]) >= 24.0 and not main.grid.is_blocked(cell.x, cell.y):
				moved[key] = true
				move_requests.erase(key)
		steps[1] = steps[1] or (moved.size() >= 2 and facing_edited)
		if terminal_seen: steps[3] = true
	if combat_started:
		var spawned := false
		var consequence := false
		for event in main.battle_log.events:
			var kind := str(event.get("type", ""))
			spawned = spawned or kind == "spawn"
			consequence = consequence or kind in ["fire", "return_fire", "kill", "escape"] or (kind == "grenade" and int(event.get("payload", {}).get("hits", 0)) > 0)
		steps[2] = steps[2] or (spawned and consequence)
	terminal_seen = terminal_seen or main.battle_log.terminal_tick >= 0
	if steps[2] and main.phase == main.Phase.REPLAY: steps[3] = true
	refresh_copy()
	if steps.count(true) == 4 and not _completion_emitted:
		_completion_emitted = true
		completed.emit()

func refresh_copy() -> void:
	if steps.count(true) == 4:
		text = "✓ 训练完成 · 继续尝试自己的伏击方案"
		return
	var labels := ["搜集补给：走到西侧弹药箱，站定搜索", "布置射界：移动两名队员并调整朝向，高台可选", "发动伏击：开始交战，观察实际火力", "看结果：时间轴复盘，或失败后调整伏击"]
	var lines := PackedStringArray(["训练 · %d/4" % steps.count(true)])
	for i in 4: lines.append(("✓ " if steps[i] else "○ ") + labels[i])
	text = "\n".join(lines)
