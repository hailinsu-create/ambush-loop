extends RefCounted

## Recorded values only. Coverage is geometry, never a promise of immediate fire.
static func line(frame: Dictionary) -> String:
	var selected: Dictionary = {}
	for op in frame.get("ops", []):
		if op.get("id", -2) == frame.get("selected_id", -1):
			selected = op
			break
	if selected.is_empty():
		return "射界：格中心视线 · 先选队员"
	var status := "就绪，仍需目标在射界内"
	if not selected.has_all(["alive", "fire_permitted", "ammo", "shot_cd", "melee"]):
		status = "开火状态未记录"
	elif not bool(selected.alive):
		status = "已阵亡"
	elif not bool(selected.fire_permitted):
		status = "禁止开火"
	elif not bool(selected.melee) and int(selected.ammo) <= 0:
		status = "缺弹"
	elif float(selected.shot_cd) > 0.0:
		status = "冷却 %.1fs" % float(selected.shot_cd)
	elif bool(selected.melee):
		status = "近战：不享高点穿透"
	var ammo := "刀" if bool(selected.get("melee", false)) else "弹%s" % str(selected.get("ammo", "—"))
	return "射界：格中心视线 · %s · %s" % [ammo, status]
