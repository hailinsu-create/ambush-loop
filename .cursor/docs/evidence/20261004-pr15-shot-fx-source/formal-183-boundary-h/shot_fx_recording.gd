extends RefCounted

## One synchronous original attack. No last-event search or deferred callbacks.
## Presentation metadata alone; the caller still owns all combat operations.
const ActorPose := preload("res://scripts/presentation/actor_pose.gd")
const FirearmPose := preload("res://scripts/presentation/firearm_pose.gd")
var _host: Node
var _log: BattleLog
var _shooter: Node
var _target: Node
var _event: Dictionary = {}
var _descriptor: Dictionary = {}
var _group := ""
var _level_id := ""
var _attempt_id := ""
var _wave_id := -1


func begin(host: Node, shooter: Node, target: Node, group: String, event: Dictionary = {}) -> void:
	clear()
	if host.phase != host.Phase.WATCHING or group not in ["ops", "enemies"]:
		return
	_host = host
	_log = host.battle_log
	_shooter = shooter
	_target = target
	_group = group
	_level_id = str(host.level.level_id)
	_attempt_id = _log.attempt_id
	_wave_id = _log.wave_id
	_event = event


func confirm(host: Node, shooter: Node, target: Node = null, event: Dictionary = {}) -> void:
	if host != _host or shooter != _shooter or not _descriptor.is_empty():
		return
	if target != null:
		if _target != null and target != _target:
			return
		_target = target
	if not event.is_empty():
		if not _event.is_empty() and event != _event:
			return
		_event = event
	if not _valid_source() or not is_instance_valid(_target):
		return
	if int(_event.get("playback_schema", 0)) not in [1, 2] or int(_event.get("playback_tick", -1)) < 0:
		return
	# This callback precedes damage and the operator's automatic pack/pistol.
	var data: Dictionary = host._snapshot_data()
	if not ActorPose.supported(data):
		return
	var item: Dictionary = {}
	for row: Dictionary in data.get(_group, []):
		if int(row.id) == int(_event.actor_id):
			item = row
			break
	if item.is_empty() or item.pos != _event.position:
		return
	var frame: Dictionary = data.duplicate(true)
	frame.merge({"recorded_phase": int(data.phase), "tick": BattleLog.record_tick(_event),
		"attempt_id": _attempt_id, "wave_id": _wave_id, "schema": BattleLog.SCHEMA_VERSION,
		"events": _log.events.duplicate(true)})
	var pose: Dictionary = ActorPose.sample(item, frame, _group)
	var target_group := "enemies" if _group == "ops" else "ops"
	var target_id: int = int(_target.label_id) if target_group == "enemies" else int(_target.op_id)
	if target_id != int(_event.target_id):
		return
	_descriptor = {"schema": 1, "confirmed": true, "level_id": _level_id,
		"attempt_id": _event.attempt_id, "wave_id": _event.wave_id, "seq": _event.seq,
		"event_id": _event.event_id, "clock_domain": "playback",
		"playback_schema": _event.playback_schema, "clock_tick": _event.playback_tick,
		"source_group": _group, "source_id": _event.actor_id, "source_pos": _event.position,
		"target_group": target_group, "target_id": target_id, "target_pos": _target.global_position,
		"source_facing": item.facing, "visual_model": item.visual_model,
		"visual_weapon": item.visual_weapon, "actor_asset_revision": data.actor_asset_revision,
		"animation_schema": data.animation_schema, "pose": pose.duplicate(true),
		"projectile": not FirearmPose.profile(str(item.visual_weapon)).is_empty(),
		"hp_before": float(_target.hp)}


func finish() -> void:
	if not _descriptor.is_empty() and _valid_source() and is_instance_valid(_target):
		var hp_after := float(_target.hp)
		var hp_before := float(_descriptor.hp_before)
		if is_finite(hp_before) and is_finite(hp_after):
			_descriptor["hp_after"] = hp_after
			_descriptor["damage"] = maxf(hp_before - hp_after, 0.0)
			_event.payload["fx"] = _descriptor.duplicate(true)
	clear()


func _valid_source() -> bool:
	if not is_instance_valid(_host) or _log == null or _host.battle_log != _log:
		return false
	if str(_host.level.level_id) != _level_id or _log.attempt_id != _attempt_id or _log.wave_id != _wave_id:
		return false
	var seq := int(_event.get("seq", -1))
	if seq < 0 or seq >= _log.events.size() or _log.events[seq] != _event:
		return false
	return int(_event.get("schema", 0)) == BattleLog.SCHEMA_VERSION and str(_event.get("attempt_id", "")) == _attempt_id and int(_event.get("wave_id", -1)) == _wave_id and str(_event.get("event_id", "")) == "%s:%d:%d" % [_attempt_id, _wave_id, seq] and str(_event.get("type", "")) == ("fire" if _group == "ops" else "return_fire")


func clear() -> void:
	_host = null
	_log = null
	_shooter = null
	_target = null
	_event = {}
	_descriptor = {}
	_group = ""
	_level_id = ""
	_attempt_id = ""
	_wave_id = -1
