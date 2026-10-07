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

var source: BattleLog
var initial_record: PackedByteArray
var initial_domain: PackedByteArray
var inputs: Array = []
var output_root: String
func dump(label: String, drawn: bool) -> void:
	var controls: Array = []; ui(m,"main",controls)
	var frame: Dictionary = m.presentation_3d.frame.duplicate(true)
	for token in ["shot_fx_source_token","tool_fx_source_token","movement_fx_source_token"]:
		if frame.has(token):
			check(frame[token]==source.get_instance_id(),label+" source binding")
			frame.erase(token)
	var actors: Array = []
	for group in ["ops","enemies","sentries"]:
		for item in frame.get(group,[]):
			var proxy = m.presentation_3d.actors.get(group+":"+str(item.id))
			if proxy == null: continue
			var body = proxy.get_node("Body")
			var bones: Array = []
			for i in body.skeleton.get_bone_count(): bones.append(plain(body.skeleton.get_bone_pose(i)))
			check(bones.size()==20,label+" 20 bones")
			actors.append({"group":group,"id":item.id,"root":plain(proxy.position),"bones":bones,"socket":plain(body.bone_socket("weapon_hand"))})
	var details := {"label":label,"drawn":drawn,"phase":m.phase,"tick":m.replay.scrub_tick,"playing":m.replay.playing,"speed":m.replay.speed,"force_touch":root.get_node("GameSettings").force_touch_hud,"ui":controls,"frame":plain(frame),"actors":actors,"domain":hash_bytes(var_to_bytes(m._snapshot_data())),"record":hash_bytes(record(source)),"cfg":cfg(),"touch_metrics":m.touch_hud.setup_bar_metrics()}
	if drawn:
		var img := root.get_texture().get_image()
		check(not img.is_empty(),label+" actual image")
		img.save_png(output_root+"/"+label+".png")
		details["rgba_sha256"]=hash_bytes(img.get_data())
		details["pixels"]=[img.get_width(),img.get_height()]
	rows.append(details)
	var f := FileAccess.open(output_root+"/"+label+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(details)); f.close()
func hash_bytes(b: PackedByteArray) -> String:
	var h := HashingContext.new(); h.start(HashingContext.HASH_SHA256); h.update(b); return h.finish().hex_encode()
func click(b: Button, label: String) -> void:
	check(b.is_visible_in_tree() and not b.disabled,label+" reachable original button")
	var pos := b.get_global_rect().get_center()
	inputs.append({"label":label,"text":b.text,"rect":plain(b.get_global_rect()),"type":"Input.parse_input_event mouse GUI; synthetic engine input, not OS/DOM trusted"})
	var motion := InputEventMouseMotion.new(); motion.position=pos; motion.global_position=pos
	Input.parse_input_event(motion)
	var e := InputEventMouseButton.new(); e.button_index=MOUSE_BUTTON_LEFT; e.position=pos; e.global_position=pos; e.pressed=true
	Input.parse_input_event(e)
	e=InputEventMouseButton.new(); e.button_index=MOUSE_BUTTON_LEFT; e.position=pos; e.global_position=pos; e.pressed=false
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func key(code: int, label: String) -> void:
	inputs.append({"label":label,"code":code,"type":"synthetic engine keyboard input"})
	var e := InputEventKey.new(); e.keycode=code; e.physical_keycode=code; e.pressed=true
	Input.parse_input_event(e)
	e=InputEventKey.new(); e.keycode=code; e.physical_keycode=code; e.pressed=false
	Input.parse_input_event(e); Input.flush_buffered_events()
func draws(label: String, count: int=3) -> void:
	dump(label+"-sync",false)
	for i in count:
		await RenderingServer.frame_post_draw
		dump(label+"-draw"+str(i+1),true)
func _run() -> void:
	output_root=OS.get_environment("FIRST_DRAW_OUTPUT")
	root.size=Vector2i(1280,720)
	check(FileAccess.get_sha256(YARD)=="e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5","original bytes")
	var paired: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PAIR))
	for name: String in paired:
		var f:=FileAccess.open("user://"+name,FileAccess.WRITE);f.store_string(paired[name].text);f.close()
	var settings=root.get_node("GameSettings");settings.load_settings();settings.pending_level_id="yard"
	check(not settings.force_touch_hud,"paired touch initially off")
	m=load("res://scenes/presentation/yard_3d.tscn").instantiate()
	m.process_mode=Node.PROCESS_MODE_DISABLED
	root.add_child(m);current_scene=m
	for i in 3: await RenderingServer.frame_post_draw
	source=load_log(YARD);m.battle_log=source;m.phase=m.Phase.WON;m.raid.wave_index=1;m.raid.waves_cleared=2
	m.process_mode=Node.PROCESS_MODE_INHERIT;m._show_win_result()
	# Initial consumer fixture only; subsequent samples use GUI routes and no refresh calls.
	for i in 12: await RenderingServer.frame_post_draw
	initial_record=record(source);initial_domain=var_to_bytes(m._snapshot_data())
	dump("paired-WON",true)
	click(m.replay_button,"original-WON-Replay")
	check(m.phase==m.Phase.REPLAY,"original Replay button entered REPLAY synchronously")
	await draws("entry-off")
	click(m.pause_button,"original-desktop-pause")
	check(not m.replay.playing,"original pause responds")
	await draws("paused-off",1)
	key(KEY_ESCAPE,"original-menu-open")
	for i in 3: await RenderingServer.frame_post_draw
	check(m.pause_overlay.is_open(),"original menu reachable")
	click(m.pause_overlay._touch_btn,"original-menu-touch-off-on")
	check(settings.force_touch_hud,"original touch toggle applied")
	await draws("touch-on-menu")
	click(m.pause_overlay._close_btn,"original-menu-close")
	await draws("touch-on-visible")
	check(m.touch_hud._replay_pause.is_visible_in_tree(),"touch transport visible")
	var prior_speed:float=m.replay.speed
	click(m.touch_hud._replay_speed,"original-touch-speed")
	check(m.replay.speed!=prior_speed,"touch speed hit responds")
	await draws("touch-speed",1)
	click(m.touch_hud._replay_pause,"original-touch-resume")
	check(m.replay.playing,"touch resume hit responds")
	await draws("touch-resume",1)
	click(m.touch_hud._replay_pause,"original-touch-pause")
	check(not m.replay.playing,"touch pause hit responds")
	key(KEY_SPACE,"original-return-WON")
	await draws("return-WON",1)
	check(m.phase==m.Phase.WON,"return original WON")
	check(record(source)==initial_record,"record containers immutable")
	click(m.replay_button,"original-WON-Replay-touch-on")
	await draws("entry-on")
	check(m.phase==m.Phase.REPLAY,"second original Replay entry")
	check(FileAccess.get_sha256(YARD)=="e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5","archive retained")
	var f:=FileAccess.open(output_root+"/summary.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows.size(),"inputs":inputs,"initial_record":hash_bytes(initial_record),"initial_domain":hash_bytes(initial_domain),"final_domain":hash_bytes(var_to_bytes(m._snapshot_data())),"final_cfg":cfg(),"scope":"original paired consumer fixture + engine GUI input; first-postdraw and two following frames; fixed-fps60, no acceptance sample refresh/caching/clock freeze, not trusted OS/Web/fresh13/performance"}));f.close()
	print("FIRST_DRAW checks=",checks," failures=",failures," rows=",rows.size())
	quit(0 if failures==0 else 1)
