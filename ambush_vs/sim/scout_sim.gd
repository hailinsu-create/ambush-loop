extends RefCounted
class_name ScoutSim

## PLAY-2 / VS-W4a scout-gather phase (separate from ambush NightSim).
## Ambush golden hashes unchanged: NightSim.begin_wait path is not used here.

const C := preload("res://sim/constants.gd")
const SimGrid := preload("res://sim/grid.gd")
const SimGeom := preload("res://sim/geom.gd")
const SimLevelLoader := preload("res://sim/level_loader.gd")
const SimPathfinder := preload("res://sim/pathfinder.gd")
const SimEventLog := preload("res://sim/event_log.gd")

## Scout pacing (view/controller + this sim only).
const BUDGET_S := 90.0
const MOVE_CELLS_PER_S := 0.5
const OPEN_S := 2.0
const REVEAL_RANGE_CHEBYSHEV := 2 ## operator within this of hidden supply → reveal

const ITEM_LABEL_ZH := {
	"kar98k": "Kar98k",
	"mp40": "MP40",
	"mg42": "MG42",
	"grenade": "手雷",
	"mine": "地雷",
	"ammo_7.92": "7.92 弹药",
	"ammo_9mm": "9mm 弹药",
}

var level: Dictionary = {}
var grid: SimGrid = null
var log: SimEventLog = null
var tick: int = 0
var phase: String = "scout" ## scout | setup (finished)
var alert: String = C.ALERT_QUIET
var operators: Array = []
var sentries: Array = []
var patrols: Array = []
var supplies: Array = [] ## runtime supply state dicts
var kit: Dictionary = {} ## {weapons:[{weapon_id,count}], ammo_pools:[{pool_id,rounds}]}
var expose_streak: int = 0
var suspicious_count: int = 0
var suspicious_recover_ticks: int = 0
var area_expose_streak: int = 0
var finished: bool = false
var finish_reason: String = "" ## "player" | "budget"
var events_this_tick: Array = []


func setup(level_data: Dictionary) -> void:
	level = level_data
	grid = SimLevelLoader.build_grid(level)
	log = SimEventLog.new()
	log.reset(str(level.get("id", "yard")), int(level.get("version", 1)), "scout")
	tick = 0
	phase = "scout"
	alert = C.ALERT_QUIET
	finished = false
	finish_reason = ""
	expose_streak = 0
	suspicious_count = 0
	suspicious_recover_ticks = 0
	area_expose_streak = 0
	events_this_tick.clear()
	_init_kit_from_loadout()
	_init_operators()
	_init_observers()
	_init_supplies()


func begin_scout() -> void:
	phase = "scout"
	finished = false
	log.emit(0, "phase", {"actor": "system", "payload": {"phase": "scout"}})
	log.emit(0, "scout_start", {
		"actor": "system",
		"payload": {"budget_s": BUDGET_S},
	})


func remaining_budget_s() -> float:
	var used := float(tick) * C.DT_S
	return maxf(0.0, BUDGET_S - used)


func budget_ticks() -> int:
	return int(round(BUDGET_S / C.DT_S))


func move_ticks_per_cell() -> int:
	return int(round(1.0 / (MOVE_CELLS_PER_S * C.DT_S))) ## 40 at 0.5 c/s


func open_ticks() -> int:
	return int(round(OPEN_S / C.DT_S)) ## 40


func has_mg42() -> bool:
	for w in kit.get("weapons", []):
		if str(w.get("weapon_id", "")) == "mg42" and int(w.get("count", 0)) > 0:
			return true
	return false


func mg42_unlocked() -> bool:
	return has_mg42()


func kit_snapshot() -> Dictionary:
	return kit.duplicate(true)


func is_finished() -> bool:
	return finished


## Full A* path including start cell (empty = unreachable). Does not mutate state.
func compute_path(op_id: String, goal: Vector2i) -> Array:
	if finished or phase != "scout":
		return []
	if not grid.walkable(goal.x, goal.y):
		return []
	var op := _op_by_id(op_id)
	if op.is_empty():
		return []
	var from := Vector2i(int(op["x"]), int(op["y"]))
	return SimPathfinder.find_path_avoiding(grid, from, goal, _occupied_cells(op_id))


func is_cell_watched(x: float, y: float, tier: String = "ground") -> bool:
	return _seen_by_observers(x, y, tier)


func request_move(op_id: String, goal: Vector2i) -> bool:
	if finished or phase != "scout":
		return false
	if not grid.walkable(goal.x, goal.y):
		return false
	var op := _op_by_id(op_id)
	if op.is_empty():
		return false
	# Cancel open if moving away.
	op["open_supply_id"] = ""
	op["open_ticks_left"] = 0
	var path: Array = compute_path(op_id, goal)
	if path.is_empty():
		return false
	# path[0] is current cell; queue the rest.
	var queue: Array = []
	for i in range(1, path.size()):
		queue.append(path[i])
	op["path"] = queue
	op["move_ticks_left"] = move_ticks_per_cell() if not queue.is_empty() else 0
	log.emit(tick, "move", {
		"actor": op_id,
		"payload": {"to": {"x": goal.x, "y": goal.y}, "steps": queue.size()},
	})
	return true


func request_open_at(op_id: String, supply_id: String = "") -> bool:
	## Start opening a supply the operator is standing on (or named id on cell).
	if finished or phase != "scout":
		return false
	var op := _op_by_id(op_id)
	if op.is_empty():
		return false
	var sx := int(op["x"])
	var sy := int(op["y"])
	var s := _supply_at(sx, sy) if supply_id.is_empty() else _supply_by_id(supply_id)
	if s.is_empty():
		return false
	if not bool(s.get("revealed", false)):
		return false
	if bool(s.get("opened", false)):
		return false
	if int(s.get("x", -1)) != sx or int(s.get("y", -1)) != sy:
		return false
	op["path"] = []
	op["move_ticks_left"] = 0
	op["open_supply_id"] = str(s["id"])
	op["open_ticks_left"] = open_ticks()
	s["opening"] = true
	s["open_progress"] = 0.0
	log.emit(tick, "supply_open", {
		"actor": op_id,
		"payload": {"supply_id": str(s["id"]), "state": "start"},
	})
	return true


func finish_scout(reason: String = "player") -> void:
	if finished:
		return
	finished = true
	finish_reason = reason
	phase = "setup"
	# Clear in-progress moves/opens.
	for op in operators:
		op["path"] = []
		op["move_ticks_left"] = 0
		op["open_supply_id"] = ""
		op["open_ticks_left"] = 0
	for s in supplies:
		s["opening"] = false
	log.emit(tick, "phase", {"actor": "system", "payload": {"phase": "setup", "reason": reason}})
	log.emit(tick, "scout_end", {
		"actor": "system",
		"payload": {
			"reason": reason,
			"has_mg42": has_mg42(),
			"kit": kit_snapshot(),
		},
	})


func advance_one_tick() -> void:
	events_this_tick.clear()
	if finished or phase != "scout":
		return
	tick += 1
	_step_patrols()
	_step_operator_moves()
	_step_opens()
	_step_reveal()
	var exposed := _any_operator_exposed()
	_step_alert(exposed)
	if tick >= budget_ticks():
		finish_scout("budget")


func supply_draw_states() -> Dictionary:
	## id → {revealed, opened, opening, open_progress, label}
	var out: Dictionary = {}
	for s in supplies:
		var st := "hidden"
		if bool(s.get("revealed", false)):
			if bool(s.get("opened", false)):
				st = "searched"
			elif bool(s.get("opening", false)):
				st = "searching"
			else:
				st = "unsearched"
		out[str(s["id"])] = {
			"revealed": bool(s.get("revealed", false)),
			"opened": bool(s.get("opened", false)),
			"opening": bool(s.get("opening", false)),
			"open_progress": float(s.get("open_progress", 0.0)),
			"state": st,
			"x": int(s["x"]),
			"y": int(s["y"]),
		}
	return out


func item_label_zh(item_id: String) -> String:
	return str(ITEM_LABEL_ZH.get(item_id, item_id))


func _init_kit_from_loadout() -> void:
	var ls: Dictionary = level.get("loadout_start", {})
	kit = {
		"weapons": [],
		"ammo_pools": [],
	}
	for w in ls.get("weapons", []):
		kit["weapons"].append({
			"weapon_id": str(w.get("weapon_id", "")),
			"count": int(w.get("count", 1)),
		})
	for a in ls.get("ammo_pools", []):
		kit["ammo_pools"].append({
			"pool_id": str(a.get("pool_id", "")),
			"rounds": int(a.get("rounds", 0)),
		})


func _init_operators() -> void:
	operators.clear()
	var i := 0
	for entry in level.get("squad_insertion", []):
		var oid := str(entry.get("id", "op_%d" % (i + 1)))
		operators.append({
			"id": oid,
			"x": float(entry.get("x", 11)),
			"y": float(entry.get("y", 1)),
			"facing_deg": float(entry.get("facing_deg", 90)),
			"tier": grid.tier_at(float(entry.get("x", 11)), float(entry.get("y", 1))),
			"display_name": str(entry.get("display_name", "%d号" % (i + 1))),
			"alive": true,
			"weapon_id": "",
			"path": [],
			"move_ticks_left": 0,
			"open_supply_id": "",
			"open_ticks_left": 0,
		})
		i += 1


func _init_observers() -> void:
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


func _init_supplies() -> void:
	supplies.clear()
	for s in level.get("supplies", []):
		var vis := str(s.get("visibility", "open"))
		var hidden := vis == "hidden" or bool(s.get("hidden", false))
		supplies.append({
			"id": str(s.get("id", "supply")),
			"x": int(s.get("x", 0)),
			"y": int(s.get("y", 0)),
			"visibility": vis,
			"hidden": hidden,
			"revealed": not hidden,
			"opened": false,
			"opening": false,
			"open_progress": 0.0,
			"contents": (s.get("contents", []) as Array).duplicate(true),
			"requires_scout_region": str(s.get("requires_scout_region", "")),
		})


func _op_by_id(op_id: String) -> Dictionary:
	for op in operators:
		if str(op["id"]) == op_id:
			return op
	return {}


func _supply_by_id(sid: String) -> Dictionary:
	for s in supplies:
		if str(s["id"]) == sid:
			return s
	return {}


func _supply_at(x: int, y: int) -> Dictionary:
	for s in supplies:
		if int(s["x"]) == x and int(s["y"]) == y:
			return s
	return {}


func _occupied_cells(except_id: String) -> Dictionary:
	var avoid: Dictionary = {}
	for op in operators:
		if str(op["id"]) == except_id:
			continue
		avoid[Vector2i(int(op["x"]), int(op["y"]))] = true
	return avoid


func _step_patrols() -> void:
	for p in patrols:
		_advance_patrol(p)


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
	p["cone"] = p.get("cone", {}).duplicate(true)
	p["cone"]["facing_deg"] = SimGeom.bearing_deg(float(a["x"]), float(a["y"]), float(b["x"]), float(b["y"]))
	if alert == C.ALERT_AREA and p.has("alert_route") and p["alert_route"].has("facing_deg"):
		p["cone"]["facing_deg"] = float(p["alert_route"]["facing_deg"])


func _step_operator_moves() -> void:
	var step_cost := move_ticks_per_cell()
	for op in operators:
		var path: Array = op.get("path", [])
		if path.is_empty():
			op["move_ticks_left"] = 0
			# Auto-start open if standing on unopened revealed supply.
			_try_autostart_open(op)
			continue
		var left := int(op.get("move_ticks_left", 0))
		if left <= 0:
			op["move_ticks_left"] = step_cost
			left = step_cost
		left -= 1
		op["move_ticks_left"] = left
		if left > 0:
			continue
		var next: Vector2i = path[0]
		path.remove_at(0)
		op["path"] = path
		var px := int(op["x"])
		var py := int(op["y"])
		op["x"] = float(next.x)
		op["y"] = float(next.y)
		op["tier"] = grid.tier_at(float(next.x), float(next.y))
		op["facing_deg"] = SimGeom.bearing_deg(float(px), float(py), float(next.x), float(next.y))
		op["move_ticks_left"] = step_cost if not path.is_empty() else 0
		if path.is_empty():
			_try_autostart_open(op)


func _try_autostart_open(op: Dictionary) -> void:
	if str(op.get("open_supply_id", "")) != "":
		return
	var s := _supply_at(int(op["x"]), int(op["y"]))
	if s.is_empty():
		return
	if bool(s.get("revealed", false)) and not bool(s.get("opened", false)) and not bool(s.get("opening", false)):
		request_open_at(str(op["id"]), str(s["id"]))


func _step_opens() -> void:
	for op in operators:
		var sid := str(op.get("open_supply_id", ""))
		if sid.is_empty():
			continue
		var left := int(op.get("open_ticks_left", 0)) - 1
		op["open_ticks_left"] = left
		var s := _supply_by_id(sid)
		if s.is_empty():
			op["open_supply_id"] = ""
			continue
		var total := float(open_ticks())
		s["open_progress"] = 1.0 - (float(maxi(left, 0)) / total)
		s["opening"] = true
		if left > 0:
			continue
		_complete_open(op, s)


func _complete_open(op: Dictionary, s: Dictionary) -> void:
	s["opened"] = true
	s["opening"] = false
	s["open_progress"] = 1.0
	op["open_supply_id"] = ""
	op["open_ticks_left"] = 0
	var gained: Array = []
	for c in s.get("contents", []):
		var wid := str(c.get("weapon_id", ""))
		var amt := int(c.get("amount", 1))
		if wid.is_empty() or amt <= 0:
			continue
		_add_to_kit(wid, amt)
		gained.append({"id": wid, "amount": amt, "label": item_label_zh(wid)})
	log.emit(tick, "supply_open", {
		"actor": str(op["id"]),
		"payload": {"supply_id": str(s["id"]), "state": "done", "gained": gained},
	})
	for g in gained:
		log.emit(tick, "pickup", {
			"actor": str(op["id"]),
			"payload": {
				"item_id": str(g["id"]),
				"amount": int(g["amount"]),
				"label": str(g["label"]),
				"supply_id": str(s["id"]),
			},
		})


func _add_to_kit(item_id: String, amount: int) -> void:
	if item_id.begins_with("ammo_"):
		var pool := item_id.trim_prefix("ammo_")
		var found := false
		for a in kit.get("ammo_pools", []):
			if str(a.get("pool_id", "")) == pool:
				a["rounds"] = int(a.get("rounds", 0)) + amount
				found = true
				break
		if not found:
			kit["ammo_pools"].append({"pool_id": pool, "rounds": amount})
		return
	var found_w := false
	for w in kit.get("weapons", []):
		if str(w.get("weapon_id", "")) == item_id:
			w["count"] = int(w.get("count", 0)) + amount
			found_w = true
			break
	if not found_w:
		kit["weapons"].append({"weapon_id": item_id, "count": amount})


func _step_reveal() -> void:
	for s in supplies:
		if bool(s.get("revealed", false)):
			continue
		if not bool(s.get("hidden", false)) and str(s.get("visibility", "")) != "hidden":
			s["revealed"] = true
			continue
		var sx := int(s["x"])
		var sy := int(s["y"])
		for op in operators:
			var dx := absi(int(op["x"]) - sx)
			var dy := absi(int(op["y"]) - sy)
			if maxi(dx, dy) <= REVEAL_RANGE_CHEBYSHEV:
				s["revealed"] = true
				log.emit(tick, "supply_reveal", {
					"actor": str(op["id"]),
					"payload": {
						"supply_id": str(s["id"]),
						"x": sx,
						"y": sy,
						"range": REVEAL_RANGE_CHEBYSHEV,
					},
				})
				break


func _any_operator_exposed() -> bool:
	for op in operators:
		if _seen_by_observers(float(op["x"]), float(op["y"]), str(op.get("tier", "ground"))):
			return true
	return false


func _seen_by_observers(tx: float, ty: float, target_tier: String) -> bool:
	for s in sentries:
		if _observer_sees(s, float(s["x"]), float(s["y"]), str(s.get("tier", "ground")), tx, ty, target_tier):
			return true
	for p in patrols:
		if _observer_sees(p, float(p["x"]), float(p["y"]), C.TIER_GROUND, tx, ty, target_tier):
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
	if ttier == C.TIER_HIGH:
		rng *= C.SILHOUETTE_MUL
	if not SimGeom.in_cone(ox, oy, facing, half, rng, tx, ty):
		return false
	return grid.los_clear(ox, oy, otier, tx, ty, ttier)


func _step_alert(exposed: bool) -> void:
	## Same tier thresholds as NightSim / ADR-ALERT (scout uses them for risk).
	match alert:
		C.ALERT_QUIET:
			if exposed:
				expose_streak += 1
				if expose_streak >= C.EXPOSE_TO_SUSPICIOUS_TICKS:
					_set_alert(C.ALERT_SUSPICIOUS, "expose_30_ticks")
					suspicious_count += 1
					if suspicious_count >= 2:
						_set_alert(C.ALERT_AREA, "second_suspicious")
					expose_streak = 0
					suspicious_recover_ticks = 0
			else:
				expose_streak = 0
		C.ALERT_SUSPICIOUS:
			if exposed:
				expose_streak += 1
				suspicious_recover_ticks = 0
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
			else:
				area_expose_streak = 0
		C.ALERT_GLOBAL:
			pass


func _set_alert(to: String, reason: String) -> void:
	if to == alert:
		return
	var from := alert
	alert = to
	log.emit(tick, "alert", {
		"actor": "system",
		"payload": {"from": from, "to": to, "reason": reason},
	})
