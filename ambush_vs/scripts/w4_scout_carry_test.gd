extends SceneTree

## T4: scout alert carried into setup/ambush (NightSim optional plan["start_alert"]).
## Contract: quiet/default is byte-identical to the golden path; suspicious/area/global
## raise the alert at tick 0 with observable cost but no start-of-night auto-loss.
## Launch only via scripts/run_isolated_test.sh|.ps1.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const C := preload("res://sim/constants.gd")

const LEVEL := "res://data/levels/yard.json"

var _failed := 0
var _passed := 0
var _results: Dictionary = {}


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_four_tiers()
	_test_quiet_vs_seen_differs()
	_test_winnable_gate()
	_test_carry_not_start_loss()
	await _test_scene_carry()
	_test_suspicious_cost()
	print("W4_SCOUT_CARRY_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _plan(which: String) -> Dictionary:
	var path := "res://data/fixtures/plan_a.json" if which == "A" else "res://data/fixtures/plan_b.json"
	return SimRunner.load_json(path)


func _plan_with(which: String, start_alert: String) -> Dictionary:
	var p := _plan(which)
	p["start_alert"] = start_alert
	return p


func _new_sim(plan: Dictionary) -> NightSim:
	var level := SimLevelLoader.load_path(LEVEL)
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	sim.begin_wait()
	return sim


func _finish(sim: NightSim) -> Dictionary:
	var guard := 0
	while not sim.is_finished() and guard < 20000:
		sim.advance_one_tick()
		guard += 1
	if not sim.is_finished():
		sim._finish("lose", "timeout")
	return sim.outcome_summary()


func _run(which: String, start_alert: String) -> Dictionary:
	var plan: Dictionary = _plan(which) if start_alert == "" else _plan_with(which, start_alert)
	return _finish(_new_sim(plan))


func _count_alert_to(sim: NightSim, tier: String) -> int:
	var n := 0
	for e in sim.log.events:
		if str(e.get("type", "")) != "alert_change":
			continue
		if str(e.get("payload", {}).get("to", "")) == tier:
			n += 1
	return n


func _run_metrics(which: String, start_alert: String) -> Dictionary:
	## Full-night run plus diagnostic counters (wait_exposed_ticks/first_exposed_tick).
	var plan: Dictionary = _plan(which) if start_alert == "" else _plan_with(which, start_alert)
	var sim := _new_sim(plan)
	var summary := _finish(sim)
	return {
		"summary": summary,
		"wait_exposed_ticks": sim.wait_exposed_ticks,
		"first_exposed_tick": sim.first_exposed_tick,
		"alert_change_to_suspicious": _count_alert_to(sim, "suspicious"),
	}


func _suspicion_worse(q: Dictionary, x: Dictionary) -> bool:
	## Is the suspicious carry measurably more exposed than quiet?
	## Chosen metric: wait_exposed_ticks (WAIT ticks judged exposed), tie-break earlier
	## first_exposed_tick. NOTE: alert_change→suspicious is NOT used here because the
	## scout_carry alert_change itself adds one at tick 0 (would pass even at mul=1.0).
	if int(x["wait_exposed_ticks"]) > int(q["wait_exposed_ticks"]):
		return true
	var qf := int(q["first_exposed_tick"])
	var xf := int(x["first_exposed_tick"])
	return xf >= 0 and (qf < 0 or xf < qf)


func _has_scout_carry(sim: NightSim) -> bool:
	for e in sim.log.events:
		if str(e.get("type", "")) == "alert_change" and str(e.get("payload", {}).get("reason", "")) == "scout_carry":
			return true
	return false


func _print_result(which: String, tier: String, s: Dictionary) -> void:
	print("RESULT which=%s tier=%s outcome=%s trigger=%s standard_ambush=%s detonate=%d kills=%d escapes=%d wounded=%d dead_ops=%d reason=%s" % [
		which, tier, str(s.get("outcome", "")), str(s.get("trigger", "")), str(s.get("standard_ambush", false)),
		int(s.get("detonate_tick", -1)), (s.get("kills", []) as Array).size(), (s.get("escapes", []) as Array).size(),
		(s.get("wounded", []) as Array).size(), (s.get("dead_ops", []) as Array).size(), str(s.get("reason", "")),
	])


func _expected_patrol_alert() -> Dictionary:
	## Read the yard alert_route so the test does not hardcode geometry.
	var level := SimLevelLoader.load_path(LEVEL)
	for p in level.get("patrols", []):
		var ar: Variant = (p as Dictionary).get("alert_route", {})
		if typeof(ar) == TYPE_DICTIONARY and (ar as Dictionary).has("facing_deg"):
			var wps: Array = (ar as Dictionary).get("waypoints", [])
			var ax := 0.0
			if not wps.is_empty():
				ax = float((wps[0] as Dictionary).get("x", 0.0))
			return {"facing": float((ar as Dictionary)["facing_deg"]), "x": ax}
	return {"facing": 0.0, "x": -1.0}


func _test_four_tiers() -> void:
	## quiet / missing key must leave the golden event stream untouched.
	var base_a := _run("A", "")
	var quiet_a := _run("A", "quiet")
	_assert(not _has_scout_carry(_new_sim(SimRunner.load_json("res://data/fixtures/plan_a.json"))), "quiet A no scout_carry event")
	_assert(str(base_a.get("log_hash", "")) == str(quiet_a.get("log_hash", "")), "quiet A log hash == missing-key hash")
	var base_b := _run("B", "")
	var quiet_b := _run("B", "quiet")
	_assert(not _has_scout_carry(_new_sim(SimRunner.load_json("res://data/fixtures/plan_b.json"))), "quiet B no scout_carry event")
	_assert(str(base_b.get("log_hash", "")) == str(quiet_b.get("log_hash", "")), "quiet B log hash == missing-key hash")

	## suspicious: tick 0 alert tier, scout_carry event, still standard-ambush eligible.
	var sim_sus := _new_sim(_plan_with("A", "suspicious"))
	_assert(str(sim_sus.alert) == "suspicious", "suspicious tick0 alert=suspicious got=%s" % sim_sus.alert)
	_assert(_has_scout_carry(sim_sus), "suspicious emits alert_change reason=scout_carry")
	_assert(sim_sus.standard_ambush_eligible == true, "suspicious keeps standard_ambush_eligible true")
	var sum_sus := _finish(sim_sus)

	## area_alert: tick 0 tier, not eligible, patrol switches to alert_route.
	var sim_area := _new_sim(_plan_with("A", "area_alert"))
	_assert(str(sim_area.alert) == "area_alert", "area tick0 alert=area_alert got=%s" % sim_area.alert)
	_assert(sim_area.standard_ambush_eligible == false, "area standard_ambush_eligible false")
	sim_area.advance_one_tick()
	var exp := _expected_patrol_alert()
	var saw_alert_patrol := false
	for p in sim_area.patrols:
		if (p as Dictionary).has("alert_route"):
			saw_alert_patrol = true
			_assert(
				is_equal_approx(float((p as Dictionary)["cone"]["facing_deg"]), float(exp["facing"])),
				"area patrol facing=alert_route.facing got=%s exp=%s" % [(p as Dictionary)["cone"]["facing_deg"], exp["facing"]]
			)
	if not saw_alert_patrol:
		_assert(false, "area patrol with alert_route exists")
	var sum_area := _finish(sim_area)
	_assert(sum_area.get("standard_ambush") == false, "area full-run standard_ambush false")

	## global_alert: first WAIT tick triggers alarm through _step_trigger.
	var sim_glob := _new_sim(_plan_with("A", "global_alert"))
	sim_glob.advance_one_tick()
	_assert(int(sim_glob.detonate_tick) <= 1, "global detonate_tick<=1 got=%d" % sim_glob.detonate_tick)
	_assert(str(sim_glob.trigger_used) == "alarm", "global trigger=alarm got=%s" % sim_glob.trigger_used)
	var sum_glob := _finish(sim_glob)
	_assert(sum_glob.get("standard_ambush") == false, "global full-run standard_ambush false")

	## illegal value falls back to quiet.
	_assert(not _has_scout_carry(_new_sim(_plan_with("A", "foo"))), "illegal start_alert falls back to quiet")

	_results["A"] = {"quiet": base_a, "suspicious": sum_sus, "area_alert": sum_area, "global_alert": sum_glob}
	_results["B"] = {
		"quiet": base_b,
		"suspicious": _run("B", "suspicious"),
		"area_alert": _run("B", "area_alert"),
		"global_alert": _run("B", "global_alert"),
	}
	var sus_ambush := bool(_results["A"]["suspicious"].get("standard_ambush", false)) or bool(_results["B"]["suspicious"].get("standard_ambush", false))
	_assert(sus_ambush, "suspicious carry keeps standard ambush available (A/B at least one standard_ambush true)")
	for which in ["A", "B"]:
		for tier in ["quiet", "suspicious", "area_alert", "global_alert"]:
			_print_result(which, tier, _results[which][tier])


func _differs(q: Dictionary, x: Dictionary) -> bool:
	if str(q.get("standard_ambush", false)) != str(x.get("standard_ambush", false)):
		return true
	if str(q.get("trigger", "")) != str(x.get("trigger", "")):
		return true
	if str(q.get("outcome", "")) != str(x.get("outcome", "")):
		return true
	if (q.get("escapes", []) as Array).size() != (x.get("escapes", []) as Array).size():
		return true
	return false


func _test_quiet_vs_seen_differs() -> void:
	for which in ["A", "B"]:
		var q: Dictionary = _results[which]["quiet"]
		var area: Dictionary = _results[which]["area_alert"]
		var glob: Dictionary = _results[which]["global_alert"]
		_assert(_differs(q, area), "plan %s quiet vs area differs q(%s,%s,%s,e%d) area(%s,%s,%s,e%d)" % [
			which, q.get("standard_ambush"), q.get("trigger"), q.get("outcome"), (q.get("escapes", []) as Array).size(),
			area.get("standard_ambush"), area.get("trigger"), area.get("outcome"), (area.get("escapes", []) as Array).size(),
		])
		_assert(_differs(q, glob), "plan %s quiet vs global differs q(%s,%s,%s,e%d) global(%s,%s,%s,e%d)" % [
			which, q.get("standard_ambush"), q.get("trigger"), q.get("outcome"), (q.get("escapes", []) as Array).size(),
			glob.get("standard_ambush"), glob.get("trigger"), glob.get("outcome"), (glob.get("escapes", []) as Array).size(),
		])


func _test_winnable_gate() -> void:
	var area_win := str(_results["A"]["area_alert"].get("outcome", "")) == "win" or str(_results["B"]["area_alert"].get("outcome", "")) == "win"
	_assert(area_win, "gate: area_alert carry, A/B at least one win")
	var glob_win := str(_results["A"]["global_alert"].get("outcome", "")) == "win" or str(_results["B"]["global_alert"].get("outcome", "")) == "win"
	_assert(glob_win, "gate: global_alert carry, A/B at least one win")


func _test_carry_not_start_loss() -> void:
	for tier in ["area_alert", "global_alert"]:
		var normal := true
		var reasons: Array = []
		for which in ["A", "B"]:
			var s: Dictionary = _results[which][tier]
			var reason := str(s.get("reason", ""))
			reasons.append("%s:%s" % [which, reason])
			if str(s.get("outcome", "")) == "lose" and reason == "":
				normal = false
		_assert(normal, "%s carry ends with a normal reason (not start-loss) %s" % [tier, " ".join(reasons)])


func _metric_line(which: String, tag: String, m: Dictionary) -> void:
	var s: Dictionary = m["summary"]
	print("SUSPICIOUS_COST which=%s tier=%s standard_ambush=%s trigger=%s detonate=%d wait_exposed_ticks=%d first_exposed_tick=%d alert_change_to_suspicious=%d outcome=%s dead_ops=%d wounded=%d" % [
		which, tag, str(s.get("standard_ambush", false)), str(s.get("trigger", "")), int(s.get("detonate_tick", -1)),
		int(m["wait_exposed_ticks"]), int(m["first_exposed_tick"]), int(m["alert_change_to_suspicious"]),
		str(s.get("outcome", "")), (s.get("dead_ops", []) as Array).size(), (s.get("wounded", []) as Array).size(),
	])


func _test_suspicious_cost() -> void:
	_assert(C.CARRY_SUSPICIOUS_RANGE_MUL > 1.0, "CARRY_SUSPICIOUS_RANGE_MUL > 1.0 got=%s" % C.CARRY_SUSPICIOUS_RANGE_MUL)
	var q_a := _run_metrics("A", "")
	var s_a := _run_metrics("A", "suspicious")
	var q_b := _run_metrics("B", "")
	var s_b := _run_metrics("B", "suspicious")
	_metric_line("A", "quiet", q_a)
	_metric_line("A", "suspicious", s_a)
	_metric_line("B", "quiet", q_b)
	_metric_line("B", "suspicious", s_b)

	_assert(bool(s_a["summary"].get("standard_ambush", false)), "suspicious A standard_ambush true")
	_assert(bool(s_b["summary"].get("standard_ambush", false)), "suspicious B standard_ambush true")

	var worse_a := _suspicion_worse(q_a, s_a)
	var worse_b := _suspicion_worse(q_b, s_b)
	_assert(worse_a or worse_b, "suspicious carry raises alert metric vs quiet (A_worse=%s B_worse=%s) qA=%d/%d sA=%d/%d qB=%d/%d sB=%d/%d" % [
		worse_a, worse_b,
		int(q_a["wait_exposed_ticks"]), int(q_a["first_exposed_tick"]), int(s_a["wait_exposed_ticks"]), int(s_a["first_exposed_tick"]),
		int(q_b["wait_exposed_ticks"]), int(q_b["first_exposed_tick"]), int(s_b["wait_exposed_ticks"]), int(s_b["first_exposed_tick"]),
	])
	## Hard assertion on the plan that measurably worsens (B), chosen metric wait_exposed_ticks:
	## suspicious B is exposed far longer than quiet B while keeping the standard ambush.
	_assert(
		int(s_b["wait_exposed_ticks"]) > int(q_b["wait_exposed_ticks"]),
		"suspicious B wait_exposed_ticks worse than quiet (%d > %d) first_exposed %d < %d" % [
			int(s_b["wait_exposed_ticks"]), int(q_b["wait_exposed_ticks"]),
			int(s_b["first_exposed_tick"]), int(q_b["first_exposed_tick"]),
		]
	)
	_assert(
		int(s_b["first_exposed_tick"]) >= 0 and int(s_b["first_exposed_tick"]) < int(q_b["first_exposed_tick"]),
		"suspicious B first_exposed_tick earlier than quiet (%d < %d)" % [int(s_b["first_exposed_tick"]), int(q_b["first_exposed_tick"])]
	)

	## Diagnostics must not perturb the default path: no-key == explicit quiet.
	for which in ["A", "B"]:
		var q := _run_metrics(which, "quiet")
		var d := _run_metrics(which, "")
		_assert(int(q["wait_exposed_ticks"]) == int(d["wait_exposed_ticks"]), "plan %s quiet vs default wait_exposed_ticks equal (%d/%d)" % [
			which, int(q["wait_exposed_ticks"]), int(d["wait_exposed_ticks"]),
		])


func _clear_env() -> void:
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	OS.set_environment("AMBUSH_GREYBOX_PLAN", "")


func _wait_scene_ready(max_frames: int = 120) -> Node:
	for _i in range(max_frames):
		await process_frame
		var scene = current_scene
		if scene != null and scene.has_method("can_start_wait") and scene.get("scout") != null:
			return scene
	return current_scene


func _place_plan_like(scene) -> void:
	## Same scripted placement as w3: three ops on plan-A-like cells + cross marker.
	var ops: Array = scene.plan.get("operators", [])
	if ops.size() < 3:
		return
	var id0 := str(ops[0]["id"])
	var id1 := str(ops[1]["id"])
	var id2 := str(ops[2]["id"])
	scene.scripted_place_operator(id0, 5, 9, 0.0)
	scene.scripted_place_operator(id1, 13, 7, 15.0)
	scene.scripted_place_operator(id2, 11, 2, 90.0)
	scene._on_op_weapon_picked(id0, "kar98k")
	scene._on_op_weapon_picked(id1, "mp40")
	scene._on_op_weapon_picked(id2, "grenade")
	scene.scripted_place_cross_marker(10, 7, 12, 7)


func _test_scene_carry() -> void:
	_clear_env()
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	if err != OK:
		_assert(false, "carry scene change_scene err=%s" % err)
		_clear_env()
		return
	var scene = await _wait_scene_ready()
	if scene == null or scene.get("scout") == null:
		_assert(false, "carry scene ready with scout")
		_clear_env()
		return
	scene.scout._set_alert("area_alert", "test")
	scene.begin_setup_from_scout()
	for _i in range(4):
		await process_frame
	_assert(str(scene.carried_alert) == "area_alert", "setup carried_alert=area_alert got=%s" % scene.carried_alert)
	_assert(str(scene.label_alert.text).find("区域警戒") >= 0, "setup label_alert mentions 区域警戒 got=%s" % scene.label_alert.text)
	_place_plan_like(scene)
	scene._start_wait()
	if scene.sim == null:
		_assert(false, "scene carry sim started (area) reason=%s" % scene.start_block_reason())
		_clear_env()
		return
	_assert(str(scene.sim.start_alert) == "area_alert", "scene sim.start_alert=area_alert got=%s" % scene.sim.start_alert)
	_assert(scene.sim.standard_ambush_eligible == false, "scene area standard_ambush_eligible false")
	scene._restart_scout()
	_assert(str(scene.carried_alert) == "quiet", "restart_scout resets carried_alert got=%s" % scene.carried_alert)
	scene.begin_setup_from_scout()
	for _i in range(4):
		await process_frame
	_place_plan_like(scene)
	scene._start_wait()
	if scene.sim == null:
		_assert(false, "scene second sim started reason=%s" % scene.start_block_reason())
		_clear_env()
		return
	_assert(str(scene.sim.alert) == "quiet", "second start alert quiet got=%s" % scene.sim.alert)
	_assert(not scene.plan.has("start_alert"), "second start plan has no start_alert")
	_clear_env()
