extends RefCounted

## Presentation cue from saved moving pose, not a footfall event or old trail.
const ActorPose := preload("res://scripts/presentation/actor_pose.gd")
const FORMAT := 1
const MAX_ACTORS := 64
const LEVELS := ["yard","warehouse","pump","railcut","depot","radio"]


static func active(frame: Dictionary) -> Array:
	if not _int_eq(frame,"movement_fx_schema",FORMAT) or not _int_eq(frame,"movement_fx_playback_schema",2) or typeof(frame.get("movement_fx_source_token")) != TYPE_INT or frame.movement_fx_source_token == 0:
		return []
	if not _int_eq(frame,"schema",BattleLog.SCHEMA_VERSION) or typeof(frame.get("visual_unsupported")) != TYPE_BOOL or frame.visual_unsupported or not _int_eq(frame,"animation_schema",ActorPose.FORMAT) or typeof(frame.get("actor_asset_revision")) != TYPE_STRING or frame.actor_asset_revision != ActorPose.ASSET_REVISION:
		return []
	if typeof(frame.get("phase")) != TYPE_INT or frame.phase not in [0,1,4,5] or typeof(frame.get("recorded_phase")) != TYPE_INT or frame.recorded_phase not in [0,1,5] or (frame.phase != 4 and frame.phase != frame.recorded_phase):
		return []
	if typeof(frame.get("attempt_id")) != TYPE_STRING or frame.attempt_id.is_empty() or typeof(frame.get("level_id")) != TYPE_STRING or frame.level_id not in LEVELS or not _nonnegative(frame,"wave_id") or not _positive(frame,"wave_count") or frame.wave_id >= frame.wave_count:
		return []
	var clock: Variant = frame.get("movement_fx_clock_s")
	var domain: Variant = frame.get("movement_fx_clock_domain")
	if not _number(clock) or float(clock) < 0.0 or typeof(domain) != TYPE_STRING or domain != ("simulation" if frame.recorded_phase == 1 else "command"):
		return []
	var raw: Variant = frame.get("movement_fx_actors")
	if not raw is Array or raw.size() > MAX_ACTORS:
		return []
	var samples: Array = []
	var counts := {}
	for actor: Variant in raw:
		if not actor is Dictionary: continue
		var result := _sample(actor)
		if result.is_empty(): continue
		result["clock_s"] = float(clock)
		samples.append(result)
		counts[result.identity] = int(counts.get(result.identity,0)) + 1
	var unique: Array = samples.filter(func(item: Dictionary) -> bool: return counts[item.identity] == 1)
	unique.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return left.id < right.id if left.group == right.group else left.group == "ops")
	return unique


static func _sample(actor: Dictionary) -> Dictionary:
	var group: Variant = actor.get("group")
	if typeof(group) != TYPE_STRING or group not in ["ops","enemies"] or not _positive(actor,"id") or (group == "ops" and actor.id > 3) or typeof(actor.get("action")) != TYPE_STRING:
		return {}
	for flag: String in ["active","alive","moving"]:
		if typeof(actor.get(flag)) != TYPE_BOOL or not actor[flag]: return {}
	if not actor.get("pos") is Vector2 or not actor.pos.is_finite() or not _number(actor.get("facing")):
		return {}
	var stance := 0
	var sprinting := false
	if group == "ops":
		if typeof(actor.get("stance")) != TYPE_INT or actor.stance not in [0,1] or typeof(actor.get("sprinting")) != TYPE_BOOL:
			return {}
		stance = actor.stance
		sprinting = actor.sprinting
		if (stance == 1 and sprinting) or actor.get("action") != ("crouch_walk" if stance == 1 else ("run" if sprinting else "walk")):
			return {}
	elif actor.get("action") != "walk":
		return {}
	return {"identity":"%s:%d" % [group,actor.id],"group":group,"id":actor.id,
		"position":actor.pos,"facing":float(actor.facing),"stance":stance,"sprinting":sprinting}


static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))


static func _int_eq(data: Dictionary, key: String, value: int) -> bool:
	return typeof(data.get(key)) == TYPE_INT and data[key] == value


static func _nonnegative(data: Dictionary, key: String) -> bool:
	return typeof(data.get(key)) == TYPE_INT and data[key] >= 0


static func _positive(data: Dictionary, key: String) -> bool:
	return typeof(data.get(key)) == TYPE_INT and data[key] > 0
