extends SceneTree

## W9: P0-4 playtest build switch + match log export.
## Playtest OFF must be unchanged; ON hides dev entries, ignores debug env hooks,
## and produces a JSON match log exportable from the result panel.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const PlaytestModeScript := preload("res://ui/playtest_mode.gd")
const MatchLogScript := preload("res://ui/match_log.gd")
const SimConstants := preload("res://sim/constants.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_playtest_source_flags()
	await _test_playtest_off_scene()
	await _test_playtest_on_lockdown()
	await _test_playtest_ignores_auto_env()
	await _test_playtest_match_log_export()
	print("W9_PLAYTEST_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _reset_env() -> void:
	OS.set_environment("AMBUSH_PLAYTEST", "")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_CAPTURE", "")
	OS.set_environment("AMBUSH_GREYBOX_FORCE_LEAK", "")
	OS.set_environment("AMBUSH_GREYBOX_ART", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _wait_scene_ready(max_frames: int = 90) -> Node:
	for _i in range(max_frames):
		await process_frame
		var scene = current_scene
		if scene != null and scene.has_method("can_start_wait"):
			return scene
	return current_scene


func _test_playtest_source_flags() -> void:
	_reset_env()
	OS.set_environment("AMBUSH_PLAYTEST", "1")
	_assert(PlaytestModeScript.is_enabled(), "playtest env=1 enabled")
	_assert(PlaytestModeScript.source() == "env", "playtest env=1 source=env")
	OS.set_environment("AMBUSH_PLAYTEST", "0")
	_assert(not PlaytestModeScript.is_enabled(), "playtest env=0 disabled")
	_assert(PlaytestModeScript.source() == "off", "playtest env=0 source=off")
	OS.set_environment("AMBUSH_PLAYTEST", "")
	_assert(not PlaytestModeScript.is_enabled(), "playtest env empty disabled (headless not web)")
	_reset_env()


func _test_playtest_off_scene() -> void:
	_reset_env()
	OS.set_environment("AMBUSH_PLAYTEST", "0")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "off scene change err=%s" % err)
	var scene = await _wait_scene_ready()
	_assert(scene != null, "off scene ready")
	if scene == null:
		_reset_env()
		return
	_assert(scene.playtest_mode == false, "off scene playtest_mode false")
	_assert(scene.btn_dev_toggle != null and scene.btn_dev_toggle.visible, "off dev toggle visible")
	var export_btn = scene.btn_rescout.get_parent().get_node_or_null("ExportLogButton")
	_assert(export_btn != null, "off export button exists")
	_assert(export_btn != null and not export_btn.visible, "off export button hidden")
	_reset_env()


func _test_playtest_on_lockdown() -> void:
	_reset_env()
	OS.set_environment("AMBUSH_PLAYTEST", "1")
	OS.set_environment("AMBUSH_GREYBOX_FORCE_LEAK", "1")
	OS.set_environment("AMBUSH_GREYBOX_CAPTURE", "user://w9_cap")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "on scene change err=%s" % err)
	var scene = await _wait_scene_ready()
	_assert(scene != null, "on scene ready")
	if scene == null:
		_reset_env()
		return
	_assert(scene.playtest_mode == true, "on playtest_mode true")
	_assert(str(scene.playtest_source) == "env", "on playtest_source env")
	_assert(not scene.dev_entries_visible(), "on dev entries hidden at boot")
	_assert(not scene.btn_dev_toggle.visible and scene.btn_dev_toggle.disabled, "on dev toggle hidden+disabled")
	scene.btn_dev_toggle.pressed.emit()
	_assert(not scene.dev_menu.visible, "on dev toggle press keeps menu closed")
	scene._toggle_example_plans()
	_assert(scene.example_plans_open == false, "on example plans stay closed")
	_assert(
		not scene.btn_plan_a.is_visible_in_tree() and not scene.btn_plan_b.is_visible_in_tree(),
		"on plan A/B hidden"
	)
	if scene.has_method("begin_setup_from_scout"):
		scene.begin_setup_from_scout()
		for _i in range(4):
			await process_frame
	var before: Array = []
	for op in scene.plan.get("operators", []):
		before.append(Vector2i(int(op.get("x", -1)), int(op.get("y", -1))))
	scene._load_preset("A")
	var after: Array = []
	for op in scene.plan.get("operators", []):
		after.append(Vector2i(int(op.get("x", -1)), int(op.get("y", -1))))
	_assert(before == after, "on _load_preset A ignored")
	var at_plan_a := false
	for p in after:
		if p == Vector2i(5, 9):
			at_plan_a = true
	_assert(not at_plan_a, "on operators not at plan A (5,9)")
	_assert(scene.force_leak_allowed() == false, "on force_leak_allowed false")
	_assert(scene.ui_phase == scene.UiPhase.SETUP, "on in SETUP phase")
	_assert(not scene.dev_entries_visible(), "on dev entries hidden in SETUP")
	_reset_env()


func _test_playtest_ignores_auto_env() -> void:
	_reset_env()
	OS.set_environment("AMBUSH_PLAYTEST", "1")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "auto+playtest scene change err=%s" % err)
	var scene = await _wait_scene_ready()
	_assert(scene != null, "auto+playtest scene ready")
	if scene == null:
		_reset_env()
		return
	for _i in range(120):
		await process_frame
	_assert(scene._headless_auto == false, "auto env ignored: _headless_auto false")
	_assert(scene.last_summary.is_empty(), "auto env ignored: last_summary empty")
	_assert(scene.ui_phase == scene.UiPhase.SCOUT, "auto env ignored: still SCOUT")
	_assert(not scene.dev_entries_visible(), "auto env ignored: dev entries hidden")
	_reset_env()


func _test_playtest_match_log_export() -> void:
	_reset_env()
	OS.set_environment("AMBUSH_PLAYTEST", "1")
	OS.set_environment("AMBUSH_GREYBOX_FORCE_LEAK", "1")
	OS.set_environment("AMBUSH_GREYBOX_CAPTURE", "user://w9_cap")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "log scene change err=%s" % err)
	var scene = await _wait_scene_ready()
	_assert(scene != null, "log scene ready")
	if scene == null:
		_reset_env()
		return
	var clock := {"ms": 0}
	scene.match_now_ms_fn = func():
		clock["ms"] = int(clock["ms"]) + 1000
		return int(clock["ms"])
	if scene.has_method("begin_setup_from_scout"):
		scene.begin_setup_from_scout()
		for _i in range(4):
			await process_frame
	var ops: Array = scene.plan.get("operators", [])
	_assert(ops.size() >= 3, "log scripted placement has operators")
	if ops.size() < 3 or scene.grid == null:
		_reset_env()
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
	scene._start_wait()
	scene.paused = true
	var guard := 0
	while not scene.sim.is_finished() and guard < 20000:
		scene.sim.advance_one_tick()
		scene._consume_sim_log()
		guard += 1
	_assert(scene.sim.is_finished(), "log sim finished guard=%d" % guard)
	scene._show_result()
	var log: Dictionary = scene.last_match_log
	var missing: Array = []
	for k in MatchLogScript.required_keys():
		if not log.has(k):
			missing.append(k)
	_assert(missing.is_empty(), "match log has all required keys missing=%s" % str(missing))
	_assert(not log.is_empty(), "match log non-empty")
	_assert(str(log.get("schema", "")) == "ambush_match_log/1", "match log schema")
	_assert(bool(log.get("playtest", false)) == true, "match log playtest true")
	var beats: Dictionary = log.get("beats_ms", {})
	var beats_ok := true
	for bk in ["scout", "setup", "wait", "fire"]:
		if not beats.has(bk) or typeof(beats[bk]) != TYPE_INT or int(beats[bk]) < 0:
			beats_ok = false
	_assert(beats_ok, "beats_ms four int keys >=0 got=%s" % str(beats))
	_assert(int(beats.get("setup", 0)) > 0, "beats_ms setup >0")
	_assert(int(beats.get("fire", 0)) > 0, "beats_ms fire >0")
	var plan_log: Dictionary = log.get("plan", {})
	var ops_log: Array = plan_log.get("operators", [])
	_assert(ops_log.size() == 3, "match log plan operators size 3 got=%d" % ops_log.size())
	var xy_ok := true
	for op in ops_log:
		if not (op is Dictionary) or not op.has("x") or not op.has("y"):
			xy_ok = false
	_assert(xy_ok, "match log plan operators have x/y")
	_assert(
		plan_log.has("grenades") and plan_log.has("trigger"),
		"match log plan has grenades+trigger keys got=%s" % str(plan_log.keys())
	)
	var trig_log: Dictionary = plan_log.get("trigger", {})
	_assert(
		str(trig_log.get("type", "")) == "cross_marker",
		"match log plan trigger cross_marker got=%s" % str(trig_log.get("type", ""))
	)
	var fires: Array = log.get("fires", [])
	_assert(not fires.is_empty(), "match log fires non-empty")
	_assert(int(log.get("fire_count", -1)) == fires.size(), "fire_count == fires.size()")
	var fire_ok := true
	for f in fires:
		if not (f is Dictionary):
			fire_ok = false
			continue
		for fk in ["tick", "t_s", "actor", "weapon_id", "target"]:
			if not f.has(fk):
				fire_ok = false
	_assert(fire_ok, "each fire has tick/t_s/actor/weapon_id/target")
	var fire_t_s_ok := true
	for f in fires:
		if not (f is Dictionary):
			fire_t_s_ok = false
			continue
		var want_t_s := float(int(f.get("tick", 0))) * float(SimConstants.DT_S)
		if absf(float(f.get("t_s", 0.0)) - want_t_s) >= 1e-6:
			fire_t_s_ok = false
	_assert(fire_t_s_ok, "each fire t_s == tick*DT_S")
	for arr_key in ["kills", "escapes", "wounded", "dead_ops"]:
		_assert(typeof(log.get(arr_key, null)) == TYPE_ARRAY, "match log %s is array" % arr_key)
	var ts_re := RegEx.new()
	ts_re.compile("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$")
	_assert(
		ts_re.search(str(log.get("started_at", ""))) != null,
		"started_at pattern got=%s" % str(log.get("started_at", ""))
	)
	_assert(
		ts_re.search(str(log.get("ended_at", ""))) != null,
		"ended_at pattern got=%s" % str(log.get("ended_at", ""))
	)
	_assert(float(log.get("duration_s", -1.0)) >= 0.0, "duration_s >= 0 got=%s" % str(log.get("duration_s", null)))
	_assert(str(log.get("outcome", "")) in ["win", "lose"], "match log outcome win|lose got=%s" % log.get("outcome"))
	_assert(int(log.get("detonate_tick", -1)) >= 0, "match log detonate_tick >= 0")
	var path := str(scene.last_match_log_path)
	var re := RegEx.new()
	re.compile("^match_\\d{8}_\\d{6}(_\\d+)?\\.json$")
	_assert(path.begins_with("user://match_logs/match_"), "log path prefix got=%s" % path)
	_assert(re.search(path.get_file()) != null, "log filename pattern got=%s" % path.get_file())
	_assert(FileAccess.file_exists(path), "log file exists")
	var fr := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(fr.get_as_text()) if fr != null else null
	_assert(typeof(parsed) == TYPE_DICTIONARY, "log file parses to dictionary")
	if typeof(parsed) == TYPE_DICTIONARY:
		var pd: Dictionary = parsed
		var miss2: Array = []
		for k in MatchLogScript.required_keys():
			if not pd.has(k):
				miss2.append(k)
		_assert(miss2.is_empty(), "parsed log has all required keys missing=%s" % str(miss2))
		_assert(str(pd.get("outcome", "")) == str(log.get("outcome", "")), "parsed log outcome matches")
	var export_btn = scene.btn_rescout.get_parent().get_node_or_null("ExportLogButton")
	_assert(export_btn != null and export_btn.is_visible_in_tree(), "export button visible in RESULT")
	_assert(scene.export_match_log() == true, "export_match_log returns true")
	_assert(int(scene.export_count) == 1, "export_count == 1")
	_assert(not scene.dev_entries_visible(), "dev entries still hidden at result")
	_reset_env()
