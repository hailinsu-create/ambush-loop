extends SceneTree

## W5b diagnostic (T5c): measure whether the barn north-ladder wait is safe.
## Read-only: no sim rule changes, no geometry changes, no golden changes.
## Visibility uses NightSim.observers_seeing_cell() -> _observer_sees(), the same
## geometry the exposure step uses. Observer clocks (for horizons past t0) run a
## trigger-free sim with no operators so patrols keep looping and the night does
## not end early; this only provides a moving observer picture.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")
const NightSim := preload("res://sim/night_sim.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")
const SimRunner := preload("res://sim/runner.gd")
const C := preload("res://sim/constants.gd")

const NORTH_CELL_WIDE := Vector2i(4, 12)
const HORIZON := 900

var _failed := 0
var _passed := 0
var _level: Dictionary
var _weapons: Dictionary
var _north_cell := Vector2i.ZERO
var _east_cell := Vector2i.ZERO
var _north_ticks := 0
var _east_ticks := 0


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run_all")


func _run_all() -> void:
	_level = SimLevelLoader.load_path("res://data/levels/yard.json")
	_weapons = SimWeapons.load_csv()
	_assert(not _level.is_empty() and not _weapons.is_empty(), "ladder safety fixtures load")
	_load_barn_l2_access()
	var north_key := _cell_key(_north_cell)
	var wide_key := _cell_key(NORTH_CELL_WIDE)
	var east_key := _cell_key(_east_cell)

	## Situation 1/2/3: actual plan A with op_mg42 on the north ladder.
	var quiet: Dictionary = _run_plan_a(_north_cell, _north_ticks, C.ALERT_QUIET)
	_print_plan_case("1_quiet_north", quiet)
	var susp: Dictionary = _run_plan_a(_north_cell, _north_ticks, C.ALERT_SUSPICIOUS)
	_print_plan_case("2_suspicious_north", susp)
	var area: Dictionary = _run_plan_a(_north_cell, _north_ticks, C.ALERT_AREA)
	_print_plan_case("3_area_north", area)

	## East door control for situation 1 (actual plan A variant using the door).
	var east_quiet: Dictionary = _run_plan_a(_east_cell, _east_ticks, C.ALERT_QUIET)
	_print_plan_case("1_quiet_east", east_quiet)

	## Situation 4: hypothetical dweller standing on the departure cells.
	## (a) inside the actual plan A nights above (observers/alert evolve as usual),
	## (b) long horizon on a trigger-free observer clock.
	_print_dwell("4a_quiet_north", quiet, C.ALERT_QUIET)
	_print_dwell("4a_suspicious_north", susp, C.ALERT_SUSPICIOUS)
	_print_dwell("4a_quiet_east", east_quiet, C.ALERT_QUIET)
	var clock_quiet: Dictionary = _run_observer_clock(C.ALERT_QUIET, HORIZON)
	_print_clock("4b_quiet_clock900", clock_quiet)
	var clock_susp: Dictionary = _run_observer_clock(C.ALERT_SUSPICIOUS, HORIZON)
	_print_clock("4b_suspicious_clock900", clock_susp)

	## Strict assertions: only measured facts (see docs/CLIMB_P1_RESULTS_20261020.md).
	_assert(int(quiet["t0"]) == 520, "quiet north t0=520 got=%s" % quiet["t0"])
	_assert(_climb_window(quiet["sim"]) == Vector2i(0, 59),
		"quiet north climb 0..59 got=%s" % str(_climb_window(quiet["sim"])))
	_assert(_count_seen(quiet["seen"], 0, 59) == 0,
		"quiet north unseen while climbing got=%d" % _count_seen(quiet["seen"], 0, 59))
	_assert(_count_seen(quiet["seen"], 60, 520) == 0,
		"quiet north unseen after climb to t0 got=%d" % _count_seen(quiet["seen"], 60, 520))
	_assert(int(_first_seen(quiet["seen"], 0, 520)["tick"]) == -1,
		"quiet north never seen to t0")

	_assert(int(susp["t0"]) == 520, "suspicious north t0=520 got=%s" % susp["t0"])
	_assert(_climb_window(susp["sim"]) == Vector2i(0, 59),
		"suspicious north climb 0..59 got=%s" % str(_climb_window(susp["sim"])))
	_assert(_count_seen(susp["seen"], 0, 59) == 0,
		"suspicious north unseen while climbing got=%d" % _count_seen(susp["seen"], 0, 59))
	_assert(_count_seen(susp["seen"], 60, 520) == 0,
		"suspicious north unseen after climb to t0 got=%d" % _count_seen(susp["seen"], 60, 520))
	_assert(int(_first_seen(susp["seen"], 0, 520)["tick"]) == -1,
		"suspicious north never seen to t0")

	_assert(int(area["t0"]) == 29, "area north t0=29 got=%s" % area["t0"])
	_assert(_climb_window(area["sim"]).y == -1,
		"area north detonates before climb_end got=%s" % str(_climb_window(area["sim"])))
	_assert(_count_seen(area["seen"], 0, 29) == 0,
		"area north unseen to t0 got=%d" % _count_seen(area["seen"], 0, 29))
	_assert(int(_first_seen(area["seen"], 0, 29)["tick"]) == -1,
		"area north never seen to t0")

	_assert(int(east_quiet["t0"]) == 298, "quiet east t0=298 got=%s" % east_quiet["t0"])
	_assert(_climb_window(east_quiet["sim"]) == Vector2i(0, 39),
		"quiet east climb 0..39 got=%s" % str(_climb_window(east_quiet["sim"])))
	_assert(_count_seen(east_quiet["seen"], 0, 39) == 32,
		"quiet east seen 32 climb ticks got=%d" % _count_seen(east_quiet["seen"], 0, 39))
	_assert(_count_seen(east_quiet["seen"], 40, 298) == 0,
		"quiet east unseen after climb to t0 got=%d" % _count_seen(east_quiet["seen"], 40, 298))
	var east_first: Dictionary = _first_seen(east_quiet["seen"], 0, 298)
	_assert(int(east_first["tick"]) == 0, "quiet east first seen tick 0 got=%s" % east_first["tick"])
	_assert(east_first["ids"] == ["patrol:west_patrol"],
		"quiet east first seen by west patrol got=%s" % str(east_first["ids"]))

	_assert(_first_txt(quiet["cells"][north_key], 520) == "none", "quiet dwell 5,12 unseen to t0")
	_assert(_first_txt(quiet["cells"][wide_key], 520) == "none", "quiet dwell 4,12 unseen to t0")
	_assert(_first_txt(quiet["cells"][east_key], 520) == "0[patrol:west_patrol]",
		"quiet dwell 6,9 seen at 0 got=%s" % _first_txt(quiet["cells"][east_key], 520))
	_assert(_first_txt(susp["cells"][north_key], 520) == "none", "suspicious dwell 5,12 unseen to t0")
	_assert(_first_txt(susp["cells"][wide_key], 520) == "none", "suspicious dwell 4,12 unseen to t0")
	_assert(_first_txt(susp["cells"][east_key], 520) == "0[patrol:west_patrol]",
		"suspicious dwell 6,9 seen at 0 got=%s" % _first_txt(susp["cells"][east_key], 520))

	_assert(int(clock_quiet["first"][north_key]) == 599,
		"clock quiet dwell 5,12 first seen 599 got=%s" % clock_quiet["first"][north_key])
	_assert(int(clock_quiet["first"][wide_key]) == 599,
		"clock quiet dwell 4,12 first seen 599 got=%s" % clock_quiet["first"][wide_key])
	_assert(clock_quiet["first_ids"][north_key] == ["patrol:west_patrol"],
		"clock quiet dwell 5,12 seen by west patrol got=%s" % str(clock_quiet["first_ids"][north_key]))
	_assert(int(clock_quiet["first"][east_key]) == 0,
		"clock quiet dwell 6,9 first seen 0 got=%s" % clock_quiet["first"][east_key])
	_assert(int(clock_susp["first"][north_key]) == 599,
		"clock suspicious dwell 5,12 first seen 599 got=%s" % clock_susp["first"][north_key])
	_assert(int(clock_susp["first"][wide_key]) == 599,
		"clock suspicious dwell 4,12 first seen 599 got=%s" % clock_susp["first"][wide_key])
	_assert(clock_susp["first_ids"][north_key] == ["patrol:west_patrol"],
		"clock suspicious dwell 5,12 seen by west patrol got=%s" % str(clock_susp["first_ids"][north_key]))
	_assert(int(clock_susp["first"][east_key]) == 0,
		"clock suspicious dwell 6,9 first seen 0 got=%s" % clock_susp["first"][east_key])

	print("W5B_LADDER_SAFETY_TEST_SUMMARY passed=", _passed, " failed=", _failed)
	quit(0 if _failed == 0 else 1)


func _load_barn_l2_access() -> void:
	var access: Dictionary = {}
	for slot in _level.get("high_slots", []):
		if str(slot.get("id", "")) == "barn_l2":
			for entry in slot.get("access", []):
				access[str(entry.get("id", ""))] = entry
			break
	var north: Dictionary = access.get("barn_north_ladder", {})
	var east: Dictionary = access.get("barn_east_door", {})
	_north_cell = Vector2i(int(north.get("x", -1)), int(north.get("y", -1)))
	_east_cell = Vector2i(int(east.get("x", -1)), int(east.get("y", -1)))
	_north_ticks = int(round(float(north.get("climb_s", 0.0)) * float(C.TICK_HZ)))
	_east_ticks = int(round(float(east.get("climb_s", 0.0)) * float(C.TICK_HZ)))
	_assert(_north_cell == Vector2i(5, 12),
		"yard barn_north_ladder cell (5,12) got=%s" % str(_north_cell))
	_assert(_north_ticks == 60,
		"yard barn_north_ladder climb ticks 60 got=%d" % _north_ticks)
	_assert(_east_cell == Vector2i(6, 9),
		"yard barn_east_door cell (6,9) got=%s" % str(_east_cell))
	_assert(_east_ticks == 40,
		"yard barn_east_door climb ticks 40 got=%d" % _east_ticks)


func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


func _assert(cond: bool, msg: String) -> void:
	if cond:
		_passed += 1
		print("PASS ", msg)
	else:
		_failed += 1
		printerr("FAIL ", msg)


func _plan_a(access: Vector2i, climb_ticks: int, start_alert: String) -> Dictionary:
	## Fixture plan A plus the same climb fields the controller writes for an
	## entrance (target stays barn_l2 (5,9), run position starts at `access`).
	var plan := SimRunner.load_json("res://data/fixtures/plan_a.json")
	for op in plan.get("operators", []):
		if str(op.get("id", "")) != "op_mg42":
			continue
		op["climbing"] = true
		op["climb_from"] = {"x": access.x, "y": access.y}
		op["climb_ticks_left"] = climb_ticks
	if start_alert != C.ALERT_QUIET:
		plan["start_alert"] = start_alert
	return plan


func _run_plan_a(access: Vector2i, climb_ticks: int, start_alert: String) -> Dictionary:
	var sim := NightSim.new()
	sim.setup(_level, _plan_a(access, climb_ticks, start_alert), _weapons)
	sim.begin_wait()
	var seen: Dictionary = {} ## processed tick -> [observer ids]
	var cells: Dictionary = {
		_cell_key(_north_cell): [],
		_cell_key(NORTH_CELL_WIDE): [],
		_cell_key(_east_cell): [],
		"5,9": [],
	}
	while sim.detonate_tick < 0 and not sim.is_finished() and sim.tick <= HORIZON:
		var processed := int(sim.tick)
		sim.advance_one_tick()
		var op: Dictionary = sim._find_op("op_mg42")
		var expose_tier := C.TIER_GROUND if bool(op.get("climbing", false)) else str(op.get("tier", "ground"))
		var seers: Array = sim.observers_seeing_cell(float(op["x"]), float(op["y"]), expose_tier)
		seen[processed] = _ids(seers)
		for key in cells.keys():
			var k := str(key)
			var parts: PackedStringArray = k.split(",")
			var cell_arr: Array = cells[k]
			cell_arr.append(_ids(sim.observers_seeing_cell(
				float(parts[0]), float(parts[1]), C.TIER_GROUND
			)))
	return {
		"sim": sim,
		"seen": seen,
		"cells": cells,
		"t0": int(sim.detonate_tick),
		"alert": start_alert,
		"access": access,
	}


func _run_observer_clock(start_alert: String, horizon: int) -> Dictionary:
	## No operators, manual trigger: patrols loop, night never detonates/finishes.
	var plan := {
		"id": "dwell_clock",
		"trigger": {"type": "manual"},
		"operators": [],
		"mines": [],
		"grenades": [],
	}
	if start_alert != C.ALERT_QUIET:
		plan["start_alert"] = start_alert
	var sim := NightSim.new()
	sim.setup(_level, plan, _weapons)
	sim.begin_wait()
	var keys := [_cell_key(_north_cell), _cell_key(NORTH_CELL_WIDE), _cell_key(_east_cell)]
	var first: Dictionary = {}
	var first_ids: Dictionary = {}
	for key in keys:
		first[key] = -1
		first_ids[key] = []
	while not sim.is_finished() and sim.tick <= horizon:
		var processed := int(sim.tick)
		sim.advance_one_tick()
		for key in keys:
			var k := str(key)
			if int(first[k]) >= 0:
				continue
			var parts: PackedStringArray = k.split(",")
			var seers: Array = sim.observers_seeing_cell(
				float(parts[0]), float(parts[1]), C.TIER_GROUND
			)
			if not seers.is_empty():
				first[k] = processed
				first_ids[k] = _ids(seers)
	return {"first": first, "first_ids": first_ids, "alert": start_alert, "horizon": horizon}


func _climb_window(sim: NightSim) -> Vector2i:
	var start := -1
	var end := -1
	for ev in sim.log.events:
		if str(ev.get("actor", "")) != "op_mg42":
			continue
		var et := str(ev.get("type", ""))
		if et == "climb_start":
			start = int(ev.get("tick", -1))
		elif et == "climb_end":
			end = int(ev.get("tick", -1))
	return Vector2i(start, end)


func _count_seen(seen: Dictionary, from_tick: int, to_tick: int) -> int:
	var n := 0
	for t in range(from_tick, to_tick + 1):
		if seen.has(t) and not (seen[t] as Array).is_empty():
			n += 1
	return n


func _first_seen(seen: Dictionary, from_tick: int, to_tick: int) -> Dictionary:
	for t in range(from_tick, to_tick + 1):
		if seen.has(t) and not (seen[t] as Array).is_empty():
			return {"tick": t, "ids": seen[t]}
	return {"tick": -1, "ids": []}


func _ids(seers: Array) -> Array:
	var out: Array = []
	for s in seers:
		var sid := "%s:%s" % [str(s.get("kind", "")), str(s.get("id", ""))]
		if not out.has(sid):
			out.append(sid)
	out.sort()
	return out


func _print_plan_case(name: String, r: Dictionary) -> void:
	var sim: NightSim = r["sim"]
	var win := _climb_window(sim)
	var t0 := int(r["t0"])
	var climb_start := win.x
	var climb_end := win.y
	var counted_end := t0
	if climb_end >= 0:
		counted_end = mini(climb_end, t0)
	var climb_seen := _count_seen(r["seen"], climb_start, counted_end) if climb_start >= 0 else 0
	var post_seen := _count_seen(r["seen"], counted_end + 1, t0) if counted_end < t0 else 0
	var first := _first_seen(r["seen"], 0, t0)
	var first_txt := "none" if int(first["tick"]) < 0 else "%d[%s]" % [first["tick"], ";".join(first["ids"])]
	var end_txt := "unfinished" if climb_end < 0 else str(climb_end)
	print("W5B_PLAN case=%s access=%s alert=%s t0=%d climb_start=%d climb_end=%s climb_seen=%d post_seen=%d first_seen=%s" % [
		name, str(r["access"]), str(r["alert"]), t0, climb_start, end_txt,
		climb_seen, post_seen, first_txt,
	])
	print("W5B_DWELL_IN_PLAN case=%s t0=%d cell_5_12_first=%s cell_4_12_first=%s cell_6_9_first=%s" % [
		name, t0,
		_first_txt(r["cells"][_cell_key(_north_cell)], t0),
		_first_txt(r["cells"][_cell_key(NORTH_CELL_WIDE)], t0),
		_first_txt(r["cells"][_cell_key(_east_cell)], t0),
	])


func _first_txt(per_tick: Array, to_tick: int) -> String:
	var end := mini(to_tick, per_tick.size() - 1)
	for t in range(0, end + 1):
		if not (per_tick[t] as Array).is_empty():
			return "%d[%s]" % [t, ";".join(per_tick[t])]
	return "none"


func _print_dwell(name: String, r: Dictionary, alert: String) -> void:
	_print_dwell_line(name, _cell_key(_north_cell), r["cells"][_cell_key(_north_cell)], int(r["t0"]), alert)
	_print_dwell_line(name, _cell_key(NORTH_CELL_WIDE), r["cells"][_cell_key(NORTH_CELL_WIDE)], int(r["t0"]), alert)
	_print_dwell_line(name, _cell_key(_east_cell), r["cells"][_cell_key(_east_cell)], int(r["t0"]), alert)


func _print_dwell_line(name: String, cell: String, per_tick: Array, t0: int, alert: String) -> void:
	print("W5B_DWELL case=%s cell=%s alert=%s to_t0_first=%s" % [
		name, cell, alert, _first_txt(per_tick, t0),
	])


func _print_clock(name: String, r: Dictionary) -> void:
	print("W5B_CLOCK case=%s alert=%s horizon=%d cell_5_12_first=%s cell_4_12_first=%s cell_6_9_first=%s" % [
		name, str(r["alert"]), int(r["horizon"]),
		_clock_txt(r, _cell_key(_north_cell)),
		_clock_txt(r, _cell_key(NORTH_CELL_WIDE)),
		_clock_txt(r, _cell_key(_east_cell)),
	])


func _clock_txt(r: Dictionary, key: String) -> String:
	var t := int(r["first"][key])
	if t < 0:
		return "none"
	return "%d[%s]" % [t, ";".join(r["first_ids"][key])]
