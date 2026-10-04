extends "res://scripts/viewport_hud_test.gd"
## Current-wave display fixtures plus one original radio reference traversal.
const Log := preload("res://scripts/replay/battle_log.gd")
var strip_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("LIVE_WAVE_TIMELINE_FAIL " + sample + " " + message)

func _dots(specs: Array) -> Array:
	return specs.map(func(p: Dictionary) -> Array: return [int(p.id),str(p.route),float(p.delay)])

func _assert_strip(label: String) -> void:
	var before: Dictionary = main._snapshot_data().duplicate(true)
	var fingerprint: String = main.battle_log.fingerprint()
	var clock := [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum]
	main._refresh_watch_timeline()
	var bar = main.watch_timeline
	var shown: bool = main.phase in [main.Phase.SETUP,main.Phase.WATCHING]
	_check(bar.visible == shown,label + " current strip visibility follows live phase")
	if shown:
		var specs: Array = main.pending_spawns if main.phase == main.Phase.WATCHING else main.level.spawns_for_wave(main.raid.wave_index)
		_check(_dots(bar.marks) == _dots(specs),label + " dots use exactly original current-wave actors/routes/delays")
		_check(str(bar.get("context_label")).contains("第%d/%d波" % [main.raid.wave_index+1,main.level.wave_count()]),label + " caption explicitly identifies current wave")
		_check(is_equal_approx(float(bar.elapsed),main.sim.time_sec() if main.phase == main.Phase.WATCHING else 0.0),label + " playhead uses original local clock")
		if main.phase == main.Phase.WATCHING:
			var pending: bool = main.pending_spawns.any(func(p: Dictionary) -> bool: return not bool(p.spawned))
			var echo: bool = main.pending_spawns.any(func(p: Dictionary) -> bool: return p.route == "echo" and not bool(p.spawned))
			_check(bar.pending_breathing() == pending,label + " breathing follows actual unspawned state, including due tick")
			_check(bar.echo_mark_pending() == echo,label + " echo cue never uses another wave")
	else:
		_check(bar.marks.is_empty() and bar.payoff_marks.is_empty() and not bar.live,label + " hidden SWEEP/history keeps no live dots or payoff")
	_check(main._snapshot_data() == before and main.battle_log.fingerprint() == fingerprint and [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum] == clock,label + " strip leaves state/source/clock unchanged")
	strip_rows.append({"case":sample,"moment":label,"phase":main.phase,"wave":main.raid.wave_index,"tick":main.sim.tick,"paused":main.sim.paused,"dots":bar.marks.duplicate(true),"payoff":bar.payoff_marks.duplicate(true),"caption":bar.get("context_label"),"elapsed":bar.elapsed})

func _assert_payoff(label: String, expected: Array) -> void:
	var raw := var_to_bytes(main.battle_log.events)
	main._refresh_watch_timeline()
	_check(main.watch_timeline.payoff_marks == expected,label + " refresh uses only stored current attempt/wave local events")
	main._sync_payoff_timelines()
	_check(main.watch_timeline.payoff_marks == expected,label + " immediate payoff callback cannot reinsert earlier wave")
	_check(var_to_bytes(main.battle_log.events) == raw,label + " original event identities/stamps/payloads are not rewritten")

func _matrix(mode: String) -> void:
	for id in ["yard","warehouse","pump","railcut","depot","radio"]:
		main._load_level(id,false,false)
		await process_frame
		for wave in main.level.wave_count():
			sample = "reference_" + mode + "_" + id + "_wave" + str(wave)
			main.raid.wave_index = wave
			main.sim.reset()
			main.phase = main.Phase.SETUP # Explicit display data, not actual13 battles.
			_assert_strip("scout_wave_preview")
			main.phase = main.Phase.WATCHING
			main._queue_spawns(main.run_id)
			_assert_strip("alarm_before_any_spawn")
			var latest := 0.0
			for p in main.pending_spawns: latest = maxf(latest,float(p.delay))
			main.sim.tick = roundi(latest*60.0)
			for p in main.pending_spawns: p.spawned = float(p.delay) < latest
			_assert_strip("due_last_actor_not_spawned")
			main._on_pause_pressed()
			_assert_strip("paused_due")
			main._on_pause_pressed()
			for p in main.pending_spawns: p.spawned = true
			main.sim.tick = 120
			_assert_strip("all_current_wave_spawned")
			var attempt := "display-fixture-" + id
			main.battle_log.begin_attempt(attempt)
			main.battle_log.wave_id = wave
			var other := (wave+1)%main.level.wave_count()
			main.battle_log.events = [
				{"type":"fire","tick":6,"timeline_tick":4006,"wave_id":other,"attempt_id":attempt,"event_id":attempt+":other:0","seq":0,"payload":{"name":"前波"}},
				{"type":"repack","tick":8,"wave_id":other,"attempt_id":attempt,"event_id":attempt+":other:1","seq":1},
				{"type":"fire","tick":10,"wave_id":wave,"attempt_id":"foreign","event_id":"foreign:0","seq":0,"payload":{"name":"异源"}},
				{"type":"fire","tick":12,"timeline_tick":4012,"wave_id":wave,"attempt_id":attempt,"event_id":attempt+":current:2","seq":2,"payload":{"name":"本波"}},
				{"type":"repack","tick":14,"wave_id":wave,"attempt_id":attempt,"event_id":attempt+":current:3","seq":3}]
			for event in main.battle_log.events:
				event["actor_id"] = 1
				event["target_id"] = 1
				event["position"] = Vector2.ZERO
				if not event.has("payload"): event["payload"] = {}
			_assert_payoff("explicit_other_wave_and_foreign_attempt",[{"t":0.2,"kind":"first_fire","label":"本"},{"t":14.0/60.0,"kind":"repack","label":"包"}])
			main.phase = main.Phase.SWEEP
			_assert_strip("sweep_hidden")
			main._refresh_route_timeline(true)
			_check(str(main.route_timeline.get("context_label")).contains("全关预览") and _dots(main.route_timeline.marks) == _dots(main.level.spawn_schedule),"whole-level teaching table is explicitly a preview")
			_check(main.route_timeline.payoff_marks.is_empty(),"teaching preview never mixes actual local payoff stamps")

func _scene(mode: String) -> void:
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn" if mode == "3d" else "res://scenes/main.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	if is_instance_valid(view): view.set_process(false)

func _radio_reference() -> void:
	await _scene("3d")
	sample = "actual_radio_reference"
	main._load_level("radio",false,false)
	await process_frame
	for index in 3:
		for stash in main.raid_stashes:
			if main.WeaponCatalogScript.family_of(stash.kind) == ["rifle","mg","scout"][index]:
				main.operators[index].receive_item(stash.kind,stash.amount)
				break
	main.raid_prepare_ref([1,4,5],[270.0,90.0,270.0],{"grenades":0,"mines":0})
	main.raid_force_alarm()
	for wave in 3:
		_assert_strip("actual_wave_start_"+str(wave))
		_assert_payoff("actual_no_current_fire_at_start_"+str(wave),[])
		if wave == 2:
			while main.sim.tick < 30: main._sim_tick()
			_assert_strip("actual_echo_due_tick30")
			main._sim_tick()
			_assert_strip("actual_echo_event_tick30_done")
			while main.sim.tick < 84: main._sim_tick()
			if DisplayServer.get_name() != "headless": await _native_click(main.pause_button)
			else: main._on_pause_pressed()
			main._update_hud()
			_assert_strip("actual_paused_final_wave_1_4s")
			_check(main.sim.paused and main.watch_clock_text() == "t=1.4s","actual visible paused clock")
			if DisplayServer.get_name() != "headless":
				view.refresh()
				await _modal_capture("live_strip_radio_paused_final_wave")
				await _native_click(main.pause_button)
			else: main._on_pause_pressed()
		while main.phase == main.Phase.WATCHING and main.sim.tick < 12000: main._sim_tick()
		_check(main.phase == main.Phase.SWEEP,"actual original reference wave clears " + str(wave))
		if main.phase != main.Phase.SWEEP: return
		_assert_strip("actual_sweep_"+str(wave))
		main.raid_vacuum_loot()
		if wave < 2: main._on_sweep_commit()
	var source = main.battle_log
	var source_attempt: String = source.attempt_id
	main._on_replay_pressed()
	main._on_pause_pressed()
	var fingerprint: String = source.fingerprint()
	var clocks := [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum]
	for tick in [0,main.replay.max_tick(),0,main.replay.max_tick()/2,main.replay.max_tick()]:
		main.replay.set_tick(int(tick))
		main._apply_replay_scrub()
		_assert_strip("history_seek_"+str(tick))
		main._sync_payoff_timelines()
		_check(main.watch_timeline.payoff_marks.is_empty(),"late payoff sync in history stays empty")
	_check(source.fingerprint() == fingerprint and [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum] == clocks,"history seeks preserve original source and simulation clock")
	var path := "res://build/asset_review/pr15-runtime/live-strip-reference-record.bin"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(var_to_bytes({"attempt_id":source.attempt_id,"events":source.events,"snapshots":source.snapshots,"terminal_tick":source.terminal_tick,"terminal_reason":source.terminal_reason,"playback_schema":source.playback_schema,"playback_snapshots":source.playback_snapshots,"playback_terminal_tick":source.playback_terminal_tick}))
	file.close()
	var sha := FileAccess.get_sha256(path)
	if DisplayServer.get_name() != "headless":
		view.refresh()
		await _modal_capture("live_strip_history_seek_no_live")
	main._on_alarm_pressed() # Existing SWEEP replay exit starts a new SCOUT attempt.
	_check(main.phase == main.Phase.SETUP and main.battle_log.attempt_id != source_attempt and main.sim.tick == 0,"original history exit resets live attempt/wave clock")
	_assert_strip("actual_exit_to_new_scout")
	_check(main.watch_timeline.payoff_marks.is_empty() and FileAccess.get_sha256(path) == sha,"new live preview has no old payoff; saved reference bytes unchanged")
	strip_rows.append({"case":"saved_reference_boundary","attempt":source_attempt,"raw_sha256":sha,"scope":"Original3-wave radio reference reaches last SWEEP; history seeks are original callbacks. Exit resets old active log by existing begin_attempt, never rewrites saved bytes. Not normal input, terminal WON or full replay acceptance."})
	if DisplayServer.get_name() != "headless":
		main._update_hud()
		view.refresh()
		await _modal_capture("live_strip_exit_new_scout")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.position = Vector2i.ZERO
	root.content_scale_factor = 1.0
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	for id in ["yard","warehouse","pump","railcut","depot","radio"]: settings.mark_tutorial_seen(id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	for mode in ["3d","legacy2d"]:
		await _scene(mode)
		await _matrix(mode)
	await _radio_reference()
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/live-wave-timeline-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":strip_rows,"captures":captures,"native_inputs":input_rows,"scope":"13-wave matrix in2modes assigns phase/index/tick/spawned/events explicitly. One actual radio reference grants authored guns/snaps/direct tick/vacuum, reaches3 SWEEP/seek/exit SCOUT. No26 real battles, normal fresh13, full equipment/replay/FX/A3/device/terminal acceptance."},"  "))
	print("LIVE_WAVE_TIMELINE_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
