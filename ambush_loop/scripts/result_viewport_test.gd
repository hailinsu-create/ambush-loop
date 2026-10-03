extends "res://scripts/viewport_hud_test.gd"
## Actual domain terminal transitions; no direct FAILED/WON assignment.
var result_rows := []

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		print("RESULT_VIEWPORT_FAIL "+sample+" "+message)

func _terminal(won: bool) -> void:
	root.content_scale_factor=1.0
	root.get_node("GameSettings").set_force_touch_hud(false)
	main._load_level("yard",false,false)
	main.raid_prepare_ref([1,2,5] if won else [],[90.0,180.0,180.0] if won else [])
	main.raid_force_alarm()
	var ticks := 0
	while main.phase==main.Phase.WATCHING and ticks<12000:
		main._sim_tick()
		ticks+=1
	if won and main.phase==main.Phase.SWEEP:
		main.raid_vacuum_loot()
		main._on_sweep_commit()
		while main.phase==main.Phase.WATCHING and ticks<12000:
			main._sim_tick()
			ticks+=1
		if main.phase==main.Phase.SWEEP:
			main.raid_vacuum_loot()
			main._on_sweep_commit()
	_check(main.phase==(main.Phase.WON if won else main.Phase.FAILED),"actual authored domain terminal reached")
	result_rows.append({"terminal":"won" if won else "failed","tick":main.sim.tick,"events":main.battle_log.events.size(),"waves":main.raid.waves_cleared,"reason":main.fail_reason})

func _result_bounds(moment: String) -> void:
	var controls := []
	_fits(main.result_panel,controls)
	_fits(main.continue_button,controls)
	if main.dossier_button!=null: _fits(main.dossier_button,controls)
	_check(not main.desktop_command_bars_visible(),"terminal hides command rails")
	result_rows.append({"sample":sample,"moment":moment,"controls":controls,"result_text":main.result_label.text,"dossier_text":main.fail_dossier_text()})

func _terminal_matrix(won: bool) -> void:
	var text: String = main.result_label.text
	var dossier: String = main.fail_dossier_text()
	for physical in [Vector2i(1280,720),Vector2i(1600,720)]:
		for factor in [1.0,2.0]:
			for touch in [false,true]:
				await _layout(physical,factor,touch,"result_won" if won else "result_failed")
				_result_bounds("closed")
				if not won and root.get_visible_rect().encloses(main.dossier_button.get_global_rect()):
					var before: Dictionary = main._snapshot_data().duplicate(true)
					await _native_click(main.dossier_button)
					_check(main._dossier_open,"native mouse opens real failure dossier")
					_result_bounds("dossier_open")
					await _modal_capture(sample+"_dossier")
					await _native_click(main.dossier_button)
					_check(not main._dossier_open and main._snapshot_data()==before,"native dossier close keeps complete terminal state")
				_check(main.result_label.text==text and main.fail_dossier_text()==dossier,"resize/input preference preserves complete result and dossier text")
	# Positive candidate must expose actual scroll and a working native CTA.
	var scroll = main.result_panel.find_child("ResultScroll",true,false)
	_check(scroll is ScrollContainer,"bounded result content has a real scroll container")
	if scroll is ScrollContainer:
		var before: Dictionary = main._snapshot_data().duplicate(true)
		var rect: Rect2 = scroll.get_global_rect()
		for _i in 10: await _native_click(scroll,5,Vector2(rect.end.x-6,rect.get_center().y))
		_check(scroll.scroll_vertical>0,"native wheel reaches long terminal content")
		_check(main._snapshot_data()==before,"result scrolling preserves complete terminal state")
		await _modal_capture(sample+"_scrolled")
	if root.get_visible_rect().encloses(main.continue_button.get_global_rect()):
		var loop_before: int = main.loop_index
		await _native_click(main.continue_button)
		for _i in 40: await process_frame
		_check(main.phase==main.Phase.SETUP and main.level.level_id==("warehouse" if won else "yard"),"native Continue follows original retry/next-level route")
		if not won: _check(main.loop_index==loop_before+1,"native retry advances original generation exactly once")

func _run() -> void:
	root.size=Vector2i(1280,720)
	var settings=root.get_node("GameSettings")
	settings.mark_tutorial_seen("yard")
	settings.mark_tutorial_seen("warehouse")
	settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	view=main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	for won in [false,true]:
		await _terminal(won)
		await _terminal_matrix(won)
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/result-viewport-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":result_rows,"captures":captures,"native_inputs":input_rows},"  "))
	print("RESULT_VIEWPORT_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
