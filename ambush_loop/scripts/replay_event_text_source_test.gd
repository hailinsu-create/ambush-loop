extends "res://scripts/replay_autoplay_test.gd"
## Controlled API source replacement; ordinary UI reachability is not asserted.

func _run() -> void:
	var path := OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE")
	if path.is_empty() or not FileAccess.file_exists(path):
		_check(false, "authentic saved fixture exists")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.position = Vector2i.ZERO
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	var values: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	source = BattleLog.new()
	for key in values: source.set(key, values[key])
	retained = _state(source)
	# Terminal UI fixture, not a claimed player victory.
	main.battle_log = source
	main.phase = main.Phase.WON
	main._show_win_result()
	main._on_replay_pressed()
	var shot: Dictionary = source.first_of_type("fire")
	_check(not shot.is_empty() and str(shot.payload.get("name", "")) != "", "authentic source contains named first shot")
	main._focus_battle_event(shot)
	view.refresh()
	var expected: String = source.format_event(shot)
	_check(main.status_label.text == "定位 · " + expected, "baseline first-shot status")
	if DisplayServer.get_name() != "headless":
		await _modal_capture("bound_text_original")
	var foreign := BattleLog.new()
	foreign.begin_attempt("unrelated-live-log-with-no-shots")
	foreign.add_snapshot(0, {"phase":0})
	foreign.add_snapshot(4, {"phase":3})
	foreign.mark_terminal(4, "won")
	var foreign_before := _state(foreign)
	main.battle_log = foreign
	main._focus_battle_event(shot)
	view.refresh()
	var list_text := ""
	for i in main._event_list_items.size():
		if main._event_list_items[i].event_id == shot.event_id:
			list_text = main.event_list.get_item_text(i)
	_check(main.replay.log == source and view.frame.attempt_id == source.attempt_id and view._event_ring.visible, "historical source and actual3D focus remain bound")
	_check(main.status_label.text == "定位 · " + expected, "status ignores unrelated live formatter")
	_check(list_text == expected, "event list ignores unrelated live formatter")
	_check(_state(source) == retained and _state(foreign) == foreign_before, "both records remain unchanged")
	if DisplayServer.get_name() != "headless":
		await _modal_capture("bound_text_live_replaced")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/replay-event-text-" + ("headless" if DisplayServer.get_name() == "headless" else "render") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"expected":expected,"actual_status":main.status_label.text,"actual_list":list_text,"attempt":source.attempt_id,"event_id":shot.event_id,"cursor":main.replay.scrub_tick,"captures":captures,"controlled_api_swap":true,"ordinary_ui_swap_reachability":"unproven"}, "  "))
	print("BOUND_TEXT checks=", checks, " failures=", failures)
	root.get_node("AudioDirector").pause_for_background()
	quit(1 if failures > 0 else 0)
