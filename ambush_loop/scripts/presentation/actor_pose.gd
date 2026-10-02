extends RefCounted

## Pure frame-to-pose conversion. No live actor or wall clock is consulted.
const FORMAT := 3
const ASSET_REVISION := "29749157c5db064bfea626c3ed9d75d9a1791ece"
const R4_REVISION := "194d9c41aaddbf014f05c70c14d40c09e6d8131b"
const LEGACY_REVISION := "00b270863ba5a2cd5425abf2a31e78965c72ae45"
const FirearmPose := preload("res://scripts/presentation/firearm_pose.gd")
const UtilityPose := preload("res://scripts/presentation/utility_pose.gd")
const FIRE_SECONDS := 0.23333333333333334


static func supported(data: Dictionary) -> bool:
	var revision := str(data.get("actor_asset_revision", ""))
	var version := int(data.get("animation_schema", 0))
	var known: bool = (version == FORMAT and revision == ASSET_REVISION) or (version == 2 and revision == R4_REVISION) or (version == 1 and revision == LEGACY_REVISION)
	var numeric_clock: bool = data.get("pose_clock_s") is float or data.get("pose_clock_s") is int
	return known and numeric_clock and is_finite(float(data.pose_clock_s)) and float(data.pose_clock_s) >= 0.0


static func sample(item: Dictionary, frame: Dictionary, group: String) -> Dictionary:
	var result := _legacy_sample(item, frame, group)
	if int(frame.get("animation_schema", 0)) == 1:
		return result
	if group == "ops" and int(frame.get("animation_schema", 0)) == FORMAT and str(frame.get("actor_asset_revision", "")) == ASSET_REVISION:
		var raw_utility: Variant = item.get("utility_pose", {})
		var utility := UtilityPose.sample(raw_utility, item, frame, result) if raw_utility is Dictionary else {}
		if not utility.is_empty():
			return utility
	var profile := FirearmPose.profile(str(item.get("visual_weapon", "")))
	if not bool(item.get("alive", true)) or bool(item.get("searching", false)) or bool(item.get("hauling", false)):
		return result
	if profile.is_empty():
		if result.action in ["fire", "aim"]:
			result.action = "walk" if bool(item.get("moving", false)) else ("crouch" if int(item.get("stance", 0)) == 1 else "idle")
		result.fallback = "weapon_action_missing"
		return result
	var raw_state: Variant = item.get("firearm_pose", {})
	var state: Dictionary = raw_state if raw_state is Dictionary else {}
	var clock := float(frame.get("pose_clock_s", 0.0))
	if state.is_empty() or str(state.get("weapon", "")) != str(item.visual_weapon) or not is_finite(float(state.get("since", INF))) or float(state.since) < 0.0 or float(state.since) > clock or str(state.get("intent", "")) not in ["ready", "aim"]:
		result.action = "crouch" if int(item.get("stance", 0)) == 1 else "idle"
		result.fallback = "firearm_record_missing_or_invalid"
		return result
	# The base owns hips and legs; authored firearm clips cover only 12 upper bones.
	result["base_action"] = "crouch_walk" if bool(item.get("moving", false)) and int(item.get("stance", 0)) == 1 else ("crouch" if int(item.get("stance", 0)) == 1 else ("run" if bool(item.get("sprinting", false)) and bool(item.get("moving", false)) else ("walk" if bool(item.get("moving", false)) else "idle")))
	result["base_seconds"] = maxf(clock, 0.0)
	result["upper_action"] = str(profile.clips[state.intent])
	result["upper_seconds"] = maxf(clock, 0.0)
	result.action = "aim" if state.intent == "aim" and result.base_action == "idle" else result.base_action
	result.seconds = maxf(clock, 0.0)
	result.event_id = ""
	var age := maxf(clock - float(state.since), 0.0)
	if age < 0.3 and ((str(state.get("from_intent", "")) == "ready" and state.intent == "aim") or (str(state.get("from_intent", "")) == "aim" and state.intent == "ready")):
		result.upper_action = str(profile.clips.raise if state.intent == "aim" else profile.clips.lower)
		result.upper_seconds = age
	# Existing command phases have no ticking battle clock. They cancel past fire
	# immediately, including the terminal shot when entering SWEEP.
	if int(frame.get("recorded_phase", -1)) != 1 or (group == "ops" and not bool(item.get("fire_permitted", false))):
		return result
	var shot := _last_event(frame, group, int(item.id), "fire" if group == "ops" else "return_fire")
	var repack := _last_event(frame, group, int(item.id), "repack") if group == "ops" else {}
	if not repack.is_empty() and _matching_weapon(repack, item) and str(repack.payload.get("repack_kind", "")) == "same_weapon" and str(repack.payload.get("source_visual_weapon", "")) == str(item.visual_weapon):
		var duration := float(repack.payload.get("reload_s", 0.0))
		var delay := 0.0
		if not shot.is_empty() and _matching_weapon(shot, item) and BattleLog.record_tick(shot) == BattleLog.record_tick(repack):
			delay = minf(FIRE_SECONDS, maxf(float(shot.payload.get("shot_interval_s", 0.0)), 0.0))
		if is_finite(duration) and duration > delay and duration < 60.0 and _elapsed(frame, repack) >= delay and _elapsed(frame, repack) < duration and (shot.is_empty() or int(repack.seq) > int(shot.seq)):
			result.upper_action = str(profile.clips.reload_contact)
			result.upper_seconds = (_elapsed(frame, repack) - delay) / (duration - delay)
			result.action = "reload_contact"
			result.event_id = str(repack.event_id)
			result.seconds = _elapsed(frame, repack)
			return result
	if not shot.is_empty() and _matching_weapon(shot, item):
		var interval := float(shot.payload.get("shot_interval_s", 0.0))
		var pulse := minf(interval, FIRE_SECONDS)
		if is_finite(interval) and pulse > 0.0 and _elapsed(frame, shot) < pulse:
			result.upper_action = str(profile.clips.fire)
			result.upper_seconds = _elapsed(frame, shot) * FIRE_SECONDS / pulse
			result.action = "fire"
			result.event_id = str(shot.event_id)
			result.seconds = _elapsed(frame, shot)
	return result


static func _matching_weapon(event: Dictionary, item: Dictionary) -> bool:
	var payload: Variant = event.get("payload", {})
	# Firearm event payload 2 keeps its unchanged R4 semantics in R5 frames.
	return payload is Dictionary and int(payload.get("animation_schema", 0)) == 2 and str(payload.get("visual_weapon", "")) == str(item.visual_weapon)


static func _legacy_sample(item: Dictionary, frame: Dictionary, group: String) -> Dictionary:
	var clock := float(frame.get("pose_clock_s", 0.0))
	var result := {"action": "idle", "seconds": maxf(clock, 0.0), "event_id": "", "fallback": ""}
	if not bool(item.get("alive", true)):
		var ev := _last_event(frame, group, int(item.id), "op_down" if group == "ops" else "kill")
		result.action = "death"
		# Old command records have no trustworthy bridge from frozen battle time.
		# Complete their non-looping fall rather than freezing a standing corpse.
		var command_without_clock: bool = int(frame.get("recorded_phase", -1)) != 1 and not _has_event_clock(frame)
		result.seconds = _elapsed(frame, ev) if not ev.is_empty() and not command_without_clock else 1.2
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
	if int(frame.get("recorded_phase", -1)) == 1 and group in ["ops", "enemies"] and int(item.get("stance", 0)) == 0 and not bool(item.get("searching", false)) and not bool(item.get("hauling", false)):
		var ev := _last_event(frame, group, int(item.id), "fire" if group == "ops" else "return_fire")
		if not ev.is_empty() and _elapsed(frame, ev) <= FIRE_SECONDS:
			result.action = "fire"
			result.seconds = _elapsed(frame, ev)
			result.event_id = str(ev.event_id)
	return result


static func _elapsed(frame: Dictionary, event: Dictionary) -> float:
	if _has_event_clock(frame):
		return maxf(float(frame.event_pose_clock_s) - float(BattleLog.record_tick(event)) / 60.0, 0.0)
	return maxf(float(int(frame.tick) - BattleLog.record_tick(event)) / 60.0, 0.0)


static func _has_event_clock(frame: Dictionary) -> bool:
	var clock: Variant = frame.get("event_pose_clock_s")
	return int(frame.get("event_pose_schema", 0)) == 1 and (clock is float or clock is int) and is_finite(float(clock)) and float(clock) >= 0.0


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
