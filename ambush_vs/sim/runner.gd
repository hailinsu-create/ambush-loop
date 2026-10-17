extends RefCounted
class_name SimRunner

## Load level + plan + weapons and run one night.


static func load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("cannot open %s" % path)
		return {}
	var v: Variant = JSON.parse_string(f.get_as_text())
	if typeof(v) != TYPE_DICTIONARY:
		return {}
	return v


static func run_plan(plan_path: String, level_path: String = "res://data/levels/yard.json") -> Dictionary:
	var level := SimLevelLoader.load_path(level_path)
	if level.is_empty():
		return {"error": "level"}
	var plan := load_json(plan_path)
	if plan.is_empty():
		return {"error": "plan"}
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	var summary: Dictionary = sim.run()
	summary["events"] = sim.log.events
	summary["event_log"] = sim.log.to_dict()
	summary["sim"] = sim
	return summary


static func run_plan_dict(plan: Dictionary, level_path: String = "res://data/levels/yard.json", tweaks: Dictionary = {}) -> Dictionary:
	var level := SimLevelLoader.load_path(level_path)
	if level.is_empty():
		return {"error": "level"}
	var weapons := SimWeapons.load_csv()
	var sim := NightSim.new()
	sim.setup(level, plan, weapons)
	for k in tweaks.keys():
		sim.set(k, tweaks[k])
	var summary: Dictionary = sim.run()
	summary["events"] = sim.log.events
	summary["event_log"] = sim.log.to_dict()
	summary["sim"] = sim
	return summary
