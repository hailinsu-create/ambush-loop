extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
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
		push_error("C2_HISTORY_HINT: " + message)


func _hidden(main: Node, context: String) -> void:
	_check(not main.c2.help_chip.visible and main.c2.help_chip.text.is_empty(), context + " removes live C2Help visibility and retained text")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	settings.mark_tutorial_seen("yard")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main._select_op(1)
	main.selected.receive_item("m1911", 5)
	main.selected.receive_item("decoy", 1)
	main.raid_force_alarm()
	var ticks := 0
	while main.phase == main.Phase.WATCHING and ticks < 6000:
		main._sim_tick()
		ticks += 1
	var controls_ok: bool = main.phase == main.Phase.SWEEP and main.c2.help_chip.visible and main.c2.help_chip.text.contains("打扫") and main.selected.alive
	print("C2_HISTORY_HINT_CONTROLS_OK=", controls_ok, " ticks=", ticks)
	if not controls_ok:
		push_error("C2_HISTORY_HINT fixture did not reach actual legal SWEEP with its natural hint")
		root.get_node("AudioDirector").pause_for_background()
		quit(2)
		return
	var source_snapshots: Array = main.battle_log.snapshots.duplicate(true)
	var source_events: Array = main.battle_log.events.duplicate(true)
	var recorded_name: String = source_snapshots.front().data.ops[2].display_name
	main._on_replay_pressed()
	main.replay.set_tick(0)
	main._apply_replay_scrub()
	_hidden(main, "actual SWEEP enters replay")
	_check(main.c2.portraits._cards[2].get_node("Nam").text == recorded_name, "history portrait is a control against the original recorded name")
	main._on_alarm_pressed()
	_check(main.phase == main.Phase.SETUP and main.c2.help_chip.visible and main.c2.help_chip.text.contains("点选"), "return to scout regenerates its current phase help")
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main._select_op(2)
	main.selected.display_name = "LIVE_ONLY_SCOUT"
	main.c2.use_skill("binoculars")
	controls_ok = main._is_command_phase() and main.selected.alive and main.c2.binoculars_t > 0.0 and main.c2.help_chip.visible and main.c2.help_chip.text.contains("LIVE_ONLY_SCOUT")
	print("C2_HISTORY_HINT_SKILL_CONTROLS_OK=", controls_ok)
	if not controls_ok:
		push_error("C2_HISTORY_HINT fixture did not produce a legal live binocular hint")
		root.get_node("AudioDirector").pause_for_background()
		quit(2)
		return
	# Re-open the separately retained recording after a genuine return to SCOUT.
	# This is historical input, never a rebinding of events to the current run.
	var stored_log := BattleLog.new()
	stored_log.snapshots = source_snapshots.duplicate(true)
	stored_log.events = source_events.duplicate(true)
	main.battle_log = stored_log
	main._flash("LIVE_ONLY MAIN BANNER", Color.WHITE)
	main._on_replay_pressed()
	main.replay.set_tick(0)
	main._apply_replay_scrub()
	_hidden(main, "legal binocular hint enters retained history")
	_check(main.c2.portraits._cards[2].get_node("Nam").text == recorded_name and main.flash_label.text.is_empty() and main.flash_text().is_empty(), "live name and banner cannot leak into retained history")
	for phone in [true, false, true, false]:
		settings.set_force_touch_hud(phone)
		main.c2.layout_chrome(phone)
		main.c2.refresh_hud_light()
		main.c2.refresh_hud()
		_hidden(main, "phone/desktop layout change")
		var status: String = main.status_label.text
		main.c2._hint("LATE_LIVE_ONLY_HINT")
		_hidden(main, "late hint producer during history")
		_check(main.status_label.text == status, "late live hint cannot overwrite the historical status")
	_check(stored_log.snapshots == source_snapshots and stored_log.events == source_events, "help and layout leave the immutable source recording unchanged")
	# Old/unknown visual recordings must have the same live-hint isolation.
	var legacy := BattleLog.new()
	legacy.snapshots = [{"tick": 0, "data": {"ops": [], "enemies": []}}]
	main.replay.bind(legacy)
	main._apply_replay_scrub()
	_hidden(main, "legacy partial history")
	legacy.snapshots[0].data["visual_schema"] = 99
	main.replay.bind(legacy)
	main._apply_replay_scrub()
	_hidden(main, "unknown future history")
	main._on_alarm_pressed()
	_check(main.phase == main.Phase.SETUP and main.c2.help_chip.visible and not main.c2.help_chip.text.contains("LIVE_ONLY"), "legacy/unknown return restores fresh scout help")
	# Explicit exit fixtures exercise existing WON/FAILED reset branches;
	# they do not claim that a complete battle reached either result here.
	for return_phase in [main.Phase.WON, main.Phase.FAILED]:
		main.battle_log = BattleLog.new()
		main.battle_log.snapshots = source_snapshots.duplicate(true)
		main.battle_log.events = source_events.duplicate(true)
		main.phase = return_phase
		main.c2._hint("PREVIOUS_RESULT_HINT")
		main._on_replay_pressed()
		_check(main.phase == main.Phase.REPLAY, "result exit fixture actually enters history")
		_hidden(main, "result exit fixture enters history")
		main._on_alarm_pressed()
		_check(main.phase != main.Phase.REPLAY and main.c2.help_chip.visible and not main.c2.help_chip.text.contains("PREVIOUS_RESULT_HINT"), "result exit restores chrome without old transient hint")
		main._start_setup(false, false)
		_check(main.phase == main.Phase.SETUP and main.c2.help_chip.visible and main.c2.help_chip.text.contains("点选"), "reset regenerates current scout help")
	if DisplayServer.get_name() != "headless":
		main.battle_log = BattleLog.new()
		main.battle_log.snapshots = source_snapshots.duplicate(true)
		main.battle_log.events = source_events.duplicate(true)
		main._on_replay_pressed()
		main.replay.set_tick(0)
		main._apply_replay_scrub()
		main.presentation_3d.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://build/asset_review/pr15-runtime/c2_history_hint_desktop.png"
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		_check(root.get_texture().get_image().save_png(path) == OK, "save real desktop history with live C2Help removed")
	root.get_node("AudioDirector").pause_for_background()
	print("C2_HISTORY_HINT_OK" if failures == 0 else "C2_HISTORY_HINT_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
