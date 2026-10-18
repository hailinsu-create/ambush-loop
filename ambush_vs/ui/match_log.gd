extends RefCounted

## P0-4: per-match JSON log builder/exporter (pure; no scene access).

const SimConstants := preload("res://sim/constants.gd")

const BEAT_KEYS := ["scout", "setup", "wait", "fire"]
const SCHEMA := "ambush_match_log/1"


static func required_keys() -> PackedStringArray:
	return PackedStringArray([
		"schema",
		"game_version",
		"level_id",
		"playtest",
		"playtest_source",
		"platform",
		"started_at",
		"ended_at",
		"started_unix",
		"ended_unix",
		"duration_s",
		"beats_ms",
		"plan",
		"detonate_tick",
		"detonate_t_s",
		"trigger",
		"fires",
		"fire_count",
		"outcome",
		"reason",
		"standard_ambush",
		"kills",
		"escapes",
		"wounded",
		"dead_ops",
		"alert",
		"sim_ticks",
		"sim_time_s",
		"log_hash",
	])


static func build(
	summary: Dictionary,
	events: Array,
	level_id: String,
	plan_src: Dictionary,
	playtest: bool,
	playtest_source: String,
	started_at: String,
	started_unix: float,
	beats_ms: Dictionary,
	sim_ticks: int
) -> Dictionary:
	var ended_unix := Time.get_unix_time_from_system()
	var beats: Dictionary = {}
	for k in BEAT_KEYS:
		beats[k] = int(beats_ms.get(k, 0))
	var dtick := int(summary.get("detonate_tick", -1))
	var det_t_s := float(dtick) * SimConstants.DT_S if dtick >= 0 else -1.0
	var fires := _collect_fires(events)
	return {
		"schema": SCHEMA,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "")),
		"level_id": level_id,
		"playtest": playtest,
		"playtest_source": playtest_source,
		"platform": OS.get_name(),
		"started_at": started_at,
		"ended_at": Time.get_datetime_string_from_system(),
		"started_unix": float(started_unix),
		"ended_unix": float(ended_unix),
		"duration_s": float(ended_unix) - float(started_unix),
		"beats_ms": beats,
		"plan": _map_plan(plan_src),
		"detonate_tick": dtick,
		"detonate_t_s": det_t_s,
		"trigger": str(summary.get("trigger", "")),
		"fires": fires,
		"fire_count": fires.size(),
		"outcome": str(summary.get("outcome", "")),
		"reason": str(summary.get("reason", "")),
		"standard_ambush": bool(summary.get("standard_ambush", false)),
		"kills": _array_copy(summary.get("kills", [])),
		"escapes": _array_copy(summary.get("escapes", [])),
		"wounded": _array_copy(summary.get("wounded", [])),
		"dead_ops": _array_copy(summary.get("dead_ops", [])),
		"alert": str(summary.get("alert", "")),
		"sim_ticks": int(sim_ticks),
		"sim_time_s": float(sim_ticks) * SimConstants.DT_S,
		"log_hash": str(summary.get("log_hash", "")),
	}


static func save(d: Dictionary) -> String:
	if d.is_empty():
		return ""
	var dir := "user://match_logs"
	var mk := DirAccess.make_dir_recursive_absolute(dir)
	if mk != OK and not DirAccess.dir_exists_absolute(dir):
		return ""
	var stamp := Time.get_datetime_string_from_system()
	stamp = stamp.replace("-", "").replace(":", "").replace("T", "_")
	var base := "match_%s" % stamp
	var path := "%s/%s.json" % [dir, base]
	var n := 2
	while FileAccess.file_exists(path):
		path = "%s/%s_%d.json" % [dir, base, n]
		n += 1
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	return path


static func _collect_fires(events: Array) -> Array:
	var out: Array = []
	for ev in events:
		if typeof(ev) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = ev
		if str(e.get("type", "")) != "fire":
			continue
		out.append({
			"tick": int(e.get("tick", 0)),
			"t_s": float(e.get("t_s", 0.0)),
			"actor": str(e.get("actor", "")),
			"weapon_id": str(e.get("weapon_id", "")),
			"target": str(e.get("target", "")),
		})
	return out


static func _map_plan(src: Dictionary) -> Dictionary:
	var ops: Array = []
	for op in src.get("operators", []):
		if typeof(op) != TYPE_DICTIONARY:
			continue
		var o: Dictionary = op
		ops.append({
			"id": str(o.get("id", "")),
			"display_name": str(o.get("display_name", "")),
			"weapon_id": str(o.get("weapon_id", "")),
			"x": int(o.get("x", 0)),
			"y": int(o.get("y", 0)),
			"height": str(o.get("tier", o.get("height", "ground"))),
			"facing_deg": float(o.get("facing_deg", 0.0)),
		})
	var mines: Array = []
	for m in src.get("mines", []):
		if typeof(m) == TYPE_DICTIONARY:
			mines.append((m as Dictionary).duplicate(true))
	var grenades: Array = []
	for g in src.get("grenades", []):
		if typeof(g) == TYPE_DICTIONARY:
			grenades.append((g as Dictionary).duplicate(true))
	var trig: Dictionary = {}
	if typeof(src.get("trigger", {})) == TYPE_DICTIONARY:
		trig = (src.get("trigger", {}) as Dictionary).duplicate(true)
	return {"operators": ops, "mines": mines, "grenades": grenades, "trigger": trig}


static func _array_copy(v: Variant) -> Array:
	if typeof(v) == TYPE_ARRAY:
		return (v as Array).duplicate(true)
	return []
