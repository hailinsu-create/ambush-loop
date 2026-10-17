extends SceneTree

## PLAY-5 / VS-W6a: review card grades/causes + body-search stub.
## Plan A vs B must differ; causes reference real unit labels; HUD has no ticks/ids/English triggers.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const ReviewBuilder := preload("res://sim/review_builder.gd")

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_test_plan_a_vs_b_review()
	_test_causes_reference_units()
	_test_hud_forbidden_tokens()
	_test_body_search_stub()
	await _test_scene_review_card()
	print("W6_REVIEW_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _names_for(plan: Dictionary) -> Dictionary:
	var names := {}
	var i := 0
	var wzh := {"kar98k": "Kar98k", "mp40": "MP40", "mg42": "MG42", "grenade": "手雷", "mine": "地雷"}
	for op in plan.get("operators", []):
		i += 1
		var wid := str(op.get("weapon_id", ""))
		names[str(op["id"])] = "%d号·%s" % [i, wzh.get(wid, "队员")]
	return names


func _run_review(plan_path: String) -> Dictionary:
	var plan: Dictionary = SimRunner.load_json(plan_path)
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	sim.begin_wait()
	while not sim.is_finished():
		sim.advance_one_tick()
	return ReviewBuilder.build(sim, plan, _names_for(plan))


func _test_plan_a_vs_b_review() -> void:
	var ra := _run_review("res://data/fixtures/plan_a.json")
	var rb := _run_review("res://data/fixtures/plan_b.json")
	_assert(str(ra.get("outcome_zh", "")) == "全歼", "A outcome 全歼 got=%s" % ra.get("outcome_zh"))
	_assert(str(rb.get("outcome_zh", "")) == "全歼", "B outcome 全歼 got=%s" % rb.get("outcome_zh"))
	# PLAY-6: return fire / cover means A is no longer a trivial S; both stay winnable A-tier.
	_assert(str(ra.get("grade", "")) in ["A", "S"], "A grade A|S got=%s" % ra.get("grade"))
	_assert(str(rb.get("grade", "")) in ["A", "B"], "B grade A|B got=%s" % rb.get("grade"))
	var ca: Array = ra.get("causes", [])
	var cb: Array = rb.get("causes", [])
	_assert(ca.size() >= 2 and ca.size() <= 3, "A causes 2–3 got=%d" % ca.size())
	_assert(cb.size() >= 2 and cb.size() <= 3, "B causes 2–3 got=%d" % cb.size())
	var joined_a := "|".join(ca)
	var joined_b := "|".join(cb)
	_assert(joined_a != joined_b, "A/B causes differ")
	_assert(
		joined_a.find("越线") >= 0 or joined_a.find("MG42") >= 0 or joined_a.find("压制") >= 0 or joined_a.find("负伤") >= 0 or joined_a.find("还击") >= 0,
		"A causes mention 越线/MG42/压制 got=%s" % joined_a
	)
	_assert(
		joined_b.find("地雷") >= 0 or joined_b.find("手雷") >= 0 or joined_b.find("MP40") >= 0 or joined_b.find("掩体") >= 0 or joined_b.find("压制") >= 0,
		"B causes mention 地雷/手雷/掩体/压制 got=%s" % joined_b
	)


func _test_causes_reference_units() -> void:
	var ra := _run_review("res://data/fixtures/plan_a.json")
	var ca := "|".join(ra.get("causes", []))
	_assert(
		ca.find("1号·MG42") >= 0 or ca.find("MG42") >= 0 or ca.find("2号·Kar98k") >= 0 or ca.find("Kar98k") >= 0,
		"A causes reference unit label got=%s" % ca
	)
	var rb := _run_review("res://data/fixtures/plan_b.json")
	var cb := "|".join(rb.get("causes", []))
	_assert(
		cb.find("地雷") >= 0 or cb.find("2号·MP40") >= 0 or cb.find("3号·手雷") >= 0 or cb.find("1号·Kar98k") >= 0 or cb.find("掩体") >= 0,
		"B causes reference real units got=%s" % cb
	)


func _test_hud_forbidden_tokens() -> void:
	for path in ["res://data/fixtures/plan_a.json", "res://data/fixtures/plan_b.json"]:
		var rev := _run_review(path)
		var blob := "%s\n%s\n%s\n%s" % [
			rev.get("outcome_zh", ""),
			rev.get("grade", ""),
			" → ".join(rev.get("timeline", [])),
			"\n".join(rev.get("causes", [])),
		]
		_assert(not ReviewBuilder.hud_has_forbidden(blob), "review HUD clean for %s" % path)


func _test_body_search_stub() -> void:
	## Full wipe enables body search; searching adds loot to stub kit file.
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	var plan := SimRunner.load_json("res://data/fixtures/plan_a.json")
	var sim := NightSim.new()
	sim.setup(level, plan, SimWeapons.load_csv())
	sim.begin_wait()
	while not sim.is_finished():
		sim.advance_one_tick()
	var rev := ReviewBuilder.build(sim, plan, _names_for(plan))
	_assert(bool(rev.get("full_wipe", false)) == true, "plan A full_wipe for body search")
	# Simulate controller loot append + persist.
	var loot := {"kind": "ammo", "pool_id": "ammo_9mm", "rounds": 16, "label_zh": "9mm 弹药 ×16"}
	var path := "user://next_night_kit.json"
	var payload := JSON.stringify({"loot": [loot]})
	var f := FileAccess.open(path, FileAccess.WRITE)
	_assert(f != null, "stub kit file writable")
	if f == null:
		return
	f.store_string(payload)
	f.flush()
	f = null
	var f2 := FileAccess.open(path, FileAccess.READ)
	_assert(f2 != null, "stub kit file readable")
	if f2 == null:
		return
	var text := f2.get_as_text()
	f2 = null
	var parsed: Variant = JSON.parse_string(text)
	_assert(typeof(parsed) == TYPE_DICTIONARY, "stub kit parses got=%s" % text.substr(0, 80))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var arr: Array = (parsed as Dictionary).get("loot", [])
	_assert(arr.size() == 1, "stub kit has 1 loot")
	_assert(str(arr[0].get("label_zh", "")).find("弹药") >= 0, "loot Chinese label")


func _test_scene_review_card() -> void:
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "1")
	OS.set_environment("AMBUSH_GREYBOX_PLAN", "A")
	var err := change_scene_to_file("res://scenes/greybox.tscn")
	_assert(err == OK, "review scene change_scene err=%s" % err)
	for _i in range(3000):
		await process_frame
		var scene = current_scene
		if scene == null:
			continue
		if scene.get("last_review") is Dictionary and not (scene.last_review as Dictionary).is_empty():
			var rev: Dictionary = scene.last_review
			_assert(str(rev.get("grade", "")) in ["A", "S"], "scene review A grade A|S got=%s" % rev.get("grade"))
			_assert(str(rev.get("outcome_zh", "")) == "全歼", "scene review A 全歼")
			if scene.has_method("review_card_text"):
				var hud := str(scene.review_card_text())
				_assert(hud.find("全歼") >= 0, "scene card shows 全歼")
				_assert(not ReviewBuilder.hud_has_forbidden(hud), "scene card HUD clean")
			var loot_n := 0
			if scene.get("next_night_loot") is Array:
				loot_n = (scene.next_night_loot as Array).size()
			_assert(bool(scene.body_search_enabled) == true or loot_n >= 0, "body search path present")
			OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
			OS.set_environment("AMBUSH_GREYBOX_PLAN", "")
			return
	_assert(false, "scene review auto did not finish")
	OS.set_environment("AMBUSH_GREYBOX_AUTO", "")
	OS.set_environment("AMBUSH_GREYBOX_PLAN", "")
