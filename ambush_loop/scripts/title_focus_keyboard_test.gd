extends "res://scripts/title_menu_viewport_test.gd"
## Natural native keyboard only. Unlock/Continue state are isolated API fixtures.
var focus_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("TITLE_FOCUS_FAIL " + sample + " " + message)
		if OS.get_environment("AMBUSH_TITLE_FOCUS_SCOPE") != "negative":
			_save_focus()
			print("TITLE_FOCUS_TEST checks=%d failures=%d aborted=true" % [checks,failures])
			quit(1)

func _settle(frames: int = 3) -> void:
	await create_timer(0.2).timeout
	for i in frames: await process_frame
	for i in 2:
		await process_frame
		await RenderingServer.frame_post_draw

func _controls(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	for item in node.find_children("*", "Control", true, false):
		var control := item as Control
		if control.focus_mode == Control.FOCUS_NONE or not control.is_visible_in_tree(): continue
		if control is BaseButton and control.disabled: continue
		result.append(control)
	return result

func _focus_in(node: Node, label: String) -> void:
	var owner := root.gui_get_focus_owner()
	var inside := is_instance_valid(owner) and node.is_ancestor_of(owner) and owner.is_visible_in_tree()
	_check(inside, label + " keeps focus in top layer")
	if inside: _check(_hit_visible(owner), label + " focus is reachable through its scroll surface")
	focus_rows.append({"id":sample,"step":label,"focus":str(owner.get_path()) if is_instance_valid(owner) else "none","inside":inside})

func _cycle(node: Node, label: String) -> void:
	var controls := _controls(node)
	_check(not controls.is_empty(), label + " has enabled focusable controls")
	_focus_in(node, label + " initial")
	for i in controls.size() + 2:
		await _key("Tab")
		_focus_in(node, label + " Tab" + str(i))
	for i in controls.size() + 2:
		await _key("shift_tab")
		_focus_in(node, label + " ShiftTab" + str(i))

func _tab_to(control: Control, layer: Node) -> void:
	for i in _controls(layer).size() + 3:
		if root.gui_get_focus_owner() == control: break
		await _key("Tab")
		_focus_in(layer,"navigate " + control.name)
	_check(root.gui_get_focus_owner() == control,"natural Tab reaches " + control.name)

func _visible_layers() -> Array:
	var result := []
	for layer in [main._quit,main._brief,main._howto,main._mission]:
		if layer.visible: result.append(str(layer.get_path()))
	if main._journal.is_open(): result.append("journal")
	if main.pause_ui.is_open(): result.append("settings")
	return result

func _settings_case(exact_negative: bool) -> void:
	await _key("Escape")
	_check(main._quit.visible,"native Escape opens original Quit")
	await _key("Tab")
	_check(root.gui_get_focus_owner() == _button(main._quit,"设置"),"natural Tab selects Quit settings")
	await _key("Return")
	_check(main.pause_ui.is_open() and not main._quit.visible,"natural Return opens settings and closes Quit")
	_focus_in(main.pause_ui,"settings opened")
	await _modal_capture(sample + "_settings")
	# Reproduce parent fresh-state sequence; do not rely on Tab5 when Continue exists.
	if exact_negative or not settings.has_progress():
		for i in 5: await _key("Tab")
		_focus_in(main.pause_ui,"settings after five natural Tabs")
		await _key("Return")
		_check(main.pause_ui.is_open() and _visible_layers() == ["settings"],"Return acts only on settings, without opening background mission")
		await _key("Escape")
		_check(not main.pause_ui.is_open() and _visible_layers().is_empty(),"Back closes highest settings layer")
		await _modal_capture(sample + "_settings_back")
		if exact_negative: return
		# Re-enter via the same original keyboard path for full dynamic Tab cycle.
		await _key("Escape")
		await _key("Tab")
		await _key("Return")
	await _cycle(main.pause_ui,"settings cycle")
	await _tab_to(main.pause_ui._close_btn,main.pause_ui)
	await _key("Return")
	_check(not main.pause_ui.is_open() and _visible_layers().is_empty(),"natural settings Continue closes only top layer")
	_focus_in(main._menu,"settings return")

func _brief_case(index: int, natural: bool) -> void:
	if natural:
		await _tab_to(main.start_btn,main._menu)
		await _key("Return")
	else: await _click(main.start_btn)
	_check(main._mission.visible,"original Start opens mission list")
	if natural:
		await _cycle(main._mission,"mission list")
		await _tab_to(main._mission_btns[index],main._mission)
		await _key("Return")
	else: await _click(main._mission_btns[index])
	_check(main._brief.visible and not main._mission.visible,"original mission action opens briefing")
	if natural: await _cycle(main._brief,"briefing " + str(index))
	await _modal_capture(sample + "_brief_" + ("keyboard_" if natural else "mouse_") + str(index))
	await _key("Escape")
	_check(_visible_layers().is_empty() and current_scene == main,"brief Escape keeps original return-to-title route")
	_focus_in(main._menu,"brief return " + str(index))
	await _modal_capture(sample + "_brief_back_" + ("keyboard_" if natural else "mouse_") + str(index))

func _pages_case() -> void:
	await _tab_to(main.help_btn,main._menu)
	await _key("Return")
	_check(main._howto.visible,"natural Return opens Help")
	await _cycle(main._howto,"Help")
	await _key("Escape")
	_check(_visible_layers().is_empty(),"Help Escape returns without cascading Quit")
	await _tab_to(main._journal_btn,main._menu)
	await _key("Return")
	_check(main._journal.is_open(),"natural Return opens Journal")
	await _cycle(main._journal,"Journal")
	await _key("Return")
	_check(_visible_layers().is_empty(),"Journal native Return closes original layer")
	await _key("Escape")
	await _cycle(main._quit,"Quit")
	await _tab_to(_button(main._quit,"取消"),main._quit)
	await _key("Return")
	_check(_visible_layers().is_empty(),"Quit native Cancel returns without quitting")

func _save_focus() -> void:
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/title-focus-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"focus_rows":focus_rows,"captures":captures,"native_inputs":input_rows,"scope":"Natural XTest Tab/ShiftTab/Return/Escape; isolated API unlock/Continue fixtures, no gameplay wins; original brief Escape returns title."},"  "))

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("TITLE_FOCUS requires native rendered verification")
		quit(2)
		return
	settings = root.get_node("GameSettings")
	root.position = Vector2i.ZERO
	root.size = Vector2i(1600,720)
	root.content_scale_factor = 2.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	await _title()
	if OS.get_environment("AMBUSH_TITLE_FOCUS_SCOPE") == "negative":
		sample = "negative_settings_fresh_1600_200"
		_check(main.continue_btn.disabled and not settings.has_progress(),"fresh isolated Continue disabled")
		await _settings_case(true)
		await _title()
		sample = "negative_mouse_yard_brief_escape"
		await _brief_case(0,false)
	else:
		var cases := [[Vector2i(1280,720),1.0,false],[Vector2i(1280,720),2.0,true],[Vector2i(1600,720),1.0,true],[Vector2i(1600,720),2.0,false]]
		for data in cases:
			for has_continue in [false,true]:
				# Only the first case is truly fresh. Clear progress through original API.
				if has_continue: settings.record_win("depot",3,false)
				else:
					if FileAccess.file_exists(settings.PROGRESS_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.PROGRESS_PATH)) # Isolated guard only; fixture reset, not player flow.
				root.size = data[0]
				root.position = Vector2i.ZERO
				root.content_scale_factor = data[1]
				settings.set_force_touch_hud(data[2])
				await _title()
				sample = "focus_" + str(data[0].x) + "_" + str(int(data[1]*100)) + "_" + ("touch" if data[2] else "desktop") + "_" + ("continue" if has_continue else "fresh")
				_check(settings.has_progress() == has_continue and main.continue_btn.disabled == (not has_continue),"Continue fixture matches original title controls")
				var progress := _progress_hash()
				if root.gui_get_focus_owner() == null: await _key("Tab") # Natural initial focus, no programmatic grab_focus fixture.
				await _cycle(main._menu,"main menu")
				await _settings_case(false)
				await _brief_case(0,false)
				await _pages_case()
				if has_continue:
					for index in 6: await _brief_case(index,true)
				_check(_progress_hash() == progress,"all child keyboard actions preserve original progress bytes")
	root.get_node("AudioDirector").pause_for_background()
	_save_focus()
	print("TITLE_FOCUS_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
