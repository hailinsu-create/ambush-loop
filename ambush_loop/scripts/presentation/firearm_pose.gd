extends RefCounted

## Immutable asset profiles; this layer never looks up an actor or ammunition.
const MANIFEST := "res://art/v2/firearm_profiles.json"
const UPPER_BONES := ["spine", "chest", "neck", "head", "clavicle.L", "clavicle.R", "upper_arm.L", "upper_arm.R", "forearm.L", "forearm.R", "hand.L", "hand.R"]
static var _profiles: Dictionary = {}
static var _loaded := false


static func profile(weapon_id: String) -> Dictionary:
	if not _loaded:
		_loaded = true
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
		if not doc is Dictionary or int(doc.get("schema", 0)) != 1 or doc.get("upper_body_mask", []) != UPPER_BONES:
			push_error("FIREARM_PROFILES_INVALID")
			return {}
		for row in doc.get("profiles", []):
			_profiles[str(row.weapon_id)] = row.duplicate(true)
	return _profiles.get(weapon_id, {}).duplicate(true)


static func intent(item: Dictionary, group: String) -> String:
	if not bool(item.get("alive", true)) or bool(item.get("searching", false)) or bool(item.get("hauling", false)):
		return "cancel"
	if group == "ops":
		return "aim" if bool(item.get("locked", false)) and bool(item.get("fire_permitted", false)) else "ready"
	return "aim" if bool(item.get("returning_fire", false)) else "ready"
