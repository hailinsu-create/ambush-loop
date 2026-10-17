extends Control
class_name GreyboxController

## Playable yard greybox: SCOUT → SETUP → WAIT → RESULT. View is thin; sim owns outcomes.
## PLAY-1 blank setup; PLAY-2 scout/gather (ScoutSim — ambush NightSim golden untouched).

const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const ScoutSim := preload("res://sim/scout_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const SimConstants := preload("res://sim/constants.gd")
const SimGeom := preload("res://sim/geom.gd")
const ReviewBuilder := preload("res://sim/review_builder.gd")
const GreyboxMapScript := preload("res://view/greybox_map.gd")
const G2AssetsScript := preload("res://view/g2_assets.gd")
const G2SfxPlayerScript := preload("res://view/g2_sfx_player.gd")
const G3AssetsScript := preload("res://view/g3_assets.gd")

enum UiPhase { SCOUT, SETUP, WAIT, RESULT }
enum PlaceMode { NONE, OP, MINE, TRIGGER_A, TRIGGER_B }

const KIT_OPERATOR_WEAPONS := ["kar98k", "mp40", "grenade"] ## base assignable; MG42 after scout pickup
const WEAPON_LABEL_ZH := {
	"kar98k": "Kar98k",
	"mp40": "MP40",
	"mg42": "MG42",
	"grenade": "手雷",
	"mine": "地雷",
}

var ui_phase: UiPhase = UiPhase.SCOUT
var level: Dictionary = {}
var weapons: Dictionary = {}
var plan: Dictionary = {}
var sim: NightSim = null
var scout: ScoutSim = null
var grid = null
var gathered_kit: Dictionary = {} ## from scout → setup weapon pool

var paused: bool = false
var speed_mul: float = 1.0
var _accum_s: float = 0.0
var preview_cell: Vector2i = Vector2i(-1, -1)
var preview_seers: Array = []
var selected_op_id: String = ""
var last_summary: Dictionary = {}
var _headless_auto: bool = false
var _capture_path: String = ""
var use_g2_art: bool = false
var art_mode_name: String = "G3"
var _last_alert: String = "quiet"
var _detonate_sfx_played: bool = false
var g2_assets = null
var sfx = null
var g3_assets = null

## PLAY-3 combat presentation (view-only; sim untouched).
var _log_cursor: int = 0
var _pending_result: bool = false
var _result_delay_left: float = 0.0
var _slow_mo_left: float = 0.0
var _fx_fires_total: int = 0
var _fx_kills_total: int = 0
const RESULT_DELAY_AFTER_KILL_S := 2.0
const SLOW_MO_S := 0.35
const SLOW_MO_MUL := 0.28

## PLAY-4 wait UX (view hooks into existing NightSim turn + audio).
var _enemy_prev_pos: Dictionary = {} ## enemy_id → Vector2
var _enemy_in_cone: Dictionary = {} ## enemy_id → bool (any op cone)
const FOOT_NEAR_CELLS := 4.0
const FOOT_FAR_CELLS := 18.0
## Yard pacing after +12 s spawn shift (PLAY-4): t0_A=520, t0_B=560.
const T0_EARLY_TICK := 520
const T0_LATE_TICK := 560

## PLAY-1 setup state (view/controller only; not consumed by sim).
var place_mode: PlaceMode = PlaceMode.NONE
var op_placed: Dictionary = {} ## op_id → bool
var op_display_names: Dictionary = {} ## op_id → Chinese
var kit_weapon_counts: Dictionary = {} ## weapon_id → remaining in kit (for UI)
var example_plans_open: bool = false

@onready var map_view: GreyboxMap = $MapHost/SubViewportContainer/SubViewport/GreyboxMap
@onready var map_viewport: SubViewport = $MapHost/SubViewportContainer/SubViewport
@onready var hud: Control = $HUD
@onready var label_phase: Label = $HUD/TopBar/PhaseLabel
@onready var label_info: Label = $HUD/TopBar/InfoLabel
@onready var label_alert: Label = $HUD/TopBar/AlertLabel
@onready var scout_panel: Control = $HUD/ScoutPanel
@onready var label_scout_clock: Label = $HUD/ScoutPanel/ClockLabel
@onready var label_scout_kit: Label = $HUD/ScoutPanel/KitLabel
@onready var btn_begin_setup: Button = $HUD/ScoutPanel/BeginSetupButton
@onready var btn_scout_preview: Button = $HUD/ScoutPanel/PreviewButton
@onready var btn_example: Button = $HUD/SetupPanel/ExamplePlansButton
@onready var btn_plan_a: Button = $HUD/SetupPanel/PlanAButton
@onready var btn_plan_b: Button = $HUD/SetupPanel/PlanBButton
@onready var btn_start: Button = $HUD/SetupPanel/StartButton
@onready var label_start_reason: Label = $HUD/SetupPanel/StartReasonLabel
@onready var btn_preview: Button = $HUD/SetupPanel/PreviewButton
@onready var btn_g2_art: Button = $HUD/SetupPanel/G2ArtButton
@onready var trigger_option: OptionButton = $HUD/SetupPanel/TriggerOption
@onready var op_cards: VBoxContainer = $HUD/SetupPanel/OpCards
@onready var kit_row: HBoxContainer = $HUD/SetupPanel/KitRow
@onready var setup_panel: Control = $HUD/SetupPanel
@onready var wait_panel: Control = $HUD/WaitPanel
@onready var result_panel: Control = $HUD/ResultPanel
@onready var result_label: Label = $HUD/ResultPanel/Margin/VBox/ResultLabel
@onready var outcome_label: Label = $HUD/ResultPanel/Margin/VBox/TitleRow/OutcomeLabel
@onready var grade_label: Label = $HUD/ResultPanel/Margin/VBox/TitleRow/GradeLabel
@onready var subtitle_label: Label = $HUD/ResultPanel/Margin/VBox/SubtitleLabel
@onready var timeline_label: Label = $HUD/ResultPanel/Margin/VBox/TimelineLabel
@onready var causes_label: Label = $HUD/ResultPanel/Margin/VBox/CausesLabel
@onready var body_hint_label: Label = $HUD/ResultPanel/Margin/VBox/BodyHintLabel
@onready var btn_pause: Button = $HUD/WaitPanel/PauseButton
@onready var btn_speed: Button = $HUD/WaitPanel/SpeedButton
@onready var btn_detonate: Button = $HUD/WaitPanel/DetonateButton
@onready var btn_restart: Button = $HUD/ResultPanel/Margin/VBox/RestartButton
@onready var btn_rescout: Button = $HUD/ResultPanel/Margin/VBox/RescoutButton
@onready var btn_restart_wait: Button = $HUD/WaitPanel/RestartWaitButton

## PLAY-5 review + body search
var last_review: Dictionary = {}
var searched_bodies: Dictionary = {} ## enemy_id → true
var next_night_loot: Array = [] ## stub persistence for next night kit
var body_search_enabled: bool = false
const NEXT_NIGHT_KIT_PATH := "user://next_night_kit.json"
## PLAY-UX PR-2: bottom-left portrait strip (all phases).
var portrait_strip: HBoxContainer = null
var _facing_submit_count: int = 0 ## test: wait re-aim submissions
## PLAY-UX PR-4: explicit tools + trigger chips.
var tool_bar: HBoxContainer = null
var trigger_chip_row: HBoxContainer = null
var setup_tool: String = "op" ## op | mine | trigger
var _trip_drag_start: Vector2i = Vector2i(-1, -1)
var pending_place_cell: Vector2i = Vector2i(-1, -1) ## ghost confirm cell
var _last_unit_drag_cell: Vector2i = Vector2i(-1, -1)
## PLAY-UX PR-5: touch HUD (≥88px), thumb cluster, pause menu, long-press detonate.
const TOUCH_MIN_PX := 88.0
const BODY_FONT_PX := 24 ## ≥22 design-px; ≥12 pt at 0.542 phone scale
const DETONATE_LONGPRESS_MS := 500
var thumb_bar: HBoxContainer = null
var btn_thumb_start: Button = null
var btn_thumb_begin: Button = null
var btn_thumb_pause: Button = null
var btn_thumb_speed: Button = null
var btn_thumb_detonate: Button = null
var pause_menu: PanelContainer = null
var btn_pause_restart: Button = null
var btn_pause_confirm: Button = null
var btn_pause_resume: Button = null
var dev_menu: VBoxContainer = null
var btn_dev_toggle: Button = null
var _detonate_press_ms: int = 0
var _detonate_holding: bool = false
var _restart_confirm_armed: bool = false
var detonate_now_ms_fn: Callable = Callable() ## test clock
## PLAY-UX PR-6: scout path preview → confirm.
var preview_path: Array = [] ## Vector2i full A* path
var scout_danger_cells: Array = [] ## Vector2i
var pending_scout_goal: Vector2i = Vector2i(-1, -1)
var scout_dest_flag: Vector2i = Vector2i(-1, -1) ## sticky until arrival
var scout_preview_cost_s: float = 0.0
var _scout_hover_from_mouse: bool = false ## desktop hover preview active
## PLAY-UX PR-7: undo stack + cancel.
const UNDO_MAX := 30
var undo_stack: Array = [] ## deep-copied plan snapshots
var btn_undo: Button = null
var btn_cancel: Button = null
var _aim_drag_active: bool = false
var _facing_before_aim: float = NAN
var _skip_next_place_undo: bool = false


func _ready() -> void:
	_apply_cjk_font()
	g2_assets = G2AssetsScript.new()
	g2_assets.load_all()
	g3_assets = G3AssetsScript.new()
	g3_assets.load_all()
	sfx = G2SfxPlayerScript.new()
	add_child(sfx)
	sfx.configure(g2_assets)
	level = SimLevelLoader.load_path("res://data/levels/yard.json")
	weapons = SimWeapons.load_csv()
	grid = SimLevelLoader.build_grid(level)
	map_view.configure(level, grid, weapons)
	map_view.set_art_mode(map_view.ArtMode.G3)
	art_mode_name = "G3"
	map_view.cell_tapped.connect(_on_cell_tapped)
	map_view.cell_dragged.connect(_on_cell_dragged)
	map_view.unit_selected.connect(_on_unit_selected)
	map_view.aim_drag_ended.connect(_on_aim_drag_ended)
	map_view.aim_drag_started.connect(_on_aim_drag_started_track)
	map_view.ground_drag_started.connect(_on_ground_drag_started)
	map_view.ground_drag_moved.connect(_on_ground_drag_moved)
	map_view.ground_drag_ended.connect(_on_ground_drag_ended)
	map_view.cell_hovered.connect(_on_cell_hovered)
	map_view.cell_long_pressed.connect(_on_cell_long_pressed)
	map_view.unit_hit_radius_cells = 0.8
	_build_portrait_strip()
	_build_setup_tool_bars()
	_build_touch_hud()
	_build_undo_cancel_buttons()

	btn_example.pressed.connect(func(): _ui_tap(); _toggle_example_plans())
	btn_plan_a.pressed.connect(func(): _ui_tap(); _load_preset("A"))
	btn_plan_b.pressed.connect(func(): _ui_tap(); _load_preset("B"))
	btn_start.pressed.connect(func(): _ui_tap(); _start_wait())
	btn_preview.pressed.connect(func(): _ui_tap(); _toggle_preview_hint())
	btn_pause.pressed.connect(func(): _ui_tap(); _toggle_pause())
	btn_speed.pressed.connect(func(): _ui_tap(); _cycle_speed())
	# Detonate: long-press only (PR-5) — disconnect instant press.
	if btn_detonate:
		for c in btn_detonate.pressed.get_connections():
			btn_detonate.pressed.disconnect(c.callable)
	btn_restart.pressed.connect(func(): _ui_tap(); _restart())
	if btn_restart_wait:
		btn_restart_wait.visible = false
		btn_restart_wait.disabled = true
	if btn_rescout:
		btn_rescout.pressed.connect(func(): _ui_tap(); _restart_scout())
	if btn_begin_setup:
		btn_begin_setup.pressed.connect(func(): _ui_tap(); begin_setup_from_scout())
	if btn_scout_preview:
		btn_scout_preview.pressed.connect(func(): _ui_tap(); _toggle_preview_hint())
	if btn_g2_art:
		btn_g2_art.pressed.connect(_cycle_art)
		_refresh_art_button()

	_fill_trigger_options()
	_set_example_plans_visible(false)
	_apply_touch_sizing()

	# Headless automation hooks (W3 test / PNG capture).
	_headless_auto = str(OS.get_environment("AMBUSH_GREYBOX_AUTO")).to_lower() in ["1", "true", "a"]
	_capture_path = str(OS.get_environment("AMBUSH_GREYBOX_CAPTURE"))
	var art_env := str(OS.get_environment("AMBUSH_GREYBOX_ART")).to_lower()
	if art_env in ["g1", "1"]:
		map_view.set_art_mode(map_view.ArtMode.G1)
		art_mode_name = "G1"
		_refresh_art_button()
	elif art_env in ["g2", "2"]:
		map_view.set_art_mode(map_view.ArtMode.G2)
		art_mode_name = "G2"
		_refresh_art_button()
	var skip_scout := str(OS.get_environment("AMBUSH_GREYBOX_SKIP_SCOUT")).to_lower() in ["1", "true"]
	if skip_scout:
		gathered_kit = level.get("loadout_start", {}).duplicate(true)
		_init_blank_plan()
		_build_op_cards()
		_build_kit_row()
		_set_ui_phase(UiPhase.SETUP)
		_refresh_start_gate()
	else:
		_start_scout_phase()
	_load_next_night_loot_stub()
	if _headless_auto:
		var plan_env := str(OS.get_environment("AMBUSH_GREYBOX_PLAN")).to_upper()
		if plan_env == "B":
			call_deferred("_auto_run_plan_b")
		else:
			call_deferred("_auto_run_plan_a")


func _apply_cjk_font() -> void:
	var font_res = load("res://ui/fonts/web_ui_font.tres")
	if font_res == null:
		return
	for n in [
		label_phase, label_info, label_alert, result_label, outcome_label, grade_label,
		subtitle_label, timeline_label, causes_label, body_hint_label,
		label_scout_clock, label_scout_kit, btn_begin_setup, btn_scout_preview,
		btn_example, btn_plan_a, btn_plan_b, btn_start, label_start_reason, btn_preview,
		btn_g2_art, btn_pause, btn_speed, btn_detonate, btn_restart, btn_rescout,
		btn_restart_wait, trigger_option,
	]:
		if n:
			n.add_theme_font_override("font", font_res)
	if trigger_option:
		var popup := trigger_option.get_popup()
		if popup:
			popup.add_theme_font_override("font", font_res)


func _ui_tap() -> void:
	if sfx:
		sfx.play("ui_tap", -8.0)


func _cycle_art() -> void:
	_ui_tap()
	var mode = map_view.cycle_art_mode()
	art_mode_name = map_view.art_mode_label()
	_refresh_art_button()
	label_info.text = "美术：%s（G1 锥/扇/标记仍叠加）" % art_mode_name


func _refresh_art_button() -> void:
	if btn_g2_art == null:
		return
	btn_g2_art.text = "美术：%s" % art_mode_name


func starting_kit_weapon_ids() -> Array:
	## Weapons available for setup from gathered_kit (MG42 only after scout pickup).
	var out: Array = []
	var src: Dictionary = gathered_kit if not gathered_kit.is_empty() else level.get("loadout_start", {})
	for w in src.get("weapons", []):
		var wid := str(w.get("weapon_id", ""))
		if wid.is_empty():
			continue
		if wid == "mg42" and not is_mg42_unlocked():
			continue
		out.append(wid)
	return out


func is_mg42_in_starting_kit() -> bool:
	## loadout_start never lists MG42; unlock is scout pickup into gathered_kit.
	for w in level.get("loadout_start", {}).get("weapons", []):
		if str(w.get("weapon_id", "")) == "mg42":
			return true
	return false


func is_mg42_unlocked() -> bool:
	if scout != null and scout.has_mg42():
		return true
	for w in gathered_kit.get("weapons", []):
		if str(w.get("weapon_id", "")) == "mg42" and int(w.get("count", 0)) > 0:
			return true
	return false


func _kit_counts_from_gathered() -> Dictionary:
	var counts: Dictionary = {}
	var src: Dictionary = gathered_kit if not gathered_kit.is_empty() else level.get("loadout_start", {})
	for w in src.get("weapons", []):
		var wid := str(w.get("weapon_id", ""))
		if wid.is_empty():
			continue
		counts[wid] = int(w.get("count", 1))
	return counts


func _start_scout_phase() -> void:
	scout = ScoutSim.new()
	scout.setup(level)
	scout.begin_scout()
	gathered_kit = scout.kit_snapshot()
	op_display_names.clear()
	for op in scout.operators:
		op_display_names[str(op["id"])] = str(op.get("display_name", "队员"))
	selected_op_id = str(scout.operators[0]["id"]) if scout.operators else ""
	sim = null
	_set_ui_phase(UiPhase.SCOUT)
	_push_map_snapshot()
	_refresh_scout_hud()
	label_info.text = "侦察搜集 · 点队员再点格行走 · 靠近箱子开箱 · 隐蔽点需接近才显现"


func begin_setup_from_scout() -> void:
	## 「开始布阵」— hand gathered kit to PLAY-1 blank setup.
	if scout != null and not scout.is_finished():
		scout.finish_scout("player")
	if scout != null:
		gathered_kit = scout.kit_snapshot()
	else:
		gathered_kit = level.get("loadout_start", {}).duplicate(true)
	_init_blank_plan_from_scout()
	_build_op_cards()
	_build_kit_row()
	_set_ui_phase(UiPhase.SETUP)
	_refresh_start_gate()
	var mg := "已解锁 MG42" if is_mg42_unlocked() else "尚未取得 MG42"
	label_info.text = "布阵开始 · 套件已带入 · %s" % mg


func _init_blank_plan() -> void:
	if gathered_kit.is_empty():
		gathered_kit = level.get("loadout_start", {}).duplicate(true)
	_init_blank_plan_from_scout()


func _assignable_weapon_ids() -> Array:
	var ids: Array = KIT_OPERATOR_WEAPONS.duplicate()
	if is_mg42_unlocked():
		ids.append("mg42")
	return ids


func _init_blank_plan_from_scout() -> void:
	## Blank board at entry (or scout end pos); weapons from gathered kit; no preset A/B.
	op_display_names.clear()
	op_placed.clear()
	kit_weapon_counts = _kit_counts_from_gathered()
	var ops: Array = []
	var defaults := ["kar98k", "mp40", "grenade"]
	var sources: Array = []
	if scout != null and not scout.operators.is_empty():
		sources = scout.operators
	else:
		sources = level.get("squad_insertion", [])
	var i := 0
	for entry in sources:
		var oid := str(entry.get("id", "op_%d" % (i + 1)))
		var dname := str(entry.get("display_name", "%d号" % (i + 1)))
		var wid: String = str(defaults[i]) if i < defaults.size() else "kar98k"
		if is_mg42_unlocked() and i == 0:
			wid = "mg42"
		if int(kit_weapon_counts.get(wid, 0)) <= 0:
			for cand in _assignable_weapon_ids():
				if int(kit_weapon_counts.get(cand, 0)) > 0:
					wid = str(cand)
					break
		if int(kit_weapon_counts.get(wid, 0)) > 0:
			kit_weapon_counts[wid] = int(kit_weapon_counts[wid]) - 1
		var op: Dictionary = {
			"id": oid,
			"x": int(entry.get("x", 11)),
			"y": int(entry.get("y", 1)),
			"tier": grid.tier_at(float(entry.get("x", 11)), float(entry.get("y", 1))),
			"facing_deg": float(entry.get("facing_deg", 90)),
			"weapon_id": wid,
			"display_name": dname,
		}
		ops.append(op)
		op_display_names[oid] = dname
		# PLAY-UX PR-4: entry cell counts as placed (yellow reminder only).
		op_placed[oid] = true
		i += 1
	var dt: Dictionary = level.get("default_trigger", {"type": "manual"}).duplicate(true)
	dt.erase("plan_id")
	var ttype := str(dt.get("type", "manual"))
	# Remap legacy bind ids (op_kar_L) to our blank squad.
	if ttype == "see_first_enemy":
		dt["bind"] = _op_id_for_weapon("kar98k")
		if str(dt.get("bind", "")) == "":
			dt["bind"] = str(ops[0]["id"]) if ops else ""
	elif ttype == "cross_marker":
		# Player places the line; leave a/b unset until placed.
		dt = {"type": "cross_marker", "bind": "marker_y7"}
	elif ttype == "mine_detonate":
		dt = {"type": "mine_detonate", "bind": ""}
	plan = {
		"id": "player",
		"label": "自订",
		"trigger": dt,
		"operators": ops,
		"mines": [],
		"grenades": [],
	}
	selected_op_id = str(ops[0]["id"]) if ops else ""
	place_mode = PlaceMode.OP
	setup_tool = "op"
	pending_place_cell = Vector2i(-1, -1)
	undo_stack.clear()
	_sync_trigger_option_from_plan()
	_push_map_snapshot()
	label_info.text = "入场位已就位 · 用工具栏放置/拖队员落位 · 仍在入场位可微调"
	_refresh_op_cards()
	_refresh_tool_chips()
	_refresh_trigger_chips()
	_update_legal_highlights()
	_refresh_start_gate()


func _op_id_for_weapon(wid: String) -> String:
	for op in plan.get("operators", []):
		if str(op.get("weapon_id", "")) == wid:
			return str(op["id"])
	return ""


func _toggle_example_plans() -> void:
	example_plans_open = not example_plans_open
	_set_example_plans_visible(example_plans_open)


func _set_example_plans_visible(vis: bool) -> void:
	example_plans_open = vis
	if btn_plan_a:
		btn_plan_a.visible = vis
	if btn_plan_b:
		btn_plan_b.visible = vis
	if btn_example:
		btn_example.text = "收起示例方案" if vis else "示例方案"


func _build_kit_row() -> void:
	if kit_row == null:
		return
	for c in kit_row.get_children():
		c.queue_free()
	var font_res = load("res://ui/fonts/web_ui_font.tres")
	var title := Label.new()
	title.text = "起始套件"
	title.add_theme_font_size_override("font_size", BODY_FONT_PX)
	if font_res:
		title.add_theme_font_override("font", font_res)
	kit_row.add_child(title)
	for wid in ["kar98k", "mp40", "grenade", "mine", "mg42"]:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(TOUCH_MIN_PX, TOUCH_MIN_PX)
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(48, 48)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if g3_assets and g3_assets.weapon_icons.has(wid):
			tr.texture = g3_assets.weapon_icons[wid]
		var lab := Label.new()
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", BODY_FONT_PX)
		if font_res:
			lab.add_theme_font_override("font", font_res)
		if wid == "mg42" and not is_mg42_unlocked():
			tr.modulate = Color(0.45, 0.45, 0.45, 0.85)
			lab.text = "MG42"
			lab.modulate = Color(0.55, 0.55, 0.55)
			box.tooltip_text = "需在隐蔽补给点找到"
			tr.tooltip_text = "需在隐蔽补给点找到"
			lab.tooltip_text = "需在隐蔽补给点找到"
		else:
			lab.text = str(WEAPON_LABEL_ZH.get(wid, wid))
			if wid == "mg42":
				lab.modulate = Color(1.0, 0.92, 0.45)
		box.add_child(tr)
		box.add_child(lab)
		kit_row.add_child(box)


func _build_op_cards() -> void:
	if op_cards == null:
		return
	for c in op_cards.get_children():
		c.queue_free()
	var font_res = load("res://ui/fonts/web_ui_font.tres")
	for op in plan.get("operators", []):
		var oid := str(op["id"])
		var card := VBoxContainer.new()
		card.name = "Card_%s" % oid
		card.add_theme_constant_override("separation", 4)
		var head := Button.new()
		head.name = "Select"
		head.custom_minimum_size = Vector2(0, TOUCH_MIN_PX)
		head.add_theme_font_size_override("font_size", BODY_FONT_PX)
		if font_res:
			head.add_theme_font_override("font", font_res)
		head.pressed.connect(_on_op_card_pressed.bind(oid))
		card.add_child(head)
		var wrow := HBoxContainer.new()
		wrow.name = "Weapons"
		wrow.add_theme_constant_override("separation", 4)
		for wid in _assignable_weapon_ids():
			var wb := Button.new()
			wb.name = "W_%s" % wid
			wb.text = str(WEAPON_LABEL_ZH.get(wid, wid))
			wb.custom_minimum_size = Vector2(TOUCH_MIN_PX, TOUCH_MIN_PX)
			wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wb.add_theme_font_size_override("font_size", BODY_FONT_PX)
			if font_res:
				wb.add_theme_font_override("font", font_res)
			wb.pressed.connect(_on_op_weapon_picked.bind(oid, wid))
			wrow.add_child(wb)
		if not is_mg42_unlocked():
			var mg := Button.new()
			mg.name = "W_mg42"
			mg.text = "MG42"
			mg.disabled = true
			mg.tooltip_text = "需在隐蔽补给点找到"
			mg.custom_minimum_size = Vector2(TOUCH_MIN_PX, TOUCH_MIN_PX)
			mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			mg.add_theme_font_size_override("font_size", BODY_FONT_PX)
			if font_res:
				mg.add_theme_font_override("font", font_res)
			wrow.add_child(mg)
		card.add_child(wrow)
		op_cards.add_child(card)
	_refresh_op_cards()


func _refresh_op_cards() -> void:
	if op_cards == null:
		return
	for op in plan.get("operators", []):
		var oid := str(op["id"])
		var card := op_cards.get_node_or_null("Card_%s" % oid)
		if card == null:
			continue
		var head: Button = card.get_node_or_null("Select")
		if head:
			var dname := str(op_display_names.get(oid, op.get("display_name", "队员")))
			var wlab := str(WEAPON_LABEL_ZH.get(str(op.get("weapon_id", "")), op.get("weapon_id", "")))
			var placed := bool(op_placed.get(oid, false))
			var mark := "✓" if placed else "·"
			var sel := "▸ " if oid == selected_op_id else ""
			var ammo_n := _op_ammo_display(oid, op)
			var hp_bit := _op_hp_display(oid, op)
			head.text = "%s%s %s · %s · 弹%d%s" % [sel, mark, dname, wlab, ammo_n, hp_bit]
		var wrow := card.get_node_or_null("Weapons")
		if wrow:
			for wid in _assignable_weapon_ids():
				var wb: Button = wrow.get_node_or_null("W_%s" % wid)
				if wb == null:
					continue
				var equipped: bool = str(op.get("weapon_id", "")) == str(wid)
				wb.disabled = false
				if equipped:
					wb.modulate = Color(1.0, 0.92, 0.55)
				else:
					wb.modulate = Color.WHITE


func _op_ammo_display(oid: String, plan_op: Dictionary) -> int:
	if sim != null:
		for sop in sim.operators:
			if str(sop.get("id", "")) == oid:
				return int(sop.get("ammo", 0))
	if plan_op.has("ammo"):
		return int(plan_op.get("ammo", 0))
	var wid := str(plan_op.get("weapon_id", ""))
	return int(SimConstants.DEFAULT_AMMO.get(wid, 0))


func _op_hp_display(oid: String, _plan_op: Dictionary) -> String:
	if sim == null:
		return ""
	for sop in sim.operators:
		if str(sop.get("id", "")) != oid:
			continue
		if not bool(sop.get("alive", true)):
			return " · 阵亡"
		if bool(sop.get("wounded", false)):
			return " · 负伤%d/%d" % [int(sop.get("hp", 0)), int(sop.get("max_hp", SimConstants.OP_MAX_HP))]
		return " · HP%d" % int(sop.get("hp", SimConstants.OP_MAX_HP))
	return ""


func _on_op_card_pressed(oid: String) -> void:
	_ui_tap()
	selected_op_id = oid
	place_mode = PlaceMode.OP
	var dname := str(op_display_names.get(oid, oid))
	label_info.text = "已选 %s · 点合法格放置 · 拖拽设朝向" % dname
	_refresh_op_cards()
	_push_map_snapshot()


func _on_op_weapon_picked(oid: String, wid: String) -> void:
	_ui_tap()
	if wid == "mg42" and not is_mg42_unlocked():
		label_info.text = "需在隐蔽补给点找到"
		return
	if wid == "mine":
		label_info.text = "地雷请用地图放置（起爆条件选「地雷」）"
		return
	# Enforce kit stock: count how many ops already hold this weapon.
	var max_count := int(_kit_counts_from_gathered().get(wid, 0))
	if max_count <= 0:
		label_info.text = "套件中没有该武器"
		return
	var held := 0
	for op in plan.get("operators", []):
		if str(op["id"]) != oid and str(op.get("weapon_id", "")) == wid:
			held += 1
	if held >= max_count:
		label_info.text = "起始套件中该武器已分完"
		return
	_push_undo()
	for op in plan.get("operators", []):
		if str(op["id"]) == oid:
			op["weapon_id"] = wid
			break
	# Keep see_first_enemy bind on rifleman when possible.
	var trig: Dictionary = plan.get("trigger", {})
	if str(trig.get("type", "")) == "see_first_enemy":
		var bind := _op_id_for_weapon("kar98k")
		if bind != "":
			trig["bind"] = bind
			plan["trigger"] = trig
	selected_op_id = oid
	_refresh_op_cards()
	_push_map_snapshot()
	label_info.text = "%s 装备 %s" % [op_display_names.get(oid, "队员"), WEAPON_LABEL_ZH.get(wid, wid)]
	_refresh_start_gate()


func _fill_trigger_options() -> void:
	trigger_option.clear()
	trigger_option.add_item("见首敌", 0)
	trigger_option.set_item_metadata(0, "see_first_enemy")
	trigger_option.add_item("地雷", 1)
	trigger_option.set_item_metadata(1, "mine_detonate")
	trigger_option.add_item("越线标记", 2)
	trigger_option.set_item_metadata(2, "cross_marker")
	trigger_option.add_item("手动", 3)
	trigger_option.set_item_metadata(3, "manual")
	if not trigger_option.item_selected.is_connected(_on_trigger_selected):
		trigger_option.item_selected.connect(_on_trigger_selected)


func _load_preset(which: String) -> void:
	var path := "res://data/fixtures/plan_a.json" if which == "A" else "res://data/fixtures/plan_b.json"
	plan = SimRunner.load_json(path).duplicate(true)
	op_display_names.clear()
	op_placed.clear()
	var i := 0
	for op in plan.get("operators", []):
		var oid := str(op["id"])
		var wid := str(op.get("weapon_id", ""))
		var dname := "%d号·%s" % [i + 1, WEAPON_LABEL_ZH.get(wid, wid)]
		op["display_name"] = dname
		op_display_names[oid] = dname
		op_placed[oid] = true
		i += 1
	selected_op_id = str(plan.get("operators", [{}])[0].get("id", "")) if plan.get("operators", []) else ""
	place_mode = PlaceMode.OP
	_sync_trigger_option_from_plan()
	_build_op_cards()
	_push_map_snapshot()
	label_info.text = "已载入示例方案 %s（教学/调试）· 可微调后开始" % which
	_refresh_start_gate()


func _sync_trigger_option_from_plan() -> void:
	var t := str(plan.get("trigger", {}).get("type", "manual"))
	for i in range(trigger_option.item_count):
		if str(trigger_option.get_item_metadata(i)) == t:
			trigger_option.select(i)
			return


func _on_trigger_selected(idx: int) -> void:
	## Trigger type only — does NOT switch place/tool mode (PLAY-UX PR-4).
	if ui_phase != UiPhase.SETUP:
		return
	var t := str(trigger_option.get_item_metadata(idx))
	_apply_trigger_type(t)
	_refresh_trigger_chips()
	_push_map_snapshot()
	_refresh_start_gate()


func _apply_trigger_type(t: String) -> void:
	_push_undo()
	match t:
		"see_first_enemy":
			var bind := selected_op_id if selected_op_id else _op_id_for_weapon("kar98k")
			if bind == "" and plan.get("operators", []):
				bind = str(plan["operators"][0]["id"])
			plan["trigger"] = {"type": "see_first_enemy", "bind": bind}
			label_info.text = "起爆：见首敌 · 绑定 %s（工具不变）" % op_display_names.get(bind, bind)
		"mine_detonate":
			if plan.get("mines", []).is_empty():
				plan["mines"] = []
			plan["trigger"] = {"type": "mine_detonate", "bind": str((plan.get("mines", [{}])[0] if plan.get("mines", []) else {}).get("id", ""))}
			label_info.text = "起爆：地雷 · 用「地雷」工具放置"
		"cross_marker":
			var trig: Dictionary = plan.get("trigger", {}).duplicate(true)
			trig["type"] = "cross_marker"
			if not trig.has("bind"):
				trig["bind"] = "marker_y7"
			plan["trigger"] = trig
			label_info.text = "起爆：越线 · 用「触发线」工具一笔拖出"
		"manual":
			plan["trigger"] = {"type": "manual"}
			label_info.text = "起爆：手动"
		_:
			pass


func _build_setup_tool_bars() -> void:
	if tool_bar != null:
		return
	tool_bar = HBoxContainer.new()
	tool_bar.name = "ToolBar"
	tool_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tool_bar.offset_left = -420
	tool_bar.offset_top = 52
	tool_bar.offset_right = -8
	tool_bar.offset_bottom = 140
	tool_bar.add_theme_constant_override("separation", 6)
	$HUD.add_child(tool_bar)
	for pair in [["op", "队员"], ["mine", "地雷"], ["trigger", "触发线"]]:
		var b := Button.new()
		b.name = "Tool_%s" % pair[0]
		b.text = str(pair[1])
		b.custom_minimum_size = Vector2(100, 88)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_tool_chip.bind(str(pair[0])))
		tool_bar.add_child(b)
	trigger_chip_row = HBoxContainer.new()
	trigger_chip_row.name = "TriggerChips"
	trigger_chip_row.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	trigger_chip_row.offset_left = -420
	trigger_chip_row.offset_top = 148
	trigger_chip_row.offset_right = -8
	trigger_chip_row.offset_bottom = 236
	trigger_chip_row.add_theme_constant_override("separation", 4)
	$HUD.add_child(trigger_chip_row)
	for pair in [
		["see_first_enemy", "见首敌"],
		["mine_detonate", "地雷"],
		["cross_marker", "越线"],
		["manual", "手动"],
	]:
		var c := Button.new()
		c.name = "Trig_%s" % pair[0]
		c.text = str(pair[1])
		c.custom_minimum_size = Vector2(88, 88)
		c.toggle_mode = true
		c.add_theme_font_size_override("font_size", 16)
		c.pressed.connect(_on_trigger_chip.bind(str(pair[0])))
		trigger_chip_row.add_child(c)
	_refresh_tool_chips()
	_refresh_trigger_chips()
	_update_setup_chrome_visibility()


func _on_tool_chip(tool_id: String) -> void:
	_ui_tap()
	setup_tool = tool_id
	match tool_id:
		"mine":
			place_mode = PlaceMode.MINE
		"trigger":
			place_mode = PlaceMode.TRIGGER_A
			_trip_drag_start = Vector2i(-1, -1)
		_:
			place_mode = PlaceMode.OP
	if map_view:
		map_view.allow_ground_pan = setup_tool != "trigger"
	label_info.text = "工具：%s" % {"op": "队员", "mine": "地雷", "trigger": "触发线"}.get(tool_id, tool_id)
	_refresh_tool_chips()
	_update_legal_highlights()
	_push_map_snapshot()


func _on_trigger_chip(trig: String) -> void:
	_ui_tap()
	_apply_trigger_type(trig)
	_sync_trigger_option_from_plan()
	_refresh_trigger_chips()
	# Explicit: tool mode unchanged.
	_refresh_tool_chips()
	_refresh_start_gate()
	_push_map_snapshot()


func _refresh_tool_chips() -> void:
	if tool_bar == null:
		return
	for c in tool_bar.get_children():
		var id := str(c.name).replace("Tool_", "")
		c.button_pressed = id == setup_tool
		c.modulate = Color(1.0, 0.92, 0.45) if id == setup_tool else Color.WHITE


func _refresh_trigger_chips() -> void:
	if trigger_chip_row == null:
		return
	var cur := str(plan.get("trigger", {}).get("type", "manual"))
	for c in trigger_chip_row.get_children():
		var id := str(c.name).replace("Trig_", "")
		c.button_pressed = id == cur
		c.modulate = Color(0.7, 0.9, 1.0) if id == cur else Color.WHITE


func _update_setup_chrome_visibility() -> void:
	var show := ui_phase == UiPhase.SETUP
	if tool_bar:
		tool_bar.visible = show
	if trigger_chip_row:
		trigger_chip_row.visible = show
	if trigger_option:
		trigger_option.visible = false ## replaced by chips


func _update_legal_highlights() -> void:
	if map_view == null or grid == null:
		return
	var cells: Array = []
	if ui_phase != UiPhase.SETUP:
		map_view.legal_cells = []
		return
	if setup_tool == "mine" or setup_tool == "op":
		for y in range(grid.height):
			for x in range(grid.width):
				if grid.walkable(x, y):
					cells.append(Vector2i(x, y))
	map_view.legal_cells = cells
	map_view.queue_redraw()


func _mk_touch_btn(text: String, min_w: float = TOUCH_MIN_PX) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, TOUCH_MIN_PX)
	b.add_theme_font_size_override("font_size", BODY_FONT_PX)
	return b


func _build_touch_hud() -> void:
	## Bottom-right thumb cluster + pause menu + top-left dev menu (PR-5).
	thumb_bar = HBoxContainer.new()
	thumb_bar.name = "ThumbBar"
	thumb_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	thumb_bar.offset_left = -520
	thumb_bar.offset_top = -120
	thumb_bar.offset_right = -8
	thumb_bar.offset_bottom = -8
	thumb_bar.add_theme_constant_override("separation", 8)
	thumb_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	$HUD.add_child(thumb_bar)
	btn_thumb_begin = _mk_touch_btn("开始布阵", 140)
	btn_thumb_start = _mk_touch_btn("开始等待", 140)
	btn_thumb_pause = _mk_touch_btn("暂停", 100)
	btn_thumb_speed = _mk_touch_btn("倍速 1×", 100)
	btn_thumb_detonate = _mk_touch_btn("长按起爆", 140)
	btn_thumb_detonate.modulate = Color(1.0, 0.55, 0.45)
	for b in [btn_thumb_begin, btn_thumb_start, btn_thumb_pause, btn_thumb_speed, btn_thumb_detonate]:
		thumb_bar.add_child(b)
	btn_thumb_begin.pressed.connect(func(): _ui_tap(); begin_setup_from_scout())
	btn_thumb_start.pressed.connect(func(): _ui_tap(); _start_wait())
	btn_thumb_pause.pressed.connect(func(): _ui_tap(); _toggle_pause())
	btn_thumb_speed.pressed.connect(func(): _ui_tap(); _cycle_speed())
	btn_thumb_detonate.button_down.connect(_on_detonate_down)
	btn_thumb_detonate.button_up.connect(_on_detonate_up)
	if btn_detonate:
		btn_detonate.visible = false
		btn_detonate.button_down.connect(_on_detonate_down)
		btn_detonate.button_up.connect(_on_detonate_up)
	# Hide side-panel duplicates of primary actions (thumb cluster owns them).
	if btn_start:
		btn_start.visible = false
	if btn_begin_setup:
		btn_begin_setup.visible = false
	if btn_pause:
		btn_pause.visible = false
	if btn_speed:
		btn_speed.visible = false
	if btn_restart_wait:
		btn_restart_wait.visible = false
	_build_pause_menu()
	_build_dev_menu()
	_refresh_thumb_visibility()


func _build_pause_menu() -> void:
	pause_menu = PanelContainer.new()
	pause_menu.name = "PauseMenu"
	pause_menu.visible = false
	pause_menu.set_anchors_preset(Control.PRESET_CENTER)
	pause_menu.offset_left = -180
	pause_menu.offset_top = -160
	pause_menu.offset_right = 180
	pause_menu.offset_bottom = 160
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pause_menu.add_child(vb)
	var title := Label.new()
	title.text = "已暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	vb.add_child(title)
	btn_pause_resume = _mk_touch_btn("继续", 200)
	btn_pause_restart = _mk_touch_btn("重新开始", 200)
	btn_pause_confirm = _mk_touch_btn("确认重新开始", 200)
	btn_pause_confirm.visible = false
	btn_pause_confirm.modulate = Color(1.0, 0.5, 0.4)
	vb.add_child(btn_pause_resume)
	vb.add_child(btn_pause_restart)
	vb.add_child(btn_pause_confirm)
	$HUD.add_child(pause_menu)
	btn_pause_resume.pressed.connect(func():
		_ui_tap()
		if paused:
			_toggle_pause()
	)
	btn_pause_restart.pressed.connect(func():
		_ui_tap()
		_restart_confirm_armed = true
		btn_pause_confirm.visible = true
		label_info.text = "再点「确认重新开始」才会清空本局"
	)
	btn_pause_confirm.pressed.connect(func():
		_ui_tap()
		if _restart_confirm_armed:
			_restart_confirm_armed = false
			btn_pause_confirm.visible = false
			if pause_menu:
				pause_menu.visible = false
			_restart()
	)


func _build_undo_cancel_buttons() -> void:
	btn_undo = _mk_touch_btn("↶", 88)
	btn_undo.name = "UndoButton"
	btn_undo.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_undo.offset_left = 116
	btn_undo.offset_top = 52
	btn_undo.offset_right = 204
	btn_undo.offset_bottom = 140
	btn_undo.tooltip_text = ""
	$HUD.add_child(btn_undo)
	btn_undo.pressed.connect(func(): _ui_tap(); _undo())
	btn_cancel = _mk_touch_btn("✕", 88)
	btn_cancel.name = "CancelButton"
	btn_cancel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_cancel.offset_left = 212
	btn_cancel.offset_top = 52
	btn_cancel.offset_right = 300
	btn_cancel.offset_bottom = 140
	$HUD.add_child(btn_cancel)
	btn_cancel.pressed.connect(func(): _ui_tap(); _cancel_mode())
	var btn_fit := _mk_touch_btn("全图", 88)
	btn_fit.name = "FitCameraButton"
	btn_fit.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_fit.offset_left = 308
	btn_fit.offset_top = 52
	btn_fit.offset_right = 396
	btn_fit.offset_bottom = 140
	$HUD.add_child(btn_fit)
	btn_fit.pressed.connect(func():
		_ui_tap()
		if map_view:
			map_view.reset_camera()
			label_info.text = "相机：全图"
	)
	_refresh_undo_cancel_visibility()


func _refresh_undo_cancel_visibility() -> void:
	var show := ui_phase == UiPhase.SETUP or ui_phase == UiPhase.SCOUT or ui_phase == UiPhase.WAIT
	if btn_undo:
		btn_undo.visible = ui_phase == UiPhase.SETUP
		btn_undo.disabled = undo_stack.is_empty()
	if btn_cancel:
		btn_cancel.visible = show


func _push_undo() -> void:
	if ui_phase != UiPhase.SETUP or plan.is_empty():
		return
	undo_stack.append({
		"plan": plan.duplicate(true),
		"op_placed": op_placed.duplicate(true),
		"setup_tool": setup_tool,
		"place_mode": place_mode,
		"selected_op_id": selected_op_id,
	})
	while undo_stack.size() > UNDO_MAX:
		undo_stack.pop_front()
	_refresh_undo_cancel_visibility()


func _undo() -> void:
	if undo_stack.is_empty() or ui_phase != UiPhase.SETUP:
		return
	var snap: Dictionary = undo_stack.pop_back()
	plan = snap.get("plan", {}).duplicate(true)
	op_placed = snap.get("op_placed", {}).duplicate(true)
	setup_tool = str(snap.get("setup_tool", "op"))
	place_mode = snap.get("place_mode", PlaceMode.OP)
	selected_op_id = str(snap.get("selected_op_id", ""))
	pending_place_cell = Vector2i(-1, -1)
	if map_view:
		map_view.place_ghost_cell = Vector2i(-1, -1)
		map_view.selected_op_id = selected_op_id
	_refresh_tool_chips()
	_refresh_trigger_chips()
	_update_legal_highlights()
	_refresh_op_cards()
	_refresh_portrait_strip()
	_refresh_start_gate()
	_refresh_undo_cancel_visibility()
	label_info.text = "已撤销"
	_push_map_snapshot()


func _cancel_mode() -> void:
	## ✕ / Esc / Android back: exit tool, clear preview, cancel aim drag.
	if _aim_drag_active:
		_cancel_aim_drag()
		return
	if ui_phase == UiPhase.SCOUT:
		_clear_scout_preview()
		scout_dest_flag = Vector2i(-1, -1)
		label_info.text = "已取消预览"
		_push_map_snapshot()
		return
	if ui_phase == UiPhase.SETUP:
		pending_place_cell = Vector2i(-1, -1)
		if map_view:
			map_view.place_ghost_cell = Vector2i(-1, -1)
			map_view.trip_preview_a = Vector2i(-1, -1)
			map_view.trip_preview_b = Vector2i(-1, -1)
		if setup_tool != "op" or place_mode != PlaceMode.OP:
			setup_tool = "op"
			place_mode = PlaceMode.OP
			_trip_drag_start = Vector2i(-1, -1)
			_refresh_tool_chips()
			_update_legal_highlights()
			label_info.text = "工具回到队员"
		else:
			label_info.text = "已取消"
		_push_map_snapshot()
		return
	if ui_phase == UiPhase.WAIT:
		label_info.text = "已取消"
		_push_map_snapshot()


func _cancel_aim_drag() -> void:
	## Restore facing (setup) / skip submit (wait); cancel gesture.
	if ui_phase == UiPhase.SETUP and selected_op_id != "" and not is_nan(_facing_before_aim):
		for op in plan.get("operators", []):
			if str(op["id"]) == selected_op_id:
				op["facing_deg"] = _facing_before_aim
				break
	_aim_drag_active = false
	_facing_before_aim = NAN
	if map_view and map_view.gesture:
		map_view.gesture.cancel()
		map_view._dragging_op = ""
		map_view.aim_preview_op = ""
		map_view.aim_preview_deg = NAN
		map_view.queue_redraw()
	label_info.text = "转向已取消"
	_push_map_snapshot()


func _on_aim_drag_started_track(op_id: String, _pos: Vector2) -> void:
	_aim_drag_active = true
	if ui_phase == UiPhase.SETUP:
		_push_undo()
		_skip_next_place_undo = true
		for op in plan.get("operators", []):
			if str(op["id"]) == op_id:
				_facing_before_aim = float(op.get("facing_deg", 0.0))
				break
	elif ui_phase == UiPhase.WAIT and sim != null:
		var op := _sim_op(op_id)
		_facing_before_aim = float(op.get("facing_deg", 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.keycode == KEY_ESCAPE or k.keycode == KEY_BACK:
			_cancel_mode()
			get_viewport().set_input_as_handled()
			return
		if k.keycode == KEY_Z and k.ctrl_pressed:
			_undo()
			get_viewport().set_input_as_handled()
			return
		# PR-8: WASD pan.
		if map_view and k.keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			var step := 48.0 / maxf(map_view.cam_zoom, 0.01)
			match k.keycode:
				KEY_W, KEY_UP:
					map_view.cam_pan.y -= step
				KEY_S, KEY_DOWN:
					map_view.cam_pan.y += step
				KEY_A, KEY_LEFT:
					map_view.cam_pan.x -= step
				KEY_D, KEY_RIGHT:
					map_view.cam_pan.x += step
			map_view._clamp_camera()
			map_view.queue_redraw()
			get_viewport().set_input_as_handled()
			return


func _build_dev_menu() -> void:
	btn_dev_toggle = _mk_touch_btn("开发", 100)
	btn_dev_toggle.name = "DevMenuToggle"
	btn_dev_toggle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	btn_dev_toggle.offset_left = 8
	btn_dev_toggle.offset_top = 52
	btn_dev_toggle.offset_right = 108
	btn_dev_toggle.offset_bottom = 140
	$HUD.add_child(btn_dev_toggle)
	dev_menu = VBoxContainer.new()
	dev_menu.name = "DevMenu"
	dev_menu.visible = false
	dev_menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dev_menu.offset_left = 8
	dev_menu.offset_top = 148
	dev_menu.offset_right = 280
	dev_menu.offset_bottom = 520
	dev_menu.add_theme_constant_override("separation", 6)
	$HUD.add_child(dev_menu)
	btn_dev_toggle.pressed.connect(func():
		_ui_tap()
		dev_menu.visible = not dev_menu.visible
	)
	# Move debug controls into the menu (reparent keeps signal connections).
	for b in [btn_example, btn_plan_a, btn_plan_b, btn_preview, btn_g2_art, btn_scout_preview]:
		if b == null:
			continue
		b.get_parent().remove_child(b)
		dev_menu.add_child(b)
		b.visible = true
		b.custom_minimum_size = Vector2(240, TOUCH_MIN_PX)
		b.add_theme_font_size_override("font_size", BODY_FONT_PX)
	# Plan A/B stay hidden until example toggle.
	if btn_plan_a:
		btn_plan_a.visible = false
	if btn_plan_b:
		btn_plan_b.visible = false


func _apply_touch_sizing() -> void:
	## Enforce ≥88 design-px touch targets and ≥22 body text.
	for n in [label_phase, label_info, label_alert, label_start_reason, label_scout_clock, label_scout_kit]:
		if n:
			n.add_theme_font_size_override("font_size", maxi(BODY_FONT_PX, int(n.get_theme_font_size("font_size"))))
	for b in [btn_start, btn_begin_setup, btn_pause, btn_speed, btn_detonate, btn_restart, btn_rescout, btn_restart_wait]:
		if b == null:
			continue
		var sz: Vector2 = b.custom_minimum_size
		b.custom_minimum_size = Vector2(maxf(sz.x, TOUCH_MIN_PX), maxf(sz.y, TOUCH_MIN_PX))
		b.add_theme_font_size_override("font_size", maxi(BODY_FONT_PX, int(b.get_theme_font_size("font_size"))))
	if trigger_option:
		trigger_option.custom_minimum_size = Vector2(0, TOUCH_MIN_PX)
	# Side panels become lighter overlays (map is full-bleed).
	if setup_panel:
		setup_panel.offset_left = -300.0
		setup_panel.offset_bottom = -130.0
	if scout_panel:
		scout_panel.offset_left = -300.0
		scout_panel.offset_bottom = -130.0
	if wait_panel:
		wait_panel.offset_left = -300.0
		wait_panel.offset_bottom = -130.0


func _refresh_thumb_visibility() -> void:
	if thumb_bar == null:
		return
	var scout := ui_phase == UiPhase.SCOUT
	var setup := ui_phase == UiPhase.SETUP
	var wait := ui_phase == UiPhase.WAIT
	if btn_thumb_begin:
		btn_thumb_begin.visible = scout
	if btn_thumb_start:
		btn_thumb_start.visible = setup
	if btn_thumb_pause:
		btn_thumb_pause.visible = scout or wait
	if btn_thumb_speed:
		btn_thumb_speed.visible = wait
	if btn_thumb_detonate:
		btn_thumb_detonate.visible = wait
	thumb_bar.visible = scout or setup or wait


func _detonate_now_ms() -> int:
	if detonate_now_ms_fn.is_valid():
		return int(detonate_now_ms_fn.call())
	return Time.get_ticks_msec()


func _on_detonate_down() -> void:
	_detonate_holding = true
	_detonate_press_ms = _detonate_now_ms()
	if btn_thumb_detonate:
		btn_thumb_detonate.text = "按住…"


func _on_detonate_up() -> void:
	if not _detonate_holding:
		return
	var held := _detonate_now_ms() - _detonate_press_ms
	_detonate_holding = false
	if btn_thumb_detonate:
		btn_thumb_detonate.text = "长按起爆"
	if held >= DETONATE_LONGPRESS_MS:
		_ui_tap()
		_manual_detonate()
	else:
		label_info.text = "起爆需长按 %.1f 秒" % (float(DETONATE_LONGPRESS_MS) / 1000.0)


func _set_ui_phase(p: UiPhase) -> void:
	ui_phase = p
	if scout_panel:
		scout_panel.visible = p == UiPhase.SCOUT
	setup_panel.visible = p == UiPhase.SETUP
	wait_panel.visible = p == UiPhase.WAIT
	result_panel.visible = p == UiPhase.RESULT
	match p:
		UiPhase.SCOUT:
			label_phase.text = "侦察"
		UiPhase.SETUP:
			label_phase.text = "布阵"
		UiPhase.WAIT:
			label_phase.text = "等待"
		UiPhase.RESULT:
			label_phase.text = "结算"
	if pause_menu and p != UiPhase.WAIT:
		pause_menu.visible = false
		_restart_confirm_armed = false
	_refresh_portrait_strip()
	_update_setup_chrome_visibility()
	_update_legal_highlights()
	_refresh_tool_chips()
	_refresh_trigger_chips()
	_refresh_thumb_visibility()
	_refresh_undo_cancel_visibility()
	if p == UiPhase.SETUP and undo_stack.is_empty() and not plan.is_empty():
		# Baseline so first undo after mutations is meaningful.
		pass


func start_block_reason() -> String:
	## One-line Chinese reason when 「开始等待」 is disabled. Empty = can start.
	if plan.get("operators", []).is_empty():
		return "请放置队员"
	for op in plan.get("operators", []):
		var oid := str(op["id"])
		if not bool(op_placed.get(oid, false)):
			return "请放置全部队员"
	var trig: Dictionary = plan.get("trigger", {})
	var t := str(trig.get("type", ""))
	if t.is_empty():
		return "请选择起爆条件"
	match t:
		"mine_detonate":
			if plan.get("mines", []).is_empty():
				return "请在地图上放置地雷"
			if str(trig.get("bind", "")).is_empty():
				return "请在地图上放置地雷"
		"cross_marker":
			if not trig.has("a") or not trig.has("b"):
				return "请在地图上设置越线标记"
		"see_first_enemy":
			if str(trig.get("bind", "")).is_empty():
				return "请选择起爆观察队员"
	return ""


func can_start_wait() -> bool:
	return start_block_reason().is_empty()


func _apply_kit_ammo_to_plan() -> void:
	## PLAY-6: finite ammo from gathered kit pools (or loadout_start) into each operator.
	var pools: Dictionary = {} ## pool_id → rounds left
	var src: Dictionary = gathered_kit if not gathered_kit.is_empty() else level.get("loadout_start", {})
	for a in src.get("ammo_pools", []):
		pools[str(a.get("pool_id", ""))] = int(a.get("rounds", 0))
	for op in plan.get("operators", []):
		var wid := str(op.get("weapon_id", ""))
		if wid in ["grenade", "mine"]:
			op["ammo"] = 0
			continue
		var pool := str(SimConstants.WEAPON_AMMO_POOL.get(wid, ""))
		var default_n := int(SimConstants.DEFAULT_AMMO.get(wid, 12))
		if pool != "" and pools.has(pool) and int(pools[pool]) > 0:
			var take: int = mini(default_n, int(pools[pool]))
			pools[pool] = int(pools[pool]) - take
			op["ammo"] = take
		elif not op.has("ammo"):
			op["ammo"] = default_n
		op["hp"] = int(op.get("hp", SimConstants.OP_MAX_HP))


func _refresh_start_gate() -> void:
	var reason := start_block_reason()
	if btn_start:
		btn_start.disabled = not reason.is_empty()
	if btn_thumb_start:
		btn_thumb_start.disabled = not reason.is_empty()
		if reason.is_empty():
			btn_thumb_start.text = "开始等待"
		else:
			btn_thumb_start.text = reason if reason.length() <= 10 else "开始等待"
	if label_start_reason:
		label_start_reason.text = reason
		label_start_reason.visible = not reason.is_empty()


func _start_wait() -> void:
	var reason := start_block_reason()
	if not reason.is_empty():
		label_info.text = reason
		_refresh_start_gate()
		return
	_apply_kit_ammo_to_plan()
	sim = NightSim.new()
	sim.setup(level, plan, weapons)
	sim.begin_wait()
	paused = false
	speed_mul = 1.0
	_accum_s = 0.0
	_last_alert = str(sim.alert)
	_detonate_sfx_played = false
	_log_cursor = 0
	_pending_result = false
	_result_delay_left = 0.0
	_slow_mo_left = 0.0
	_fx_fires_total = 0
	_fx_kills_total = 0
	_enemy_prev_pos.clear()
	_enemy_in_cone.clear()
	if map_view and map_view.combat_fx:
		map_view.combat_fx.reset()
		map_view.shake_offset = Vector2.ZERO
	btn_speed.text = "倍速 1×"
	_set_ui_phase(UiPhase.WAIT)
	if sfx:
		sfx.start_ambient("ambient_yard", -14.0)
	_push_map_snapshot()


func _toggle_pause() -> void:
	paused = not paused
	var t := "继续" if paused else "暂停"
	if btn_pause:
		btn_pause.text = t
	if btn_thumb_pause:
		btn_thumb_pause.text = t
	if pause_menu:
		# Restart confirm only in WAIT; scout pause is timing-only.
		pause_menu.visible = paused and ui_phase == UiPhase.WAIT
		if not paused:
			_restart_confirm_armed = false
			if btn_pause_confirm:
				btn_pause_confirm.visible = false
	if ui_phase == UiPhase.SCOUT:
		label_info.text = "侦察已暂停 · 仍可点格预览/下令" if paused else "侦察继续"


func _cycle_speed() -> void:
	if speed_mul < 1.5:
		speed_mul = 2.0
		btn_speed.text = "倍速 2×"
		if btn_thumb_speed:
			btn_thumb_speed.text = "倍速 2×"
	else:
		speed_mul = 1.0
		btn_speed.text = "倍速 1×"
		if btn_thumb_speed:
			btn_thumb_speed.text = "倍速 1×"


func _manual_detonate() -> void:
	if sim == null or ui_phase != UiPhase.WAIT:
		return
	sim.request_manual_detonate()
	label_info.text = "已请求手动起爆"


func _restart() -> void:
	## Keep player's last plan (DESIGN_V2 §4.5); do not force preset A.
	sim = null
	last_summary = {}
	last_review = {}
	searched_bodies.clear()
	body_search_enabled = false
	preview_cell = Vector2i(-1, -1)
	preview_seers = []
	place_mode = PlaceMode.OP
	_set_ui_phase(UiPhase.SETUP)
	_sync_trigger_option_from_plan()
	_build_op_cards()
	_push_map_snapshot()
	_refresh_start_gate()
	label_info.text = "已保留上一局计划 · 可继续微调"


func _restart_scout() -> void:
	## PLAY-5: full reset into scout/gather for a fresh night.
	sim = null
	scout = null
	last_summary = {}
	last_review = {}
	searched_bodies.clear()
	body_search_enabled = false
	plan = {}
	gathered_kit = {}
	op_placed.clear()
	op_display_names.clear()
	preview_cell = Vector2i(-1, -1)
	preview_seers = []
	_start_scout_phase()
	_push_map_snapshot()
	label_info.text = "重新侦察 · 搜集补给后再布阵"


func _toggle_preview_hint() -> void:
	label_info.text = "点地面：看谁能看见这里（预览＝模拟）"


func _on_cell_tapped(cell: Vector2i) -> void:
	if ui_phase == UiPhase.RESULT and body_search_enabled:
		if _try_search_body_at(cell):
			return
	if ui_phase == UiPhase.SCOUT:
		_on_scout_cell_tapped(cell)
		return
	if ui_phase == UiPhase.SETUP:
		preview_cell = cell
		preview_seers = _preview_who_sees(cell)
		match place_mode:
			PlaceMode.MINE:
				_place_mine_at(cell)
			PlaceMode.TRIGGER_A, PlaceMode.TRIGGER_B:
				# PR-4: trip line is one drag, not two taps.
				label_info.text = "触发线：按住拖出起点→终点"
			_:
				if selected_op_id != "" and grid.walkable(cell.x, cell.y):
					_handle_op_place_tap(cell)
				else:
					pending_place_cell = Vector2i(-1, -1)
					if map_view:
						map_view.place_ghost_cell = Vector2i(-1, -1)
					label_info.text = "格 (%d,%d) · 可见观察者 %d" % [cell.x, cell.y, preview_seers.size()]
		_push_map_snapshot()
		_refresh_start_gate()
	elif ui_phase == UiPhase.WAIT and sim != null:
		preview_cell = cell
		preview_seers = sim.observers_seeing_cell(float(cell.x), float(cell.y), grid.tier_at(float(cell.x), float(cell.y)))
		label_info.text = "格 (%d,%d) · 可见 %d" % [cell.x, cell.y, preview_seers.size()]
		_push_map_snapshot()


func _handle_op_place_tap(cell: Vector2i) -> void:
	## Ghost + confirm: first tap shows ✓, second tap same cell places.
	if pending_place_cell == cell:
		_move_selected_op(cell)
		pending_place_cell = Vector2i(-1, -1)
		if map_view:
			map_view.place_ghost_cell = Vector2i(-1, -1)
		return
	pending_place_cell = cell
	if map_view:
		map_view.place_ghost_cell = cell
	label_info.text = "放置预览 (%d,%d) · 再点确认 / 拖队员落位" % [cell.x, cell.y]


func _on_scout_cell_tapped(cell: Vector2i) -> void:
	if scout == null or scout.is_finished():
		return
	preview_cell = cell
	# Tap another operator to select.
	for op in scout.operators:
		if int(op["x"]) == cell.x and int(op["y"]) == cell.y:
			selected_op_id = str(op["id"])
			_clear_scout_preview()
			label_info.text = "选中 %s · 点格预览路径，再点确认" % op_display_names.get(selected_op_id, selected_op_id)
			_push_map_snapshot()
			return
	if selected_op_id == "":
		label_info.text = "请先点选一名队员"
		return
	# Desktop mouse: hover already set preview → click confirms immediately.
	if _scout_hover_from_mouse and pending_scout_goal == cell and not preview_path.is_empty():
		_confirm_scout_move(cell)
		return
	# Touch: first tap = preview; second tap same cell = confirm.
	if pending_scout_goal == cell and not preview_path.is_empty():
		_confirm_scout_move(cell)
		return
	_set_scout_preview(cell)
	_push_map_snapshot()


func _set_scout_preview(cell: Vector2i) -> void:
	if scout == null or selected_op_id == "":
		return
	var path: Array = scout.compute_path(selected_op_id, cell)
	if path.is_empty():
		preview_path = []
		scout_danger_cells = []
		pending_scout_goal = Vector2i(-1, -1)
		scout_preview_cost_s = 0.0
		label_info.text = "无法到达 (%d,%d)" % [cell.x, cell.y]
		return
	preview_path = path
	pending_scout_goal = cell
	scout_dest_flag = cell
	var steps := maxi(0, path.size() - 1)
	scout_preview_cost_s = float(steps) * float(scout.move_ticks_per_cell()) * SimConstants.DT_S
	scout_danger_cells = []
	for p in path:
		var c: Vector2i = p
		var tier: String = str(grid.tier_at(float(c.x), float(c.y)))
		if scout.is_cell_watched(float(c.x), float(c.y), tier):
			scout_danger_cells.append(c)
	var risk := " · 被看见风险" if not scout_danger_cells.is_empty() else ""
	label_info.text = "预览 (%d,%d) · 耗时 %.0fs%s · 再点确认 / ✓" % [
		cell.x, cell.y, scout_preview_cost_s, risk
	]


func _confirm_scout_move(cell: Vector2i) -> void:
	if scout == null or selected_op_id == "":
		return
	if scout.request_move(selected_op_id, cell):
		scout_dest_flag = cell
		label_info.text = "%s 前往 (%d,%d) · %.0fs" % [
			op_display_names.get(selected_op_id, "队员"), cell.x, cell.y, scout_preview_cost_s
		]
		preview_path = []
		scout_danger_cells = []
		pending_scout_goal = Vector2i(-1, -1)
		_scout_hover_from_mouse = false
	else:
		label_info.text = "无法到达 (%d,%d)" % [cell.x, cell.y]
	_push_map_snapshot()


func _clear_scout_preview() -> void:
	preview_path = []
	scout_danger_cells = []
	pending_scout_goal = Vector2i(-1, -1)
	scout_preview_cost_s = 0.0
	_scout_hover_from_mouse = false
	# Keep dest flag until unit arrives (cleared in _process).


func _on_cell_hovered(cell: Vector2i) -> void:
	## Desktop hover preview during scout (does not commit path).
	if ui_phase != UiPhase.SCOUT or scout == null or scout.is_finished():
		return
	if selected_op_id == "":
		return
	# Don't hover-preview on own unit cell.
	for op in scout.operators:
		if int(op["x"]) == cell.x and int(op["y"]) == cell.y:
			return
	_scout_hover_from_mouse = true
	_set_scout_preview(cell)
	_push_map_snapshot()


func _on_cell_long_pressed(cell: Vector2i) -> void:
	## PR-6 who-sees; PR-7 long-press delete mine / trip line in SETUP.
	preview_cell = cell
	if ui_phase == UiPhase.SETUP:
		if _try_delete_mine_at(cell) or _try_delete_trip_near(cell):
			return
		preview_seers = _preview_who_sees(cell)
	elif ui_phase == UiPhase.SCOUT and scout != null:
		preview_seers = _preview_who_sees_level_observers(cell)
	elif ui_phase == UiPhase.WAIT and sim != null:
		preview_seers = sim.observers_seeing_cell(
			float(cell.x), float(cell.y), grid.tier_at(float(cell.x), float(cell.y))
		)
	else:
		return
	label_info.text = "格 (%d,%d) · 可见观察者 %d" % [cell.x, cell.y, preview_seers.size()]
	_push_map_snapshot()


func _try_delete_mine_at(cell: Vector2i) -> bool:
	var mines: Array = plan.get("mines", [])
	for i in range(mines.size()):
		var m: Dictionary = mines[i]
		if int(m.get("x", -1)) == cell.x and int(m.get("y", -1)) == cell.y:
			_push_undo()
			mines.remove_at(i)
			plan["mines"] = mines
			if str(plan.get("trigger", {}).get("type", "")) == "mine_detonate":
				plan["trigger"] = {"type": "mine_detonate", "bind": ""}
			label_info.text = "已删除地雷 (%d,%d)" % [cell.x, cell.y]
			_refresh_start_gate()
			_push_map_snapshot()
			return true
	return false


func _try_delete_trip_near(cell: Vector2i) -> bool:
	var trig: Dictionary = plan.get("trigger", {})
	if str(trig.get("type", "")) != "cross_marker" or not trig.has("a") or not trig.has("b"):
		return false
	var a := Vector2i(int(trig["a"]["x"]), int(trig["a"]["y"]))
	var b := Vector2i(int(trig["b"]["x"]), int(trig["b"]["y"]))
	# Near either endpoint or midpoint (Chebyshev ≤1).
	var mid := Vector2i(int(round((a.x + b.x) * 0.5)), int(round((a.y + b.y) * 0.5)))
	if _cheb(cell, a) > 1 and _cheb(cell, b) > 1 and _cheb(cell, mid) > 1:
		return false
	_push_undo()
	trig = trig.duplicate(true)
	trig.erase("a")
	trig.erase("b")
	plan["trigger"] = trig
	label_info.text = "已删除触发线"
	_refresh_start_gate()
	_push_map_snapshot()
	return true


func _cheb(p: Vector2i, q: Vector2i) -> int:
	return maxi(absi(p.x - q.x), absi(p.y - q.y))


func _preview_who_sees_level_observers(cell: Vector2i) -> Array:
	## Scout-phase who-sees without NightSim operators (sentries/patrols only).
	if scout == null:
		return []
	var out: Array = []
	var ttier: String = str(grid.tier_at(float(cell.x), float(cell.y)))
	for s in scout.sentries:
		if _observer_dict_sees(s, float(s["x"]), float(s["y"]), str(s.get("tier", "ground")), float(cell.x), float(cell.y), ttier):
			out.append(s)
	for p in scout.patrols:
		if _observer_dict_sees(p, float(p["x"]), float(p["y"]), "ground", float(cell.x), float(cell.y), ttier):
			out.append(p)
	return out


func _observer_dict_sees(obs: Dictionary, ox: float, oy: float, otier: String, tx: float, ty: float, ttier: String) -> bool:
	var cone: Dictionary = obs.get("cone", {})
	var facing := float(cone.get("facing_deg", 0))
	var half := float(cone.get("angle_deg", 50)) * 0.5
	var rng := float(cone.get("range_cells", 8))
	if ttier == "high":
		rng *= SimConstants.SILHOUETTE_MUL
	if not SimGeom.in_cone(ox, oy, facing, half, rng, tx, ty):
		return false
	return grid.los_clear(ox, oy, otier, tx, ty, ttier)


func _refresh_scout_hud() -> void:
	if scout == null:
		return
	if label_scout_clock:
		label_scout_clock.text = "夜时剩余 %.0f 秒" % scout.remaining_budget_s()
	if label_scout_kit:
		var parts: Array = []
		for w in scout.kit.get("weapons", []):
			parts.append("%s×%d" % [
				scout.item_label_zh(str(w.get("weapon_id", ""))),
				int(w.get("count", 0)),
			])
		for a in scout.kit.get("ammo_pools", []):
			parts.append("%s %d" % [str(a.get("pool_id", "")), int(a.get("rounds", 0))])
		label_scout_kit.text = "套件：" + " · ".join(parts)
	label_alert.text = _alert_zh(scout.alert)


func _place_mine_at(cell: Vector2i) -> void:
	if not grid.walkable(cell.x, cell.y):
		label_info.text = "此处不能放地雷（非法格）"
		return
	_push_undo()
	var mid := "mine_%d_%d" % [cell.x, cell.y]
	plan["mines"] = [{"id": mid, "x": cell.x, "y": cell.y}]
	plan["trigger"] = {"type": "mine_detonate", "bind": mid}
	place_mode = PlaceMode.OP
	setup_tool = "op"
	_refresh_tool_chips()
	_refresh_trigger_chips()
	_update_legal_highlights()
	label_info.text = "地雷已放在 (%d,%d) · 工具回到队员" % [cell.x, cell.y]


func _place_trigger_point(cell: Vector2i, is_a: bool) -> void:
	var trig: Dictionary = plan.get("trigger", {"type": "cross_marker", "bind": "marker_y7"}).duplicate(true)
	trig["type"] = "cross_marker"
	if not trig.has("bind"):
		trig["bind"] = "marker_y7"
	if is_a:
		trig["a"] = {"x": cell.x, "y": cell.y}
		trig.erase("b")
		plan["trigger"] = trig
		place_mode = PlaceMode.TRIGGER_B
		label_info.text = "越线起点 (%d,%d) · 再点终点" % [cell.x, cell.y]
	else:
		trig["b"] = {"x": cell.x, "y": cell.y}
		if not trig.has("a"):
			trig["a"] = {"x": cell.x, "y": cell.y}
		plan["trigger"] = trig
		place_mode = PlaceMode.OP
		label_info.text = "越线标记已设 (%d,%d)–(%d,%d)" % [
			int(trig["a"]["x"]), int(trig["a"]["y"]), cell.x, cell.y
		]


func _preview_who_sees(cell: Vector2i) -> Array:
	## SETUP uses a throwaway sim geometry query without advancing time.
	var tmp := NightSim.new()
	var stub_plan := plan.duplicate(true)
	tmp.setup(level, stub_plan, weapons)
	return tmp.observers_seeing_cell(float(cell.x), float(cell.y), grid.tier_at(float(cell.x), float(cell.y)))


func _move_selected_op(cell: Vector2i) -> void:
	if selected_op_id == "":
		return
	# Reject stacking on another operator.
	for op in plan.get("operators", []):
		if str(op["id"]) != selected_op_id and int(op["x"]) == cell.x and int(op["y"]) == cell.y:
			label_info.text = "该格已有队员"
			return
	# Aim-drag already pushed undo at drag start; ghost/tap place needs its own.
	if _skip_next_place_undo:
		_skip_next_place_undo = false
	else:
		_push_undo()
	for op in plan.get("operators", []):
		if str(op["id"]) == selected_op_id:
			op["x"] = cell.x
			op["y"] = cell.y
			op["tier"] = grid.tier_at(float(cell.x), float(cell.y))
			op_placed[selected_op_id] = true
			var dname := str(op_display_names.get(selected_op_id, "队员"))
			var tier := str(op["tier"])
			label_info.text = "%s 已放置 (%d,%d)%s · 拖锥尖设朝向" % [
				dname, cell.x, cell.y, " · 高点" if tier == "high" else ""
			]
			# PR-4: keep selection for aim handle; empty taps use ghost confirm (no teleport).
			if map_view:
				map_view.selected_op_id = selected_op_id
				map_view.place_ghost_cell = Vector2i(-1, -1)
			pending_place_cell = Vector2i(-1, -1)
			_refresh_op_cards()
			_refresh_portrait_strip()
			return


func _on_cell_dragged(_cell: Vector2i, world_dir: Vector2) -> void:
	## SETUP place-drag: ghost under finger. WAIT: facing preview only.
	if selected_op_id == "":
		return
	if world_dir.length() < 8.0:
		return
	var facing := rad_to_deg(atan2(-world_dir.y, world_dir.x))
	if ui_phase == UiPhase.SETUP:
		# Live facing while aiming near unit; place ghost when over a cell.
		_last_unit_drag_cell = _cell
		if setup_tool == "op" and map_view:
			map_view.place_ghost_cell = _cell
			pending_place_cell = _cell
		for op in plan.get("operators", []):
			if str(op["id"]) == selected_op_id:
				op["facing_deg"] = facing
				break
		_push_map_snapshot()
		return
	if ui_phase == UiPhase.WAIT and sim != null and not sim.plan_locked:
		# Preview cost text only — do NOT call request_operator_facing here.
		var delta := _facing_delta_deg(float(_sim_op(selected_op_id).get("facing_deg", 0.0)), facing)
		var steps := int(ceil(delta / 45.0 - 1e-9))
		var cost_s := float(steps) * SimConstants.TURN_COST_S_PER_45
		var dname := str(op_display_names.get(selected_op_id, "队员"))
		label_info.text = "%s 预览转向 %.0f° · 约 %.1fs · 松手确认 / 拖回取消" % [dname, delta, cost_s]
		_push_map_snapshot()


func _facing_delta_deg(from_deg: float, to_deg: float) -> float:
	return SimGeom.abs_angle_delta_deg(from_deg, to_deg)


func _on_aim_drag_ended(op_id: String, world_dir: Vector2, preview_deg: float, cancelled: bool) -> void:
	_aim_drag_active = false
	if ui_phase == UiPhase.SETUP:
		if cancelled and not is_nan(_facing_before_aim):
			for op in plan.get("operators", []):
				if str(op["id"]) == op_id:
					op["facing_deg"] = _facing_before_aim
					break
			_facing_before_aim = NAN
			label_info.text = "转向已取消"
			_push_map_snapshot()
			return
		_facing_before_aim = NAN
		_on_setup_unit_drag_ended(op_id, world_dir, preview_deg, cancelled)
		return
	if ui_phase != UiPhase.WAIT or sim == null or sim.plan_locked:
		_facing_before_aim = NAN
		return
	if cancelled or op_id == "" or world_dir.length() < 8.0 or is_nan(preview_deg):
		_facing_before_aim = NAN
		label_info.text = "转向已取消"
		_push_map_snapshot()
		return
	# ONE turn order on release.
	sim.request_operator_facing(op_id, preview_deg)
	_facing_submit_count += 1
	_facing_before_aim = NAN
	var op := _sim_op(op_id)
	var left := int(op.get("turn_ticks_left", 0))
	var dname := str(op_display_names.get(op_id, "队员"))
	if left > 0:
		label_info.text = "%s 转向中 · %.1fs · 不能开火" % [dname, float(left) * SimConstants.DT_S]
	else:
		label_info.text = "%s 朝向已更新" % dname
	_refresh_portrait_strip()
	_push_map_snapshot()


func _on_setup_unit_drag_ended(op_id: String, world_dir: Vector2, preview_deg: float, cancelled: bool) -> void:
	## Drag unit onto a walkable cell → place; else keep facing from drag.
	var drop := _last_unit_drag_cell
	_last_unit_drag_cell = Vector2i(-1, -1)
	if map_view:
		map_view.place_ghost_cell = Vector2i(-1, -1)
	pending_place_cell = Vector2i(-1, -1)
	if cancelled or op_id == "" or setup_tool != "op":
		_push_map_snapshot()
		return
	selected_op_id = op_id
	var ox := 0
	var oy := 0
	for op in plan.get("operators", []):
		if str(op["id"]) == op_id:
			ox = int(op["x"])
			oy = int(op["y"])
			break
	if drop.x < 0 and map_view and world_dir.length() >= 8.0:
		var screen_origin: Vector2 = map_view.cell_to_screen(float(ox), float(oy))
		drop = map_view.screen_to_cell(screen_origin + world_dir)
	if drop.x >= 0 and grid.walkable(drop.x, drop.y) and (drop.x != ox or drop.y != oy):
		_move_selected_op(drop)
		if not is_nan(preview_deg):
			for op2 in plan.get("operators", []):
				if str(op2["id"]) == op_id:
					op2["facing_deg"] = preview_deg
					break
		_refresh_start_gate()
		_push_map_snapshot()
		return
	# Same cell / short drag: facing only (already applied live).
	_push_map_snapshot()
	_refresh_start_gate()


func _on_ground_drag_started(start_cell: Vector2i, _pos: Vector2) -> void:
	if ui_phase != UiPhase.SETUP or setup_tool != "trigger":
		return
	_trip_drag_start = start_cell
	if map_view:
		map_view.trip_preview_a = start_cell
		map_view.trip_preview_b = Vector2i(-1, -1)
		map_view.queue_redraw()
	label_info.text = "触发线起点 (%d,%d) · 拖到终点松手" % [start_cell.x, start_cell.y]


func _on_ground_drag_moved(cell: Vector2i, start_cell: Vector2i, _pos: Vector2) -> void:
	if ui_phase != UiPhase.SETUP or setup_tool != "trigger":
		return
	if map_view:
		map_view.trip_preview_a = start_cell
		map_view.trip_preview_b = cell
		map_view.queue_redraw()
	# Do NOT write plan.trigger mid-drag (PR-4 acceptance).


func _on_ground_drag_ended(end_cell: Vector2i, start_cell: Vector2i, cancelled: bool) -> void:
	if ui_phase != UiPhase.SETUP or setup_tool != "trigger":
		if map_view:
			map_view.trip_preview_a = Vector2i(-1, -1)
			map_view.trip_preview_b = Vector2i(-1, -1)
		return
	if map_view:
		map_view.trip_preview_a = Vector2i(-1, -1)
		map_view.trip_preview_b = Vector2i(-1, -1)
	if cancelled or start_cell == end_cell:
		label_info.text = "触发线已取消"
		_trip_drag_start = Vector2i(-1, -1)
		_push_map_snapshot()
		return
	_push_undo()
	var trig: Dictionary = plan.get("trigger", {}).duplicate(true)
	trig["type"] = "cross_marker"
	if not trig.has("bind"):
		trig["bind"] = "marker_y7"
	trig["a"] = {"x": start_cell.x, "y": start_cell.y}
	trig["b"] = {"x": end_cell.x, "y": end_cell.y}
	plan["trigger"] = trig
	_trip_drag_start = Vector2i(-1, -1)
	setup_tool = "op"
	place_mode = PlaceMode.OP
	_refresh_tool_chips()
	_refresh_trigger_chips()
	_update_legal_highlights()
	label_info.text = "越线标记已设 (%d,%d)–(%d,%d) · 工具回到队员" % [
		start_cell.x, start_cell.y, end_cell.x, end_cell.y
	]
	_push_map_snapshot()
	_refresh_start_gate()


func _sim_op(op_id: String) -> Dictionary:
	if sim == null:
		return {}
	for op in sim.operators:
		if str(op["id"]) == op_id:
			return op
	return {}


func _on_unit_selected(op_id: String) -> void:
	selected_op_id = op_id
	var dname := str(op_display_names.get(op_id, "队员"))
	if ui_phase == UiPhase.SCOUT:
		label_info.text = "选中 %s · 点格行走开箱" % dname
		_refresh_portrait_strip()
		_push_map_snapshot()
		return
	if ui_phase == UiPhase.WAIT:
		label_info.text = "选中 %s · 拖锥尖重瞄（松手确认）" % dname
		_refresh_portrait_strip()
		_push_map_snapshot()
		return
	setup_tool = "op"
	place_mode = PlaceMode.OP
	pending_place_cell = Vector2i(-1, -1)
	if map_view:
		map_view.place_ghost_cell = Vector2i(-1, -1)
	label_info.text = "选中 %s · 拖到目标格落位 / 点格确认放置" % dname
	_refresh_tool_chips()
	_update_legal_highlights()
	_refresh_op_cards()
	_refresh_portrait_strip()
	_push_map_snapshot()


func _build_portrait_strip() -> void:
	if portrait_strip != null:
		return
	portrait_strip = HBoxContainer.new()
	portrait_strip.name = "PortraitStrip"
	portrait_strip.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	portrait_strip.offset_left = 8
	portrait_strip.offset_top = -120
	portrait_strip.offset_right = 420
	portrait_strip.offset_bottom = -8
	portrait_strip.add_theme_constant_override("separation", 8)
	portrait_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	$HUD.add_child(portrait_strip)
	_refresh_portrait_strip()


func _refresh_portrait_strip() -> void:
	if portrait_strip == null:
		return
	for c in portrait_strip.get_children():
		c.queue_free()
	var font_res = load("res://ui/fonts/web_ui_font.tres")
	var ops: Array = []
	if ui_phase == UiPhase.SCOUT and scout != null:
		ops = scout.operators
	elif ui_phase == UiPhase.WAIT and sim != null:
		ops = sim.operators
	elif plan.has("operators"):
		ops = plan.get("operators", [])
	var i := 0
	for op in ops:
		i += 1
		var oid := str(op.get("id", ""))
		var btn := Button.new()
		btn.name = "Portrait_%s" % oid
		btn.custom_minimum_size = Vector2(96, 96)
		btn.toggle_mode = true
		btn.button_pressed = oid == selected_op_id
		var dname := str(op_display_names.get(oid, op.get("display_name", "%d号" % i)))
		var wlab := str(WEAPON_LABEL_ZH.get(str(op.get("weapon_id", "")), op.get("weapon_id", "")))
		var ammo_n := _op_ammo_display(oid, op)
		var hp_n := int(op.get("hp", SimConstants.OP_MAX_HP))
		if sim != null:
			for sop in sim.operators:
				if str(sop.get("id", "")) == oid:
					hp_n = int(sop.get("hp", hp_n))
					break
		btn.text = "%s\n%s\nHP%d 弹%d" % [dname, wlab, hp_n, ammo_n]
		btn.add_theme_font_size_override("font_size", 14)
		if font_res:
			btn.add_theme_font_override("font", font_res)
		if oid == selected_op_id:
			btn.modulate = Color(1.0, 0.95, 0.55)
		btn.pressed.connect(_on_portrait_pressed.bind(oid))
		portrait_strip.add_child(btn)
	portrait_strip.visible = ui_phase != UiPhase.RESULT


func _on_portrait_pressed(oid: String) -> void:
	_ui_tap()
	selected_op_id = oid
	if map_view:
		map_view.selected_op_id = oid
	_on_unit_selected(oid)


func scripted_place_operator(oid: String, x: int, y: int, facing_deg: float = 90.0) -> bool:
	## Test/helper: place one operator (bypasses ghost confirm).
	if not grid.walkable(x, y):
		return false
	selected_op_id = oid
	pending_place_cell = Vector2i(-1, -1)
	_move_selected_op(Vector2i(x, y))
	for op in plan.get("operators", []):
		if str(op["id"]) == oid:
			op["facing_deg"] = facing_deg
			break
	# Match UX2 acceptance: callers may expect clear selection after place helper.
	selected_op_id = ""
	if map_view:
		map_view.selected_op_id = ""
	_push_map_snapshot()
	_refresh_start_gate()
	return bool(op_placed.get(oid, false))


func scripted_place_mine(x: int, y: int) -> void:
	place_mode = PlaceMode.MINE
	_place_mine_at(Vector2i(x, y))
	_push_map_snapshot()
	_refresh_start_gate()


func scripted_place_cross_marker(ax: int, ay: int, bx: int, by: int) -> void:
	place_mode = PlaceMode.TRIGGER_A
	_place_trigger_point(Vector2i(ax, ay), true)
	_place_trigger_point(Vector2i(bx, by), false)
	_push_map_snapshot()
	_refresh_start_gate()


func _process(delta: float) -> void:
	if sfx:
		sfx.tick_gates(delta)
	if map_view and map_view.combat_fx:
		map_view.combat_fx.advance(delta)
		_update_shake(delta)
	if ui_phase == UiPhase.SCOUT and scout != null and not scout.is_finished() and not paused:
		_accum_s += delta * speed_mul
		var dt := SimConstants.DT_S
		while _accum_s >= dt and not scout.is_finished():
			_accum_s -= dt
			scout.advance_one_tick()
			gathered_kit = scout.kit_snapshot()
		_clear_dest_flag_if_arrived()
		_push_map_snapshot()
		_refresh_scout_hud()
		if scout.is_finished():
			begin_setup_from_scout()
		return
	# Hold result panel until delay after last kill (PLAY-3).
	if _pending_result:
		_result_delay_left -= delta
		_push_map_snapshot()
		if _result_delay_left <= 0.0:
			_pending_result = false
			_show_result()
		return
	if ui_phase != UiPhase.WAIT or sim == null or paused:
		return
	if _slow_mo_left > 0.0:
		_slow_mo_left -= delta
	var mul := speed_mul * (SLOW_MO_MUL if _slow_mo_left > 0.0 else 1.0)
	_accum_s += delta * mul
	var dt2 := SimConstants.DT_S
	while _accum_s >= dt2 and not sim.is_finished():
		_accum_s -= dt2
		sim.advance_one_tick()
		_consume_sim_log()
		_tick_wait_audio()
		if sim.is_finished():
			break
	_push_map_snapshot()
	_update_wait_labels()
	if sim.is_finished() and not _pending_result:
		_pending_result = true
		_result_delay_left = RESULT_DELAY_AFTER_KILL_S
		label_info.text = "清场…结算将在 %.0f 秒后显示" % RESULT_DELAY_AFTER_KILL_S


func _tick_wait_audio() -> void:
	## PLAY-4: distance-based march footsteps + tension when enemy enters a cone.
	if sim == null or sfx == null:
		return
	_tick_footsteps()
	_tick_cone_tension()


func _tick_footsteps() -> void:
	var nearest_d := 1e9
	var moved := false
	for e in sim.enemies:
		if not e.get("alive", true) or not e.get("entered", false) or e.get("escaped", false):
			continue
		var eid := str(e["id"])
		var pos := Vector2(float(e["x"]), float(e["y"]))
		if _enemy_prev_pos.has(eid):
			if pos.distance_to(_enemy_prev_pos[eid]) > 0.01:
				moved = true
		_enemy_prev_pos[eid] = pos
		for op in sim.operators:
			if not op.get("alive", true):
				continue
			var d := SimGeom.dist_centers(float(op["x"]), float(op["y"]), pos.x, pos.y)
			if d < nearest_d:
				nearest_d = d
	if not moved or nearest_d >= FOOT_FAR_CELLS:
		return
	var t := clampf((nearest_d - FOOT_NEAR_CELLS) / maxf(0.001, FOOT_FAR_CELLS - FOOT_NEAR_CELLS), 0.0, 1.0)
	var gain := lerpf(-4.0, -22.0, t)
	sfx.play_foot("dirt", gain)


func _tick_cone_tension() -> void:
	for e in sim.enemies:
		if not e.get("alive", true) or not e.get("entered", false) or e.get("escaped", false):
			continue
		var eid := str(e["id"])
		var in_any := false
		for op in sim.operators:
			if not op.get("alive", true):
				continue
			var wid := str(op.get("weapon_id", ""))
			var w: Dictionary = weapons.get(wid, {})
			if w.is_empty():
				continue
			var half := float(w.get("sector_deg", 0)) * 0.5
			var rng := float(w.get("max_range", 0))
			if SimGeom.in_cone(
				float(op["x"]), float(op["y"]), float(op["facing_deg"]), half, rng,
				float(e["x"]), float(e["y"])
			):
				in_any = true
				break
		var was := bool(_enemy_in_cone.get(eid, false))
		_enemy_in_cone[eid] = in_any
		if in_any and not was:
			sfx.play_tension()
			return


func _consume_sim_log() -> void:
	## Feed new NightSim log events into combat FX + per-shot audio.
	if sim == null or map_view == null or map_view.combat_fx == null:
		return
	var events: Array = sim.log.events
	if _log_cursor >= events.size():
		return
	var slice: Array = events.slice(_log_cursor)
	_log_cursor = events.size()
	var got: Dictionary = map_view.combat_fx.consume_events(slice, sim.enemies, sim.operators)
	_fx_fires_total += int(got.get("fires", 0))
	_fx_kills_total += int(got.get("kills", 0))
	for ev in slice:
		var t := str(ev.get("type", ""))
		match t:
			"fire":
				if sfx:
					sfx.play_weapon(str(ev.get("weapon_id", "kar98k")))
			"enemy_fire":
				if sfx:
					sfx.play_weapon("kar98k")
			"hit":
				if sfx:
					sfx.play_hit()
			"op_wounded":
				if sfx:
					sfx.play_hit()
			"kill":
				if sfx:
					sfx.play_body_drop()
				# Final-kill slow-mo when no living entered enemies remain.
				if map_view.combat_fx.living_enemy_count(sim.enemies) == 0:
					_slow_mo_left = SLOW_MO_S
			"mine_detonate":
				if sfx:
					sfx.play_weapon("mine")
			"grenade_throw":
				if sfx:
					sfx.play_grenade_throw()
			"grenade_blast":
				if sfx:
					sfx.play_weapon("grenade")
			_:
				pass
	_refresh_op_cards()
	if int(got.get("mines", 0)) > 0 or int(got.get("grenade_blasts", 0)) > 0:
		# Screen shake driven by combat_fx.shake_*
		pass
	map_view.queue_redraw()


func _update_shake(delta: float) -> void:
	if map_view == null or map_view.combat_fx == null:
		return
	var fx = map_view.combat_fx
	if fx.shake_time_left > 0:
		fx.shake_time_left -= 1
		var amp := float(fx.shake_amp) * (float(fx.shake_time_left) / 10.0)
		map_view.shake_offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	else:
		map_view.shake_offset = Vector2.ZERO
		fx.shake_amp = 0.0


func combat_fx_stats() -> Dictionary:
	## Test hook: fires/kills consumed by the view layer.
	if map_view == null or map_view.combat_fx == null:
		return {"fires": _fx_fires_total, "kills": _fx_kills_total, "bodies": 0}
	var st: Dictionary = map_view.combat_fx.stats()
	st["fires_controller"] = _fx_fires_total
	st["kills_controller"] = _fx_kills_total
	return st


func _update_wait_labels() -> void:
	if sim == null:
		return
	_sync_alert_sfx()
	_maybe_play_detonate_sfx()
	label_alert.text = _alert_zh(sim.alert)
	var sec := int(floor(float(sim.tick) * SimConstants.DT_S))
	var phase_zh := "等待"
	match str(sim.phase):
		"detonate":
			phase_zh = "交火"
		"resolve":
			phase_zh = "清场"
		"wait":
			phase_zh = "等待"
		_:
			phase_zh = "进行中"
	var trig_zh := ""
	if str(sim.trigger_used) != "":
		trig_zh = " · " + ReviewBuilder.trigger_zh(str(sim.trigger_used))
	elif sim.plan_locked:
		trig_zh = " · 计划锁定"
	label_info.text = "已等待 %d 秒 · %s%s" % [sec, phase_zh, trig_zh]


func _sync_alert_sfx() -> void:
	## Alert tier change: g2 alert cue + enemy shout (art/audio_v2/alarm).
	if sim == null or sfx == null:
		return
	var a := str(sim.alert)
	if a != _last_alert:
		sfx.play_alert(a)
		_last_alert = a


func _maybe_play_detonate_sfx() -> void:
	## Sting only — per-shot weapon audio comes from fire events (PLAY-3).
	if sim == null or sfx == null or _detonate_sfx_played:
		return
	if sim.detonate_tick < 0 or str(sim.trigger_used) == "":
		return
	_detonate_sfx_played = true
	sfx.play("ambush_trigger", -2.0)


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
	last_review = ReviewBuilder.build(sim, plan, op_display_names)
	if sfx:
		sfx.stop_ambient()
	searched_bodies.clear()
	body_search_enabled = bool(last_review.get("full_wipe", false))
	_set_ui_phase(UiPhase.RESULT)
	_apply_review_card(last_review)
	_push_map_snapshot()


func _apply_review_card(rev: Dictionary) -> void:
	var outcome_zh := str(rev.get("outcome_zh", "失败"))
	var grade := str(rev.get("grade", "C"))
	if outcome_label:
		outcome_label.text = outcome_zh
	if grade_label:
		grade_label.text = grade
		match grade:
			"S":
				grade_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			"A":
				grade_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.55))
			"B":
				grade_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
			_:
				grade_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.45))
	var std := bool(rev.get("standard_ambush", false))
	if subtitle_label:
		subtitle_label.text = "伏击质量 %s · %s · %s" % [
			grade,
			"标准伏击" if std else "非标准伏击",
			_alert_zh(str(rev.get("summary", {}).get("alert", "quiet"))),
		]
	var chips: Array = rev.get("timeline", [])
	if timeline_label:
		timeline_label.text = "时间线：" + " → ".join(chips)
	var causes: Array = rev.get("causes", [])
	var lines: Array = []
	for i in range(causes.size()):
		lines.append("%d. %s" % [i + 1, str(causes[i])])
	if causes_label:
		causes_label.text = "\n".join(lines)
	if body_hint_label:
		if body_search_enabled:
			var left := _lootable_body_ids().size() - searched_bodies.size()
			body_hint_label.text = "清场搜尸：点地图上的尸体缴获补给（剩余 %d）· 带入下一夜" % maxi(0, left)
			body_hint_label.visible = true
		else:
			body_hint_label.text = ""
			body_hint_label.visible = false
	# Hidden debug mirror for tests (not shown).
	if result_label:
		result_label.visible = false
		result_label.text = "%s|%s" % [outcome_zh, grade]
	label_info.text = "%s · 评级 %s" % [outcome_zh, grade]


func review_card_text() -> String:
	## Test hook: concatenated player-facing review strings (no forbidden tokens).
	var parts: Array = []
	if outcome_label:
		parts.append(outcome_label.text)
	if grade_label:
		parts.append(grade_label.text)
	if subtitle_label:
		parts.append(subtitle_label.text)
	if timeline_label:
		parts.append(timeline_label.text)
	if causes_label:
		parts.append(causes_label.text)
	if body_hint_label and body_hint_label.visible:
		parts.append(body_hint_label.text)
	return "\n".join(parts)


func _lootable_body_ids() -> Array:
	var out: Array = []
	if map_view == null or map_view.combat_fx == null:
		return out
	for id in map_view.combat_fx.bodies.keys():
		out.append(str(id))
	return out


func _try_search_body_at(cell: Vector2i) -> bool:
	if map_view == null or map_view.combat_fx == null:
		return false
	for id in map_view.combat_fx.bodies.keys():
		if searched_bodies.has(str(id)):
			continue
		var b: Dictionary = map_view.combat_fx.bodies[id]
		var bx := int(floor(float(b.get("x", -99))))
		var by := int(floor(float(b.get("y", -99))))
		if bx == cell.x and by == cell.y:
			_search_body(str(id))
			return true
	return false


func _search_body(enemy_id: String) -> void:
	if searched_bodies.has(enemy_id):
		return
	searched_bodies[enemy_id] = true
	var loot := _roll_body_loot(enemy_id)
	next_night_loot.append(loot)
	_save_next_night_loot_stub()
	if sfx:
		sfx.play("ui_tap", -6.0)
	var left := 0
	for id in _lootable_body_ids():
		if not searched_bodies.has(str(id)):
			left += 1
	label_info.text = "搜尸获得：%s · 已存入下一夜套件" % str(loot.get("label_zh", "补给"))
	if body_hint_label:
		if left > 0:
			body_hint_label.text = "清场搜尸：点尸体继续缴获（剩余 %d）" % left
		else:
			body_hint_label.text = "尸体已搜完 · 补给将带入下一夜"
	_push_map_snapshot()


func _roll_body_loot(_enemy_id: String) -> Dictionary:
	## Deterministic stub loot for next-night kit (no RNG).
	var n := next_night_loot.size()
	match n % 3:
		0:
			return {"kind": "ammo", "pool_id": "ammo_9mm", "rounds": 16, "label_zh": "9mm 弹药 ×16"}
		1:
			return {"kind": "ammo", "pool_id": "ammo_792", "rounds": 10, "label_zh": "7.92 弹药 ×10"}
		_:
			return {"kind": "codex", "item_id": "luger_codex", "label_zh": "图鉴：卢格手枪（收藏）"}


func _save_next_night_loot_stub() -> void:
	var f := FileAccess.open(NEXT_NIGHT_KIT_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"loot": next_night_loot}, "\t"))


func _load_next_night_loot_stub() -> void:
	next_night_loot.clear()
	if not FileAccess.file_exists(NEXT_NIGHT_KIT_PATH):
		return
	var f := FileAccess.open(NEXT_NIGHT_KIT_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var arr: Array = (parsed as Dictionary).get("loot", [])
	for item in arr:
		if typeof(item) == TYPE_DICTIONARY:
			next_night_loot.append(item)


func _push_map_snapshot() -> void:
	var ops: Array = []
	var enemies: Array = []
	var sentries: Array = level.get("sentries", [])
	var patrols: Array = level.get("patrols", [])
	var mines: Array = plan.get("mines", []) if plan else []
	var grenades: Array = plan.get("grenades", []) if plan else []
	var trig: Dictionary = plan.get("trigger", {}) if plan else {}
	var al := "quiet"
	var ph := "setup"
	var supply_states: Dictionary = {}
	if ui_phase == UiPhase.SCOUT and scout != null:
		ops = scout.operators
		sentries = scout.sentries
		patrols = scout.patrols
		al = scout.alert
		ph = "scout"
		supply_states = scout.supply_draw_states()
	elif sim != null:
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
		ops = plan.get("operators", []) if plan else []
		# After scout: show revealed/opened crates during setup.
		if scout != null:
			supply_states = scout.supply_draw_states()
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
		"highlight_high_slots": ui_phase == UiPhase.SETUP,
		"op_display_names": op_display_names,
		"supply_states": supply_states,
		"searched_bodies": searched_bodies,
		"body_search_enabled": body_search_enabled and ui_phase == UiPhase.RESULT,
		"scout_preview_path": preview_path if ui_phase == UiPhase.SCOUT else [],
		"scout_danger_cells": scout_danger_cells if ui_phase == UiPhase.SCOUT else [],
		"scout_dest_flag": scout_dest_flag if ui_phase == UiPhase.SCOUT else Vector2i(-1, -1),
		"scout_confirm_cell": pending_scout_goal if ui_phase == UiPhase.SCOUT else Vector2i(-1, -1),
		"scout_preview_cost_s": scout_preview_cost_s if ui_phase == UiPhase.SCOUT else 0.0,
	})


func _clear_dest_flag_if_arrived() -> void:
	if scout == null or scout_dest_flag.x < 0 or selected_op_id == "":
		return
	for op in scout.operators:
		if str(op["id"]) != selected_op_id:
			continue
		var path: Array = op.get("path", [])
		if path.is_empty() and int(op["x"]) == scout_dest_flag.x and int(op["y"]) == scout_dest_flag.y:
			scout_dest_flag = Vector2i(-1, -1)
		return


func _auto_run_plan_b() -> void:
	await _auto_run_plan("B")


func _auto_run_plan_a() -> void:
	await _auto_run_plan("A")


func _auto_run_plan(which: String) -> void:
	## Headless: scout → setup → load A|B → wait/result. Captures review_a / review_b.
	for _i in range(8):
		await get_tree().process_frame
	map_view._fit_cell_px()
	if ui_phase != UiPhase.SCOUT or scout == null:
		_start_scout_phase()
	_push_map_snapshot()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("scout_start")
	# Open SE crate (15,4) then approach hidden (21,5).
	var oid := str(scout.operators[0]["id"])
	selected_op_id = oid
	scout.request_move(oid, Vector2i(15, 4))
	var guard := 0
	while not scout.is_finished() and guard < 8000:
		scout.advance_one_tick()
		guard += 1
		var s_se := scout._supply_by_id("crate_se")
		if bool(s_se.get("opened", false)):
			break
	gathered_kit = scout.kit_snapshot()
	_push_map_snapshot()
	_refresh_scout_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("crate_opened")
	scout.request_move(oid, Vector2i(21, 5))
	guard = 0
	while not scout.is_finished() and guard < 8000:
		scout.advance_one_tick()
		guard += 1
		var s_h := scout._supply_by_id("hidden_H")
		if bool(s_h.get("revealed", false)) and bool(s_h.get("opened", false)):
			break
	gathered_kit = scout.kit_snapshot()
	_push_map_snapshot()
	_refresh_scout_hud()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("hidden_found")
	begin_setup_from_scout()
	_push_map_snapshot()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("setup_mg42")
	_try_capture("blank")
	if plan.get("operators", []):
		var oid0 := str(plan["operators"][0]["id"])
		scripted_place_operator(oid0, 5, 9, 0.0)
	_push_map_snapshot()
	await get_tree().process_frame
	_try_capture("mid")
	_load_preset(which)
	_push_map_snapshot()
	await get_tree().process_frame
	_try_capture("setup")
	_start_wait()
	paused = true ## prevent _process double-ticking during auto
	var captured_trigger := false
	var captured_midfight := false
	var captured_reaim := false
	var captured_cover_fire := false
	var captured_wounded := false
	## Capture-only helper; never arm during normal AUTO tests (require CAPTURE dir).
	var force_leak := (
		_capture_path != ""
		and str(OS.get_environment("AMBUSH_GREYBOX_FORCE_LEAK")).to_lower() in ["1", "true"]
	)
	var leak_armed := false
	while sim != null and not sim.is_finished():
		sim.advance_one_tick()
		# PLAY-6 capture helper: after detonate, mute friendlies and leave one survivor to flee/leak.
		if force_leak and sim.detonate_tick >= 0 and not leak_armed and sim.tick >= sim.detonate_tick + 2:
			sim.skip_fire = true
			sim.skip_enemy_fire = true
			var kept := ""
			for e in sim.enemies:
				if e["alive"] and e["entered"] and not e["escaped"]:
					if kept == "":
						kept = str(e["id"])
					else:
						sim._kill_enemy(e, "capture", "capture")
			leak_armed = true
		_consume_sim_log()
		_tick_wait_audio()
		if map_view and map_view.combat_fx:
			map_view.combat_fx.advance(SimConstants.DT_S)
		if sim.tick == 140:
			_push_map_snapshot()
			await get_tree().process_frame
			await get_tree().process_frame
			_try_capture("wait")
		# PLAY-4 mid-wait re-aim shot only when capturing (must not alter AUTO golden fire counts).
		if (
			not captured_reaim
			and _capture_path != ""
			and which == "A"
			and sim.tick == 200
			and sim.detonate_tick < 0
		):
			var kar_id := _op_id_for_weapon("kar98k")
			if kar_id == "" and sim.operators:
				kar_id = str(sim.operators[0]["id"])
			if kar_id != "":
				selected_op_id = kar_id
				var cur := float(_sim_op(kar_id).get("facing_deg", 0.0))
				sim.request_operator_facing(kar_id, cur + 90.0)
				_push_map_snapshot()
				await get_tree().process_frame
				await get_tree().process_frame
				_try_capture("reaim")
				captured_reaim = true
		if not captured_trigger and sim.detonate_tick >= 0 and sim.tick >= sim.detonate_tick + 2:
			_push_map_snapshot()
			await get_tree().process_frame
			await get_tree().process_frame
			_try_capture("trigger")
			captured_trigger = true
		if (
			not captured_midfight
			and captured_trigger
			and map_view.combat_fx != null
			and map_view.combat_fx.kills_seen >= 2
			and map_view.combat_fx.living_enemy_count(sim.enemies) > 0
		):
			_push_map_snapshot()
			await get_tree().process_frame
			await get_tree().process_frame
			_try_capture("midfight")
			captured_midfight = true
		# PLAY-6 evidence shots: enemy in cover returning fire; wounded operator.
		if not captured_cover_fire and sim.detonate_tick >= 0:
			var cover_actor := ""
			for e in sim.enemies:
				if bool(e.get("in_cover", false)) and bool(e.get("alive", false)):
					cover_actor = str(e.get("id", ""))
					break
			var saw_cover_shot := false
			if cover_actor != "":
				for ev in sim.log.events:
					if str(ev.get("type", "")) == "enemy_fire" and str(ev.get("actor", "")) == cover_actor:
						saw_cover_shot = true
						break
			# Fallback: any living cover-seeker that has fired (plan A rarely reaches full in_cover).
			if cover_actor == "" or not saw_cover_shot:
				for e in sim.enemies:
					if not bool(e.get("alive", false)) or str(e.get("mode", "")) != "cover":
						continue
					for ev in sim.log.events:
						if str(ev.get("type", "")) == "enemy_fire" and str(ev.get("actor", "")) == str(e.get("id", "")):
							cover_actor = str(e.get("id", ""))
							saw_cover_shot = true
							break
					if saw_cover_shot:
						break
			if cover_actor != "" and saw_cover_shot:
				_push_map_snapshot()
				await get_tree().process_frame
				await get_tree().process_frame
				_try_capture("cover_fire")
				captured_cover_fire = true
		if not captured_wounded and not (sim.wounded_ids as Array).is_empty():
			# Hold a beat so the 负伤 ring is on-screen with active tracers.
			for _w in range(3):
				if sim.is_finished():
					break
				sim.advance_one_tick()
				_consume_sim_log()
				if map_view and map_view.combat_fx:
					map_view.combat_fx.advance(SimConstants.DT_S)
			_push_map_snapshot()
			await get_tree().process_frame
			await get_tree().process_frame
			_try_capture("wounded")
			captured_wounded = true
	_consume_sim_log()
	_push_map_snapshot()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("bodies")
	_show_result()
	# Demo one body search so hint updates before review shot.
	if body_search_enabled and map_view and map_view.combat_fx:
		for bid in map_view.combat_fx.bodies.keys():
			_search_body(str(bid))
			break
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("result")
	_try_capture("review_a" if which == "A" else "review_b")
	# PLAY-6: if this run had a leak, also tag a leak review shot.
	if not (last_summary.get("escapes", []) as Array).is_empty():
		_try_capture("leak_review")
	var fxst := combat_fx_stats()
	var log_fires := 0
	if sim != null:
		for ev in sim.log.events:
			if str(ev.get("type", "")) == "fire":
				log_fires += 1
	print(
		"GREYBOX_AUTO_DONE plan=", which,
		" detonate_tick=", last_summary.get("detonate_tick"),
		" standard_ambush=", last_summary.get("standard_ambush"),
		" outcome=", last_summary.get("outcome"),
		" grade=", last_review.get("grade", ""),
		" outcome_zh=", last_review.get("outcome_zh", ""),
		" has_mg42=", is_mg42_unlocked(),
		" fx_fires=", fxst.get("fires", 0),
		" fx_fires_ctrl=", fxst.get("fires_controller", _fx_fires_total),
		" log_fires=", log_fires,
		" fx_kills=", fxst.get("kills", 0),
		" fx_bodies=", fxst.get("bodies", 0),
		" loot_n=", next_night_loot.size()
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
