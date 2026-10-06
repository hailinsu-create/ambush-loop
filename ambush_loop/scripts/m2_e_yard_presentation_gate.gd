extends "res://scripts/m2_yard_supply_gate.gd"

const PresenterScript := preload("res://scripts/m2_i0_yard_presentation.gd")
const EAdapter := preload("res://scripts/m2_i0_yard_adapter.gd")
const ESpace := preload("res://scripts/presentation/world_space.gd")

func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	capture_dir = OS.get_environment("AMBUSH_TEST_DATA_ROOT").get_base_dir().path_join("m2-e-screens")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var main = await _open_yard("E_PRESENTATION")
	if main == null or not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	_expect(main.get_node_or_null("I0YardPresentation") == null, "M2_E_NORMAL_ENTRY_NO_EAGER_3D_ALLOCATION")
	await _click(main.yard_hud.preview_3d_button)
	var presenter = main.get_node_or_null("I0YardPresentation")
	presenter.set_process(false)
	presenter.sync_presentation()
	_expect(presenter._world != null and presenter.active, "M2_E_YARD_BOUND")
	_expect(presenter._toggle.size.y >= 48, "M2_E_TOGGLE_TARGET")
	for route in ["main", "flank"]:
		var expected := EAdapter.world_anchor(main.grid, main.route_world[route][0], 1.6)
		_expect(presenter.landmark_nodes[route].position.is_equal_approx(expected), "M2_E_AUTHORED_ENTRY_" + route)
	_expect(presenter.landmark_nodes["exit"].position.is_equal_approx(EAdapter.world_anchor(main.grid, main.escape_world, 1.6)), "M2_E_AUTHORED_EXIT")
	await _capture_if_rendered(main, "setup-high-platform")
	main.raid_force_alarm()
	for _tick in 260: main._sim_tick()
	presenter.sync_presentation()
	_expect(presenter._enemy_nodes.has("3") and presenter._enemy_nodes["3"].visible, "M2_E_ACTUAL_FLANK_ACTIVE")
	await _capture_if_rendered(main, "watch-main-flank")
	_run_battle(main)
	_expect(main.phase == main.Phase.WON, "M2_E_REAL_B2_WIN")
	var log_identity = main.battle_log
	var records: Array = main.battle_log.snapshots.duplicate(true)
	_expect(not records.is_empty() and int(records[0]["data"].get("presentation_schema", 0)) == 2, "M2_E_RECORD_SCHEMA")
	var event: Dictionary = {}
	for candidate in main.battle_log.events:
		if str(candidate.get("type", "")) == "fire":
			event = candidate
			break
	_expect(not event.is_empty(), "M2_E_REAL_FIRE_EVENT")
	var before_visibility: Dictionary = {}
	for actor in main.operators + main.enemies + main.loot_piles:
		if is_instance_valid(actor): before_visibility[actor] = actor.visible
	main._on_replay_pressed()
	await _frames(4)
	_expect(main.scrub_slider.is_visible_in_tree() and main.scrub_slider.get_global_rect().size.y >= 48, "M2_E_VISIBLE_DESKTOP_REPLAY_TIMELINE")
	# Deliberately corrupt live display inputs after recording: replay must ignore them.
	main.operators[2].global_position = Vector2(208, 528)
	main.operators[2].facing_deg = 270.0
	var baseline := _authority(main)
	var baseline_detail := _authority_data(main)
	for tick in [0, 239, 240, int(event.get("tick", 0)), main.battle_log.terminal_tick]:
		main.replay.set_tick(tick)
		main._apply_replay_scrub()
		presenter.sync_presentation()
		_verify_record(presenter, main.replay.snapshot_at_or_before(tick).get("data", {}))
		var marker_data: Dictionary = main.replay.snapshot_at_or_before(tick).get("data", {})
		var marker_records: Array = marker_data.get("ops", []) + marker_data.get("enemies", []) + marker_data.get("barrels", [])
		var markers: Array = main.replay_layer.get_children().filter(func(node): return not node.is_queued_for_deletion())
		_expect(markers.size() == marker_records.size(), "M2_E_2D_RECORD_COUNT")
		for i in mini(markers.size(), marker_records.size()):
			_expect(is_equal_approx(float(markers[i].get_meta("recorded_facing")), float(marker_records[i].get("facing", 90.0))), "M2_E_2D_3D_RECORDED_FACING_PARITY")
		_expect(presenter.pick_at(Vector2(640, 360)).is_empty() and presenter.screen_to_logic(Vector2(640, 360)) == Vector2.INF, "M2_E_REPLAY_NO_WORLD_ACTION")
	await _capture_if_rendered(main, "replay-terminal")
	var event_tick := int(event.get("tick", 0))
	for age in [-1, 0, 6, 0]:
		# Isolate one real recorded event to verify exact lifetime without other shots.
		var all_events: Array = main.battle_log.events
		main.battle_log.events = [event]
		presenter._sync_event_fx(event_tick + age)
		_expect(_visible_fx(presenter) == (1 if age >= 0 and age < 6 else 0), "M2_E_FIRE_FIXED_TICK_BOUNDARY_%d" % age)
		main.battle_log.events = all_events
	var node_count: int = presenter._world.get_child_count()
	for i in 100:
		main.replay.set_tick((i * 17) % (main.replay.max_tick() + 1))
		presenter._set_active(i % 2 == 0)
		presenter.sync_presentation()
		_expect(presenter._world.visible == presenter.active, "M2_E_FALLBACK_VISIBILITY")
	_expect(presenter._world.get_child_count() == node_count and presenter._fx_nodes.size() == 16, "M2_E_BOUNDED_NODE_POOL")
	if baseline != _authority(main):
		print("M2_E_AUTHORITY_BEFORE=" + str(baseline_detail))
		print("M2_E_AUTHORITY_AFTER=" + str(_authority_data(main)))
	print("M2_E_READONLY_COMPONENTS authority=%s identity=%s records=%s" % [baseline == _authority(main), main.battle_log == log_identity, records == main.battle_log.snapshots])
	_expect(baseline == _authority(main) and main.battle_log == log_identity and records == main.battle_log.snapshots, "M2_E_SCRUB_TOGGLE_READONLY")
	main.replay.set_tick(event_tick)
	presenter._set_active(true)
	presenter.sync_presentation()
	await _capture_if_rendered(main, "replay-fire")
	main._exit_replay_to_setup()
	_expect(main.phase == main.Phase.WON and baseline == _authority(main), "M2_E_REPLAY_EXIT_NO_POSITION_OR_COMBAT_MUTATION")
	for actor in before_visibility:
		_expect(actor.visible == before_visibility[actor], "M2_E_REPLAY_EXIT_EXACT_VISIBILITY")
	main._load_level("warehouse", false, false)
	presenter._process(0)
	_expect(not presenter.active and not presenter._world.visible and not presenter._controls.visible, "M2_E_OTHER_LEVEL_NOT_PROMOTED")
	main._load_level("yard", false, false)
	presenter._process(0)
	_expect(not presenter.active, "M2_E_LEVEL_RETURN_REQUIRES_EXPLICIT_OPT_IN")
	if failures.is_empty():
		print("M2_E_PRESENTATION_OK records=1 enemy_lifecycle=1 replay_readonly=1 fixed_tick_fx=1 bounded_nodes=1 authored_landmarks=1 fallback=1")
		quit(0)
	else: _finish_failed()

func _verify_record(presenter, data: Dictionary) -> void:
	for collection in ["ops", "enemies"]:
		var nodes: Dictionary = presenter._actor_nodes if collection == "ops" else presenter._enemy_nodes
		var seen := {}
		for record in data.get(collection, []):
			var key := str(record["id"])
			seen[key] = true
			_expect(nodes.has(key), "M2_E_RECORD_NODE_" + key)
			if not nodes.has(key): continue
			var body = nodes[key]
			_expect(body.position.is_equal_approx(EAdapter.recorded_anchor(record["pos"], int(record.get("tier", 0)), 0.68)), "M2_E_RECORDED_ANCHOR_" + key)
			_expect(is_equal_approx(body.rotation.y, ESpace.facing_yaw(float(record.get("facing", 90)))), "M2_E_RECORDED_FACING_" + key)
			var expected: bool = bool(record.get("alive", false)) and bool(record.get("visible", true) if collection == "ops" else record.get("active", true))
			_expect(body.visible == expected, "M2_E_RECORDED_LIFECYCLE_" + key)
		for key in nodes:
			if not seen.has(key): _expect(not nodes[key].visible, "M2_E_NOT_YET_SPAWNED_HIDDEN_" + key)

func _visible_fx(presenter) -> int:
	var count := 0
	for node in presenter._fx_nodes:
		if node.visible: count += 1
	return count

func _authority(main) -> String:
	return str(_authority_data(main)).sha256_text()

func _authority_data(main) -> Array:
	var state := []
	for op in main.operators: state.append([op.op_id, op.global_position, op.facing_deg, op.hp, op.alive, op.weapon_id, op.ammo_pool, op.pack.slots])
	for enemy in main.enemies: state.append([enemy.label_id, enemy.global_position, enemy.facing_deg, enemy.hp, enemy.alive, enemy.active])
	return [state, main.sim.tick, main.battle_log.events.duplicate(true), main.battle_log.snapshots.duplicate(true), main.battle_log.terminal_tick, main.battle_log.terminal_reason]
