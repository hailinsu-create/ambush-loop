extends "res://scripts/shot_fx_pool_test.gd"
## Actual backend shot, farther LOS fixture, same-frame pixel on/off controls.
var visibility_rows := []

func _pixels(before: Image, after: Image, centre: Vector2, radius: int) -> int:
	var changed:=0
	for y in range(maxi(0,int(centre.y)-radius),mini(after.get_height(),int(centre.y)+radius+1)):
		for x in range(maxi(0,int(centre.x)-radius),mini(after.get_width(),int(centre.x)+radius+1)):
			var a:=before.get_pixel(x,y)
			var b:=after.get_pixel(x,y)
			if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))>0.1: changed+=1
	return changed

func _run_cases() -> void:
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	root.content_scale_factor=1.0
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
	_bind_pool()
	var op: OperatorUnit=pair[0]
	var enemy: EnemyRunner=pair[1]
	enemy.global_position=op.global_position+Vector2(0,128)
	op.apply_weapon("kar98k",true)
	_check(main.grid.has_los(op.global_position,enemy.global_position),"farther original shot fixture has real grid LOS")
	var event:=_event(op,enemy)
	_check(main._try_fire_with_recorded_fx(op,enemy,event) and event.payload.has("fx"),"actual farther original backend shot succeeds")
	if not event.payload.has("fx"):return
	var frame:=ViewState.capture(main)
	var original:=_state(main.battle_log)
	var live: Dictionary=main._snapshot_data()
	var sim_tuple := [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,enemy.hp]
	main.presentation_3d.rig.focus=Space.logic_to_world((op.global_position+enemy.global_position)*0.5)
	main.presentation_3d.rig.view_size=12.0
	for yaw in [0.0,35.0,125.0,215.0,305.0]:
		main.presentation_3d.rig.yaw_deg=yaw
		main.presentation_3d.rig.apply_pose()
		main.presentation_3d.refresh()
		var active: Array=_diag().active
		_check(active.size()==1,"farther shot original presenter active yaw="+str(yaw))
		if active.is_empty():continue
		var muzzle: Vector3=active[0].muzzle
		var target: Vector3=active[0].target
		var camera: Camera3D=main.presentation_3d.rig.camera
		pool._hide() # Explicit same-frame off control, source is unchanged.
		await _capture("control-off-yaw"+str(int(yaw)))
		pool.update_frame(frame)
		await _capture("actual-shot-yaw"+str(int(yaw)))
		if DisplayServer.get_name()!="headless":
			var before:=Image.load_from_file(captures[-2].path)
			var after:=Image.load_from_file(captures[-1].path)
			var points := {"muzzle":camera.unproject_position(muzzle),"tracer_midpoint":camera.unproject_position((muzzle+target)*0.5),"impact":camera.unproject_position(target)}
			var values := {"muzzle":_pixels(before,after,points.muzzle,14),"tracer_midpoint":_pixels(before,after,points.tracer_midpoint,6),"impact":_pixels(before,after,points.impact,22)}
			_check(values.muzzle>8,"actual rendered muzzle changes source ROI yaw="+str(yaw)+" pixels="+str(values.muzzle))
			_check(values.tracer_midpoint>2,"actual rendered tracer changes independent midpoint ROI yaw="+str(yaw)+" pixels="+str(values.tracer_midpoint))
			_check(values.impact>8,"actual rendered impact changes saved victim torso ROI yaw="+str(yaw)+" pixels="+str(values.impact))
			visibility_rows.append({"yaw_deg":yaw,"pixels_changed":values,"screen_points":points,"control_off_image":captures[-2].path,"actual_shot_image":captures[-1].path})
	for age in [0,2,5,8,9,0]:
		var copy:=frame.duplicate(true)
		copy.playback_tick=event.playback_tick+age
		pool.update_frame(copy)
		var active: Array=_diag().active
		_check(active.is_empty() if age==9 else active.size()==1 and active[0].muzzle_visible==(age<3) and active[0].tracer_visible==(age<6) and active[0].impact_visible,"farther real source saved lifetime and restore age="+str(age))
		await _capture("actual-lifetime-age"+str(age))
	_check(_state(main.battle_log)==original and main._snapshot_data()==live and [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum,op.ammo,enemy.hp]==sim_tuple,"same-frame draw controls and saved ages never change actual original source/live/HP/ammo/sim")
	rows.append({"case":"actual-farther-shot-pixel-controls","event":event,"visibility":visibility_rows,"scope":"explicit grant/position/API fixture plus actual Window on/off pixels, five camera yaws; no normal battle/native input/A3 acceptance"})
