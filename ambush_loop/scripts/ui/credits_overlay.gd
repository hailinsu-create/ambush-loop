class_name CreditsOverlay
extends CanvasLayer

signal finished

## Smoke reads this exact chain from source. Keep in-file even if body is generated.
const CHAIN := "院子 / 仓道 / 泵站 / 信号楼 / 油库 / 电台"

var _open: bool = false
var _panel: PanelContainer


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.016, 0.014, 0.010, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.name = "CreditsPanel"
	_panel.theme = NightOps.theme()
	add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var word := Label.new()
	word.name = "Title"
	word.text = "AMBUSH LOOP"
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	word.add_theme_font_size_override("font_size", 28)
	word.add_theme_color_override("font_color", NightOps.OLIVE_HI)
	box.add_child(word)
	# Keep the heading and exit reachable; only the full recap scrolls.
	var scroll := ScrollContainer.new()
	scroll.name = "CreditsScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	var tag := Label.new()
	tag.text = "北区补给链 · 第三夜 · 灯塔停转 · 点选单兵 · 岗哨黄锥"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_color_override("font_color", NightOps.OLIVE_DIM)
	content.add_child(tag)
	var rail := HBoxContainer.new()
	rail.name = "NightRail"
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_theme_constant_override("separation", 8)
	content.add_child(rail)
	for def in LevelDef.catalog():
		var chip := Label.new()
		chip.text = LevelDef.mood_tag(def.level_id)
		chip.add_theme_font_size_override("font_size", 13)
		chip.add_theme_color_override("font_color", LevelDef.signature_color(def.level_id))
		rail.add_child(chip)
	var body := Label.new()
	body.name = "Body"
	body.text = LevelDef.campaign_recap_body()
	if body.text.find(CHAIN) < 0:
		body.text = "%s 全部封锁。\n%s" % [CHAIN, body.text]
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 15)
	content.add_child(body)
	var btn := Button.new()
	btn.name = "ReturnButton"
	btn.text = "返回标题"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.pressed.connect(_on_done)
	box.add_child(btn)
	get_viewport().size_changed.connect(_layout_for_surface)
	_layout_for_surface()


func _layout_for_surface() -> void:
	var usable := get_viewport().get_visible_rect().size
	var half := Vector2(minf(600.0, usable.x - 24.0), minf(496.0, usable.y - 24.0)) * 0.5
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -half.x
	_panel.offset_right = half.x
	_panel.offset_top = -half.y
	_panel.offset_bottom = half.y


func is_open() -> bool:
	return _open


func present() -> void:
	_layout_for_surface()
	_open = true
	visible = true


func _on_done() -> void:
	_open = false
	visible = false
	finished.emit()
