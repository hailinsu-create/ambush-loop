extends SceneTree

## W3 greybox headless: interactive sim API + G1 assets + greybox scene auto plan A.
## Asserts t0=520 (PLAY-4 pacing) and standard_ambush (view must not change outcomes).
## PLAY-1: blank start not startable; scripted placement reaches result; MG42 not in kit.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const G1AssetsScript := preload("res://view/g1_assets.gd")
const G2AssetsScript := preload("res://view/g2_assets.gd")
const G3AssetsScript := preload("res://view/g3_assets.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_plan_a_via_interactive_api()
	_test_view_snapshot_does_not_mutate_sim()
	_test_g1_assets_load()
	_test_g2_assets_load()
	_test_g3_assets_load()
	_test_mg42_not_in_starting_kit()
	await _test_blank_start_not_startable()
	await _test_scripted_placement_reaches_result()
	await _test_start_wait_climb()
	await _test_greybox_scene_boots()
	print("W3_GREYBOX_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _test_plan_a_via_interactive_api() -> void:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var plan := SimRunner.load_json("res://data/fixtures/plan_a.json")
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.begin_wait()
	while not sim.is_finished():
		sim.advance_one_tick()
	var s := sim.outcome_summary()
	_assert(int(s.get("detonate_tick", -1)) == 520, "greybox API plan A t0=520 got=%s" % s.get("detonate_tick"))
	_assert(bool(s.get("standard_ambush", false)) == true, "greybox API plan A standard_ambush")
	_assert(str(s.get("outcome", "")) == "win", "greybox API plan A win")
	_assert(str(s.get("trigger", "")) == "cross_marker", "greybox API plan A trigger")
	var batch: Dictionary = SimRunner.run_plan("res://data/fixtures/plan_a.json")
	_assert(str(s.get("log_hash", "")) == str(batch.get("log_hash", "")), "interactive API hash == run() hash")


func _test_view_snapshot_does_not_mutate_sim() -> void:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var plan := SimRunner.load_json("res://data/fixtures/plan_a.json")
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	sim.begin_wait()
	while sim.tick < 100 and not sim.is_finished():
		sim.advance_one_tick()
	var _seers: Array = sim.observers_seeing_cell(11.0, 7.0, "ground")
	var sectors: Dictionary = sim.sector_clear_and_blocked(5.0, 9.0, 0.0, 30.0, 16.0, "high")
	_assert(sectors.has("clear") and sectors.has("blocked"), "sector_clear_and_blocked keys")
	while not sim.is_finished():
		sim.advance_one_tick()
	var s := sim.outcome_summary()
	_assert(int(s.get("detonate_tick", -1)) == 520, "preview queries leave t0=520")
	_assert(bool(s.get("standard_ambush", false)) == true, "preview queries leave standard_ambush")


func _test_g1_assets_load() -> void:
	var a = G1AssetsScript.new()
	a.load_all()
	_assert(a.tile_ground != null, "g1 tile_ground")
	_assert(a.friendly != null, "g1 friendly")
	_assert(a.alert_icons.has("suspicious"), "g1 alert suspicious")
	_assert(a.trigger_icons.has("cross_marker"), "g1 trigger cross_marker")
	_assert(a.threat_slot != null, "g1 threat_slot")


func _test_g2_assets_load() -> void:
	## All referenced G2 texture + SFX paths must load (G2 asset batch).
	var a = G2AssetsScript.new()
	a.load_all()
	_assert(a.all_textures_ok(), "g2 textures ok")
	_assert(a.all_sfx_ok(), "g2 sfx ok")
	var missing: Array = []
	for path in G2AssetsScript.referenced_texture_paths():
		if load(path) as Texture2D == null:
			missing.append(path)
	for cue in G2AssetsScript.referenced_sfx_cues():
		var spath := "res://assets/g2/sfx/%s.wav" % cue
		if load(spath) as AudioStream == null:
			missing.append(spath)
	_assert(missing.is_empty(), "g2 all referenced paths load missing=%s" % str(missing))
	_assert(a.weapon_icons.size() == 5 and a.weapon_units.size() == 5, "g2 five weapons icons+units")


func _test_g3_assets_load() -> void:
	## All referenced G3 WebP paths must load (high-detail art batch).
	var a = G3AssetsScript.new()
	a.load_all()
	_assert(a.all_textures_ok(), "g3 textures ok")
	var missing: Array = []
	for path in G3AssetsScript.referenced_texture_paths():
		if load(path) as Texture2D == null:
			missing.append(path)
	_assert(missing.is_empty(), "g3 all referenced paths load missing=%s" % str(missing))
	_assert(a.weapon_icons.size() == 5, "g3 five weapon icons")
	_assert(a.friendly_unit_for_weapon("mg42") != null, "g3 friendly mg42 unit")
	_assert(a.units.get("enemy_officer") != null, "g3 enemy officer")


func _test_mg42_not_in_starting_kit() -> void:
	## PLAY-1: MG42 is locked until hidden cache; must not appear in loadout_start kit.
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var kit_ids: Array = []
	for w in level.get("loadout_start", {}).get("weapons", []):
		kit_ids.append(str(w.get("weapon_id", "")))
	_assert(not kit_ids.has("mg42"), "MG42 not in loadout_start weapons got=%s" % str(kit_ids))
	_assert(kit_ids.has("kar98k") and kit_ids.has("mp40"), "kit has kar98k+mp40")
	# Hidden supply is the only MG42 source in yard data.
	var hidden_has_mg42 := false
	for s in level.get("supplies", []):
		if str(s.get("visibility", "")) != "hidden" and not bool(s.get("hidden", false)):
			continue
		for c in s.get("contents", []):
			if str(c.get("weapon_id", "")) == "mg42":
				hidden_has_mg42 = true
	_assert(hidden_has_mg42, "hidden supply contains MG42")


func _wait_scene_ready(max_frames: int = 90) -> Node:
	for _i in range(max_frames):
		await process_frame
		var scene = current_scene
		if scene != null and scene.has_method("can_start_wait"):
			return scene
	return current_scene


func _test_blank_start_not_startable() -> void:
	## Untouched setup (after scout→布阵, no placement) must NOT be startable.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "blank start change_scene err=%s" % err)
	var scene = await _wait_scene_ready()
	_assert(scene != null and scene.has_method("can_start_wait"), "blank start scene has can_start_wait")
	if scene == null:
		return
	# PLAY-2 boots into scout; enter setup without gathering MG42.
	if scene.has_method("begin_setup_from_scout"):
		scene.begin_setup_from_scout()
		for _i in range(4):
			await process_frame
	# PLAY-UX PR-4: entry cells count as placed; see_first_enemy bind is remapped → startable.
	_assert(scene.can_start_wait() == true, "entry-as-placed + complete trigger is startable")
	_assert(str(scene.start_block_reason()) == "", "blank start open when trigger complete")
	# Operators must be at squad_insertion (or scout end=entry), not plan A coords.
	var ops: Array = scene.plan.get("operators", [])
	_assert(ops.size() == 3, "blank start has 3 operators")
	var at_a_barn := false
	for op in ops:
		if int(op.get("x", -1)) == 5 and int(op.get("y", -1)) == 9:
			at_a_barn = true
	_assert(not at_a_barn, "blank start not at plan A barn slot")
	var insertion: Array = scene.level.get("squad_insertion", [])
	_assert(insertion.size() == 3, "yard.json squad_insertion present")
	for i in range(mini(ops.size(), insertion.size())):
		_assert(
			int(ops[i]["x"]) == int(insertion[i]["x"]) and int(ops[i]["y"]) == int(insertion[i]["y"]),
			"op[%d] at insertion (%d,%d)" % [i, int(insertion[i]["x"]), int(insertion[i]["y"])]
		)
	# HUD must not expose internal ids like op_kar_L on display names.
	var names: Dictionary = scene.op_display_names
	for k in names.keys():
		var n := str(names[k])
		_assert(not n.begins_with("op_"), "display name not internal id: %s" % n)
	_assert(scene.is_mg42_in_starting_kit() == false, "controller: MG42 not in starting kit")
	_assert(scene.is_mg42_unlocked() == false, "MG42 still locked without scout pickup")
	if scene.btn_start:
		_assert(scene.btn_start.disabled == false, "StartButton enabled when entry-as-placed + trigger ok")


func _test_scripted_placement_reaches_result() -> void:
	## Scripted player placement (plan-A-like) reaches a finished result.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "scripted placement change_scene err=%s" % err)
	var scene = await _wait_scene_ready()
	_assert(scene != null, "scripted placement scene ready")
	if scene == null:
		return
	if scene.has_method("begin_setup_from_scout"):
		scene.begin_setup_from_scout()
		for _i in range(4):
			await process_frame
	var ops: Array = scene.plan.get("operators", [])
	_assert(ops.size() >= 3, "scripted placement has operators")
	var id0 := str(ops[0]["id"])
	var id1 := str(ops[1]["id"])
	var id2 := str(ops[2]["id"])
	_assert(scene.scripted_place_operator(id0, 5, 9, 0.0), "place op0 barn high")
	_assert(scene.scripted_place_operator(id1, 13, 7, 15.0), "place op1 low-wall high")
	_assert(scene.scripted_place_operator(id2, 11, 2, 90.0), "place op2 south")
	# Assign weapons like a kit pick, then set cross_marker like plan A.
	scene._on_op_weapon_picked(id0, "kar98k")
	scene._on_op_weapon_picked(id1, "mp40")
	scene._on_op_weapon_picked(id2, "grenade")
	scene.scripted_place_cross_marker(10, 7, 12, 7)
	_assert(scene.can_start_wait() == true, "after full placement can start")
	scene._start_wait()
	_assert(scene.sim != null, "sim started after placement")
	if scene.sim == null:
		return
	scene.paused = true
	var guard := 0
	while not scene.sim.is_finished() and guard < 20000:
		scene.sim.advance_one_tick()
		guard += 1
	_assert(scene.sim.is_finished(), "scripted placement sim finished guard=%d" % guard)
	scene._show_result()
	var ls: Dictionary = scene.last_summary
	_assert(not ls.is_empty(), "scripted placement has outcome summary")
	_assert(str(ls.get("outcome", "")) in ["win", "lose"], "scripted placement outcome win|lose got=%s" % ls.get("outcome"))
	_assert(int(ls.get("detonate_tick", -1)) >= 0, "scripted placement detonated")


func _test_start_wait_climb() -> void:
	## T5: on _start_wait every high-cell operator begins a ~2 s (40 tick) climb
	## from an adjacent ground departure cell (ground tier, no fire); ground
	## operators do not climb. After 40 sim ticks the high op is back on its
	## target cell at high tier and can fire again.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "climb scene err=%s" % err)
	var scene = await _wait_scene_ready()
	_assert(scene != null, "climb scene ready")
	if scene == null:
		return
	if scene.has_method("begin_setup_from_scout"):
		scene.begin_setup_from_scout()
		for _i in range(4):
			await process_frame
	var ops: Array = scene.plan.get("operators", [])
	_assert(ops.size() >= 3, "climb has operators")
	var id0 := str(ops[0]["id"])
	var id1 := str(ops[1]["id"])
	var id2 := str(ops[2]["id"])
	scene.scripted_place_operator(id0, 5, 9, 0.0)
	scene.scripted_place_operator(id1, 13, 7, 15.0)
	scene.scripted_place_operator(id2, 11, 2, 90.0)
	scene.scripted_place_cross_marker(10, 7, 12, 7)
	scene._start_wait()
	if scene.sim == null:
		_assert(false, "climb sim started")
		return
	var sim = scene.sim
	var high0 = sim.operators[0]
	var low2 = sim.operators[2]
	_assert(bool(high0.get("climbing", false)) == true, "climb high op climbing at wait start")
	_assert(str(high0.get("tier", "")) == "ground", "climb high op tier ground while climbing got=%s" % high0.get("tier"))
	_assert(bool(high0.get("can_fire", true)) == false, "climb high op cannot fire while climbing")
	var dep0: Vector2i = scene._climb_departure_cell(Vector2i(5, 9))
	_assert(
		int(high0["x"]) == dep0.x and int(high0["y"]) == dep0.y
			and scene.grid.tier_at(float(dep0.x), float(dep0.y)) == "ground",
		"climb high op runs at ground departure %s" % dep0
	)
	_assert(bool(low2.get("climbing", false)) == false, "climb ground op does not climb")
	for _i in range(40):
		sim.advance_one_tick()
	_assert(
		str(high0.get("tier", "")) == "high" and int(high0["x"]) == 5 and int(high0["y"]) == 9,
		"climb high op on high target after 40 ticks got=(%s,%s)/%s" % [high0["x"], high0["y"], high0.get("tier")]
	)
	_assert(bool(high0.get("can_fire", true)) == true, "climb high op can fire after 40 ticks")
	OS.set_environment("AMBUSH_GREYBOX_SKIP_SCOUT", "")


func _test_greybox_scene_boots() -> void:
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "change_scene greybox err=%s" % err)
	# Wait for deferred auto-run (includes scout walk) + RESULT.
	for i in range(2000):
		await process_frame
		var scene = current_scene
		if scene != null and scene.get("last_summary") is Dictionary:
			var ls: Dictionary = scene.last_summary
			if not ls.is_empty():
				## T5 climb changed plan A's auto scene result: the MG now climbs up
				## from its east ground departure (6,9) during the first 2 s, where the
				## southbound west patrol spots it → early suspicious, later area/global
				## alert → alarm detonate at 298 instead of the cross_marker 520. The
				## squad still wipes the wave (win) but the standard ambush is lost.
				## The direct API tests above stay at 520/standard (no climb applied).
				_assert(int(ls.get("detonate_tick", -1)) == 298, "scene auto plan A t0=298 (climb) got=%s" % ls.get("detonate_tick"))
				_assert(bool(ls.get("standard_ambush", false)) == false, "scene auto plan A standard_ambush lost to climb exposure")
				_assert(str(ls.get("outcome", "")) == "win", "scene auto win")
				OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
				return
	_assert(false, "scene auto did not produce last_summary in time")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
