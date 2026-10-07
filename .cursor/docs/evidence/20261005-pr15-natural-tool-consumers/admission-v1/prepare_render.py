from pathlib import Path
import hashlib,json
R=Path('/tmp/pr15-natural-tool-originals-20261005')
old=Path('/tmp/pr15-web-controls/replay-touch-candidate-95daa-20261005/hud_final_oracle.gd').read_text()
prefix=old[:old.index('func freeze_presentation_clock')]
helpers=old[old.index('func record('):old.index('func settle(')]
tail=r'''
const Reader=preload("res://scripts/presentation/tool_fx_frame.gd")
const ActorPose=preload("res://scripts/presentation/actor_pose.gd")
const Space=preload("res://scripts/presentation/world_space.gd")
var source:BattleLog
var target_event:Dictionary
var label:String
var output_root:String
var domain_before:Dictionary
var config_before:Dictionary
var checkpoint_before:Dictionary
var source_before:PackedByteArray
func dump(name:String)->void:
	var frame:Dictionary=m.presentation_3d.frame.duplicate(true)
	check(frame.attempt_id==source.attempt_id and frame.wave_id==1,"original event scope "+name)
	var controls:Array=[];ui(m,"main",controls)
	var actors:Array=[]
	for group in ["ops","enemies","sentries"]:
		for item in frame.get(group,[]):
			var proxy=m.presentation_3d.actors.get(group+":"+str(item.id))
			if proxy==null:continue
			var body=proxy.get_node("Body")
			var bones:Array=[]
			for i in body.skeleton.get_bone_count():bones.append(plain(body.skeleton.get_bone_pose(i)))
			check(bones.size()==20,"20 bones "+name)
			actors.append({"group":group,"id":item.id,"action":body.sampled_action,"seconds":body.sampled_time,"equipped":body.equipped_id,"layers":plain(body._layers),"bones":bones,"socket":plain(body.bone_socket("weapon_hand"))})
	var img:=root.get_texture().get_image();img.save_png(output_root+"/"+name+".png")
	var value:Dictionary={"label":name,"tick":m.replay.scrub_tick,"target_event":plain(target_event),"frame":plain(frame),"UI":controls,"actors":actors,"tool_pool_active":plain(m.presentation_3d.tool_fx._active),"event_ring_visible":m.presentation_3d._event_ring.visible,"domain":plain(m._snapshot_data()),"cfg":cfg(),"checkpoint":WebConfigStore.snapshot()}
	var f:=FileAccess.open(output_root+"/"+name+".json",FileAccess.WRITE);f.store_string(JSON.stringify(value));f.close();rows.append(value)
func select(tick:int,name:String)->void:
	m.replay.set_tick(tick);m._apply_replay_scrub();m.presentation_3d.refresh()
	await RenderingServer.frame_post_draw
	dump(name)
	check(m._snapshot_data()==domain_before,"full live domain unchanged "+name)
	check(cfg()==config_before and WebConfigStore.snapshot()==checkpoint_before,"complete cfg/checkpoint unchanged "+name)
	check(record(source)==source_before,"record containers unchanged "+name)
func _run()->void:
	label=OS.get_environment("TOOL_CASE");output_root=OS.get_environment("TOOL_OUTPUT")
	root.size=Vector2i(1280,720)
	var level_id:String="warehouse" if label=="warehouse-mine" else "railcut"
	var relative:String="20261004-pr15-remaining-journey/run-b27" if level_id=="warehouse" else "20261004-pr15-railcut-journey/run-3b49"
	for name in ["ambush_loop.cfg","ambush_loop_settings.cfg"]:
		var original:String="/workspace/ambush-pr15/.cursor/docs/evidence/"+relative+"/ending-player-progress/"+name
		var f:=FileAccess.open("user://"+name,FileAccess.WRITE);f.store_string(FileAccess.get_file_as_string(original));f.close()
	var settings=root.get_node("GameSettings");settings.load_settings();settings.pending_level_id=level_id
	m=load("res://scenes/presentation/yard_3d.tscn").instantiate();m.process_mode=Node.PROCESS_MODE_DISABLED;root.add_child(m);current_scene=m
	for i in 3:await RenderingServer.frame_post_draw
	m.set_process(false);m.presentation_3d.set_process(false);m.process_mode=Node.PROCESS_MODE_INHERIT
	source=load_log("/tmp/pr15-natural-tool-originals-20261005/"+label+".bin")
	for ev in source.events:
		if ev.seq==(39 if level_id=="warehouse" else 28):target_event=ev
	check(target_event.type==("mine" if level_id=="warehouse" else "repack"),"original target event")
	m.battle_log=source;m.phase=m.Phase.WON;m.raid.wave_index=1;m.raid.waves_cleared=2;m._show_win_result()
	for i in 6:await RenderingServer.frame_post_draw
	m._on_replay_pressed();m.replay.pause()
	domain_before=m._snapshot_data().duplicate(true);config_before=cfg();checkpoint_before=WebConfigStore.snapshot();source_before=record(source)
	var file:=FileAccess.open(output_root+"/before.json",FileAccess.WRITE);file.store_string(JSON.stringify({"domain":plain(domain_before),"cfg":config_before,"checkpoint":checkpoint_before,"source_archive_sha":FileAccess.get_sha256("/tmp/pr15-natural-tool-originals-20261005/"+label+".bin")}));file.close()
	m.presentation_3d.rig.focus=Space.logic_to_world(target_event.position);m.presentation_3d.rig.view_size=7.0;m.presentation_3d.rig.yaw_deg=180.0;m.presentation_3d.rig.pitch_deg=35.0;m.presentation_3d.rig.apply_pose()
	var event_tick:int=target_event.playback_tick
	await select(event_tick-1,"before-event")
	await select(event_tick,"event")
	if level_id=="warehouse":
		check(m.presentation_3d.frame.tool_fx_schema==0 and Reader.active(m.presentation_3d.frame).is_empty() and m.presentation_3d.tool_fx._active.is_empty(),"old mine record is neutral; no invented confirmation cue")
		await select(event_tick+6,"after-event")
	else:
		check(target_event.payload.repack_kind=="same_weapon" and target_event.payload.visual_weapon=="kar98k","genuine same weapon payload")
		await select(event_tick+int(ceil(ActorPose.FIRE_SECONDS*60))+12,"reload-contact")
		var body=m.presentation_3d.actors["ops:1"].get_node("Body")
		check(body.sampled_action=="reload_contact" and body.equipped_id=="kar98k" and body._layers.event_id==target_event.event_id,"actual historical reload contact/bound weapon/event")
		await select(event_tick+72,"after-reload")
		body=m.presentation_3d.actors["ops:1"].get_node("Body")
		check(body.sampled_action!="reload_contact","reload ends on saved event clock")
	m._focus_battle_event(target_event);m.presentation_3d.refresh();await RenderingServer.frame_post_draw;dump("focused-event")
	check(m.replay_focus_type==target_event.type and m.presentation_3d._event_ring.visible,"actual 3D original event focus")
	await select(event_tick-1,"seek-back")
	var domain_return_before:Dictionary=m._snapshot_data().duplicate(true)
	var event:=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
	await RenderingServer.frame_post_draw
	check(m.phase==m.Phase.WON,"original Space returns paired WON")
	check(record(source)==source_before,"exit retains original record")
	check(m.presentation_3d.tool_fx._active.is_empty(),"old pool clear on exit")
	file=FileAccess.open(output_root+"/after.json",FileAccess.WRITE);file.store_string(JSON.stringify({"domain":plain(m._snapshot_data()),"domain_before_return":plain(domain_return_before),"cfg":cfg(),"checkpoint":WebConfigStore.snapshot(),"record_unchanged":record(source)==source_before}));file.close()
	file=FileAccess.open(output_root+"/summary.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":rows.size(),"scope":"old natural records/current 1ec-equal b74 consumer; controlled seeks/camera/paused scene; no producer/whole/Web/performance/positive mine cue acceptance"}));file.close()
	print("NATURAL_TOOL_CONSUMER label=",label," checks=",checks," failures=",failures," samples=",rows.size())
	quit(0 if failures==0 else 1)
'''
(R/'render.gd').write_text(prefix+helpers+tail)
(R/'render-controls.json').write_text(json.dumps({'script_sha256':hashlib.sha256((R/'render.gd').read_bytes()).hexdigest(),'scope':'pre-start frozen consumer; old mine neutral compatibility, real repack pose; no positive mine FX acceptance'},indent=2))
print('RENDER_CONTROLS_FROZEN')
