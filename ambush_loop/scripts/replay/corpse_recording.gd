extends RefCounted

## Live recording seam only. Weak node links never enter a historical frame.
const Pose := preload("res://scripts/presentation/actor_pose.gd")
var scope := ""
var records := {}
var links := {}
var actor_links := {}
var _seq := 0
var _last_frame: Array = []


func reset(id: String) -> void:
	scope = id
	records.clear()
	links.clear()
	actor_links.clear()
	_seq = 0
	_last_frame.clear()


func remember(host: Node, loot: Node2D, actor: Node2D, group: String) -> void:
	if loot == null or scope.is_empty() or group not in ["enemies", "sentries"]:
		return
	var model := "enemy_patrol"
	if group == "enemies":
		model = {"main": "enemy_patrol", "flank": "enemy_flank", "sneak": "enemy_sneak", "echo": "enemy_radio"}.get(actor.kind_id(), "")
	if model.is_empty():
		return
	var id := "%s:body:%d" % [scope, records.size()]
	var domain := _domain(host)
	var clock := _clock(host, domain)
	records[id] = {"schema": 1, "id": id, "scope_id": scope, "asset_revision": Pose.ASSET_REVISION,
		"source_group": group, "source_actor_id": int(actor.label_id), "source_attempt_id": host.battle_log.attempt_id,
		"source_wave_id": host.battle_log.wave_id, "source_pos": actor.global_position,
		"model": model, "facing": float(actor.facing_deg), "pos": loot.global_position,
		"death_clock_domain": domain, "death_clock_s": clock, "death_age_s": 0.0,
		"last_domain": domain, "last_clock": clock, "mode": "ground", "carrier_id": -1,
		"ever_grabbed": false, "ground_anchor": {}, "last_carrier": {}, "transition": {}, "transition_age_s": 0.0}
	links[id] = weakref(loot)
	actor_links[actor.get_instance_id()] = id


func id_for_actor(actor: Node) -> String:
	return str(actor_links.get(actor.get_instance_id(), ""))


func id_for_loot(loot: Node) -> String:
	for id in links:
		if links[id].get_ref() == loot:
			return id
	return ""


func action(host: Node, op: Node, loot: Node, mode: String) -> void:
	var id := id_for_loot(loot)
	if id.is_empty():
		return
	var record: Dictionary = records[id]
	_advance(record, host)
	var carrier := _carrier(op)
	record.pos = loot.global_position
	record.last_carrier = carrier
	record.ever_grabbed = true
	record.mode = mode
	record.transition_age_s = 0.0
	record.transition = {"event_id": "%s:corpse:%d:%d" % [scope, host.battle_log.wave_id, _seq],
		"seq": _seq, "attempt_id": host.battle_log.attempt_id, "wave_id": host.battle_log.wave_id,
		"phase": int(host.phase), "actor_id": int(op.op_id), "weapon": str(op.weapon_id), "clock_domain": _domain(host)}
	_seq += 1
	if mode == "release":
		record.ground_anchor = carrier.duplicate(true)


func cancel_action(op_id: int) -> void:
	for record in records.values():
		if int(record.transition.get("actor_id", -1)) == op_id:
			record.mode = "hold" if int(record.carrier_id) >= 0 else "ground"
			record.transition.clear()


func capture(host: Node, data: Dictionary) -> Array:
	if host.phase == host.Phase.REPLAY:
		return _last_frame.duplicate(true)
	var output: Array = []
	for record in records.values():
		_advance(record, host)
		var loot: Node2D = links[record.id].get_ref()
		var available: bool = is_instance_valid(loot) and not bool(loot.collected)
		if is_instance_valid(loot):
			record.pos = loot.global_position
		var owner: Node = null
		if available:
			# Original gameplay permits shared hauled_loot references. Last operator
			# in the existing follow loop wins; presentation adds no ownership lock.
			for op in host.operators:
				if op.alive and op.visible and op.is_hauling() and op.hauled_loot == loot:
					owner = op
		var previous: int = int(record.carrier_id)
		record.carrier_id = int(owner.op_id) if owner != null else -1
		if owner != null:
			record.last_carrier = _carrier(owner)
			record.ever_grabbed = true
			if previous != int(record.carrier_id) and record.mode != "grab":
				record.mode = "hold"
				record.transition.clear()
		elif previous >= 0:
			record.ground_anchor = record.last_carrier.duplicate(true)
			if record.mode != "release":
				record.mode = "ground"
				record.transition.clear()
		if not available and record.mode == "grab":
			record.mode = "ground"
			record.ground_anchor = record.last_carrier.duplicate(true)
			record.transition.clear()
		var transition: Dictionary = record.transition
		var actor: Node = null
		for op in host.operators:
			if int(op.op_id) == int(transition.get("actor_id", -1)):
				actor = op
				break
		var valid: bool = not transition.is_empty() and actor != null and actor.alive and actor.visible \
			and int(transition.phase) == int(host.phase) and int(transition.wave_id) == host.battle_log.wave_id \
			and str(transition.attempt_id) == host.battle_log.attempt_id and str(transition.weapon) == str(actor.weapon_id) \
			and not actor.is_moving() and not actor.is_searching()
		if record.mode == "grab" and owner != actor:
			valid = false
		if not valid or (record.mode == "grab" and float(record.transition_age_s) >= 1.0) or (record.mode == "release" and float(record.transition_age_s) >= 0.7):
			record.mode = "hold" if owner != null else "ground"
			record.transition.clear()
		var pairing: bool = owner != null and host._is_command_phase() and not owner.is_searching()
		var shown_mode: String = str(record.mode) if pairing or record.mode == "release" else "ground"
		var entry := {"schema": 1, "id": record.id, "scope_id": scope, "asset_revision": record.asset_revision,
			"source_group": record.source_group, "source_actor_id": record.source_actor_id,
			"source_attempt_id": record.source_attempt_id, "source_wave_id": record.source_wave_id,
			"source_pos": record.source_pos, "model": record.model, "pos": record.pos, "facing": record.facing,
			"active": true, "loot_available": available, "carrier_id": record.carrier_id, "pairing": pairing,
			"mode": shown_mode, "ever_grabbed": record.ever_grabbed, "death_age_s": record.death_age_s,
			"transition_age_s": record.transition_age_s, "transition": record.transition.duplicate(true),
			"carrier": record.last_carrier.duplicate(true), "ground_anchor": record.ground_anchor.duplicate(true)}
		output.append(entry)
		for item in data.ops:
			if int(item.id) == int(record.carrier_id):
				item["corpse_known_haul"] = true
			if (pairing and int(item.id) == int(record.carrier_id)) or (shown_mode == "release" and int(item.id) == int(transition.get("actor_id", -1))):
				item["corpse_pose"] = {"schema": 1, "scope_id": scope, "body_id": record.id,
					"actor_id": item.id, "phase": int(host.phase), "wave_id": host.battle_log.wave_id,
					"mode": shown_mode, "age_s": record.transition_age_s,
					"weapon": str(item.weapon), "attempt_id": host.battle_log.attempt_id,
					"event_id": str(record.transition.get("event_id", ""))}
	_last_frame = output.duplicate(true)
	return output


static func _carrier(op: Node) -> Dictionary:
	return {"id": int(op.op_id), "pos": op.global_position, "facing": float(op.facing_deg),
		"model": ["operator_rifle", "operator_mg", "operator_scout"][int(op.role)], "stance": int(op.stance)}


static func _domain(host: Node) -> String:
	return "simulation" if host.phase == host.Phase.WATCHING else "command"


static func _clock(host: Node, domain: String) -> float:
	return float(host.battle_log.timeline_tick(host.sim.tick)) / 60.0 if domain == "simulation" else float(host._pose_command_clock_s)


static func _advance(record: Dictionary, host: Node) -> void:
	var domain := _domain(host)
	# On a domain change, close the original clock interval before switching.
	# This removes capture-frequency dependence at the final battle tick.
	var delta := maxf(_clock(host, str(record.last_domain)) - float(record.last_clock), 0.0)
	record.death_age_s = float(record.death_age_s) + delta
	record.transition_age_s = float(record.transition_age_s) + delta
	record.last_domain = domain
	record.last_clock = _clock(host, domain)
