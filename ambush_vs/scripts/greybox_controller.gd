extends Control
class_name GreyboxController

## Playable yard greybox: SETUP → WAIT → RESULT. View is thin; sim owns outcomes.

const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const SimConstants := preload("res://sim/constants.gd")
const SimGeom := preload("res://sim/geom.gd")
const GreyboxMapScript := preload("res://view/greybox_map.gd")
const G2AssetsScript := preload("res://view/g2_assets.gd")
const G2SfxPlayerScript := preload("res://view/g2_sfx_player.gd")

enum UiPhase { SETUP, WAIT, RESULT }

var ui_phase: UiPhase = UiPhase.SETUP
var level: Dictionary = {}
var weapons: Dictionary = {}
var plan: Dictionary = {}
var sim: NightSim = null
var grid = null

var paused: bool = false
var speed_mul: float = 1.0
var _accum_s: float = 0.0
var preview_cell: Vector2i = Vector2i(-1, -1)
var preview_seers: Array = []
var selected_op_id: String = ""
var last_summary: Dictionary = {}
var _headless_auto: bool = false
var _capture_path: String = ""
var use_g2_art: bool = true
var _last_alert: String = "quiet"
var _detonate_sfx_played: bool = false
var g2_assets = null
var sfx = null

@onready var map_view: GreyboxMap = $MapHost/GreyboxMap
@onready var hud: Control = $HUD
@onready var label_phase: Label = $HUD/TopBar/PhaseLabel
@onready var label_info: Label = $HUD/TopBar/InfoLabel
@onready var label_alert: Label = $HUD/TopBar/AlertLabel
@onready var btn_plan_a: Button = $HUD/SetupPanel/PlanAButton
@onready var btn_plan_b: Button = $HUD/SetupPanel/PlanBButton
@onready var btn_start: Button = $HUD/SetupPanel/StartButton
@onready var btn_preview: Button = $HUD/SetupPanel/PreviewButton
@onready var btn_g2_art: Button = $HUD/SetupPanel/G2ArtButton
@onready var trigger_option: OptionButton = $HUD/SetupPanel/TriggerOption
@onready var setup_panel: Control = $HUD/SetupPanel
@onready var wait_panel: Control = $HUD/WaitPanel
@onready var result_panel: Control = $HUD/ResultPanel
@onready var result_label: Label = $HUD/ResultPanel/ResultLabel
@onready var btn_pause: Button = $HUD/WaitPanel/PauseButton
@onready var btn_speed: Button = $HUD/WaitPanel/SpeedButton
@onready var btn_detonate: Button = $HUD/WaitPanel/DetonateButton
@onready var btn_restart: Button = $HUD/ResultPanel/RestartButton
@onready var btn_restart_wait: Button = $HUD/WaitPanel/RestartWaitButton


func _ready() -> void:
	_apply_cjk_font()
	g2_assets = G2AssetsScript.new()
	g2_assets.load_all()
	sfx = G2SfxPlayerScript.new()
	add_child(sfx)
	sfx.configure(g2_assets)
	level = SimLevelLoader.load_path("res://data/levels/yard.json")
	weapons = SimWeapons.load_csv()
	grid = SimLevelLoader.build_grid(level)
	map_view.configure(level, grid, weapons)
	map_view.set_use_g2_art(use_g2_art)
	map_view.cell_tapped.connect(_on_cell_tapped)
	map_view.cell_dragged.connect(_on_cell_dragged)
	map_view.unit_selected.connect(_on_unit_selected)

	btn_plan_a.pressed.connect(func(): _ui_tap(); _load_preset("A"))
	btn_plan_b.pressed.connect(func(): _ui_tap(); _load_preset("B"))
	btn_start.pressed.connect(func(): _ui_tap(); _start_wait())
	btn_preview.pressed.connect(func(): _ui_tap(); _toggle_preview_hint())
	btn_pause.pressed.connect(func(): _ui_tap(); _toggle_pause())
	btn_speed.pressed.connect(func(): _ui_tap(); _cycle_speed())
	btn_detonate.pressed.connect(func(): _ui_tap(); _manual_detonate())
	btn_restart.pressed.connect(func(): _ui_tap(); _restart())
	btn_restart_wait.pressed.connect(func(): _ui_tap(); _restart())
	if btn_g2_art:
		btn_g2_art.pressed.connect(_toggle_g2_art)
		_refresh_g2_button()

	_fill_trigger_options()
	_load_preset("A")
	_set_ui_phase(UiPhase.SETUP)

	# Headless automation hooks (W3 test / PNG capture).
	_headless_auto = str(OS.get_environment("AMBUSH_GREYBOX_AUTO")).to_lower() in ["1", "true", "a"]
	_capture_path = str(OS.get_environment("AMBUSH_GREYBOX_CAPTURE"))
	var g2_env := str(OS.get_environment("AMBUSH_GREYBOX_G2")).to_lower()
	if g2_env in ["0", "false", "off"]:
		use_g2_art = false
		map_view.set_use_g2_art(false)
		_refresh_g2_button()
	if _headless_auto:
		call_deferred("_auto_run_plan_a")


func _apply_cjk_font() -> void:
	var font_res = load("res://ui/fonts/web_ui_font.tres")
	if font_res == null:
		return
	for n in [label_phase, label_info, label_alert, result_label, btn_plan_a, btn_plan_b, btn_start, btn_preview, btn_g2_art, btn_pause, btn_speed, btn_detonate, btn_restart, btn_restart_wait, trigger_option]:
		if n:
			n.add_theme_font_override("font", font_res)
	if trigger_option:
		var popup := trigger_option.get_popup()
		if popup:
			popup.add_theme_font_override("font", font_res)


func _ui_tap() -> void:
	if sfx:
		sfx.play("ui_tap", -8.0)


func _toggle_g2_art() -> void:
	_ui_tap()
	use_g2_art = not use_g2_art
	map_view.set_use_g2_art(use_g2_art)
	_refresh_g2_button()
	label_info.text = "G2 美术：%s（G1 锥/扇/标记仍叠加）" % ("开" if use_g2_art else "关")


func _refresh_g2_button() -> void:
	if btn_g2_art == null:
		return
	btn_g2_art.text = "G2 美术：开" if use_g2_art else "G2 美术：关"


func _fill_trigger_options() -> void:
	trigger_option.clear()
	trigger_option.add_item("见首敌 (see_first_enemy)", 0)
	trigger_option.set_item_metadata(0, "see_first_enemy")
	trigger_option.add_item("地雷 (mine)", 1)
	trigger_option.set_item_metadata(1, "mine_detonate")
	trigger_option.add_item("越线标记 (cross_marker)", 2)
	trigger_option.set_item_metadata(2, "cross_marker")
	trigger_option.add_item("手动 (manual)", 3)
	trigger_option.set_item_metadata(3, "manual")
	trigger_option.item_selected.connect(_on_trigger_selected)


func _load_preset(which: String) -> void:
	var path := "res://data/fixtures/plan_a.json" if which == "A" else "res://data/fixtures/plan_b.json"
	plan = SimRunner.load_json(path).duplicate(true)
	selected_op_id = str(plan.get("operators", [{}])[0].get("id", "")) if plan.get("operators", []) else ""
	_sync_trigger_option_from_plan()
	_push_map_snapshot()
	label_info.text = "方案 %s 已加载 · 可微调站位/朝向后开始" % which


func _sync_trigger_option_from_plan() -> void:
	var t := str(plan.get("trigger", {}).get("type", "manual"))
	for i in range(trigger_option.item_count):
		if str(trigger_option.get_item_metadata(i)) == t:
			trigger_option.select(i)
			return


func _on_trigger_selected(idx: int) -> void:
	if ui_phase != UiPhase.SETUP:
		return
	var t := str(trigger_option.get_item_metadata(idx))
	match t:
		"see_first_enemy":
			plan["trigger"] = {"type": "see_first_enemy", "bind": selected_op_id if selected_op_id else "op_kar_L"}
		"mine_detonate":
			if plan.get("mines", []).is_empty():
				plan["mines"] = [{"id": "mine_11_6", "x": 11, "y": 6}]
			plan["trigger"] = {"type": "mine_detonate", "bind": str(plan["mines"][0]["id"])}
		"cross_marker":
			plan["trigger"] = {
				"type": "cross_marker",
				"bind": "marker_y7",
				"a": {"x": 10, "y": 7},
				"b": {"x": 12, "y": 7},
			}
		"manual":
			plan["trigger"] = {"type": "manual"}
	_push_map_snapshot()


func _set_ui_phase(p: UiPhase) -> void:
	ui_phase = p
	setup_panel.visible = p == UiPhase.SETUP
	wait_panel.visible = p == UiPhase.WAIT
	result_panel.visible = p == UiPhase.RESULT
	match p:
		UiPhase.SETUP:
			label_phase.text = "布阵 SETUP"
		UiPhase.WAIT:
			label_phase.text = "等待 WAIT"
		UiPhase.RESULT:
			label_phase.text = "结算 RESULT"


func _start_wait() -> void:
	if plan.get("operators", []).is_empty():
		label_info.text = "请先加载方案或放置队员"
		return
	var trig: Dictionary = plan.get("trigger", {})
	if trig.is_empty() or str(trig.get("type", "")) == "":
		label_info.text = "必须选择一个起爆条件"
		return
	sim = NightSim.new()
	sim.setup(level, plan, weapons)
	sim.begin_wait()
	paused = false
	speed_mul = 1.0
	_accum_s = 0.0
	_last_alert = str(sim.alert)
	_detonate_sfx_played = false
	btn_speed.text = "倍速 1×"
	_set_ui_phase(UiPhase.WAIT)
	_push_map_snapshot()
	if _capture_path != "" and str(OS.get_environment("AMBUSH_GREYBOX_SHOT")) == "setup":
		# captured before start in auto path
		pass


func _toggle_pause() -> void:
	paused = not paused
	btn_pause.text = "继续" if paused else "暂停"


func _cycle_speed() -> void:
	if speed_mul < 1.5:
		speed_mul = 2.0
		btn_speed.text = "倍速 2×"
	else:
		speed_mul = 1.0
		btn_speed.text = "倍速 1×"


func _manual_detonate() -> void:
	if sim == null or ui_phase != UiPhase.WAIT:
		return
	sim.request_manual_detonate()
	label_info.text = "已请求手动起爆"


func _restart() -> void:
	sim = null
	last_summary = {}
	preview_cell = Vector2i(-1, -1)
	preview_seers = []
	_load_preset("A")
	_set_ui_phase(UiPhase.SETUP)


func _toggle_preview_hint() -> void:
	label_info.text = "点地面：看谁能看见这里（预览＝模拟）"


func _on_cell_tapped(cell: Vector2i) -> void:
	if ui_phase == UiPhase.SETUP:
		if not grid.walkable(cell.x, cell.y):
			# still allow preview on non-walkable? A-05 = all standable; preview any cell with observers
			pass
		preview_cell = cell
		preview_seers = _preview_who_sees(cell)
		label_info.text = "格 (%d,%d) · 可见观察者 %d" % [cell.x, cell.y, preview_seers.size()]
		# place selected op if placing
		if selected_op_id != "" and grid.walkable(cell.x, cell.y):
			_move_selected_op(cell)
		_push_map_snapshot()
	elif ui_phase == UiPhase.WAIT and sim != null:
		preview_cell = cell
		preview_seers = sim.observers_seeing_cell(float(cell.x), float(cell.y), grid.tier_at(float(cell.x), float(cell.y)))
		label_info.text = "格 (%d,%d) · 可见 %d" % [cell.x, cell.y, preview_seers.size()]
		_push_map_snapshot()


func _preview_who_sees(cell: Vector2i) -> Array:
	## SETUP uses a throwaway sim geometry query without advancing time.
	var tmp := NightSim.new()
	var stub_plan := plan.duplicate(true)
	tmp.setup(level, stub_plan, weapons)
	return tmp.observers_seeing_cell(float(cell.x), float(cell.y), grid.tier_at(float(cell.x), float(cell.y)))


func _move_selected_op(cell: Vector2i) -> void:
	for op in plan.get("operators", []):
		if str(op["id"]) == selected_op_id:
			op["x"] = cell.x
			op["y"] = cell.y
			op["tier"] = grid.tier_at(float(cell.x), float(cell.y))
			return


func _on_cell_dragged(_cell: Vector2i, world_dir: Vector2) -> void:
	if ui_phase != UiPhase.SETUP or selected_op_id == "":
		return
	if world_dir.length() < 8.0:
		return
	# Convert screen drag to world facing: screen +x=east, +y=south-screen = -world-y
	var facing := rad_to_deg(atan2(-world_dir.y, world_dir.x))
	for op in plan.get("operators", []):
		if str(op["id"]) == selected_op_id:
			op["facing_deg"] = facing
			break
	_push_map_snapshot()


func _on_unit_selected(op_id: String) -> void:
	selected_op_id = op_id
	label_info.text = "选中 %s · 拖拽设朝向 · 点格移动" % op_id


func _process(delta: float) -> void:
	if ui_phase != UiPhase.WAIT or sim == null or paused:
		return
	_accum_s += delta * speed_mul
	var dt := SimConstants.DT_S
	while _accum_s >= dt and not sim.is_finished():
		_accum_s -= dt
		sim.advance_one_tick()
		if sim.is_finished():
			break
	_push_map_snapshot()
	_update_wait_labels()
	if sim.is_finished():
		_show_result()


func _update_wait_labels() -> void:
	if sim == null:
		return
	_sync_alert_sfx()
	_maybe_play_detonate_sfx()
	label_alert.text = _alert_zh(sim.alert)
	label_info.text = "t=%d (%.1fs) · 阶段 %s · 触发 %s" % [
		sim.tick, float(sim.tick) * SimConstants.DT_S, sim.phase, sim.trigger_used if sim.trigger_used else str(sim.trigger.get("type", ""))
	]


func _sync_alert_sfx() -> void:
	## Known G1 gap: wire four alert-tier cues into greybox on change.
	if sim == null or sfx == null:
		return
	var a := str(sim.alert)
	if a != _last_alert:
		sfx.play_alert(a)
		_last_alert = a


func _maybe_play_detonate_sfx() -> void:
	if sim == null or sfx == null or _detonate_sfx_played:
		return
	if sim.detonate_tick < 0 or str(sim.trigger_used) == "":
		return
	_detonate_sfx_played = true
	sfx.play("ambush_trigger", -2.0)
	var trig := str(sim.trigger_used)
	if trig == "mine_detonate":
		sfx.play_weapon("mine")
	else:
		for op in sim.operators:
			if op.get("alive", true):
				sfx.play_weapon(str(op.get("weapon_id", "kar98k")))
				break


func _alert_zh(a: String) -> String:
	match a:
		"quiet":
			return "警报：安静"
		"suspicious":
			return "警报：起疑 ?"
		"area_alert":
			return "警报：区域警戒 ?!"
		"global_alert":
			return "警报：全图警报 !"
		_:
			return a


func _show_result() -> void:
	last_summary = sim.outcome_summary()
	_set_ui_phase(UiPhase.RESULT)
	var reason := _reason_zh(last_summary)
	result_label.text = "\n".join([
		"标准伏击：%s" % ("是" if bool(last_summary.get("standard_ambush", false)) else "否"),
		"胜负：%s" % ("胜利" if str(last_summary.get("outcome", "")) == "win" else "失败"),
		"起爆 tick：%s  条件：%s" % [str(last_summary.get("detonate_tick", -1)), str(last_summary.get("trigger", ""))],
		"击杀：%s" % ",".join(last_summary.get("kills", [])),
		"逃脱：%s" % (",".join(last_summary.get("escapes", [])) if last_summary.get("escapes", []) else "无"),
		"警报档：%s" % _alert_zh(str(last_summary.get("alert", ""))),
		"原因：%s" % reason,
	])
	_push_map_snapshot()


func _reason_zh(s: Dictionary) -> String:
	var r := str(s.get("reason", ""))
	var trig := str(s.get("trigger", ""))
	if trig == "alarm":
		return "被岗哨/巡逻发现升至全图警报"
	if r == "enemy_escape":
		var t0 := int(s.get("detonate_tick", -1))
		if t0 >= 0 and t0 < 280:
			return "起爆过早（侧翼未入杀伤区）"
		if t0 > 320:
			return "起爆过晚"
		return "敌人逃脱"
	if r == "clear":
		if bool(s.get("standard_ambush", false)):
			return "标准伏击成功"
		return "清场但未达标准伏击"
	if r == "timeout":
		return "超时"
	if trig == "manual":
		return "手动起爆"
	return r if r else "—"


func _push_map_snapshot() -> void:
	var ops: Array = []
	var enemies: Array = []
	var sentries: Array = level.get("sentries", [])
	var patrols: Array = level.get("patrols", [])
	var mines: Array = plan.get("mines", [])
	var grenades: Array = plan.get("grenades", [])
	var trig: Dictionary = plan.get("trigger", {})
	var al := "quiet"
	var ph := "setup"
	if sim != null:
		ops = sim.operators
		enemies = sim.enemies
		sentries = sim.sentries
		patrols = sim.patrols
		mines = sim.mines
		grenades = sim.grenade_plans
		trig = sim.trigger
		al = sim.alert
		ph = sim.phase
	else:
		ops = plan.get("operators", [])
	map_view.apply_snapshot({
		"operators": ops,
		"enemies": enemies,
		"sentries": sentries,
		"patrols": patrols,
		"mines": mines,
		"grenade_plans": grenades,
		"trigger": trig,
		"alert": al,
		"phase": ph,
		"preview_cell": preview_cell,
		"preview_seers": preview_seers,
		"selected_op_id": selected_op_id,
	})


func _auto_run_plan_a() -> void:
	## Headless: load A, optionally capture, run to result via sim ticks (paused wall-clock).
	_load_preset("A")
	# Wait for layout/resize so map cell_px fits and first draw lands.
	for _i in range(8):
		await get_tree().process_frame
	map_view._fit_cell_px()
	_push_map_snapshot()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("setup")
	_start_wait()
	paused = true ## prevent _process double-ticking during auto
	while sim != null and not sim.is_finished():
		sim.advance_one_tick()
		if sim.tick == 140:
			_push_map_snapshot()
			await get_tree().process_frame
			await get_tree().process_frame
			_try_capture("wait")
	_push_map_snapshot()
	_show_result()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("result")
	print(
		"GREYBOX_AUTO_DONE detonate_tick=", last_summary.get("detonate_tick"),
		" standard_ambush=", last_summary.get("standard_ambush"),
		" outcome=", last_summary.get("outcome")
	)
	if _capture_path != "" or _headless_auto:
		await get_tree().process_frame
		get_tree().quit(0)


func _try_capture(tag: String) -> void:
	if _capture_path == "":
		return
	var shot := str(OS.get_environment("AMBUSH_GREYBOX_SHOT"))
	if shot != "" and shot != "all" and shot != tag:
		return
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	var path := "%s/greybox_%s.png" % [_capture_path, tag]
	img.save_png(path)
	print("GREYBOX_CAPTURE ", path)
