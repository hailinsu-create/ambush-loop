class_name IntelStore
extends RefCounted

## Cross-loop memory: limited ghost paths with life index + cut-off time.

const MAX_RECORDS := 5
const ESCAPE_CONTEXT_SCHEMA := 1
const LEVEL_IDS := ["yard", "warehouse", "pump", "railcut", "depot", "radio"]
const ROUTES := ["main", "flank", "sneak", "echo", "alt"]

var records: Array = [] # {loop, path:PackedVector2Array, cut_sec:float, reason:String}


func clear() -> void:
	records.clear()


func add_path(
	loop_i: int,
	path: PackedVector2Array,
	cut_sec: float,
	reason: String,
	hint: String = "",
	route: String = "",
	leak_tick: int = -1,
	leaker_id: int = -1,
	source_context: Dictionary = {}
) -> void:
	if path.size() < 2:
		return
	var summary := "第%d世 · %s · %.1fs" % [loop_i, BattleLog.reason_zh(reason), cut_sec]
	if hint != "":
		summary += " · " + hint
	var tick := leak_tick
	if tick < 0:
		tick = int(round(cut_sec * 60.0))
	var record := {
		"loop": loop_i,
		"path": path.duplicate(),
		"cut_sec": cut_sec,
		"reason": reason,
		"hint": hint,
		"route": route,
		"leak_tick": tick,
		"leaker_id": leaker_id,
		"summary": summary,
	}
	if not source_context.is_empty():
		record["escape_context"] = source_context.duplicate(true)
	records.append(record)
	while records.size() > MAX_RECORDS:
		records.pop_front()


func recent(n: int = 3) -> Array:
	if records.is_empty():
		return []
	var start := maxi(records.size() - n, 0)
	return records.slice(start, records.size())


func latest_line() -> String:
	if records.is_empty():
		return ""
	return str(records[records.size() - 1].get("summary", ""))


func latest_hint() -> String:
	if records.is_empty():
		return ""
	return str(records[records.size() - 1].get("hint", ""))


func latest_route() -> String:
	if records.is_empty():
		return ""
	return str(records[records.size() - 1].get("route", ""))


func latest_leak_tick() -> int:
	if records.is_empty():
		return -1
	return int(records[records.size() - 1].get("leak_tick", -1))


func latest_leaker_id() -> int:
	if records.is_empty():
		return -1
	return int(records[records.size() - 1].get("leaker_id", -1))


func wall_text(n: int = 4) -> String:
	## Fail-panel dossier of recent loops. Presentation only.
	if records.is_empty():
		return ""
	var lines: PackedStringArray = PackedStringArray()
	lines.append("—— 情报墙 ——")
	for rec in recent(n):
		var summary := str(rec.get("summary", "")).strip_edges()
		if summary == "":
			continue
		lines.append(summary)
	if lines.size() <= 1:
		return ""
	return "\n".join(lines)


func leak_advice_line(level, route_zh: String) -> String:
	## Historical facts from saved events. Never predict a deadline from today's level.
	if records.is_empty():
		return ""
	var rec: Dictionary = records[records.size() - 1]
	if str(rec.get("reason", "")) != "escape":
		return ""
	var route := str(rec.get("route", ""))
	var lid := int(rec.get("leaker_id", -1))
	var wing := route_zh if route in ROUTES and route_zh != "" else "路线"
	var actor := "敌%d" % lid if lid >= 1 else ""
	var context := validated_escape_context(rec, str(level.level_id) if level != null else "")
	if context.is_empty():
		return "旧情报 · %s%s · 波次/入场未确认" % [wing, actor]
	return "历史第%d波 · %s敌%d · %.1f→%.1fs（出发→逃逸）；检查%s射界" % [int(context.wave_id) + 1, wing, lid, float(context.spawn.tick) / 60.0, float(context.escape.tick) / 60.0, wing]


func make_escape_context(level_id: String, spawn: Dictionary, escape: Dictionary) -> Dictionary:
	var payload: Variant = escape.get("payload", {})
	if not payload is Dictionary:
		return {}
	var context := {"schema": ESCAPE_CONTEXT_SCHEMA, "level_id": level_id,
		"attempt_id": escape.get("attempt_id", ""), "wave_id": escape.get("wave_id", -1),
		"actor_id": escape.get("actor_id", -1), "spawn": spawn.duplicate(true), "escape": escape.duplicate(true)}
	return validated_escape_context({"reason": "escape", "route": payload.get("route", ""),
		"leaker_id": escape.get("actor_id", -1), "leak_tick": escape.get("tick", -1), "escape_context": context}, level_id)


func validated_escape_context(record: Dictionary, level_id: String = "") -> Dictionary:
	var raw: Variant = record.get("escape_context", {})
	if not raw is Dictionary or str(record.get("reason", "")) != "escape":
		return {}
	var context: Dictionary = raw
	if typeof(context.get("schema")) != TYPE_INT or context.schema != ESCAPE_CONTEXT_SCHEMA:
		return {}
	if context.get("level_id", "") not in LEVEL_IDS or (level_id != "" and context.level_id != level_id):
		return {}
	if typeof(context.get("attempt_id")) != TYPE_STRING or str(context.attempt_id) == "":
		return {}
	if typeof(context.get("wave_id")) != TYPE_INT or context.wave_id < 0:
		return {}
	if context.wave_id >= LevelDef.by_id(str(context.level_id)).wave_count():
		return {}
	if typeof(context.get("actor_id")) != TYPE_INT or context.actor_id < 1 or context.actor_id != record.get("leaker_id", -1):
		return {}
	if not _context_event(context.get("spawn"), "spawn", context) or not _context_event(context.get("escape"), "escape", context):
		return {}
	var spawn: Dictionary = context.spawn
	var escape: Dictionary = context.escape
	if escape.payload.route != record.get("route", "") or escape.tick != record.get("leak_tick", -1):
		return {}
	if escape.seq <= spawn.seq or escape.tick < spawn.tick or escape.timeline_tick < spawn.timeline_tick or escape.playback_tick < spawn.playback_tick:
		return {}
	if escape.timeline_tick - escape.tick != spawn.timeline_tick - spawn.tick:
		return {}
	# Explicit continuous playback2 may include additional phase boundaries.
	# It cannot consume less time than the same-wave simulation interval.
	if escape.playback_tick - spawn.playback_tick < escape.tick - spawn.tick:
		return {}
	return context.duplicate(true)


func _context_event(raw: Variant, kind: String, context: Dictionary) -> bool:
	if not raw is Dictionary:
		return false
	var event: Dictionary = raw
	if typeof(event.get("schema")) != TYPE_INT or event.schema != BattleLog.SCHEMA_VERSION or event.get("type", "") != kind or event.get("attempt_id", "") != context.attempt_id:
		return false
	if typeof(event.get("playback_schema")) != TYPE_INT or event.playback_schema != 2:
		return false
	if event.get("wave_id", -1) != context.wave_id or event.get("actor_id", -1) != context.actor_id:
		return false
	for key in ["seq", "tick", "timeline_tick", "playback_tick"]:
		if typeof(event.get(key)) != TYPE_INT or int(event[key]) < 0:
			return false
	if event.timeline_tick < event.tick or event.get("event_id", "") != "%s:%d:%d" % [context.attempt_id, context.wave_id, event.seq]:
		return false
	var payload: Variant = event.get("payload", {})
	return payload is Dictionary and payload.get("route", "") in ROUTES
