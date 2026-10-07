extends RefCounted

## Pure saved confirmation reader. No live actor/tool lookup or wall clock.
const FORMAT := 1
const LIFETIME_TICKS := 180
const MAX_RECORDS := 48
const MAX_VICTIMS := 64
const LEVELS := ["yard","warehouse","pump","railcut","depot","radio"]


static func active(frame: Dictionary) -> Array:
	var raw: Variant = frame.get("tool_fx")
	if not raw is Array or raw.size() > MAX_RECORDS:
		return []
	var samples := []
	var counts := {}
	for value: Variant in raw:
		if not value is Dictionary: continue
		var result := sample(frame, value)
		if result.is_empty(): continue
		samples.append(result)
		for identity: String in [result.effect_id, result.tool_id]:
			counts[identity] = int(counts.get(identity, 0)) + 1
		if result.kind == "mine":
			var identity: String = result.original_event.event_id
			counts[identity] = int(counts.get(identity,0)) + 1
	var unique := samples.filter(func(item: Dictionary) -> bool:
		return counts[item.effect_id] == 1 and counts[item.tool_id] == 1 and (item.kind != "mine" or counts[item.original_event.event_id] == 1))
	unique.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left.seq < right.seq)
	return unique


static func sample(frame: Dictionary, effect: Dictionary) -> Dictionary:
	if not _int_eq(frame,"tool_fx_schema",FORMAT) or not _int_eq(frame,"tool_fx_playback_schema",2) or typeof(frame.get("tool_fx_source_token")) != TYPE_INT or frame.tool_fx_source_token == 0:
		return {}
	if not _int_eq(frame,"schema",BattleLog.SCHEMA_VERSION) or not _bool_eq(frame,"visual_unsupported",false) or typeof(frame.get("phase")) != TYPE_INT or frame.phase not in [0,1,2,3,4,5]:
		return {}
	if typeof(frame.get("recorded_phase")) != TYPE_INT or frame.recorded_phase not in [0,1,2,3,5] or not _nonnegative(frame,"playback_tick") or not _nonnegative(frame,"wave_id") or not _positive(frame,"wave_count") or frame.wave_id >= frame.wave_count:
		return {}
	if typeof(frame.get("attempt_id")) != TYPE_STRING or frame.attempt_id.is_empty() or frame.get("level_id") not in LEVELS:
		return {}
	if not _int_eq(effect,"schema",FORMAT) or not _bool_eq(effect,"confirmed",true) or not _int_eq(effect,"playback_schema",2) or effect.get("clock_domain") != "playback":
		return {}
	if effect.get("level_id") != frame.level_id or effect.get("attempt_id") != frame.attempt_id or not _int_eq(effect,"wave_id",frame.wave_id) or not _nonnegative(effect,"seq") or not _nonnegative(effect,"local_tick") or not _nonnegative(effect,"clock_tick"):
		return {}
	if typeof(effect.get("effect_id")) != TYPE_STRING or effect.effect_id != "%s:tool_fx:%d" % [frame.attempt_id,effect.seq] or not _tool_id(effect.get("tool_id"),frame.attempt_id):
		return {}
	if not _nonnegative(effect,"created_wave_id") or effect.created_wave_id > effect.wave_id or not _nonnegative(effect,"created_clock_tick") or effect.created_clock_tick > effect.clock_tick:
		return {}
	if effect.get("owner_group") != "ops" or not _positive(effect,"owner_id") or effect.owner_id > 3 or typeof(effect.get("phase")) != TYPE_INT or effect.phase not in [0,1,5]:
		return {}
	if not _position(effect.get("created_pos")) or not _position(effect.get("position")) or not _number(effect.get("radius")) or float(effect.radius) <= 0.0:
		return {}
	var age: int = frame.playback_tick - effect.clock_tick
	if age < 0 or age >= LIFETIME_TICKS:
		return {}
	var kind: Variant = effect.get("kind")
	if (kind == "grenade" and effect.get("variant") not in ["stiel","mills","mk2"]) or (kind == "mine" and effect.get("variant") != "mine") or kind not in ["grenade","mine"]:
		return {}
	var victims: Variant = effect.get("victims")
	if not victims is Array or victims.size() > MAX_VICTIMS:
		return {}
	var seen := {}
	for victim: Variant in victims:
		if not victim is Dictionary or victim.get("group") not in ["ops","enemies"] or not _positive(victim,"id") or (victim.group == "ops" and victim.id > 3) or not _position(victim.get("pos")):
			return {}
		for key in ["hp_before","hp_after","damage"]:
			if not _number(victim.get(key)): return {}
		var delta: float = float(victim.hp_before) - float(victim.hp_after)
		if not is_finite(delta) or float(victim.hp_before) < 0.0 or float(victim.damage) < 0.0 or float(victim.damage) != maxf(delta,0.0):
			return {}
		var identity := "%s:%d" % [victim.group,victim.id]
		if seen.has(identity): return {}
		seen[identity] = true
	var event: Variant = effect.get("original_event")
	if not event is Dictionary:
		return {}
	if kind == "grenade":
		if not event.is_empty(): return {}
	elif not _mine_event(frame,effect,event,victims):
		return {}
	var result := effect.duplicate(true)
	result["age_ticks"] = age
	return result


static func _mine_event(frame: Dictionary, effect: Dictionary, reference: Dictionary, victims: Array) -> bool:
	if victims.size() != 1 or victims.front().group != "enemies" or not _nonnegative(reference,"seq") or not _int_eq(reference,"actor_id",victims.front().id) or not _int_eq(reference,"target_id",-1) or reference.get("type") != "mine" or reference.get("position") != effect.position or reference.get("attempt_id") != frame.attempt_id or not _int_eq(reference,"wave_id",frame.wave_id):
		return false
	if typeof(reference.get("event_id")) != TYPE_STRING or reference.event_id != "%s:%d:%d" % [frame.attempt_id,frame.wave_id,reference.seq]:
		return false
	var events: Variant = frame.get("events")
	if not events is Array or reference.seq >= events.size():
		return false
	var event: Variant = events[reference.seq]
	if not event is Dictionary or not _int_eq(event,"schema",BattleLog.SCHEMA_VERSION) or not _int_eq(event,"playback_schema",2) or not _int_eq(event,"tick",effect.local_tick) or not _nonnegative(event,"playback_tick") or event.playback_tick < effect.clock_tick or event.playback_tick > frame.playback_tick:
		return false
	# A synchronous death may advance the presentation boundary before logging
	# the original mine event; retain that actual saved event clock.
	for key: String in ["event_id","seq","actor_id","target_id","position","type","attempt_id","wave_id"]:
		if typeof(event.get(key)) != typeof(reference.get(key)) or event.get(key) != reference.get(key): return false
	return true


static func _tool_id(raw: Variant, attempt: String) -> bool:
	if typeof(raw) != TYPE_STRING or not raw.begins_with(attempt + ":tool:"):
		return false
	var ordinal: String = raw.substr((attempt + ":tool:").length())
	return ordinal.is_valid_int() and ordinal.to_int() >= 0 and str(ordinal.to_int()) == ordinal


static func _position(raw: Variant) -> bool:
	return raw is Vector2 and raw.is_finite()


static func _number(raw: Variant) -> bool:
	return (typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT) and is_finite(float(raw))


static func _nonnegative(data: Dictionary, key: String) -> bool:
	return typeof(data.get(key)) == TYPE_INT and data[key] >= 0


static func _positive(data: Dictionary, key: String) -> bool:
	return typeof(data.get(key)) == TYPE_INT and data[key] > 0


static func _int_eq(data: Dictionary, key: String, value: int) -> bool:
	return typeof(data.get(key)) == TYPE_INT and data[key] == value


static func _bool_eq(data: Dictionary, key: String, value: bool) -> bool:
	return typeof(data.get(key)) == TYPE_BOOL and data[key] == value
