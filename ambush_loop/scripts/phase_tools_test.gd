extends SceneTree

const StorageGuard := preload("res://scripts/test_storage_guard.gd")
var checks := 0
var failures := 0
var down_events := 0


func _init() -> void:
	if not StorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("PHASE_TOOLS: " + message)


func _state(main: Node) -> Dictionary:
	return {"inventory": main.selected.pack.items(), "decoys": main.selected.decoys,
		"grenades": main.selected.grenades, "mark": main.selected.nade_mark,
		"marked": main.selected.has_nade_mark, "facing": main.selected.facing_deg,
		"deployed_decoys": main.raid_decoys.size()}


func _fixture(main: Node) -> void:
	main._load_level("yard", false, false)
	main.set_process(false)
	main.presentation_3d.set_process(false)
	# Test one native down/up pair independently of wall-clock hold-repeat.
	main.touch_hud.set_process(false)
	main.raid_prepare_ref([1, 2, 5], [90.0, 180.0, 180.0])
	main._select_op(1)
	main.selected.receive_item("decoy", 2)
	main.selected.receive_item("grenade", 2)
	await process_frame
	await process_frame


func _touch(at: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = at
	ev.index = 9
	ev.pressed = pressed
	Input.parse_input_event(ev)
	await process_frame
	await process_frame


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
	for phase in ([] if OS.get_environment("AMBUSH_PHASE_TOOLS_LEGAL_ONLY") == "1" else ["alert", "paused_alert", "replay"]):
		for action in ["nade", "direct_nade", "decoy", "direct_decoy", "rotate_cw", "rotate_ccw"]:
			await _fixture(main)
			main.raid_force_alarm()
			main.sim.paused = phase == "paused_alert"
			if phase == "replay":
				main._sim_tick()
				main._on_replay_pressed()
			var before := _state(main)
			if action == "direct_nade":
				main._place_nade_mark(main.selected.global_position + Vector2(50, 0))
			elif action == "direct_decoy":
				main._throw_decoy_at(main.selected.global_position + Vector2(50, 0))
			else:
				main.apply_touch_command(action)
			_check(before == _state(main), phase + " " + action + " preserves frozen plan and inventory")
	for phase in ["scout", "sweep"]:
		await _fixture(main)
		if phase == "sweep":
			main.raid_force_alarm()
			var limit := 0
			while main.phase == main.Phase.WATCHING and limit < 3000:
				main._sim_tick()
				limit += 1
			_check(main.phase == main.Phase.SWEEP, "actual battle reaches SWEEP before native rotation")
		_check(main.selected.alive and not main.selected.locked, phase + " selected MG survives and accepts plan edits")
		# Actual combat may consume grenades. Supply only these tools after its
		# result, for the legal-entry fixture; this is not a campaign/loadout test.
		main.selected.receive_item("grenade", 2)
		main.selected.receive_item("decoy", 2)
		main._update_hud()
		await process_frame
		for command in ["rotate_cw", "rotate_ccw"]:
			var button: Button = main.touch_hud._btns[command]
			button.button_down.connect(func() -> void: down_events += 1, CONNECT_ONE_SHOT)
			var previous_events := down_events
			var facing: float = main.selected.facing_deg
			var at := button.get_global_rect().get_center()
			await _touch(at, true)
			await _touch(at, false)
			_check(down_events == previous_events + 1, phase + " " + command + " receives a native ScreenTouch GUI press")
			var expected := fposmod(facing + (8.0 if command == "rotate_cw" else -8.0), 360.0)
			print("PHASE_TOOLS_NATIVE phase=", phase, " command=", command, " role=", main.selected.role, " before=", facing, " actual=", main.selected.facing_deg, " expected=", expected, " modal=", main._modal_blocks_input(), " locked=", main.selected.locked)
			_check(is_equal_approx(main.selected.facing_deg, expected), phase + " " + command + " rotates the selected MG within its existing 8-degree limit")
		main.apply_touch_command("nade")
		_check(main.selected.has_nade_mark, phase + " permits a planned grenade point")
		main.apply_touch_command("nade")
		_check(not main.selected.has_nade_mark, phase + " permits clearing the grenade point")
		var decoys: int = main.selected.decoys
		var objects: int = main.raid_decoys.size()
		main.apply_touch_command("decoy")
		_check(main.selected.decoys == decoys - 1 and main.raid_decoys.size() == objects + 1, phase + " legitimately deploys one decoy")
	root.get_node("AudioDirector").pause_for_background()
	print("PHASE_TOOLS_OK" if failures == 0 else "PHASE_TOOLS_FAILED", " checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
