extends "res://scripts/viewport_hud_test.gd"
## Wave-clock display contract. Matrix assignments are explicit reference data.
const Log := preload("res://scripts/replay/battle_log.gd")
# Earliest future actor/delay/route in each original wave, independently listed.
const EXPECTED := {
	"yard":[[2,0.6,"main"],[3,0.2,"flank"]],
	"warehouse":[[3,0.8,"main"],[2,0.3,"flank"]],
	"pump":[[3,0.7,"main"],[2,0.3,"flank"]],
	"railcut":[[2,0.6,"main"],[3,0.4,"flank"]],
	"depot":[[2,0.4,"flank"],[3,0.4,"sneak"]],
	"radio":[[2,0.4,"flank"],[3,0.4,"sneak"],[5,0.5,"echo"]]}
var hint_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("CURRENT_WAVE_HINT_FAIL " + sample + " " + message)

func _query(label: String, id: int, remain: float) -> void:
	var before: Dictionary = main._snapshot_data().duplicate(true)
	var events: String = main.battle_log.fingerprint()
	var clock := [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum]
	var queue: Array = main.pending_spawns.duplicate(true)
	var info: Dictionary = main._next_wave_info()
	_check(bool(info.pending) == (id >= 0), label + " pending follows only current actual queue")
	if id >= 0:
		_check(int(info.get("id",-1)) == id, label + " exact current-wave actor")
		_check(is_equal_approx(float(info.remain),remain), label + " remaining seconds use original local wave clock")
	main._refresh_touch_hud()
	if main.phase == main.Phase.WATCHING:
		_check(main.watch_wave_chip.visible == (id >= 0), label + " desktop hint visibility agrees with queue")
		if id >= 0: _check(main.watch_wave_chip.text == main._next_wave_line(), label + " desktop uses same local clock")
		root.get_node("GameSettings").set_force_touch_hud(true)
		main._refresh_touch_hud()
		_check(main.touch_hud._wave_chip.visible == (id >= 0), label + " touch hint visibility agrees with queue")
		if id >= 0: _check(main.touch_hud._wave_lab.text.contains("%.1fs" % remain), label + " touch seconds agree with local clock")
		root.get_node("GameSettings").set_force_touch_hud(false)
		main._refresh_touch_hud()
	_check(main._snapshot_data() == before and main.battle_log.fingerprint() == events and main.pending_spawns == queue and [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum] == clock, label + " display leaves state/log/queue/clock untouched")
	hint_rows.append({"case":sample,"moment":label,"wave":main.raid.wave_index,"tick":main.sim.tick,"phase":main.phase,"paused":main.sim.paused,"info":info,"desktop":main.watch_wave_chip.text,"queue":queue})

func _reference_matrix(mode: String) -> void:
	for id in EXPECTED:
		main._load_level(id,false,false)
		await process_frame
		_check(main.level.wave_count() == EXPECTED[id].size(), "original wave inventory " + id)
		for wave in EXPECTED[id].size():
			sample = "reference_" + mode + "_" + id + "_wave" + str(wave)
			# Display fixture, not a natural wave transition or full battle smoke.
			main.phase = main.Phase.WATCHING
			main.raid.wave_index = wave
			main.sim.reset()
			main.intel.clear()
			main._queue_spawns(main.run_id)
			var authored: Array = main.level.spawns_for_wave(wave)
			_check(main.pending_spawns.map(func(p: Dictionary) -> int: return int(p.id)) == authored.map(func(p: Dictionary) -> int: return int(p.id)), "queue is exactly this original wave's actor set")
			for p in main.pending_spawns: p.spawned = is_zero_approx(float(p.delay))
			var expected: Array = EXPECTED[id][wave]
			_query("local_zero",int(expected[0]),float(expected[1]))
			main.sim.tick = roundi(float(expected[1])*60.0)-1
			_query("one_tick_before_actual_spawn",int(expected[0]),1.0/60.0)
			main._on_pause_pressed()
			var tick: int = main.sim.tick
			_check(main.sim.paused and main.sim.steps_for_frame(1.0) == 0 and main.sim.tick == tick,"paused ALERT keeps original local clock frozen")
			_query("paused_one_tick_before",int(expected[0]),1.0/60.0)
			main._on_pause_pressed()
			# Terminal/intel eligibility preserves its original cut semantics.
			main.phase = main.Phase.FAILED
			main.sim.tick = 6
			main.intel.records = [{"cut_sec":0.05}]
			_query("terminal_cut_reference",int(expected[0]),float(expected[1])-0.1)
			_check(is_equal_approx(float(main._next_wave_info().intel_cut),0.05),"terminal retains original intel cut")
			main.phase = main.Phase.WATCHING
			main.intel.clear()
			main.sim.tick = 84
			for p in main.pending_spawns: p.spawned = true
			_query("all_current_wave_spawned_at_1_4s",-1,0.0)

func _scene(mode: String) -> void:
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn" if mode == "3d" else "res://scenes/main.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	if is_instance_valid(view): view.set_process(false)

func _actual_radio_reference() -> void:
	await _scene("3d")
	sample = "actual_domain_reference_radio"
	main._load_level("radio",false,false)
	await process_frame
	for index in 3:
		for stash in main.raid_stashes:
			if main.WeaponCatalogScript.family_of(stash.kind) == ["rifle","mg","scout"][index]:
				main.operators[index].receive_item(stash.kind,stash.amount)
				break
	main.raid_prepare_ref([1,4,5],[270.0,90.0,270.0],{"grenades":0,"mines":0})
	main.raid_force_alarm()
	for wave in 2:
		var steps := 0
		while main.phase == main.Phase.WATCHING and steps < 12000:
			main._sim_tick()
			steps += 1
		_check(main.phase == main.Phase.SWEEP, "reference actual original wave clears " + str(wave))
		if main.phase != main.Phase.SWEEP: return
		main.raid_vacuum_loot()
		main._on_sweep_commit()
	_check(main.phase == main.Phase.WATCHING and main.raid.wave_index == 2 and main.sim.tick == 0,"original transitions reset actual final-wave local clock")
	_query("actual_final_wave_start",5,0.5)
	while main.sim.tick < 29: main._sim_tick()
	_query("actual_tick29_before_echo",5,1.0/60.0)
	main._sim_tick()
	_query("actual_due_tick30_not_spawned_yet",5,0.0)
	main._sim_tick()
	var echo: Array = main.battle_log.events.filter(func(e: Dictionary) -> bool: return e.type == "spawn" and int(e.wave_id) == 2)
	_check(echo.size() == 1 and int(echo[0].actor_id) == 5 and int(echo[0].tick) == 30,"actual original echo event is id5/wave2/localtick30")
	_query("actual_echo_spawned",-1,0.0)
	while main.sim.tick < 84 and main.phase == main.Phase.WATCHING: main._sim_tick()
	_check(main.phase == main.Phase.WATCHING and main.sim.tick == 84,"reference reaches actual ALERT t1.4")
	if DisplayServer.get_name() != "headless": await _native_click(main.pause_button)
	else: main._on_pause_pressed()
	_query("actual_paused_final_wave_1_4s",-1,0.0)
	_check(main.sim.paused,"original pause command freezes actual final wave")
	var before_draw: Dictionary = main._snapshot_data().duplicate(true)
	var draw_log: String = main.battle_log.fingerprint()
	main._update_hud() # Auto process is disabled in this reference fixture.
	var banner: Label = main._watch_letterbox.get_node("WatchBanner")
	_check(main.watch_clock_text() == "t=1.4s" and banner.text.contains("第3/3波") and banner.text.contains("暂停") and banner.text.contains("t=1.4s") and banner.text.contains("待0"),"actual visible HUD is paused final wave1.4s with zero pending")
	_check(main._snapshot_data() == before_draw and main.battle_log.fingerprint() == draw_log,"original full HUD refresh preserves paused state/log")
	hint_rows.append({"case":"actual_draw_clock","clock":main.watch_clock_text(),"banner":banner.text,"tick":main.sim.tick,"paused":main.sim.paused,"scope":"Original HUD explicitly refreshed because reference driver disables automatic process; asserted before physical capture."})
	if DisplayServer.get_name() != "headless":
		view.refresh()
		for _i in 5: await process_frame
		await _modal_capture("wave_hint_actual_radio_paused_final_wave_1_4s")
		await _native_click(main.pause_button)
	else: main._on_pause_pressed()
	while main.phase == main.Phase.WATCHING and main.sim.tick < 12000: main._sim_tick()
	_check(main.phase == main.Phase.SWEEP,"original final wave clears")
	if main.phase != main.Phase.SWEEP: return
	main.raid_vacuum_loot()
	main._on_sweep_commit()
	_check(main.phase == main.Phase.WON,"original final extraction reaches WON")
	var source = main.battle_log
	var path := "res://build/asset_review/pr15-runtime/current-wave-reference-radio-record.bin"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(var_to_bytes({"attempt_id":source.attempt_id,"events":source.events,"snapshots":source.snapshots,"terminal_tick":source.terminal_tick,"terminal_reason":source.terminal_reason,"playback_schema":source.playback_schema,"playback_snapshots":source.playback_snapshots,"playback_terminal_tick":source.playback_terminal_tick}))
	file.close()
	var bytes_hash := FileAccess.get_sha256(path)
	main._on_replay_pressed()
	main._on_pause_pressed()
	var fingerprint: String = source.fingerprint()
	# Explicit live host contamination must never become historical hint data.
	main.pending_spawns.append({"id":99,"delay":20.0,"route":"sneak","spawned":false})
	for touch in [false,true]:
		root.get_node("GameSettings").set_force_touch_hud(touch)
		main._refresh_touch_hud()
		_check(not main.watch_wave_chip.visible and not main.touch_hud._wave_chip.visible and not bool(main._next_wave_info().pending),"bound history never reads live pending wave")
	_check(source.fingerprint() == fingerprint and FileAccess.get_sha256(path) == bytes_hash,"replay hint isolation preserves bound source/bytes")
	main._update_hud()
	_check(not main.replay.playing and main.phase_chip.text.contains("暂停"),"history visible transport agrees with original paused command")
	hint_rows.append({"case":"reference_record_history_boundary","record_sha256":bytes_hash,"attempt":source.attempt_id,"terminal_tick":source.terminal_tick,"events":source.events.size(),"playback_schema":source.playback_schema,"scope":"Reference authored-firearm grants/cover snap/direct tick/vacuum; not a normal input source or full replay acceptance."})
	if DisplayServer.get_name() != "headless":
		view.refresh()
		await _modal_capture("wave_hint_reference_history_no_live_hint")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.position = Vector2i.ZERO
	root.content_scale_factor = 1.0
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	for id in EXPECTED: settings.mark_tutorial_seen(id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	var path := OS.get_environment("AMBUSH_NATIVE_RECORD_DIR").path_join("native-player-radio-record.bin")
	var original_sha := FileAccess.get_sha256(path)
	_check(original_sha == "e584a89d86b60c2931e5d947b3ab2dba416801a4ea499f5b5685507ef8d7128f","actual3b native radio source hash")
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var echo: Array = raw.events.filter(func(e: Dictionary) -> bool: return e.type == "spawn" and int(e.wave_id) == 2)
	_check(echo.size() == 1 and int(echo[0].actor_id) == 5 and int(echo[0].tick) == 30,"original normal final wave contains only echo5/localtick30")
	_check(FileAccess.get_sha256(path) == original_sha,"original normal source bytes unchanged/read only")
	for mode in ["3d","legacy2d"]:
		await _scene(mode)
		await _reference_matrix(mode)
	await _actual_radio_reference()
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/current-wave-hint-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":hint_rows,"captures":captures,"native_inputs":input_rows,"scope":"Six-level13-wave timing display matrix in3D/legacy2D is explicitly synthetic phase/index/tick/spawned data; not actual26 battles. Actual radio reference uses original transitions/spawn event/pause/WON/history, with grants/snap/direct ticks/vacuum. Original normal3b source is read-only. No normal fresh fullsmoke, full replay, FX/performance/device acceptance."},"  "))
	print("CURRENT_WAVE_HINT_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
