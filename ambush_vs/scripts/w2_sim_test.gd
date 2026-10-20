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


func _count_events(sim: NightSim, type: String, actor: String = "") -> int:
	var n := 0
	for e in sim.log.events:
		if str(e.get("type", "")) != type:
			continue
		if actor != "" and str(e.get("actor", "")) != actor:
			continue
		n += 1
	return n


func _event_tick(sim: NightSim, type: String, actor: String = "") -> int:
	for e in sim.log.events:
		if str(e.get("type", "")) != type:
			continue
		if actor != "" and str(e.get("actor", "")) != actor:
			continue
		return int(e.get("tick", -1))
	return -1


func _find_neighbor_of_tier(grid, cx: int, cy: int, want: String) -> Vector2i:
	## Fixed 8-neighbour order. walkable() guards against walls/structures, which
	## report tier "ground" through tier_at() and would otherwise be picked.
	var order := [
		Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
	]
	for d in order:
		var nx: int = cx + d.x
		var ny: int = cy + d.y
		if grid.walkable(nx, ny) and grid.tier_at(float(nx), float(ny)) == want:
			return Vector2i(nx, ny)
	return Vector2i(-1, -1)


func _find_first_cell_of_tier(grid, want: String) -> Vector2i:
	for y in range(grid.height):
		for x in range(grid.width):
			if grid.walkable(x, y) and grid.tier_at(float(x), float(y)) == want:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


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
	## P0-2: published Kar aim is 巷口 (~11°), not the old 15° cone-edge guess.
	var base: Dictionary = _plan_a()
	var base_facing := float(base["operators"][1]["facing_deg"])
	_assert(is_equal_approx(base_facing, 11.0), "A Kar facing clean 11° got=%s" % base_facing)
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
	## T5 contract: climb +2.0 s = 40 ticks. While climbing the operator runs at the
	## departure cell (climb_from) at ground tier, cannot fire, and is exposed at the
	## departure cell/ground (no ×1.5 silhouette). On finish it snaps to the target
	## cell / that cell's tier and regains fire (unless a turn cooldown is running).
	## ground→high and high→ground share one path. Fields are opt-in: a plan without
	## `climbing` is byte-identical to the golden stream.
	var ticks := int(round(2.0 * 20.0))
	_assert(ticks == 40, "H-04 climb 2.0s = 40 ticks")

	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var grid := SimLevelLoader.build_grid(level)
	var weapons := SimWeapons.load_csv()

	## --- Up-climb: operators[0] (op_mg42) target (5,9) high, from an adjacent ground cell. ---
	var op0_x := int(float(_plan_a()["operators"][0]["x"]))
	var op0_y := int(float(_plan_a()["operators"][0]["y"]))
	var op0_tier := str(_plan_a()["operators"][0]["tier"])
	_assert(op0_tier == "high", "H-04 operators[0] starts high got=%s" % op0_tier)
	var up_from := _find_neighbor_of_tier(grid, op0_x, op0_y, "ground")
	_assert(up_from.x >= 0, "H-04 found ground neighbour for high op")

	var up := _plan_a()
	up["operators"][0]["climbing"] = true
	up["operators"][0]["climb_from"] = {"x": up_from.x, "y": up_from.y}
	# climb_ticks_left intentionally omitted → default derived from CLIMB_COST_S*TICK_HZ.
	var sim := NightSim.new()
	sim.setup(level, up, weapons)
	sim.begin_wait()
	var op: Dictionary = sim.operators[0]

	_assert(bool(op["climbing"]) == true, "H-04 climbing flag")
	_assert(str(op["tier"]) == "ground", "H-04 climb tier ground")
	_assert(bool(op["can_fire"]) == false, "H-04 no fire while climbing")
	_assert(int(op["climb_ticks_left"]) == 40, "H-04 default climb ticks=40 got=%s" % op["climb_ticks_left"])
	_assert(int(op["x"]) == up_from.x and int(op["y"]) == up_from.y,
		"H-04 runs at climb_from got=(%s,%s) want=(%s,%s)" % [op["x"], op["y"], up_from.x, up_from.y])

	## Ticks 1..39: still mid-climb, still at the departure cell.
	for _i in range(39):
		sim.advance_one_tick()
	_assert(bool(op["climbing"]) == true, "H-04 still climbing at 39 ticks")
	_assert(bool(op["can_fire"]) == false, "H-04 still no fire at 39 ticks")
	_assert(int(op["x"]) == up_from.x and int(op["y"]) == up_from.y,
		"H-04 still at climb_from at 39 ticks got=(%s,%s)" % [op["x"], op["y"]])

	## 40th processed tick: climb completes.
	sim.advance_one_tick()
	_assert(bool(op["climbing"]) == false, "H-04 climb ends at 40 ticks")
	_assert(str(op["tier"]) == "high", "H-04 tier target high after climb got=%s" % op["tier"])
	_assert(int(op["x"]) == op0_x and int(op["y"]) == op0_y,
		"H-04 at target after climb got=(%s,%s) want=(%s,%s)" % [op["x"], op["y"], op0_x, op0_y])
	_assert(bool(op["can_fire"]) == true, "H-04 can fire after climb")

	## --- Events: exactly one climb_start + one climb_end; drift-free off-by-one. ---
	_assert(_count_events(sim, "climb_start") == 1, "H-04 one climb_start got=%d" % _count_events(sim, "climb_start"))
	_assert(_count_events(sim, "climb_end") == 1, "H-04 one climb_end got=%d" % _count_events(sim, "climb_end"))
	## climb_start is emitted by begin_wait() (tick 0); climb_end fires on the tick
	## whose _step_climb reaches zero. begin_wait() only announces (no decrement),
	## so the 40 decrements land on processed ticks 0..39 → climb_end tick == 39.
	var end_tick := _event_tick(sim, "climb_end", str(op["id"]))
	_assert(end_tick == ticks - 1, "H-04 climb_end tick=%d (nominal 40, off-by-one) got=%d" % [ticks - 1, end_tick])
	_assert(_event_tick(sim, "climb_start", str(op["id"])) == 0, "H-04 climb_start at tick 0")

	## Default plan (no climbing) must emit no climb_* events and keep the golden hash.
	var gold: Dictionary = SimRunner.load_json("res://data/golden/hashes.json")
	var base: Dictionary = SimRunner.run_plan("res://data/fixtures/plan_a.json")
	var base_sim: NightSim = base["sim"]
	_assert(_count_events(base_sim, "climb_start") == 0 and _count_events(base_sim, "climb_end") == 0,
		"H-04 no-climb plan_a emits no climb_* events")
	_assert(str(base.get("log_hash", "")) == str(gold.get("plan_a", "")),
		"H-04 no-climb plan_a hash matches golden")

	## --- Departure-cell exposure: deterministic probe on the low_wall_pad column. ---
	## Synthetic sentry due -y of x=13, range 3.5: the departure ground cell (13,8)
	## is 4.0 away → out of range (not seen); the high target (13,7) is 5.0 away and
	## is seen only through the ×1.5 night silhouette (5.0 ≤ 3.5×1.5 = 5.25). So a
	## correct climb (ground tier, no silhouette) must not be exposed, whereas the
	## same operator parked on the high target would be.
	var exp_plan := _plan_a()
	exp_plan["operators"][1]["climbing"] = true
	var exp_from := _find_neighbor_of_tier(grid, 13, 7, "ground") ## op_kar_L target (13,7) high
	_assert(exp_from.x == 13 and exp_from.y == 8, "H-04 exposure probe departure=(%d,%d)" % [exp_from.x, exp_from.y])
	exp_plan["operators"][1]["climb_from"] = {"x": exp_from.x, "y": exp_from.y}
	var esim := NightSim.new()
	esim.setup(level, exp_plan, weapons)
	esim.begin_wait()
	var eop: Dictionary = esim.operators[1]
	_assert(int(eop["x"]) == exp_from.x and int(eop["y"]) == exp_from.y, "H-04 exposure op runs at departure")
	esim.sentries = [{
		"id": "t5_probe", "x": 13, "y": 12, "tier": "ground",
		"cone": {"facing_deg": -90.0, "angle_deg": 60.0, "range_cells": 3.5},
	}]
	esim.patrols = []
	_assert(esim._seen_by_observers(13.0, 8.0, "ground") == false, "H-04 probe: departure ground not visible")
	_assert(esim._seen_by_observers(13.0, 7.0, "high") == true, "H-04 probe: target high visible via silhouette")
	_assert(esim._step_vision_expose() == false, "H-04 climbing op not exposed (departure ground, no silhouette)")

	## --- Down-climb (leave high): ground target, high departure. ---
	var down_plan := _plan_a()
	var down_to := _find_first_cell_of_tier(grid, "high") ## op_mp40 target (11,2) is ground
	_assert(down_to.x >= 0 and str(_plan_a()["operators"][2]["tier"]) == "ground", "H-04 down op target is ground")
	down_plan["operators"][2]["climbing"] = true
	down_plan["operators"][2]["climb_from"] = {"x": down_to.x, "y": down_to.y}
	var dsim := NightSim.new()
	dsim.setup(level, down_plan, weapons)
	dsim.begin_wait()
	var dop: Dictionary = dsim.operators[2]
	_assert(str(dop["tier"]) == "ground" and not bool(dop["can_fire"]), "H-04 down-climb mid: ground/no fire")
	for _i in range(40):
		dsim.advance_one_tick()
	_assert(bool(dop["climbing"]) == false, "H-04 down-climb ends")
	_assert(str(dop["tier"]) == "ground", "H-04 down-climb tier ground at target")
	_assert(int(dop["x"]) == 11 and int(dop["y"]) == 2, "H-04 down-climb at target got=(%s,%s)" % [dop["x"], dop["y"]])

	## --- Countdown gate: not just a data tag — one tick left must flip state. ---
	var gate := _plan_a()
	gate["operators"][0]["climbing"] = true
	gate["operators"][0]["climb_from"] = {"x": up_from.x, "y": up_from.y}
	gate["operators"][0]["climb_ticks_left"] = 1
	var gsim := NightSim.new()
	gsim.setup(level, gate, weapons)
	gsim.begin_wait()
	var gop: Dictionary = gsim.operators[0]
	_assert(bool(gop["can_fire"]) == false, "H-04 gate: blocked with 1 tick left")
	gsim.advance_one_tick()
	_assert(bool(gop["can_fire"]) == true, "H-04 gate: fire after final tick")
	_assert(str(gop["tier"]) == "high", "H-04 gate: tier resolves to target high got=%s" % gop["tier"])

	## --- Detonate during climb: alarm at tick 0 must not unlock mid-climb fire. ---
	var det := _plan_a()
	det["start_alert"] = "global_alert" ## T4 carry: arms trigger=alarm on the first WAIT tick
	det["operators"][0]["climbing"] = true
	det["operators"][0]["climb_from"] = {"x": up_from.x, "y": up_from.y}
	var detsim := NightSim.new()
	detsim.setup(level, det, weapons)
	detsim.begin_wait()
	var detop: Dictionary = detsim.operators[0]
	for _i in range(39):
		detsim.advance_one_tick()
	_assert(int(detsim.detonate_tick) == 0, "H-04 detonate-in-climb at tick 0 got=%d" % detsim.detonate_tick)
	_assert(bool(detop["climbing"]) == true and not bool(detop["can_fire"]), "H-04 detonate-in-climb still climbing/no fire")
	_assert(_count_events(detsim, "fire", str(detop["id"])) == 0, "H-04 no mid-climb fire while detonated")


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
	# PLAY-6: ammo is RPM-gated (not per-tick); prime one round so a single step can fire.
	op["fire_accum"] = 0.999
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
