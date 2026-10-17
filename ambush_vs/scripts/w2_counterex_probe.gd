extends SceneTree

## One-shot probe for D.3 counterexample gates (measurement only; not CI).
## Launch: AMBUSH_ALLOW_PROBE=1 ./scripts/run_isolated_test.sh <godot> w2_counterex_probe.gd

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const ReviewBuilder := preload("res://sim/review_builder.gd")
const SimConstants := preload("res://sim/constants.gd")

const TICK_HZ := 20


func _init() -> void:
	if OS.get_environment("AMBUSH_ALLOW_PROBE") != "1":
		printerr("PROBE_REFUSED set AMBUSH_ALLOW_PROBE=1")
		quit(2)
		return
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var rows: Array = []
	for soft in [true, false]:
		rows.append_array(_measure_all(soft))
	print("COUNTEREX_PROBE_BEGIN")
	for r in rows:
		print(JSON.stringify(r))
	print("COUNTEREX_PROBE_END count=", rows.size())
	quit(0)


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


func _run_plan(plan: Dictionary, soft_cap: bool, tweaks: Dictionary = {}) -> Dictionary:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.enemy_return_soft_cap = soft_cap
	for k in tweaks.keys():
		sim.set(k, tweaks[k])
	var summary: Dictionary = sim.run()
	var m := _metrics(summary, sim.log.events)
	m["soft_cap"] = soft_cap
	return m


func _holds(case_m: Dictionary, base_m: Dictionary) -> Dictionary:
	## D.3: escape≥1 OR clear_s +50% OR injury +50%.
	var esc := int(case_m.get("escape_n", 0))
	var clear := float(case_m.get("clear_s", -1.0))
	var inj := int(case_m.get("injury_n", 0))
	var base_clear := float(base_m.get("clear_s", -1.0))
	var base_inj := int(base_m.get("injury_n", 0))
	var lose := str(case_m.get("outcome", "")) != "win"
	var clear_ok := base_clear > 0.0 and clear >= 0.0 and clear >= base_clear * 1.5
	var inj_ok := false
	if base_inj <= 0:
		inj_ok = inj >= 1 ## +50% of 0 → any injury counts as worse
	else:
		inj_ok = float(inj) >= float(base_inj) * 1.5
	var esc_ok := esc >= 1
	var holds := esc_ok or clear_ok or inj_ok or lose
	## Strict D.3 text does not list "lose" — but lose implies escape or wipeout failure.
	## Report both: holds_strict (three criteria) and holds_or_lose.
	var holds_strict := esc_ok or clear_ok or inj_ok
	return {
		"holds_strict": holds_strict,
		"holds_or_lose": holds,
		"via_escape": esc_ok,
		"via_clear_50": clear_ok,
		"via_injury_50": inj_ok,
		"via_lose": lose,
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


func _measure_all(soft: bool) -> Array:
	var out: Array = []
	var base_a := _run_plan(_plan_a(), soft)
	var base_b := _run_plan(_plan_b(), soft)
	out.append(_row("BASE-A", soft, base_a))
	out.append(_row("BASE-B", soft, base_b))

	# Facing offsets: A key shooter = MG42 (index 0); B key = Kar98k (index 0).
	for delta in [30.0, 60.0]:
		var pa := _plan_a()
		pa["operators"][0]["facing_deg"] = float(pa["operators"][0]["facing_deg"]) + delta
		var ma := _run_plan(pa, soft)
		out.append(_row("F-A%.0f" % delta, soft, ma, _holds(ma, base_a)))

		var pb := _plan_b()
		pb["operators"][0]["facing_deg"] = float(pb["operators"][0]["facing_deg"]) + delta
		var mb := _run_plan(pb, soft)
		out.append(_row("F-B%.0f" % delta, soft, mb, _holds(mb, base_b)))

	# Detonation timing scans relative to ideal t0 (PLAY-4: 520/560).
	for dt_s in [-4, -2, 0, 2, 4]:
		var dt_i: int = int(dt_s)
		var tick_a: int = 520 + dt_i * TICK_HZ
		var pa2 := _plan_a()
		pa2["trigger"] = {"type": "manual"}
		pa2["manual_detonate_tick"] = tick_a
		var ma2 := _run_plan(pa2, soft)
		var hold_a := {} if dt_i == 0 else _holds(ma2, base_a)
		out.append(_row("T-A%+d" % dt_i, soft, ma2, hold_a))

		var tick_b: int = 560 + dt_i * TICK_HZ
		var pb2 := _plan_b()
		# Force manual so mine does not lock t0; scan absolute tick.
		pb2["trigger"] = {"type": "manual"}
		pb2["manual_detonate_tick"] = tick_b
		var mb2 := _run_plan(pb2, soft)
		var hold_b := {} if dt_i == 0 else _holds(mb2, base_b)
		out.append(_row("T-B%+d" % dt_i, soft, mb2, hold_b))

	# Weapon swap: A MG42 → Kar98k at same slot.
	var pa_w := _plan_a()
	pa_w["operators"][0]["weapon_id"] = "kar98k"
	var mw := _run_plan(pa_w, soft)
	out.append(_row("W-A-MG→Kar", soft, mw, _holds(mw, base_a)))

	# Unscouted east alley: main-road-only layout (no east cover / Kar at L).
	var pa_u := _plan_a()
	# Drop Kar alley watch; aim both remaining at main road only.
	pa_u["operators"] = [
		pa_u["operators"][0], ## MG still on barn but only covers main
		pa_u["operators"][2], ## MP south gate
	]
	# Point MG at main; no alley shooter.
	pa_u["operators"][0]["facing_deg"] = 0.0
	var mu := _run_plan(pa_u, soft)
	out.append(_row("S-unscout-east", soft, mu, _holds(mu, base_a)))

	# Alert levels: at least one of A/B wins under each.
	for alert_name in ["quiet", "suspicious", "area_alert", "global_alert"]:
		var wins := 0
		var detail: Array = []
		for which in ["A", "B"]:
			var plan: Dictionary = _plan_a() if which == "A" else _plan_b()
			var m := _run_to_alert_then_finish(plan, soft, alert_name)
			detail.append({"plan": which, "outcome": m.get("outcome"), "escape_n": m.get("escape_n"), "injury_n": m.get("injury_n"), "clear_s": m.get("clear_s")})
			if str(m.get("outcome", "")) == "win":
				wins += 1
		out.append({
			"id": "ALERT-%s" % alert_name,
			"soft_cap": soft,
			"wins": wins,
			"holds_strict": wins >= 1,
			"detail": detail,
		})

	return out


func _run_to_alert_then_finish(plan: Dictionary, soft: bool, target_alert: String) -> Dictionary:
	if target_alert == "quiet":
		return _run_plan(plan, soft)
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.enemy_return_soft_cap = soft
	# For global, force manual so alarm path can own detonate if needed.
	if target_alert == "global_alert":
		plan = plan.duplicate(true)
		plan["trigger"] = {"type": "manual"}
		sim.setup(level, plan, weapons)
		sim.enemy_return_soft_cap = soft
	sim.log.emit(0, "sim_start", {"actor": "system", "payload": {"plan_id": plan.get("id"), "alert_probe": target_alert}})
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
	# If we wanted suspicious only, stop expose so it does not climb further before fight.
	if target_alert == "suspicious":
		sim.force_expose = false
	while not sim._done and sim.tick <= sim.max_ticks:
		sim._tick_once()
		if sim._done:
			break
		sim.tick += 1
	if not sim._done:
		sim._finish("lose", "timeout")
	var summary := sim.outcome_summary()
	return _metrics(summary, sim.log.events)
