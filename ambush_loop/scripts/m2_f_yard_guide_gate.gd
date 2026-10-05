extends "res://scripts/m2_yard_supply_gate.gd"

func _run() -> void:
	create_timer(300.0).timeout.connect(func(): quit(3))
	capture_dir = OS.get_environment("AMBUSH_TEST_DATA_ROOT").get_base_dir().path_join("m2-f-screens")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var main = await _open_yard("F_OPERABLE")
	if main == null:
		_finish_failed()
		return
	var guide = main.yard_hud.operable_guide
	var gs = main._gs()
	_expect(not main.tutorial_overlay.is_open() and not main._modal_blocks_input(), "M2_F_NO_YARD_MODAL")
	_expect(guide.mouse_filter == Control.MOUSE_FILTER_IGNORE and guide.steps.count(true) == 0, "M2_F_TRANSPARENT_NO_CLICK_CREDIT")
	for size in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.content_scale_size = size
		root.size = size
		gs.set_force_touch_hud(true)
		main._update_hud()
		await _frames(6)
		var guide_rect: Rect2 = guide.get_global_rect()
		_expect(guide_rect.position.x >= 0 and guide_rect.end.x <= size.x and guide_rect.end.y < main.touch_hud._btns.alarm.get_global_rect().position.y, "M2_F_GUIDE_FITS_ABOVE_CONTROLS_%s" % size)
		var point := guide_rect.get_center()
		guide.visible = false
		await _tap_point(point)
		var without: Dictionary = main._touch_intent.duplicate(true)
		main.cancel_touch_intent()
		guide.visible = true
		await _tap_point(point)
		_expect(without == main._touch_intent and guide.steps.count(true) == 0, "M2_F_NATIVE_TRANSPARENT_SAME_WORLD_RESULT_%s" % size)
		main.cancel_touch_intent()
		await _capture_if_rendered(main, "guide-%dx%d" % [size.x, size.y])
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	gs.set_force_touch_hud(false)
	main._update_hud()
	await _frames(4)
	main.operators[0].receive_ammo(1)
	main._update_hud()
	_expect(not guide.steps[0], "M2_F_DIRECT_AMMO_NOT_SEARCH")
	main.apply_touch_command("alarm")
	_expect(not guide.steps[2], "M2_F_ALARM_CLICK_NOT_COMBAT")
	# Do not run this accidentally accepted attempt; a fresh setup is legitimate.
	main._start_setup(false, false)
	var stash = _find_stash(main, "rifle_ammo")
	var op = main.operators[0]
	_expect(bool((await _walk_to_cell(main, op, stash.cell)).get("ok", false)), "M2_F_REAL_FIRST_MOVE")
	_expect(not guide.steps[0], "M2_F_ARRIVAL_SEARCH_START_NOT_COMPLETE")
	main.raid_advance_search(0.01)
	_expect(not guide.steps[0], "M2_F_SHORT_SEARCH_NOT_COMPLETE")
	main.raid_advance_search(0.8)
	main._update_hud()
	_expect(guide.steps[0] and not guide.steps[1] and not gs.has_seen_tutorial("yard"), "M2_F_REAL_SUPPLY_ONLY")
	main.selected = op
	main.apply_touch_command("rotate_cw")
	_expect(not guide.steps[1], "M2_F_ONE_DEPLOY_PLUS_FACING_NOT_ENOUGH")
	var op2 = main.operators[1]
	_expect(bool((await _walk_to_cell(main, op2, Vector2i(12, 14))).get("ok", false)), "M2_F_SECOND_LEGAL_MOVE")
	main._update_hud()
	_expect(guide.steps[1], "M2_F_GROUND_TWO_MOVES_FACING")
	_expect(not main.yard_manual_permission, "M2_F_DEFAULT_AUTO_UNCHANGED")
	# Prepare the existing true ramp tactic, not a seeded plan.
	main._start_setup(false, false)
	if not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	main.raid_force_alarm()
	main._update_hud()
	_expect(not guide.steps[2], "M2_F_ACCEPTED_ALARM_WITHOUT_EVENT_INCOMPLETE")
	_run_battle(main)
	main._update_hud()
	_expect(guide.steps[2] and not guide.steps[3] and not gs.has_seen_tutorial("yard"), "M2_F_REAL_COMBAT_NOT_YET_REVIEWED")
	main._on_replay_pressed()
	_expect(guide.steps.count(true) == 4 and gs.has_seen_tutorial("yard"), "M2_F_REPLAY_COMPLETES_EXISTING_PREFERENCE")
	var before := _state_signature(main)
	main.replay.set_tick(207)
	main._apply_replay_scrub()
	_expect(before == _state_signature(main), "M2_F_REPLAY_GUIDE_NO_GAMEPLAY_WRITE")
	main = await _open_yard("F_RELOAD_SEEN")
	_expect(not main.yard_hud.operable_guide.visible and main.operators[0].ammo == 1 and main.stash_count() == 4, "M2_F_ONLY_TUTORIAL_PREF_PERSISTS_NOT_PREPARATION")
	# Unseen isolated profile: exercise real failure -> D1 adjustment branch.
	gs.seen_tutorial = false
	gs.seen_level_tutorials.erase("yard")
	gs.save_settings()
	main._load_level("yard", false, false)
	guide = main.yard_hud.operable_guide
	_expect(guide.steps.count(true) == 0, "M2_F_FRESH_MISSION_RESETS_OBSERVER")
	if not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	main.selected = main.operators[0]
	main.apply_touch_command("rotate_cw")
	main.operators[0].set_facing(180)
	main.operators[1].set_facing(180)
	main.operators[2].set_facing(0)
	main.raid_force_alarm()
	_run_battle(main)
	_expect(main.phase == main.Phase.FAILED and guide.steps[2], "M2_F_REAL_LOSS_KEEPS_COMBAT_CREDIT")
	main._on_continue_pressed()
	_expect(main.phase == main.Phase.SETUP and guide.steps.count(true) == 4 and gs.has_seen_tutorial("yard"), "M2_F_ACTUAL_CHECKPOINT_RETRY_COMPLETES_MONOTONIC")
	for id in ["warehouse", "pump", "depot", "radio", "railcut"]:
		main._load_level(id, false, false)
		_expect(not main.yard_hud.visible and main.tutorial_overlay.pages_for(id).size() >= 2, "M2_F_OTHER_TUTORIAL_RETAINED_" + id)
	if failures.is_empty():
		print("M2_F_OPERABLE_GUIDE_OK actual_supply=1 legal_deployment=1 combat=1 replay_retry=1 preference_only=1 other_five=1")
		quit(0)
	else: _finish_failed()

func _tap_point(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
	await _frames(2)
