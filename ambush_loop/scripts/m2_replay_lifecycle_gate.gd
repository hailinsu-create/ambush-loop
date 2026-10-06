extends "res://scripts/m2_yard_supply_gate.gd"

## Actual losing free-position tactic; replay is presentation, never retry authority.
func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	for size in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.content_scale_size = size
		root.size = size
		var main = await _open_yard("REPLAY_LIFECYCLE")
		if main == null or not await _acquire_weapons(main, "REPLAY_LIFECYCLE"):
			_finish_failed()
			return
		var gs = root.get_node_or_null("GameSettings")
		if gs: gs.force_touch_hud = true
		main._ensure_touch_hud()
		var cells := [Vector2i(15,13), Vector2i(29,15), Vector2i(12,14)]
		for i in 3:
			await _walk_to_cell(main, main.operators[i], cells[i])
			main.operators[i].set_facing(180.0 if i < 2 else 0.0)
			main.operators[i].set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
		main.apply_touch_command("permission_mode")
		main.raid_force_alarm()
		main.apply_touch_command("team_fire")
		_run_battle(main)
		_expect(main.phase == main.Phase.FAILED, "M2_REPLAY_REAL_GROUND_FAILURE")
		var checkpoint: String = str(main.preparation_checkpoint.snapshot)
		var log_before: String = str([main.battle_log.events, main.battle_log.snapshots])
		var crew_before: Array = []
		var visibility: Dictionary = {}
		for op in main.operators:
			crew_before.append([op.global_position, op.facing_deg, op.hp, op.ammo, op.pack.slots.duplicate(true), op.ammo_pool.duplicate(true)])
		for actor in main.operators + main.enemies + main.loot_piles:
			if is_instance_valid(actor): visibility[actor] = actor.visible
		main._update_hud()
		await _frames(8)
		var replay_ctas: Array = []
		_collect_replay_buttons(main.result_panel, replay_ctas)
		_expect(replay_ctas.size() == 1 and not main.touch_hud.is_visible_in_tree(), "M2_REPLAY_ONE_RESULT_OWNER_NO_TOUCH_RAIL")
		if replay_ctas.size() != 1:
			_finish_failed()
			return
		var rect: Rect2 = replay_ctas[0].get_global_rect()
		_expect(rect.size.y >= 48 and root.get_visible_rect().encloses(rect), "M2_REPLAY_NATIVE_TARGET_BOUNDS")
		for other in [main.continue_button, main.restart_preparation_button, main.dossier_button]:
			_expect(not rect.intersects(other.get_global_rect()), "M2_REPLAY_RESULT_NONOVERLAP")
		await _native_tap(rect.get_center())
		_expect(main.phase == main.Phase.REPLAY and main._touches.is_empty(), "M2_REPLAY_NATIVE_SINGLE_ENTRY")
		main.replay.set_tick(240)
		main._apply_replay_scrub()
		main._exit_replay_to_setup()
		_expect(main.phase == main.Phase.FAILED and checkpoint == str(main.preparation_checkpoint.snapshot), "M2_REPLAY_FAILURE_CHECKPOINT_UNCHANGED")
		_expect(log_before == str([main.battle_log.events, main.battle_log.snapshots]), "M2_REPLAY_LOG_UNCHANGED")
		for actor in visibility:
			_expect(actor.visible == visibility[actor], "M2_REPLAY_GROUND_EXACT_VISIBILITY")
		for i in 3:
			var op = main.operators[i]
			_expect(crew_before[i] == [op.global_position, op.facing_deg, op.hp, op.ammo, op.pack.slots, op.ammo_pool], "M2_REPLAY_GROUND_AUTHORITY_UNCHANGED")
		await _frames(8)
		await _native_tap(main.continue_button.get_global_rect().get_center())
		_expect(main.phase == main.Phase.SETUP and main.yard_manual_permission and not main._manual_permission_queued and not main._manual_permission_used, "M2_REPLAY_NATIVE_MANUAL_RESTORE_FRESH_QUEUE")
		_expect(_rounds(main) == [7,50,6] and main.raid_stashes.size() == 1 and main.battle_log.events.is_empty(), "M2_REPLAY_NATIVE_EXACT_SUPPLY_NO_PERMISSION_EVENT")
		for i in 3:
			var record: Dictionary = main.preparation_checkpoint.snapshot.crew[i]
			var op = main.operators[i]
			_expect(op.global_position == record.position and op.pack.slots == record.pack and op.ammo_pool == record.ammo_pool and op.has_nade_mark == record.has_mark, "M2_REPLAY_NATIVE_EXACT_CHECKPOINT_FIELDS")
		main.raid_force_alarm()
		main._sim_tick()
		main._on_abort_pressed()
		main._on_replay_pressed()
		main._exit_replay_to_setup()
		await _frames(8)
		await _native_tap(main.restart_preparation_button.get_global_rect().get_center())
		_expect(main.phase == main.Phase.SETUP and _inventory_empty(main) and main.raid_stashes.size() == 4 and not main.preparation_checkpoint_available(), "M2_REPLAY_NATIVE_FRESH_RECOLLECT_BRANCH")
		main.queue_free()
		await _frames(3)
	if failures.is_empty():
		print("M2_REPLAY_LIFECYCLE_OK sizes=2 native=1 manual_checkpoint=1 free_position=1 single_owner=1 exact_restore=1 fresh_restart=1 readonly=1")
		quit(0)
	else: _finish_failed()

func _collect_replay_buttons(node: Node, output: Array) -> void:
	if node is Button and node.text == "时间轴复盘" and node.is_visible_in_tree(): output.append(node)
	for child in node.get_children(): _collect_replay_buttons(child, output)

func _native_tap(position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = position
		event.pressed = pressed
		root.push_input(event, true)
		await _frames(1)
	await _frames(4)
