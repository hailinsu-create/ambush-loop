extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
var checks := 0
var failures := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PRESENTATION_LIFECYCLE: " + message)


func _send(event: InputEvent) -> void:
	Input.parse_input_event(event)
	await process_frame
	await process_frame


func _touch(id: int, pressed: bool, at: Vector2, canceled: bool = false) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.position = at
	event.pressed = pressed
	event.canceled = canceled
	return event


func _key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	await _send(event)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	await _send(event)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(true)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	var view = main.presentation_3d
	await _key(KEY_I)
	_check(main.backpack_panel.is_open(), "native I opens scout backpack")
	await _key(KEY_ESCAPE)
	_check(not main.backpack_panel.is_open() and not main.pause_overlay.is_open(), "native Escape closes backpack before pause")
	main._toggle_backpack()
	main.handle_android_back()
	_check(not main.backpack_panel.is_open() and not main.pause_overlay.is_open(), "Android Back closes backpack first")
	main.handle_android_back()
	_check(main.pause_overlay.is_open(), "next Android Back opens pause menu")
	main.pause_overlay.dismiss()
	var at := Vector2(640, 345)
	_check(not view.pointer_over_ui(at), "lifecycle test target is clear of HUD")
	for action in ["cancel", "backpack", "menu", "focus", "reset"]:
		await _send(_touch(0, true, at))
		match action:
			"cancel":
				await _send(_touch(0, false, at, true))
			"backpack":
				main._toggle_backpack()
				await _send(_touch(1, true, Vector2(80, 80)))
				await _send(_touch(1, false, Vector2(80, 80)))
				main.backpack_panel.dismiss()
			"menu":
				main._toggle_pause_menu()
				main.pause_overlay.dismiss()
			"focus":
				main.handle_app_focus_out()
				main.handle_app_focus_in()
			"reset":
				main._start_setup(false, false)
		var before: Dictionary = main._snapshot_data().duplicate(true)
		await _send(_touch(0, false, at))
		_check(not main.selected.is_moving() and before == main._snapshot_data(), action + " cancels pending world command")
		_check(view.gestures.contacts.is_empty() and view.gestures.suppressed_contacts.is_empty(), action + " releases touch ownership")
		var actor = main.operators[1]
		var body: Vector2 = view.rig.project_logic(actor.global_position, 1.1)
		main._select_op(0)
		await _send(_touch(3, true, body))
		await _send(_touch(3, false, body))
		_check(main.selected == actor, action + " allows the next independent tap")
	main.raid_force_alarm()
	await _key(KEY_I)
	_check(not main.backpack_panel.is_open(), "native I rejects ALERT backpack")
	main.sim.paused = true
	await _key(KEY_I)
	_check(not main.backpack_panel.is_open(), "native I rejects paused ALERT backpack")
	main.sim.paused = false
	for i in 60:
		main._sim_tick()
	var ev: Dictionary = main.battle_log.last_of_type("spawn")
	var snapshot: Dictionary = main.replay.snapshot_at_or_before(0)
	main._on_replay_pressed()
	await _key(KEY_I)
	_check(not main.backpack_panel.is_open(), "native I rejects REPLAY backpack")
	snapshot = main.replay.snapshot_at_or_before(main.replay.playback_time(ev))
	var expected: Vector2 = main._pos_from_snapshot(snapshot, ev, ev.position)
	var before: Dictionary = main._snapshot_data().duplicate(true)
	main._focus_battle_event(ev)
	view.refresh()
	_check(main.replay.scrub_tick == main.replay.playback_time(ev), "event focus seeks recorded playback time")
	_check(view._event_ring.visible and view._event_ring.position.distance_to(Space.logic_to_world(expected, 0.065)) < 0.001, "3D event ring uses recorded position")
	_check(view.rig.focus.distance_to(Space.logic_to_world(expected)) < 0.001, "3D event focus moves the camera")
	_check(before == main._snapshot_data(), "3D focus does not write live combat state")
	_check(BattleLog.record_tick(ev) > 0, "focus regression uses an actual delayed spawn")
	main.replay.set_tick(main.replay.playback_time(ev) - 1)
	main._apply_replay_scrub()
	view.refresh()
	_check(not view._event_ring.visible, "backward scrub before the focused event clears its future ring within the same wave")
	main._focus_battle_event(ev)
	view.refresh()
	_check(view._event_ring.visible, "refocusing a recorded event restores its ring")
	if DisplayServer.get_name() != "headless":
		var output := "res://build/asset_review/pr15-runtime"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		await process_frame
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(output.path_join("replay_event_focus.png")) == OK, "save rendered event focus")
		main._exit_replay_to_setup()
		main._toggle_backpack()
		await process_frame
		await RenderingServer.frame_post_draw
		_check(root.get_texture().get_image().save_png(output.path_join("scout_backpack.png")) == OK, "save rendered editable backpack")
	root.get_node("AudioDirector").pause_for_background()
	print("PRESENTATION_LIFECYCLE_OK checks=" if failures == 0 else "PRESENTATION_LIFECYCLE_FAILED checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
