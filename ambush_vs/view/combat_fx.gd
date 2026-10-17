extends RefCounted
class_name GreyboxCombatFx

## PLAY-3 / VS-FX1: consume NightSim log events into presentation FX.
## Does not mutate sim state. Muzzle style adapted from main muzzle_flash.gd
## (ambush_loop/scripts/fx/muzzle_flash.gd) — see PROVENANCE_VS.md.

const TRACER_LIFE_S := 0.12
const MUZZLE_LIFE_S := 0.09
const HIT_LIFE_S := 0.16
const BLAST_LIFE_S := 0.40
const BODY_FALL_S := 0.35

var bodies: Dictionary = {} ## enemy_id → {x,y,facing_deg,age}
var flashes: Array = [] ## {x,y,facing_deg,weapon_id,age,life}
var tracers: Array = [] ## {x0,y0,x1,y1,weapon_id,age,life}
var hits: Array = [] ## {x,y,age,life}
var blasts: Array = [] ## {x,y,kind,age,life} kind=mine|grenade

var fires_seen: int = 0
var enemy_fires_seen: int = 0
var hits_seen: int = 0
var kills_seen: int = 0
var mines_seen: int = 0
var grenade_blasts_seen: int = 0
var last_kill_id: String = ""
var shake_amp: float = 0.0
var shake_time_left: int = 0 ## wall ticks / frames handled by controller


func reset() -> void:
	bodies.clear()
	flashes.clear()
	tracers.clear()
	hits.clear()
	blasts.clear()
	fires_seen = 0
	enemy_fires_seen = 0
	hits_seen = 0
	kills_seen = 0
	mines_seen = 0
	grenade_blasts_seen = 0
	last_kill_id = ""
	shake_amp = 0.0
	shake_time_left = 0


func stats() -> Dictionary:
	return {
		"fires": fires_seen,
		"enemy_fires": enemy_fires_seen,
		"hits": hits_seen,
		"kills": kills_seen,
		"mines": mines_seen,
		"grenade_blasts": grenade_blasts_seen,
		"bodies": bodies.size(),
	}


func consume_events(events: Array, enemies: Array, operators: Array) -> Dictionary:
	## Process a slice of sim.log.events. Returns per-call counts.
	var n_fire := 0
	var n_enemy_fire := 0
	var n_hit := 0
	var n_kill := 0
	var n_mine := 0
	var n_gblast := 0
	for ev in events:
		var t := str(ev.get("type", ""))
		match t:
			"fire":
				n_fire += 1
				fires_seen += 1
				_on_fire(ev, enemies, operators)
			"enemy_fire":
				n_enemy_fire += 1
				enemy_fires_seen += 1
				_on_enemy_fire(ev, enemies, operators)
			"hit":
				n_hit += 1
				hits_seen += 1
				_on_hit(ev, enemies, operators)
			"kill":
				n_kill += 1
				kills_seen += 1
				_on_kill(ev, enemies)
			"mine_detonate":
				n_mine += 1
				mines_seen += 1
				_on_blast(ev, "mine")
			"grenade_blast":
				n_gblast += 1
				grenade_blasts_seen += 1
				_on_blast(ev, "grenade")
			_:
				pass
	return {
		"fires": n_fire,
		"enemy_fires": n_enemy_fire,
		"hits": n_hit,
		"kills": n_kill,
		"mines": n_mine,
		"grenade_blasts": n_gblast,
	}


func advance(delta: float) -> void:
	_age_list(flashes, delta)
	_age_list(tracers, delta)
	_age_list(hits, delta)
	_age_list(blasts, delta)
	for id in bodies.keys():
		var b: Dictionary = bodies[id]
		b["age"] = float(b.get("age", 0.0)) + delta


func living_enemy_count(enemies: Array) -> int:
	var n := 0
	for e in enemies:
		if bool(e.get("alive", true)) and bool(e.get("entered", false)) and not bool(e.get("escaped", false)):
			n += 1
	return n


func _age_list(arr: Array, delta: float) -> void:
	var i := 0
	while i < arr.size():
		var item: Dictionary = arr[i]
		item["age"] = float(item.get("age", 0.0)) + delta
		if float(item["age"]) >= float(item.get("life", 0.1)):
			arr.remove_at(i)
		else:
			i += 1


func _unit_by_id(units: Array, uid: String) -> Dictionary:
	for u in units:
		if str(u.get("id", "")) == uid:
			return u
	return {}


func _on_fire(ev: Dictionary, enemies: Array, operators: Array) -> void:
	var actor := str(ev.get("actor", ""))
	var target := str(ev.get("target", ""))
	var wid := str(ev.get("weapon_id", "kar98k"))
	var pos: Dictionary = ev.get("pos", {})
	var ax := float(pos.get("x", 0.0))
	var ay := float(pos.get("y", 0.0))
	var facing := float(ev.get("facing_deg", 0.0))
	var op := _unit_by_id(operators, actor)
	if not op.is_empty():
		ax = float(op.get("x", ax))
		ay = float(op.get("y", ay))
		facing = float(op.get("facing_deg", facing))
	var tx := ax + cos(deg_to_rad(facing))
	var ty := ay + sin(deg_to_rad(facing))
	var tgt := _unit_by_id(enemies, target)
	if not tgt.is_empty():
		tx = float(tgt.get("x", tx))
		ty = float(tgt.get("y", ty))
	flashes.append({
		"x": ax, "y": ay, "facing_deg": facing, "weapon_id": wid,
		"age": 0.0, "life": MUZZLE_LIFE_S * (1.35 if wid == "mg42" else 1.0),
	})
	tracers.append({
		"x0": ax, "y0": ay, "x1": tx, "y1": ty, "weapon_id": wid,
		"age": 0.0, "life": TRACER_LIFE_S * (1.2 if wid == "mg42" else 1.0),
	})


func _on_enemy_fire(ev: Dictionary, enemies: Array, operators: Array) -> void:
	## PLAY-6 return fire: muzzle + tracer from enemy toward operator.
	var actor := str(ev.get("actor", ""))
	var target := str(ev.get("target", ""))
	var pos: Dictionary = ev.get("pos", {})
	var ax := float(pos.get("x", 0.0))
	var ay := float(pos.get("y", 0.0))
	var facing := float(ev.get("facing_deg", 0.0))
	var en := _unit_by_id(enemies, actor)
	if not en.is_empty():
		ax = float(en.get("x", ax))
		ay = float(en.get("y", ay))
	var tx := ax + cos(deg_to_rad(facing))
	var ty := ay + sin(deg_to_rad(facing))
	var tgt := _unit_by_id(operators, target)
	if not tgt.is_empty():
		tx = float(tgt.get("x", tx))
		ty = float(tgt.get("y", ty))
		facing = rad_to_deg(atan2(ty - ay, tx - ax))
	flashes.append({
		"x": ax, "y": ay, "facing_deg": facing, "weapon_id": "enemy_rifle",
		"age": 0.0, "life": MUZZLE_LIFE_S,
	})
	tracers.append({
		"x0": ax, "y0": ay, "x1": tx, "y1": ty, "weapon_id": "enemy_rifle",
		"age": 0.0, "life": TRACER_LIFE_S,
	})


func _on_hit(ev: Dictionary, enemies: Array, operators: Array = []) -> void:
	var target := str(ev.get("target", ""))
	var tgt := _unit_by_id(enemies, target)
	if tgt.is_empty() and not operators.is_empty():
		tgt = _unit_by_id(operators, target)
	var x := 0.0
	var y := 0.0
	if not tgt.is_empty():
		x = float(tgt.get("x", 0.0))
		y = float(tgt.get("y", 0.0))
	hits.append({"x": x, "y": y, "age": 0.0, "life": HIT_LIFE_S})


func _on_kill(ev: Dictionary, enemies: Array) -> void:
	var tid := str(ev.get("target", ""))
	last_kill_id = tid
	var tgt := _unit_by_id(enemies, tid)
	var x := 0.0
	var y := 0.0
	var facing := 0.0
	if not tgt.is_empty():
		x = float(tgt.get("x", 0.0))
		y = float(tgt.get("y", 0.0))
		# Prefer march facing from last segment if present.
		facing = float(tgt.get("facing_deg", 0.0))
	bodies[tid] = {"x": x, "y": y, "facing_deg": facing, "age": 0.0}


func _on_blast(ev: Dictionary, kind: String) -> void:
	var pos: Dictionary = ev.get("pos", {})
	var x := float(pos.get("x", 0.0))
	var y := float(pos.get("y", 0.0))
	# mine_detonate may put coords in payload
	var payload: Dictionary = ev.get("payload", {})
	if not pos.has("x") and payload.has("x"):
		x = float(payload.get("x", x))
		y = float(payload.get("y", y))
	blasts.append({"x": x, "y": y, "kind": kind, "age": 0.0, "life": BLAST_LIFE_S})
	shake_amp = 7.0 if kind == "mine" else 5.0
	shake_time_left = 10
