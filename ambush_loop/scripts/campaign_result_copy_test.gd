extends "res://scripts/viewport_hud_test.gd"
## Result facts only. Reference grants/ticks/fixtures are not player journeys.
const Payoff := preload("res://scripts/replay/payoff.gd")
const Log := preload("res://scripts/replay/battle_log.gd")
const NAMES := {"yard":"院子","warehouse":"仓库","pump":"泵站","railcut":"信号楼","depot":"油库","radio":"电台"}
const RECORDS := {
	"warehouse":"63fccaa28ed9ff9f90729f458ebf695f05bac57cac9be0d58ec28c54ef17a08c",
	"pump":"48f2305b9dcdc562a8d0cb9c2ce44ca02ea474c579e91116b75d187960d96eb4",
	"railcut":"154c69778d82b3d7a35b32d7d5ebd8782cd792cb9edad82544495a125af86e53",
	"depot":"ec232057b98e04262fd60f4e44933c7545f396ded83be68a05cdea26b4ebb3e0",
	"radio":"e584a89d86b60c2931e5d947b3ab2dba416801a4ea499f5b5685507ef8d7128f"}
var result_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("CAMPAIGN_RESULT_COPY_FAIL " + sample + " " + message)

func _expected(id: String, won: bool) -> String:
	return str(NAMES.get(id,"")) + ("封锁完成" if won else "尚未封锁")

func _readonly_records() -> void:
	for id in RECORDS:
		sample = "original_native_" + id
		var path := OS.get_environment("AMBUSH_NATIVE_RECORD_DIR").path_join("native-player-" + id + "-record.bin")
		_check(FileAccess.file_exists(path), "original record exists")
		if not FileAccess.file_exists(path): continue
		var sha := FileAccess.get_sha256(path)
		_check(sha == RECORDS[id], "original fixed source SHA256")
		var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
		var actual := Log.new()
		for key in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:
			actual.set(key,raw[key])
		var before := actual.fingerprint()
		_check(actual.terminal_reason == "win", "actual original domain WON")
		if id == "warehouse": _check(not actual.has_type("repack"), "original assigned pack never reloaded")
		if id == "pump": _check(not actual.has_type("route_choice"), "original open door has no branch event")
		if id in ["depot","radio"]: _check(not actual.has_type("mine") and not actual.has_type("trip"), "original mine placement was not a trigger")
		var text := Payoff.highlight_result_line(LevelDef.by_id(id),actual,true)
		_check(text == _expected(id,true), "original native result must not turn a teaching goal into a completed action")
		_check(actual.fingerprint() == before and FileAccess.get_sha256(path) == sha, "source log and bytes remain unchanged")
		result_rows.append({"case":sample,"source_sha256":sha,"attempt":actual.attempt_id,"formatter":text,"terminal_tick":actual.terminal_tick,"scope":"Original native source read only. No playback binding/rendering, source rewrite or new journey."})

func _formatter_matrix() -> void:
	for id in NAMES:
		for kind in ["empty","unrelated","action_fixture","legacy_sparse"]:
			var log := Log.new()
			if kind != "empty":
				log.events = [{"type":"fire","tick":600,"actor_id":1,"target_id":1,"payload":{"route":"main"}}]
			if kind == "action_fixture":
				log.events.append({"type":"ambush_armed","tick":0})
				log.events.append({"type":"route_choice","tick":20,"payload":{"covered":false}})
				log.events.append({"type":"trip","tick":40,"actor_id":1,"target_id":3})
				log.events.append({"type":"repack","tick":60,"actor_id":1})
			if kind == "legacy_sparse": log.events = [{"type":"route_choice","tick":5}]
			var before := log.fingerprint()
			for won in [false,true]:
				sample = id + "_" + kind + "_" + str(won)
				var text := Payoff.highlight_result_line(LevelDef.by_id(id),log,won)
				_check(text == _expected(id,won), "neutral terminal outcome does not infer role/route/trap/repack completion")
				_check(log.fingerprint() == before and log.playback_schema == 0, "formatter preserves sparse/legacy events and schema")
				result_rows.append({"case":sample,"formatter":text,"scope":"Explicit synthetic formatter fixture; action_fixture is not an actual trigger."})
		for won in [false,true]:
			_check(Payoff.highlight_result_line(LevelDef.by_id(id),null,won) == _expected(id,won), "missing log never invents actions " + id)
	_check(Payoff.highlight_result_line(null,null,true) == "", "null level remains empty")
	_check(Payoff.highlight_result_line({"level_id":"unknown","highlight_hook":"unproven"},null,true) == "封锁完成", "unknown level gives neutral outcome")
	_check(Payoff.highlight_result_line({"level_id":"unknown","highlight_hook":"unproven"},null,false) == "尚未封锁", "unknown failure gives neutral outcome")

func _assert_copy(won: bool) -> void:
	var expected := _expected(main.level.level_id,won)
	var before: Dictionary = main._snapshot_data().duplicate(true)
	var fingerprint: String = main.battle_log.fingerprint()
	var clock := [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum]
	_check(main.highlight_result_text() == expected, "shared original formatter uses factual outcome")
	if won:
		main._fill_result_stats()
		_check(main.result_stats_block_text().contains("高光  " + expected), "original statistics use same outcome")
		_check(not main.result_stats_block_text().contains(main.level.highlight_hook), "statistics do not claim teaching action")
		_check(main.result_label.text.contains(expected), "original result body contains factual outcome")
		_check(not main.result_label.text.contains(main.level.highlight_hook), "body does not claim teaching action")
	else:
		_check(main.fail_dossier_text().contains(expected), "original failed dossier contains unfinished outcome")
	_check(main._snapshot_data() == before and main.battle_log.fingerprint() == fingerprint and [main.sim.tick,main.sim.paused,main.sim.speed,main.sim._accum] == clock, "formatting preserves state/log/clock")
	result_rows.append({"case":sample,"phase":main.phase,"terminal_tick":main.battle_log.terminal_tick,"mine_events":main.battle_log.events.filter(func(e: Dictionary) -> bool: return e.type == "mine"),"formatter":main.highlight_result_text(),"stats":main.result_stats_block_text(),"body":main.result_label.text,"dossier":main.fail_dossier_text(),"scope":"Reference grants/cover snaps/direct ticks/vacuum reach original terminal; not normal player input."})

func _domain_case(id: String, wins: bool, mine: bool, mode: String) -> void:
	sample = "facts_" + mode + "_" + id + ("_won" if wins else "_failed") + ("_mine" if mine else "_no_mine")
	main._load_level(id,false,false)
	main.raid_prepare_ref([1,4,5] if wins else [], ([270.0,270.0,180.0] if id == "depot" else [270.0,90.0,270.0]) if wins else [], {"grenades":0,"mines":1 if mine else 0})
	if mine:
		main._select_op(0)
		main._deploy_selected_to(main.cover_slots[0])
		var carried: int = main.selected.mines
		_check(main.phase == main.Phase.SETUP,"reference placement occurs only in SCOUT")
		main._try_place_inventory_mine(Vector2(240,368))
		_check(main.selected.mines == carried-1 and main.raid_mines.size() == 1, "original backend consumes reference mine")
		main._deploy_selected_to(main.cover_slots[1])
		main.selected.set_facing(270.0)
	for wave in main.level.wave_count():
		main.raid_force_alarm()
		var steps := 0
		while main.phase == main.Phase.WATCHING and steps < 12000:
			main._sim_tick()
			steps += 1
		if main.phase == main.Phase.FAILED: break
		_check(main.phase == main.Phase.SWEEP,"original reference domain reaches SWEEP " + str(wave))
		if main.phase != main.Phase.SWEEP: return
		main.raid_vacuum_loot()
		if mine and wave == 0:
			main._select_op(0)
			main._deploy_selected_to(main.cover_slots[2])
			main.selected.set_facing(90.0)
		if wave + 1 == main.level.wave_count(): main._on_sweep_commit()
		await process_frame
	_check(main.phase == (main.Phase.WON if wins else main.Phase.FAILED), "actual expected terminal reached without phase assignment")
	_check(main.battle_log.has_type("mine") == mine, "actual backend trigger distinguished from no-mine case")
	_assert_copy(wins)
	if DisplayServer.get_name() != "headless":
		if is_instance_valid(view): view.refresh()
		for _i in 5: await process_frame
		await _modal_capture(sample)
		if not wins:
			var before: Dictionary = main._snapshot_data().duplicate(true)
			await _native_click(main.dossier_button)
			_check(main._dossier_open, "native original button opens failed dossier")
			await _modal_capture(sample + "_dossier")
			var scroll: ScrollContainer = main._result_scroll
			var rect := scroll.get_global_rect()
			for step in 3:
				await _native_click(scroll,5,Vector2(rect.end.x-8,rect.get_center().y))
				await _modal_capture(sample + "_scroll" + str(step))
			_check(scroll.scroll_vertical > 0, "native wheel scrolls original dossier")
			_check(main._snapshot_data() == before, "native open/scroll preserves terminal state")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.position = Vector2i.ZERO
	root.content_scale_factor = 1.0
	var settings = root.get_node("GameSettings")
	settings.set_force_touch_hud(false)
	for id in NAMES: settings.mark_tutorial_seen(id)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/asset_review/pr15-runtime"))
	_readonly_records()
	_formatter_matrix()
	for mode in ["3d","legacy2d"]:
		settings.pending_level_id = "yard"
		change_scene_to_file("res://scenes/presentation/yard_3d.tscn" if mode == "3d" else "res://scenes/main.tscn")
		await process_frame
		await process_frame
		main = current_scene
		view = main.presentation_3d
		main.set_process(false)
		if is_instance_valid(view): view.set_process(false)
		await _domain_case("depot",true,false,mode)
		await _domain_case("radio",false,false,mode)
		if mode == "3d":
			await _domain_case("depot",true,true,mode)
			await _domain_case("radio",true,false,mode)
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/campaign-result-copy-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":result_rows,"captures":captures,"native_inputs":input_rows,"scope":"Bounded factual result copy only; original records read-only, all new battles are explicit reference fixtures. Legacy2D covers result UI only. No replay rendering, normal journey, performance or device claim."},"  "))
	print("CAMPAIGN_RESULT_COPY_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
