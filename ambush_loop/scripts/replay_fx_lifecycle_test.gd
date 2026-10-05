extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
const CASES := preload("res://scripts/campaign_replay_test.gd").CASES
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
		push_error("REPLAY_FX: " + message)


func _clear(main: Node) -> bool:
	if main._tone_wash.color.a > 0.0001 or main._sig_wash.color.a > 0.0001 or main._alarm_vignette.color.a > 0.0001:
		return false
	for edge in main._rim_flash.get_children():
		if edge.color.a > 0.0001:
			return false
	return not main._fail_static.visible and main._fail_static.modulate.a < 0.0001


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	for case in CASES:
		settings.mark_tutorial_seen(case[0])
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	for i in CASES.size():
		var case: Array = CASES[i]
		main._load_level(case[0], false, false)
		await process_frame
		main.raid_prepare_ref(case[1], case[2])
		main.raid_force_alarm()
		for tick in 6:
			main._sim_tick()
		main.presentation_3d.refresh()
		# Explicit visual-event fixture: real effect generators over an actual
		# recording. It does not claim an actual failed/aborted terminal journey.
		main._alarm_edge_flash()
		main._win_stinger()
		main._play_result_tone(i % 2 == 0)
		if i % 2 == 1:
			main._play_fail_static()
		await create_timer(0.13).timeout
		await process_frame
		_check(main._tone_wash.color.a > 0.001, "real live result wash is active before entering history: " + case[0])
		var snapshots: Array = main.battle_log.snapshots.duplicate(true)
		var events: Array = main.battle_log.events.duplicate(true)
		main._on_replay_pressed()
		main.replay.set_tick(0)
		main._apply_replay_scrub()
		main.presentation_3d.rig.reset_view()
		main.presentation_3d.refresh()
		_check(main.phase == main.Phase.REPLAY and _clear(main), "entering REPLAY clears live wash/rim/static immediately: " + case[0])
		await process_frame
		_check(_clear(main), "old real tweens cannot repaint the first history frame: " + case[0])
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var dir := "res://build/asset_review/pr15-environment-battle"
			DirAccess.make_dir_recursive_absolute(dir)
			_check(root.get_texture().get_image().save_png(dir.path_join(case[0] + "_history_fx_clear.png")) == OK, "actual history framebuffer saved")
		await create_timer(0.45).timeout
		main.replay.set_tick(main.replay.max_tick())
		main._apply_replay_scrub()
		main.presentation_3d.refresh()
		_check(_clear(main), "late historical seek stays clear of live result effects: " + case[0])
		_check(main.battle_log.snapshots == snapshots and main.battle_log.events == events, "clearing live FX preserves source recording: " + case[0])
	root.get_node("AudioDirector").pause_for_background()
	print("REPLAY_FX_OK" if failures == 0 else "REPLAY_FX_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
