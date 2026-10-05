extends "res://scripts/m2_yard_supply_gate.gd"

var overlap_observation: Dictionary = {}

func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	var results: Array[Dictionary] = []
	var ground_core := ""
	var cases: Array = ["HIGH", "GROUND", "HIGH_NEAR", "GROUND_NEAR", "HIGH_BAD", "GROUND_BAD", "GROUND_NO_GRENADE"]
	var probe := OS.get_environment("AMBUSH_B2_CASE")
	if probe != "":
		if not cases.has(probe):
			quit(4)
			return
		cases = [probe]
	for kind in cases:
		var main = await _open_yard(kind)
		if main == null:
			_finish_failed()
			return
		_expect(main.level.wave_count() == 1, "M2_B2_SINGLE_CONTACT_" + kind)
		_expect(main.level.route_cells.flank == [Vector2i(32,10), Vector2i(32,15), Vector2i(31,17), Vector2i(31,19)], "M2_B2_SHORT_AUTHORED_EAST_ENTRY")
		_expect(main.level.route_cells.main == [Vector2i(13,3), Vector2i(13,5), Vector2i(13,7), Vector2i(13,11), Vector2i(13,15), Vector2i(13,17), Vector2i(24,17), Vector2i(31,17), Vector2i(31,19)], "M2_B2_MAIN_ROUTE_UNCHANGED")
		_expect(main.grid.validate_level_geometry(main.level.cover_defs, main.level.route_cells).is_empty(), "M2_B2_AUTHORED_ROUTE_GEOMETRY")
		if not await _acquire_weapons(main, kind):
			_finish_failed()
			return
		var ground: bool = kind.begins_with("GROUND")
		var near: bool = kind.ends_with("NEAR")
		var bad: bool = kind.ends_with("BAD")
		var no_grenade: bool = kind == "GROUND_NO_GRENADE"
		var grenade_before := 0
		if ground and not no_grenade:
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
		var cells := [Vector2i(15, 13), Vector2i(29, 15), Vector2i(12, 14)] if ground else [Vector2i(30, 11), Vector2i(12, 14), Vector2i(15, 10)]
		var faces := [180.0, 330.0, 0.0] if ground else [0.0, 45.0, 153.4]
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
			if not no_grenade: main._place_nade_mark(main.grid.cell_to_world_center(Vector2i(13, 11)))
		else:
			_expect(ramp_used and main.raid_stashes.size() == 1, "M2_B2_HIGH_REAL_RAMP_OPTIONAL_UNTOUCHED")
		if bad:
			# A real uncovered side lane, rather than a scripted failure result.
			main.operators[1 if ground else 0].set_facing(180.0)
		var initial: Array = _rounds(main)
		if kind in ["GROUND", "GROUND_NO_GRENADE"]:
			var core: Array = []
			for op in main.operators:
				core.append([op.op_id, op.global_position, op.facing_deg, op.fire_mode, op.weapon_id, op.ammo, op.ammo_pool, op.hp, op.alive, op.stance])
			var signature := str(core).sha256_text()
			if kind == "GROUND": ground_core = signature
			elif probe == "": _expect(signature == ground_core, "M2_B2_CLEAN_NO_GRENADE_COMBAT_STATE")
			print("M2_B2_PREALARM kind=%s core=%s grenades=%d crates=%d" % [kind, signature, main.operators[0].grenades, main.raid_stashes.size()])
		main.raid_force_alarm()
		overlap_observation.clear()
		_run_battle(main)
		var won: bool = main.phase == main.Phase.WON
		var spawn_ids: Array = []
		var kill_ids: Array = []
		var shots := [0, 0, 0]
		var spawn_ticks: Dictionary = {}
		var death_ticks: Dictionary = {}
		var main_contact := 99999
		var flank_interaction := 99999
		for event in main.battle_log.events:
			var typ := str(event.get("type", ""))
			if typ in ["spawn", "grenade", "kill", "escape"]:
				print("M2_B2_EVENT kind=%s tick=%d type=%s actor=%d payload=%s" % [kind, int(event.tick), typ, int(event.actor_id), event.payload])
			if typ == "fire" and main.battle_log.first_of_type("fire").get("seq", -1) == event.seq:
				print("M2_B2_FIRST_FIRE kind=%s tick=%d target=%d" % [kind, int(event.tick), int(event.target_id)])
			if typ == "spawn":
				spawn_ids.append(int(event.get("actor_id", -1)))
				spawn_ticks[int(event.get("actor_id", -1))] = int(event.tick)
			if typ == "kill": kill_ids.append(int(event.get("actor_id", -1)))
			if typ == "kill": death_ticks[int(event.actor_id)] = int(event.tick)
			if typ == "fire" and int(event.target_id) in [1,2]: main_contact = mini(main_contact, int(event.tick))
			if (typ == "fire" and int(event.target_id) == 3) or (typ == "return_fire" and int(event.actor_id) == 3): flank_interaction = mini(flank_interaction, int(event.tick))
			if typ == "grenade":
				for target in event.payload.get("targets", []):
					if int(target.id) in [1,2] and float(target.damage) > 0: main_contact = mini(main_contact, int(event.tick))
			if typ == "fire":
				var owner := int(event.get("actor_id", -1))
				if owner >= 1 and owner <= 3: shots[owner - 1] += 1
		for i in 3:
			_expect(initial[i] - main.operators[i].ammo == shots[i], "M2_B2_AMMO_LEDGER")
		_expect(int(spawn_ticks.get(3, -1)) > int(spawn_ticks.get(2, 99999)), "M2_B2_FLANK_LATER_SAME_CONTACT")
		if no_grenade:
			_expect(not won and main.phase == main.Phase.FAILED, "M2_B2_GROUND_EXPLOSIVE_DEPENDENCY")
		elif bad:
			_expect(not won and main.battle_log.terminal_reason == "escape", "M2_B2_REAL_COUNTEREXAMPLE_" + kind)
		else:
			_expect(won, "M2_B2_REAL_WIN_" + kind)
			var last_main := maxi(int(death_ticks.get(1, -1)), int(death_ticks.get(2, -1)))
			_expect(spawn_ticks == {1:0, 2:36, 3:240}, "M2_B2_EXACT_AUTHORED_SPAWN_TICKS")
			_expect(main_contact < 240 and last_main > 240 and int(overlap_observation.get("alive_main", 0)) >= 1 and int(overlap_observation.get("phase", -1)) == main.Phase.WATCHING, "M2_B2_TRUE_ACTIVE_CONTACT_OVERLAP")
			_expect(flank_interaction <= last_main + 120 and int(death_ticks.get(3, 99999)) - last_main <= 240, "M2_B2_FLANK_TAIL_BOUNDED")
			print("M2_B2_TIMELINE plan=%s main_contact=%d flank_spawn=240 main_last_kill=%d flank_first_interaction=%d flank_kill=%d" % [kind, main_contact, last_main, flank_interaction, int(death_ticks.get(3, -1))])
			for id in [1, 2, 3]:
				_expect(spawn_ids.count(id) == 1 and kill_ids.count(id) == 1, "M2_B2_THREE_TARGETS_ONCE")
		if ground and not no_grenade:
			_expect(main.operators[0].grenades == 0, "M2_B2_OPTIONAL_GRENADE_ACTUALLY_CONSUMED")
			var blast: Dictionary = main.battle_log.last_of_type("grenade")
			_expect(int(blast.get("payload", {}).get("hits", 0)) > 0, "M2_B2_GRENADE_REAL_TARGET_HIT")
			var follow_up := false
			for target in blast.get("payload", {}).get("targets", []):
				if float(target.get("damage", 0)) <= 0: continue
				for event in main.battle_log.events:
					if str(event.type) == "fire" and int(event.target_id) == int(target.id) and int(event.tick) >= int(blast.get("tick", 99999)) and kill_ids.has(int(target.id)):
						follow_up = true
			_expect(follow_up or bad, "M2_B2_EXPLOSIVE_WOUND_FIREARM_FINISH")
		print("M2_B2_SPAWN_TICKS kind=%s ticks=%s" % [kind, spawn_ticks])
		print("M2_B2_RESULT kind=%s won=%s terminal=%s shots=%s kills=%s remaining=%s grenade=%d" % [kind, won, main.battle_log.terminal_reason, shots, kill_ids, _rounds(main), main.operators[0].grenades])
		results.append({"kind": kind, "won": won})
	if failures.is_empty():
		print("M2_SINGLE_CONTACT_GATE_OK scenarios=7 real_resources=1 high_and_ground=1 nearby=1 counterexamples=1") if probe == "" else print("M2_B2_PROBE_OK case=" + probe)
		quit(0)
	else:
		_finish_failed()

func _run_battle(main) -> void:
	for tick in MAX_SIM_TICKS:
		if main.phase == main.Phase.SWEEP: main._on_sweep_commit()
		if main.phase != main.Phase.WATCHING: return
		main._sim_tick()
		if overlap_observation.is_empty():
			for event in main.battle_log.events:
				if str(event.type) == "spawn" and int(event.actor_id) == 3:
					var alive_main := 0
					for enemy in main.enemies:
						if enemy.alive and enemy.label_id in [1,2]: alive_main += 1
					overlap_observation = {"phase": main.phase, "alive_main": alive_main}
					break
	_fail("M2_B2_SIMULATION_GUARD")
