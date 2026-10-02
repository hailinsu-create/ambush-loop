extends SceneTree

## M1-D contract gate: freeze setup edits at alarm and exercise the real abort/retry path.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")

var failures: Array[String] = []


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		_fail("M1_D_LOAD_MAIN err=%d" % err)
		return
	await _frames(14)
	var main = current_scene
	if main == null or main.level == null or str(main.level.level_id) != "yard":
		_fail("M1_D_NOT_YARD")
		return
	main.set_process(false)
	for op in main.operators:
		op.set_process(false)

	if main.operators.size() < 3 or main.cover_slots.size() < 4:
		_fail("M1_D_FIXTURE_SHORT operators=%d slots=%d" % [main.operators.size(), main.cover_slots.size()])
		return
	# Build a real three-operator plan with distinct roles, facings and fire modes.
	for i in 3:
		var op = main.operators[i]
		main.selected = op
		main._deploy_selected_to(main.cover_slots[i], false)
		op.apply_weapon("rifle", true)
		op.set_facing(37.0 + float(i) * 83.0)
		if i == 1:
			op.set_fire_mode(1)
	main.selected = main.operators[0]
	var gear = main.operators[0]
	gear.pack.add_item("smg", 1)
	gear.pack.add_item("mine", 1)
	gear.pack.add_item("decoy", 1)
	gear.mines = 1
	gear.decoys = 1
	gear.grenades = 1
	gear.set_nade_mark(gear.global_position + Vector2(48, 0))

	# Precondition the actual backpack signals: these operations must work in SETUP.
	main._toggle_backpack()
	_expect(main.backpack_panel.is_open(), "M1_D_SETUP_BACKPACK_OPENS")
	var old_weapon := str(gear.weapon_id)
	main.backpack_panel.equip_requested.emit("smg")
	_expect(str(gear.weapon_id) == "smg" and old_weapon != "smg", "M1_D_SETUP_EQUIP_SIGNAL_LIVE")
	gear.apply_weapon("rifle", true)
	gear.pack.add_item("smg", 1)
	main.backpack_panel.dismiss()

	# Capture a tripwire and door state so retry restoration is observable.
	if main.level.door_cell.x >= 0:
		main._on_door_pressed()
	var routes: Array = main.route_world.values()
	if routes.is_empty() or (routes[0] as PackedVector2Array).size() < 2:
		_fail("M1_D_ROUTE_FIXTURE_MISSING")
		return
	var route: PackedVector2Array = routes[0]
	main._try_place_tripwire(route[0])
	_expect(main.tripwires.size() == 1, "M1_D_SETUP_TRIPWIRE_PLACED")
	_expect(main._deployed_count() == 3, "M1_D_SETUP_THREE_DEPLOYED")

	# Leave the panel open at the boundary: the alarm must close it itself.
	main._toggle_backpack()
	_expect(main.backpack_panel.is_open(), "M1_D_BACKPACK_OPEN_BEFORE_ALARM")
	main._on_alarm_pressed()
	_expect(int(main.phase) == int(main.Phase.WATCHING), "M1_D_ALARM_ENTERS_WATCH")
	_expect(not main.backpack_panel.is_open(), "M1_D_ALARM_DISMISSES_BACKPACK")
	_expect(main.frozen_plan != null, "M1_D_FROZEN_PLAN_CAPTURED")
	var frozen := _plan_signature(main.frozen_plan)
	_expect(frozen == _plan_signature(main._live_plan()), "M1_D_LIVE_PLAN_EQUALS_FREEZE")
	var frozen_tripwire: Vector2 = main.tripwires[0].position if not main.tripwires.is_empty() else Vector2.INF
	var before := _authoritative_signature(main)
	var frozen_copy_before := _plan_signature(main.frozen_plan)

	# A direct keyboard event, map helpers, setup controls, and actual connected
	# inventory signals must not edit the in-flight plan or loadout.
	var key_i := InputEventKey.new()
	key_i.pressed = true
	key_i.physical_keycode = KEY_I
	main._unhandled_input(key_i)
	main._toggle_backpack()
	main.backpack_panel.equip_requested.emit("smg")
	main.backpack_panel.pass_requested.emit("mine")
	main.backpack_panel.drop_requested.emit("decoy")
	main._on_clear_pressed()
	main._on_mode_pressed()
	main._on_pack_pressed()
	main._on_door_pressed()
	main._toggle_tool()
	main._deploy_selected_to(main.cover_slots[3], false)
	main._command_move_selected(gear.global_position + Vector2(96, 0))
	main._try_place_tripwire(route[route.size() - 1])
	main._try_place_inventory_mine(gear.global_position + Vector2(12, 0))
	main._place_nade_mark(gear.global_position + Vector2(24, 0))
	main._throw_decoy_at(gear.global_position + Vector2(24, 0))
	main._transfer_selected_to_nearest()
	main.apply_touch_command("bag")
	main.apply_touch_command("nade")
	main.apply_touch_command("decoy")
	main.apply_touch_command("pass")
	main.apply_touch_command("fire")
	main.apply_touch_command("pack")
	main.apply_touch_command("trip")
	main.apply_touch_command("door")
	main.apply_touch_command("clear")
	var key_r := InputEventKey.new()
	key_r.pressed = true
	key_r.physical_keycode = KEY_R
	main._unhandled_input(key_r)
	main._toggle_pause_menu()
	_expect(main.pause_overlay.is_open(), "M1_D_PAUSE_MENU_PRESENTS_IN_WATCH")
	_expect(not main.pause_overlay._wipe_btn.visible, "M1_D_MEMORY_WIPE_HIDDEN_IN_WATCH")
	main._on_memory_wipe_from_menu()
	main.pause_overlay.dismiss()
	_expect(_authoritative_signature(main) == before, "M1_D_WATCH_EDIT_PATHS_BLOCKED")
	_expect(_plan_signature(main.frozen_plan) == frozen_copy_before, "M1_D_FROZEN_COPY_STABLE")
	_expect(not main.backpack_panel.is_open(), "M1_D_WATCH_BAG_STAYS_CLOSED")
	_expect(main.tripwires.size() == 1 and main.tripwires[0].position == frozen_tripwire, "M1_D_WATCH_TRIPWIRE_STABLE")

	# Presentation controls remain usable without changing the tactical plan.
	main._on_pause_pressed()
	main._on_speed_pressed()
	_expect(_plan_signature(main.frozen_plan) == frozen, "M1_D_VIEW_CONTROLS_KEEP_FREEZE")
	_expect(_authoritative_signature(main) == before, "M1_D_VIEW_CONTROLS_KEEP_LOADOUT")
	main._on_pause_pressed()

	# Create actual transient combat state, fail, and use the normal continue callback.
	var route_name := str(main.route_world.keys()[0])
	main._spawn_one({"id": 901, "route": route_name, "delay": 0.0, "loot": 1, "kit": "", "teaching_note": ""})
	main._spawn_loot_at(gear.global_position + Vector2(10, 8), 1, "smg")
	main.battle_log.add_snapshot(main.sim.tick, {"phase": "watch"})
	_expect(not main.enemies.is_empty() and not main.loot_piles.is_empty(), "M1_D_TRANSIENTS_CREATED")
	main._on_abort_pressed()
	_expect(int(main.phase) == int(main.Phase.FAILED), "M1_D_REAL_ABORT_FAILURE")
	main._on_continue_pressed()
	await _frames(3)
	_expect(int(main.phase) == int(main.Phase.SETUP), "M1_D_REAL_CONTINUE_RETRY")
	_expect(main._deployed_count() == 3, "M1_D_RETRY_RESTORES_DEPLOYMENT")
	_expect(_plan_signature(main._live_plan()) == frozen, "M1_D_RETRY_RESTORES_PLAN")
	_expect(main.tripwires.size() == 1 and main.tripwires[0].position == frozen_tripwire, "M1_D_RETRY_RESTORES_TRIPWIRE")
	_expect(main.enemies.is_empty() and main.loot_piles.is_empty(), "M1_D_RETRY_CLEARS_ENEMIES_LOOT")
	_expect(main.raid_mines.is_empty() and main.raid_grenades.is_empty() and main.raid_decoys.is_empty(), "M1_D_RETRY_CLEARS_THROWABLES")
	_expect(main.pending_spawns.is_empty() and main.battle_log.events.is_empty() and main.battle_log.snapshots.is_empty(), "M1_D_RETRY_CLEARS_COMBAT_LOG")
	_expect(int(main.sim.tick) == 0, "M1_D_RETRY_RESETS_SIM_CLOCK")
	var resources_reset := true
	for op in main.operators:
		resources_reset = resources_reset and str(op.weapon_id) == "knife"
		resources_reset = resources_reset and int(op.ammo) == 0 and op.pack.occupied() == 0
		resources_reset = resources_reset and int(op.grenades) == 0 and int(op.mines) == 0 and int(op.decoys) == 0
		resources_reset = resources_reset and not bool(op.has_ammo_pack)
	_expect(resources_reset, "M1_D_RETRY_RESETS_INVENTORY")
	if not main.operators.is_empty():
		var retry_op = main.operators[0]
		var old_face := float(retry_op.facing_deg)
		retry_op.set_facing(old_face + 31.0)
		_expect(main._diff_vs_last_plan() != "", "M1_D_POST_RETRY_PLAN_DIFF_VISIBLE")
	if not await _pump_door_retry_gate(main):
		return

	if not failures.is_empty():
		for failure in failures:
			push_error(failure)
		print("M1_YARD_PLAN_CONTRACT_FAILED count=%d" % failures.size())
		quit(2)
		return
	print("M1_YARD_PLAN_CONTRACT_OK freeze=1 watch_edit_blocked=1 presentation_only=1 retry_plan=1 retry_resources_reset=1 combat_reset=1 diff=1")
	quit(0)


func _pump_door_retry_gate(main) -> bool:
	main._load_level("pump", false, false)
	await _frames(4)
	for op in main.operators:
		op.set_process(false)
	if main.level == null or main.level.door_cell.x < 0:
		_fail("M1_D_PUMP_DOOR_FIXTURE_MISSING")
		return false
	main.selected = main.operators[0]
	main._deploy_selected_to(main.cover_slots[0], false)
	main.selected.apply_weapon("rifle", true)
	main._on_door_pressed()
	var routes: Array = main.route_world.values()
	if routes.is_empty():
		_fail("M1_D_PUMP_ROUTE_FIXTURE_MISSING")
		return false
	var route: PackedVector2Array = routes[0]
	main._try_place_tripwire(route[0])
	main._on_alarm_pressed()
	var frozen := _plan_signature(main.frozen_plan)
	main._on_abort_pressed()
	main._on_continue_pressed()
	await _frames(3)
	var ok: bool = (
		int(main.phase) == int(main.Phase.SETUP)
		and bool(main.door_locked)
		and main.tripwires.size() == 1
		and _plan_signature(main._live_plan()) == frozen
	)
	_expect(ok, "M1_D_PUMP_RETRY_RESTORES_DOOR_TRIPWIRE")
	return ok


func _plan_signature(plan) -> String:
	if plan == null:
		return "<null>"
	var parts: Array[String] = []
	for entry in plan.deployments:
		parts.append("%d:%d:%.3f:%d:%s" % [
			int(entry.get("op_id", -1)),
			int(entry.get("slot_id", -1)),
			float(entry.get("facing", -1.0)),
			int(entry.get("fire_mode", -1)),
			str(bool(entry.get("has_ammo_pack", false))),
		])
	var wires: Array[String] = []
	for pos in plan.tripwire_positions:
		wires.append("%.2f,%.2f" % [pos.x, pos.y])
	return "%s|door=%s|wires=%s" % [";".join(parts), str(plan.door_locked), ";".join(wires)]


func _authoritative_signature(main) -> String:
	var parts: Array[String] = []
	for op in main.operators:
		parts.append("%d|slot=%d|pos=%.2f,%.2f|face=%.2f|mode=%d|weapon=%s|ammo=%d|pool=%s|pack=%s|n=%d,%d,%d|nade=%s|auto=%s|locked=%s" % [
			int(op.op_id),
			int(op.slot.slot_id) if op.slot else -1,
			op.global_position.x,
			op.global_position.y,
			float(op.facing_deg),
			int(op.fire_mode),
			str(op.weapon_id),
			int(op.ammo),
			JSON.stringify(op.ammo_pool),
			JSON.stringify(op.pack.slots),
			int(op.grenades), int(op.mines), int(op.decoys),
			str(bool(op.has_nade_mark)),
			str(bool(op.auto_grenade)),
			str(bool(op.locked)),
		])
	var wire_bits: Array[String] = []
	for wire in main.tripwires:
		wire_bits.append("%.2f,%.2f:%s:%s" % [wire.position.x, wire.position.y, str(bool(wire.armed)), str(bool(wire.spent))])
	return "%s|door=%s|wires=%s|phase=%d|tick=%d|combat=%d,%d,%d,%d,%d,%d,%d" % [
		";".join(parts), str(main.door_locked), ";".join(wire_bits), int(main.phase), int(main.sim.tick),
		main.enemies.size(), main.loot_piles.size(), main.raid_mines.size(),
		main.raid_grenades.size(), main.raid_decoys.size(), main.battle_log.events.size(),
		main.pending_spawns.size()
	]


func _frames(count: int) -> void:
	for _i in count:
		await process_frame


func _expect(ok: bool, marker: String) -> void:
	if not ok:
		failures.append(marker)
		push_error(marker)
	else:
		print(marker)


func _fail(marker: String) -> void:
	push_error(marker)
	quit(2)
