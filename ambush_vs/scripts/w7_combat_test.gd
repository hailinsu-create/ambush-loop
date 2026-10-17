extends SceneTree

## PLAY-6 / VS-W7: post-detonate enemy reaction — cover, return fire, flee/leak, ammo.
## Deterministic NightSim only; updates expected via AMBUSH_WRITE_GOLDEN on W2.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const SimConstants := preload("res://sim/constants.gd")
const ReviewBuilder := preload("res://sim/review_builder.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_cover_seeking()
	_test_return_fire_wounds_operator()
	_test_flee_and_leak_raises_alert()
	_test_ammo_runs_out()
	_test_plan_a_winnable_not_flawless()
	_test_plan_b_beatable()
	_test_determinism()
	print("W7_COMBAT_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _fresh_sim(plan: Dictionary, opts: Dictionary = {}) -> NightSim:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	if opts.has("skip_fire"):
		sim.skip_fire = bool(opts["skip_fire"])
	if opts.has("skip_enemy_fire"):
		sim.skip_enemy_fire = bool(opts["skip_enemy_fire"])
	if opts.has("max_ticks"):
		sim.max_ticks = int(opts["max_ticks"])
	return sim


func _run_to_end(sim: NightSim) -> Dictionary:
	sim.begin_wait()
	while not sim.is_finished():
		sim.advance_one_tick()
	return sim.outcome_summary()


func _count_type(sim: NightSim, t: String) -> int:
	var n := 0
	for e in sim.log.events:
		if str(e.get("type", "")) == t:
			n += 1
	return n


func _test_cover_seeking() -> void:
	## After detonate, survivors emit seek_cover and at least one reaches in_cover.
	var plan: Dictionary = SimRunner.load_json("res://data/fixtures/plan_b.json")
	var sim := _fresh_sim(plan, {"skip_fire": true}) ## let them live long enough to duck
	sim.begin_wait()
	var saw_seek := false
	var saw_cover := false
	while not sim.is_finished():
		sim.advance_one_tick()
		if sim.detonate_tick >= 0:
			for e in sim.log.events:
				if str(e.get("type", "")) == "enemy_seek_cover":
					saw_seek = true
				if str(e.get("type", "")) == "enemy_in_cover":
					saw_cover = true
			if saw_cover or sim.tick - sim.detonate_tick > 80:
				break
	_assert(saw_seek, "enemies emit enemy_seek_cover after detonate")
	_assert(saw_cover, "at least one enemy reaches enemy_in_cover within N cells")
	var any_in := false
	for e in sim.enemies:
		if bool(e.get("in_cover", false)):
			any_in = true
			var goal: Vector2i = e.get("cover_goal", Vector2i(-1, -1))
			var gx: int = goal.x
			var gy: int = goal.y
			var dx: int = absi(int(floor(float(e["x"]))) - gx)
			var dy: int = absi(int(floor(float(e["y"]))) - gy)
			_assert(dx <= SimConstants.COVER_SEEK_RADIUS and dy <= SimConstants.COVER_SEEK_RADIUS,
				"cover goal within COVER_SEEK_RADIUS got dx=%s dy=%s" % [dx, dy])
			break
	_assert(any_in, "sim state marks in_cover on a survivor")


func _test_return_fire_wounds_operator() -> void:
	## Mute friendly fire; enemies return-fire until an operator is wounded.
	var plan: Dictionary = SimRunner.load_json("res://data/fixtures/plan_a.json")
	# Give ops plenty of HP visibility; start at full.
	for op in plan.get("operators", []):
		op["hp"] = SimConstants.OP_MAX_HP
	var sim := _fresh_sim(plan, {"skip_fire": true})
	sim.begin_wait()
	while not sim.is_finished():
		sim.advance_one_tick()
		if not (sim.wounded_ids as Array).is_empty():
			break
		if sim.detonate_tick >= 0 and sim.tick - sim.detonate_tick > 200:
			break
	_assert(_count_type(sim, "enemy_fire") > 0, "enemy_fire events emitted")
	_assert(not (sim.wounded_ids as Array).is_empty(), "return fire wounds at least one operator got=%s" % [sim.wounded_ids])
	var wid := str(sim.wounded_ids[0])
	var op: Dictionary = {}
	for o in sim.operators:
		if str(o["id"]) == wid:
			op = o
			break
	# May still be wounded, or subsequently killed by stacked soft-capped hits from other enemies.
	_assert(
		bool(op.get("wounded", false)) or not bool(op.get("alive", true)) or int(op.get("hp", 99)) < SimConstants.OP_MAX_HP,
		"wounded/killed/HP-down on %s hp=%s wounded=%s alive=%s" % [wid, op.get("hp"), op.get("wounded"), op.get("alive")]
	)
	_assert(int(op.get("hp", 99)) < SimConstants.OP_MAX_HP or not bool(op.get("alive", true)), "HP reduced on %s" % wid)


func _test_flee_and_leak_raises_alert() -> void:
	## Kill most enemies via scripted damage after detonate; survivors flee and can leak.
	var plan: Dictionary = SimRunner.load_json("res://data/fixtures/plan_a.json")
	var sim := _fresh_sim(plan, {"skip_fire": true, "skip_enemy_fire": true})
	sim.begin_wait()
	var fled := false
	var leaked := false
	while not sim.is_finished():
		sim.advance_one_tick()
		if sim.detonate_tick >= 0 and sim.tick == sim.detonate_tick + 1:
			# Wipe down to one survivor so flee threshold triggers.
			var kept := ""
			for e in sim.enemies:
				if e["alive"] and e["entered"] and not e["escaped"]:
					if kept == "":
						kept = str(e["id"])
					else:
						sim._kill_enemy(e, "test", "test")
		if _count_type(sim, "enemy_flee") > 0:
			fled = true
		if not (sim.escaped_ids as Array).is_empty():
			leaked = true
			break
		if sim.detonate_tick >= 0 and sim.tick - sim.detonate_tick > 400:
			break
	_assert(fled, "enemy_flee when squad strength below threshold")
	_assert(leaked or not (sim.escaped_ids as Array).is_empty(), "fleeing enemy can exit as leak")
	var s := sim.outcome_summary()
	_assert(str(s.get("next_night_alert", "quiet")) != SimConstants.ALERT_QUIET,
		"leak raises next_night_alert got=%s" % s.get("next_night_alert"))
	# Review cause should mention escape / 逃脱.
	var rev := ReviewBuilder.build(sim, plan, {})
	var causes := "|".join(rev.get("causes", []))
	_assert(causes.find("逃") >= 0 or causes.find("漏网") >= 0, "review causes mention leak got=%s" % causes)


func _test_ammo_runs_out() -> void:
	var plan: Dictionary = SimRunner.load_json("res://data/fixtures/plan_a.json")
	for op in plan.get("operators", []):
		op["ammo"] = 3
	var sim := _fresh_sim(plan, {"skip_enemy_fire": true})
	var s := _run_to_end(sim)
	_assert(_count_type(sim, "ammo_empty") > 0, "ammo_empty logged when mags run dry")
	var any_zero := false
	for op in sim.operators:
		if str(op.get("weapon_id", "")) in ["grenade", "mine"]:
			continue
		if int(op.get("ammo", 0)) <= 0:
			any_zero = true
	_assert(any_zero, "at least one gun at 0 ammo")
	_assert(str(s.get("outcome", "")) != "", "sim still finishes with finite ammo outcome=%s" % s.get("outcome"))


func _test_plan_a_winnable_not_flawless() -> void:
	var plan: Dictionary = SimRunner.load_json("res://data/fixtures/plan_a.json")
	var sim := _fresh_sim(plan)
	var s := _run_to_end(sim)
	_assert(str(s.get("outcome", "")) == "win", "plan A still winnable")
	_assert(s.get("escapes", []).is_empty(), "plan A no leaks on default")
	var rev := ReviewBuilder.build(sim, plan, {})
	var grade := str(rev.get("grade", ""))
	_assert(grade in ["A", "S"], "plan A grade A or S got=%s" % grade)
	# Not trivially flawless: either wounded, cover fight, or grade below S.
	var not_flawless := (
		grade != "S"
		or not (s.get("wounded", []) as Array).is_empty()
		or _count_type(sim, "enemy_in_cover") > 0
		or _count_type(sim, "enemy_fire") > 0
	)
	_assert(not_flawless, "plan A no longer trivially flawless (combat reaction lands)")


func _test_plan_b_beatable() -> void:
	var plan: Dictionary = SimRunner.load_json("res://data/fixtures/plan_b.json")
	var sim := _fresh_sim(plan)
	var s := _run_to_end(sim)
	_assert(str(s.get("outcome", "")) == "win", "plan B beatable with care outcome=%s" % s.get("outcome"))
	_assert(bool(s.get("standard_ambush", false)) == true or str(s.get("outcome", "")) == "win",
		"plan B remains a viable ambush")


func _test_determinism() -> void:
	var ha := ""
	var hb := ""
	for i in range(2):
		var plan: Dictionary = SimRunner.load_json("res://data/fixtures/plan_a.json")
		var sim := _fresh_sim(plan)
		var s := _run_to_end(sim)
		if i == 0:
			ha = str(s.get("log_hash", ""))
		else:
			hb = str(s.get("log_hash", ""))
	_assert(ha != "" and ha == hb, "PLAY-6 combat is deterministic hash=%s" % ha)
