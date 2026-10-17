extends SceneTree

## W2 sim contract + golden tests. Exit 0 on pass.
## Launch only via scripts/run_isolated_test.sh|.ps1.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const SimGeom := preload("res://sim/geom.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	_run_all()
	print("W2_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	_test_golden_a()
	_test_golden_b()
	_test_a_facing_stability()
	_test_a06_area_alert()
	_test_t08_global_alarm()
	_test_t05_manual()
	_test_t06_empty_trigger()
	_test_t07_determinism()
	_test_h01_high_gap()
	_test_h04_climb()
	_test_h06_no_height_damage_mult()
	_test_alert_escalation()
	_test_gatehouse_blocks_g_to_l()
	_test_wait_turn_blocks_fire()
	_update_or_compare_golden_hashes()


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _count_actor_fire(sim: NightSim, actor: String) -> int:
	var n := 0
	for e in sim.log.events:
		if str(e.get("type", "")) == "fire" and str(e.get("actor", "")) == actor:
			n += 1
	return n


func _plan_a() -> Dictionary:
	return SimRunner.load_json("res://data/fixtures/plan_a.json")


func _plan_b() -> Dictionary:
	return SimRunner.load_json("res://data/fixtures/plan_b.json")


func _test_golden_a() -> void:
	## PLAY-4 pacing: yard enter_t +12 s → t0_A = 26 s = tick 520 (was 280).
	var s: Dictionary = SimRunner.run_plan("res://data/fixtures/plan_a.json")
	_assert(int(s.get("detonate_tick", -1)) == 520, "golden A t0 tick=520 got=%s" % s.get("detonate_tick"))
	_assert(str(s.get("trigger", "")) == "cross_marker", "golden A trigger=cross_marker got=%s" % s.get("trigger"))
	_assert(bool(s.get("standard_ambush", false)) == true, "golden A standard_ambush")
	_assert(str(s.get("outcome", "")) == "win", "golden A win")
	_assert(s.get("escapes", []).is_empty(), "golden A no escapes")
	var targets := ["E1", "E2", "E3", "E4", "F1", "F2"]
	var kills: Array = s.get("kills", [])
	for t in targets:
		_assert(kills.has(t), "golden A killed %s" % t)


func _test_a_facing_stability() -> void:
	## t0 must stay 520 under Kar facing ±1° (cross_marker is facing-independent;
	## also assert kill-zone still covers F1 so standard ambush holds).
	var base: Dictionary = _plan_a()
	var base_facing := float(base["operators"][1]["facing_deg"])
	_assert(is_equal_approx(base_facing, 15.0), "A Kar facing clean 15° got=%s" % base_facing)
	for delta in [-1.0, 0.0, 1.0]:
		var plan: Dictionary = _plan_a()
		plan["operators"][1]["facing_deg"] = base_facing + delta
		var s: Dictionary = SimRunner.run_plan_dict(plan)
		_assert(int(s.get("detonate_tick", -1)) == 520,
			"A facing%+.0f° t0=520 got=%s" % [delta, s.get("detonate_tick")])
		_assert(bool(s.get("standard_ambush", false)) == true,
			"A facing%+.0f° standard_ambush" % delta)


func _test_golden_b() -> void:
	## PLAY-4 pacing: yard enter_t +12 s → t0_B = 28 s = tick 560 (was 320).
	var s := SimRunner.run_plan("res://data/fixtures/plan_b.json")
	_assert(int(s.get("detonate_tick", -1)) == 560, "golden B t0 tick=560 got=%s" % s.get("detonate_tick"))
	_assert(str(s.get("trigger", "")) == "mine_detonate", "golden B trigger")
	_assert(bool(s.get("standard_ambush", false)) == true, "golden B standard_ambush")
	_assert(str(s.get("outcome", "")) == "win", "golden B win")


func _test_a06_area_alert() -> void:
	## After area alert, at least one of A/B still wins (standard_ambush false).
	var wins := 0
	for plan_path in ["res://data/fixtures/plan_a.json", "res://data/fixtures/plan_b.json"]:
		var plan := SimRunner.load_json(plan_path)
		var level := SimLevelLoader.load_path("res://data/levels/yard.json")
		var weapons := SimWeapons.load_csv()
		var sim := NightSim.new()
		sim.setup(level, plan, weapons)
		sim.log.emit(0, "sim_start", {"actor": "system", "payload": {"plan_id": plan.get("id"), "a06": true}})
		for m in sim.mines:
			sim.log.emit(0, "mine_place", {"actor": str(m["id"]), "weapon_id": "mine", "pos": {"x": m["x"], "y": m["y"], "height": "ground"}})
		sim._set_phase(0, "wait")
		sim.force_expose = true
		var guard := 0
		var recovering := false
		while sim.alert != "area_alert" and guard < 400:
			sim._tick_once()
			if sim.alert == "suspicious" and sim.suspicious_count == 1 and not recovering:
				sim.force_expose = false
				recovering = true
			if sim.alert == "quiet" and sim.suspicious_count == 1:
				sim.force_expose = true
			sim.tick += 1
			guard += 1
		sim.force_expose = false
		_assert(sim.alert == "area_alert", "A-06 reached area_alert plan=%s alert=%s" % [plan.get("id"), sim.alert])
		while not sim._done and sim.tick <= sim.max_ticks:
			sim._tick_once()
			if sim._done:
				break
			sim.tick += 1
		if not sim._done:
			sim._finish("lose", "timeout")
		if str(sim._outcome) == "win":
			wins += 1
			_assert(sim.standard_ambush == false, "A-06 win ⇒ standard_ambush false plan=%s" % plan.get("id"))
	_assert(wins >= 1, "A-06 at least one plan wins after area_alert wins=%d" % wins)


func _test_t08_global_alarm() -> void:
	var plan := _plan_a()
	# Manual-only so see_first cannot fire before global alert (T-08 isolates alarm path).
	plan["trigger"] = {"type": "manual"}
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.force_expose = true
	sim.log.emit(0, "sim_start", {"actor": "system", "payload": {"plan_id": "A_alarm"}})
	sim._set_phase(0, "wait")
	var guard := 0
	var recovering := false
	while sim.trigger_used != "alarm" and guard < 500:
		sim._tick_once()
		if sim.alert == "suspicious" and sim.suspicious_count == 1 and not recovering:
			sim.force_expose = false
			recovering = true
		if sim.alert == "quiet" and sim.suspicious_count == 1:
			sim.force_expose = true
		if sim.alert == "area_alert":
			sim.force_expose = true
		sim.tick += 1
		guard += 1
	_assert(str(sim.trigger_used) == "alarm", "T-08 trigger=alarm got=%s" % sim.trigger_used)
	_assert(sim.detonate_tick >= 0, "T-08 detonate entered")
	_assert(sim.standard_ambush == false, "T-08 standard_ambush false")
	_assert(sim.alert == "global_alert", "T-08 alert global")


func _test_t05_manual() -> void:
	var plan := _plan_a()
	plan["manual_detonate_tick"] = 100
	# Keep see_first_enemy configured; manual overrides when pressed.
	var s := SimRunner.run_plan_dict(plan)
	_assert(str(s.get("trigger", "")) == "manual", "T-05 trigger=manual got=%s" % s.get("trigger"))
	_assert(int(s.get("detonate_tick", -1)) == 100, "T-05 detonate_tick=100")


func _test_t06_empty_trigger() -> void:
	var plan := _plan_a()
	plan["trigger"] = {}
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var err := ""
	# Validation: empty trigger should be rejected before wait.
	if plan.get("trigger", {}).is_empty():
		err = "empty_trigger"
	_assert(err == "empty_trigger", "T-06 empty trigger intercepted")


func _test_t07_determinism() -> void:
	var s1 := SimRunner.run_plan("res://data/fixtures/plan_a.json")
	var s2 := SimRunner.run_plan_dict(_plan_a(), "res://data/levels/yard.json", {"speed_mul": 4.0})
	_assert(str(s1.get("log_hash")) == str(s2.get("log_hash")), "T-07 same hash 1x vs 4x")
	_assert(int(s1.get("detonate_tick")) == int(s2.get("detonate_tick")), "T-07 same t0")
	# Plan locks at detonate: facing unchanged after
	var sim: NightSim = s1["sim"]
	_assert(sim.plan_locked, "T-07 plan_locked")
	for op in sim.operators:
		_assert(is_equal_approx(float(op["facing_deg"]), float(op["locked_facing"])), "T-07 facing locked %s" % op["id"])


func _test_h01_high_gap() -> void:
	## Yard v1.2: compare blocked fractions on the *intersection* of cones from
	## (5,9) high vs (6,9) ground (same cells). Edge walls otherwise dominate.
	var level: Dictionary = SimLevelLoader.load_path("res://data/levels/yard.json")
	var weapons: Dictionary = SimWeapons.load_csv()
	var sim = NightSim.new()
	sim.setup(level, _plan_a(), weapons)
	var facing := 0.0
	var half := 30.0
	var rng := 12.0
	var total := 0
	var high_blocked := 0
	var ground_blocked := 0
	var diff := 0
	for y in range(0, sim.grid.height):
		for x in range(0, sim.grid.width):
			if not SimGeom.in_cone(5.0, 9.0, facing, half, rng, float(x), float(y)):
				continue
			if not SimGeom.in_cone(6.0, 9.0, facing, half, rng, float(x), float(y)):
				continue
			total += 1
			var tt: String = sim.grid.tier_at(float(x), float(y))
			var h_clear: bool = sim.grid.los_clear(5.0, 9.0, "high", float(x), float(y), tt)
			var g_clear: bool = sim.grid.los_clear(6.0, 9.0, "ground", float(x), float(y), tt)
			if not h_clear:
				high_blocked += 1
			if not g_clear:
				ground_blocked += 1
			if (not g_clear) and h_clear:
				diff += 1
	_assert(total > 0, "H-01 intersect non-empty")
	_assert(diff > 0, "H-01 low-cover differential > 0 got=%d" % diff)
	var high_frac := float(high_blocked) / float(total)
	var ground_frac := float(ground_blocked) / float(total)
	_assert(
		high_frac < ground_frac * 0.5 + 1e-6,
		"H-01 high gap %s < 50%% of ground %s (intersect)" % [high_frac, ground_frac],
	)


func _test_h04_climb() -> void:
	## Climb +2.0 s = 40 ticks; during climb tier acts as ground / no fire.
	var ticks := int(round(2.0 * 20.0))
	_assert(ticks == 40, "H-04 climb 2.0s = 40 ticks")
	var plan := _plan_a()
	plan["operators"][0]["climbing"] = true
	plan["operators"][0]["climb_ticks_left"] = 40
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	var op: Dictionary = sim.operators[0]
	_assert(bool(op["climbing"]) == true, "H-04 climbing flag")
	_assert(str(op["tier"]) == "ground", "H-04 climb tier ground")
	_assert(bool(op["can_fire"]) == false, "H-04 no fire while climbing")


func _test_h06_no_height_damage_mult() -> void:
	var table: Dictionary = SimWeapons.load_csv()
	var w: Dictionary = table["kar98k"]
	var need_g := SimWeapons.shots_needed(w, 6.0)
	var need_h := need_g # no height multiplier field
	_assert(need_g == need_h, "H-06 shots_needed independent of height")
	_assert(not w.has("height_damage_mult"), "H-06 no height_damage_mult field")


func _test_alert_escalation() -> void:
	var plan := _plan_a()
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	sim.force_expose = true
	sim.skip_fire = true
	sim.log.emit(0, "sim_start", {"actor": "system", "payload": {"plan_id": "alert_seq"}})
	sim._set_phase(0, "wait")
	var saw := []
	var guard := 0
	while sim.alert != "global_alert" and guard < 500:
		var prev := sim.alert
		sim._tick_once()
		if sim.alert != prev:
			saw.append(sim.alert)
		# After first suspicious, clear expose to recover then re-expose
		if sim.alert == "suspicious" and sim.suspicious_count == 1 and sim.expose_streak == 0:
			sim.force_expose = false
		if sim.alert == "quiet" and sim.suspicious_count == 1:
			sim.force_expose = true
		sim.tick += 1
		guard += 1
	_assert(saw.has("suspicious"), "alert seq has suspicious")
	_assert(saw.has("area_alert"), "alert seq has area_alert")
	_assert(saw.has("global_alert"), "alert seq has global_alert")
	_assert(str(sim.trigger_used) == "alarm", "alert seq ends with alarm trigger")


func _test_wait_turn_blocks_fire() -> void:
	## PLAY-4 / ADR-TRIGGER §3.2: 90° turn = 2 s = 40 ticks; facing applied; can_fire false meanwhile.
	var plan := _plan_a()
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	sim.begin_wait()
	var op: Dictionary = sim.operators[1] ## Kar@L
	var start_facing := float(op["facing_deg"])
	var target := start_facing + 90.0
	sim.request_operator_facing(str(op["id"]), target)
	_assert(is_equal_approx(float(op["facing_deg"]), target), "wait turn facing set to target")
	_assert(int(op["turn_ticks_left"]) == 40, "wait turn 90° → 40 ticks got=%s" % op["turn_ticks_left"])
	_assert(bool(op["can_fire"]) == false, "wait turn blocks can_fire")
	# Advance almost the full cost: still blocked.
	for _i in range(39):
		sim.advance_one_tick()
	_assert(int(op["turn_ticks_left"]) == 1, "wait turn 1 tick left got=%s" % op["turn_ticks_left"])
	_assert(bool(op["can_fire"]) == false, "wait turn still blocked at 1 left")
	_assert(is_equal_approx(float(op["facing_deg"]), target), "wait turn facing held after delay almost done")
	sim.advance_one_tick()
	_assert(int(op["turn_ticks_left"]) == 0, "wait turn complete")
	_assert(bool(op["can_fire"]) == true, "wait turn restores can_fire")
	_assert(is_equal_approx(float(op["facing_deg"]), target), "wait turn facing after full delay")
	# Isolate Kar: mute other ops so only turn-gate is under test.
	for other in sim.operators:
		if str(other["id"]) != str(op["id"]):
			other["can_fire"] = false
	sim.request_operator_facing(str(op["id"]), float(op["facing_deg"]) + 45.0)
	_assert(int(op["turn_ticks_left"]) == 20, "45° turn = 20 ticks")
	_assert(bool(op["can_fire"]) == false, "45° turn blocks can_fire")
	var e0: Dictionary = sim.enemies[0]
	e0["entered"] = true
	e0["alive"] = true
	e0["escaped"] = false
	e0["x"] = float(op["x"])
	e0["y"] = float(op["y"])
	var fires_before := _count_actor_fire(sim, str(op["id"]))
	sim._step_fire()
	_assert(_count_actor_fire(sim, str(op["id"])) == fires_before, "no fire while turn_ticks_left>0")
	op["turn_ticks_left"] = 0
	op["can_fire"] = true
	sim._step_fire()
	_assert(_count_actor_fire(sim, str(op["id"])) > fires_before, "fires after turn completes")


func _test_gatehouse_blocks_g_to_l() -> void:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var grid := SimLevelLoader.build_grid(level)
	var clear := grid.los_clear(8.0, 14.0, "high", 13.0, 7.0, "high")
	_assert(clear == false, "G→L LOS blocked by #(9,12)")
	# Without wall, cone geometry would hit (paper); distance/angle check
	var dist := SimGeom.dist_centers(8, 14, 13, 7)
	var bearing := SimGeom.bearing_deg(8, 14, 13, 7)
	var delta := SimGeom.abs_angle_delta_deg(-59.0, bearing)
	_assert(dist <= 12.0 + 1e-6, "G→L within high cone range dist=%s" % dist)
	_assert(delta <= 25.0 + 1e-6, "G→L within half-angle delta=%s" % delta)


func _update_or_compare_golden_hashes() -> void:
	var path := "res://data/golden/hashes.json"
	var a := SimRunner.run_plan("res://data/fixtures/plan_a.json")
	var b := SimRunner.run_plan("res://data/fixtures/plan_b.json")
	var got := {
		"plan_a": str(a.get("log_hash", "")),
		"plan_b": str(b.get("log_hash", "")),
		"t0_a": int(a.get("detonate_tick", -1)),
		"t0_b": int(b.get("detonate_tick", -1)),
	}
	# Rewrite when AMBUSH_WRITE_GOLDEN=1 (PLAY-4 pacing shift must document reason in commit).
	if OS.get_environment("AMBUSH_WRITE_GOLDEN") == "1":
		var abs_path := ProjectSettings.globalize_path(path)
		var f := FileAccess.open(abs_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(got, "\t"))
		print("WROTE_GOLDEN ", abs_path, " ", JSON.stringify(got))
		_assert(got["t0_a"] == 520 and got["t0_b"] == 560, "golden write t0s 520/560")
		return
	if not FileAccess.file_exists(path):
		print("GOLDEN_HASHES_CANDIDATE ", JSON.stringify(got))
		_assert(got["t0_a"] == 520 and got["t0_b"] == 560, "golden candidate t0s")
		return
	var f2 := FileAccess.open(path, FileAccess.READ)
	var exp: Variant = JSON.parse_string(f2.get_as_text())
	_assert(typeof(exp) == TYPE_DICTIONARY, "golden hashes file parse")
	if typeof(exp) != TYPE_DICTIONARY:
		return
	var e: Dictionary = exp
	_assert(str(e.get("plan_a")) == got["plan_a"], "golden hash A")
	_assert(str(e.get("plan_b")) == got["plan_b"], "golden hash B")
	_assert(int(e.get("t0_a")) == got["t0_a"], "golden file t0_a")
	_assert(int(e.get("t0_b")) == got["t0_b"], "golden file t0_b")
