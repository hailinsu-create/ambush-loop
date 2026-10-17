extends SceneTree

## PLAY-2 / VS-W4a: ScoutSim unit tests (ambush NightSim / W2 golden untouched).

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const ScoutSim := preload("res://sim/scout_sim.gd")
const SimPathfinder := preload("res://sim/pathfinder.gd")
const SimConstants := preload("res://sim/constants.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimWeapons := preload("res://sim/weapons.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_pathfinder_reaches_crate()
	_test_crate_yields_ammo()
	_test_hidden_reveal_by_range()
	_test_mg42_locked_until_pickup()
	_test_budget_expiry_auto_advances()
	_test_ambush_golden_unchanged_after_scout_module()
	print("W4_SCOUT_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _make_scout() -> ScoutSim:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var s := ScoutSim.new()
	s.setup(level)
	s.begin_scout()
	return s


func _walk_to(s: ScoutSim, oid: String, goal: Vector2i, max_ticks: int = 6000) -> bool:
	if not s.request_move(oid, goal):
		return false
	var guard := 0
	while guard < max_ticks and not s.is_finished():
		s.advance_one_tick()
		guard += 1
		var op := s._op_by_id(oid)
		if int(op["x"]) == goal.x and int(op["y"]) == goal.y and (op.get("path", []) as Array).is_empty():
			return true
	return int(s._op_by_id(oid)["x"]) == goal.x and int(s._op_by_id(oid)["y"]) == goal.y


func _test_pathfinder_reaches_crate() -> void:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var grid = SimLevelLoader.build_grid(level)
	var path: Array = SimPathfinder.find_path(grid, Vector2i(10, 1), Vector2i(15, 4))
	_assert(not path.is_empty(), "pathfinder entry→crate_se non-empty")
	_assert(path[0] == Vector2i(10, 1), "path starts at entry")
	_assert(path[path.size() - 1] == Vector2i(15, 4), "path ends at crate_se")


func _test_crate_yields_ammo() -> void:
	var s := _make_scout()
	var oid := str(s.operators[0]["id"])
	var rounds_before := 0
	for a in s.kit.get("ammo_pools", []):
		if str(a.get("pool_id", "")) == "9mm":
			rounds_before = int(a.get("rounds", 0))
	_assert(_walk_to(s, oid, Vector2i(15, 4)), "walk to crate_se")
	# Finish open if still in progress.
	var guard := 0
	while guard < 80 and not bool(s._supply_by_id("crate_se").get("opened", false)):
		s.advance_one_tick()
		guard += 1
	_assert(bool(s._supply_by_id("crate_se").get("opened", false)), "crate_se opened")
	var rounds_after := rounds_before
	for a in s.kit.get("ammo_pools", []):
		if str(a.get("pool_id", "")) == "9mm":
			rounds_after = int(a.get("rounds", 0))
	_assert(rounds_after >= rounds_before + 16, "crate yields +16 9mm got=%d from=%d" % [rounds_after, rounds_before])
	var saw_pickup := false
	for e in s.log.events:
		if str(e.get("type", "")) == "pickup" and str(e.get("payload", {}).get("item_id", "")) == "ammo_9mm":
			saw_pickup = true
			_assert(str(e.get("payload", {}).get("label", "")).contains("弹药"), "pickup Chinese label")
	_assert(saw_pickup, "pickup event for ammo_9mm")


func _test_hidden_reveal_by_range() -> void:
	var s := _make_scout()
	var hid := s._supply_by_id("hidden_H")
	_assert(bool(hid.get("revealed", true)) == false, "hidden not revealed at start")
	# Far cell: still hidden.
	var oid := str(s.operators[0]["id"])
	_assert(_walk_to(s, oid, Vector2i(11, 2)), "walk near entry")
	_assert(bool(s._supply_by_id("hidden_H").get("revealed", false)) == false, "still hidden far away")
	# Approach within Chebyshev 2 of (21,5) → e.g. (19,5) or (21,5).
	_assert(_walk_to(s, oid, Vector2i(19, 5)), "walk within reveal range")
	_assert(bool(s._supply_by_id("hidden_H").get("revealed", false)) == true, "revealed within range")
	var saw_reveal := false
	for e in s.log.events:
		if str(e.get("type", "")) == "supply_reveal" and str(e.get("payload", {}).get("supply_id", "")) == "hidden_H":
			saw_reveal = true
	_assert(saw_reveal, "supply_reveal event logged")


func _test_mg42_locked_until_pickup() -> void:
	var s := _make_scout()
	_assert(s.mg42_unlocked() == false, "MG42 locked before pickup")
	var oid := str(s.operators[0]["id"])
	_assert(_walk_to(s, oid, Vector2i(21, 5)), "walk onto hidden_H")
	var guard := 0
	while guard < 120 and not bool(s._supply_by_id("hidden_H").get("opened", false)):
		s.advance_one_tick()
		guard += 1
	_assert(bool(s._supply_by_id("hidden_H").get("opened", false)), "hidden opened")
	_assert(s.mg42_unlocked() == true, "MG42 unlocked after pickup")
	var cnt := 0
	for w in s.kit.get("weapons", []):
		if str(w.get("weapon_id", "")) == "mg42":
			cnt = int(w.get("count", 0))
	_assert(cnt >= 1, "kit has MG42 count>=1")


func _test_budget_expiry_auto_advances() -> void:
	var s := _make_scout()
	_assert(s.is_finished() == false, "scout not finished at start")
	# Jump near end of budget then tick past.
	s.tick = s.budget_ticks() - 2
	s.advance_one_tick()
	_assert(s.is_finished() == false, "not finished one tick before budget")
	s.advance_one_tick()
	_assert(s.is_finished() == true, "budget expiry finishes scout")
	_assert(s.finish_reason == "budget", "finish_reason=budget")
	_assert(s.phase == "setup", "phase advances to setup")


func _test_ambush_golden_unchanged_after_scout_module() -> void:
	## Loading ScoutSim must not alter NightSim plan A golden.
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var plan := SimRunner.load_json("res://data/fixtures/plan_a.json")
	var weapons := SimWeapons.load_csv()
	var scout := ScoutSim.new()
	scout.setup(level)
	scout.begin_scout()
	scout.finish_scout("player")
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.begin_wait()
	while not sim.is_finished():
		sim.advance_one_tick()
	var summary := sim.outcome_summary()
	_assert(int(summary.get("detonate_tick", -1)) == 520, "after scout module plan A t0=520")
	_assert(bool(summary.get("standard_ambush", false)) == true, "after scout module standard_ambush")
	var batch: Dictionary = SimRunner.run_plan("res://data/fixtures/plan_a.json")
	_assert(str(summary.get("log_hash", "")) == str(batch.get("log_hash", "")), "after scout module hash matches run()")
