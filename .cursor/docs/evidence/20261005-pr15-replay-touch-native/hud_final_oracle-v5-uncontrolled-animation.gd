extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const FIELDS := ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]
const YARD := "/workspace/ambush-pr15/.cursor/docs/evidence/20261005-pr15-fresh-web-yard-pause/run/yard-record.bin"
const OLD := "/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin"
const PAIR := "/workspace/pr15-hud-subsegment-stage-1ec-20261005/qa/yard-paired-settings.json"
var checks := 0
var failures := 0
var rows: Array = []
var m: Node
func _init() -> void:
	if not Guard.check(): quit(91); return
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("HUD_FINAL_ORACLE: "+label)
func plain(v: Variant) -> Variant:
	if v is Vector2 or v is Vector2i: return [v.x,v.y]
	if v is Vector3: return [v.x,v.y,v.z]
	if v is Color: return [v.r,v.g,v.b,v.a]
	if v is Rect2: return [v.position.x,v.position.y,v.size.x,v.size.y]
	if v is Transform3D: return [plain(v.basis.x),plain(v.basis.y),plain(v.basis.z),plain(v.origin)]
	if v is Dictionary:
		var out := {}
		for k in v: out[str(k)] = plain(v[k])
		return out
	if v is Array or v is PackedStringArray or v is PackedInt32Array or v is PackedVector2Array:
		var out: Array = []
		for x in v: out.append(plain(x))
		return out
	if v is Resource:
		var out := {"class":v.get_class()}
		if v is StyleBox:
			for p in v.get_property_list():
				if p.usage & PROPERTY_USAGE_STORAGE and p.name not in ["resource_local_to_scene","resource_name","script"]: out[str(p.name)] = plain(v.get(p.name))
		else: out["resource_path"] = v.resource_path
		return out
	if v is Object: return {"class":v.get_class()}
	return v
func ui(n: Node, path: String, out: Array) -> void:
	if n is Control:
		var item := {"path":path,"class":n.get_class(),"visible":n.visible,"in_tree":n.is_visible_in_tree(),"rect":plain(n.get_global_rect()),"modulate":plain(n.modulate),"self_modulate":plain(n.self_modulate),"minimum":plain(n.custom_minimum_size),"mouse_filter":n.mouse_filter}
		for p in n.get_property_list():
			if p.name in ["text","disabled","button_pressed","value","min_value","max_value","editable"] or str(p.name).begins_with("theme_override"):
				item[str(p.name)] = plain(n.get(p.name))
		if n is Button:
			var styles := {}
			for name in ["normal","hover","pressed","disabled","focus"]: styles[name] = plain(n.get_theme_stylebox(name))
			item["styles"] = styles
			item["font_size"] = n.get_theme_font_size("font_size")
		if n is ItemList:
			var texts: Array = []
			for i in n.item_count: texts.append(n.get_item_text(i))
			item["items"] = texts
		out.append(item)
	for i in n.get_child_count(): ui(n.get_child(i),path+"/"+str(i),out)
func record(log: BattleLog) -> PackedByteArray:
	var out := {}
	for f: String in FIELDS: out[f] = log.get(f)
	return var_to_bytes(out)
func load_log(path: String) -> BattleLog:
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var log := BattleLog.new()
	for f: String in FIELDS: log.set(f,raw[f])
	return log
func cfg() -> Dictionary:
	var out := {}
	for name in ["ambush_loop.cfg","ambush_loop_settings.cfg"]:
		out[name] = FileAccess.get_file_as_string("user://"+name)
	return out
func settle() -> void:
	for i in 3: await process_frame
func capture(label: String, source: BattleLog) -> void:
	m._apply_replay_scrub(); m._update_hud(); m.presentation_3d.refresh()
	await settle()
	var frame: Dictionary = m.presentation_3d.frame.duplicate(true)
	for token in ["shot_fx_source_token","tool_fx_source_token","movement_fx_source_token"]:
		check(frame[token] == source.get_instance_id(),label+" source token bound before normalization")
		frame.erase(token)
	var controls: Array = []; ui(m,"main",controls)
	var actors: Array = []
	for group in ["ops","enemies","sentries"]:
		for item in frame.get(group,[]):
			var proxy = m.presentation_3d.actors.get(group+":"+str(item.id))
			var body = proxy.get_node("Body")
			var bones: Array = []
			for i in body.skeleton.get_bone_count(): bones.append(plain(body.skeleton.get_bone_pose(i)))
			check(bones.size()==20,label+" 20 bones")
			actors.append({"group":group,"id":item.id,"root":plain(proxy.position),"bones":bones,"socket":plain(body.bone_socket("weapon_hand"))})
	rows.append({"label":label,"tick":m.replay.scrub_tick,"frame":plain(frame),"ui":controls,"actors":actors})
func _run() -> void:
	root.size = Vector2i(1280,720)
	check(FileAccess.get_sha256(YARD)=="e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5","yard original bytes")
	check(FileAccess.get_sha256(OLD)=="1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12","old original bytes")
	var paired: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PAIR))
	for name: String in paired:
		var f := FileAccess.open("user://"+name,FileAccess.WRITE); f.store_string(paired[name].text); f.close()
	var settings = root.get_node("GameSettings"); settings.load_settings(); settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn"); await settle()
	m = current_scene; m.set_process(false); m.presentation_3d.set_process(false)
	var yard := load_log(YARD); var old := load_log(OLD)
	m.battle_log=yard; m.phase=m.Phase.WON; m.raid.wave_index=1; m.raid.waves_cleared=2; m._show_win_result(); await settle()
	var domain_data: Dictionary = m._snapshot_data().duplicate(true); var domain := var_to_bytes(domain_data); var config := cfg()
	var yard_bytes := record(yard); var old_bytes := record(old)
	m._on_replay_pressed(); m.replay.pause()
	for touch in [false,true]:
		# Presentation fixture only; avoid persisting a new preference.
		settings.force_touch_hud=touch
		for entry in [[yard,"yard"],[old,"old-schema1"],[yard,"yard-return"]]:
			var source: BattleLog = entry[0]; m.battle_log=source; m.replay.bind(source); m.replay.pause()
			for tick in [0,6339,source.playback_terminal_tick]:
				m.replay.set_tick(mini(tick,source.playback_terminal_tick))
				await capture(str(entry[1])+"/touch="+str(touch)+"/seek="+str(tick),source)
			if not source.events.is_empty():
				m._focus_battle_event(source.events[-1]); await capture(str(entry[1])+"/touch="+str(touch)+"/focus-last",source)
				var saved: Dictionary = rows[-1].duplicate(true)
				m.battle_log=old if source==yard else yard
				var saved_clock: float = m._pose_command_clock_s
				m._pose_command_clock_s+=100.0
				await capture(str(entry[1])+"/touch="+str(touch)+"/foreign-live",source)
				check(saved.frame==rows[-1].frame and saved.actors==rows[-1].actors,"bound history unchanged by live source/clock poison")
				m.battle_log=source; m._pose_command_clock_s=saved_clock
	settings.force_touch_hud=false; m.battle_log=yard; m.replay.bind(yard); m.replay.pause()
	var key := InputEventKey.new(); key.physical_keycode=KEY_SPACE; key.pressed=true; Input.parse_input_event(key); await settle()
	key=InputEventKey.new(); key.physical_keycode=KEY_SPACE; key.pressed=false; Input.parse_input_event(key); await settle()
	check(m.phase==m.Phase.WON,"original Space returns paired WON")
	var domain_after: Dictionary = m._snapshot_data()
	var differences: Array = []
	for k in domain_data:
		if domain_data[k]!=domain_after.get(k): differences.append({"key":k,"before":plain(domain_data[k]),"after":plain(domain_after.get(k))})
	print("DOMAIN_DIFFERENCE_KEYS=",differences.map(func(x): return x.key))
	var stable_after: Dictionary = domain_after.duplicate(true)
	for i in stable_after.ops.size():
		check(m.operators[i].slot==null and not stable_after.ops[i].active,"existing return keeps unassigned live actor hidden")
		stable_after.ops[i].active=domain_data.ops[i].active
	check(stable_after==domain_data,"full snapshot unchanged except explicitly checked existing live visibility transition")
	check(cfg()==config,"complete cfg texts retained")
	check(record(yard)==yard_bytes and record(old)==old_bytes,"source containers immutable")
	check(FileAccess.get_sha256(YARD)=="e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5" and FileAccess.get_sha256(OLD)=="1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12","source archives unchanged")
	var f := FileAccess.open(OS.get_environment("HUD_ORACLE_OUTPUT"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"cfg":cfg(),"scope":"controlled original-record consumer; token instance IDs checked then omitted; no new producer/whole/device acceptance"})); f.close()
	print("HUD_FINAL_ORACLE checks=",checks," failures=",failures," cases=",rows.size())
	m.queue_free(); await process_frame; quit(0 if failures==0 else 1)
