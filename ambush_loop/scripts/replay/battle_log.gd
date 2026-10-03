class_name BattleLog
extends RefCounted

## Event log + lightweight presentation snapshots (blueprint §4.1).

var events: Array = [] # Dictionaries
var snapshots: Array = [] # every ~0.1s
var terminal_tick: int = -1
var terminal_reason: String = ""
const SCHEMA_VERSION := 2
var attempt_id: String = ""
var wave_id: int = 0
var wave_offset: int = 0
var _last_timeline_tick: int = -1
## Optional presentation clock. Original battle stamps/statistics stay intact.
var playback_schema: int = 0
var playback_snapshots: Array = []
var playback_terminal_tick: int = -1
var _playback_tick: int = 0
var _command_subticks: float = 0.0


func clear() -> void:
	events.clear()
	snapshots.clear()
	terminal_tick = -1
	terminal_reason = ""
	attempt_id = ""
	wave_id = 0
	wave_offset = 0
	_last_timeline_tick = -1
	playback_schema = 0
	playback_snapshots.clear()
	playback_terminal_tick = -1
	_playback_tick = 0
	_command_subticks = 0.0


func begin_attempt(id: String = "") -> void:
	clear()
	# Stored with the recording; independent of the host's coroutine run token.
	attempt_id = id if id != "" else Crypto.new().generate_random_bytes(16).hex_encode()


func begin_wave(index: int) -> void:
	if index == wave_id:
		return
	wave_id = index
	wave_offset = _last_timeline_tick + 1


func enable_continuous_playback() -> void:
	playback_schema = 1


func current_playback_tick() -> int:
	return _playback_tick


func advance_simulation_playback() -> void:
	if playback_schema == 1 and playback_terminal_tick < 0:
		_playback_tick += 1


func advance_command_playback(delta: float) -> void:
	if playback_schema != 1 or playback_terminal_tick >= 0 or not is_finite(delta) or delta <= 0.0:
		return
	_command_subticks += delta * 60.0
	var ticks := floori(_command_subticks + 0.000001)
	_playback_tick += ticks
	_command_subticks = maxf(_command_subticks - ticks, 0.0)


func _append_playback(snapshot: Dictionary) -> void:
	if playback_schema != 1:
		return
	snapshot["playback_schema"] = 1
	snapshot["playback_tick"] = _playback_tick
	snapshot["frame_seq"] = playback_snapshots.size()
	playback_snapshots.append(snapshot)


func add_command_snapshot(tick: int, data: Dictionary) -> void:
	if playback_schema != 1 or playback_terminal_tick >= 0:
		return
	# Recording a frozen command tick must not move the next battle-wave offset.
	_append_playback({"schema":SCHEMA_VERSION,"attempt_id":attempt_id,
		"wave_id":wave_id,"tick":tick,"timeline_tick":timeline_tick(tick),
		"data":data.duplicate(true)})


func timeline_tick(local_tick: int) -> int:
	return wave_offset + local_tick


static func record_tick(record: Dictionary) -> int:
	# Original single-wave snapshots/events used only tick.
	return int(record.get("timeline_tick", record.get("tick", 0)))


func _stamp(tick: int) -> Dictionary:
	var global_tick := timeline_tick(tick)
	_last_timeline_tick = maxi(_last_timeline_tick, global_tick)
	return {"schema": SCHEMA_VERSION, "attempt_id": attempt_id,
		"wave_id": wave_id, "tick": tick, "timeline_tick": global_tick}


func add_event(tick: int, type: String, actor_id: int = -1, target_id: int = -1, pos: Vector2 = Vector2.ZERO, payload: Dictionary = {}) -> void:
	var event := _stamp(tick)
	event.merge({"seq": events.size(), "event_id": "%s:%d:%d" % [attempt_id, wave_id, events.size()],
		"type": type, "actor_id": actor_id, "target_id": target_id,
		"position": pos, "payload": payload.duplicate(true)})
	if playback_schema == 1:
		event["playback_schema"] = 1
		event["playback_tick"] = _playback_tick
	events.append(event)


func add_snapshot(tick: int, data: Dictionary) -> void:
	var snapshot := _stamp(tick)
	snapshot["data"] = data.duplicate(true)
	snapshots.append(snapshot)
	_append_playback(snapshot)


func mark_terminal(tick: int, reason: String) -> void:
	if terminal_tick >= 0:
		return
	terminal_tick = timeline_tick(tick)
	terminal_reason = reason
	if playback_schema == 1:
		playback_terminal_tick = _playback_tick
	add_event(tick, "terminal", -1, -1, Vector2.ZERO, {"reason": reason})


func format_event(ev: Dictionary) -> String:
	var t: float = float(record_tick(ev)) / 60.0
	var typ: String = str(ev["type"])
	match typ:
		"spawn":
			var kit := str(ev.get("payload", {}).get("kit", "")).strip_edges()
			var route := str(ev.get("payload", {}).get("route", ""))
			var note := str(ev.get("payload", {}).get("note", "")).strip_edges()
			if kit == "echo":
				return "%.1fs  敌%d 灯塔回波进入东廊" % [t, ev["actor_id"]]
			if note != "":
				return "%.1fs  敌%d 从%s进入（%s）" % [t, ev["actor_id"], _route_zh(route), note]
			if route != "":
				return "%.1fs  敌%d 从%s进入战场" % [t, ev["actor_id"], _route_zh(route)]
			return "%.1fs  敌%d 进入战场" % [t, ev["actor_id"]]
		"fire":
			var shooter := str(ev.get("payload", {}).get("name", ""))
			var first := first_of_type("fire")
			var is_first := not first.is_empty() and int(first.get("seq", -2)) == int(ev.get("seq", -1))
			if is_first and shooter != "":
				return "%.1fs  ★ 第一枪是%s → 敌%d" % [t, shooter, ev["target_id"]]
			if shooter != "":
				return "%.1fs  %s 开火 → 敌%d" % [t, shooter, ev["target_id"]]
			return "%.1fs  队员%d 开火 → 敌%d" % [t, ev["actor_id"], ev["target_id"]]
		"return_fire":
			return "%.1fs  敌%d 还击 → 队员%d" % [t, ev["actor_id"], ev["target_id"]]
		"kill":
			return "%.1fs  敌%d 被击毙" % [t, ev["actor_id"]]
		"loot":
			return "%.1fs  队员%d 拾取 +%s弹" % [t, ev["actor_id"], str(ev["payload"].get("amount", "?"))]
		"empty":
			return "%.1fs  队员%d 弹药耗尽" % [t, ev["actor_id"]]
		"op_down":
			return "%.1fs  队员%d 阵亡" % [t, ev["actor_id"]]
		"escape":
			var route_zh := _route_zh(str(ev.get("payload", {}).get("route", "")))
			if route_zh != "":
				return "%.1fs  敌%d 沿%s越界逃逸" % [t, ev["actor_id"], route_zh]
			return "%.1fs  敌%d 越界逃逸" % [t, ev["actor_id"]]
		"abort":
			return "%.1fs  指挥官中止尝试" % t
		"barrel":
			var hits := int(ev.get("payload", {}).get("hits", 0))
			if hits > 0:
				return "%.1fs  ★ 油桶炸到人 · %d" % [t, hits]
			return "%.1fs  油桶爆炸" % t
		"repack":
			var pack_nm := str(ev.get("payload", {}).get("name", ""))
			if pack_nm != "":
				return "%.1fs  ★ %s 弹包续上" % [t, pack_nm]
			return "%.1fs  队员%d 弹包补给" % [t, ev["actor_id"]]
		"ambush_armed":
			var amb_nm := str(ev.get("payload", {}).get("name", ""))
			if amb_nm != "":
				return "%.1fs  ★ %s 入伏许可 — 现在打" % [t, amb_nm]
			return "%.1fs  队员%d 入伏许可开启" % [t, ev["actor_id"]]
		"door":
			return "%.1fs  门状态=%s" % [t, str(ev["payload"].get("locked", "?"))]
		"no_engage":
			return "%.1fs  队员%d 无法交战 敌%d（%s）" % [
				t, ev["actor_id"], ev["target_id"], _no_engage_reason_zh(str(ev["payload"].get("reason", "?")))
			]
		"trip":
			return "%.1fs  ★ 绊索抽中 敌%d" % [t, ev["actor_id"]]
		"route_choice":
			if bool(ev.get("payload", {}).get("covered", false)):
				return "%.1fs  ★ 敌%d 改走紫色备用接近 — 被你罩住" % [t, ev["actor_id"]]
			return "%.1fs  敌%d 改走紫色备用接近" % [t, ev["actor_id"]]
		"terminal":
			return "%.1fs  终局：%s" % [t, str(ev["payload"].get("reason", "?"))]
		_:
			return "%.1fs  %s" % [t, typ]


func _no_engage_reason_zh(reason: String) -> String:
	match reason:
		"hold":
			return "入伏未许可"
		"ammo":
			return "弹药"
		"range":
			return "射程"
		"cone":
			return "射界"
		"los":
			return "视线"
		_:
			return reason


func summary_lines(max_count: int = 12) -> PackedStringArray:
	var out := PackedStringArray()
	var start := maxi(events.size() - max_count, 0)
	for i in range(start, events.size()):
		out.append(format_event(events[i]))
	return out


func last_of_type(type_name: String) -> Dictionary:
	for i in range(events.size() - 1, -1, -1):
		if str(events[i]["type"]) == type_name:
			return events[i]
	return {}


static func reason_zh(reason: String) -> String:
	match reason:
		"escape":
			return "逃逸"
		"wipe":
			return "全灭"
		"abort":
			return "中止"
		"win":
			return "通关"
		"empty":
			return "空弹"
		"route_choice":
			return "改线"
		"trip":
			return "绊索"
		_:
			return reason


func has_type(type_name: String) -> bool:
	return not last_of_type(type_name).is_empty()


func max_kill_combo(window_ticks: int = 48) -> int:
	var best := 0
	var run := 0
	var last := -99999
	var last_wave := -1
	for ev in events:
		if str(ev.get("type", "")) != "kill":
			continue
		var t := record_tick(ev)
		var wave := int(ev.get("wave_id", 0))
		if wave == last_wave and t - last <= window_ticks and last >= 0:
			run += 1
		else:
			run = 1
		last = t
		last_wave = wave
		best = maxi(best, run)
	return best


func _route_zh(route: String) -> String:
	match route:
		"main":
			return "主路"
		"flank":
			return "侧翼"
		"sneak":
			return "西暗道"
		"alt":
			return "备用接近"
		_:
			return ""


func first_of_type(type_name: String) -> Dictionary:
	for ev in events:
		if str(ev["type"]) == type_name:
			return ev
	return {}


func terminal_summary_line() -> String:
	## One-line 终局摘要 from terminal reason + last meaningful events.
	var bits: PackedStringArray = []
	match terminal_reason:
		"escape":
			var esc := last_of_type("escape")
			var route_zh := _route_zh(str(esc.get("payload", {}).get("route", "")))
			if route_zh != "":
				bits.append("敌军沿%s从逃逸口越界" % route_zh)
			else:
				bits.append("敌军从逃逸口越界")
		"wipe":
			bits.append("参战小队全灭")
		"abort":
			bits.append("指挥官中止尝试")
		"win":
			bits.append("零逃逸，封锁成功")
		_:
			if terminal_reason != "":
				bits.append(reason_zh(terminal_reason))
	var first_fire := first_of_type("fire")
	if not first_fire.is_empty():
		var nm := str(first_fire.get("payload", {}).get("name", ""))
		if nm != "":
			bits.append("第一枪是%s" % nm)
		else:
			bits.append("第一枪是队员%d" % int(first_fire.get("actor_id", 0)))
	if has_type("empty") and terminal_reason != "win":
		bits.append("有队员空弹")
	if has_type("trip"):
		var trip_ev := last_of_type("trip")
		bits.append("绊索抽中敌%d" % int(trip_ev.get("actor_id", 0)))
	if has_type("barrel"):
		var bar := last_of_type("barrel")
		var hits := int(bar.get("payload", {}).get("hits", 0))
		if hits > 0:
			bits.append("油桶炸到人")
	if has_type("ambush_armed"):
		bits.append("入伏后再打")
	if has_type("repack"):
		bits.append("弹包续上")
	if has_type("route_choice"):
		var rc := last_of_type("route_choice")
		if bool(rc.get("payload", {}).get("covered", false)):
			bits.append("门锁后紫线改道被你罩住")
		else:
			bits.append("门锁后敌改走备用接近")
	var combo := max_kill_combo()
	if combo >= 2:
		bits.append("连击×%d" % combo)
	if bits.is_empty():
		return "终局摘要：—"
	return "终局摘要：" + "；".join(bits) + "。"


func fingerprint() -> String:
	var parts: PackedStringArray = []
	for ev in events:
		parts.append("%s:%d" % [str(ev["type"]), int(ev["tick"])])
	return ",".join(parts)
