extends SceneTree

## P0-1 / D.3 counterexample gates (W2 family) + T6 return-fire difficulty.
## Asserts: (1) measurement harness in both difficulty tiers; (2) currently-holding
## D.3 gates stay green under the new default (assist OFF); (3) known non-holding
## cases stay documented; (4) four alert tiers still salvage ≥1 plan on OFF.
## Full matrix → ambush_vs/docs/COUNTEREX_P0_1_RESULTS_20261017.md
## Launch only via scripts/run_isolated_test.sh|.ps1.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const ReviewBuilder := preload("res://sim/review_builder.gd")
const C := preload("res://sim/constants.gd")

const TICK_HZ := 20
const T0_A := 520
const T0_B := 560

## T7 strict group: these four key mistakes must end in outcome=="lose" on the
## default hard tier. (They used to be win and only satisfied D.3 on paper.)
## 代定，盲测后可调：调 STRICT_LOSE_IDS 后同步结果页与 yard_paper_v1_7。
const STRICT_LOSE_IDS := ["F-A60", "T-A+2", "T-A+4", "W-A-MG→Kar"]
## T7 transition gate (owner-defaulted): if a strict case cannot be made to lose,
## it may pass only as win + standard_ambush==false + grade C + a review cause
## naming the timing/geometry mistake. Target is empty; T-A+4 must never be standard.
## 代定，盲测后可调：关掉即恢复“严判组必须全 lose”。
const COUNTEREX_TRANSITION_GATE := true
## 代定，盲测后可调：逐例登记走过渡门的用例（当前为空 = 全部已判负）。
const TRANSITION_IDS := []
## Cases that satisfy D.3 under the new default (assist OFF; strict three-criterion D.3).
const HOLDING_IDS := [
	"F-A30",
	"F-B30", "F-B60",
	"T-A-4", "T-A-2",
	"T-B-4", "T-B-2", "T-B+2", "T-B+4",
	"S-unscout-east",
]
## Cases that do NOT satisfy D.3 under assist OFF (document; watch regressions).
const PENDING_IDS := []

var _failed := 0
var _passed := 0
var _rows: Array = [] ## measurement rows for summary print


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	_run_all()
	print("W2_COUNTEREX_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	print("COUNTEREX_ROWS_BEGIN")
	for r in _rows:
		print(JSON.stringify(r))
	print("COUNTEREX_ROWS_END")
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _run_all() -> void:
	_test_soft_cap_default()
	_test_plan_key_roundtrip()
	var on_matrix := _measure_matrix(true)
	var off_matrix := _measure_matrix(false)
	_rows.append_array(off_matrix.values())
	_rows.append_array(on_matrix.values())
	_assert_baselines(on_matrix, off_matrix)
	_assert_holding_gates(off_matrix)
	_assert_strict_loses(off_matrix)
	_assert_transition_gate(off_matrix)
	_assert_pending_documented(off_matrix)
	_assert_alert_wins(on_matrix, off_matrix)
	_assert_soft_cap_control_differs(on_matrix, off_matrix)
	_print_comparison(off_matrix, on_matrix)


func _plan_a() -> Dictionary:
	return SimRunner.load_json("res://data/fixtures/plan_a.json")


func _plan_b() -> Dictionary:
	return SimRunner.load_json("res://data/fixtures/plan_b.json")


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
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.enemy_return_soft_cap = soft_cap
	var summary: Dictionary = sim.run()
	var m := _metrics(summary, sim.log.events)
	var rev := ReviewBuilder.build(sim, plan)
	m["grade"] = str(rev.get("grade", ""))
	m["causes"] = rev.get("causes", [])
	m["soft_cap"] = soft_cap
	return m


func _holds(case_m: Dictionary, base_m: Dictionary) -> Dictionary:
	## D.3: escape≥1 OR clear_s +50% OR injury +50% (vs same-plan baseline).
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

	for delta in [30.0, 60.0]:
		var pa := _plan_a()
		pa["operators"][0]["facing_deg"] = float(pa["operators"][0]["facing_deg"]) + delta
		var ma := _run_plan(pa, soft)
		var id_a := "F-A%.0f" % delta
		out[id_a] = _row(id_a, soft, ma, _holds(ma, base_a))

		var pb := _plan_b()
		pb["operators"][0]["facing_deg"] = float(pb["operators"][0]["facing_deg"]) + delta
		var mb := _run_plan(pb, soft)
		var id_b := "F-B%.0f" % delta
		out[id_b] = _row(id_b, soft, mb, _holds(mb, base_b))

	for dt_i in [-4, -2, 0, 2, 4]:
		# Plan A: manual at ideal±Δ (cross_marker replaced).
		var pa2 := _plan_a()
		pa2["trigger"] = {"type": "manual"}
		pa2["manual_detonate_tick"] = T0_A + dt_i * TICK_HZ
		var ma2 := _run_plan(pa2, soft)
		var id_ta := "T-A%+d" % dt_i
		if dt_i == 0:
			out[id_ta] = _row(id_ta, soft, ma2)
		else:
			out[id_ta] = _row(id_ta, soft, ma2, _holds(ma2, base_a))

		# Plan B: Δt=0 keeps mine; ± offsets use manual without mines so t0 is free.
		var pb2 := _plan_b()
		if dt_i == 0:
			var mb0 := _run_plan(pb2, soft)
			out["T-B+0"] = _row("T-B+0", soft, mb0)
		else:
			pb2["trigger"] = {"type": "manual"}
			pb2["manual_detonate_tick"] = T0_B + dt_i * TICK_HZ
			pb2["mines"] = []
			var mb2 := _run_plan(pb2, soft)
			var id_tb := "T-B%+d" % dt_i
			out[id_tb] = _row(id_tb, soft, mb2, _holds(mb2, base_b))

	var pa_w := _plan_a()
	pa_w["operators"][0]["weapon_id"] = "kar98k"
	var mw := _run_plan(pa_w, soft)
	out["W-A-MG→Kar"] = _row("W-A-MG→Kar", soft, mw, _holds(mw, base_a))

	# Unscouted east alley: main-road-only (drop Kar alley watch).
	var pa_u := _plan_a()
	pa_u["operators"] = [pa_u["operators"][0], pa_u["operators"][2]]
	pa_u["operators"][0]["facing_deg"] = 0.0
	var mu := _run_plan(pa_u, soft)
	out["S-unscout-east"] = _row("S-unscout-east", soft, mu, _holds(mu, base_a))

	for alert_name in ["quiet", "suspicious", "area_alert", "global_alert"]:
		var wins := 0
		var detail: Array = []
		for which in ["A", "B"]:
			var plan: Dictionary = _plan_a() if which == "A" else _plan_b()
			var m := _run_to_alert_then_finish(plan, soft, alert_name)
			detail.append({
				"plan": which,
				"outcome": m.get("outcome"),
				"escape_n": m.get("escape_n"),
				"injury_n": m.get("injury_n"),
				"clear_s": m.get("clear_s"),
			})
			if str(m.get("outcome", "")) == "win":
				wins += 1
		out["ALERT-%s" % alert_name] = {
			"id": "ALERT-%s" % alert_name,
			"soft_cap": soft,
			"wins": wins,
			"holds_strict": wins >= 1,
			"detail": detail,
		}

	return out


func _run_to_alert_then_finish(plan: Dictionary, soft: bool, target_alert: String) -> Dictionary:
	if target_alert == "quiet":
		return _run_plan(plan, soft)
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var weapons := SimWeapons.load_csv()
	var work: Dictionary = plan.duplicate(true)
	if target_alert == "global_alert":
		work["trigger"] = {"type": "manual"} ## alarm owns detonate
	var sim := NightSim.new()
	sim.setup(level, work, weapons)
	sim.enemy_return_soft_cap = soft
	sim.log.emit(0, "sim_start", {"actor": "system", "payload": {"plan_id": work.get("id"), "alert_probe": target_alert}})
	for m in sim.mines:
		sim.log.emit(0, "mine_place", {"actor": str(m["id"]), "weapon_id": "mine", "pos": {"x": m["x"], "y": m["y"], "height": "ground"}})
	sim._set_phase(0, "wait")
	sim.force_expose = true
	var guard := 0
	var recovering := false
	while sim.alert != target_alert and guard < 600:
		sim._tick_once()
		if target_alert == "area_alert" or target_alert == "global_alert":
			if sim.alert == "suspicious" and sim.suspicious_count == 1 and not recovering:
				sim.force_expose = false
				recovering = true
			if sim.alert == "quiet" and sim.suspicious_count == 1:
				sim.force_expose = true
		if sim.alert == target_alert:
			break
		sim.tick += 1
		guard += 1
	sim.force_expose = false
	while not sim._done and sim.tick <= sim.max_ticks:
		sim._tick_once()
		if sim._done:
			break
		sim.tick += 1
	if not sim._done:
		sim._finish("lose", "timeout")
	return _metrics(sim.outcome_summary(), sim.log.events)


func _test_soft_cap_default() -> void:
	var sim := NightSim.new()
	_assert(sim.enemy_return_soft_cap == C.RETURN_FIRE_ASSIST_DEFAULT,
		"enemy_return_soft_cap defaults to RETURN_FIRE_ASSIST_DEFAULT got=%s" % sim.enemy_return_soft_cap)
	_assert(C.RETURN_FIRE_ASSIST_DEFAULT == false,
		"T6 owner default is hard tier (assist OFF) got=%s" % C.RETURN_FIRE_ASSIST_DEFAULT)
	_assert(C.RETURN_FIRE_ASSIST_MAX_HITS_PER_ENEMY == 1,
		"assist cap constant is 1 hit/enemy got=%s" % C.RETURN_FIRE_ASSIST_MAX_HITS_PER_ENEMY)


func _test_plan_key_roundtrip() -> void:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var weapons := SimWeapons.load_csv()
	var quiet_sim := NightSim.new()
	quiet_sim.setup(level, _plan_a(), weapons)
	_assert(quiet_sim.enemy_return_soft_cap == false, "plan without key -> assist OFF")
	var assist_plan := _plan_a()
	assist_plan["return_fire_assist"] = true
	var assist_sim := NightSim.new()
	assist_sim.setup(level, assist_plan, weapons)
	_assert(assist_sim.enemy_return_soft_cap == true, "plan return_fire_assist=true -> assist ON")
	assist_sim.enemy_return_soft_cap = false
	_assert(assist_sim.enemy_return_soft_cap == false, "post-setup test override still wins")


func _assert_baselines(on_m: Dictionary, off_m: Dictionary) -> void:
	var ba: Dictionary = off_m["BASE-A"]
	var bb: Dictionary = off_m["BASE-B"]
	_assert(str(ba.get("outcome")) == "win", "BASE-A default assist OFF wins")
	_assert(str(bb.get("outcome")) == "win", "BASE-B default assist OFF wins")
	_assert(int(ba.get("detonate_tick", -1)) == T0_A, "BASE-A t0=%d" % T0_A)
	_assert(int(bb.get("detonate_tick", -1)) == T0_B, "BASE-B t0=%d" % T0_B)
	_assert(bool(ba.get("standard_ambush", false)) == true, "BASE-A default standard_ambush")
	_assert(bool(bb.get("standard_ambush", false)) == true, "BASE-B default standard_ambush")
	_assert(str(on_m["BASE-A"].get("outcome")) == "win", "BASE-A assist ON wins")
	_assert(str(on_m["BASE-B"].get("outcome")) == "win", "BASE-B assist ON wins")
	var bb_assist: Dictionary = on_m["BASE-B"]
	_assert(
		str(bb.get("outcome")) != "win"
		or int(bb.get("injury_n", 0)) > int(bb_assist.get("injury_n", 0)),
		"assist OFF is harsher on BASE-B (lose or +injury) off=%s/inj%s on=win/inj%s" % [
			bb.get("outcome"), bb.get("injury_n"), bb_assist.get("injury_n")])


func _assert_holding_gates(off_m: Dictionary) -> void:
	for id in HOLDING_IDS:
		var r: Dictionary = off_m[id]
		_assert(bool(r.get("holds_strict", false)),
			"holding gate %s must stay D.3-true under default assist OFF" % id)


func _assert_strict_loses(off_m: Dictionary) -> void:
	for id in STRICT_LOSE_IDS:
		if COUNTEREX_TRANSITION_GATE and TRANSITION_IDS.has(id):
			continue ## fallback: self._assert_transition_gate enforces win/C/non-standard
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
	var ta4: Dictionary = off_m["T-A+4"]
	_assert(bool(ta4.get("standard_ambush", true)) == false,
		"T-A+4 standard_ambush must be false")


func _assert_transition_gate(off_m: Dictionary) -> void:
	_assert(COUNTEREX_TRANSITION_GATE == true,
		"T7 transition gate is enabled as fallback")
	_assert(TRANSITION_IDS.is_empty(),
		"T7 transition list is empty (all strict cases lose) got=%s" % [TRANSITION_IDS])
	for id in TRANSITION_IDS:
		_assert(STRICT_LOSE_IDS.has(id), "transition id %s is a strict case" % id)
	if not COUNTEREX_TRANSITION_GATE:
		return
	for id in TRANSITION_IDS:
		var r: Dictionary = off_m[id]
		if str(r.get("outcome", "")) == "lose":
			_assert(true, "transition case %s resolved by geometry (lose)" % id)
			continue
		_assert(str(r.get("outcome", "")) == "win", "transition %s is win got=%s" % [id, r.get("outcome")])
		_assert(bool(r.get("standard_ambush", true)) == false,
			"transition %s is not standard" % id)
		_assert(str(r.get("grade", "")) == "C", "transition %s grade C got=%s" % [id, r.get("grade")])
		var joined := "|".join(r.get("causes", []))
		_assert(joined.contains("晚") or joined.contains("偏早") or joined.contains("朝向") or joined.contains("漏网"),
			"transition %s review names the mistake got=%s" % [id, joined])


func _assert_pending_documented(off_m: Dictionary) -> void:
	for id in PENDING_IDS:
		_assert(off_m.has(id), "pending case %s present in matrix" % id)
		var r: Dictionary = off_m[id]
		# Honest lock: these currently do NOT hold; if a future geometry fix makes them hold,
		# move id into HOLDING_IDS and update the results doc (do not silently pass).
		_assert(bool(r.get("holds_strict", true)) == false,
			"pending gate %s still documented as not-yet-holding (got holds=true — update HOLDING_IDS + docs)" % id)


func _assert_alert_wins(on_m: Dictionary, off_m: Dictionary) -> void:
	for name in ["quiet", "suspicious", "area_alert", "global_alert"]:
		var r_off: Dictionary = off_m["ALERT-%s" % name]
		_assert(int(r_off.get("wins", 0)) >= 1,
			"ALERT-%s default assist OFF ≥1 plan wins got=%s" % [name, r_off.get("wins")])
		var r_on: Dictionary = on_m["ALERT-%s" % name]
		_assert(int(r_on.get("wins", 0)) >= 1,
			"ALERT-%s assist ON ≥1 plan wins got=%s" % [name, r_on.get("wins")])


func _assert_soft_cap_control_differs(on_m: Dictionary, off_m: Dictionary) -> void:
	var on_b: Dictionary = on_m["BASE-B"]
	var off_b: Dictionary = off_m["BASE-B"]
	var changed := (
		str(on_b.get("outcome")) != str(off_b.get("outcome"))
		or int(on_b.get("injury_n", 0)) != int(off_b.get("injury_n", 0))
		or int(on_b.get("dead_ops_n", 0)) != int(off_b.get("dead_ops_n", 0))
	)
	_assert(changed, "assist ON/OFF control differs on BASE-B")


func _print_comparison(off_m: Dictionary, on_m: Dictionary) -> void:
	## Two-tier side-by-side table for the results doc (default first).
	print("COUNTEREX_COMPARE_BEGIN")
	print("id|off_outcome|off_esc|off_clear_s|off_inj|off_dead|on_outcome|on_esc|on_clear_s|on_inj|on_dead|off_holds|on_holds")
	for id in off_m.keys():
		var off: Dictionary = off_m[id]
		var on: Dictionary = on_m[id]
		if off.has("wins"):
			print("%s|wins=%s|wins=%s" % [id, off.get("wins"), on.get("wins")])
			continue
		print("%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
			id,
			off.get("outcome"), off.get("escape_n"), off.get("clear_s"), off.get("injury_n"), off.get("dead_ops_n"),
			on.get("outcome"), on.get("escape_n"), on.get("clear_s"), on.get("injury_n"), on.get("dead_ops_n"),
			off.get("holds_strict", "-"), on.get("holds_strict", "-"),
		])
	print("COUNTEREX_COMPARE_END")
