extends RefCounted
class_name NightSim

## Pure headless one-night simulation. No Node/scene dependency.
## Tick order (TERMS §4.1): input → move → mine → vision/expose → alert → trigger → fire.

const C := preload("res://sim/constants.gd")
const SimConstants := preload("res://sim/constants.gd")
const SimGeom := preload("res://sim/geom.gd")
const SimGrid := preload("res://sim/grid.gd")
const SimEventLog := preload("res://sim/event_log.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimWeapons := preload("res://sim/weapons.gd")

var level: Dictionary = {}
var grid: SimGrid
var weapons: Dictionary = {}
var log: SimEventLog

var phase: String = C.PHASE_SETUP
var alert: String = C.ALERT_QUIET
var tick: int = 0
var plan_id: String = ""
var plan_locked: bool = false

var operators: Array = [] ## Dictionary each
var enemies: Array = []
var mines: Array = [] ## {id,x,y,alive}
var grenade_plans: Array = [] ## {actor,aim_x,aim_y,delay_ticks,thrown,blasted}
var sentries: Array = []
var patrols: Array = []

var trigger: Dictionary = {} ## {type,bind,...}
var detonate_tick: int = -1
var trigger_used: String = ""
var standard_ambush: bool = false
var standard_ambush_eligible: bool = true ## false once area/global reached before detonate
var alert_reached_area_before_detonate: bool = false

var expose_streak: int = 0
var suspicious_count: int = 0
var suspicious_recover_ticks: int = 0
var area_expose_streak: int = 0

var escaped_ids: Array = []
var killed_ids: Array = []
var manual_detonate_tick: int = -1 ## set ≥0 to force manual at that tick
var force_expose: bool = false ## test hook: treat squad as exposed every tick
var skip_fire: bool = false
var max_ticks: int = 2000
var speed_mul: float = 1.0 ## playback only; does not affect ticks/hash

var _routes: Dictionary = {}
var _ambush_target_set: Dictionary = {}
var _march_speed: float = 0.5
var _night: bool = true
var _exit_cells: Dictionary = {} ## "x,y" → exit id
var _done: bool = false
var _outcome: String = ""


func setup(level_data: Dictionary, plan: Dictionary, weapons_table: Dictionary) -> void:
	level = level_data
	weapons = weapons_table
	grid = SimLevelLoader.build_grid(level)
	log = SimEventLog.new()
	plan_id = str(plan.get("id", ""))
	log.reset(str(level.get("id", "")), int(level.get("version", 1)), plan_id)

	_night = bool(level.get("night", true))
	_march_speed = float(level.get("enemies", {}).get("march_speed_cells_per_s", 0.5))
	_ambush_target_set.clear()
	for tid in level.get("ambush_targets", []):
		_ambush_target_set[str(tid)] = true

	_routes.clear()
	for r in level.get("enemies", {}).get("routes", []):
		_routes[str(r["id"])] = r.get("waypoints", [])

	_exit_cells.clear()
	for ex in level.get("exits", []):
		if not bool(ex.get("fail_on_enemy_escape", false)):
			continue
		for cell in ex.get("cells", []):
			_exit_cells["%d,%d" % [int(cell["x"]), int(cell["y"])]] = str(ex["id"])

	operators.clear()
	for op in plan.get("operators", []):
		operators.append(_make_op(op))

	mines.clear()
	for m in plan.get("mines", []):
		mines.append({
			"id": str(m.get("id", "mine")),
			"x": float(m["x"]),
			"y": float(m["y"]),
			"alive": true,
		})

	grenade_plans.clear()
	for g in plan.get("grenades", []):
		grenade_plans.append({
			"actor": str(g.get("actor", "op_grenade")),
			"aim_x": float(g["aim_x"]),
			"aim_y": float(g["aim_y"]),
			"delay_ticks": int(g.get("delay_ticks", 12)),
			"thrown": false,
			"blasted": false,
		})

	trigger = plan.get("trigger", level.get("default_trigger", {})).duplicate(true)
	if trigger.is_empty() or str(trigger.get("type", "")) == "":
		push_error("NightSim: trigger required (T-06)")
	manual_detonate_tick = int(plan.get("manual_detonate_tick", -1))

	enemies.clear()
	for sp in level.get("enemies", {}).get("spawns", []):
		enemies.append(_make_enemy(sp))

	sentries.clear()
	for s in level.get("sentries", []):
		sentries.append(s.duplicate(true))

	patrols.clear()
	for p in level.get("patrols", []):
		var pd: Dictionary = p.duplicate(true)
		pd["_progress_s"] = 0.0
		pd["_seg"] = 0
		pd["x"] = float(pd["waypoints"][0]["x"])
		pd["y"] = float(pd["waypoints"][0]["y"])
		if not pd.has("cone"):
			pd["cone"] = {"facing_deg": 0.0, "angle_deg": 50.0, "range_cells": 6.0}
		patrols.append(pd)

	phase = C.PHASE_SETUP
	alert = C.ALERT_QUIET
	tick = 0
	plan_locked = false
	detonate_tick = -1
	trigger_used = ""
	standard_ambush = false
	standard_ambush_eligible = true
	alert_reached_area_before_detonate = false
	expose_streak = 0
	suspicious_count = 0
	suspicious_recover_ticks = 0
	area_expose_streak = 0
	escaped_ids.clear()
	killed_ids.clear()
	_done = false
	_outcome = ""


func run() -> Dictionary:
	begin_wait()
	while not _done and tick <= max_ticks:
		advance_one_tick()
	if not _done:
		_finish("lose", "timeout")
	return outcome_summary()


## Interactive / greybox API (thin wrappers; tick rules unchanged).

func begin_wait() -> void:
	## SETUP is instantaneous; emit mine_place then enter WAIT at tick 0.
	log.emit(0, "sim_start", {
		"actor": "system",
		"payload": {
			"plan_id": plan_id,
			"night": _night,
			"ambush_targets": level.get("ambush_targets", []),
		},
	})
	for m in mines:
		log.emit(0, "mine_place", {
			"actor": str(m["id"]),
			"weapon_id": "mine",
			"pos": {"x": m["x"], "y": m["y"], "height": "ground"},
		})
	_set_phase(0, C.PHASE_WAIT)


func advance_one_tick() -> bool:
	## Process current tick then increment. Returns true when night finished.
	if _done:
		return true
	_tick_once()
	if _done:
		return true
	tick += 1
	if tick > max_ticks:
		_finish("lose", "timeout")
		return true
	return false


func is_finished() -> bool:
	return _done


func outcome_summary() -> Dictionary:
	var h := log.hash_sha256()
	var summary := {
		"outcome": _outcome,
		"standard_ambush": standard_ambush,
		"detonate_tick": detonate_tick,
		"trigger": trigger_used,
		"alert": alert,
		"kills": killed_ids.duplicate(),
		"escapes": escaped_ids.duplicate(),
		"log_hash": h,
		"reason": _end_reason(),
	}
	log.set_summary(summary)
	return summary


func request_manual_detonate() -> void:
	## Arms manual trigger for the next processed tick (ADR-TRIGGER T-05).
	if phase != C.PHASE_WAIT or detonate_tick >= 0:
		return
	manual_detonate_tick = tick


func request_operator_facing(op_id: String, new_facing_deg: float) -> void:
	## WAIT turn cost: 1.0 s per 45° (ADR-TRIGGER §3.2 / TERMS §9.3). SETUP should set facing before begin_wait.
	if phase != C.PHASE_WAIT or plan_locked:
		return
	var op := _find_op(op_id)
	if op.is_empty() or not op["alive"]:
		return
	var delta := SimGeom.abs_angle_delta_deg(float(op["facing_deg"]), new_facing_deg)
	var steps := int(ceil(delta / 45.0 - 1e-9))
	if steps <= 0:
		op["facing_deg"] = new_facing_deg
		return
	op["facing_deg"] = new_facing_deg
	op["turn_ticks_left"] = maxi(int(op.get("turn_ticks_left", 0)), steps * C.TICK_HZ)


func observers_seeing_cell(tx: float, ty: float, target_tier: String) -> Array:
	## Preview: which sentries/patrols see this cell (A-05; uses same geometry as expose).
	var out: Array = []
	for s in sentries:
		if _observer_sees(s, float(s["x"]), float(s["y"]), str(s.get("tier", "ground")), tx, ty, target_tier):
			out.append({"kind": "sentry", "id": str(s.get("id", "sentry")), "x": s["x"], "y": s["y"]})
	for p in patrols:
		if _observer_sees(p, float(p["x"]), float(p["y"]), SimConstants.TIER_GROUND, tx, ty, target_tier):
			out.append({"kind": "patrol", "id": str(p.get("id", "patrol")), "x": p["x"], "y": p["y"]})
	return out


func sector_clear_and_blocked(
	ox: float, oy: float, facing: float, half: float, rng: float, tier: String
) -> Dictionary:
	## Clear LOS cells + grey occlusion gaps inside cone (ADR-HEIGHT §3.2).
	var clear_cells: Array = []
	var blocked_cells: Array = []
	var r_ceil := int(ceil(rng)) + 1
	var oxi := int(floor(ox))
	var oyi := int(floor(oy))
	for y in range(oyi - r_ceil, oyi + r_ceil + 1):
		for x in range(oxi - r_ceil, oxi + r_ceil + 1):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				continue
			if not SimGeom.in_cone(ox, oy, facing, half, rng, float(x), float(y)):
				continue
			var tt := grid.tier_at(float(x), float(y))
			if grid.los_clear(ox, oy, tier, float(x), float(y), tt):
				clear_cells.append(Vector2i(x, y))
			else:
				blocked_cells.append(Vector2i(x, y))
	return {"clear": clear_cells, "blocked": blocked_cells}


func _end_reason() -> String:
	## Best-effort reason from last sim_end event for result UI.
	for i in range(log.events.size() - 1, -1, -1):
		var e: Dictionary = log.events[i]
		if str(e.get("type", "")) == "sim_end":
			return str(e.get("payload", {}).get("reason", ""))
	return ""


func _tick_once() -> void:
	## 1 input
	if phase == C.PHASE_WAIT and manual_detonate_tick >= 0 and tick == manual_detonate_tick:
		_enter_detonate("manual", "system")
	_step_turn_cooldowns()

	## 2 move
	_step_move()

	## 3 mine
	_step_mines()

	## 4 vision / exposure
	var exposed := _step_vision_expose()

	## 5 alert update
	_step_alert(exposed)

	## 6 trigger
	if phase == C.PHASE_WAIT:
		_step_trigger()

	## 7 fire (detonate / resolve)
	if phase == C.PHASE_DETONATE or phase == C.PHASE_RESOLVE:
		_step_fire()
		_step_grenades()
		_check_escapes()
		_check_end()


func _step_turn_cooldowns() -> void:
	for op in operators:
		var left := int(op.get("turn_ticks_left", 0))
		if left > 0:
			op["turn_ticks_left"] = left - 1


func _set_phase(t: int, p: String) -> void:
	phase = p
	log.emit(t, "phase", {"actor": "system", "payload": {"phase": p}})


func _make_op(op: Dictionary) -> Dictionary:
	var x := float(op["x"])
	var y := float(op["y"])
	var climbing := bool(op.get("climbing", false))
	var tier := str(op.get("tier", grid.tier_at(x, y)))
	if climbing:
		tier = SimConstants.TIER_GROUND
	return {
		"id": str(op["id"]),
		"x": x,
		"y": y,
		"facing_deg": float(op.get("facing_deg", 0)),
		"weapon_id": str(op.get("weapon_id", "")),
		"tier": tier,
		"alive": true,
		"can_fire": not climbing,
		"climbing": climbing,
		"climb_ticks_left": int(op.get("climb_ticks_left", 0)),
		"turn_ticks_left": 0,
		"shot_accum": 0.0,
		"locked_facing": float(op.get("facing_deg", 0)),
		"locked_x": x,
		"locked_y": y,
	}


func _make_enemy(sp: Dictionary) -> Dictionary:
	var route_id := str(sp["route_id"])
	var wps: Array = _routes.get(route_id, [])
	var offset := float(sp.get("path_offset_cells", 0.0))
	return {
		"id": str(sp["id"]),
		"route_id": route_id,
		"enter_t_s": float(sp["enter_t_s"]),
		"group": str(sp.get("group", "main")),
		"waypoints": wps,
		"path_offset_cells": offset,
		"entered": false,
		"alive": true,
		"escaped": false,
		"x": 0.0,
		"y": 0.0,
		"prev_x": 0.0,
		"prev_y": 0.0,
		"progress": offset, ## cells along polyline (may be negative until enter advances)
		"hit_accum": 0.0,
	}


func _step_move() -> void:
	var t_s := float(tick) * C.DT_S
	for e in enemies:
		if not e["alive"] or e["escaped"]:
			continue
		if not e["entered"]:
			if t_s + 1e-9 >= float(e["enter_t_s"]):
				e["entered"] = true
				# Absolute clock: progress = speed*(t-enter)+offset (no enter-tick double-step).
				e["progress"] = _march_speed * (t_s - float(e["enter_t_s"])) + float(e["path_offset_cells"])
				_place_enemy_on_path(e)
				e["prev_x"] = e["x"]
				e["prev_y"] = e["y"]
				log.emit(tick, "enemy_enter", {
					"actor": e["id"],
					"pos": {"x": e["x"], "y": e["y"], "height": "ground"},
					"payload": {"route_id": e["route_id"], "group": e["group"]},
				})
			else:
				continue
		else:
			e["prev_x"] = e["x"]
			e["prev_y"] = e["y"]
			e["progress"] = _march_speed * (t_s - float(e["enter_t_s"])) + float(e["path_offset_cells"])
			_place_enemy_on_path(e)

	# Patrols loop edges
	for p in patrols:
		_advance_patrol(p)


func _place_enemy_on_path(e: Dictionary) -> void:
	var wps: Array = e["waypoints"]
	if wps.is_empty():
		return
	var progress: float = maxf(0.0, float(e["progress"]))
	var remaining := progress
	for i in range(wps.size() - 1):
		var a: Dictionary = wps[i]
		var b: Dictionary = wps[i + 1]
		var ax := float(a["x"])
		var ay := float(a["y"])
		var bx := float(b["x"])
		var by := float(b["y"])
		var seg := Vector2(bx - ax, by - ay).length()
		if remaining <= seg + 1e-9:
			var t := 0.0 if seg <= 1e-9 else remaining / seg
			e["x"] = ax + (bx - ax) * t
			e["y"] = ay + (by - ay) * t
			return
		remaining -= seg
	var last: Dictionary = wps[wps.size() - 1]
	e["x"] = float(last["x"])
	e["y"] = float(last["y"])


func _advance_patrol(p: Dictionary) -> void:
	var wps: Array = p["waypoints"]
	if alert == C.ALERT_AREA or alert == C.ALERT_GLOBAL:
		if p.has("alert_route") and p["alert_route"].has("waypoints"):
			wps = p["alert_route"]["waypoints"]
	if wps.size() < 2:
		return
	var edge := float(p.get("edge_s", 6.0))
	if alert == C.ALERT_AREA and p.has("alert_route"):
		edge = float(p["alert_route"].get("edge_s", edge))
	p["_progress_s"] = float(p.get("_progress_s", 0.0)) + C.DT_S
	var cycle := edge * float(wps.size())
	var tmod := fmod(float(p["_progress_s"]), cycle)
	var seg_f: float = tmod / edge
	var seg_i: int = int(floor(seg_f)) % wps.size()
	var frac: float = fposmod(seg_f, 1.0)
	var a: Dictionary = wps[seg_i] as Dictionary
	var b: Dictionary = wps[(seg_i + 1) % wps.size()] as Dictionary
	p["x"] = float(a["x"]) + (float(b["x"]) - float(a["x"])) * frac
	p["y"] = float(a["y"]) + (float(b["y"]) - float(a["y"])) * frac
	# Face along segment
	p["cone"] = p.get("cone", {}).duplicate(true)
	p["cone"]["facing_deg"] = SimGeom.bearing_deg(float(a["x"]), float(a["y"]), float(b["x"]), float(b["y"]))
	if alert == C.ALERT_AREA and p.has("alert_route") and p["alert_route"].has("facing_deg"):
		p["cone"]["facing_deg"] = float(p["alert_route"]["facing_deg"])


func _step_mines() -> void:
	if phase != C.PHASE_WAIT and phase != C.PHASE_DETONATE and phase != C.PHASE_RESOLVE:
		return
	for m in mines:
		if not m["alive"]:
			continue
		for e in enemies:
			if not e["alive"] or not e["entered"] or e["escaped"]:
				continue
			# Paper mine points are cell coordinates on the path (e.g. (11,6) at t=16),
			# not "any point inside the cell" — trigger near the exact grid point.
			var dx := absf(float(e["x"]) - float(m["x"]))
			var dy := absf(float(e["y"]) - float(m["y"]))
			var step := _march_speed * C.DT_S
			if dx <= step * 0.5 + 1e-6 and dy <= step * 0.5 + 1e-6:
				m["alive"] = false
				log.emit(tick, "mine_detonate", {
					"actor": m["id"],
					"target": e["id"],
					"weapon_id": "mine",
					"pos": {"x": m["x"], "y": m["y"], "height": "ground"},
				})
				_kill_enemy(e, m["id"], "mine")
				if phase == C.PHASE_WAIT and str(trigger.get("type", "")) == "mine_detonate":
					var bind := str(trigger.get("bind", m["id"]))
					if bind == str(m["id"]) or bind.is_empty():
						_enter_detonate("mine_detonate", "system", bind)


func _step_vision_expose() -> bool:
	if force_expose:
		return true
	if phase != C.PHASE_WAIT and phase != C.PHASE_SETUP:
		# After detonate, marching enemies can seek; for v0 exposure still counted for global path tests pre-detonate.
		pass
	# Only sentries/patrols have cones before detonate (ADR-ALERT M1).
	for op in operators:
		if not op["alive"]:
			continue
		var ox := float(op["x"])
		var oy := float(op["y"])
		var otier := str(op["tier"])
		# Climbing: exposure uses departure cell (already on op pos); tier counted as ground.
		var expose_tier := SimConstants.TIER_GROUND if bool(op.get("climbing", false)) else otier
		if _seen_by_observers(ox, oy, expose_tier):
			return true
	return false


func _seen_by_observers(tx: float, ty: float, target_tier: String) -> bool:
	for s in sentries:
		if _observer_sees(s, float(s["x"]), float(s["y"]), str(s.get("tier", "ground")), tx, ty, target_tier):
			return true
	for p in patrols:
		if _observer_sees(p, float(p["x"]), float(p["y"]), SimConstants.TIER_GROUND, tx, ty, target_tier):
			return true
	return false


func _observer_sees(
	obs: Dictionary,
	ox: float,
	oy: float,
	otier: String,
	tx: float,
	ty: float,
	ttier: String
) -> bool:
	var cone: Dictionary = obs.get("cone", {})
	var facing := float(cone.get("facing_deg", 0))
	if alert == C.ALERT_AREA and obs.has("alert_route") and obs["alert_route"].has("facing_deg"):
		facing = float(obs["alert_route"]["facing_deg"])
	var half := float(cone.get("angle_deg", 50)) * 0.5
	var rng := float(cone.get("range_cells", 8))
	if _night and ttier == SimConstants.TIER_HIGH:
		rng *= SimConstants.SILHOUETTE_MUL
	if not SimGeom.in_cone(ox, oy, facing, half, rng, tx, ty):
		return false
	return grid.los_clear(ox, oy, otier, tx, ty, ttier)


func _step_alert(exposed: bool) -> void:
	if phase != C.PHASE_WAIT:
		return
	match alert:
		C.ALERT_QUIET:
			if exposed:
				expose_streak += 1
				if expose_streak >= C.EXPOSE_TO_SUSPICIOUS_TICKS:
					_set_alert(C.ALERT_SUSPICIOUS, "expose_30_ticks")
					suspicious_count += 1
					if suspicious_count >= 2:
						_set_alert(C.ALERT_AREA, "second_suspicious")
						alert_reached_area_before_detonate = true
						standard_ambush_eligible = false
					expose_streak = 0
					suspicious_recover_ticks = 0
			else:
				expose_streak = 0
		C.ALERT_SUSPICIOUS:
			if exposed:
				expose_streak += 1
				suspicious_recover_ticks = 0
				# Still suspicious; second suspicious only after recover→quiet→suspicious again
			else:
				expose_streak = 0
				suspicious_recover_ticks += 1
				if suspicious_recover_ticks >= C.SUSPICIOUS_RECOVER_TICKS:
					_set_alert(C.ALERT_QUIET, "recover_80_ticks")
					suspicious_recover_ticks = 0
		C.ALERT_AREA:
			if exposed:
				area_expose_streak += 1
				if area_expose_streak >= C.AREA_TO_GLOBAL_TICKS:
					_set_alert(C.ALERT_GLOBAL, "expose_30_ticks")
					standard_ambush_eligible = false
					alert_reached_area_before_detonate = true
					# Global alert → detonate alarm same tick (after alert, in trigger step)
			else:
				area_expose_streak = 0
		C.ALERT_GLOBAL:
			pass


func _set_alert(to: String, reason: String) -> void:
	if to == alert:
		return
	var from := alert
	alert = to
	log.emit(tick, "alert_change", {
		"actor": "system",
		"payload": {"from": from, "to": to, "reason": reason},
	})


func _step_trigger() -> void:
	if alert == C.ALERT_GLOBAL and detonate_tick < 0:
		_enter_detonate("alarm", "system")
		return
	var ttype := str(trigger.get("type", ""))
	match ttype:
		"see_first_enemy":
			var bind := str(trigger.get("bind", ""))
			var op := _find_op(bind)
			if op.is_empty():
				return
			if _op_sees_any_ambush_target(op):
				_enter_detonate("see_first_enemy", bind, bind)
		"cross_marker":
			var a_v: Variant = trigger.get("a", {})
			var b_v: Variant = trigger.get("b", {})
			if typeof(a_v) != TYPE_DICTIONARY or typeof(b_v) != TYPE_DICTIONARY:
				return
			var a: Dictionary = a_v
			var b: Dictionary = b_v
			if a.is_empty() or b.is_empty():
				return
			# Default: headman E1 center crosses segment
			for e in enemies:
				if str(e["id"]) != "E1":
					continue
				if not e["entered"] or not e["alive"]:
					return
				if _crossed_marker(e, a, b):
					_enter_detonate("cross_marker", "E1", str(trigger.get("bind", "marker")))
					return
		"mine_detonate":
			pass ## handled in _step_mines
		"manual":
			pass ## handled in input
		_:
			pass


func _crossed_marker(e: Dictionary, a: Dictionary, b: Dictionary) -> bool:
	## Segment endpoints snap to cell coords. Headman crosses when the southbound
	## path goes from prev_y > line_y to y <= line_y with x in [xmin, xmax].
	var ax := float(a.get("x", 0))
	var ay := float(a.get("y", 0))
	var bx := float(b.get("x", 0))
	var by := float(b.get("y", 0))
	var x_min := minf(ax, bx)
	var x_max := maxf(ax, bx)
	var y_line := (ay + by) * 0.5
	var x := float(e["x"])
	var y := float(e["y"])
	var prev_y := float(e.get("prev_y", y))
	if x < x_min - 0.51 or x > x_max + 0.51:
		return false
	# Southbound cross of horizontal marker (yard main road).
	if absf(ay - by) <= 1e-6:
		return prev_y > y_line + 1e-9 and y <= y_line + 1e-9
	# Fallback: reached the marker cell band.
	return absf(y - y_line) <= 0.5 * _march_speed * C.DT_S + 1e-6 and x >= x_min - 0.51 and x <= x_max + 0.51


func _op_sees_any_ambush_target(op: Dictionary) -> bool:
	var w: Dictionary = weapons.get(str(op["weapon_id"]), {})
	if w.is_empty():
		return false
	var half := float(w.get("sector_deg", 0)) * 0.5
	var rng := float(w.get("max_range", 0))
	var ox := float(op["x"])
	var oy := float(op["y"])
	var otier := str(op["tier"])
	var facing := float(op["facing_deg"])
	for e in enemies:
		if not e["alive"] or not e["entered"] or e["escaped"]:
			continue
		if not _ambush_target_set.has(str(e["id"])):
			continue
		var ex := float(e["x"])
		var ey := float(e["y"])
		if not SimGeom.in_cone(ox, oy, facing, half, rng, ex, ey):
			continue
		if not grid.los_clear(ox, oy, otier, ex, ey, SimConstants.TIER_GROUND):
			continue
		return true
	return false


func _enter_detonate(trig: String, actor: String, bind: String = "") -> void:
	if detonate_tick >= 0:
		return
	detonate_tick = tick
	trigger_used = trig
	plan_locked = true
	# Lock operators
	for op in operators:
		op["locked_facing"] = op["facing_deg"]
		op["locked_x"] = op["x"]
		op["locked_y"] = op["y"]
		op["facing_deg"] = op["locked_facing"]
		op["x"] = op["locked_x"]
		op["y"] = op["locked_y"]

	# Standard ambush: eligible + all entered ambush_targets in kill zone
	var kz := compute_kill_zone_cells()
	var all_in := true
	var any_entered := false
	for e in enemies:
		if not _ambush_target_set.has(str(e["id"])):
			continue
		if not e["entered"]:
			all_in = false
			continue
		any_entered = true
		var cell := Vector2i(int(floor(float(e["x"]))), int(floor(float(e["y"]))))
		if not kz.has("%d,%d" % [cell.x, cell.y]):
			# Also accept continuous pos within any kill cell center proximity
			if not _pos_in_kill_zone(float(e["x"]), float(e["y"]), kz):
				all_in = false
	standard_ambush = standard_ambush_eligible and any_entered and all_in and escaped_ids.is_empty()

	var payload_trig := {"trigger": trig}
	if not bind.is_empty():
		payload_trig["bind"] = bind
	log.emit(tick, "trigger", {"actor": actor, "payload": payload_trig})
	log.emit(tick, "detonate", {
		"actor": "system",
		"payload": {"standard_ambush_eligible": standard_ambush_eligible, "standard_ambush": standard_ambush},
	})
	_set_phase(tick, C.PHASE_DETONATE)


func compute_kill_zone_cells() -> Dictionary:
	## Map "x,y" → true
	var kz: Dictionary = {}
	for op in operators:
		if not op["alive"]:
			continue
		var wid := str(op["weapon_id"])
		if wid in ["grenade", "mine"]:
			continue
		var w: Dictionary = weapons.get(wid, {})
		if w.is_empty():
			continue
		var half := float(w.get("sector_deg", 0)) * 0.5
		var rng := float(w.get("max_range", 0))
		var cells: Array = grid.cells_in_sector(
			float(op["x"]), float(op["y"]), float(op["facing_deg"]), half, rng, str(op["tier"])
		)
		for c in cells:
			kz["%d,%d" % [c.x, c.y]] = true
	for m in mines:
		kz["%d,%d" % [int(m["x"]), int(m["y"])]] = true
	for g in grenade_plans:
		var ax := int(g["aim_x"])
		var ay := int(g["aim_y"])
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				if Vector2(dx, dy).length() <= 2.0 + 1e-9:
					kz["%d,%d" % [ax + dx, ay + dy]] = true
	return kz


func _pos_in_kill_zone(x: float, y: float, kz: Dictionary) -> bool:
	var ix := int(floor(x))
	var iy := int(floor(y))
	if kz.has("%d,%d" % [ix, iy]):
		return true
	# Fractional positions near cell boundary: check neighbors
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if kz.has("%d,%d" % [ix + dx, iy + dy]):
				if SimGeom.dist_centers(x, y, float(ix + dx), float(iy + dy)) <= 0.71:
					return true
	return false


func _step_fire() -> void:
	if skip_fire:
		return
	for op in operators:
		if not op["alive"] or not op["can_fire"]:
			continue
		if bool(op.get("climbing", false)) or int(op.get("turn_ticks_left", 0)) > 0:
			continue
		var wid := str(op["weapon_id"])
		if wid in ["grenade", "mine"]:
			continue
		var w: Dictionary = weapons.get(wid, {})
		if w.is_empty():
			continue
		var rpm := float(w.get("rpm", 0))
		if rpm <= 0.0:
			continue
		var target := _pick_target(op, w)
		if target.is_empty():
			continue
		var dist := SimGeom.dist_centers(float(op["x"]), float(op["y"]), float(target["x"]), float(target["y"]))
		var need := SimWeapons.shots_needed(w, dist)
		if need >= 99:
			continue
		op["shot_accum"] = float(op["shot_accum"]) + rpm / 60.0 * C.DT_S
		log.emit(tick, "fire", {
			"actor": op["id"],
			"target": target["id"],
			"weapon_id": wid,
			"pos": {"x": op["x"], "y": op["y"], "height": op["tier"]},
			"facing_deg": op["facing_deg"],
			"payload": {"in_kill_zone": true},
		})
		if float(op["shot_accum"]) + 1e-9 >= float(need):
			op["shot_accum"] = 0.0
			log.emit(tick, "hit", {
				"actor": op["id"],
				"target": target["id"],
				"weapon_id": wid,
				"payload": {"shots_needed_band": SimGeom.range_band(dist), "fatal": true},
			})
			_kill_enemy(target, op["id"], wid)


func _pick_target(op: Dictionary, w: Dictionary) -> Dictionary:
	var half := float(w.get("sector_deg", 0)) * 0.5
	var rng := float(w.get("max_range", 0))
	var best: Dictionary = {}
	var best_d := 1e9
	for e in enemies:
		if not e["alive"] or not e["entered"] or e["escaped"]:
			continue
		var ex := float(e["x"])
		var ey := float(e["y"])
		if not SimGeom.in_cone(float(op["x"]), float(op["y"]), float(op["facing_deg"]), half, rng, ex, ey):
			continue
		if not grid.los_clear(float(op["x"]), float(op["y"]), str(op["tier"]), ex, ey, SimConstants.TIER_GROUND):
			continue
		var d := SimGeom.dist_centers(float(op["x"]), float(op["y"]), ex, ey)
		if d < best_d:
			best_d = d
			best = e
	return best


func _step_grenades() -> void:
	if detonate_tick < 0:
		return
	for g in grenade_plans:
		if g["blasted"]:
			continue
		var dt := tick - detonate_tick
		if not g["thrown"] and dt >= 1:
			g["thrown"] = true
			log.emit(tick, "grenade_throw", {
				"actor": g["actor"],
				"weapon_id": "grenade",
				"payload": {"aim_x": g["aim_x"], "aim_y": g["aim_y"]},
			})
		if g["thrown"] and not g["blasted"] and dt >= int(g["delay_ticks"]):
			g["blasted"] = true
			log.emit(tick, "grenade_blast", {
				"actor": g["actor"],
				"weapon_id": "grenade",
				"pos": {"x": g["aim_x"], "y": g["aim_y"], "height": "ground"},
				"payload": {"radius_cells": 2},
			})
			for e in enemies:
				if not e["alive"] or e["escaped"]:
					continue
				if SimGeom.dist_centers(float(e["x"]), float(e["y"]), float(g["aim_x"]), float(g["aim_y"])) <= 2.0 + 1e-9:
					_kill_enemy(e, g["actor"], "grenade")


func _kill_enemy(e: Dictionary, actor: String, weapon_id: String) -> void:
	if not e["alive"]:
		return
	e["alive"] = false
	killed_ids.append(e["id"])
	log.emit(tick, "kill", {"actor": actor, "target": e["id"], "weapon_id": weapon_id})


func _check_escapes() -> void:
	for e in enemies:
		if not e["alive"] or e["escaped"] or not e["entered"]:
			continue
		var key := "%d,%d" % [int(floor(float(e["x"]))), int(floor(float(e["y"])))]
		if _exit_cells.has(key):
			e["escaped"] = true
			escaped_ids.append(e["id"])
			log.emit(tick, "enemy_escape", {
				"actor": e["id"],
				"pos": {"x": e["x"], "y": e["y"], "height": "ground"},
				"payload": {"exit": _exit_cells[key]},
			})
			standard_ambush = false


func _check_end() -> void:
	# All ambush targets dead or escaped?
	var pending := 0
	var alive_ops := 0
	for op in operators:
		if op["alive"]:
			alive_ops += 1
	if alive_ops == 0:
		_finish("lose", "squad_wipe")
		return
	for e in enemies:
		if not _ambush_target_set.has(str(e["id"])):
			continue
		if e["alive"] and not e["escaped"]:
			# Must have entered eventually; unentered still pending if night ongoing
			if e["entered"] or float(tick) * C.DT_S < float(e["enter_t_s"]):
				if not e["entered"]:
					pending += 1
				else:
					pending += 1
	if pending == 0:
		var escaped_targets := 0
		for id in escaped_ids:
			if _ambush_target_set.has(str(id)):
				escaped_targets += 1
		if escaped_targets > 0:
			_finish("lose", "enemy_escape")
		else:
			_finish("win", "clear")
		return
	# Switch to resolve a few ticks after detonate for logging
	if phase == C.PHASE_DETONATE and detonate_tick >= 0 and tick - detonate_tick >= 2:
		_set_phase(tick, C.PHASE_RESOLVE)


func _finish(outcome: String, reason: String) -> void:
	if _done:
		return
	_done = true
	_outcome = outcome
	# Final standard_ambush requires win path with eligibility and no escapes among targets
	if outcome != "win":
		standard_ambush = false
	elif not standard_ambush_eligible:
		standard_ambush = false
	log.emit(tick, "sim_end", {
		"actor": "system",
		"payload": {"outcome": outcome, "escaped": escaped_ids.size(), "reason": reason},
	})


func _find_op(id: String) -> Dictionary:
	for op in operators:
		if str(op["id"]) == id:
			return op
	return {}


static func _cell_of(v: float) -> int:
	return int(floor(v + 1e-6))


## --- Test / CLI helpers ---

func sector_blocked_fraction(ox: float, oy: float, facing: float, half: float, rng: float, tier: String) -> float:
	## Fraction of in-cone cells that fail LOS (grey gap). Used by H-01.
	var total := 0
	var blocked := 0
	var r_ceil := int(ceil(rng)) + 1
	var oxi := int(floor(ox))
	var oyi := int(floor(oy))
	for y in range(oyi - r_ceil, oyi + r_ceil + 1):
		for x in range(oxi - r_ceil, oxi + r_ceil + 1):
			if x < 0 or y < 0 or x >= grid.width or y >= grid.height:
				continue
			if not SimGeom.in_cone(ox, oy, facing, half, rng, float(x), float(y)):
				continue
			total += 1
			var tt := grid.tier_at(float(x), float(y))
			if not grid.los_clear(ox, oy, tier, float(x), float(y), tt):
				blocked += 1
	if total == 0:
		return 0.0
	return float(blocked) / float(total)
