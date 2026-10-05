extends "res://scripts/viewport_hud_test.gd"
## Native title journey; progress unlocks are isolated API fixtures, not wins.
var settings
var quit_received := false
var exit_kind := "button"

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("TITLE_MENU_FAIL " + sample + " " + message)

func _settle(frames: int = 12) -> void:
	await create_timer(0.18).timeout # Production modal fades last 0.15 seconds.
	for i in frames: await process_frame
	for draw in 2:
		await process_frame
		await RenderingServer.frame_post_draw

func _key(name: String) -> void:
	var output := []
	var status := OS.execute("python3", [ProjectSettings.globalize_path("res://scripts/native_x11_test_input.py"), "key", name], output, true)
	_check(status == 0, "native key helper exit0 " + name + " " + str(output))
	input_rows.append({"id": sample, "key": name, "helper_exit": status})
	await _settle()

func _panel(layer: CanvasLayer) -> Control:
	for child in layer.get_children():
		if child is PanelContainer: return child
	return null

func _button(layer: Node, text: String) -> Button:
	for node in layer.find_children("*", "Button", true, false):
		if node.text == text: return node
	return null

func _scroll(node: Node) -> ScrollContainer:
	for item in node.find_children("*", "ScrollContainer", true, false):
		if item.is_visible_in_tree(): return item
	return null

func _hit_visible(node: Control) -> bool:
	if node == null or not node.is_visible_in_tree(): return false
	var bounds: Rect2 = root.get_visible_rect()
	var ancestor := node.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			bounds = bounds.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return bounds.grow(0.5).encloses(node.get_global_rect())

func _reach(node: Control) -> void:
	_check(node != null, "original control exists")
	if node == null: return
	var ancestor := node.get_parent()
	var scroller: ScrollContainer
	while ancestor != null:
		if ancestor is ScrollContainer:
			scroller = ancestor
			break
		ancestor = ancestor.get_parent()
	for step in 80:
		if _hit_visible(node) or scroller == null: break
		var at: Rect2 = scroller.get_global_rect()
		var before := scroller.scroll_vertical
		await _native_click(scroller, 4 if node.get_global_rect().position.y < at.position.y else 5, at.get_center())
		if scroller.scroll_vertical == before: break
	_check(_hit_visible(node), "original control becomes fully reachable " + str(node.get_path()) + " " + str(node.get_global_rect()))
	rows.append({"id": sample + "_reach", "control": str(node.get_path()), "rect": _rect(node.get_global_rect()), "fully_reachable": _hit_visible(node), "scroll": scroller.scroll_vertical if scroller != null else 0})

func _click(node: Control) -> void:
	if node == null: return
	await _reach(node)
	await _native_click(node)
	await _settle()

func _scroll_end(node: Node, label: String) -> void:
	var scroller := _scroll(node)
	_check(scroller != null, label + " has a real scroll surface")
	if scroller == null: return
	var bar := scroller.get_v_scroll_bar()
	for step in 100:
		if bar.value + bar.page >= bar.max_value - 0.5: break
		var previous := bar.value
		await _native_click(scroller, 5, scroller.get_global_rect().get_center())
		if bar.value == previous: break
	_check(bar.value + bar.page >= bar.max_value - 0.5, label + " native wheel reaches content end")
	rows.append({"id": sample + "_" + label + "_scroll", "value": bar.value, "page": bar.page, "max": bar.max_value})

func _layout_note(layer: CanvasLayer, label: String) -> void:
	var controls := []
	_fits(_panel(layer), controls)
	rows.append({"id": sample + "_" + label, "window": [root.size.x, root.size.y], "scale": root.content_scale_factor, "viewport": _rect(root.get_visible_rect()), "controls": controls})

func _cleanup() -> void:
	if main._modal_tween != null: main._modal_tween.kill()
	for layer in [main._brief, main._howto, main._mission, main._quit]: layer.visible = false
	main._journal.dismiss()
	main.pause_ui.dismiss()

func _title() -> void:
	change_scene_to_file("res://scenes/title.tscn")
	await process_frame
	await process_frame
	main = current_scene
	await create_timer(0.85).timeout
	await _settle()

func _progress_hash() -> String:
	return FileAccess.get_sha256(settings.PROGRESS_PATH) if FileAccess.file_exists(settings.PROGRESS_PATH) else "absent"

func _pages() -> void:
	var before := _progress_hash()
	await _click(main.help_btn)
	_check(main._howto.visible, "native Help opens original instructions")
	if not main._howto.visible:
		rows.append({"id": sample + "_help", "entry": "diagnostic fallback after failed native entry"})
		main._on_help()
		await _settle()
	_layout_note(main._howto, "help")
	var help_body: Label
	for label in main._howto.find_children("*", "Label", true, false):
		if label.text == main.HOWTO: help_body = label
	_check(help_body != null and help_body.text == main.HOWTO, "complete original HOWTO text retained")
	await _scroll_end(main._howto, "help")
	await _modal_capture(sample + "_help_end")
	await _click(_button(main._howto, "关闭"))
	_check(not main._howto.visible and not main._quit.visible, "native Help close returns to menu without quit")
	_cleanup()
	await _click(main.help_btn)
	await _key("Escape")
	_check(not main._howto.visible and not main._quit.visible, "native Escape closes Help first")
	_cleanup()
	await _click(main._journal_btn)
	_check(main.journal_visible(), "native Journal opens original dossier")
	if not main.journal_visible():
		main.open_journal()
		await _settle()
	_layout_note(main._journal, "journal")
	_check(main._journal._board.get_child_count() == 6, "dossier retains all six original nights")
	await _scroll_end(main._journal, "journal")
	await _modal_capture(sample + "_journal_end")
	await _click(_button(main._journal, "关闭"))
	_check(not main.journal_visible(), "native dossier close returns")
	_cleanup()
	await _click(main._journal_btn)
	await _key("Escape")
	_check(not main.journal_visible() and not main._quit.visible, "native Escape closes Journal first")
	_cleanup()
	await _click(main.start_btn)
	_check(main.mission_select_visible(), "native Start opens original six missions")
	if not main.mission_select_visible(): main._show_mission_select()
	await _settle()
	_layout_note(main._mission, "missions")
	_check(main.mission_row_count() == 6, "all six original mission buttons retained")
	for index in 6:
		var expected_id: String = settings.LEVEL_ORDER[index]
		await _click(main._mission_btns[index])
		_check(main.briefing_visible() and main.pending_mission_id() == expected_id, "native mission row opens its original briefing " + expected_id)
		if not main.briefing_visible():
			main._on_mission_picked(index)
			await _settle()
		_layout_note(main._brief, "brief_" + expected_id)
		_check(main.briefing_codename_text() == LevelDef.operation_codename(expected_id), "original briefing codename retained " + expected_id)
		await _scroll_end(main._brief, "brief_" + expected_id)
		await _reach(main._brief_go)
		if index in [0, 5]: await _modal_capture(sample + "_brief_" + expected_id)
		await _click(_button(main._brief, "返回"))
		_check(main.mission_select_visible() and not main.briefing_visible(), "native briefing Back returns to missions " + expected_id)
		if not main.mission_select_visible():
			main._brief.visible = false
			main._show_mission_select()
			await _settle()
	await _scroll_end(main._mission, "missions")
	await _modal_capture(sample + "_missions_end")
	await _click(_button(main._mission, "返回"))
	_check(not main.mission_select_visible(), "native mission Back returns to menu")
	_cleanup()
	await _click(main.start_btn)
	await _key("Escape")
	_check(not main.mission_select_visible() and not main._quit.visible, "native Escape closes mission selection first")
	_cleanup()
	await _click(main.quit_btn)
	_check(main._quit.visible, "native Quit opens original confirmation")
	if not main._quit.visible:
		main._show_quit_confirm()
		await _settle()
	_layout_note(main._quit, "quit")
	await _modal_capture(sample + "_quit")
	await _click(_button(main._quit, "取消"))
	_check(not main._quit.visible, "native quit Cancel preserves title")
	_cleanup()
	await _key("Escape")
	_check(main._quit.visible, "title Escape opens quit confirmation")
	await _click(_button(main._quit, "设置"))
	_check(main.pause_ui.is_open() and not main._quit.visible, "native quit Settings opens original settings")
	var controls := []
	_fits(main.pause_ui._panel, controls)
	await _scroll_end(main.pause_ui, "settings")
	await _modal_capture(sample + "_settings_end")
	await _click(main.pause_ui._close_btn)
	_check(not main.pause_ui.is_open() and not main._quit.visible, "native settings Continue returns without quit")
	_cleanup()
	var muted: bool = settings.muted
	await _key("m")
	await _key("m")
	_check(settings.muted == muted, "native M toggles and restores mute")
	main.start_btn.grab_focus() # Explicit initial keyboard-focus fixture.
	for step in 8:
		if root.gui_get_focus_owner() == main.help_btn: break
		await _key("Tab")
	_check(root.gui_get_focus_owner() == main.help_btn and _hit_visible(main.help_btn), "native Tab traverses and exposes Help")
	await _key("Return")
	_check(main._howto.visible, "native Enter opens focused Help")
	await _key("Escape")
	_check(not main._howto.visible and not main._quit.visible, "keyboard Help returns without cascading quit")
	_cleanup()
	main.handle_app_focus_out()
	await _settle()
	main.handle_app_focus_in()
	await _settle()
	_check(_progress_hash() == before, "menus/scroll/keys/background preserve isolated campaign progress")

func _game_entry(continue_entry: bool) -> void:
	if continue_entry:
		# Accepting Yard legitimately saves Yard; seed the intended Continue fixture again.
		settings.record_win("depot", 3, false)
		main._refresh_continue()
		await _click(main.continue_btn)
	else:
		await _click(main.start_btn)
		await _click(main._mission_btns[0])
		await _click(main._brief_go)
	await _settle()
	var entered := current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn"
	_check(entered, "original " + ("Continue" if continue_entry else "Accept") + " enters actual gameplay scene")
	if entered:
		_check(current_scene.phase == current_scene.Phase.SETUP and current_scene.level.level_id == ("radio" if continue_entry else "yard"), "original entry resolves actual SCOUT and selected level")
	await _title()

func _save_report() -> void:
	var path := "res://build/asset_review/pr15-runtime/title-menu-" + ("exit-keyboard" if exit_kind == "keyboard" else "report") + ".json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "rows": rows, "captures": captures, "native_inputs": input_rows, "original_quit_signal_received": quit_received, "exit_kind": exit_kind}, "  "))

func _quit_signal() -> void:
	quit_received = true
	_save_report()
	print("TITLE_MENU_TEST checks=%d failures=%d actual_quit=%s" % [checks, failures, exit_kind])

func _actual_quit() -> void:
	await _key("Escape")
	_check(main._quit.visible, "final native Escape opens confirmation")
	var yes := _button(main._quit, "退出")
	var original_binding := false
	for connection in yes.get_signal_connection_list("pressed"):
		if connection.callable.get_object() == main and connection.callable.get_method() == "_confirm_quit": original_binding = true
	_check(original_binding, "actual quit keeps original _confirm_quit binding")
	if failures > 0:
		_save_report()
		print("TITLE_MENU_TEST checks=%d failures=%d actual_quit=not_run" % [checks, failures])
		quit(1)
		return
	yes.pressed.connect(_quit_signal)
	if exit_kind == "keyboard":
		for step in 8:
			if root.gui_get_focus_owner() == yes: break
			await _key("Tab")
		_check(root.gui_get_focus_owner() == yes, "native Tab reaches quit Yes")
		await _key("Return")
	else:
		await _click(yes)
	# Original production quit should have ended the engine before this guard.
	await create_timer(0.5).timeout
	_check(false, "original native quit did not exit the engine")
	_save_report()
	print("TITLE_MENU_TEST checks=%d failures=%d actual_quit=failed" % [checks, failures])
	quit(1)

func _run() -> void:
	settings = root.get_node("GameSettings")
	if DisplayServer.get_name() == "headless":
		print("TITLE_MENU requires native rendered verification")
		quit(2)
		return
	root.position = Vector2i.ZERO
	root.size = Vector2i(1600, 720)
	root.content_scale_factor = 2.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	await _title()
	if OS.get_environment("AMBUSH_TITLE_EXIT_ONLY") == "keyboard":
		exit_kind = "keyboard"
		sample = "exit_keyboard_1600_200"
		await _actual_quit()
		return
	_check(main.continue_btn.disabled and not settings.has_progress(), "fresh isolated title disables Continue")
	await _click(main.continue_btn)
	_check(current_scene == main, "disabled original Continue cannot enter gameplay")
	settings.record_win("depot", 3, false) # Original API unlock fixture, not actual six-level wins.
	for id in settings.LEVEL_ORDER: settings.mark_tutorial_seen(id)
	await _title()
	var cases := []
	for physical in [Vector2i(1280, 720), Vector2i(1600, 720)]:
		for factor in [1.0, 2.0]:
			for touch in [false, true]: cases.append([physical, factor, touch])
	if OS.get_environment("AMBUSH_TITLE_MATRIX") == "one": cases = [[Vector2i(1600, 720), 2.0, false]]
	for case in cases:
		root.size = case[0]
		root.content_scale_factor = case[1]
		settings.set_force_touch_hud(case[2])
		sample = "title_" + str(root.size.x) + "_" + str(int(root.content_scale_factor * 100)) + "_" + ("touch" if case[2] else "desktop")
		await _settle()
		_check(root.size == case[0] and root.content_scale_factor == case[1], "actual requested window and scaling")
		_check(not main.continue_btn.disabled and settings.progress_level_id() == "radio", "original saved progress enables Continue")
		await _modal_capture(sample + "_menu")
		await _scroll_end(main, "menu")
		await _modal_capture(sample + "_menu_end")
		print("TITLE_MENU_CASE " + sample)
		await _pages()
		await _game_entry(false)
		await _game_entry(true)
		await _settle()
	await _actual_quit()
