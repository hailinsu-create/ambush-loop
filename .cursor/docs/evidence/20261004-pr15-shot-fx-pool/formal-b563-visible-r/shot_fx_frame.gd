extends RefCounted

## Pure saved-event reader. No actor lookup, simulation or wall clock.
const FORMAT := 1
const LIFETIME_TICKS := 9
const ActorPose := preload("res://scripts/presentation/actor_pose.gd")
const FirearmPose := preload("res://scripts/presentation/firearm_pose.gd")
const Assets := preload("res://scripts/presentation/asset_library.gd")
const LEVELS := ["yard","warehouse","pump","railcut","depot","radio"]
const ACTIONS := ["idle","walk","run","crouch","crouch_walk","aim","fire","reload_contact"]
const BASE_ACTIONS := ["idle","walk","run","crouch","crouch_walk"]


static func active(frame: Dictionary) -> Array:
	var out := []
	var events: Variant = frame.get("events",[])
	if not events is Array:
		return out
	for raw: Variant in events:
		if raw is Dictionary:
			var shot := sample(frame,raw)
			if not shot.is_empty(): out.append(shot)
	return out


static func sample(frame: Dictionary, event: Dictionary) -> Dictionary:
	# RefCounted instance IDs can be negative. The token is opaque, not a fact.
	if not _equal_int(frame,"shot_fx_schema",FORMAT) or not _equal_int(frame,"shot_fx_playback_schema",2) or typeof(frame.get("shot_fx_source_token")) != TYPE_INT or frame.shot_fx_source_token == 0:
		return {}
	if not _equal_int(frame,"schema",BattleLog.SCHEMA_VERSION) or not _equal_int(frame,"recorded_phase",1) or not _equal_int(frame,"animation_schema",ActorPose.FORMAT):
		return {}
	if not _equal_bool(frame,"animation_supported",true) or not _equal_bool(frame,"visual_unsupported",false) or frame.get("actor_asset_revision") != ActorPose.ASSET_REVISION:
		return {}
	if not _nonnegative_int(frame,"playback_tick") or not _nonnegative_int(frame,"wave_id") or typeof(frame.get("attempt_id")) != TYPE_STRING or frame.attempt_id.is_empty() or frame.get("level_id") not in LEVELS:
		return {}
	if not _positive_int(frame,"wave_count") or frame.wave_id >= frame.wave_count:
		return {}
	if not _equal_int(event,"schema",BattleLog.SCHEMA_VERSION) or not _equal_int(event,"playback_schema",2) or event.get("type") not in ["fire","return_fire"]:
		return {}
	if not _nonnegative_int(event,"seq") or not _nonnegative_int(event,"tick") or not _nonnegative_int(event,"timeline_tick") or not _nonnegative_int(event,"playback_tick") or not _positive_int(event,"actor_id") or not _positive_int(event,"target_id"):
		return {}
	if typeof(event.get("attempt_id")) != TYPE_STRING or typeof(event.get("event_id")) != TYPE_STRING or event.attempt_id != frame.attempt_id or not _equal_int(event,"wave_id",frame.wave_id) or event.event_id != "%s:%d:%d" % [frame.attempt_id,frame.wave_id,event.seq]:
		return {}
	var age: int = frame.playback_tick-event.playback_tick
	if age < 0 or age >= LIFETIME_TICKS:
		return {}
	var payload: Variant = event.get("payload")
	if not payload is Dictionary or not payload.get("fx") is Dictionary:
		return {}
	var fx: Dictionary = payload.fx
	if not _equal_int(fx,"schema",FORMAT) or not _equal_bool(fx,"confirmed",true) or not _equal_bool(fx,"projectile",true) or not _equal_int(fx,"playback_schema",2) or fx.get("clock_domain") != "playback" or not _equal_int(fx,"clock_tick",event.playback_tick):
		return {}
	for key in ["event_id","attempt_id"]:
		if typeof(fx.get(key)) != TYPE_STRING or fx.get(key) != event.get(key): return {}
	for key in ["wave_id","seq"]:
		if not _equal_int(fx,key,event[key]): return {}
	var source_group := "ops" if event.type == "fire" else "enemies"
	var target_group := "enemies" if source_group == "ops" else "ops"
	if fx.get("level_id") != frame.level_id or fx.get("source_group") != source_group or fx.get("target_group") != target_group or not _equal_int(fx,"source_id",event.actor_id) or not _equal_int(fx,"target_id",event.target_id):
		return {}
	if not fx.get("source_pos") is Vector2 or not fx.source_pos.is_finite() or fx.source_pos != event.get("position") or not fx.get("target_pos") is Vector2 or not fx.target_pos.is_finite() or not _number(fx.get("source_facing")):
		return {}
	if fx.get("actor_asset_revision") != ActorPose.ASSET_REVISION or not _equal_int(fx,"animation_schema",ActorPose.FORMAT) or typeof(fx.get("visual_model")) != TYPE_STRING or not Assets.has_asset(fx.visual_model,0,ActorPose.ASSET_REVISION) or Assets.asset_record(fx.visual_model).get("category") != "character":
		return {}
	if typeof(fx.get("visual_weapon")) != TYPE_STRING or fx.visual_weapon != payload.get("visual_weapon"):
		return {}
	var profile := FirearmPose.profile(fx.visual_weapon)
	if profile.is_empty() or not _valid_pose(fx.get("pose"),profile):
		return {}
	for key in ["hp_before","hp_after","damage"]:
		if not _number(fx.get(key)): return {}
	if float(fx.damage) < 0.0 or float(fx.hp_before) < 0.0 or float(fx.damage) != maxf(float(fx.hp_before)-float(fx.hp_after),0.0):
		return {}
	var result := fx.duplicate(true)
	result["age_ticks"] = age
	return result


static func _valid_pose(raw: Variant, profile: Dictionary) -> bool:
	if not raw is Dictionary:
		return false
	var pose: Dictionary = raw
	if pose.get("action") not in ACTIONS or not _number(pose.get("seconds")) or float(pose.seconds)<0.0:
		return false
	if pose.has("visual_facing") and not _number(pose.visual_facing):
		return false
	if pose.has("preserve_upper_world_basis") and typeof(pose.preserve_upper_world_basis) != TYPE_BOOL:
		return false
	if pose.has("upper_yaw_rad") and not _number(pose.upper_yaw_rad):
		return false
	if pose.has("upper_action"):
		if pose.get("base_action") not in BASE_ACTIONS or pose.upper_action not in profile.clips.values():
			return false
		for key in ["base_seconds","upper_seconds"]:
			if not _number(pose.get(key)) or float(pose[key])<0.0: return false
	return true


static func _number(raw: Variant) -> bool:
	return (raw is float or raw is int) and is_finite(float(raw))


static func _nonnegative_int(data: Dictionary, key: String) -> bool:
	return typeof(data.get(key)) == TYPE_INT and int(data[key]) >= 0


static func _positive_int(data: Dictionary, key: String) -> bool:
	return typeof(data.get(key)) == TYPE_INT and int(data[key]) > 0


static func _equal_int(data: Dictionary, key: String, value: int) -> bool:
	return typeof(data.get(key)) == TYPE_INT and data[key] == value


static func _equal_bool(data: Dictionary, key: String, value: bool) -> bool:
	return typeof(data.get(key)) == TYPE_BOOL and data[key] == value
