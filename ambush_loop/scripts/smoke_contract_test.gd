extends "res://scripts/smoke_test.gd"
## Bounded original smoke gates, explicitly not the whole smoke suite.
func _run() -> void:
	_wipe_save()
	if not await _assert_launch_bar(): return
	var settings=root.get_node("GameSettings")
	settings.pending_level_id="radio"
	settings.mark_tutorial_seen("radio")
	if change_scene_to_file("res://scenes/main.tscn")!=OK:
		push_error("SMOKE_CONTRACT_SCENE_LOAD")
		quit(2)
		return
	await process_frame
	await process_frame
	var main=current_scene
	main.set_process(false)
	main._update_hud()
	if not _assert_radio_contract(main): return
	root.get_node("AudioDirector").pause_for_background()
	print("SMOKE_CONTRACT_OK launch_modal+radio_scout_contract; not full smoke")
	quit(0)
