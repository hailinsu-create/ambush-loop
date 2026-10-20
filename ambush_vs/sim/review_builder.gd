extends RefCounted
class_name ReviewBuilder

## PLAY-5 / VS-W6a: build Chinese review card from NightSim summary + log.
## No ticks, internal ids, or English trigger names in player-facing strings.

const SimConstants := preload("res://sim/constants.gd")

## Ideal detonate window (yard defaults after PLAY-4 pacing).
const IDEAL_T0_A_TICK := 520
const IDEAL_T0_B_TICK := 560
const VOLLEY_WINDOW_TICKS := 10
const CLEAR_FAST_S := 0.55 ## PLAY-6: cover scramble makes sub-0.55 rare; S stays elite


static func build(sim, plan: Dictionary, op_display_names: Dictionary = {}) -> Dictionary:
	## Returns {outcome_zh, grade, causes[], timeline[], metrics{}, standard_ambush, full_wipe}.
	var summary: Dictionary = sim.outcome_summary() if sim.has_method("outcome_summary") else {}
	var events: Array = sim.log.events if sim.log != null else []
	var metrics := _compute_metrics(summary, events)
	var grade := _grade(summary, metrics)
	var outcome_zh := _outcome_zh(summary)
	var causes := _causes(summary, metrics, plan, op_display_names, events)
	var timeline := _timeline(summary, metrics, events, plan)
	return {
		"outcome_zh": outcome_zh,
		"grade": grade,
		"causes": causes,
		"timeline": timeline,
		"metrics": metrics,
		"standard_ambush": bool(summary.get("standard_ambush", false)),
		"full_wipe": _full_wipe(summary),
		"summary": summary,
	}


static func _full_wipe(summary: Dictionary) -> bool:
	return (
		str(summary.get("outcome", "")) == "win"
		and (summary.get("escapes", []) as Array).is_empty()
		and not (summary.get("kills", []) as Array).is_empty()
	)


static func _compute_metrics(summary: Dictionary, events: Array) -> Dictionary:
	var det := int(summary.get("detonate_tick", -1))
	var first_fire := -1
	var last_kill := -1
	var volley_kills := 0
	var volley_by_actor: Dictionary = {} ## actor → first-volley kill count
	var kill_actors: Dictionary = {} ## actor → count
	var alert_peak := "quiet"
	var alert_rank := {"quiet": 0, "suspicious": 1, "area_alert": 2, "global_alert": 3}
	for e in events:
		var t := str(e.get("type", ""))
		var tick := int(e.get("tick", -1))
		if t == "fire" and first_fire < 0:
			first_fire = tick
		if t == "kill":
			last_kill = tick
			var actor := str(e.get("actor", ""))
			kill_actors[actor] = int(kill_actors.get(actor, 0)) + 1
			if det >= 0 and tick >= det and tick <= det + VOLLEY_WINDOW_TICKS:
				volley_kills += 1
				volley_by_actor[actor] = int(volley_by_actor.get(actor, 0)) + 1
		if t == "alert_change" or t == "alert":
			var a := str(e.get("payload", {}).get("alert", e.get("alert", "")))
			if int(alert_rank.get(a, -1)) > int(alert_rank.get(alert_peak, 0)):
				alert_peak = a
	# Peak also from summary end alert.
	var end_alert := str(summary.get("alert", "quiet"))
	if int(alert_rank.get(end_alert, -1)) > int(alert_rank.get(alert_peak, 0)):
		alert_peak = end_alert
	var clear_s := -1.0
	if det >= 0 and last_kill >= det:
		clear_s = float(last_kill - det) * SimConstants.DT_S
	return {
		"detonate_tick": det,
		"first_fire_tick": first_fire,
		"last_kill_tick": last_kill,
		"clear_s": clear_s,
		"volley_kills": volley_kills,
		"volley_by_actor": volley_by_actor,
		"kill_actors": kill_actors,
		"alert_peak": alert_peak,
		"escape_n": (summary.get("escapes", []) as Array).size(),
		"kill_n": (summary.get("kills", []) as Array).size(),
	}


static func _grade(summary: Dictionary, m: Dictionary) -> String:
	## Ambush-quality grade (achievement-on-quality idea from DEV_PLAN D5 / W6).
	## S: standard wipe, quiet/suspicious, fast clear, strong first volley
	## A: standard wipe but slower / thinner volley
	## B: win with leaks or alert damage (not standard)
	## C: lose / heavy leaks / alarm
	var outcome := str(summary.get("outcome", ""))
	var std := bool(summary.get("standard_ambush", false))
	var esc := int(m.get("escape_n", 0))
	var trig := str(summary.get("trigger", ""))
	var peak := str(m.get("alert_peak", "quiet"))
	var volley := int(m.get("volley_kills", 0))
	var clear_s := float(m.get("clear_s", -1.0))
	var wounded_n := (summary.get("wounded", []) as Array).size()
	var dead_n := (summary.get("dead_ops", []) as Array).size()
	if outcome != "win" or trig == "alarm" or esc >= 3 or peak == "global_alert" or dead_n > 0:
		return "C"
	if not std or esc > 0 or peak == "area_alert":
		return "B"
	# Standard wipe, quiet/suspicious — wounds or slow clear → A (not trivially S).
	if wounded_n == 0 and volley >= 4 and clear_s >= 0.0 and clear_s <= CLEAR_FAST_S:
		return "S"
	return "A"


static func _outcome_zh(summary: Dictionary) -> String:
	var outcome := str(summary.get("outcome", ""))
	var esc: Array = summary.get("escapes", [])
	if outcome == "win" and esc.is_empty():
		return "全歼"
	if not esc.is_empty():
		return "部分逃脱"
	return "失败"


static func trigger_zh(trig: String) -> String:
	return _trigger_zh(trig)


static func _trigger_zh(trig: String) -> String:
	match trig:
		"cross_marker":
			return "越线开火"
		"mine_detonate":
			return "地雷起爆"
		"see_first_enemy":
			return "见敌开火"
		"manual":
			return "手动起爆"
		"alarm":
			return "被发现被迫交火"
		_:
			return "计划起爆"


static func _is_known_actor(actor: String, plan: Dictionary, names: Dictionary) -> bool:
	if names.has(actor) and str(names[actor]) != "":
		return true
	for op in plan.get("operators", []):
		if str(op.get("id", "")) == actor:
			return true
	for mine in plan.get("mines", []):
		if str(mine.get("id", "")) == actor:
			return true
	if actor.begins_with("mine"):
		return true
	return false


static func _op_label(op_id: String, plan: Dictionary, names: Dictionary) -> String:
	if names.has(op_id) and str(names[op_id]) != "":
		return str(names[op_id])
	# Fallback: numbered weapon label from plan (never raw id).
	var i := 0
	for op in plan.get("operators", []):
		i += 1
		if str(op.get("id", "")) == op_id:
			var wid := str(op.get("weapon_id", ""))
			var wzh := {"kar98k": "Kar98k", "mp40": "MP40", "mg42": "MG42", "grenade": "手雷", "mine": "地雷"}
			return "%d号·%s" % [i, wzh.get(wid, "队员")]
	if op_id.begins_with("mine"):
		return "地雷"
	return "队员"


static func _causes(
	summary: Dictionary,
	m: Dictionary,
	plan: Dictionary,
	names: Dictionary,
	events: Array
) -> Array:
	var out: Array = []
	var trig := str(summary.get("trigger", ""))
	var std := bool(summary.get("standard_ambush", false))
	var esc: Array = summary.get("escapes", [])
	var peak := str(m.get("alert_peak", "quiet"))
	var det := int(m.get("detonate_tick", -1))
	var clear_s := float(m.get("clear_s", -1.0))
	var volley := int(m.get("volley_kills", 0))
	var kill_actors: Dictionary = m.get("kill_actors", {})
	var wounded: Array = summary.get("wounded", [])
	var dead_ops: Array = summary.get("dead_ops", [])
	var combat := _combat_flags(events)

	# 1) Trigger / timing cause
	if trig == "alarm":
		out.append("岗哨或巡逻发现了小队，全图警报后被迫交火")
	elif det >= 0:
		var ideal := IDEAL_T0_B_TICK if str(plan.get("id", "")) == "B" else IDEAL_T0_A_TICK
		var early := det < ideal - 40 ## >2 s early
		var late := det > ideal + 40
		if early:
			out.append("触发偏早，侧翼可能还没进入杀伤区")
		elif late:
			out.append("触发偏晚，前队已接近杀伤区边缘")
		else:
			out.append("%s，敌人仍在预设杀伤区内" % _trigger_zh(trig))

	# 2) PLAY-6: wound / suppression / ammo / kill narrative (prefer combat truth)
	if not dead_ops.is_empty():
		var dlab := _op_label(str(dead_ops[0]), plan, names)
		out.append("%s 阵亡，火力缺口被敌人抓住" % dlab)
	elif not wounded.is_empty():
		var wlab := _op_label(str(wounded[0]), plan, names)
		if not esc.is_empty():
			out.append("%s被压制，左翼一人逃脱" % wlab)
		else:
			out.append("%s被还击压制，开火变慢" % wlab)
	elif bool(combat.get("ammo_empty", false)):
		var alab := _op_label(str(combat.get("ammo_actor", "")), plan, names)
		out.append("%s 弹药打空，压制断档" % alab)
	else:
		var top_actor := ""
		var top_n := 0
		var total_kills := 0
		for a in kill_actors.keys():
			var n := int(kill_actors[a])
			total_kills += n
			if not _is_known_actor(str(a), plan, names):
				continue
			if n > top_n:
				top_n = n
				top_actor = str(a)
		var volley_by_actor: Dictionary = m.get("volley_by_actor", {})
		if top_actor != "" and top_n > 0:
			var label := _op_label(top_actor, plan, names)
			var own_volley := int(volley_by_actor.get(top_actor, 0))
			if top_actor.begins_with("mine"):
				out.append("地雷炸开了纵队头兵，撕开口子")
			elif own_volley >= 4:
				out.append("%s在首轮点杀了 %d 人，压制势头很猛" % [label, own_volley])
			else:
				out.append("%s扛下了主要击杀（%d 人），清场靠交叉火力补完" % [label, top_n])
		elif total_kills > 0:
			if volley >= 4:
				out.append("首轮齐射点杀了 %d 人，压制势头很猛" % volley)
			else:
				out.append("交叉火力完成清场（%d 人）" % total_kills)

	# 3) Leaks / alert / quality (skip if wound+leak already combined)
	var wound_leak_combined := not wounded.is_empty() and not esc.is_empty()
	if not wound_leak_combined and not esc.is_empty():
		var next_a := str(summary.get("next_night_alert", "quiet"))
		if next_a != "quiet" and next_a != "":
			out.append("有 %d 人漏网逃脱，下一夜警报将升高" % esc.size())
		else:
			out.append("有 %d 人漏网逃脱，杀伤区或朝向还有缺口" % esc.size())
	elif peak == "area_alert" or peak == "global_alert":
		out.append("交火前警报已升高，标准伏击不可得")
	elif bool(combat.get("in_cover", false)) and std and clear_s > CLEAR_FAST_S:
		out.append("残敌钻进掩体还击，清场比完美压制慢一拍")
	elif std and clear_s >= 0.0 and clear_s <= CLEAR_FAST_S and wounded.is_empty():
		out.append("警报保持安静，标准伏击成立")
	elif std:
		out.append("无人逃脱，但清场比完美压制慢一拍")
	elif str(summary.get("outcome", "")) != "win":
		out.append("未能清场，需要调整站位、朝向或起爆时机")

	# Ensure 2–3 causes; trim extras.
	while out.size() > 3:
		out.pop_back()
	while out.size() < 2:
		out.append("复盘数据不足，建议再跑一局对照")
	return out


static func _combat_flags(events: Array) -> Dictionary:
	var ammo_empty := false
	var ammo_actor := ""
	var in_cover := false
	for e in events:
		var t := str(e.get("type", ""))
		if t == "ammo_empty" and not ammo_empty:
			ammo_empty = true
			ammo_actor = str(e.get("actor", ""))
		if t == "enemy_in_cover":
			in_cover = true
	return {"ammo_empty": ammo_empty, "ammo_actor": ammo_actor, "in_cover": in_cover}


static func _timeline(summary: Dictionary, m: Dictionary, events: Array, plan: Dictionary) -> Array:
	## Player-facing chips; use approximate seconds from wait start, never tick ids.
	var chips: Array = ["等待"]
	var det := int(m.get("detonate_tick", -1))
	if det >= 0:
		var sec := int(round(float(det) * SimConstants.DT_S))
		chips.append("约%d秒·%s" % [sec, _trigger_zh(str(summary.get("trigger", "")))])
	var volley := int(m.get("volley_kills", 0))
	if volley > 0:
		chips.append("首轮×%d" % volley)
	var clear_s := float(m.get("clear_s", -1.0))
	if clear_s >= 0.0:
		chips.append("清场%.1f秒" % clear_s)
	var esc_n := int(m.get("escape_n", 0))
	if esc_n > 0:
		chips.append("逃脱×%d" % esc_n)
	elif str(summary.get("outcome", "")) == "win":
		chips.append("全歼")
	else:
		chips.append("失败")
	# Cap strip length for HUD.
	if chips.size() > 5:
		chips = chips.slice(0, 5)
	return chips


static func hud_has_forbidden(text: String) -> bool:
	## Test helper: reject ticks / English trigger tokens / raw op ids in HUD.
	if text.find("tick") >= 0 or text.find("Tick") >= 0:
		return true
	for tok in ["cross_marker", "mine_detonate", "see_first_enemy", "manual", "alarm", "op_mg42", "op_kar", "op_mp40", "E1", "F1"]:
		if text.find(tok) >= 0:
			return true
	# Bare "t=123" style
	if text.find("t=") >= 0:
		return true
	return false
