extends "res://scripts/viewport_hud_test.gd"
## Reference recording fixture; native replay uses the ordinary engine process.
const ViewState := preload("res://scripts/presentation/view_state.gd")
var source: BattleLog
var retained: Dictionary
var live: Dictionary
var sim_state: Array

class ClockProbe extends Node:
	var host: Node
	var expected_ticks := 0.0
	var first := true
	var armed := false
	var rate_rows := []
	func _process(delta: float) -> void:
		if not armed or host.phase != host.Phase.REPLAY: return
		if first:
			expected_ticks = 0.0
			first = false
		expected_ticks += delta * 120.0
		rate_rows.append({"delta":delta, "tick":host.replay.scrub_tick, "expected":mini(floori(expected_ticks + 0.000001), host.replay.max_tick())})

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("REPLAY_AUTO_FAIL " + sample + " " + message)

func _draw() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	await process_frame
	await RenderingServer.frame_post_draw

func _key(name: String) -> void:
	var output := []
	var status := OS.execute("python3", [ProjectSettings.globalize_path("res://scripts/native_x11_test_input.py"), "key", name], output, true)
	_check(status == 0, "native key helper exit0 " + name)
	input_rows.append({"id":sample, "key":name, "helper_exit":status})
	for i in 5: await process_frame
	await _draw()

func _state(log: BattleLog) -> Dictionary:
	var result := {}
	for key in ["attempt_id", "events", "snapshots", "terminal_tick", "terminal_reason", "playback_schema", "playback_snapshots", "playback_terminal_tick", "wave_id", "wave_offset", "_playback_tick", "_command_subticks"]:
		var value = log.get(key)
		result[key] = value.duplicate(true) if value is Array or value is Dictionary else value
	return result

func _unchanged(label: String) -> void:
	_check(_state(source) == retained, label + " retains the original recording byte values")
	_check(main._snapshot_data() == live, label + " keeps live state frozen")
	_check([main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum] == sim_state, label + " does not use or change SimClock")

func _clock_cases() -> void:
	var log := BattleLog.new()
	log.begin_attempt("clock-fixture")
	log.add_snapshot(0, {"phase":0})
	log.add_snapshot(1200, {"phase":3})
	log.mark_terminal(1200, "won")
	var player := ReplayPlayer.new()
	player.bind(log)
	_check(player.scrub_tick == 1200 and not player.playing, "direct bind preserves terminal selection compatibility")
	var supported := player.has_method("advance") and player.has_method("play") and player.has_method("pause") and player.has_method("set_speed")
	_check(supported, "independent history playback clock exists")
	if not supported: return
	var before := _state(log)
	for hz in [30,60,240]:
		for speed in [1.0,2.0]:
			player.bind(log)
			player.call("set_speed", speed)
			player.call("play", true)
			for frame in hz: player.call("advance", 1.0 / float(hz))
			_check(player.scrub_tick == int(60.0 * speed), "one second rate independent of frame cadence " + str(hz) + "/" + str(speed))
	player.call("pause")
	var tick := player.scrub_tick
	player.call("advance", 12.0)
	_check(player.scrub_tick == tick, "paused time never accumulates")
	player.set_tick(60)
	player.call("play", false)
	player.call("advance", 0.001)
	player.set_tick(300)
	_check(not player.playing, "explicit seek pauses automatic playback")
	player.call("play", false)
	player.call("advance", 0.007)
	_check(player.scrub_tick == 300, "seek removes old sub-tick debt")
	for delta in [-1.0,0.0,INF,NAN]: player.call("advance", delta)
	_check(player.scrub_tick == 300, "invalid deltas cannot advance history")
	player.call("advance", 20.0)
	_check(player.scrub_tick == 1200 and not player.playing, "endpoint clamps and stops at recorded terminal")
	player.call("play", false)
	_check(player.scrub_tick == 0 and player.playing, "resume at the end explicitly replays from the beginning")
	player.bind(log)
	_check(not player.playing and player.scrub_tick == 1200, "new bind clears previous playing clock")
	_check(_state(log) == before, "transport never changes original legacy record")
	log.snapshots.append({"tick":0,"data":{}})
	player.bind(log)
	player.call("play", true)
	player.call("advance", 1.0)
	_check(player.legacy_ambiguous and not player.playing and player.scrub_tick == 0, "ambiguous old reset stream cannot auto-play")
	var path := OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE")
	_check(not path.is_empty() and FileAccess.file_exists(path), "actual schema1 source fixture is available")
	if not path.is_empty() and FileAccess.file_exists(path):
		var hash := FileAccess.get_sha256(path)
		var values: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
		var old := BattleLog.new()
		for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]: old.set(key, values[key])
		var saved := _state(old)
		player.bind(old)
		player.call("play", true)
		player.call("advance", 0.5)
		_check(player.continuous_playback and player.scrub_tick == 60 and player.max_tick() == 1415, "real schema1 supports independent2x clock without upgrading")
		player.call("advance", 30.0)
		_check(player.scrub_tick == 1415 and not player.playing and _state(old) == saved and FileAccess.get_sha256(path) == hash, "real schema1 endpoint and original bytes retained")

func _prepare() -> void:
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
	main._start_setup(false, false)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	main._select_op(2)
	main._command_move_selected(main.grid.cell_to_world_center(Vector2i(32,16)))
	for i in 48: main._process(1.0/60.0)
	main.raid_prepare_ref([1,2,5],[90.0,180.0,180.0])
	main.raid_force_alarm()
	var wave_ticks := []
	for wave in 2:
		var steps := 0
		while main.phase == main.Phase.WATCHING and steps < 5000:
			main._sim_tick()
			steps += 1
		_check(main.phase == main.Phase.SWEEP, "original reference wave reaches SWEEP")
		wave_ticks.append(main.sim.tick)
		main._select_op(2)
		main._command_move_selected(main.grid.cell_to_world_center(Vector2i(32,16)))
		for i in 48: main._process(1.0/60.0)
		main.raid_vacuum_loot()
		main._on_sweep_commit()
	source = main.battle_log
	retained = _state(source)
	_check(main.phase == main.Phase.WON and wave_ticks == [1056,227] and source.terminal_tick == 1283 and source.events.size() == 34, "original two-wave battle terminal/events preserved")
	rows.append({"record_fixture":"original reference deployments and legal command movement, not normal player victories", "wave_ticks":wave_ticks,"terminal":source.terminal_tick,"events":source.events.size(),"playback_terminal":source.playback_terminal_tick,"attempt":source.attempt_id})

func _bones() -> Array:
	var body = view.actors["ops:3"].get_node("Body")
	var result := [body.global_transform, body.sampled_action, body.sampled_time]
	for i in body.skeleton.get_bone_count(): result.append(body.skeleton.get_bone_pose(i))
	return result

func _pause_control(touch: bool) -> Control:
	return main.touch_hud.get("_replay_pause") if touch else main.pause_button

func _speed_control(touch: bool) -> Control:
	return main.touch_hud.get("_replay_speed") if touch else main.speed_button

func _native_case(touch: bool) -> void:
	root.size = Vector2i(1600,720) if touch else Vector2i(1280,720)
	root.content_scale_factor = 2.0 if touch else 1.0
	root.get_node("GameSettings").set_force_touch_hud(touch)
	sample = "auto_200_compact" if touch else "auto_100_desktop"
	main._update_hud()
	await _draw()
	# Before REPLAY, the reference fixture is idle; only the real replay is processed.
	var probe := ClockProbe.new()
	probe.host = main
	probe.process_priority = 50
	root.add_child(probe)
	probe.armed = true
	main.set_process(true)
	if touch:
		main._event_log_open = false
		main._update_hud()
		await _native_click(main.touch_hud._btns.replay)
	else:
		await _native_click(main.replay_button)
	await _draw()
	_check(main.phase == main.Phase.REPLAY and main.replay.log == source, "native production button binds the original recording")
	_check(main.replay.playing and main.replay.scrub_tick > 0 and float(main.replay.get("speed")) == 2.0, "ordinary native entry automatically advances at2x")
	live = main._snapshot_data().duplicate(true)
	sim_state = [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum]
	var start: int = main.replay.scrub_tick
	await create_timer(0.4).timeout
	await _draw()
	probe.armed = false
	_check(main.is_processing() and main.replay.scrub_tick > start, "ordinary engine process advances replay without sample seeks")
	for item in probe.rate_rows: _check(item.tick == item.expected, "native frame delta drives120 historical ticks per second")
	rows.append({"id":sample,"native_rate_samples":probe.rate_rows})
	probe.queue_free()
	await _modal_capture(sample + "_playing")
	var pause := _pause_control(touch)
	var speed := _speed_control(touch)
	_check(pause != null and speed != null, "original transport routes expose pause and speed controls")
	if pause == null or speed == null:
		main.set_process(false)
		main._exit_replay_to_setup()
		return
	var controls := []
	_fits(pause,controls)
	_fits(speed,controls)
	await _native_click(pause)
	await _draw()
	var paused_tick: int = main.replay.scrub_tick
	var paused_bones := _bones()
	await create_timer(0.25).timeout
	await _draw()
	_check(not main.replay.playing and main.replay.scrub_tick == paused_tick and _bones() == paused_bones, "native pause freezes clock and original20-bone pose")
	_unchanged("native pause")
	await _native_click(speed)
	_check(float(main.replay.get("speed")) == 1.0 and not main.replay.playing, "native1x selection preserves paused state")
	await _native_click(pause)
	await create_timer(0.2).timeout
	await _draw()
	_check(main.replay.playing and main.replay.scrub_tick > paused_tick, "native resume continues at selected rate")
	await _key("p")
	_check(not main.replay.playing, "original P key pauses REPLAY")
	var slider: Control = main.touch_hud._replay_scrub if touch else main.scrub_slider
	var at := slider.get_global_rect()
	await _native_click(slider,1, Vector2(at.position.x + at.size.x * 0.7, at.get_center().y))
	await _draw()
	var seek: int = main.replay.scrub_tick
	_check(not main.replay.playing and seek > paused_tick and seek < main.replay.max_tick(), "native slider seeks retained clock and remains paused")
	await _key("Right")
	_check(main.replay.scrub_tick == seek + 6 and not main.replay.playing, "original right step remains6 ticks and pauses")
	await _key("Left")
	_check(main.replay.scrub_tick == seek and not main.replay.playing, "original left step reverses exactly")
	var ev: Dictionary = source.events[5]
	main._focus_battle_event(ev) # Original event API; native automatic clock is separately exercised.
	await _draw()
	_check(main.replay.scrub_tick == main.replay.playback_time(ev) and not main.replay.playing and view._event_ring.visible, "event seeks original saved identity/time and pauses")
	_unchanged("event seek")
	await _key("equal")
	_check(float(main.replay.get("speed")) == 2.0, "original plus key selects2x replay")
	await _key("p")
	await _key("Escape")
	_check(main.pause_overlay.is_open(), "native Escape opens original settings")
	var menu_tick: int = main.replay.scrub_tick
	await create_timer(0.25).timeout
	await _draw()
	_check(main.replay.scrub_tick == menu_tick, "original settings gate auto-play without time debt")
	await _key("Escape")
	await _draw()
	_check(not main.pause_overlay.is_open() and main.replay.playing and main.replay.scrub_tick > menu_tick, "closing original menu resumes prior playback state")
	main.handle_app_focus_out()
	var focus_tick: int = main.replay.scrub_tick
	await create_timer(0.25).timeout
	await _draw()
	main.handle_app_focus_in()
	await _draw()
	_check(not main.replay.playing and main.replay.scrub_tick == focus_tick, "focus return stays paused until explicit continue")
	_unchanged("focus gate")
	await _native_click(pause)
	# Run all remaining frames under the real engine callback; no manual cursor samples.
	var deadline := Time.get_ticks_msec() + 30000
	while main.replay.playing and Time.get_ticks_msec() < deadline:
		await process_frame
	await _draw()
	_check(main.phase == main.Phase.REPLAY and not main.replay.playing and main.replay.scrub_tick == main.replay.max_tick(), "native automatic playback reaches the actual recorded endpoint and stops")
	_check(view.frame.recorded_phase == main.Phase.WON and view.frame.attempt_id == source.attempt_id, "terminal presentation retains original WON identity")
	_unchanged("native endpoint")
	await _modal_capture(sample + "_endpoint")
	await _native_click(pause)
	_check(main.replay.playing and main.replay.scrub_tick < main.replay.max_tick(), "native terminal control restarts the same recording")
	await _key("p")
	await _key("space")
	_check(main.phase == main.Phase.WON and not main.replay.playing, "original space binding returns to WON and stops history transport")
	main.set_process(false)
	_check(_state(source) == retained, "return leaves original recording unchanged")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	_clock_cases()
	await _prepare()
	if DisplayServer.get_name() == "headless":
		main._on_replay_pressed()
		var start: int = main.replay.scrub_tick
		main._process(0.5)
		_check(main.replay.playing and main.replay.scrub_tick == start + 60, "production REPLAY process drives independent2x clock")
	else:
		await _native_case(false)
		await _native_case(true)
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/replay-auto-" + ("headless" if DisplayServer.get_name() == "headless" else "render") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows,"captures":captures,"native_inputs":input_rows},"  "))
	print("REPLAY_AUTO_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
