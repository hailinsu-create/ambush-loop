extends Control

## Captures only gestures that BEGIN on this handle. World/multi-touch stays host-owned.
var presenter: Node
var pointer := -1
var mouse_owned := false
var actor_instance := -1
var captured_phase := -1
var captured_tool := -1
var title: Label

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_capture()

func _ready() -> void:
	custom_minimum_size = Vector2(112, 56)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	title = Label.new()
	title.text = "↗ 拖动朝向"
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	queue_redraw()

func _draw() -> void:
	draw_style_box(_style(), Rect2(Vector2.ZERO, size))

func _style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("164740") if pointer >= 0 else Color("14242a")
	style.border_color = Color("8ce3d7")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style

func _process(_delta: float) -> void:
	if presenter == null or presenter.host == null: visible = false; return
	var game: Node = presenter.host
	var op: Node = game.selected
	var allowed: bool = presenter.active and game._is_command_phase() and not game._modal_blocks_input() and op != null and op.alive and op.visible and not op.locked and not game.touch_intent_pending()
	if pointer >= 0 and (not allowed or game._facing_touch != pointer or op.get_instance_id() != actor_instance or int(game.phase) != captured_phase or int(game.tool) != captured_tool):
		cancel_capture()
	visible = allowed
	if not allowed: return
	# Do not chase the finger or change GUI ownership while a pointer is down.
	if pointer >= 0: return
	var anchor: Vector2 = presenter.screen_position_for_logic(op.global_position)
	visible = anchor.is_finite()
	if visible:
		var viewport_size := get_viewport().get_visible_rect().size
		var insets := Vector4(16, 76, 16, 150)
		if game.touch_hud != null:
			var safe: Vector4 = game.touch_hud._intent_safe_insets
			insets = Vector4(maxf(insets.x, safe.x), maxf(insets.y, safe.y), maxf(insets.z, safe.z), maxf(insets.w, safe.w))
		var layout := preload("res://scripts/ui/touch_intent_layout.gd").choose_position(anchor, viewport_size, size, insets, presenter.intent_ui_obstacles(), game._gs().left_handed)
		position = layout.position

func cancel_capture() -> void:
	if pointer >= 0 and presenter != null and presenter.host != null:
		var game: Node = presenter.host
		game._yard_facing_preview.clear()
		game._touches.erase(pointer)
		game._canceled_touch_indices[pointer] = true
		if game._facing_touch == pointer: game._facing_touch = -1
	pointer = -1
	mouse_owned = false
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if presenter == null or presenter.host == null: return
	var game: Node = presenter.host
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		event = event.duplicate()
		event.position = get_global_transform_with_canvas() * event.position
	if event is InputEventScreenTouch:
		if event.pressed:
			if pointer >= 0: cancel_capture(); accept_event(); return
			if game.begin_yard_facing_handle(event.index, event.position):
				pointer = event.index
				actor_instance = game.selected.get_instance_id()
				captured_phase = int(game.phase)
				captured_tool = int(game.tool)
		elif event.index == pointer:
			game._handle_touch_gestures(event)
			pointer = -1
			mouse_owned = false
		accept_event()
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == pointer:
		game._handle_touch_gestures(event)
		accept_event()
	elif event is InputEventMouse and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			var touch := InputEventScreenTouch.new()
			touch.index = 990
			touch.position = get_local_mouse_position()
			touch.pressed = event.pressed
			_gui_input(touch)
			mouse_owned = event.pressed and pointer >= 0
		elif event is InputEventMouseMotion and mouse_owned and pointer >= 0:
			var drag := InputEventScreenDrag.new()
			drag.index = pointer
			drag.position = get_global_mouse_position()
			game._handle_touch_gestures(drag)
		accept_event()
