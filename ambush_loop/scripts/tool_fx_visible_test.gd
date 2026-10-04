extends "res://scripts/tool_fx_pool_test.gd"
## Actual original empty explosion, explicit placement and saved-age controls.
var visibility_rows: Array=[]

func _pixels(before: Image, after: Image, center: Vector2, radius: int) -> int:
	var changed:=0
	for y in range(maxi(0,int(center.y)-radius),mini(after.get_height(),int(center.y)+radius+1)):
		for x in range(maxi(0,int(center.x)-radius),mini(after.get_width(),int(center.x)+radius+1)):
			var left:=before.get_pixel(x,y)
			var right:=after.get_pixel(x,y)
			if maxf(absf(left.r-right.r),maxf(absf(left.g-right.g),absf(left.b-right.b)))>0.04:changed+=1
	return changed

func _run() -> void:
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	root.content_scale_factor=1.0
	directory="res://build/asset_review/pr15-runtime/tool-fx-visible-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="yard"
	settings.mark_tutorial_seen("yard")
	settings.set_force_touch_hud(false)
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	var pair: Array=await _reset()
	var owner: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	owner.global_position=main.grid.cell_to_world_center(Vector2i(25,12))
	enemy.global_position=Vector2(960,576)
	for op: OperatorUnit in main.operators:
		if op!=owner:op.global_position=Vector2(1024,640)
	var destination: Vector2=main.grid.cell_to_world_center(Vector2i(25,17))
	_check(not main.grid.is_blocked(25,12) and not main.grid.is_blocked(25,17),"explicit source fixture uses authored open-ground cells")
	var grenade:=_throw(owner,destination)
	await _blast([grenade])
	var actual_spent:=grenade.spent() # Original removal queues this tool for deletion.
	main._on_pause_pressed() # Original paused ALERT; main automatic process already disabled.
	for index in 30:await process_frame # Settle original presentation tweens before off controls.
	main._update_hud()
	var frame:=ViewState.capture(main)
	pool=main.presentation_3d.get_node("ToolFx")
	pool.update_frame(frame,false) # Exercise the original presenter reader and pool path.
	var actual: Array=_diag().active
	_check(actual_spent and actual.size()==1 and frame.tool_fx.front().victims.is_empty() and main.sim.paused,"real original empty blast confirmed and original ALERT pause reached")
	var original:=_state(main.battle_log)
	var live: Dictionary=main._snapshot_data().duplicate(true)
	var backend:=var_to_bytes([main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades]),enemy.global_position,enemy.hp])
	var effect: Dictionary=frame.tool_fx.front()
	main.presentation_3d.rig.focus=Space.logic_to_world(effect.position)
	main.presentation_3d.rig.view_size=12.0
	for yaw in [0.0,35.0,125.0,215.0,305.0]:
		main.presentation_3d.rig.yaw_deg=yaw
		main.presentation_3d.rig.apply_pose()
		main.presentation_3d.refresh() # Original world/actor/occlusion refresh at each camera pose.
		for age in [0,60]:
			var copy:=frame.duplicate(true)
			copy.playback_tick=effect.clock_tick+age
			pool.update_frame(copy,false)
			var active: Array=_diag().active
			_check(active.size()==1 and active.front().age_ticks==age,"actual saved source admitted yaw="+str(yaw)+" age="+str(age))
			if active.is_empty():continue
			var point: Vector3=active.front().center+Vector3(0,0.3,0) if age==0 else active.front().smoke.front().position
			var screen: Vector2=main.presentation_3d.rig.camera.unproject_position(point)
			_check(screen.x>=40 and screen.x<=1240 and screen.y>=40 and screen.y<=680,"actual flash/smoke ROI lies inside Window yaw="+str(yaw)+" age="+str(age))
			pool._hide()
			await _capture("off0-yaw"+str(int(yaw))+"-age"+str(age))
			pool.update_frame(copy,false)
			await _capture("on-yaw"+str(int(yaw))+"-age"+str(age))
			pool._hide()
			await _capture("off1-yaw"+str(int(yaw))+"-age"+str(age))
			if DisplayServer.get_name()!="headless":
				var off0:=Image.load_from_file(captures[-3].path)
				var on:=Image.load_from_file(captures[-2].path)
				var off1:=Image.load_from_file(captures[-1].path)
				var visible:=_pixels(off0,on,screen,28)
				var stable:=_pixels(off0,off1,screen,28)
				_check(visible>20,"actual flash/smoke changes source ROI yaw="+str(yaw)+" age="+str(age)+" pixels="+str(visible))
				_check(stable<=2,"same-frame off control stable yaw="+str(yaw)+" age="+str(age)+" pixels="+str(stable))
				visibility_rows.append({"yaw_deg":yaw,"age_ticks":age,"source_point":point,"screen_point":screen,"on_changed_pixels":visible,"off_changed_pixels":stable,"off0":captures[-3].path,"on":captures[-2].path,"off1":captures[-1].path})
	_check(_state(main.battle_log)==original and main._snapshot_data()==live and var_to_bytes([main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,main.operators.map(func(op:OperatorUnit)->Array:return [op.global_position,op.hp,op.ammo,op.grenades]),enemy.global_position,enemy.hp])==backend,"actual off/on draw controls keep original recording/live positions/HP/ammo/inventory/sim")
	root.get_node("AudioDirector").pause_for_background()
	var file:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"source":effect,"visibility":visibility_rows,"captures":captures,"scope":"actual original grenade/fuse/bounce on explicitly placed open ground; paused ALERT and explicit saved-age copies; same-frame Window off/on/off ROI, five camera yaws. No native input/normal13/fullart/FINAL/A3/device acceptance"},"  "))
	file.close()
	print("TOOL_FX_VISIBLE_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures==0 else 1)
