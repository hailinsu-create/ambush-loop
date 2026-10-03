extends SceneTree
## Real rendered Window sizes; 200% means Window.content_scale_factor=2.
## Unlike simulate_narrow_layout, every bounds oracle uses the usable viewport.
const Guard := preload("res://scripts/test_storage_guard.gd")
var main: Node
var view: Node3D
var checks := 0
var failures := 0
var rows := []
var captures := []
var sample := ""
var input_rows := []

func _native_click(node: Control, button: int = 1, point: Vector2 = Vector2(INF,INF)) -> void:
	var logical := node.get_global_rect().get_center() if not point.is_finite() else point
	var screen: Vector2 = root.get_screen_transform()*logical
	var output := []
	var status := OS.execute("python3",[ProjectSettings.globalize_path("res://scripts/native_x11_test_input.py"),str(int(screen.x)),str(int(screen.y)),str(button)],output,true)
	_check(status==0,"native X11 helper exit0 "+str(output))
	input_rows.append({"id":sample,"path":str(node.get_path()),"physical_screen":[screen.x,screen.y],"button":button,"helper_exit":status})
	for _i in 5: await process_frame

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("VIEWPORT_HUD: "+sample+" "+message)

func _rect(value: Rect2) -> Array:
	return [value.position.x,value.position.y,value.size.x,value.size.y]

func _fits(node: Control, controls: Array) -> void:
	if not node.is_visible_in_tree(): return
	var rect := node.get_global_rect()
	var screen := root.get_visible_rect().grow(0.5)
	var fits := screen.encloses(rect)
	controls.append({"path":str(node.get_path()),"rect":_rect(rect),"fits":fits})
	_check(fits,"visible control inside actual viewport: "+str(node.get_path())+" "+str(rect))

func _buttons(node: Node, controls: Array) -> void:
	if node is Button or node is HSlider:
		_fits(node,controls)
	for child in node.get_children(): _buttons(child,controls)

func _text_rect(label: Label) -> Rect2:
	var rect := label.get_global_rect()
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var glyph := Vector2(font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x,font.get_height(font_size))
	if label.clip_text: glyph.x=minf(glyph.x,rect.size.x)
	if label.horizontal_alignment==HORIZONTAL_ALIGNMENT_RIGHT: rect.position.x+=maxf(0.0,rect.size.x-glyph.x)
	elif label.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER: rect.position.x+=maxf(0.0,(rect.size.x-glyph.x)*0.5)
	rect.size=glyph
	return rect

func _inspect(touch: bool, physical: Vector2i, scale_factor: float) -> void:
	var controls := []
	_check(root.size==physical,"requested physical Window size is real "+str(root.size))
	_check(root.content_scale_factor==scale_factor,"requested content scale factor is real")
	_buttons(main.get_node("HUD"),controls)
	_buttons(main.touch_hud,controls)
	_buttons(view._camera_controls,controls)
	for left in controls.size():
		for right in range(left+1,controls.size()):
			var a: Array = controls[left].rect
			var b: Array = controls[right].rect
			_check(not Rect2(a[0],a[1],a[2],a[3]).grow(-0.5).intersects(Rect2(b[0],b[1],b[2],b[3]).grow(-0.5)),"visible command hit rectangles do not overlap: "+controls[left].path+" / "+controls[right].path)
	if main.role_box.is_visible_in_tree(): _fits(main.role_box,controls)
	if main.title_label.is_visible_in_tree(): _fits(main.title_label,controls)
	if main.phase_chip.is_visible_in_tree(): _fits(main.phase_chip,controls)
	if main.status_label.is_visible_in_tree() and main.route_legend.is_visible_in_tree():
		for chip: Control in main.route_legend.get_children():
			_check(not _text_rect(main.status_label).intersects(chip.get_global_rect()),"SCOUT status glyphs do not overlap route chips")
			_check(not _text_rect(main.title_label).intersects(chip.get_global_rect()),"SCOUT title glyphs do not overlap route chips")
	if main.title_label.is_visible_in_tree() and main.phase_chip.is_visible_in_tree():
		_check(not _text_rect(main.title_label).intersects(_text_rect(main.phase_chip)),"title glyphs do not overlap phase glyphs")
	rows.append({"id":sample,"phase":main.phase_id(),"touch":touch,"requested_window":[physical.x,physical.y],"actual_window":[root.size.x,root.size.y],"content_scale_factor":root.content_scale_factor,"content_scale_size":root.content_scale_size,"usable_viewport":_rect(root.get_visible_rect()),"stretch_transform":str(root.get_stretch_transform()),"screen_transform":str(root.get_screen_transform()),"controls":controls})

func _layout(physical: Vector2i, scale_factor: float, touch: bool, label: String) -> void:
	sample=label+"_"+str(physical.x)+"_"+str(int(scale_factor*100))+"_"+("touch" if touch else "desktop")
	var before: Dictionary = main._snapshot_data().duplicate(true)
	root.size=physical
	root.position=Vector2i(0,0)
	root.content_scale_factor=scale_factor
	root.get_node("GameSettings").set_force_touch_hud(touch)
	for _i in 4: await process_frame
	main._update_hud()
	view.refresh()
	for _i in 3: await process_frame
	_inspect(touch,physical,scale_factor)
	_check(main._snapshot_data()==before,"resize/200%/input-mode never changes simulation")
	await RenderingServer.frame_post_draw
	# Root texture can retain the project base size under stretch/aspect keep.
	# Capture the actual private X11 screen and crop only the native window.
	var screen := DisplayServer.screen_get_image(root.current_screen)
	_check(screen!=null and not screen.is_empty(),"actual display capture available")
	var image := screen.get_region(Rect2i(root.position,root.size))
	_check(image.get_size()==physical,"captured image has actual physical dimensions "+str(image.get_size()))
	var path := "res://build/asset_review/pr15-runtime/viewport_"+sample+".png"
	_check(image.save_png(path)==OK,"capture saved")
	captures.append({"id":sample,"path":path,"sha256":FileAccess.get_sha256(path),"image_size":[image.get_width(),image.get_height()],"capture_source":"DisplayServer.screen_get_image native Window crop","root_texture_size":root.get_texture().get_image().get_size()})

func _modal_capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
	var path := "res://build/asset_review/pr15-runtime/viewport_"+label+".png"
	_check(image.save_png(path)==OK,"actual modal capture saved")
	captures.append({"id":label,"path":path,"sha256":FileAccess.get_sha256(path),"image_size":[image.get_width(),image.get_height()],"capture_source":"DisplayServer.screen_get_image native Window crop"})

func _native_commands() -> void:
	var before: Dictionary = main._snapshot_data().duplicate(true)
	if main.phase==main.Phase.REPLAY:
		var history: Array = main.replay.log.snapshots.duplicate(true)
		await _native_click(main.c2.portraits._cards[0])
		_check(main._snapshot_data()==before and main.replay.log.snapshots==history,"native compact historical portrait remains read-only")
	if main.phase==main.Phase.WATCHING:
		await _native_click(main.touch_hud._btns.pause)
		_check(main.sim.paused and main.phase==main.Phase.WATCHING,"actual 200% mouse pauses ALERT")
		await _native_click(main.touch_hud._btns.pause)
		_check(not main.sim.paused and main._snapshot_data()==before,"actual 200% mouse resumes identical ALERT")
	elif main.phase in [main.Phase.SETUP,main.Phase.SWEEP]:
		if not main._can_edit_equipment():
			_check(main.touch_hud._btns.bag.disabled,"unavailable/dead selected actor has a visibly locked bag")
			for index in main.operators.size():
				var op = main.operators[index]
				if op.alive and op.visible and not op.locked:
					await _native_click(main.c2.portraits._cards[index])
					_check(main.selected==op,"native 200% portrait selects actual living operator")
					break
			before=main._snapshot_data().duplicate(true)
		await _native_click(main.touch_hud._btns.bag)
		_check(main.backpack_panel.is_open(),"actual 200% mouse opens backpack")
		if main.backpack_panel.is_open():
			var controls := []
			_fits(main.backpack_panel._panel,controls)
			_fits(main.backpack_panel._close_btn,controls)
			await _modal_capture(sample+"_backpack")
			await _native_click(main.backpack_panel._close_btn)
			_check(not main.backpack_panel.is_open() and main._snapshot_data()==before,"native close backpack preserves command state")
	if main.phase!=main.Phase.REPLAY:
		var settings=root.get_node("GameSettings")
		var audio_before := [settings.music_volume,settings.sfx_volume]
		await _native_click(main.get_node("HUD/Root/CompactMenu"))
		for _i in 18: await process_frame
		_check(main.pause_overlay.is_open(),"actual 200% mouse opens settings")
		if main.pause_overlay.is_open():
			var controls := []
			_fits(main.pause_overlay._panel,controls)
			_fits(main.pause_overlay._close_btn,controls)
			# Actual wheel events expose the lower settings, with Continue fixed.
			var scroll_rect: Rect2 = main.pause_overlay._scroll.get_global_rect()
			for _i in 8: await _native_click(main.pause_overlay._scroll,5,Vector2(scroll_rect.end.x-6.0,scroll_rect.get_center().y))
			_check(main.pause_overlay._scroll.scroll_vertical>0,"native wheel reaches lower settings")
			_check([settings.music_volume,settings.sfx_volume]==audio_before,"scrollbar wheel preserves audio preferences")
			await _modal_capture(sample+"_settings")
			await _native_click(main.pause_overlay._close_btn)
			_check(not main.pause_overlay.is_open() and main._snapshot_data()==before,"native Continue restores identical state")
	await _native_click(view._camera_toggle)
	view.refresh()
	await process_frame
	_check(view._camera_panel.is_visible_in_tree(),"actual 200% mouse opens camera palette")
	var controls := []
	_buttons(view._camera_controls,controls)
	await _modal_capture(sample+"_camera")
	await _native_click(view._camera_toggle)
	view.refresh()
	_check(not view._camera_panel.is_visible_in_tree() and main._snapshot_data()==before,"native camera close preserves state")

func _matrix(label: String) -> void:
	for physical in [Vector2i(1280,720),Vector2i(1600,720)]:
		for scale_factor in [1.0,2.0]:
			for touch in [false,true]:
				await _layout(physical,scale_factor,touch,label)
				if physical.x==1600 and scale_factor==2.0 and not touch: await _native_commands()

func _run() -> void:
	if DisplayServer.get_name()=="headless":
		_check(false,"requires actual rendering/display, not a headless size fixture")
		quit(2)
		return
	root.size=Vector2i(1280,720)
	var settings=root.get_node("GameSettings")
	settings.mark_tutorial_seen("yard")
	settings.set_force_touch_hud(false)
	settings.pending_level_id="yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main=current_scene
	view=main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	await _matrix("scout")
	root.content_scale_factor=1.0
	settings.set_force_touch_hud(false)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	main.raid_force_alarm()
	_check(main.phase==main.Phase.WATCHING,"original ALERT entered")
	await _matrix("alert")
	root.content_scale_factor=1.0
	settings.set_force_touch_hud(false)
	var ticks := 0
	while main.phase==main.Phase.WATCHING and ticks<12000:
		main._sim_tick()
		ticks+=1
	_check(main.phase==main.Phase.SWEEP and main.sim.tick==1056,"reference original yard first wave reaches SWEEP1056")
	await _matrix("sweep")
	root.content_scale_factor=1.0
	settings.set_force_touch_hud(false)
	main._on_replay_pressed()
	_check(main.phase==main.Phase.REPLAY,"production history entry")
	await _matrix("replay")
	# Other level headers are actual production SCOUT loads, not multi-wave
	# visual acceptance of those battlefields.
	for level in ["warehouse","pump","railcut","depot","radio"]:
		settings.mark_tutorial_seen(level)
		root.content_scale_factor=1.0
		settings.set_force_touch_hud(false)
		main._load_level(level,false,false)
		for factor in [1.0,2.0]: await _layout(Vector2i(1600,720),factor,false,level+"_scout")
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/viewport-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures,"native_inputs":input_rows,"definition":"200% is Window.content_scale_factor=2; physical Window crop and usable viewport asserted; private X11 XTest mouse events"},"  "))
	print("VIEWPORT_HUD_TEST checks=%d failures=%d samples=%d" % [checks,failures,rows.size()])
	quit(0 if failures==0 else 1)
