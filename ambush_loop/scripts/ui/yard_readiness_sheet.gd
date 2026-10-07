extends Control
signal start_requested
signal dismissed
var text_label: Label
var candidate: CheckButton
var game: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.05, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 0)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 18)
	column.add_child(text_label)
	candidate = CheckButton.new()
	candidate.text = "下次院子默认 3D（候选，手机待验）"
	candidate.toggled.connect(func(value: bool) -> void:
		if game != null: game._gs().set_yard_3d_candidate(value))
	column.add_child(candidate)
	var row := HBoxContainer.new()
	column.add_child(row)
	var back := Button.new()
	back.text = "返回布置"
	back.custom_minimum_size = Vector2(190, 56)
	back.pressed.connect(func() -> void: visible = false; dismissed.emit())
	row.add_child(back)
	var start := Button.new()
	start.text = "开始交战"
	start.custom_minimum_size = Vector2(190, 56)
	start.pressed.connect(func() -> void: visible = false; start_requested.emit())
	row.add_child(start)
	visible = false

func present(host: Node, text: String) -> void:
	game = host
	text_label.text = text
	candidate.set_pressed_no_signal(host._gs().yard_3d_candidate)
	visible = true

func _gui_input(_event: InputEvent) -> void:
	accept_event()
