extends RefCounted

## Neutral display values for partial records; no live actor or level fallback.
static func operator_at(frame: Dictionary, index: int) -> Dictionary:
	for op in frame.get("ops", []):
		if int(op.get("id", -1)) == index + 1:
			return op
	return {}


static func selected(frame: Dictionary) -> Dictionary:
	return operator_at(frame, int(frame.get("selected_id", -1)) - 1)


static func operator_name(op: Dictionary) -> String:
	return str(op.get("display_name", "队员%d" % int(op.get("id", 0))))


static func role_label(op: Dictionary) -> String:
	return str(op.get("role_label", "队员"))


static func weapon_label(op: Dictionary) -> String:
	return str(op.get("weapon_label", "装备未记录"))


static func inventory_line(op: Dictionary) -> String:
	return str(op.get("inventory_line", "弹药 %s · 背包未记录" % str(op.get("ammo", "—"))))
