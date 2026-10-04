extends RefCounted

## Confirmed original tool attacks only. These values never drive combat.
## Runtime links are weak; only copied plain values enter VisualSnapshot.
const SCHEMA := 1
const MAX_TOOLS := 64
const MAX_RECENT := 48
const RECENT_TICKS := 180
var _log: BattleLog
var _level_id := ""
var _attempt_id := ""
var _tool_seq := 0
var _effect_seq := 0
var _tools := {}
var _recent: Array = []


func reset() -> void:
	_log = null
	_level_id = ""
	_attempt_id = ""
	_tool_seq = 0
	_effect_seq = 0
	_tools.clear()
	_recent.clear()


func _scope(host: Node) -> bool:
	if not is_instance_valid(host) or host.level == null or host.battle_log == null:
		return false
	var log: BattleLog = host.battle_log
	var level_id: String = str(host.level.level_id)
	if _log != log or _level_id != level_id or _attempt_id != log.attempt_id:
		reset()
		_log = log
		_level_id = level_id
		_attempt_id = log.attempt_id
	return not _attempt_id.is_empty() and _log.playback_schema == 2


func _prune_links() -> void:
	for key in _tools.keys():
		if not is_instance_valid(_tools[key].link.get_ref()):
			_tools.erase(key)


func register(host: Node, tool: Node2D, owner: OperatorUnit, kind: String) -> void:
	if not _scope(host) or host.phase not in [host.Phase.SETUP, host.Phase.WATCHING, host.Phase.SWEEP]:
		return
	if not is_instance_valid(tool) or not is_instance_valid(owner) or not host.operators.has(owner):
		return
	if (kind == "grenade" and not tool is RaidGrenade) or (kind == "mine" and not tool is RaidMine) or kind not in ["grenade", "mine"]:
		return
	if typeof(owner.op_id) != TYPE_INT or not tool.global_position.is_finite():
		return
	_prune_links()
	var key := tool.get_instance_id()
	if _tools.has(key) or _tools.size() >= MAX_TOOLS:
		return
	var variant: String = str(tool.variant) if kind == "grenade" else "mine"
	var born := {"tool_id": "%s:tool:%d" % [_attempt_id, _tool_seq], "kind": kind,
		"variant": variant, "owner_group": "ops", "owner_id": owner.op_id,
		"created_wave_id": _log.wave_id, "created_clock_tick": _log.current_playback_tick(),
		"created_pos": tool.global_position}
	_tools[key] = {"link": weakref(tool), "born": born, "pending": {}}
	_tool_seq += 1


func _begin(host: Node, tool: Node2D, kind: String, pos: Vector2, radius: float) -> Dictionary:
	if not _scope(host) or host.phase not in [host.Phase.SETUP, host.Phase.WATCHING, host.Phase.SWEEP]:
		return {}
	if not is_instance_valid(tool) or not pos.is_finite() or not is_finite(radius) or radius <= 0.0:
		return {}
	var key := tool.get_instance_id()
	var entry: Dictionary = _tools.get(key, {})
	if entry.is_empty() or entry.link.get_ref() != tool or entry.born.kind != kind or pos != tool.global_position:
		return {}
	var source: Dictionary = entry.born.duplicate(true)
	source.merge({"schema": SCHEMA, "level_id": _level_id, "attempt_id": _attempt_id,
		"wave_id": _log.wave_id, "local_tick": int(host.sim.tick), "phase": int(host.phase),
		"clock_domain": "playback", "playback_schema": _log.playback_schema,
		"clock_tick": _log.current_playback_tick(), "position": pos, "radius": radius})
	entry.pending = source.duplicate(true)
	return source


func begin_grenade(host: Node, tool: RaidGrenade, pos: Vector2, radius: float) -> Dictionary:
	if not is_instance_valid(tool) or not tool.spent() or radius != tool.radius:
		return {}
	return _begin(host, tool, "grenade", pos, radius)


func begin_mine(host: Node, tool: Node2D) -> Dictionary:
	if not tool is RaidMine or tool.spent or not tool.armed:
		return {}
	return _begin(host, tool, "mine", tool.global_position, RaidMine.RADIUS)


static func victim(node: Node2D, group: String, hp_before: float) -> Dictionary:
	if not is_instance_valid(node) or group not in ["ops", "enemies"]:
		return {}
	var id: Variant = node.get("op_id" if group == "ops" else "label_id")
	var hp_after := float(node.hp)
	if typeof(id) != TYPE_INT or not node.global_position.is_finite() or not is_finite(hp_before) or not is_finite(hp_after):
		return {}
	var delta := hp_before - hp_after
	if not is_finite(delta):
		return {}
	return {"group": group, "id": id, "pos": node.global_position,
		"hp_before": hp_before, "hp_after": hp_after, "damage": maxf(delta, 0.0)}


func _mine_event(source: Dictionary, victims: Array, event: Dictionary) -> Dictionary:
	if victims.size() != 1 or victims.front().is_empty():
		return {}
	var seq: Variant = event.get("seq")
	if typeof(seq) != TYPE_INT or seq < 0 or seq >= _log.events.size() or _log.events[seq] != event:
		return {}
	if event.get("schema") != BattleLog.SCHEMA_VERSION or event.get("type") != "mine" or event.get("attempt_id") != _attempt_id or event.get("wave_id") != source.wave_id:
		return {}
	if event.get("event_id") != "%s:%d:%d" % [_attempt_id, source.wave_id, seq] or event.get("tick") != source.local_tick:
		return {}
	if event.get("playback_schema") != 2 or event.get("playback_tick") != _log.current_playback_tick():
		return {}
	if typeof(event.get("actor_id")) != TYPE_INT or event.actor_id != victims.front().id or victims.front().group != "enemies" or event.get("target_id") != -1 or event.get("position") != source.position:
		return {}
	return {"event_id": event.event_id, "seq": seq, "actor_id": event.actor_id,
		"target_id": event.target_id, "position": event.position, "type": event.type,
		"attempt_id": event.attempt_id, "wave_id": event.wave_id}


func finish(host: Node, tool: Node2D, source: Dictionary, victims: Array, event: Dictionary = {}) -> void:
	if source.is_empty() or not _scope(host) or not is_instance_valid(tool):
		return
	var key := tool.get_instance_id()
	var entry: Dictionary = _tools.get(key, {})
	if entry.is_empty() or entry.link.get_ref() != tool or entry.pending != source:
		return
	if source.attempt_id != _attempt_id or source.level_id != _level_id or source.wave_id != _log.wave_id:
		return
	if (source.kind == "grenade" and not tool.spent()) or (source.kind == "mine" and not tool.spent):
		return
	for item: Dictionary in victims:
		if item.is_empty():
			return
	var original_event := {}
	if source.kind == "mine":
		original_event = _mine_event(source, victims, event)
		if original_event.is_empty():
			return
	var record: Dictionary = source.duplicate(true)
	# This sequence belongs to the presentation stream, never BattleLog.events.
	record.merge({"confirmed": true, "seq": _effect_seq,
		"effect_id": "%s:tool_fx:%d" % [_attempt_id, _effect_seq],
		"victims": victims.duplicate(true), "original_event": original_event})
	_recent.append(record)
	_effect_seq += 1
	_tools.erase(key)
	while _recent.size() > MAX_RECENT:
		_recent.pop_front()


func capture(host: Node) -> Array:
	if not _scope(host):
		return []
	_prune_links()
	var now := _log.current_playback_tick()
	var wave := _log.wave_id
	_recent = _recent.filter(func(record: Dictionary) -> bool:
		return record.wave_id == wave and record.clock_tick <= now and now - record.clock_tick <= RECENT_TICKS)
	return _recent.duplicate(true)
