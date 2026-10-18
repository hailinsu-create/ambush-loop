extends RefCounted

## P0-4: playtest build switch. Default OFF keeps the public build unchanged.
## Enable with AMBUSH_PLAYTEST=1, ?playtest=1 on the web build, or the "playtest" export feature.


static func source() -> String:
	## "env" | "url" | "feature" | "off"
	var env_flag: Variant = _flag("AMBUSH_PLAYTEST")
	if env_flag == true:
		return "env"
	if env_flag == false:
		return "off"
	if OS.has_feature("web"):
		var q := str(JavaScriptBridge.eval(
			"new URLSearchParams(window.location.search).get('playtest') || ''", true
		)).strip_edges().to_lower()
		if q in ["1", "true"]:
			return "url"
		if q in ["0", "false"]:
			return "off"
	if OS.has_feature("playtest"):
		return "feature"
	return "off"


static func is_enabled() -> bool:
	return source() != "off"


static func _flag(var_name: String) -> Variant:
	var v := str(OS.get_environment(var_name)).strip_edges().to_lower()
	if v in ["1", "true"]:
		return true
	if v in ["0", "false"]:
		return false
	return null
