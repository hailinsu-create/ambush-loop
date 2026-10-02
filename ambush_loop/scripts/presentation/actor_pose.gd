extends RefCounted

## Pure frame-to-pose conversion. No live actor or wall clock is consulted.
const FORMAT := 1
const ASSET_REVISION := "00b270863ba5a2cd5425abf2a31e78965c72ae45"
const FIRE_SECONDS := 0.23333333333333334


static func supported(data: Dictionary) -> bool:
	return int(data.get("animation_schema", 0)) == FORMAT and str(data.get("actor_asset_revision", "")) == ASSET_REVISION and data.has("pose_clock_s") and is_finite(float(data.pose_clock_s)) and float(data.pose_clock_s) >= 0.0


static func sample(item: Dictionary, frame: Dictionary, group: String) -> Dictionary:
	var clock := float(frame.get("pose_clock_s", 0.0))
	var result := {"action": "idle", "seconds": maxf(clock, 0.0), "event_id": "", "fallback": ""}
	if not bool(item.get("alive", true)):
		var ev := _last_event(frame, group, int(item.id), "op_down" if group == "ops" else "kill")
		result.action = "death"
		result.seconds = _elapsed(frame, ev) if not ev.is_empty() else 1.2
		result.event_id = str(ev.get("event_id", ""))
		return result
	if bool(item.get("hauling", false)):
		# The delivered haul is ammo-pack carry, not the actual corpse mechanic.
		result.fallback = "corpse_haul_clip_missing"
		result.action = "walk" if bool(item.get("moving", false)) else "idle"
	elif bool(item.get("searching", false)):
		result.action = "pickup"
		result.seconds = maxf(float(item.get("search_t", 0.0)), 0.0) + float(frame.get("pose_snapshot_delta_s", 0.0))
	elif int(item.get("stance", 0)) == 1:
		# No crouch-fire overlay was delivered. Never stand up to show a shot.
		result.action = "crouch_walk" if bool(item.get("moving", false)) else "crouch"
	elif bool(item.get("moving", false)):
		result.action = "run" if bool(item.get("sprinting", false)) else "walk"
	else:
		result.action = "aim" if bool(item.get("locked", false)) or bool(item.get("returning_fire", false)) else "idle"
	if group in ["ops", "enemies"] and int(item.get("stance", 0)) == 0 and not bool(item.get("searching", false)) and not bool(item.get("hauling", false)):
		var ev := _last_event(frame, group, int(item.id), "fire" if group == "ops" else "return_fire")
		if not ev.is_empty() and _elapsed(frame, ev) <= FIRE_SECONDS:
			result.action = "fire"
			result.seconds = _elapsed(frame, ev)
			result.event_id = str(ev.event_id)
	return result


static func _elapsed(frame: Dictionary, event: Dictionary) -> float:
	return maxf(float(int(frame.tick) - BattleLog.record_tick(event)) / 60.0, 0.0)


static func _last_event(frame: Dictionary, group: String, id: int, type: String) -> Dictionary:
	if group == "sentries" or int(frame.get("schema", 0)) != BattleLog.SCHEMA_VERSION or str(frame.get("attempt_id", "")).is_empty():
		return {}
	var best := {}
	for ev in frame.get("events", []):
		if int(ev.get("schema", 0)) != BattleLog.SCHEMA_VERSION or str(ev.get("attempt_id", "")) != str(frame.attempt_id) or int(ev.get("wave_id", -2)) != int(frame.wave_id):
			continue
		if str(ev.get("event_id", "")).is_empty() or str(ev.get("type", "")) != type or int(ev.get("actor_id", -1)) != id or BattleLog.record_tick(ev) > int(frame.tick):
			continue
		if best.is_empty() or BattleLog.record_tick(ev) > BattleLog.record_tick(best) or (BattleLog.record_tick(ev) == BattleLog.record_tick(best) and int(ev.get("seq", -1)) > int(best.get("seq", -1))):
			best = ev
	return best


static func choose_lod(height_pixels: float, previous: int = -1) -> int:
	if previous == 0 and height_pixels >= 70.0:
		return 0
	if previous == 2 and height_pixels <= 52.0:
		return 2
	return 0 if height_pixels > 90.0 else (2 if height_pixels < 42.0 else 1)
