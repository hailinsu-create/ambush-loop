extends RefCounted

const VisualSnapshot := preload("res://scripts/replay/visual_snapshot.gd")
const ActorPose := preload("res://scripts/presentation/actor_pose.gd")
const EnvironmentScene := preload("res://scripts/presentation/environment_scene.gd")
const GROUPS := ["ops", "enemies", "sentries", "stashes", "covers", "loot", "barrels", "tripwires", "mines", "grenades", "decoys", "environment_objects"]

## Historical frames use only the selected record, including its world layout,
## equipment and object state. No nodes or live containers cross the seam.
static func capture(host: Node) -> Dictionary:
	var historical: bool = host.phase == host.Phase.REPLAY
	var snap: Dictionary = host.replay.snapshot_at_or_before(host.replay.scrub_tick) if historical else {}
	var data: Dictionary = snap.get("data", {}) if historical else host._snapshot_data()
	var visual_schema := int(data.get("visual_schema", 0))
	var unsupported := visual_schema > VisualSnapshot.FORMAT_VERSION or visual_schema < 0
	if unsupported:
		data = {}
	var snapshot_delta := maxf(float(host.replay.scrub_tick - BattleLog.record_tick(snap)) / 60.0, 0.0) if historical else 0.0
	var simulation_clock: bool = str(data.get("pose_clock_domain", "")) == "simulation"
	var raw_event_clock: Variant = data.get("event_pose_clock_s")
	var event_clock_valid: bool = int(data.get("event_pose_schema", 0)) == 1 and (raw_event_clock is int or raw_event_clock is float) and is_finite(float(raw_event_clock)) and float(raw_event_clock) >= 0.0
	var frame := {
		"run_id": -1 if historical else host.run_id,
		"tick": host.replay.scrub_tick if historical else host.battle_log.timeline_tick(host.sim.tick),
		"phase": int(host.phase), "recorded_phase": int(data.get("phase", -1)),
		"schema": int(snap.get("schema", 1)) if historical else BattleLog.SCHEMA_VERSION,
		"attempt_id": str(snap.get("attempt_id", "")) if historical else host.battle_log.attempt_id,
		"wave_id": int(snap.get("wave_id", -1)) if historical else host.battle_log.wave_id,
		"local_tick": int(snap.get("tick", 0)) if historical else host.sim.tick,
		"visual_schema": visual_schema, "historical_defaults": historical and visual_schema == 0,
		"hud_schema": int(data.get("hud_schema", 0)), "level_title": str(data.get("level_title", "历史关卡")),
		"attempt_number": int(data.get("attempt_number", -1)), "wave_count": int(data.get("wave_count", -1)),
		"visual_unsupported": unsupported,
		"animation_schema": int(data.get("animation_schema", 0)),
		"actor_asset_revision": str(data.get("actor_asset_revision", "")),
		"animation_supported": ActorPose.supported(data),
		"environment_schema": int(data.get("environment_schema", 0)),
		"environment_revision": str(data.get("environment_revision", "")),
		"environment_layout_revision": str(data.get("environment_layout_revision", "")),
		"environment_supported": EnvironmentScene.supported(data),
		"pose_snapshot_delta_s": snapshot_delta if simulation_clock else 0.0,
		"pose_clock_s": float(data.get("pose_clock_s", 0.0)) + (snapshot_delta if simulation_clock else 0.0),
		"event_pose_schema": 1 if event_clock_valid else 0,
		"event_pose_clock_s": float(raw_event_clock) + (snapshot_delta if simulation_clock else 0.0) if event_clock_valid else 0.0,
		"level_id": str(data.get("level_id", "")), "blocked": data.get("blocked", PackedByteArray()).duplicate(),
		"selected_id": int(data.get("selected_id", -1)), "escape": data.get("escape", Vector2.ZERO),
		"door_locked": bool(data.get("door_locked", false)), "replay": historical,
		"has_door": bool(data.get("has_door", false)), "door_pos": data.get("door_pos", Vector2.ZERO),
		"events": host.replay.events_up_to(host.replay.scrub_tick).duplicate(true) if historical else host.battle_log.events.duplicate(true),
	}
	for group in GROUPS:
		frame[group] = data.get(group, []).duplicate(true)
		for item in frame[group]:
			item["active"] = bool(item.get("active", true))
			if group in ["ops", "enemies", "sentries"]:
				_actor_defaults(item)
	_freeze(frame)
	return frame


static func _actor_defaults(item: Dictionary) -> void:
	# Legacy recordings lack these values. Never borrow live equipment.
	item["facing"] = float(item.get("facing", 90.0))
	item["weapon"] = str(item.get("weapon", ""))
	item["role"] = int(item.get("role", 0))
	item["moving"] = bool(item.get("moving", false))
	item["stance"] = int(item.get("stance", 0))
	item["action"] = str(item.get("action", "idle" if bool(item.get("alive", true)) else "death"))
	item["visual_model"] = str(item.get("visual_model", ""))
	item["visual_weapon"] = str(item.get("visual_weapon", ""))
	item["cone"] = item.get("cone", PackedVector2Array()).duplicate()


static func _freeze(value: Variant) -> void:
	if value is Dictionary:
		for child in value.values():
			_freeze(child)
		value.make_read_only()
	elif value is Array:
		for child in value:
			_freeze(child)
		value.make_read_only()
