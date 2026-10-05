extends "res://scripts/m2_yard_supply_gate.gd"

func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	var results: Array[Dictionary] = []
	for kind in ["HIGH", "GROUND", "HIGH_NEAR", "GROUND_NEAR", "HIGH_BAD", "GROUND_BAD"]:
		var main = await _open_yard(kind)
		if main == null:
			_finish_failed()
			return
		_expect(main.level.wave_count() == 1, "M2_B2_SINGLE_CONTACT_" + kind)
		if not await _acquire_weapons(main, kind):
			_finish_failed()
			return
		var ground: bool = kind.begins_with("GROUND")
		var near: bool = kind.ends_with("NEAR")
		var bad: bool = kind.ends_with("BAD")
		var grenade_before := 0
		if ground:
			var stash = main.raid_stashes[0]
			_expect(stash.kind == "grenade", "M2_B2_REAL_OPTIONAL_GRENADE")
			var trace: Dictionary = await _walk_to_cell(main, main.operators[0], stash.cell)
			_expect(bool(trace.get("ok", false)), "M2_B2_REAL_GRENADE_ROUTE")
			main.selected = main.operators[0]
			main._try_pickup_near_selected()
			main.raid_advance_search(1.0)
			await _frames(2)
			grenade_before = main.operators[0].grenades
			_expect(grenade_before == 1, "M2_B2_REAL_GRENADE_SEARCH")
		var cells := [Vector2i(15, 13), Vector2i(12, 14), Vector2i(29, 15)] if ground else [Vector2i(30, 11), Vector2i(12, 14), Vector2i(15, 10)]
		var faces := [180.0, 45.0, 0.0] if ground else [0.0, 45.0, 153.4]
		if near:
			faces[1] += 5.0
			cells[0] += Vector2i(0, 1) if not ground else Vector2i(-1, 0)
		var ramp_used := false
		for i in 3:
			var op = main.operators[i]
			var trace: Dictionary = await _walk_to_cell(main, op, cells[i])
			_expect(bool(trace.get("ok", false)), "M2_B2_REAL_DEPLOY_%s_%d" % [kind, i])
			ramp_used = ramp_used or bool(trace.get("used_ramp", false))
			op.set_facing(faces[i])
			op.set_fire_mode(OperatorUnit.FireMode.ENGAGE_ON_SIGHT)
			if ground:
				_expect(main.grid.get_elevation_tier(op.grid_cell().x, op.grid_cell().y) == 0, "M2_B2_GROUND_NO_HIGHPOINT")
		if ground:
			_expect(not ramp_used, "M2_B2_GROUND_NO_RAMP_ROUTE")
			main.selected = main.operators[0]
			main._place_nade_mark(main.grid.cell_to_world_center(Vector2i(13, 11)))
		else:
			_expect(ramp_used and main.raid_stashes.size() == 1, "M2_B2_HIGH_REAL_RAMP_OPTIONAL_UNTOUCHED")
		if bad:
			# A real uncovered side lane, rather than a scripted failure result.
			main.operators[2 if ground else 0].set_facing(180.0)
		var initial: Array = _rounds(main)
		main.raid_force_alarm()
		_run_battle(main)
		var won: bool = main.phase == main.Phase.WON
		var spawn_ids: Array = []
		var kill_ids: Array = []
		var shots := [0, 0, 0]
		for event in main.battle_log.events:
			var typ := str(event.get("type", ""))
			if typ == "spawn": spawn_ids.append(int(event.get("actor_id", -1)))
			if typ == "kill": kill_ids.append(int(event.get("actor_id", -1)))
			if typ == "fire":
				var owner := int(event.get("actor_id", -1))
				if owner >= 1 and owner <= 3: shots[owner - 1] += 1
		for i in 3:
			_expect(initial[i] - main.operators[i].ammo == shots[i], "M2_B2_AMMO_LEDGER")
		if bad:
			_expect(not won and main.battle_log.terminal_reason == "escape", "M2_B2_REAL_COUNTEREXAMPLE_" + kind)
		else:
			_expect(won, "M2_B2_REAL_WIN_" + kind)
			for id in [1, 2, 3]:
				_expect(spawn_ids.count(id) == 1 and kill_ids.count(id) == 1, "M2_B2_THREE_TARGETS_ONCE")
		if ground:
			_expect(main.operators[0].grenades == 0, "M2_B2_OPTIONAL_GRENADE_ACTUALLY_CONSUMED")
			var blast: Dictionary = main.battle_log.last_of_type("grenade")
			_expect(int(blast.get("payload", {}).get("hits", 0)) > 0, "M2_B2_GRENADE_REAL_TARGET_HIT")
		print("M2_B2_RESULT kind=%s won=%s terminal=%s shots=%s kills=%s remaining=%s grenade=%d" % [kind, won, main.battle_log.terminal_reason, shots, kill_ids, _rounds(main), main.operators[0].grenades])
		results.append({"kind": kind, "won": won})
	if failures.is_empty():
		print("M2_SINGLE_CONTACT_GATE_OK scenarios=6 real_resources=1 high_and_ground=1 nearby=1 counterexamples=1")
		quit(0)
	else:
		_finish_failed()
