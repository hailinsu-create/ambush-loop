extends RefCounted

## Utility actions sample copied successful gameplay events. They never delay
## damage, consume inventory, move a tool, or consult a live actor.
const SCHEMA := 1
const Space := preload("res://scripts/presentation/world_space.gd")
const CLIPS := {"knife_stab": {"duration": 0.8, "offset": 0.5, "item": "knife"},
	"grenade_throw": {"duration": 1.0, "offset": 0.5, "item": ""},
	"decoy_place": {"duration": 1.2, "offset": 0.5, "item": ""}}


static func valid(state: Dictionary, item: Dictionary, frame: Dictionary) -> bool:
	var raw_clock: Variant = state.get("since")
	var clock: float = float(frame.get("pose_clock_s", 0.0))
	return int(state.get("schema", 0)) == SCHEMA and CLIPS.has(str(state.get("action", ""))) \
		and not str(state.get("scope_id", "")).is_empty() and str(state.scope_id) == str(frame.get("utility_scope_id", "")) \
		and not str(state.get("event_id", "")).is_empty() and int(state.get("seq", -1)) >= 0 \
		and str(state.event_id) == "%s:%d:%d" % [state.scope_id, int(state.get("wave_id", -1)), int(state.seq)] \
		and int(state.get("actor_id", -1)) == int(item.get("id", -2)) \
		and str(state.get("attempt_id", "")) == str(frame.get("attempt_id", "")) \
		and int(state.get("wave_id", -1)) == int(frame.get("wave_id", -2)) \
		and int(state.get("phase", -1)) == int(frame.get("recorded_phase", -2)) \
		and int(state.phase) in [0, 1, 5] \
		and str(state.get("clock_domain", "")) == str(frame.get("pose_clock_domain", "")) \
		and str(state.clock_domain) == ("simulation" if int(state.phase) == 1 else "command") \
		and str(state.get("weapon", "")) == str(item.get("weapon", "")) \
		and state.get("target") is Vector2 and state.target.is_finite() \
		and bool(item.get("alive", false)) and not bool(item.get("searching", false)) and not bool(item.get("hauling", false)) \
		and (str(state.action) != "decoy_place" or not bool(item.get("moving", false))) \
		and (raw_clock is int or raw_clock is float) and is_finite(float(raw_clock)) \
		and float(raw_clock) >= 0.0 and float(raw_clock) <= clock \
		and clock - float(raw_clock) < float(CLIPS[state.action].duration) - float(CLIPS[state.action].offset)


static func sample(state: Dictionary, item: Dictionary, frame: Dictionary, _base: Dictionary) -> Dictionary:
	if not valid(state, item, frame):
		return {}
	# Between sparse snapshots a later real shot can interrupt the copied tool
	# pose. Use original BattleLog attempt/wave/seq, never the host run token.
	if str(state.clock_domain) == "simulation":
		for event in frame.get("events", []):
			var identity := "%s:%d:%d" % [str(state.attempt_id), int(state.wave_id), int(event.get("seq", -1))]
			if int(event.get("schema", 0)) == BattleLog.SCHEMA_VERSION and str(event.get("event_id", "")) == identity and int(event.get("seq", -1)) >= 0 and str(event.get("attempt_id", "")) == str(state.attempt_id) and int(event.get("wave_id", -1)) == int(state.wave_id) and int(event.get("actor_id", -1)) == int(item.id) and str(event.get("type", "")) == "fire" and int(event.get("seq", -1)) > int(state.get("battle_seq_floor", -1)) and BattleLog.record_tick(event) <= int(frame.get("tick", -1)):
				return {}
	var spec: Dictionary = CLIPS[state.action]
	var seconds := float(spec.offset) + float(frame.pose_clock_s) - float(state.since)
	var pose := {"action": str(state.action), "seconds": seconds, "event_id": str(state.event_id),
		"fallback": "", "visual_item": str(spec.item), "utility": true}
	var direction: Vector2 = state.target - item.get("pos", Vector2.ZERO)
	var facing: float = rad_to_deg(direction.angle()) if direction.length_squared() > 0.0001 else float(item.get("facing", 90.0))
	# Decoy's crouch is authored full-body only while stationary and standing.
	# Other actions, and an already crouched decoy, preserve all eight lower bones.
	if str(state.action) != "decoy_place" or int(item.get("stance", 0)) == 1:
		pose.merge({"base_action": "crouch_walk" if bool(item.get("moving", false)) and int(item.get("stance", 0)) == 1 else ("crouch" if int(item.get("stance", 0)) == 1 else ("run" if bool(item.get("sprinting", false)) and bool(item.get("moving", false)) else ("walk" if bool(item.get("moving", false)) else "idle"))),
			"base_seconds": float(frame.pose_clock_s), "upper_action": str(state.action), "upper_seconds": seconds,
			"preserve_upper_world_basis": false,
			"upper_yaw_rad": wrapf(Space.facing_yaw(facing) - Space.facing_yaw(float(item.get("facing", 90.0))), -PI, PI)})
	else:
		pose["visual_facing"] = facing
	return pose
