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
	var glyph := label.get_minimum_size()
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
	if main.role_box.is_visible_in_tree(): _fits(main.role_box,controls)
	if main.title_label.is_visible_in_tree(): _fits(main.title_label,controls)
	if main.phase_chip.is_visible_in_tree(): _fits(main.phase_chip,controls)
	if main.status_label.is_visible_in_tree() and main.route_legend.is_visible_in_tree():
		for chip: Control in main.route_legend.get_children():
			_check(not _text_rect(main.status_label).intersects(chip.get_global_rect()),"SCOUT status glyphs do not overlap route chips")
	if main.title_label.is_visible_in_tree() and main.phase_chip.is_visible_in_tree():
		_check(not _text_rect(main.title_label).intersects(_text_rect(main.phase_chip)),"title glyphs do not overlap phase glyphs")
	rows.append({"id":sample,"phase":main.phase_id(),"touch":touch,"requested_window":[physical.x,physical.y],"actual_window":[root.size.x,root.size.y],"content_scale_factor":root.content_scale_factor,"content_scale_size":root.content_scale_size,"usable_viewport":_rect(root.get_visible_rect()),"stretch_transform":str(root.get_stretch_transform()),"controls":controls})

func _layout(physical: Vector2i, scale_factor: float, touch: bool, label: String) -> void:
	sample=label+"_"+str(physical.x)+"_"+str(int(scale_factor*100))+"_"+("touch" if touch else "desktop")
	var before: Dictionary = main._snapshot_data().duplicate(true)
	root.size=physical
	root.content_scale_factor=scale_factor
	root.get_node("GameSettings").set_force_touch_hud(touch)
	for _i in 4: await process_frame
	main._update_hud()
	view.refresh()
	for _i in 3: await process_frame
	_inspect(touch,physical,scale_factor)
	_check(main._snapshot_data()==before,"resize/200%/input-mode never changes simulation")
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.get_size()==physical,"captured image has actual physical dimensions "+str(image.get_size()))
	var path := "res://build/asset_review/pr15-runtime/viewport_"+sample+".png"
	_check(image.save_png(path)==OK,"capture saved")
	captures.append({"id":sample,"path":path,"sha256":FileAccess.get_sha256(path),"image_size":[image.get_width(),image.get_height()]})

func _matrix(label: String) -> void:
	for physical in [Vector2i(1280,720),Vector2i(1600,720)]:
		for scale_factor in [1.0,2.0]:
			for touch in [false,true]: await _layout(physical,scale_factor,touch,label)

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
	main.raid_prepare_ref([1,2,3],[90.0,90.0,90.0])
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
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/viewport-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures,"definition":"200% is Window.content_scale_factor=2; real root texture dimensions and usable viewport asserted"},"  "))
	print("VIEWPORT_HUD_TEST checks=%d failures=%d samples=%d" % [checks,failures,rows.size()])
	quit(0 if failures==0 else 1)
