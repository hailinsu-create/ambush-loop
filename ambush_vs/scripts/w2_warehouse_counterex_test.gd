extends SceneTree

## T9: warehouse named counterexamples (W2 family).
## Default hard tier (assist OFF) must win both fixtures with standard_ambush,
## at least two named cases must lose outright, and the remaining named cases
## must still satisfy the same D.3 gate as the yard
## (escape>=1 OR clear_s +50% OR injury +50% vs same-plan BASE).
## Full table -> ambush_vs/docs/WAREHOUSE_P1_RESULTS_20261020.md
## Launch only via scripts/run_isolated_test.sh|.ps1.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const SimLevels := preload("res://sim/levels.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const ReviewBuilder := preload("res://sim/review_builder.gd")
const C := preload("res://sim/constants.gd")

const TICK_HZ := 20
const LEVEL_ID := "warehouse"
## 代定，盲测后可调：严格判负组（至少两例）。
const STRICT_LOSE_IDS := ["F-WA30", "W-WA-MG→Kar"]
## 其余命名反例：必须满足 D.3（逃脱≥1 / 清场 +50% / 受伤 +50%）。
const HOLDING_IDS := ["T-WA-4", "S-WA-no-dock"]

var _failed := 0
var _passed := 0
var _rows: Array = []
var _t0_a := -1
var _t0_b := -1


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	_run_all()
	print("W2_WAREHOUSE_COUNTEREX_SUMMARY passed=", _passed, " failed=", _failed)
	print("WAREHOUSE_COUNTEREX_ROWS_BEGIN")
	for r in _rows:
		print(JSON.stringify(r))
	print("WAREHOUSE_COUNTEREX_ROWS_END")
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _run_all() -> void:
	var golden := _read_golden()
	_t0_a = int(golden.get("t0_a", -1))
	_t0_b = int(golden.get("t0_b", -1))
	_test_level_contract(golden)
	var on_matrix := _measure_matrix(true)
	var off_matrix := _measure_matrix(false)
	_rows.append_array(off_matrix.values())
	_rows.append_array(on_matrix.values())
	_assert_baselines(off_matrix)
	_assert_holding_gates(off_matrix)
	_assert_strict_loses(off_matrix)
	_print_comparison(off_matrix, on_matrix)


func _read_golden() -> Dictionary:
	return SimRunner.load_json(SimLevels.golden_path_for(LEVEL_ID))


func _test_level_contract(golden: Dictionary) -> void:
	var level := SimLevelLoader.load_path(SimLevels.path_for(LEVEL_ID))
	_assert(not level.is_empty(), "warehouse level loads")
	_assert(SimLevelLoader.validate(level).is_empty(), "warehouse passes SimLevelLoader.validate")
	_assert(str(level.get("id", "")) == LEVEL_ID, "warehouse id matches registry")
	_assert(int(level.get("version", 0)) == 1, "warehouse version=1")
	var grid: Dictionary = level.get("grid", {})
	_assert(int(grid.get("width", 99)) <= 24 and int(grid.get("height", 99)) <= 16,
		"warehouse grid <=24x16 got=%sx%s" % [grid.get("width"), grid.get("height")])
	var high_slots: Array = level.get("high_slots", [])
	_assert(not high_slots.is_empty(), "warehouse has high_slots")
	var has_access := false
	for hs in high_slots:
		if hs.has("access") and not (hs.get("access", []) as Array).is_empty():
			has_access = true
	_assert(has_access, "warehouse high slot declares T5 access")
	var exits: Array = level.get("exits", [])
	_assert(exits.size() >= 2, "warehouse has >=2 exits got=%s" % exits.size())
	_assert(_t0_a > 0 and _t0_b > 0, "warehouse golden t0 present a=%s b=%s" % [_t0_a, _t0_b])
	_assert(str(golden.get("plan_a", "")) != "" and str(golden.get("plan_b", "")) != "",
		"warehouse golden has both plan hashes")


func _plan_a() -> Dictionary:
	return SimRunner.load_json(str(SimLevels.fixtures_for(LEVEL_ID)["plan_a"]))


func _plan_b() -> Dictionary:
	return SimRunner.load_json(str(SimLevels.fixtures_for(LEVEL_ID)["plan_b"]))


func _metrics(summary: Dictionary, events: Array) -> Dictionary:
	var m := ReviewBuilder._compute_metrics(summary, events)
	m["outcome"] = str(summary.get("outcome", ""))
	m["wounded_n"] = (summary.get("wounded", []) as Array).size()
	m["dead_ops_n"] = (summary.get("dead_ops", []) as Array).size()
	m["injury_n"] = int(m["wounded_n"]) + int(m["dead_ops_n"])
	m["escape_n"] = int(m.get("escape_n", 0))
	m["detonate_tick"] = int(summary.get("detonate_tick", -1))
	m["standard_ambush"] = bool(summary.get("standard_ambush", false))
	m["trigger"] = str(summary.get("trigger", ""))
	return m


func _run_plan(plan: Dictionary, soft_cap: bool) -> Dictionary:
	var level := SimLevelLoader.load_path(SimLevels.path_for(LEVEL_ID))
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	sim.enemy_return_soft_cap = soft_cap
	var summary: Dictionary = sim.run()
	var m := _metrics(summary, sim.log.events)
	m["soft_cap"] = soft_cap
	return m


func _holds(case_m: Dictionary, base_m: Dictionary) -> Dictionary:
	## D.3: escape>=1 OR clear_s +50% OR injury +50% (vs same-plan baseline).
	var esc := int(case_m.get("escape_n", 0))
	var clear := float(case_m.get("clear_s", -1.0))
	var inj := int(case_m.get("injury_n", 0))
	var base_clear := float(base_m.get("clear_s", -1.0))
	var base_inj := int(base_m.get("injury_n", 0))
	var clear_ok := base_clear > 0.0 and clear >= 0.0 and clear >= base_clear * 1.5
	var inj_ok := false
	if base_inj <= 0:
		inj_ok = inj >= 1
	else:
		inj_ok = float(inj) >= float(base_inj) * 1.5
	var esc_ok := esc >= 1
	return {
		"holds_strict": esc_ok or clear_ok or inj_ok,
		"via_escape": esc_ok,
		"via_clear_50": clear_ok,
		"via_injury_50": inj_ok,
		"base_clear_s": base_clear,
		"base_injury_n": base_inj,
	}


func _row(id: String, soft: bool, m: Dictionary, hold: Dictionary = {}) -> Dictionary:
	var out := {
		"id": id,
		"soft_cap": soft,
		"outcome": m.get("outcome"),
		"escape_n": m.get("escape_n"),
		"clear_s": m.get("clear_s"),
		"injury_n": m.get("injury_n"),
		"wounded_n": m.get("wounded_n"),
		"dead_ops_n": m.get("dead_ops_n"),
		"detonate_tick": m.get("detonate_tick"),
		"standard_ambush": m.get("standard_ambush"),
		"trigger": m.get("trigger"),
	}
	for k in hold.keys():
		out[k] = hold[k]
	return out


func _measure_matrix(soft: bool) -> Dictionary:
	var out: Dictionary = {}
	var base_a := _run_plan(_plan_a(), soft)
	var base_b := _run_plan(_plan_b(), soft)
	out["BASE-A"] = _row("BASE-A", soft, base_a)
	out["BASE-B"] = _row("BASE-B", soft, base_b)

	var pa_f := _plan_a()
	pa_f["operators"][0]["facing_deg"] = float(pa_f["operators"][0]["facing_deg"]) + 30.0
	var m_f := _run_plan(pa_f, soft)
	out["F-WA30"] = _row("F-WA30", soft, m_f, _holds(m_f, base_a))

	var pa_t := _plan_a()
	pa_t["trigger"] = {"type": "manual"}
	pa_t["manual_detonate_tick"] = _t0_a - 4 * TICK_HZ
	pa_t["mines"] = []
	var m_t := _run_plan(pa_t, soft)
	out["T-WA-4"] = _row("T-WA-4", soft, m_t, _holds(m_t, base_a))

	var pa_w := _plan_a()
	pa_w["operators"][0]["weapon_id"] = "kar98k"
	var m_w := _run_plan(pa_w, soft)
	out["W-WA-MG→Kar"] = _row("W-WA-MG→Kar", soft, m_w, _holds(m_w, base_a))

	var pa_s := _plan_a()
	pa_s["operators"].remove_at(0)
	var m_s := _run_plan(pa_s, soft)
	out["S-WA-no-dock"] = _row("S-WA-no-dock", soft, m_s, _holds(m_s, base_a))
	return out


func _assert_baselines(off_m: Dictionary) -> void:
	var ba: Dictionary = off_m["BASE-A"]
	var bb: Dictionary = off_m["BASE-B"]
	_assert(str(ba.get("outcome")) == "win", "BASE-A default assist OFF wins")
	_assert(str(bb.get("outcome")) == "win", "BASE-B default assist OFF wins")
	_assert(bool(ba.get("standard_ambush", false)), "BASE-A default standard_ambush")
	_assert(bool(bb.get("standard_ambush", false)), "BASE-B default standard_ambush")
	_assert(int(ba.get("detonate_tick", -1)) == _t0_a, "BASE-A t0=%d matches golden" % _t0_a)
	_assert(int(bb.get("detonate_tick", -1)) == _t0_b, "BASE-B t0=%d matches golden" % _t0_b)


func _assert_holding_gates(off_m: Dictionary) -> void:
	for id in HOLDING_IDS:
		var r: Dictionary = off_m[id]
		_assert(bool(r.get("holds_strict", false)),
			"holding gate %s must stay D.3-true under default assist OFF" % id)


func _assert_strict_loses(off_m: Dictionary) -> void:
	_assert(STRICT_LOSE_IDS.size() >= 2, "warehouse strict group has >=2 cases")
	for id in STRICT_LOSE_IDS:
		var r: Dictionary = off_m[id]
		var outcome := str(r.get("outcome", ""))
		_assert(outcome == "lose", "strict %s outcome=lose got=%s" % [id, outcome])
		var evidence := (
			int(r.get("escape_n", 0)) >= 1
			or int(r.get("dead_ops_n", 0)) >= 1
			or float(r.get("clear_s", -1.0)) < 0.0
		)
		_assert(evidence, "strict %s has fail evidence esc=%s dead=%s clear=%s" % [
			id, r.get("escape_n"), r.get("dead_ops_n"), r.get("clear_s")])
		_assert(bool(r.get("standard_ambush", true)) == false,
			"strict %s is not a standard ambush" % id)


func _print_comparison(off_m: Dictionary, on_m: Dictionary) -> void:
	print("WAREHOUSE_COUNTEREX_COMPARE_BEGIN")
	print("id|off_outcome|off_esc|off_clear_s|off_inj|off_dead|on_outcome|on_esc|on_clear_s|on_inj|on_dead|off_holds")
	for id in off_m.keys():
		var off: Dictionary = off_m[id]
		var on: Dictionary = on_m[id]
		print("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
			id,
			off.get("outcome"), off.get("escape_n"), off.get("clear_s"), off.get("injury_n"), off.get("dead_ops_n"),
			on.get("outcome"), on.get("escape_n"), on.get("clear_s"), on.get("injury_n"), on.get("dead_ops_n"),
			off.get("holds_strict", "-"),
		])
	print("WAREHOUSE_COUNTEREX_COMPARE_END")
