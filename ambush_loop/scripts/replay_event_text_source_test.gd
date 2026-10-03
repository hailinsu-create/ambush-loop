extends "res://scripts/replay_autoplay_test.gd"
## Controlled API source replacement; ordinary UI reachability is not asserted.
var auto_frames := 0

class TextProbe extends Node:
	var suite: SceneTree
	var host: Node
	var rate := 1.0
	var origin := 0
	var elapsed_ticks := 0.0
	var ticks := []
	func _process(delta: float) -> void:
		elapsed_ticks += delta * rate * 60.0
		suite._check(host.replay.scrub_tick == mini(origin + floori(elapsed_ticks + 0.000001), host.replay.max_tick()), "real engine callback advances selected source at " + str(rate) + "x")
		suite._assert_display("automatic")
		ticks.append(host.replay.scrub_tick)
		suite.auto_frames += 1

func _assert_display(label: String) -> void:
	var expected: Array = main.replay.events_up_to(main.replay.scrub_tick)
	var count := mini(12, expected.size())
	var valid: bool = main.event_list.item_count == count and main._event_list_items.size() == count
	for i in count:
		var ev: Dictionary = expected[expected.size() - count + i]
		valid = valid and main._event_list_items[i] == ev and main.event_list.get_item_text(i) == source.format_event(ev)
	_check(valid, label + " event list matches saved prefix and source formatter")
	view.refresh()
	var snap: Dictionary = main.replay.snapshot_at_or_before(main.replay.scrub_tick)
	var equipment := true
	for i in snap.data.get("ops", []).size():
		var op: Dictionary = snap.data.ops[i]
		equipment = equipment and view.frame.ops[i].weapon == str(op.get("weapon", ""))
	_check(main.replay.log == source and view.frame.attempt_id == snap.attempt_id and view.frame.wave_id == snap.wave_id and view.frame.frame_seq == snap.frame_seq and equipment, label + " real3D identity/frame/equipment come from the bound snapshot")

func _focus_text(ev: Dictionary, label: String) -> void:
	main._focus_battle_event(ev)
	_assert_display(label)
	_check(main.status_label.text == "定位 · " + source.format_event(ev) and main.replay.scrub_tick == main.replay.playback_time(ev) and not main.replay.playing and view._event_ring.visible, label + " focuses exact saved event/time/text and pauses")

func _exercise_source(label: String) -> void:
	sample = label
	live = main._snapshot_data().duplicate(true)
	sim_state = [main.sim.tick, main.sim.speed, main.sim.paused, main.sim._accum]
	var shot: Dictionary = source.first_of_type("fire")
	var later: Dictionary = source.last_of_type("fire")
	_check(shot.event_id != later.event_id and source.format_event(shot).contains("★") and not source.format_event(later).contains("★"), label + " has distinct named first and later shots")
	_focus_text(shot, label + " initial")
	var original_frame: Dictionary = view.frame.duplicate(true)
	var original_bones := _bones()
	for kind in ["no_fire", "colliding_seq"]:
		var foreign := BattleLog.new()
		foreign.begin_attempt(label + "-live-" + kind)
		foreign.add_snapshot(0, {"phase":0})
		if kind == "colliding_seq":
			for i in int(later.seq): foreign.add_event(0, "spawn", i)
			foreign.add_event(1, "fire", 99, 99, Vector2.ZERO, {"name":"无关队员"})
		foreign.add_snapshot(4, {"phase":3})
		foreign.mark_terminal(4, "won")
		var saved := _state(foreign)
		main.battle_log = foreign
		_focus_text(shot, label + " " + kind)
		_check(view.frame == original_frame and _bones() == original_bones, label + " live replacement preserves entire first-shot frame/root/20bones")
		if DisplayServer.get_name() != "headless": await _modal_capture(label + "_" + kind + "_first")
		_focus_text(later, label + " later " + kind)
		for tick in [main.replay.max_tick(), main.replay.playback_time(shot) - 1, main.replay.playback_time(shot), main.replay.playback_time(later), 0, main.replay.playback_time(shot)]:
			main.replay.set_tick(tick)
			main._apply_replay_scrub()
			_assert_display(label + " seek " + str(tick))
		_check(main.focus_latest_of_type("fire"), label + " type focus resolves historical source")
		_check(main.status_label.text == "定位 · " + source.format_event(later) and main.replay.scrub_tick == main.replay.playback_time(later), label + " type focus ignores live event/seq")
		# Exercise the existing RichTextLabel fallback, then restore the ItemList.
		var saved_list = main.event_list
		var saved_log = main.event_log
		var fallback := RichTextLabel.new()
		main.add_child(fallback)
		main.event_list = null
		main.event_log = fallback
		main._fill_event_list([shot, later], 2, "历史测试")
		_check(fallback.text == "[b]历史测试[/b]\n" + source.format_event(shot) + "\n" + source.format_event(later), label + " fallback text also uses bound record")
		main.event_list = saved_list
		main.event_log = saved_log
		fallback.queue_free()
		# The normal live branch must retain its own contextual first-shot label.
		main.phase = main.Phase.WATCHING
		main._fill_event_list(foreign.events, 12, "现场测试")
		var last_index: int = main.event_list.item_count - 1
		_check(main.event_list.get_item_text(last_index) == foreign.format_event(foreign.events.back()), label + " live phase retains live formatter")
		main.phase = main.Phase.REPLAY
		for rate in [1.0, 2.0]:
			main.replay.set_tick(main.replay.playback_time(shot) - 4)
			main._apply_replay_scrub()
			main.replay.set_speed(rate)
			main.replay.play()
			var probe := TextProbe.new()
			probe.suite = self
			probe.host = main
			probe.rate = rate
			probe.origin = main.replay.scrub_tick
			probe.process_priority = 50
			root.add_child(probe)
			main.set_process(true)
			var deadline := Time.get_ticks_msec() + 15000
			while (probe.ticks.size() < 8 or main.replay.scrub_tick <= main.replay.playback_time(shot) + 4) and Time.get_ticks_msec() < deadline:
				await process_frame
			main.set_process(false)
			probe.set_process(false)
			main.replay.pause()
			_check(probe.ticks.size() >= 8 and main.replay.scrub_tick > main.replay.playback_time(shot) + 4, label + " natural " + str(rate) + "x crosses original first shot")
			rows.append({"source":label,"live":kind,"rate":rate,"origin":probe.origin,"natural_ticks":probe.ticks.duplicate(),"endpoint":main.replay.scrub_tick,"attempt":source.attempt_id})
			probe.queue_free()
			_focus_text(shot, label + " focus after auto " + str(rate))
			if DisplayServer.get_name() != "headless": await _modal_capture(label + "_" + kind + "_auto" + str(int(rate)))
		_check(_state(foreign) == saved and _state(source) == retained and [main.sim.tick, main.sim.speed, main.sim.paused, main.sim._accum] == sim_state, label + " automatic/seek/focus never mutates either record or SimClock")
		main.battle_log = source
		_unchanged(label + " restores original live source")
	# Null binding must not silently borrow current live events.
	main.replay.bind(null)
	_check(not main.focus_latest_of_type("fire"), label + " null history cannot focus live fire")
	main._update_event_log()
	_check(main.event_list.item_count == 0, label + " null history list is empty")
	main.replay.bind(source)
	_focus_text(shot, label + " rebound")
	main._update_event_log()
	_check(main.event_list.get_item_text(main.event_list.item_count - 1) == source.format_event(shot), label + " general log refresh uses selected historical prefix")

func _run() -> void:
	var path := OS.get_environment("AMBUSH_LEGACY_RECORD_FIXTURE")
	if path.is_empty() or not FileAccess.file_exists(path):
		_check(false, "authentic saved fixture exists")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.position = Vector2i.ZERO
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
	view.set_process(false)
	var values: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	source = BattleLog.new()
	for key in values: source.set(key, values[key])
	retained = _state(source)
	# Terminal UI fixture, not a claimed player victory.
	main.battle_log = source
	main.phase = main.Phase.WON
	main._show_win_result()
	main._on_replay_pressed()
	var shot: Dictionary = source.first_of_type("fire")
	_check(not shot.is_empty() and str(shot.payload.get("name", "")) != "", "authentic source contains named first shot")
	main._focus_battle_event(shot)
	view.refresh()
	var expected: String = source.format_event(shot)
	_check(main.status_label.text == "定位 · " + expected, "baseline first-shot status")
	if DisplayServer.get_name() != "headless":
		await _modal_capture("bound_text_original")
	var foreign := BattleLog.new()
	foreign.begin_attempt("unrelated-live-log-with-no-shots")
	foreign.add_snapshot(0, {"phase":0})
	foreign.add_snapshot(4, {"phase":3})
	foreign.mark_terminal(4, "won")
	var foreign_before := _state(foreign)
	main.battle_log = foreign
	main._focus_battle_event(shot)
	view.refresh()
	var list_text := ""
	for i in main._event_list_items.size():
		if main._event_list_items[i].event_id == shot.event_id:
			list_text = main.event_list.get_item_text(i)
	_check(main.replay.log == source and view.frame.attempt_id == source.attempt_id and view._event_ring.visible, "historical source and actual3D focus remain bound")
	_check(main.status_label.text == "定位 · " + expected, "status ignores unrelated live formatter")
	_check(list_text == expected, "event list ignores unrelated live formatter")
	_check(_state(source) == retained and _state(foreign) == foreign_before, "both records remain unchanged")
	if DisplayServer.get_name() != "headless":
		await _modal_capture("bound_text_live_replaced")
	var minimal := {"checks":checks,"failures":failures,"expected":expected,"actual_status":main.status_label.text,"actual_list":list_text,"attempt":source.attempt_id,"event_id":shot.event_id,"cursor":main.replay.scrub_tick}
	var hash_before := FileAccess.get_sha256(path)
	main.battle_log = source
	await _exercise_source("actual_schema1")
	var legacy := source
	var legacy_saved := retained.duplicate(true)
	await _prepare()
	main._on_replay_pressed()
	main.replay.pause()
	await _exercise_source("actual_schema2_reference")
	var modern := source
	var modern_saved := retained.duplicate(true)
	# Rebind two authentic sources in both directions; no source upgrade.
	for bound in [legacy, modern, legacy]:
		source = bound
		main.replay.bind(bound)
		_focus_text(bound.first_of_type("fire"), "source rebind schema" + str(bound.playback_schema))
	_check(_state(legacy) == legacy_saved and _state(modern) == modern_saved and FileAccess.get_sha256(path) == hash_before and hash_before == "1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12", "authentic old bytes and both recording schemas remain unchanged after source rebinds")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/replay-event-text-" + ("headless" if DisplayServer.get_name() == "headless" else "render") + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"minimal":minimal,"rows":rows,"natural_callback_frames":auto_frames,"legacy_file_sha256":hash_before,"captures":captures,"controlled_api_swap":true,"ordinary_ui_swap_reachability":"unproven","reference_battle_is_player_victory":false}, "  "))
	print("BOUND_TEXT checks=", checks, " failures=", failures)
	root.get_node("AudioDirector").pause_for_background()
	quit(1 if failures > 0 else 0)
