extends SceneTree

## T8: level registry + selection + per-level golden contract.
## Launch only via scripts/run_isolated_test.sh|.ps1.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const SimLevels := preload("res://sim/levels.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")

const TICK_HZ := 20
const T0_A := 520
const T0_B := 560
const PLAN_KEYS := ["plan_a", "plan_b"]

var _failed := 0
var _passed := 0
var _orig_level_env := ""


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	_orig_level_env = OS.get_environment("AMBUSH_LEVEL")
	_run_all()
	OS.set_environment("AMBUSH_LEVEL", _orig_level_env)
	print("W3_LEVEL_CONTRACT_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _run_all() -> void:
	_test_registry_contract()
	_test_fixture_wins()
	_test_named_lose_cases()
	_test_deterministic_golden_hashes()
	_test_resolve_id()
	_test_selected_id()
	_test_runner_defaults()


func _test_registry_contract() -> void:
	var reg := SimLevels.registry()
	_assert(not reg.is_empty(), "registry non-empty")
	_assert(reg.has(SimLevels.DEFAULT_ID), "registry has DEFAULT_ID=%s" % SimLevels.DEFAULT_ID)
	var ids := SimLevels.ids()
	_assert(not ids.is_empty(), "ids non-empty")
	var sorted_ids: Array = ids.duplicate()
	sorted_ids.sort()
	_assert(ids == sorted_ids, "ids sorted stable got=%s" % str(ids))
	_assert(ids.size() >= 2 or ids.has("yard"), "yard registered")
	for id_v in ids:
		var id := str(id_v)
		_assert(SimLevels.has(id), "has(%s)" % id)
		var path := SimLevels.path_for(id)
		_assert(FileAccess.file_exists(path), "%s path exists: %s" % [id, path])
		var level := SimLevelLoader.load_path(path)
		_assert(not level.is_empty(), "%s load_path succeeds" % id)
		_assert(SimLevelLoader.validate(level).is_empty(), "%s passes validate" % id)
		_assert(str(level.get("id", "")) == id, "%s level.id matches registry" % id)
		var golden := SimLevels.golden_path_for(id)
		_assert(FileAccess.file_exists(golden), "%s golden exists: %s" % [id, golden])
		var fixtures := SimLevels.fixtures_for(id)
		for plan_key in PLAN_KEYS:
			_assert(fixtures.has(plan_key), "%s fixture %s registered" % [id, plan_key])
			var fixture_path := str(fixtures.get(plan_key, ""))
			_assert(FileAccess.file_exists(fixture_path), "%s fixture %s exists: %s" % [id, plan_key, fixture_path])


func _test_fixture_wins() -> void:
	for id_v in SimLevels.ids():
		var id := str(id_v)
		var fixtures := SimLevels.fixtures_for(id)
		for plan_key in PLAN_KEYS:
			var plan := SimRunner.load_json(str(fixtures[plan_key]))
			var summary := SimRunner.run_level_plan(id, plan)
			_assert(str(summary.get("outcome", "")) == "win",
				"%s/%s wins got=%s" % [id, plan_key, summary.get("outcome")])


func _test_named_lose_cases() -> void:
	var cases := {
		"F-A30": _plan_f_a30(),
		"T-B+4": _plan_t_b_plus4(),
	}
	for id_v in cases.keys():
		var id := str(id_v)
		var summary := SimRunner.run_level_plan(SimLevels.DEFAULT_ID, cases[id])
		_assert(str(summary.get("outcome", "")) == "lose",
			"named counterexample %s loses got=%s" % [id, summary.get("outcome")])


func _plan_f_a30() -> Dictionary:
	var plan := SimRunner.load_json(str(SimLevels.fixtures_for(SimLevels.DEFAULT_ID)["plan_a"]))
	plan["operators"][0]["facing_deg"] = float(plan["operators"][0]["facing_deg"]) + 30.0
	return plan


func _plan_t_b_plus4() -> Dictionary:
	var plan := SimRunner.load_json(str(SimLevels.fixtures_for(SimLevels.DEFAULT_ID)["plan_b"]))
	plan["trigger"] = {"type": "manual"}
	plan["manual_detonate_tick"] = T0_B + 4 * TICK_HZ
	plan["mines"] = []
	return plan


func _test_deterministic_golden_hashes() -> void:
	for id_v in SimLevels.ids():
		var id := str(id_v)
		var golden_path := SimLevels.golden_path_for(id)
		var f := FileAccess.open(golden_path, FileAccess.READ)
		var exp_v: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
		_assert(typeof(exp_v) == TYPE_DICTIONARY, "%s golden parses" % id)
		if typeof(exp_v) != TYPE_DICTIONARY:
			continue
		var exp: Dictionary = exp_v
		var fixtures := SimLevels.fixtures_for(id)
		for plan_key in PLAN_KEYS:
			var plan_path := str(fixtures[plan_key])
			var first := SimRunner.run_level_plan(id, SimRunner.load_json(plan_path))
			var second := SimRunner.run_level_plan(id, SimRunner.load_json(plan_path))
			var first_hash := str(first.get("log_hash", ""))
			var second_hash := str(second.get("log_hash", ""))
			_assert(first_hash == second_hash, "%s/%s hash deterministic" % [id, plan_key])
			_assert(first_hash == str(exp.get(plan_key, "")), "%s/%s hash matches golden" % [id, plan_key])
			var t0_key := "t0_a" if plan_key == "plan_a" else "t0_b"
			var t0 := int(first.get("detonate_tick", -1))
			_assert(t0 == int(exp.get(t0_key, -1)), "%s/%s t0=%d matches golden %s" % [id, plan_key, t0, t0_key])
		_assert(int(exp.get("t0_a", -1)) == T0_A, "%s golden t0_a=%d" % [id, T0_A])
		_assert(int(exp.get("t0_b", -1)) == T0_B, "%s golden t0_b=%d" % [id, T0_B])


func _test_resolve_id() -> void:
	_assert(SimLevels.resolve_id("") == "yard", "resolve_id empty -> yard")
	_assert(SimLevels.resolve_id("YARD ") == "yard", "resolve_id 'YARD ' -> yard")
	_assert(SimLevels.resolve_id("nope") == "yard", "resolve_id unknown -> yard")
	_assert(SimLevels.path_for("nope") == SimLevels.path_for("yard"), "path_for unknown falls back to yard")


func _test_selected_id() -> void:
	OS.set_environment("AMBUSH_LEVEL", "yard")
	_assert(SimLevels.selected_id() == "yard", "selected_id env yard")
	_assert(SimLevels.selection_source() == "env", "selection_source env")
	OS.set_environment("AMBUSH_LEVEL", "nope")
	_assert(SimLevels.selected_id() == "yard", "selected_id unknown env falls back to yard")
	_assert(SimLevels.selection_source() == "env_unknown", "selection_source env_unknown")
	OS.set_environment("AMBUSH_LEVEL", "")
	_assert(SimLevels.selected_id() == "yard", "selected_id cleared env -> default yard")
	_assert(SimLevels.selection_source() == "default", "selection_source default")


func _test_runner_defaults() -> void:
	var plan := SimRunner.load_json(str(SimLevels.fixtures_for(SimLevels.DEFAULT_ID)["plan_a"]))
	var default_summary := SimRunner.run_plan_dict(plan)
	var explicit_summary := SimRunner.run_plan_dict(plan, SimLevels.path_for("yard"))
	var level_summary := SimRunner.run_level_plan("yard", plan)
	var explicit_hash := str(explicit_summary.get("log_hash", ""))
	_assert(str(default_summary.get("log_hash", "")) == explicit_hash, "run_plan_dict default == explicit yard")
	_assert(str(level_summary.get("log_hash", "")) == explicit_hash, "run_level_plan yard == explicit yard")
