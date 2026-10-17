extends RefCounted
class_name SimEventLog

## 20 Hz event log + stable SHA-256 over canonical JSON lines.


var schema_version: int = 1
var level_id: String = ""
var level_version: int = 1
var plan_id: String = ""
var tick_hz: int = SimConstants.TICK_HZ
var events: Array = []
var summary: Dictionary = {}


func reset(p_level_id: String, p_level_version: int, p_plan_id: String) -> void:
	level_id = p_level_id
	level_version = p_level_version
	plan_id = p_plan_id
	events.clear()
	summary.clear()


func emit(tick: int, type: String, fields: Dictionary = {}) -> void:
	var ev := {
		"tick": tick,
		"t_s": float(tick) / float(tick_hz),
		"type": type,
	}
	for k in fields.keys():
		ev[k] = fields[k]
	events.append(ev)


func set_summary(s: Dictionary) -> void:
	summary = s.duplicate(true)


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"level_id": level_id,
		"level_version": level_version,
		"plan_id": plan_id,
		"tick_hz": tick_hz,
		"seed": null,
		"events": events.duplicate(true),
		"summary": summary.duplicate(true),
	}


func canonical_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	for ev in events:
		lines.append(_canonical_json(ev))
	return lines


func hash_sha256() -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for line in canonical_lines():
		ctx.update(line.to_utf8_buffer())
		ctx.update(PackedByteArray([10])) # newline
	var dig := ctx.finish()
	return dig.hex_encode()


static func _canonical_json(v: Variant) -> String:
	return JSON.stringify(_sort_keys(v))


static func _sort_keys(v: Variant) -> Variant:
	if typeof(v) == TYPE_DICTIONARY:
		var d: Dictionary = v
		var keys := d.keys()
		keys.sort()
		var out := {}
		for k in keys:
			out[str(k)] = _sort_keys(d[k])
		return out
	if typeof(v) == TYPE_ARRAY:
		var arr: Array = []
		for item in v:
			arr.append(_sort_keys(item))
		return arr
	return v
