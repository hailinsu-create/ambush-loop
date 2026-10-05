extends SceneTree

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("M2_ROLE_DOCK_SCENE %s" % err)
		quit(1)
		return
	for _frame in 12:
		await process_frame
	var main = current_scene
	var gs = root.get_node_or_null("GameSettings")
	if main == null or gs == null:
		push_error("M2_ROLE_DOCK_NO_MAIN_OR_SETTINGS")
		quit(2)
		return
	if not _expect_content_fit("desktop_initial", main):
		return
	if not _expect_teaching_owner("yard_initial", main):
		return
	for _refresh in 8:
		main._update_hud()
		await _frames(3)
		print("M2_ROLE_DOCK_REFRESH touch=%s pin_touch=%s pending_touch=%s revision=%d dock=%s content=%s" % [main._want_touch(), main._role_box_pin_touch, main._role_box_pin_pending_touch, main._role_box_pin_revision, main.role_box.offset_bottom-main.role_box.offset_top, main.role_box.get_combined_minimum_size().y])
		if bool(main._role_box_pin_pending):
			push_error("M2_ROLE_DOCK_UNCHANGED_REFRESH_REQUEUES")
			quit(70)
			return
	var original_min: Vector2 = main.role_box.custom_minimum_size
	main.role_box.custom_minimum_size.y = main.role_box.get_combined_minimum_size().y + 56.0
	main._schedule_role_box_refit(false)
	if not main._role_box_pin_pending:
		push_error("M2_ROLE_DOCK_REAL_CONTENT_CHANGE_NOT_QUEUED")
		quit(70)
		return
	await _frames(4)
	if main._role_box_pin_pending or not _expect_content_fit("real_content_growth", main):
		quit(70)
		return
	main.role_box.custom_minimum_size = original_min
	main._schedule_role_box_refit(false)
	# Change touch mode while the desktop callback still owns a pending request.
	gs.set_force_touch_hud(true)
	main._ensure_touch_hud()
	main._update_hud()
	await _frames(4)
	if not _expect_content_fit("touch", main):
		return
	if not _expect_teaching_owner("yard_touch", main):
		return
	main.role_box.custom_minimum_size.y = main.role_box.get_combined_minimum_size().y + 56.0
	main._schedule_role_box_refit(true)
	gs.set_force_touch_hud(false)
	main._ensure_touch_hud()
	main._update_hud()
	await _frames(4)
	if not _expect_content_fit("desktop_restored", main):
		return
	if not _expect_teaching_owner("yard_desktop_restored", main):
		return
	if main._role_box_pin_pending:
		push_error("M2_ROLE_DOCK_MODE_FLIP_PENDING_LATCH")
		quit(70)
		return
	main.role_box.custom_minimum_size = original_min
	main._update_hud()
	await _frames(4)
	main._ensure_night_grade()
	main._ensure_watch_cinema()
	for op in main.operators:
		if op != null and op.has_method("_rebuild_cone"):
			op._rebuild_cone()
	main._update_hud()
	await _frames(2)
	if not _expect_content_fit("after_feel_setup", main):
		return
	if not _expect_teaching_owner("yard_after_feel_setup", main):
		return
	main._load_level("warehouse", false, false)
	await _frames(4)
	if not _expect_content_fit("legacy_level_desktop", main):
		return
	if not _expect_teaching_owner("legacy_desktop", main):
		return
	gs.set_force_touch_hud(true)
	await _frames(2)
	if not _expect_teaching_owner("legacy_touch", main):
		return
	gs.set_force_touch_hud(false)
	await _frames(2)
	if not _expect_teaching_owner("legacy_desktop_restored", main):
		return
	print("M2_ROLE_DOCK_GATE_OK")
	quit(0)


func _expect_content_fit(stage: String, main) -> bool:
	var box = main.role_box
	if box == null or not box is Container:
		push_error("M2_ROLE_DOCK_MISSING stage=%s" % stage)
		quit(44)
		return false
	var dock_h := float(box.offset_bottom - box.offset_top)
	var content_h := float((box as Container).get_combined_minimum_size().y)
	print("M2_ROLE_DOCK_STATE stage=%s touch=%s dock=%s content=%s" % [stage, main._want_touch(), dock_h, content_h])
	if absf(dock_h - content_h) > 12.0:
		push_error("M2_ROLE_DOCK_NOT_CONTENT stage=%s dock=%s content=%s" % [stage, dock_h, content_h])
		quit(44)
		return false
	return true


func _expect_teaching_owner(stage: String, main) -> bool:
	var label = main.spawn_teach_label
	var actual_visible := label != null and is_instance_valid(label) and bool(label.visible)
	var actual_text := str(label.text) if label != null and is_instance_valid(label) else "missing"
	var expected_text := str(main.level.beat_text).strip_edges() if main.level != null else "missing-level"
	var yard_owned := bool(main.yard_redesign_active())
	var expected_visible := not yard_owned and not bool(main._want_touch()) and int(main.phase) == int(main.Phase.SETUP)
	var hud_has_objective := (
		yard_owned
		and main.yard_hud != null
		and bool(main.yard_hud.visible)
		and str(main.yard_hud.objective.text).find("侧巷") >= 0
	)
	var text_matches := actual_text == expected_text
	if actual_visible != expected_visible or not text_matches or (yard_owned and not hud_has_objective):
		push_error(
			"M2_ROLE_DOCK_TEACH stage=%s touch=%s yard=%s visible=%s expected_visible=%s text=%s objective=%s"
			% [stage, main._want_touch(), yard_owned, actual_visible, expected_visible, actual_text, main.yard_hud.objective.text if main.yard_hud != null else "missing-hud"]
		)
		quit(45)
		return false
	print("M2_ROLE_DOCK_TEACH_OK stage=%s visible=%s" % [stage, actual_visible])
	return true


func _frames(count: int) -> void:
	for _frame in count:
		await process_frame
