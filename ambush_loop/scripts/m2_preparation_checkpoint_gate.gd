extends "res://scripts/m2_yard_supply_gate.gd"

func _run() -> void:
	create_timer(180.0).timeout.connect(func(): quit(3))
	var main = await _open_yard("CHECKPOINT")
	if main == null:
		_finish_failed()
		return
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await _frames(4)
	_expect(main.has_method("preparation_checkpoint_available"), "M2_D1_CHECKPOINT_API")
	if not failures.is_empty():
		_finish_failed()
		return
	if not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	var before: Array = _rounds(main)
	var selected_id: int = main.selected.op_id
	var positions: Array = []
	var packs: Array = []
	var pools: Array = []
	var faces: Array = []
	for op in main.operators:
		positions.append(op.global_position)
		packs.append(op.pack.slots.duplicate(true))
		pools.append(op.ammo_pool.duplicate(true))
		faces.append(op.facing_deg)
	main.raid_force_alarm()
	_expect(main.preparation_checkpoint_available(), "M2_D1_CAPTURE_AT_ALARM")
	for repeat in 10:
		main.operators[0].ammo = 0
		main._on_abort_pressed()
		var begin := Time.get_ticks_msec()
		main._on_continue_pressed()
		var elapsed := Time.get_ticks_msec() - begin
		_expect(elapsed < 5000, "M2_D1_RESTORE_UNDER_FIVE_SECONDS")
		_expect(main.phase == main.Phase.SETUP and _rounds(main) == before, "M2_D1_EXACT_INVENTORY_NO_ADDITION")
		_expect(main.selected.op_id == selected_id and main.raid_stashes.size() == 1, "M2_D1_SELECTED_UNSEARCHED_ONLY")
		_expect(main.enemies.is_empty() and main.raid_grenades.is_empty() and main.battle_log.events.is_empty(), "M2_D1_NO_BATTLE_STATE_LEAK")
		for i in 3:
			var op = main.operators[i]
			_expect(op.global_position == positions[i] and not op.locked, "M2_D1_POSITION_UNLOCKED")
			_expect(op.pack.slots == packs[i] and op.ammo_pool == pools[i] and op.facing_deg == faces[i], "M2_D1_PACK_POOL_FACING_EXACT")
		print("M2_D1_RESTORE repeat=%d elapsed_msec=%d rounds=%s" % [repeat, elapsed, _rounds(main)])
		await _frames(2)
		main.raid_force_alarm()
	main._on_abort_pressed()
	main.level.waves[0][0].delay += 0.01
	_expect(not main.preparation_checkpoint_available() and not main.preparation_checkpoint.restore(main), "M2_D1_CHANGED_RULES_REJECTED_WITHOUT_MUTATION")
	main.level.waves[0][0].delay -= 0.01
	var gs = root.get_node_or_null("GameSettings")
	if gs: gs.force_touch_hud = true
	main._ensure_touch_hud()
	main._update_hud()
	await _frames(6)
	var restart_rect: Rect2 = main.restart_preparation_button.get_global_rect()
	print("M2_D1_RESTART_RECT rect=%s viewport=%s panel=%s" % [restart_rect, root.get_visible_rect(), main.result_panel.get_global_rect()])
	_expect(root.get_visible_rect().encloses(restart_rect), "M2_D1_RESTART_IN_VIEWPORT")
	_expect(main.restart_preparation_button.is_visible_in_tree() and restart_rect.size.y >= 48, "M2_D1_REAL_RESTART_TOUCH_TARGET")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = restart_rect.get_center()
	touch.pressed = true
	root.push_input(touch, true)
	touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = restart_rect.get_center()
	touch.pressed = false
	root.push_input(touch, true)
	await _frames(6)
	_expect(_inventory_empty(main) and main.raid_stashes.size() == 4 and not main.preparation_checkpoint_available(), "M2_D1_EXPLICIT_RESTART_BASELINE")
	if not await _acquire_weapons(main, "GROUND_CHECKPOINT"):
		_finish_failed()
		return
	var grenade = main.raid_stashes[0]
	await _walk_to_cell(main, main.operators[0], grenade.cell)
	main.selected = main.operators[0]
	main._try_pickup_near_selected()
	main.raid_advance_search(1.0)
	await _frames(2)
	var ground_cells := [Vector2i(15, 13), Vector2i(29, 15), Vector2i(12, 14)]
	var ground_faces := [180.0, 330.0, 0.0]
	for i in 3:
		var route: Dictionary = await _walk_to_cell(main, main.operators[i], ground_cells[i])
		_expect(bool(route.get("ok", false)) and not bool(route.get("used_ramp", false)), "M2_D1_REAL_GROUND_DEPLOYMENT")
		main.operators[i].set_facing(ground_faces[i])
	main.selected = main.operators[0]
	var mark: Vector2 = main.grid.cell_to_world_center(Vector2i(13, 11))
	main._place_nade_mark(mark)
	for repeat in 10:
		main.raid_force_alarm()
		for tick in 400:
			if main.operators[0].grenades == 0: break
			main._sim_tick()
		_expect(main.operators[0].grenades == 0, "M2_D1_ACTUAL_BATTLE_CONSUMES_GRENADE")
		main._on_abort_pressed()
		if repeat == 9:
			await _frames(6)
			var button_rect: Rect2 = main.continue_button.get_global_rect()
			_expect(button_rect.size.y >= 48 and root.get_visible_rect().encloses(button_rect), "M2_D1_NATIVE_RESTORE_BUTTON_GEOMETRY")
			var run_before: int = main.run_id
			for pressed in [true, false]:
				var event := InputEventScreenTouch.new()
				event.index = 0
				event.position = button_rect.get_center()
				event.pressed = pressed
				root.push_input(event, true)
			await _frames(6)
			_expect(main.run_id == run_before + 1 and main._touches.is_empty() and main._touch_intent.is_empty(), "M2_D1_NATIVE_RESTORE_EXACTLY_ONCE_UI_ONLY")
		else:
			main._on_continue_pressed()
		_expect(main.phase == main.Phase.SETUP and _rounds(main) == [7, 50, 6] and main.raid_stashes.is_empty(), "M2_D1_GROUND_NO_RESPAWN_COLLECTED_CRATE")
		_expect(main.operators[0].grenades == 1 and main.operators[0].pack.count_of("grenade") == 1 and main.operators[0].has_nade_mark and main.operators[0].nade_mark == mark and main.operators[0].grenade_cd == 0.0, "M2_D1_GROUND_EXACT_TOOL_MARK_COOLDOWN")
		_expect(main.raid_grenades.is_empty() and main.sim.tick == 0, "M2_D1_GROUND_NO_FAILED_RUN_ENTITIES")
		await _frames(2)
	root.content_scale_size = Vector2i(960, 540)
	root.size = Vector2i(960, 540)
	await _frames(4)
	main.raid_force_alarm()
	main._on_abort_pressed()
	await _frames(8)
	var result_rects: Array[Rect2] = []
	for button in [main.continue_button, main.restart_preparation_button, main.result_replay_button, main.dossier_button]:
		var rect: Rect2 = button.get_global_rect()
		print("M2_D1_RESULT_RECT name=%s rect=%s" % [button.name, rect])
		_expect(button.is_visible_in_tree() and rect.size.y >= 48 and root.get_visible_rect().encloses(rect), "M2_D1_SMALL_RESULT_TARGET_BOUNDS")
		for other in result_rects: _expect(not rect.intersects(other), "M2_D1_RESULT_TARGETS_NONOVERLAP")
		result_rects.append(rect)
	var restart_center: Vector2 = main.restart_preparation_button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = restart_center
		event.pressed = pressed
		root.push_input(event, true)
	await _frames(8)
	_expect(_inventory_empty(main) and main.raid_stashes.size() == 4, "M2_D1_SMALL_NATIVE_RESTART_BRANCH")
	main._load_level("warehouse", false, false)
	_expect(not main.preparation_checkpoint_available(), "M2_D1_OTHER_LEVEL_REJECTS_CHECKPOINT")
	if failures.is_empty():
		print("M2_PREPARATION_CHECKPOINT_OK actual_prepare=1 restores=20 two_tactics=1 no_resource_gain=1 native_restore_restart=1 other_level=1")
		quit(0)
	else:
		_finish_failed()
