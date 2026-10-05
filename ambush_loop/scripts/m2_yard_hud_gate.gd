extends "res://scripts/m1_yard_visual_evidence_gate.gd"

## Reuse the M1 real pickup/path fixtures; exercise the actual M2 controls.
func _run() -> void:
	create_timer(300.0).timeout.connect(func():
		push_error("M2_A_GATE_WALL_CLOCK_GUARD")
		quit(3)
	)
	capture_dir = OS.get_environment("AMBUSH_TEST_DATA_ROOT").get_base_dir().path_join("m2-a-screens")
	DirAccess.make_dir_recursive_absolute(capture_dir)
	var main = await _open_yard("M2_HUD")
	if main == null or not await _prepare_plan(main, "A"):
		_finish_failed()
		return
	main._update_hud()
	await _frames(3)
	_expect(main.yard_hud.visible and not main.yard_hud.details_open, "M2_A_DEFAULT_SIMPLE")
	_expect(not main.role_box.visible and main.c2.portraits.is_visible_in_tree(), "M2_A_ONE_SQUAD_STRIP")
	_expect(not main.desktop_command_bars_visible() and main.yard_hud.commands.visible, "M2_A_ONE_COMMAND_ROW")
	_expect(not main.routes_draw.visible and not main.watch_timeline.visible and not main.killzone_draw.visible, "M2_A_DEFAULT_DETAILS_FOLDED")
	_expect(main.selected_coverage_draw.visible and main.selected_coverage_draw.get_child_count() > 0, "M2_A_SELECTED_TRUE_GEOMETRY_RETAINED")
	_expect(main.yard_hud.buttons["alarm"].text == "开始交战", "M2_A_ACTION_WORDING")
	await _capture_if_rendered(main, "default-plan-a")
	var before := _state_signature(main)
	await _click(main.yard_hud.details_button)
	_expect(main.yard_hud.details_open and main.routes_draw.visible and main.watch_timeline.visible, "M2_A_REAL_GUI_OPENS_DETAILS")
	_expect(before == _state_signature(main), "M2_A_DETAILS_CLICK_NO_MOVE_OR_SIM_CHANGE")
	await _capture_if_rendered(main, "tactical-plan-a")
	await _click(main.yard_hud.details_button)
	_expect(not main.yard_hud.details_open and before == _state_signature(main), "M2_A_REAL_GUI_FOLDS_WITHOUT_STATE_CHANGE")
	for op in main.operators:
		op.rotate_by(0.0)
		op._rebuild_cone()
		_expect(not op.cone.visible and not op.cone_edge.visible, "M2_A_DIRECTION_GUIDE_STAYS_FOLDED_OP%d" % op.op_id)
	var gs = main._gs()
	gs.set_force_touch_hud(true)
	main._update_hud()
	await _frames(3)
	_expect(not main.yard_hud.commands.visible and main.touch_hud.visible and not main.desktop_command_bars_visible(), "M2_A_TOUCH_SINGLE_COMMAND_ROW")
	_expect(main.touch_hud._btns["alarm"].text == "开始交战", "M2_A_TOUCH_ACTION_WORDING")
	_expect(main.c2.portraits.get_parent() == main.touch_hud.portrait_slot(), "M2_A_TOUCH_PORTRAITS_REPARENTED")
	_expect(main.yard_hud.selected_status.get_parent() == main.touch_hud.portrait_slot().get_parent(), "M2_A_TOUCH_STATUS_ABOVE_TOUCH_PLATE")
	before = _state_signature(main)
	await _touch(main.yard_hud.details_button)
	_expect(main.yard_hud.details_open and before == _state_signature(main), "M2_A_REAL_TOUCH_DETAILS_NO_WORLD_COMMAND")
	await _touch(main.yard_hud.details_button)
	await _capture_if_rendered(main, "touch-plan-a")
	gs.set_force_touch_hud(false)
	main._update_hud()
	var legend_should_be_visible: bool = int(main.phase) == int(main.Phase.SETUP) and main.level != null and not main._want_touch() and not main.yard_redesign_active()
	print(
		"M2_A_LEGEND_STATE force=%s touch=%s yard_hud=%s visible=%s expected=%s phase=%s level=%s"
		% [gs.force_touch_hud, main._want_touch(), main.yard_redesign_active(), main.route_legend.visible if main.route_legend != null else "missing", legend_should_be_visible, main.phase, main.level.level_id if main.level != null else "missing"]
	)
	_expect(
		main.route_legend != null and bool(main.route_legend.visible) == legend_should_be_visible,
		"M2_A_TOUCH_MODE_LEGEND_RESTORES"
	)
	await _click(main.yard_hud.buttons["alarm"])
	_expect(main.phase == main.Phase.WATCHING, "M2_A_REAL_GUI_STARTS_AUTHORITATIVE_BATTLE")
	before = _state_signature(main)
	await _click(main.yard_hud.buttons["pause"])
	_expect(main.sim.paused and before == _state_signature(main), "M2_A_PAUSE_PRESERVES_PLAN_AND_EVENTS")
	await _click(main.yard_hud.details_button)
	_expect(main.yard_hud.details_open and before == _state_signature(main), "M2_A_PAUSED_DETAILS_PRESERVE_FROZEN_STATE")
	await _click(main.yard_hud.buttons["speed"])
	_expect(main.sim.speed == 2.0 and before == _state_signature(main), "M2_A_SPEED_VIEW_ONLY")
	await _click(main.yard_hud.buttons["pause"])
	var ticks := 0
	while main.phase != main.Phase.WON and main.phase != main.Phase.FAILED and ticks < MAX_SIM_TICKS:
		ticks += 1
		if main.phase == main.Phase.SWEEP:
			main._on_sweep_commit()
		else:
			main._sim_tick()
	_expect(main.phase == main.Phase.WON, "M2_A_EXISTING_REAL_PLAN_A_STILL_WINS")
	var negative = await _open_yard("M2_FAILURE")
	if negative == null or not await _prepare_main_only(negative):
		_finish_failed()
		return
	negative.raid_force_alarm()
	ticks = 0
	while negative.phase != negative.Phase.FAILED and negative.phase != negative.Phase.WON and ticks < MAX_SIM_TICKS:
		ticks += 1
		if negative.phase == negative.Phase.SWEEP:
			negative._on_sweep_commit()
		else:
			negative._sim_tick()
	_expect(_has_real_flank_escape(negative), "M2_A_FAILURE_REAL_FLANK_ESCAPE")
	var escape: Dictionary = negative.battle_log.last_of_type("escape")
	_expect(negative.result_label.text.contains(negative.battle_log.format_event(escape)), "M2_A_FAILURE_USES_ACTUAL_ACTOR_ROUTE_AND_TIME")
	_expect(not negative.result_label.text.contains("改一处") and not negative.result_label.text.contains("穿梭"), "M2_A_FAILURE_NO_GUARANTEED_ADVICE")
	_expect(negative.result_label.text.contains("最近记录") and not negative.result_dossier.visible, "M2_A_FAILURE_OBSERVATIONS_AND_OPTIONAL_ADVICE")
	_expect(negative._fail_dossier_text.contains("可以尝试："), "M2_A_AUTHORED_ADVICE_LABELLED_SUGGESTION")
	_expect(not negative.route_timeline.visible and negative.yard_hud.result_replay.is_visible_in_tree(), "M2_A_RESULT_CLEAN_WITH_ACCESSIBLE_REPLAY")
	await _capture_if_rendered(negative, "flank-failure")
	var events_before: String = var_to_str(negative.battle_log.events)
	await _click(negative.yard_hud.result_replay)
	_expect(negative.phase == negative.Phase.REPLAY and events_before == var_to_str(negative.battle_log.events), "M2_A_REAL_GUI_ENTERS_READ_ONLY_REPLAY")
	await _click(negative.yard_hud.buttons["alarm"])
	await _frames(3)
	_expect(negative.phase == negative.Phase.SETUP and negative.yard_hud.visible and not negative.yard_hud.details_open, "M2_A_RETRY_RESTORES_DEFAULT_PRESENTATION")
	negative._load_level("warehouse", false, false)
	await _frames(3)
	_expect(not negative.yard_hud.visible and negative.yard_tactical_details_visible() and negative.role_box.visible and negative.touch_hud._hint.visible and not negative.yard_hud.result_replay.visible, "M2_A_OTHER_LEVEL_LEGACY_PRESENTATION_RESTORED")
	if not failures.is_empty():
		_finish_failed()
		return
	print("M2_YARD_HUD_OK real_mouse=1 real_touch=1 no_input_passthrough=1 freeze=1 real_win=1 real_escape=1 other_level_restore=1 screenshots=%s" % capture_dir)
	quit(0)


func _state_signature(main) -> String:
	var ops := []
	for op in main.operators:
		ops.append([op.op_id, op.global_position, op.facing_deg, op.weapon_id, op.ammo, op.move_path, op.locked, op.fire_mode, op.pack.slots, op.ammo_pool])
	return var_to_str([main.phase, main.sim.tick, ops, main.battle_log.events, main.last_plan, main.pending_spawns])


func _click(button: Button) -> void:
	await _frames(2)
	var at := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _touch(button: Button) -> void:
	await _frames(2)
	var at := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = at
		event.index = 0
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _capture_if_rendered(main, label: String) -> void:
	if DisplayServer.get_name() != "headless":
		_expect(await _capture(main, label), "M2_A_%s_CAPTURE" % label)
