extends "res://scripts/smoke_test.gd"

## Fast diagnostic of the full smoke suffix; NEVER substitutes for the full gate.
func _run() -> void:
	create_timer(600.0).timeout.connect(func(): quit(3))
	_wipe_save()
	if change_scene_to_file("res://scenes/main.tscn") != OK:
		quit(1)
		return
	for _frame in 12: await process_frame
	var main = current_scene
	if not _assert_lifecycle(main): return
	if not _assert_watch_juice(main): return
	if not _assert_alarm_stinger(main): return
	if not _assert_win_stinger(main): return
	if not _assert_perf_tier(main): return
	if not _assert_readability(main): return
	if not _assert_unit_anim(main): return
	if not await _assert_feel_presence(main): return
	if not _assert_props(main): return
	if not _assert_teaching(main): return
	if not _assert_iteration_slice(main): return
	if not await _assert_checklist(main): return
	_show_yard_details(main)
	main._refresh_watch_timeline()
	if not main.setup_spawn_preview_visible() or main.setup_spawn_preview_count() < 2:
		push_error("M2_POST_TOUCH_SPAWN_PREVIEW")
		quit(59)
		return
	if not _assert_raid_contract(main): return
	if not await _assert_fail_paths(main): return
	if not await _assert_skip_to_outcome(main): return
	if not await _assert_raid_campaign(main): return
	if not _assert_sweep_hint(main): return
	print("M2_POST_TOUCH_SUFFIX_OK not_full_smoke=1")
	quit(0)
