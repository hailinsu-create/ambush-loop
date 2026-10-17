extends SceneTree

## W3 greybox headless: interactive sim API + G1 assets + greybox scene auto plan A.
## Asserts t0=280 and standard_ambush (view must not change outcomes).

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
	_assert(int(s.get("detonate_tick", -1)) == 280, "greybox API plan A t0=280 got=%s" % s.get("detonate_tick"))
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
	_assert(int(s.get("detonate_tick", -1)) == 280, "preview queries leave t0=280")
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


func _test_greybox_scene_boots() -> void:
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "1")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "change_scene greybox err=%s" % err)
	# Wait for deferred auto-run + a few frames of RESULT.
	for i in range(120):
		await process_frame
		var scene = current_scene
		if scene != null and scene.get("last_summary") is Dictionary:
			var ls: Dictionary = scene.last_summary
			if not ls.is_empty():
				_assert(int(ls.get("detonate_tick", -1)) == 280, "scene auto plan A t0=280 got=%s" % ls.get("detonate_tick"))
				_assert(bool(ls.get("standard_ambush", false)) == true, "scene auto standard_ambush")
				_assert(str(ls.get("outcome", "")) == "win", "scene auto win")
				OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
				return
	_assert(false, "scene auto did not produce last_summary in time")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
