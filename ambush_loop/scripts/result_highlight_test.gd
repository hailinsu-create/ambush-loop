extends "res://scripts/viewport_hud_test.gd"
## Bounded result-copy fixtures, not a native player journey or closed-route QA.
const Payoff := preload("res://scripts/replay/payoff.gd")
const Log := preload("res://scripts/replay/battle_log.gd")
var result_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("RESULT_HIGHLIGHT_FAIL " + sample + " " + message)

func _assert_copy(won: bool, label: String) -> void:
	var expected := "泵站封锁完成" if won else "泵站尚未封锁"
	var before: Dictionary = main._snapshot_data().duplicate(true)
	var fingerprint: String = main.battle_log.fingerprint()
	var clock := [main.sim.tick, main.sim.paused, main.sim.speed, main.sim._accum]
	_check(main.highlight_result_text() == expected, label + " result formatter gives factual neutral outcome")
	if won:
		main._fill_result_stats()
		_check(main.result_stats_block_text().contains("高光  " + expected), label + " stats use the same factual neutral outcome")
		_check(not main.result_stats_block_text().contains(main.level.highlight_hook), label + " stats do not claim the authored locked-door goal")
		_check(main.result_label.text.contains(expected), label + " original result body displays neutral outcome")
		_check(not main.result_label.text.contains(main.level.highlight_hook), label + " original result body does not claim an unproven purple-route goal")
	else:
		_check(main.fail_dossier_text().contains(expected), label + " original failure dossier displays unfinished outcome")
		_check(not main.fail_dossier_text().contains("打中过：" + main.level.highlight_hook), label + " failure route event alone never invents a covered-route achievement")
	_check(main._snapshot_data() == before and main.battle_log.fingerprint() == fingerprint and [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum] == clock, label + " formatting keeps battle state, recording and clock unchanged")
	result_rows.append({"case":label,"phase":main.phase,"door_locked":main.door_locked,"door_events":main.battle_log.events.filter(func(event: Dictionary) -> bool: return event.type == "door"),"route_choice":main.battle_log.events.filter(func(event: Dictionary) -> bool: return event.type == "route_choice"),"terminal":main.battle_log.terminal_tick,"formatter":main.highlight_result_text(),"stats":main.result_stats_block_text(),"result_body":main.result_label.text,"failure_dossier":main.fail_dossier_text()})

func _domain_case(locked: bool, wins: bool) -> void:
	sample = "pump_highlight_" + ("locked" if locked else "open") + ("_won" if wins else "_failed")
	main._load_level("pump",false,false)
	main.raid_prepare_ref([1,4,5],[90.0,180.0 if locked and wins else 0.0,180.0])
	if locked: main._on_door_pressed()
	_check(main.door_locked == locked, "fixture uses original SCOUT door command")
	for wave in main.level.wave_count():
		main.raid_force_alarm()
		var steps := 0
		while main.phase == main.Phase.WATCHING and steps < 12000:
			main._sim_tick()
			steps += 1
		if main.phase == main.Phase.FAILED: break
		_check(main.phase == main.Phase.SWEEP,"reference domain wave naturally reaches SWEEP " + str(wave))
		if main.phase != main.Phase.SWEEP: return
		main.raid_vacuum_loot()
		if wave + 1 == main.level.wave_count(): main._on_sweep_commit()
		await process_frame
	_check(main.phase == (main.Phase.WON if wins else main.Phase.FAILED), "reference domain reaches actual expected terminal")
	_check(main.battle_log.has_type("route_choice") == locked, "actual domain recording distinguishes open and locked branch")
	_assert_copy(wins,sample)
	if DisplayServer.get_name() != "headless":
		view.refresh()
		await process_frame
		await create_timer(0.5).timeout
		await _modal_capture(sample)
		if not wins:
			var before: Dictionary = main._snapshot_data().duplicate(true)
			await _native_click(main.dossier_button)
			_check(main._dossier_open, "native original dossier button opens failure copy")
			_check(main._snapshot_data() == before, "native dossier opening leaves failed battle state unchanged")
			await _modal_capture(sample + "_dossier")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.position = Vector2i.ZERO
	root.content_scale_factor = 1.0
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	settings.mark_tutorial_seen("yard")
	settings.mark_tutorial_seen("pump")
	settings.pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	view.set_process(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	var path := OS.get_environment("AMBUSH_NATIVE_RECORD")
	_check(FileAccess.file_exists(path), "actual030 native pump recording exists")
	if not FileAccess.file_exists(path): quit(2); return
	var original_hash := FileAccess.get_sha256(path)
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var actual := Log.new()
	for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]: actual.set(key,raw[key])
	var pump := LevelDef.by_id("pump")
	_check(actual.terminal_reason == "win" and actual.terminal_tick == 935 and not actual.has_type("route_choice") and actual.first_of_type("door").payload.locked == false,"authentic actual030 open-door source retained")
	_check(Payoff.highlight_result_line(pump,actual,true) == "泵站封锁完成","actual030 open-door win must not claim locked purple-route achievement")
	_check(FileAccess.get_sha256(path) == original_hash,"original native source bytes unchanged")
	result_rows.append({"case":"authentic030_readonly_formatter","path":path,"raw_sha256":original_hash,"attempt":actual.attempt_id,"formatter":Payoff.highlight_result_line(pump,actual,true),"scope":"Original native record read only; no replay binding/rendering or source rewrite."})
	await _domain_case(false,true)
	await _domain_case(true,true)
	await _domain_case(true,false)
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/result-highlight-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":result_rows,"captures":captures,"window":[root.size.x,root.size.y],"scale":root.content_scale_factor,"scope":"Bounded reference domain SCOUT door command, grants/cover snaps, direct tick and vacuum fixtures reach original terminal UI; not normal input, not native journey, not closed-route performance/art QA. Authentic030 source only read by formatter. No replay mutation."},"  "))
	print("RESULT_HIGHLIGHT_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
