extends RefCounted

const VisualSnapshot := preload("res://scripts/replay/visual_snapshot.gd")
const ActorPose := preload("res://scripts/presentation/actor_pose.gd")
const EnvironmentScene := preload("res://scripts/presentation/environment_scene.gd")
const GROUPS := ["ops", "enemies", "sentries", "stashes", "covers", "loot", "barrels", "tripwires", "mines", "grenades", "decoys", "environment_objects", "corpses"]

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
	var continuous: bool = historical and host.replay.continuous_playback
	var snapshot_delta := maxf(float(host.replay.scrub_tick - host.replay.playback_time(snap)) / 60.0, 0.0) if historical else 0.0
	var simulation_clock: bool = str(data.get("pose_clock_domain", "")) == "simulation"
	var advance_pose: bool = simulation_clock or (continuous and str(data.get("pose_clock_domain", "")) == "command")
	var domain_tick: int = BattleLog.record_tick(snap) + (int(round(snapshot_delta * 60.0)) if simulation_clock else 0)
	var raw_event_clock: Variant = data.get("event_pose_clock_s")
	var event_clock_valid: bool = int(data.get("event_pose_schema", 0)) == 1 and (raw_event_clock is int or raw_event_clock is float) and is_finite(float(raw_event_clock)) and float(raw_event_clock) >= 0.0
	var source: BattleLog = host.replay.log if historical else host.battle_log
	var fx_playback_schema: int = int(snap.get("playback_schema",0)) if continuous else (source.playback_schema if not historical and source != null else 0)
	var fx_supported: bool = fx_playback_schema == 2 and ActorPose.supported(data) and str(data.get("actor_asset_revision","")) == ActorPose.ASSET_REVISION and int(data.get("animation_schema",0)) == ActorPose.FORMAT
	var raw_tool_schema: Variant = data.get("tool_fx_schema")
	var raw_tools: Variant = data.get("tool_fx", [])
	var tool_supported: bool = typeof(raw_tool_schema) == TYPE_INT and raw_tool_schema == 1 and typeof(raw_tools) == TYPE_ARRAY and fx_playback_schema == 2 and not unsupported and (int(snap.get("schema", 1)) if historical else BattleLog.SCHEMA_VERSION) == BattleLog.SCHEMA_VERSION
	var raw_movement_schema: Variant = data.get("movement_fx_schema")
	var raw_movement_clock: Variant = data.get("pose_clock_s")
	var movement_supported: bool = typeof(raw_movement_schema) == TYPE_INT and raw_movement_schema == 1 and typeof(data.get("visual_schema")) == TYPE_INT and data.visual_schema == VisualSnapshot.FORMAT_VERSION and typeof(data.get("animation_schema")) == TYPE_INT and data.animation_schema == ActorPose.FORMAT and data.get("actor_asset_revision") == ActorPose.ASSET_REVISION and fx_playback_schema == 2 and not unsupported and typeof(raw_movement_clock) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(raw_movement_clock)) and float(raw_movement_clock) >= 0.0
	# Validate original movement envelope before the legacy/default casts below.
	movement_supported = movement_supported and typeof(data.get("phase")) == TYPE_INT and data.phase in [0,1,5] and typeof(data.get("wave_count")) == TYPE_INT and data.wave_count > 0 and typeof(data.get("level_id")) == TYPE_STRING and typeof(data.get("actor_asset_revision")) == TYPE_STRING and typeof(data.get("pose_clock_domain")) == TYPE_STRING
	if historical:
		movement_supported = movement_supported and typeof(snap.get("schema")) == TYPE_INT and snap.schema == BattleLog.SCHEMA_VERSION and typeof(snap.get("playback_schema")) == TYPE_INT and snap.playback_schema == 2 and typeof(snap.get("wave_id")) == TYPE_INT and snap.wave_id >= 0 and snap.wave_id < data.wave_count and typeof(snap.get("attempt_id")) == TYPE_STRING and source != null and snap.attempt_id == source.attempt_id and typeof(snap.get("frame_seq")) == TYPE_INT and snap.frame_seq >= 0
	var frame := {
		"run_id": -1 if historical else host.run_id,
		"tick": (domain_tick if continuous else host.replay.scrub_tick) if historical else host.battle_log.timeline_tick(host.sim.tick),
		"playback_schema": int(snap.get("playback_schema", 0)) if continuous else 0,
		"playback_tick": host.replay.scrub_tick if historical else host.battle_log.current_playback_tick(),
		"frame_seq": int(snap.get("frame_seq", -1)) if historical else -1,
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
		"pose_clock_domain": str(data.get("pose_clock_domain", "")),
		"utility_scope_id": str(data.get("utility_scope_id", "")),
		"corpse_schema": int(data.get("corpse_schema", 0)),
		"corpse_contact_schema": int(data.get("corpse_contact_schema", 0)),
		"corpse_pairing_schema": int(data.get("corpse_pairing_schema", 0)),
		"animation_supported": ActorPose.supported(data),
		"environment_schema": int(data.get("environment_schema", 0)),
		"environment_cutaway_schema": int(data.get("environment_cutaway_schema", 0)),
		"environment_revision": str(data.get("environment_revision", "")),
		"environment_layout_revision": str(data.get("environment_layout_revision", "")),
		"environment_supported": EnvironmentScene.supported(data),
		"pose_snapshot_delta_s": snapshot_delta if advance_pose else 0.0,
		"pose_clock_s": float(data.get("pose_clock_s", 0.0)) + (snapshot_delta if advance_pose else 0.0),
		"event_pose_schema": 1 if event_clock_valid else 0,
		"event_pose_clock_s": float(raw_event_clock) + (snapshot_delta if advance_pose else 0.0) if event_clock_valid else 0.0,
		"level_id": str(data.get("level_id", "")), "blocked": data.get("blocked", PackedByteArray()).duplicate(),
		"selected_id": int(data.get("selected_id", -1)), "escape": data.get("escape", Vector2.ZERO),
		"door_locked": bool(data.get("door_locked", false)), "replay": historical,
		"has_door": bool(data.get("has_door", false)), "door_pos": data.get("door_pos", Vector2.ZERO),
		"events": host.replay.events_up_to(host.replay.scrub_tick).duplicate(true) if historical else host.battle_log.events.duplicate(true),
		"shot_fx_schema": 1 if fx_supported else 0,
		"shot_fx_playback_schema": fx_playback_schema,
		# A cache invalidation token only; never replaces saved factual identity.
		"shot_fx_source_token": source.get_instance_id() if source != null else 0,
		"tool_fx_schema": 1 if tool_supported else 0,
		"tool_fx_playback_schema": fx_playback_schema,
		"tool_fx_source_token": source.get_instance_id() if source != null else 0,
		"tool_fx_terminal_reason": source.terminal_reason if source != null and int(data.get("phase",-1)) in [2,3] else "",
		"tool_fx": raw_tools.duplicate(true) if tool_supported else [],
		"movement_fx_schema": 1 if movement_supported else 0,
		"movement_fx_playback_schema": fx_playback_schema,
		"movement_fx_source_token": source.get_instance_id() if source != null else 0,
		"movement_fx_clock_s": float(raw_movement_clock) + (snapshot_delta if advance_pose else 0.0) if movement_supported else 0.0,
		"movement_fx_clock_domain": data.get("pose_clock_domain") if movement_supported else "",
		"movement_fx_actors": _movement_actors(data) if movement_supported else [],
	}
	for group in GROUPS:
		frame[group] = data.get(group, []).duplicate(true)
		for item in frame[group]:
			item["active"] = bool(item.get("active", true))
			if group in ["ops", "enemies", "sentries"]:
				_actor_defaults(item)
	_freeze(frame)
	return frame


static func _movement_actors(data: Dictionary) -> Array:
	var result: Array = []
	for group: String in ["ops","enemies"]:
		var actors: Variant = data.get(group)
		if not actors is Array: return []
		for actor: Variant in actors:
			if not actor is Dictionary: continue
			var item := {"group":group}
			for key: String in ["id","pos","active","alive","moving","facing","action","stance","sprinting"]:
				if actor.has(key): item[key] = actor[key]
			result.append(item)
	return result


static func _actor_defaults(item: Dictionary) -> void:
	# Legacy recordings lack these values. Never borrow live equipment.
	item["facing"] = float(item.get("facing", 90.0))
	item["weapon"] = str(item.get("weapon", ""))
	item["role"] = int(item.get("role", 0))
	var raw_moving: Variant = item.get("moving",false)
	item["moving"] = raw_moving if typeof(raw_moving) == TYPE_BOOL else false
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
