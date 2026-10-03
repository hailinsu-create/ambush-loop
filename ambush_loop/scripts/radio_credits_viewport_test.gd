extends "res://scripts/viewport_hud_test.gd"
## Reference radio fixture, actual three waves, native original CTA and exit.
var finished_count := 0

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		print("RADIO_CREDITS_FAIL "+sample+" "+message)

func _button() -> Button:
	for node in main.credits_overlay.find_children("*","Button",true,false):
		if node.text=="返回标题": return node
	return null

func _word() -> Label:
	for node in main.credits_overlay.find_children("*","Label",true,false):
		if node.text=="AMBUSH LOOP": return node
	return null

func _title() -> bool:
	return current_scene!=null and current_scene.scene_file_path=="res://scenes/title.tscn"

func _native_escape(label: String) -> void:
	var output := []
	var status:=OS.execute("python3",[ProjectSettings.globalize_path("res://scripts/native_x11_test_input.py"),"key","Escape"],output,true)
	_check(status==0,"native Escape helper exit0 "+str(output))
	input_rows.append({"id":label,"key":"Escape","helper_exit":status})
	for _i in 10: await process_frame

func _radio() -> void:
	root.content_scale_factor=1.0
	root.size=Vector2i(1280,720)
	root.position=Vector2i.ZERO
	var settings=root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	settings.mark_tutorial_seen("radio")
	settings.pending_level_id="radio"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	view=main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	main.raid_prepare_ref([1,4,5],[270.0,90.0,270.0])
	main._try_place_tripwire(main.grid.cell_to_world_center(Vector2i(7,11)))
	main.raid_force_alarm()
	var ends := []
	for wave in 3:
		var steps:=0
		while main.phase==main.Phase.WATCHING and steps<12000:
			main._sim_tick()
			steps+=1
		_check(main.phase==main.Phase.SWEEP,"actual original radio wave clears "+str(wave))
		ends.append(main.sim.tick)
		if main.phase!=main.Phase.SWEEP: return
		main.raid_vacuum_loot()
		main._on_sweep_commit()
	_check(main.phase==main.Phase.WON and main.raid.waves_cleared==3,"actual radio three-wave extraction reaches original WON")
	_check(main.battle_log.terminal_tick==1413 and main.battle_log.events.size()==51,"original radio battle terminal1413 and51 events retained")
	_check(main.continue_button.text=="查看致谢","real last-level CTA is credits")
	rows.append({"stage":"radio_terminal","waves":3,"wave_ends":ends,"battle_terminal_tick":main.battle_log.terminal_tick,"events":main.battle_log.events.size(),"result_text":main.result_label.text,"battle_footer":main.result_stats.text})
	finished_count=0
	main.credits_overlay.finished.connect(func() -> void: finished_count+=1)
	await _native_click(main.continue_button)
	_check(main.credits_overlay.is_open(),"native original WON CTA opens real credits")

func _layout_credits(physical: Vector2i,factor: float,touch: bool) -> void:
	sample="radio_credits_"+str(physical.x)+"_"+str(int(factor*100))+"_"+("touch" if touch else "desktop")
	var before: Dictionary=main._snapshot_data().duplicate(true)
	var text: String=main.result_label.text
	var footer: String=main.result_stats.text
	var body: Label=main.credits_overlay.find_child("Body",true,false)
	var recap: String=body.text
	root.size=physical
	root.position=Vector2i.ZERO
	root.content_scale_factor=factor
	root.get_node("GameSettings").set_force_touch_hud(touch)
	for _i in 4: await process_frame
	main._update_hud()
	view.refresh()
	for _i in 3: await process_frame
	_check(root.size==physical and root.content_scale_factor==factor,"actual physical window and scale applied")
	var controls := []
	_fits(_word(),controls)
	_fits(_button(),controls)
	_check(root.get_visible_rect().grow(0.5).encloses(_text_rect(_word())),"credits title glyph stays inside usable viewport")
	_check(body.text==recap and main.result_label.text==text and main.result_stats.text==footer and main._snapshot_data()==before,"credits resize/preference retains full recap, original battle footer and command state")
	_check(main.credits_overlay.find_child("NightRail",true,false).get_child_count()==6,"all original six-night labels retained")
	rows.append({"id":sample,"window":[root.size.x,root.size.y],"scale":factor,"usable_viewport":_rect(root.get_visible_rect()),"controls":controls,"recap":body.text,"battle_footer":footer})
	await _modal_capture(sample)

func _run() -> void:
	await _radio()
	if main.phase!=main.Phase.WON: quit(2); return
	for physical in [Vector2i(1280,720),Vector2i(1600,720)]:
		for factor in [1.0,2.0]:
			for touch in [false,true]: await _layout_credits(physical,factor,touch)
	var scroll=main.credits_overlay.find_child("CreditsScroll",true,false)
	_check(scroll is ScrollContainer,"long credits body has a bounded scroll container")
	if scroll is ScrollContainer:
		var before: Dictionary=main._snapshot_data().duplicate(true)
		var rect: Rect2=scroll.get_global_rect()
		for _i in 20: await _native_click(scroll,5,Vector2(rect.end.x-6,rect.get_center().y))
		var bar: VScrollBar=scroll.get_v_scroll_bar()
		_check(scroll.scroll_vertical>0 and bar.value>=bar.max_value-bar.page-1,"native wheel reaches the complete long credits body")
		_check(main._snapshot_data()==before,"credits wheel cannot change underlying battle or selection")
		await _modal_capture(sample+"_scrolled")
	await _native_click(_button())
	for _i in 10: await process_frame
	_check(_title(),"native200 return button reaches actual title scene")
	if not _title():
		await _native_escape("negative_cleanup_back")
		_check(_title(),"original native Back remains a usable cleanup route")
	# Independent original100 positive route, without bypassing any credits CTA.
	await _radio()
	await _layout_credits(Vector2i(1600,720),1.0,false)
	await _native_click(_button())
	for _i in 10: await process_frame
	_check(_title() and finished_count==1,"native100 button follows original finished signal and title route once")
	# A fresh real radio terminal exercises native Escape at200.
	await _radio()
	await _layout_credits(Vector2i(1600,720),2.0,false)
	await _native_escape("radio_credits_200_back")
	_check(_title(),"native200 Escape follows original Back-to-title route")
	root.get_node("AudioDirector").pause_for_background()
	var file:=FileAccess.open("res://build/asset_review/pr15-runtime/radio-credits-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures,"native_inputs":input_rows},"  "))
	print("RADIO_CREDITS_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures==0 else 1)
