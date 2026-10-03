extends "res://scripts/m2_yard_hud_gate.gd"

## B1 resource contract only. B2 encounter/ground tactic is not yet implemented.
func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	capture_dir = OS.get_environment("AMBUSH_TEST_DATA_ROOT").get_base_dir().path_join("m2-b1-screens")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var main = await _open_yard("SUPPLY")
	if main == null:
		_finish_failed()
		return
	_expect(_inventory_empty(main), "M2_B1_AUTHORED_START_1_3_1_NO_TOOLS")
	var tutorial := preload("res://scripts/ui/tutorial_overlay.gd")
	_expect(not str(tutorial.YARD_STEPS[0].body).contains("只有刀") and str(tutorial.YARD_STEPS_TOUCH[0].body).contains("1/3/1"), "M2_B1_DESKTOP_TOUCH_TUTORIAL_MATCH_RESOURCE_CONTRACT")
	_expect(main.raid_stashes.size() == 4, "M2_B1_FOUR_INTERACTIONS")
	_expect(main.level.wave_count() == 2, "M2_B1_WAVES_UNCHANGED_UNTIL_B2")
	await _capture_if_rendered(main, "insertion-supplies")
	if not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	_expect(_rounds(main) == [7, 50, 6], "M2_B1_REAL_PICKUP_EXACT_7_50_6")
	_expect(main.raid_stashes.size() == 1 and main.raid_stashes[0].kind == "grenade", "M2_B1_OPTIONAL_CRATE_UNTOUCHED")
	await _capture_if_rendered(main, "supplied-highpoint")
	var initial := _rounds(main)
	main.raid_force_alarm()
	_run_battle(main)
	_expect(main.phase == main.Phase.WON, "M2_B1_STANDARD_PLAN_WINS_WITHOUT_OPTIONAL")
	var spent := [0, 0, 0]
	for event in main.battle_log.events:
		if str(event.get("type", "")) == "fire":
			var id := int(event.get("actor_id", -1))
			if id >= 1 and id <= 3:
				spent[id - 1] += 1
	for i in 3:
		_expect(initial[i] - main.operators[i].ammo == spent[i], "M2_B1_OP%d_ROUND_LEDGER" % (i + 1))
	print("M2_B1_LEDGER initial=%s shots=%s remaining=%s" % [initial, spent, _rounds(main)])

	# Actual setup/retry entry must reset to starting grants, not recovered ammo.
	for repeat in 3:
		main._start_setup(true, false)
		await _frames(2)
		_expect(_inventory_empty(main) and main.raid_stashes.size() == 4, "M2_B1_REPEAT%d_NO_RESOURCE_DUPLICATION" % repeat)
	var op = main.operators[0]
	var original := str(op.weapon_id)
	op.ammo = 0
	op.ammo_pool["rifle"] = 0
	for repeat in 4:
		op.apply_weapon("knife", true)
		op.apply_weapon(original, true)
		_expect(op.ammo == 0, "M2_B1_EMPTY_REEQUIP%d_NO_FREE_ROUNDS" % repeat)
	var receiver = main.operators[1]
	var before := int(receiver.ammo_pool.get("rifle", 0))
	_expect(bool(op.transfer_to(receiver, original).get("ok", false)), "M2_B1_EMPTY_GUN_TRANSFER_ALLOWED")
	_expect(int(receiver.ammo_pool.get("rifle", 0)) == before, "M2_B1_EMPTY_TRANSFER_NO_MINIMUM_ONE_ROUND")
	receiver.apply_weapon(original, false)
	_expect(receiver.ammo == before, "M2_B1_TRANSFERRED_EMPTY_GUN_STAYS_EMPTY")
	var dropped: Dictionary = receiver.drop_from_pack(original)
	_expect(bool(dropped.get("ok", false)) and int(dropped.get("amount", -1)) == 0, "M2_B1_EMPTY_DROP_RECORD_ZERO")
	var reclaimed: Dictionary = receiver.receive_item(original, int(dropped.get("amount", -1)))
	_expect(bool(reclaimed.get("ok", false)) and int(receiver.ammo_pool.get("rifle", 0)) == 0, "M2_B1_EMPTY_RECLAIM_NO_FREE_ROUND")

	main._start_setup(false, false)
	await _frames(2)
	op = main.operators[0]
	var wrong: Dictionary = op.receive_item("mg_ammo", 8)
	_expect(bool(wrong.get("pooled", false)) and op.ammo == 1 and int(op.ammo_pool.get("mg", 0)) == 8, "M2_B1_TYPED_AMMO_DOES_NOT_LOAD_WRONG_GUN")
	op.receive_item("mg42", 0)
	op.apply_weapon("mg42", true)
	_expect(op.ammo == 8, "M2_B1_EQUIP_ONLY_POOLED_ROUNDS_NOT_START_AMMO")
	op.apply_weapon("kar98k", true)
	_expect(op.ammo == 1, "M2_B1_SWITCH_BACK_PRESERVES_RIFLE_BUDGET")
	op.receive_ammo(20)
	op.apply_weapon("knife", true)
	op.apply_weapon("kar98k", true)
	_expect(op.ammo == 21, "M2_B1_CARRIED_OVERFLOW_NOT_LOST_OR_REGENERATED")
	var dropped_loaded: Dictionary = op.drop_from_pack("kar98k")
	_expect(int(dropped_loaded.get("amount", -1)) == 21 and int(op.ammo_pool.get("rifle", 0)) == 0, "M2_B1_LOADED_DROP_REMOVES_ALL_OWNED_ROUNDS")
	op.receive_item("kar98k", 21)
	op.apply_weapon("kar98k", false)
	_expect(op.ammo == 21, "M2_B1_LOADED_RECLAIM_CONSERVES_ROUNDS")
	var loaded_receiver = main.operators[1]
	var rifle_before := int(loaded_receiver.ammo_pool.get("rifle", 0))
	_expect(bool(op.transfer_to(loaded_receiver, "kar98k").get("ok", false)), "M2_B1_LOADED_TRANSFER_ACCEPTED")
	_expect(int(op.ammo_pool.get("rifle", 0)) == 0 and int(loaded_receiver.ammo_pool.get("rifle", 0)) == rifle_before + 21, "M2_B1_LOADED_TRANSFER_CONSERVES_SQUAD_BUDGET")
	loaded_receiver.apply_weapon("kar98k", false)
	_expect(loaded_receiver.ammo == rifle_before + 21 and loaded_receiver.inventory_line().contains("携行弹"), "M2_B1_TRANSFER_BUDGET_HAS_NO_MAGAZINE_CAP_OR_HIDDEN_RESERVE")
	var zero: Dictionary = loaded_receiver.receive_item("rifle_ammo", 0)
	_expect(int(zero.get("gained", -1)) == 0 and loaded_receiver.ammo == rifle_before + 21, "M2_B1_ZERO_TYPED_PICKUP_NO_FREE_ROUND")

	main._start_setup(false, false)
	await _frames(2)
	var grenade = main.raid_stashes[3]
	var path: Dictionary = await _walk_to_cell(main, main.operators[0], grenade.cell)
	_expect(bool(path.get("ok", false)), "M2_B1_OPTIONAL_ROUTE_REAL_PATH")
	main.selected = main.operators[0]
	main._try_pickup_near_selected()
	main.raid_advance_search(0.8)
	await process_frame
	_expect(main.operators[0].grenades == 1 and main.operators[0].consume_grenade() and main.operators[0].grenades == 0 and not main.operators[0].consume_grenade(), "M2_B1_ONE_OPTIONAL_TOOL_SINGLE_CONSUMPTION")
	main.raid_force_alarm()
	main._on_abort_pressed()
	main._on_continue_pressed()
	await _frames(3)
	_expect(_inventory_empty(main) and main.raid_stashes.size() == 4, "M2_B1_REAL_ABORT_CONTINUE_BASELINE")
	for id in ["warehouse", "pump", "railcut", "depot", "radio"]:
		main._load_level(id, false, false)
		await _frames(3)
		_expect(not main.level.explicit_ammo and main.level.starting_loadouts.is_empty(), "M2_B1_%s_LEGACY_DEFINITION" % id)
		for legacy_op in main.operators:
			_expect(not legacy_op.explicit_ammo and legacy_op.weapon_id == "knife", "M2_B1_%s_LEGACY_KNIFE_START" % id)
		main.operators[0].receive_item("rifle", 1)
		_expect(main.operators[0].ammo >= main.operators[0].start_ammo, "M2_B1_%s_LEGACY_EQUIP_GRANT" % id)
	if not failures.is_empty():
		_finish_failed()
		return
	print("M2_YARD_SUPPLY_OK real_pickups=1 exact_budget=1 standard_win=1 optional_not_required=1 empty_equip_transfer_drop=1 retry_reset=1 other_five_legacy=1")
	quit(0)


func _rounds(main) -> Array:
	var rounds: Array = []
	for op in main.operators:
		rounds.append(int(op.ammo))
	return rounds


func _run_battle(main) -> void:
	for tick in MAX_SIM_TICKS:
		if main.phase == main.Phase.SWEEP:
			main._on_sweep_commit()
		if main.phase != main.Phase.WATCHING:
			return
		main._sim_tick()
	_fail("M2_B1_SIMULATION_GUARD")
