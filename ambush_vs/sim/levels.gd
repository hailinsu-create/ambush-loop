extends RefCounted
class_name SimLevels

## T8: explicit level registry (directory scans are unreliable inside exported PCK).
## New levels default to res://data/golden/hashes_<id>.json; yard keeps hashes.json.

const DEFAULT_ID := "yard"


static func registry() -> Dictionary:
	return {
		"yard": {
			"path": "res://data/levels/yard.json",
			"golden": "res://data/golden/hashes.json",
			"fixtures": {
				"plan_a": "res://data/fixtures/plan_a.json",
				"plan_b": "res://data/fixtures/plan_b.json",
			},
		},
		"warehouse": {
			"path": "res://data/levels/warehouse.json",
			"golden": "res://data/golden/hashes_warehouse.json",
			"fixtures": {
				"plan_a": "res://data/fixtures/plan_warehouse_a.json",
				"plan_b": "res://data/fixtures/plan_warehouse_b.json",
			},
		},
	}


static func ids() -> Array:
	var out: Array = registry().keys()
	out.sort()
	return out


static func has(id: String) -> bool:
	return registry().has(id)


static func resolve_id(raw: String) -> String:
	var id := raw.strip_edges().to_lower()
	if id.is_empty() or not registry().has(id):
		return DEFAULT_ID
	return id


static func path_for(id: String) -> String:
	var entry: Dictionary = registry().get(resolve_id(id), {})
	return str(entry.get("path", ""))


static func golden_path_for(id: String) -> String:
	var entry: Dictionary = registry().get(resolve_id(id), {})
	return str(entry.get("golden", ""))


static func fixtures_for(id: String) -> Dictionary:
	var entry: Dictionary = registry().get(resolve_id(id), {})
	var fixtures: Dictionary = entry.get("fixtures", {})
	return fixtures.duplicate(true)


static func selected_id() -> String:
	return str(_selection().get("id", DEFAULT_ID))


static func selection_source() -> String:
	return str(_selection().get("source", "default"))


static func _selection() -> Dictionary:
	var env_raw := str(OS.get_environment("AMBUSH_LEVEL")).strip_edges()
	if not env_raw.is_empty():
		var env_id := resolve_id(env_raw)
		var env_source := "env" if env_id == env_raw.to_lower() else "env_unknown"
		return {"id": env_id, "source": env_source}
	if OS.has_feature("web"):
		var url_raw := str(JavaScriptBridge.eval(
			"new URLSearchParams(window.location.search).get('level') || ''", true
		)).strip_edges()
		if not url_raw.is_empty():
			var url_id := resolve_id(url_raw)
			var url_source := "url" if url_id == url_raw.to_lower() else "url_unknown"
			return {"id": url_id, "source": url_source}
	return {"id": DEFAULT_ID, "source": "default"}
