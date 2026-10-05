extends SceneTree

const Guard := preload("res://scripts/test_storage_guard.gd")
var failures: Array[String] = []
var portrait_picks: int = 0

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _run() -> void:
	create_timer(120.0).timeout.connect(func(): quit(3))
	for scene_path in ["res://scenes/main.tscn", "res://scenes/presentation/yard_i0_3d.tscn"]:
		change_scene_to_file(scene_path)
		await _frames(14)
		var main = current_scene
		for _page in 4:
			if main.tutorial_overlay != null and main.tutorial_overlay.is_open():
				main.tutorial_overlay._on_next()
		root.get_node("GameSettings").set_force_touch_hud(true)
		main._ensure_touch_hud()
		main.set_process(false)
		main.c2.portraits.picked.connect(func(_idx: int): portrait_picks += 1)
		for op in main.operators:
			op.set_process(false)
		for size in [Vector2i(1280, 720), Vector2i(960, 540)]:
			root.content_scale_size = size
			root.size = size
			await _frames(4)
			main._start_setup(false, false)
			for op in main.operators:
				op.set_process(false)
			main._update_hud()
			await _frames(8)
			var hud = main.touch_hud
			_expect(Vector2i(root.get_visible_rect().size) == size, "REAL_VIEWPORT_%s" % size)
			var rects: Array[Rect2] = []
			for card in main.c2.portraits._cards:
				_check_rect(card, size, rects)
			for cmd in hud.SETUP_RESIDENT:
				_check_rect(hud._btns[cmd], size, rects)
			await _tap(Vector2(345, size.y - 24))
			_expect(not main.touch_intent_pending() and main._touches.is_empty(), "OPAQUE_RAIL_BLANK_OWNS_TOUCH")
			main.cancel_touch_intent()
			for i in 3:
				var picks_before := portrait_picks
				await _tap(main.c2.portraits.card_global_rect(i).get_center())
				for pressed in [true, false]:
					var mouse := InputEventMouseButton.new()
					mouse.device = -1
					mouse.button_index = MOUSE_BUTTON_LEFT
					mouse.position = main.c2.portraits.card_global_rect(i).get_center()
					mouse.global_position = mouse.position
					mouse.pressed = pressed
					root.push_input(mouse, true)
				_expect(portrait_picks == picks_before + 1, "PORTRAIT_TOUCH_EMULATION_ONCE")
				_expect(main.selected == main.operators[i], "PORTRAIT_SELECT_%s" % i)
				_expect(not main.touch_intent_pending() and main._touches.is_empty(), "PORTRAIT_UI_ONLY")
			var stance := int(main.selected.stance)
			await _tap(hud._btns.bag.get_global_rect().get_center())
			_expect(main.backpack_panel.is_open() and not main.touch_intent_pending(), "BAG_UI_ONLY")
			main.backpack_panel.dismiss()
			await _frames(2)
			await _tap(hud._btns.crouch.get_global_rect().get_center())
			_expect(int(main.selected.stance) != stance, "CROUCH_ACTION")
			_expect(not main.touch_intent_pending() and main._touches.is_empty(), "CROUCH_UI_ONLY")
			for cmd in ["rotate_ccw", "rotate_cw"]:
				var facing := float(main.selected.facing_deg)
				await _tap(hud._btns[cmd].get_global_rect().get_center())
				_expect(not is_equal_approx(float(main.selected.facing_deg), facing), "ROTATE_ACTION_" + cmd)
				_expect(not main.touch_intent_pending() and main._touches.is_empty(), "ROTATE_UI_ONLY")
			# A real local move preview, followed by panel label and cancel touches.
			var target: Vector2 = main.grid.cell_to_world_center(Vector2i(10, 16))
			main._begin_touch_intent(target)
			await _frames(4)
			_expect(main.touch_intent_pending(), "PENDING_FIXTURE")
			_check_rect(hud._btns.world_confirm, size, rects)
			_check_rect(hud._btns.world_cancel, size, rects)
			var intent: Dictionary = main._touch_intent.duplicate(true)
			await _tap(hud._world_intent_label.get_global_rect().get_center())
			_expect(main._touch_intent == intent, "PANEL_LABEL_NO_PASSTHROUGH")
			await _tap(hud._btns.world_cancel.get_global_rect().get_center())
			_expect(not main.touch_intent_pending() and not main.selected.is_moving(), "CANCEL_UI_ONLY")
			main._begin_touch_intent(target)
			await _frames(4)
			await _tap(hud._btns.world_confirm.get_global_rect().get_center())
			_expect(not main.touch_intent_pending() and main.selected.is_moving(), "CONFIRM_EXISTING_PATH")
			main.selected.stop_move()
			# Phase refresh must remove the entire old row from hit testing.
			await _tap(hud._btns.alarm.get_global_rect().get_center())
			_expect(main.phase == main.Phase.WATCHING and main._touches.is_empty(), "ALARM_EXISTING_COMMAND_ONLY")
			await _frames(6)
			rects.clear()
			for cmd in hud.SETUP_RESIDENT:
				_expect(not hud._btns[cmd].is_visible_in_tree(), "HIDDEN_SETUP_" + cmd)
			for cmd in hud.WATCH_RESIDENT:
				_check_rect(hud._btns[cmd], size, rects)
			var paused := bool(main.sim.paused)
			await _tap(hud._btns.pause.get_global_rect().get_center())
			_expect(bool(main.sim.paused) != paused and main._touches.is_empty(), "WATCH_PAUSE_UI_ONLY")
			var speed := float(main.sim.speed)
			await _tap(hud._btns.speed.get_global_rect().get_center())
			_expect(float(main.sim.speed) != speed and main._touches.is_empty(), "WATCH_SPEED_UI_ONLY")
			print("M2_T3_LAYOUT_CHECK scene=%s viewport=%s" % [scene_path, size])
	if failures.is_empty():
		print("M2_TOUCH_TARGET_GATE_OK sizes=2 scenes=2 real_rects=1 ui_ownership=1")
		quit(0)
	else:
		push_error("M2_T3_RED " + ";".join(failures))
		quit(1)

func _check_rect(button: Control, viewport_size: Vector2i, prior: Array[Rect2]) -> void:
	var rect := button.get_global_rect()
	print("M2_T3_RECT name=%s viewport=%s rect=%s" % [button.name, viewport_size, rect])
	_expect(button.is_visible_in_tree(), "VISIBLE_" + button.name)
	_expect(rect.size.x >= 48 and rect.size.y >= 48, "MINIMUM_" + button.name)
	_expect(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(rect), "BOUNDS_" + button.name)
	for other in prior:
		_expect(not rect.intersects(other), "OVERLAP_" + button.name)
	prior.append(rect)

func _tap(position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.pressed = pressed
		event.position = position
		root.push_input(event, true)
	await _frames(8)

func _frames(count: int) -> void:
	for _frame in count:
		await process_frame

func _expect(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
