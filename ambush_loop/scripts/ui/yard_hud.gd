extends Control

## Yard presentation only. All commands still use the host's authoritative handlers.
var host: Node
var details_open := false
var heading: Label
var objective: Label
var selected_status: Label
var details_button: Button
var menu_button: Button
var commands: HBoxContainer
var result_replay: Button
var permission_mode_button: Button
var preview_3d_button: Button
var buttons: Dictionary = {}
var hidden_chrome: Dictionary = {}
var operable_guide: Label
var replay_slider_home: Node = null
var replay_slider_minimum := Vector2.ZERO
var replay_slider_touch := -1


func bind(main: Node) -> void:
	host = main
	name = "YardHud"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 8
	heading = _label(Vector2(16, 10), Vector2(650, 30), 22)
	objective = _label(Vector2(16, 42), Vector2(810, 28), 15)
	operable_guide = preload("res://scripts/ui/yard_operable_guide.gd").new()
	operable_guide.position = Vector2(16, 80)
	operable_guide.size = Vector2(470, 120)
	add_child(operable_guide)
	operable_guide.completed.connect(host._on_tutorial_dismissed)
	selected_status = _label(Vector2.ZERO, Vector2.ZERO, 14)
	selected_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	selected_status.offset_left = 380
	selected_status.offset_right = -16
	selected_status.offset_top = -126
	selected_status.offset_bottom = -76
	selected_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_button = _top_button("战术视图", -228, -112)
	details_button.pressed.connect(toggle_details)
	menu_button = _top_button("菜单", -104, -16)
	menu_button.pressed.connect(func(): host._toggle_pause_menu())
	preview_3d_button = _top_button("查看 3D 院子", -396, -240)
	preview_3d_button.custom_minimum_size = Vector2(156, 48)
	preview_3d_button.offset_bottom = 58
	preview_3d_button.pressed.connect(host.open_yard_3d)
	permission_mode_button = Button.new()
	permission_mode_button.position = Vector2(16, 80)
	permission_mode_button.size = Vector2(220, 48)
	permission_mode_button.custom_minimum_size = Vector2(220, 48)
	permission_mode_button.focus_mode = Control.FOCUS_NONE
	permission_mode_button.mouse_filter = Control.MOUSE_FILTER_STOP
	permission_mode_button.pressed.connect(func(): host.apply_touch_command("permission_mode"))
	add_child(permission_mode_button)
	commands = HBoxContainer.new()
	commands.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	commands.offset_left = -884
	commands.offset_right = -16
	commands.offset_top = -64
	commands.offset_bottom = -16
	commands.alignment = BoxContainer.ALIGNMENT_END
	commands.add_theme_constant_override("separation", 8)
	commands.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(commands)
	for spec in [["rotate_ccw", "↺", 54], ["rotate_cw", "↻", 54], ["fire", "开火模式", 160], ["bag", "背包", 76], ["pause", "暂停", 88], ["speed", "1×", 64], ["abort", "中止", 76], ["team_fire", "全队开火", 120], ["replay", "时间轴复盘", 120], ["alarm", "开始交战", 156]]:
		var button := Button.new()
		var cmd := str(spec[0])
		button.text = str(spec[1])
		button.custom_minimum_size = Vector2(int(spec[2]), 48)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		button.pressed.connect(func(): host.apply_touch_command(cmd))
		commands.add_child(button)
		buttons[cmd] = button
	buttons["alarm"].add_theme_stylebox_override("normal", NightOps.flat(Color(0.26, 0.30, 0.15), Color(0.82, 0.79, 0.39), 2, 10, 8))
	result_replay = Button.new()
	result_replay.text = "时间轴复盘"
	result_replay.focus_mode = Control.FOCUS_NONE
	result_replay.custom_minimum_size.y = 48
	result_replay.visible = false
	result_replay.pressed.connect(func(): host._on_replay_pressed())
	var result_box: VBoxContainer = host.continue_button.get_parent()
	result_box.add_child(result_replay)
	result_box.move_child(result_replay, host.continue_button.get_index())


func _label(pos: Vector2, extent: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = extent
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", NightOps.TEXT)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.02, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)
	return label


func _top_button(text: String, left: float, right: float) -> Button:
	var button := Button.new()
	button.text = text
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = left
	button.offset_right = right
	button.offset_top = 10
	button.offset_bottom = 50
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(button)
	return button


func toggle_details() -> void:
	if host == null or host._modal_blocks_input() or not host.yard_redesign_active():
		return
	details_open = not details_open
	host._update_hud()


func primary_text() -> String:
	if host.phase == host.Phase.SWEEP:
		return "完成行动" if host.raid.is_last_wave(host.level) else "继续交战"
	if host.phase == host.Phase.REPLAY:
		return "返回结算"
	if host.squad_has_firearm():
		return "开始交战"
	return "确认无枪交战" if host._alarm_warned_no_gun else "先搜集武器"


func refresh() -> void:
	visible = host.yard_redesign_active()
	result_replay.visible = visible and host._result_overlay_active() and not host._want_touch()
	if not visible:
		selected_status.visible = false
		return
	var result_open: bool = host._result_overlay_active()
	var phone: bool = host._want_touch()
	var status_parent: Control = host.touch_hud.portrait_slot().get_parent() if phone else self
	if selected_status.get_parent() != status_parent:
		selected_status.reparent(status_parent, false)
		selected_status.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		selected_status.offset_left = 380
		selected_status.offset_right = -16
		selected_status.offset_top = -126
		selected_status.offset_bottom = -76
	selected_status.z_index = 8
	var command_phase: bool = host._is_command_phase()
	var watching: bool = host.phase == host.Phase.WATCHING
	var replaying: bool = host.phase == host.Phase.REPLAY
	# Keep the original read-only slider and handler, outside hidden legacy chrome.
	if host.scrub_slider:
		if replay_slider_home == null:
			replay_slider_home = host.scrub_slider.get_parent()
			replay_slider_minimum = host.scrub_slider.custom_minimum_size
			host.scrub_slider.gui_input.connect(_on_replay_slider_gui)
		var slider_parent: Control = host.touch_hud.replay_controls() if phone else self
		if host.scrub_slider.get_parent() != slider_parent:
			host.scrub_slider.reparent(slider_parent, false)
			if phone: slider_parent.move_child(host.scrub_slider, 0)
		host.scrub_slider.custom_minimum_size = Vector2(220, 48)
		if not phone:
			host.scrub_slider.set_anchors_preset(Control.PRESET_TOP_LEFT)
			host.scrub_slider.position = Vector2(16, 80)
			host.scrub_slider.size = Vector2(470, 48)
		host.scrub_slider.visible = replaying and not result_open
		if not replaying: replay_slider_touch = -1
	operable_guide.visible = not result_open and not details_open and not replaying and not host._gs().has_seen_tutorial("yard")
	permission_mode_button.visible = details_open and not result_open and host.phase == host.Phase.SETUP
	permission_mode_button.text = "发动：手动许可（实验）" if host.yard_manual_permission else "发动：入伏自动（默认）"
	permission_mode_button.tooltip_text = "仅待伏队员：自动在黄色区入伏许可；手动在交战中许可一次。不改变随遇开火或自动投雷。"
	var phase_text := "准备"
	if watching:
		phase_text = "交战 · %.1fs" % host.sim.time_sec()
	elif host.phase == host.Phase.SWEEP:
		phase_text = "战后整理"
	elif replaying:
		phase_text = "复盘"
	heading.text = "院子 · %s" % phase_text
	objective.text = "搜集弹药，封锁主路和侧巷；阻止敌人从出口逃离。"
	heading.visible = not result_open and not watching
	objective.visible = not result_open and not watching and not replaying
	details_button.visible = not result_open
	menu_button.visible = not result_open
	preview_3d_button.visible = not result_open and host.get_node_or_null("I0YardPresentation") == null
	details_button.text = "收起战术" if details_open else "战术视图"
	details_button.tooltip_text = "查看路线、时间轴和方向参考；青色菱形表示选中队员的射线覆盖。"
	commands.visible = not phone and not result_open
	selected_status.visible = not result_open and command_phase
	if host.selected:
		var op = host.selected
		selected_status.text = "%s · %s · %d 发 · 朝%s · %s\n%s" % [op.display_name, WeaponCatalog.display_name(op.weapon_id), op.ammo, op.facing_compass(), op.fire_mode_label(), "先搜集武器" if op.melee else ("弹药已耗尽" if op.ammo <= 0 else "青色菱形：这名队员有射线的路线点；开火仍受弹药与许可限制。")]
	for cmd in buttons:
		var button: Button = buttons[cmd]
		button.visible = (command_phase and cmd in ["rotate_ccw", "rotate_cw", "fire", "bag", "alarm"]) or (watching and cmd in ["pause", "speed", "abort"]) or (replaying and cmd == "alarm")
		button.disabled = false
	buttons["alarm"].text = primary_text()
	buttons["alarm"].disabled = host._living_ops() < 1 and command_phase
	buttons["fire"].text = host.selected.fire_mode_label() if host.selected else "开火模式"
	buttons["pause"].text = "继续" if host.sim.paused else "暂停"
	buttons["speed"].text = "2×" if host.sim.speed >= 1.5 else "1×"
	buttons["team_fire"].visible = not result_open and host.team_permission_visible()
	buttons["team_fire"].text = host.team_permission_text()
	buttons["team_fire"].disabled = host._manual_permission_queued or host._manual_permission_used
	for node in [host.title_label.get_parent(), host.role_box, host.help_label, host.extra_bar, host.get_node("HUD/Root/BottomBar"), host.plan_readout, host.phase_chip, host.intel_chip, host.route_legend, host.spawn_teach_label]:
		if node:
			if not hidden_chrome.has(node):
				hidden_chrome[node] = node.visible
			node.visible = false
	if host.checklist_strip:
		host.checklist_strip.visible = false
	if host.watch_timeline:
		host.watch_timeline.visible = details_open and (command_phase or watching)
	if host.route_timeline:
		host.route_timeline.visible = host.phase == host.Phase.REPLAY
	if host._watch_letterbox:
		var banner: Label = host._watch_letterbox.get_node_or_null("WatchBanner")
		if banner and watching:
			banner.text = "交战 · 部署已锁定 · %s · %.1fs" % ["暂停" if host.sim.paused else ("2×" if host.sim.speed >= 1.5 else "1×"), host.sim.time_sec()]
	for op in host.operators:
		if op.tag:
			op.tag.visible = details_open and not phone
		if op.tag_plate:
			op.tag_plate.visible = details_open and not phone
		if op.face_chip:
			op.face_chip.visible = details_open and not phone
		if op.compass_rose:
			op.compass_rose.visible = details_open
	if host.c2:
		if host.c2.portraits:
			host.c2.portraits.visible = not result_open
		if host.c2.minimap:
			host.c2.minimap.visible = details_open and not phone and not result_open
			host.c2.minimap.offset_top = 80
			host.c2.minimap.offset_bottom = 184
		if host.c2.skill_bar:
			host.c2.skill_bar.visible = details_open and not phone and command_phase and not result_open
		if host.c2.help_chip:
			host.c2.help_chip.visible = false
	if phone and host.touch_hud:
		host.touch_hud.set_alarm_cta(primary_text())
		host.touch_hud._hint.visible = false
		if host.selected:
			selected_status.text = "%s · %s · %d 发 · 朝%s\n按住↺/↻转向 · 长按队员打开技能" % [host.selected.display_name, WeaponCatalog.display_name(host.selected.weapon_id), host.selected.ammo, host.selected.facing_compass()]


func _on_replay_slider_gui(event: InputEvent) -> void:
	if not host.yard_redesign_active() or host.phase != host.Phase.REPLAY: return
	# Godot Range's mouse path remains intact; explicit native touch uses GUI-local X.
	if event is InputEventScreenTouch:
		if event.pressed and replay_slider_touch < 0:
			replay_slider_touch = event.index
			host.scrub_slider.value = clampf(event.position.x / maxf(host.scrub_slider.size.x, 1.0), 0.0, 1.0)
		elif not event.pressed and event.index == replay_slider_touch:
			replay_slider_touch = -1
		host.scrub_slider.accept_event()
	elif event is InputEventScreenDrag and event.index == replay_slider_touch:
		host.scrub_slider.value = clampf(event.position.x / maxf(host.scrub_slider.size.x, 1.0), 0.0, 1.0)
		host.scrub_slider.accept_event()


func restore_chrome() -> void:
	if host.scrub_slider and is_instance_valid(replay_slider_home):
		if host.scrub_slider.get_parent() != replay_slider_home:
			host.scrub_slider.reparent(replay_slider_home, false)
		host.scrub_slider.custom_minimum_size = replay_slider_minimum
	for node in hidden_chrome:
		if is_instance_valid(node):
			node.visible = bool(hidden_chrome[node])
	hidden_chrome.clear()
	if host.touch_hud:
		host.touch_hud._hint.visible = true
	if host.c2 and host.c2.minimap:
		host.c2.minimap.offset_top = 44
		host.c2.minimap.offset_bottom = 148


static func failure_observations(main: Node) -> PackedStringArray:
	var out := PackedStringArray()
	var event: Dictionary = main.battle_log.last_of_type("escape")
	if event.is_empty():
		out.append(main.battle_log.terminal_summary_line())
		return out
	out.append(main.battle_log.format_event(event))
	var target := int(event.get("actor_id", -1))
	var terminal_tick := int(event.get("tick", 0))
	for op in main.operators:
		var latest: Dictionary = {}
		for i in range(main.battle_log.events.size() - 1, -1, -1):
			var observed: Dictionary = main.battle_log.events[i]
			if int(observed.get("actor_id", -1)) == int(op.op_id) and int(observed.get("target_id", -1)) == target and int(observed.get("tick", 0)) <= terminal_tick and str(observed.get("type", "")) in ["fire", "no_engage"]:
				latest = observed
				break
		if latest.is_empty():
			out.append("%s：没有对此目标的射击或受阻记录" % op.display_name)
		else:
			var time := float(latest.get("tick", 0)) / 60.0
			var reason: String = "曾开火" if str(latest.get("type", "")) == "fire" else main.battle_log._no_engage_reason_zh(str(latest.get("payload", {}).get("reason", "")))
			out.append("%s · 最近记录 %.1fs：%s" % [op.display_name, time, reason])
	return out
