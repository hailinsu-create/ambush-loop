extends SceneTree

## P0-2 / G.1: example A/B still win under stand ±1 and facing ±5°.
##
## Contract (finger tolerance on the *intended* pad, not every Cartesian neighbor):
## 1) Published cell × facing ±5° — always.
## 2) Stand ±1 only on role-legal cells:
##    - high tier → same `high_slot` footprint
##    - ground with cover at home → ±1 neighbors that also have cover (cover pad)
##    - open ground → full Chebyshev ±1
## 3) Offset cells re-aim to the plan's intent landmark (巷口 / 路口 / 南门),
##    then ±5° — matching magnifier snap then finger error.
## 4) P0-1 facing counterex (±30/±60 on key shooter) still D.3-true.
##
## Launch only via scripts/run_isolated_test.sh|.ps1.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const SimRunner := preload("res://sim/runner.gd")
const AimSnap := preload("res://sim/aim_snap.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimGeom := preload("res://sim/geom.gd")

## T7 yard v1.7: every cover-pad ±1 cell must either win or be explicitly
## forbidden in the level (`no_place` + Chinese reason, rejected by the controller).
## The old T6 finger-slip lose exceptions are gone: those cells are now no_place.
const WEST_NO_PLACE_CELLS := [
	Vector2i(7, 4), Vector2i(7, 5), Vector2i(7, 6), Vector2i(8, 4),
]
const NO_PLACE_REASON_WEST := "此掩体侧射界被挡，禁止落位"

var _failed := 0
var _passed := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	_run()
	print("W2_AIM_TOLERANCE_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _run() -> void:
	var level := SimLevelLoader.load_path("res://data/levels/yard.json")
	_assert_west_cells_explicitly_forbidden(level)
	_assert_plan_tolerance("A", "res://data/fixtures/plan_a.json", level)
	_assert_plan_tolerance("B", "res://data/fixtures/plan_b.json", level)
	_assert_counterex_still_holds()


func _no_place_reason(level: Dictionary, x: int, y: int) -> String:
	for c in level.get("cells", []):
		if int(c["x"]) == x and int(c["y"]) == y:
			if not bool(c.get("no_place", false)):
				return ""
			return str(c.get("no_place_reason_zh", ""))
	return ""


func _assert_west_cells_explicitly_forbidden(level: Dictionary) -> void:
	for cell in WEST_NO_PLACE_CELLS:
		var reason := _no_place_reason(level, cell.x, cell.y)
		_assert(reason == NO_PLACE_REASON_WEST,
			"west no-place cell (%d,%d) reason=%s" % [cell.x, cell.y, reason])


func _high_slots(level: Dictionary) -> Dictionary:
	var m: Dictionary = {}
	for hs in level.get("high_slots", []):
		var cells: Array = []
		for c in hs.get("cells", []):
			cells.append(Vector2i(int(c["x"]), int(c["y"])))
		m[str(hs.get("id", ""))] = cells
	return m


func _slot_of(xy: Vector2i, slots: Dictionary) -> String:
	for id in slots.keys():
		for c in slots[id]:
			if c == xy:
				return str(id)
	return ""


## Intent landmark for an operator in a published plan (neutral names only).
func _intent_center(which: String, oi: int, ox: int, oy: int, pub_f: float, is_home: bool) -> float:
	if is_home:
		return pub_f
	## A: MG / Kar → 巷口; MP → 南门. B: Kar → 路口; MP/grenade keep published aim.
	if which == "A":
		if oi == 0:
			return AimSnap.round_to_step(SimGeom.bearing_deg(float(ox), float(oy), 18.0, 8.0))
		if oi == 1:
			return SimGeom.bearing_deg(float(ox), float(oy), 18.0, 8.0)
		return SimGeom.bearing_deg(float(ox), float(oy), 11.0, 14.0)
	if oi == 0:
		return SimGeom.bearing_deg(float(ox), float(oy), 11.0, 7.0)
	return pub_f


func _cells_to_test(which: String, oi: int, op: Dictionary, level: Dictionary, slots: Dictionary) -> Array:
	var ox0: int = int(op["x"])
	var oy0: int = int(op["y"])
	var tier := str(op.get("tier", "ground"))
	var home := Vector2i(ox0, oy0)
	var out: Array = []
	var seen: Dictionary = {}
	var add := func(c: Vector2i) -> void:
		var k := "%d,%d" % [c.x, c.y]
		if seen.has(k):
			return
		seen[k] = true
		out.append(c)
	add.call(home)
	if tier == "high":
		var sid := _slot_of(home, slots)
		if sid != "":
			for c in slots[sid]:
				if absi(c.x - ox0) <= 1 and absi(c.y - oy0) <= 1:
					add.call(c)
		return out
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			add.call(Vector2i(ox0 + int(dx), oy0 + int(dy)))
	return out


func _assert_plan_tolerance(which: String, path: String, level: Dictionary) -> void:
	var base: Dictionary = SimRunner.load_json(path)
	var slots := _high_slots(level)
	for oi in range(base["operators"].size()):
		var op: Dictionary = base["operators"][oi]
		var ox0: int = int(op["x"])
		var oy0: int = int(op["y"])
		var pub_f: float = float(op["facing_deg"])
		var cells: Array = _cells_to_test(which, oi, op, level, slots)
		for cell in cells:
			var ox: int = cell.x
			var oy: int = cell.y
			var is_home := ox == ox0 and oy == oy0
			var center_f: float = _intent_center(which, oi, ox, oy, pub_f, is_home)
			for df in [-5.0, 0.0, 5.0]:
				var p: Dictionary = base.duplicate(true)
				p["operators"][oi]["x"] = ox
				p["operators"][oi]["y"] = oy
				p["operators"][oi]["facing_deg"] = center_f + float(df)
				var s: Dictionary = SimRunner.run_plan_dict(p)
				var tag := "%s op%d@(%d,%d) aim%+.0f (c=%.1f)" % [which, oi, ox, oy, df, center_f]
				var no_place := _no_place_reason(level, ox, oy)
				if not no_place.is_empty():
					_assert(str(s.get("outcome", "")) != "",
						"%s no_place reason=%s (measured outcome=%s esc=%s)" % [
							tag, no_place, s.get("outcome"), s.get("escapes")])
				else:
					_assert(str(s.get("outcome", "")) == "win",
						"%s wins got=%s esc=%s" % [tag, s.get("outcome"), s.get("escapes")])


func _row_from_run(summary: Dictionary) -> Dictionary:
	var ReviewBuilder := preload("res://sim/review_builder.gd")
	var events: Array = summary.get("events", []) as Array
	var m: Dictionary = ReviewBuilder._compute_metrics(summary, events)
	m["outcome"] = summary.get("outcome")
	m["escape_n"] = (summary.get("escapes", []) as Array).size()
	m["injury_n"] = (summary.get("wounded", []) as Array).size() + (summary.get("dead_ops", []) as Array).size()
	return m


func _holds_d3(case_m: Dictionary, base_m: Dictionary) -> bool:
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
	return esc >= 1 or clear_ok or inj_ok


func _assert_counterex_still_holds() -> void:
	## Spot-check P0-1 facing gates: ±30/60 on key shooter still D.3-true.
	var base_a: Dictionary = _row_from_run(SimRunner.run_plan("res://data/fixtures/plan_a.json"))
	var base_b: Dictionary = _row_from_run(SimRunner.run_plan("res://data/fixtures/plan_b.json"))
	_assert(str(base_a.get("outcome")) == "win", "BASE-A still wins")
	_assert(str(base_b.get("outcome")) == "win", "BASE-B still wins")
	for delta in [30.0, 60.0]:
		var pa: Dictionary = SimRunner.load_json("res://data/fixtures/plan_a.json")
		pa["operators"][0]["facing_deg"] = float(pa["operators"][0]["facing_deg"]) + delta
		var sa := _row_from_run(SimRunner.run_plan_dict(pa))
		_assert(_holds_d3(sa, base_a), "F-A%.0f still D.3 esc=%s out=%s clear=%s inj=%s" % [
			delta, sa.get("escape_n"), sa.get("outcome"), sa.get("clear_s"), sa.get("injury_n")])
		var pb: Dictionary = SimRunner.load_json("res://data/fixtures/plan_b.json")
		pb["operators"][0]["facing_deg"] = float(pb["operators"][0]["facing_deg"]) + delta
		var sb := _row_from_run(SimRunner.run_plan_dict(pb))
		_assert(_holds_d3(sb, base_b), "F-B%.0f still D.3 esc=%s out=%s clear=%s inj=%s" % [
			delta, sb.get("escape_n"), sb.get("outcome"), sb.get("clear_s"), sb.get("injury_n")])
