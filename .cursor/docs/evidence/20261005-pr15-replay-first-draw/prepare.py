from pathlib import Path
import hashlib,json,subprocess

R=Path('/tmp/pr15-replay-first-draw-20261005')
R.mkdir(exist_ok=True)
original=Path('/tmp/pr15-web-controls/replay-touch-candidate-95daa-20261005/hud_final_oracle.gd').read_text()
prefix=original[:original.index('func freeze_presentation_clock')]
helpers=original[original.index('func record('):original.index('func settle(')]
tail=r'''
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
'''
(R/'first_draw.gd').write_text(prefix+helpers+tail)
repo=Path('/workspace/ambush-pr15');A=Path('/workspace/pr15-replay-save-stage-1ec-20261005');B=Path('/workspace/pr15-replay-touch-candidate-95daa-20261005')
files=subprocess.check_output(['git','ls-files','-z','ambush_loop'],cwd=repo).decode().split('\0')[:-1]
diff=[];missing=[];checked=[]
for name in files:
 rel=name.removeprefix('ambush_loop/')
 if not (A/rel).is_file() or not (B/rel).is_file():missing.append(rel);continue
 aa=(A/rel).read_bytes();bb=(B/rel).read_bytes()
 checked.append({'path':rel,'A':hashlib.sha256(aa).hexdigest(),'B':hashlib.sha256(bb).hexdigest()})
 if aa!=bb:diff.append(rel)
assert diff==['scripts/main.gd'],diff
assert missing==['ArtSource/v2/yard_kit.blend'],missing
imports=[]
for p in sorted((A/'.godot/imported').glob('*')):
 if p.is_file():
  q=B/p.relative_to(A);assert q.is_file() and p.read_bytes()==q.read_bytes(),str(p)
  imports.append({'path':str(p.relative_to(A)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(R/'runtime-audit.json').write_text(json.dumps({'actual_exit':0,'checked':checked,'missing_nonruntime_blend':missing,'differences':diff,'imports':imports},ensure_ascii=False,indent=2))
print(json.dumps({'actual_exit':0,'product_files':len(checked),'sole_diff':diff,'imports':len(imports),'helper_sha256':hashlib.sha256((R/'first_draw.gd').read_bytes()).hexdigest()}))
