extends RefCounted

## Optional copied R5 body state. Older records keep their original actor pose.
const REVISION := "29749157c5db064bfea626c3ed9d75d9a1791ece"
const MODELS := ["operator_rifle", "operator_mg", "operator_scout", "enemy_patrol", "enemy_flank", "enemy_sneak", "enemy_radio"]


static func supported(frame: Dictionary) -> bool:
	return int(frame.get("corpse_schema", 0)) == 1 and int(frame.get("animation_schema", 0)) == 3 and str(frame.get("actor_asset_revision", "")) == REVISION and not str(frame.get("utility_scope_id", "")).is_empty()


static func valid(body: Dictionary, frame: Dictionary) -> bool:
	var clock: Variant = body.get("transition_age_s")
	return supported(frame) and int(body.get("schema", 0)) == 1 and str(body.get("scope_id", "")) == str(frame.utility_scope_id) and str(body.get("id", "")).begins_with(str(frame.utility_scope_id) + ":body:") and str(body.get("asset_revision", "")) == REVISION and str(body.get("model", "")) in MODELS and body.get("pos") is Vector2 and body.pos.is_finite() and str(body.get("source_group", "")) in ["enemies", "sentries"] and str(body.get("mode", "")) in ["ground", "grab", "hold", "release"] and (clock is float or clock is int) and is_finite(float(clock)) and float(clock) >= 0.0


static func age(body: Dictionary, frame: Dictionary, key: String) -> float:
	return maxf(float(body.get(key, 0.0)) + float(frame.get("pose_snapshot_delta_s", 0.0)), 0.0)


static func transition_valid(body: Dictionary, frame: Dictionary) -> bool:
	var event: Dictionary = body.get("transition", {})
	return not event.is_empty() and int(event.get("seq", -1)) >= 0 and str(event.get("event_id", "")) == "%s:corpse:%d:%d" % [str(body.scope_id), int(event.get("wave_id", -1)), int(event.get("seq", -1))] and str(event.get("attempt_id", "")) == str(frame.get("attempt_id", "")) and int(event.get("wave_id", -1)) == int(frame.get("wave_id", -2)) and int(event.get("phase", -1)) == int(frame.get("recorded_phase", -2)) and int(event.phase) in [0, 5]


static func sample(item: Dictionary, frame: Dictionary) -> Dictionary:
	var raw: Variant = item.get("corpse_pose", {})
	if not raw is Dictionary:
		return {}
	var state: Dictionary = raw
	if not supported(frame) or int(state.get("schema", 0)) != 1 or str(state.get("scope_id", "")) != str(frame.utility_scope_id) or int(state.get("actor_id", -1)) != int(item.id) or not bool(item.alive) or bool(item.get("searching", false)) or int(state.get("phase", -1)) != int(frame.get("recorded_phase", -2)) or int(state.phase) not in [0, 5] or int(state.get("wave_id", -1)) != int(frame.get("wave_id", -2)) or str(state.get("attempt_id", "")) != str(frame.get("attempt_id", "")) or str(state.get("weapon", "")) != str(item.weapon):
		return {}
	var body := {}
	for candidate in frame.get("corpses", []):
		if str(candidate.get("id", "")) == str(state.get("body_id", "")) and valid(candidate, frame):
			body = candidate
			break
	if body.is_empty():
		return {}
	var mode := str(state.get("mode", ""))
	if mode in ["grab", "release"] and (not transition_valid(body, frame) or str(state.get("event_id", "")) != str(body.transition.event_id) or int(body.transition.get("actor_id", -1)) != int(item.id) or str(body.transition.get("weapon", "")) != str(item.weapon)):
		return {}
	var seconds := age(body, frame, "transition_age_s")
	if mode == "grab" and (seconds >= 1.0 or bool(item.moving)):
		mode = "hold"
	if mode == "release" and (seconds >= 0.7 or bool(item.moving)):
		return {}
	if mode != "release" and (int(body.carrier_id) != int(item.id) or not bool(body.pairing)):
		return {}
	var clip := "corpse_grab" if mode == "grab" else ("corpse_release" if mode == "release" else "corpse_drag")
	if mode == "hold":
		seconds = float(frame.pose_clock_s) if bool(item.moving) else 0.0
	var pose := {"action": clip, "seconds": seconds, "event_id": str(state.get("event_id", "")), "fallback": "", "visual_item": "", "corpse": true}
	if int(item.stance) == 1:
		pose.merge({"base_action": "crouch_walk" if bool(item.moving) else "crouch", "base_seconds": float(frame.pose_clock_s), "upper_action": clip, "upper_seconds": seconds, "preserve_upper_world_basis": false})
	return pose
