extends "res://scripts/m2_yard_supply_gate.gd"

func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	var signatures: Array = []
	var frame_counts: Array[int] = []
	for speed in [1.0, 2.0]:
		var main = await _open_yard("C_SPEED")
		if main == null or not await _prepare_plan(main, "A"):
			_finish_failed()
			return
		main.apply_touch_command("permission_mode")
		for i in [0,1]: main.operators[i].set_fire_mode(OperatorUnit.FireMode.HOLD_FOR_AMBUSH)
		main.operators[2].set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
		main.raid_force_alarm()
		main.sim.set_speed(speed)
		var real_frames := 0
		while main.phase == main.Phase.WATCHING and real_frames < 3000:
			real_frames += 1
			for _step in main.sim.steps_for_frame(SimClock.TICK_DT):
				if main.phase != main.Phase.WATCHING: break
				if main.sim.tick == 200:
					main.apply_touch_command("team_fire")
					main.apply_touch_command("team_fire")
					_expect(not main.operators[0].fire_permitted and _permissions(main).is_empty(), "C_UI_ONLY_QUEUES")
				main._sim_tick()
		if main.phase == main.Phase.SWEEP: main._on_sweep_commit()
		_expect(main.phase == main.Phase.WON, "C_REAL_MANUAL_REFERENCE_WINS")
		var permissions: Array = _permissions(main)
		_expect(permissions.size() == 1 and int(permissions[0].tick) == 200 and permissions[0].payload.armed_ids == [1,2], "C_FIXED_TICK_HOLD_ONLY_ONCE")
		main.apply_touch_command("team_fire")
		_expect(_permissions(main).size() == 1, "C_LATE_DUPLICATE_INERT")
		signatures.append(str([main.battle_log.events, main._snapshot_data(), main.battle_log.terminal_tick, _rounds(main)]))
		frame_counts.append(real_frames)
		var before := _authority_signature(main)
		main._on_replay_pressed()
		main.replay.set_tick(199)
		main._apply_replay_scrub()
		_expect(_permission_count(main.replay.events_up_to(199)) == 0 and _permission_count(main.replay.events_up_to(200)) == 1, "C_REPLAY_RECORDED_PERMISSION_BOUNDARY")
		main.replay.set_tick(250)
		main._apply_replay_scrub()
		_expect(_authority_signature(main) == before, "C_REPLAY_READ_ONLY")
	_expect(signatures.size() == 2 and signatures[0] == signatures[1] and frame_counts[1] < frame_counts[0], "C_ONE_TWO_SPEED_IDENTICAL_AUTHORITATIVE_LOG")
	print("M2_C_FRAME_COUNTS %s" % [frame_counts])
	for scene_path in ["res://scenes/main.tscn", "res://scenes/presentation/yard_i0_3d.tscn"]:
		change_scene_to_file(scene_path)
		await _frames(14)
		var main = current_scene
		if main.level.level_id != "yard":
			main._load_level("yard", false, false)
			await _frames(2)
		var presenter = main.get_node_or_null("I0YardPresentation")
		if presenter != null and presenter._world == null:
			presenter._bound = false
			presenter.bind(main)
		for _page in 4:
			if main.tutorial_overlay and main.tutorial_overlay.is_open(): main.tutorial_overlay._on_next()
		root.get_node("GameSettings").set_force_touch_hud(true)
		main.set_process(false)
		for size in [Vector2i(1280,720), Vector2i(960,540)]:
			root.content_scale_size = size
			root.size = size
			main._start_setup(false, false)
			for op in main.operators: op.set_process(false)
			main.yard_hud.details_open = true
			main._update_hud()
			await _frames(6)
			_expect(not main.touch_hud._btns.team_fire.is_visible_in_tree(), "C_AUTO_SETUP_BUTTON_HIDDEN")
			await _native_tap(main.yard_hud.permission_mode_button.get_global_rect().get_center())
			print("M2_C_MODE_TOUCH level=%s rect=%s visible=%s manual=%s" % [main.level.level_id, main.yard_hud.permission_mode_button.get_global_rect(), main.yard_hud.permission_mode_button.is_visible_in_tree(), main.yard_manual_permission])
			_expect(main.yard_manual_permission and main._touches.is_empty(), "C_NATIVE_PREPARATION_MODE_UI_ONLY")
			for i in [0,1]: main.operators[i].set_fire_mode(OperatorUnit.FireMode.HOLD_FOR_AMBUSH)
			main.operators[2].set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
			main.raid_force_alarm()
			for op in main.operators: op.set_process(false)
			# Use real scheduled runners: entry into authored zone alone cannot arm HOLD.
			for _tick in 230: main._sim_tick()
			_expect(not main.operators[0].fire_permitted and not main.operators[1].fire_permitted and main.operators[2].fire_permitted and _permissions(main).is_empty(), "C_MANUAL_ZONE_NEVER_AUTO_ARMS")
			main.apply_touch_command("pause")
			var tick_before: int = main.sim.tick
			main._update_hud()
			await _frames(6)
			var button: Button = main.touch_hud._btns.team_fire
			var rect: Rect2 = button.get_global_rect()
			_expect(button.is_visible_in_tree() and rect.size.x >= 48 and rect.size.y >= 48 and root.get_visible_rect().encloses(rect), "C_NATIVE_TARGET_BOUNDS")
			for command in ["abort","pause","speed"]:
				_expect(not rect.intersects(main.touch_hud._btns[command].get_global_rect()), "C_NATIVE_TARGET_NONOVERLAP")
			await _native_tap(rect.get_center())
			for pressed in [true,false]:
				var mouse := InputEventMouseButton.new()
				mouse.device = -1
				mouse.position = rect.get_center()
				mouse.global_position = mouse.position
				mouse.button_index = MOUSE_BUTTON_LEFT
				mouse.pressed = pressed
				root.push_input(mouse, true)
			_expect(main._manual_permission_queued and not main.operators[0].fire_permitted and _permissions(main).is_empty() and main._touches.is_empty() and not main.touch_intent_pending(), "C_NATIVE_PAUSED_QUEUE_NO_PASSTHROUGH")
			for _frame in 8: _expect(main.sim.steps_for_frame(SimClock.TICK_DT) == 0, "C_PAUSE_NO_FIXED_TICKS")
			_expect(main.sim.tick == tick_before, "C_PAUSE_TICK_UNCHANGED")
			var positions: Array = []
			var faces: Array = []
			for op in main.operators:
				positions.append(op.global_position)
				faces.append(op.facing_deg)
			main.apply_touch_command("rotate_cw")
			main.apply_touch_command("fire")
			main.apply_touch_command("permission_mode")
			_expect(main.yard_manual_permission and main.operators[0].fire_mode == OperatorUnit.FireMode.HOLD_FOR_AMBUSH, "C_WATCH_MODE_FROZEN")
			main.apply_touch_command("pause")
			main._sim_tick()
			_expect(_permissions(main).size() == 1 and int(_permissions(main)[0].tick) == tick_before and _permissions(main)[0].payload.armed_ids == [1,2], "C_NATIVE_RESUME_EXACTLY_ONCE")
			for i in 3: _expect(main.operators[i].global_position == positions[i] and main.operators[i].facing_deg == faces[i], "C_NO_COMBAT_DEPLOYMENT_MUTATION")
			main._on_abort_pressed()
			main._on_continue_pressed()
			_expect(main.yard_manual_permission and not main._manual_permission_queued and not main._manual_permission_used, "C_CHECKPOINT_MODE_WITHOUT_BATTLE_QUEUE")
			main.apply_touch_command("team_fire")
			_expect(not main._manual_permission_queued, "C_SETUP_PERMISSION_REQUEST_REJECTED")
	# No HOLD: request still records once with empty actual armed_ids.
	var empty = await _open_yard("C_EMPTY")
	for op in empty.operators: op.set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
	empty.apply_touch_command("permission_mode")
	empty.raid_force_alarm()
	empty.apply_touch_command("team_fire")
	empty._sim_tick()
	_expect(_permissions(empty).size() == 1 and _permissions(empty)[0].payload.armed_ids.is_empty(), "C_NO_HOLD_HONEST_EMPTY_EVENT")
	empty._on_abort_pressed()
	empty._on_restart_preparation_pressed()
	empty.apply_touch_command("permission_mode")
	_expect(not empty.yard_manual_permission, "C_OPTION_EXPLICITLY_RETURNS_AUTO")
	for op in empty.operators: op.set_fire_mode(OperatorUnit.FireMode.HOLD_FOR_AMBUSH)
	empty.raid_force_alarm()
	for _tick in 230:
		if empty.phase == empty.Phase.WATCHING: empty._sim_tick()
	_expect(empty.operators[0].fire_permitted and empty.operators[1].fire_permitted and _permissions(empty).is_empty(), "C_AUTO_ZONE_OLD_ARMING_PATH")
	if failures.is_empty():
		print("M2_C_TEAM_FIRE_OK fixed_tick=1 hold_only=1 once=1 pause=1 speed_parity=1 readonly_replay=1 native_two_scenes_sizes=1 checkpoint=1")
		quit(0)
	else: _finish_failed()

func _permissions(main) -> Array:
	return main.battle_log.events.filter(func(event): return str(event.type) == "team_fire_permission")

func _authority_signature(main) -> String:
	var crew: Array = []
	for op in main.operators:
		crew.append([op.op_id, op.global_position, op.facing_deg, op.hp, op.alive, op.weapon_id, op.ammo, op.ammo_pool.duplicate(true), op.pack.slots.duplicate(true), op.fire_mode, op.fire_permitted])
	var targets: Array = []
	for enemy in main.enemies: targets.append([enemy.label_id, enemy.global_position, enemy.hp, enemy.alive])
	return str([crew, targets, main.battle_log.events, main.battle_log.snapshots, main.sim.tick, main._manual_permission_used])

func _permission_count(events: Array) -> int:
	return events.filter(func(event): return str(event.type) == "team_fire_permission").size()

func _native_tap(position: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = position
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(1)
	await _frames(2)
