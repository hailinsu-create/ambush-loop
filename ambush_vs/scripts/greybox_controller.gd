extends Control
class_name GreyboxController

## Playable yard greybox: SETUP → WAIT → RESULT. View is thin; sim owns outcomes.
## PLAY-1 / VS-UX1: blank board start — player places ops, weapons, mines, trigger.

const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const SimConstants := preload("res://sim/constants.gd")
const SimGeom := preload("res://sim/geom.gd")
const GreyboxMapScript := preload("res://view/greybox_map.gd")
const G2AssetsScript := preload("res://view/g2_assets.gd")
const G2SfxPlayerScript := preload("res://view/g2_sfx_player.gd")
const G3AssetsScript := preload("res://view/g3_assets.gd")

enum UiPhase { SETUP, WAIT, RESULT }
enum PlaceMode { NONE, OP, MINE, TRIGGER_A, TRIGGER_B }

const KIT_OPERATOR_WEAPONS := ["kar98k", "mp40", "grenade"] ## assignable from loadout_start
const LOCKED_WEAPONS := ["mg42"] ## need hidden cache (scout) — greyed in HUD
const WEAPON_LABEL_ZH := {
	"kar98k": "Kar98k",
	"mp40": "MP40",
	"mg42": "MG42",
	"grenade": "手雷",
	"mine": "地雷",
}

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
var use_g2_art: bool = false
var art_mode_name: String = "G3"
var _last_alert: String = "quiet"
var _detonate_sfx_played: bool = false
var g2_assets = null
var sfx = null
var g3_assets = null

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

	btn_example.pressed.connect(func(): _ui_tap(); _toggle_example_plans())
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
		btn_g2_art.pressed.connect(_cycle_art)
		_refresh_art_button()

	_fill_trigger_options()
	_set_example_plans_visible(false)
	_init_blank_plan()
	_build_op_cards()
	_build_kit_row()
	_set_ui_phase(UiPhase.SETUP)
	_refresh_start_gate()

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
	if _headless_auto:
		call_deferred("_auto_run_plan_a")


func _apply_cjk_font() -> void:
	var font_res = load("res://ui/fonts/web_ui_font.tres")
	if font_res == null:
		return
	for n in [label_phase, label_info, label_alert, result_label, btn_example, btn_plan_a, btn_plan_b, btn_start, label_start_reason, btn_preview, btn_g2_art, btn_pause, btn_speed, btn_detonate, btn_restart, btn_restart_wait, trigger_option]:
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
	## Weapons available from loadout_start (never includes MG42).
	var out: Array = []
	for w in level.get("loadout_start", {}).get("weapons", []):
		var wid := str(w.get("weapon_id", ""))
		if wid.is_empty() or wid in LOCKED_WEAPONS:
			continue
		out.append(wid)
	return out


func is_mg42_in_starting_kit() -> bool:
	for wid in starting_kit_weapon_ids():
		if wid == "mg42":
			return true
	for w in level.get("loadout_start", {}).get("weapons", []):
		if str(w.get("weapon_id", "")) == "mg42":
			return true
	return false


func _kit_counts_from_level() -> Dictionary:
	var counts: Dictionary = {}
	for w in level.get("loadout_start", {}).get("weapons", []):
		var wid := str(w.get("weapon_id", ""))
		if wid.is_empty():
			continue
		counts[wid] = int(w.get("count", 1))
	return counts


func _init_blank_plan() -> void:
	## Blank board: squad at yard entry; no preset A/B coordinates.
	op_display_names.clear()
	op_placed.clear()
	kit_weapon_counts = _kit_counts_from_level()
	var ops: Array = []
	var defaults := ["kar98k", "mp40", "grenade"]
	var i := 0
	for entry in level.get("squad_insertion", []):
		var oid := str(entry.get("id", "op_%d" % (i + 1)))
		var dname := str(entry.get("display_name", "%d号" % (i + 1)))
		var wid: String = str(defaults[i]) if i < defaults.size() else "kar98k"
		# Prefer a kit weapon that still has stock.
		if int(kit_weapon_counts.get(wid, 0)) <= 0:
			for cand in KIT_OPERATOR_WEAPONS:
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
		op_placed[oid] = false
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
	_sync_trigger_option_from_plan()
	_push_map_snapshot()
	label_info.text = "从南门入场位开始 · 点队员卡选人，再点合法格放置；拖拽设朝向"
	_refresh_op_cards()
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
	title.add_theme_font_size_override("font_size", 14)
	if font_res:
		title.add_theme_font_override("font", font_res)
	kit_row.add_child(title)
	for wid in ["kar98k", "mp40", "grenade", "mine", "mg42"]:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(48, 64)
		var tr := TextureRect.new()
		tr.custom_minimum_size = Vector2(40, 40)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if g3_assets and g3_assets.weapon_icons.has(wid):
			tr.texture = g3_assets.weapon_icons[wid]
		var lab := Label.new()
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", 11)
		if font_res:
			lab.add_theme_font_override("font", font_res)
		if wid in LOCKED_WEAPONS:
			tr.modulate = Color(0.45, 0.45, 0.45, 0.85)
			lab.text = "MG42"
			lab.modulate = Color(0.55, 0.55, 0.55)
			box.tooltip_text = "需在隐蔽补给点找到"
			tr.tooltip_text = "需在隐蔽补给点找到"
			lab.tooltip_text = "需在隐蔽补给点找到"
		else:
			lab.text = str(WEAPON_LABEL_ZH.get(wid, wid))
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
		head.custom_minimum_size = Vector2(0, 36)
		head.add_theme_font_size_override("font_size", 15)
		if font_res:
			head.add_theme_font_override("font", font_res)
		head.pressed.connect(_on_op_card_pressed.bind(oid))
		card.add_child(head)
		var wrow := HBoxContainer.new()
		wrow.name = "Weapons"
		wrow.add_theme_constant_override("separation", 4)
		for wid in KIT_OPERATOR_WEAPONS:
			var wb := Button.new()
			wb.name = "W_%s" % wid
			wb.text = str(WEAPON_LABEL_ZH.get(wid, wid))
			wb.custom_minimum_size = Vector2(0, 32)
			wb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			wb.add_theme_font_size_override("font_size", 12)
			if font_res:
				wb.add_theme_font_override("font", font_res)
			wb.pressed.connect(_on_op_weapon_picked.bind(oid, wid))
			wrow.add_child(wb)
		var mg := Button.new()
		mg.name = "W_mg42"
		mg.text = "MG42"
		mg.disabled = true
		mg.tooltip_text = "需在隐蔽补给点找到"
		mg.custom_minimum_size = Vector2(0, 32)
		mg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mg.add_theme_font_size_override("font_size", 12)
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
			head.text = "%s%s %s · %s" % [sel, mark, dname, wlab]
		var wrow := card.get_node_or_null("Weapons")
		if wrow:
			for wid in KIT_OPERATOR_WEAPONS:
				var wb: Button = wrow.get_node_or_null("W_%s" % wid)
				if wb == null:
					continue
				var equipped: bool = str(op.get("weapon_id", "")) == str(wid)
				wb.disabled = false
				if equipped:
					wb.modulate = Color(1.0, 0.92, 0.55)
				else:
					wb.modulate = Color.WHITE


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
	if wid in LOCKED_WEAPONS:
		label_info.text = "需在隐蔽补给点找到"
		return
	if wid not in starting_kit_weapon_ids() and wid != "grenade":
		# mine is kit but not an operator weapon in blank setup
		if wid == "mine":
			label_info.text = "地雷请用地图放置（起爆条件选「地雷」）"
			return
	# Enforce kit stock: count how many ops already hold this weapon.
	var max_count := int(_kit_counts_from_level().get(wid, 0))
	if max_count <= 0:
		label_info.text = "起始套件中没有该武器"
		return
	var held := 0
	for op in plan.get("operators", []):
		if str(op["id"]) != oid and str(op.get("weapon_id", "")) == wid:
			held += 1
	if held >= max_count:
		label_info.text = "起始套件中该武器已分完"
		return
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
	if ui_phase != UiPhase.SETUP:
		return
	var t := str(trigger_option.get_item_metadata(idx))
	match t:
		"see_first_enemy":
			var bind := selected_op_id if selected_op_id else _op_id_for_weapon("kar98k")
			if bind == "" and plan.get("operators", []):
				bind = str(plan["operators"][0]["id"])
			plan["trigger"] = {"type": "see_first_enemy", "bind": bind}
			place_mode = PlaceMode.OP
			label_info.text = "起爆：见首敌 · 绑定 %s" % op_display_names.get(bind, bind)
		"mine_detonate":
			plan["mines"] = []
			plan["trigger"] = {"type": "mine_detonate", "bind": ""}
			place_mode = PlaceMode.MINE
			label_info.text = "起爆：地雷 · 请点地图放置地雷"
		"cross_marker":
			plan["trigger"] = {"type": "cross_marker", "bind": "marker_y7"}
			place_mode = PlaceMode.TRIGGER_A
			label_info.text = "起爆：越线标记 · 请点地图设起点"
		"manual":
			plan["trigger"] = {"type": "manual"}
			place_mode = PlaceMode.OP
			label_info.text = "起爆：手动"
	_push_map_snapshot()
	_refresh_start_gate()


func _set_ui_phase(p: UiPhase) -> void:
	ui_phase = p
	setup_panel.visible = p == UiPhase.SETUP
	wait_panel.visible = p == UiPhase.WAIT
	result_panel.visible = p == UiPhase.RESULT
	match p:
		UiPhase.SETUP:
			label_phase.text = "布阵"
		UiPhase.WAIT:
			label_phase.text = "等待"
		UiPhase.RESULT:
			label_phase.text = "结算"


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


func _refresh_start_gate() -> void:
	var reason := start_block_reason()
	if btn_start:
		btn_start.disabled = not reason.is_empty()
	if label_start_reason:
		label_start_reason.text = reason
		label_start_reason.visible = not reason.is_empty()


func _start_wait() -> void:
	var reason := start_block_reason()
	if not reason.is_empty():
		label_info.text = reason
		_refresh_start_gate()
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
	## Keep player's last plan (DESIGN_V2 §4.5); do not force preset A.
	sim = null
	last_summary = {}
	preview_cell = Vector2i(-1, -1)
	preview_seers = []
	place_mode = PlaceMode.OP
	_set_ui_phase(UiPhase.SETUP)
	_sync_trigger_option_from_plan()
	_build_op_cards()
	_push_map_snapshot()
	_refresh_start_gate()
	label_info.text = "已保留上一局计划 · 可继续微调"


func _toggle_preview_hint() -> void:
	label_info.text = "点地面：看谁能看见这里（预览＝模拟）"


func _on_cell_tapped(cell: Vector2i) -> void:
	if ui_phase == UiPhase.SETUP:
		preview_cell = cell
		preview_seers = _preview_who_sees(cell)
		match place_mode:
			PlaceMode.MINE:
				_place_mine_at(cell)
			PlaceMode.TRIGGER_A:
				_place_trigger_point(cell, true)
			PlaceMode.TRIGGER_B:
				_place_trigger_point(cell, false)
			_:
				if selected_op_id != "" and grid.walkable(cell.x, cell.y):
					_move_selected_op(cell)
				else:
					label_info.text = "格 (%d,%d) · 可见观察者 %d" % [cell.x, cell.y, preview_seers.size()]
		_push_map_snapshot()
		_refresh_start_gate()
	elif ui_phase == UiPhase.WAIT and sim != null:
		preview_cell = cell
		preview_seers = sim.observers_seeing_cell(float(cell.x), float(cell.y), grid.tier_at(float(cell.x), float(cell.y)))
		label_info.text = "格 (%d,%d) · 可见 %d" % [cell.x, cell.y, preview_seers.size()]
		_push_map_snapshot()


func _place_mine_at(cell: Vector2i) -> void:
	if not grid.walkable(cell.x, cell.y):
		label_info.text = "此处不能放地雷"
		return
	var mid := "mine_%d_%d" % [cell.x, cell.y]
	plan["mines"] = [{"id": mid, "x": cell.x, "y": cell.y}]
	plan["trigger"] = {"type": "mine_detonate", "bind": mid}
	place_mode = PlaceMode.OP
	label_info.text = "地雷已放在 (%d,%d)" % [cell.x, cell.y]


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
	for op in plan.get("operators", []):
		if str(op["id"]) == selected_op_id:
			op["x"] = cell.x
			op["y"] = cell.y
			op["tier"] = grid.tier_at(float(cell.x), float(cell.y))
			op_placed[selected_op_id] = true
			var dname := str(op_display_names.get(selected_op_id, "队员"))
			var tier := str(op["tier"])
			label_info.text = "%s 已放置 (%d,%d)%s" % [
				dname, cell.x, cell.y, " · 高点" if tier == "high" else ""
			]
			_refresh_op_cards()
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
	place_mode = PlaceMode.OP
	var dname := str(op_display_names.get(op_id, "队员"))
	label_info.text = "选中 %s · 拖拽设朝向 · 点格放置" % dname
	_refresh_op_cards()
	_push_map_snapshot()


func scripted_place_operator(oid: String, x: int, y: int, facing_deg: float = 90.0) -> bool:
	## Test/helper: place one operator as a player would.
	if not grid.walkable(x, y):
		return false
	selected_op_id = oid
	_move_selected_op(Vector2i(x, y))
	for op in plan.get("operators", []):
		if str(op["id"]) == oid:
			op["facing_deg"] = facing_deg
			break
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
		"highlight_high_slots": ui_phase == UiPhase.SETUP,
		"op_display_names": op_display_names,
	})


func _auto_run_plan_a() -> void:
	## Headless: blank → mid placement shot → load A → wait/result (golden path).
	for _i in range(8):
		await get_tree().process_frame
	map_view._fit_cell_px()
	_push_map_snapshot()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("blank")
	# Mid-placement: move one op onto high ground (player-like), leave others at entry.
	if plan.get("operators", []):
		var oid0 := str(plan["operators"][0]["id"])
		scripted_place_operator(oid0, 5, 9, 0.0)
	_push_map_snapshot()
	await get_tree().process_frame
	await get_tree().process_frame
	_try_capture("mid")
	_load_preset("A")
	_push_map_snapshot()
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
