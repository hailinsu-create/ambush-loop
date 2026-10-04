extends "res://scripts/viewport_hud_test.gd"
## Explicit display matrix, then original radio reference late escape.
var context_rows := []

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("TEACHING_CONTEXT_FAIL " + sample + " " + message)

func _scene(mode: String) -> void:
	root.get_node("GameSettings").pending_level_id = "yard"
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn" if mode == "3d" else "res://scenes/main.tscn")
	await process_frame
	await process_frame
	main = current_scene
	view = main.presentation_3d
	main.set_process(false)
	if is_instance_valid(view): view.set_process(false)

func _matrix(mode: String) -> void:
	for id in ["yard","warehouse","pump","railcut","depot","radio"]:
		main._load_level(id,false,false)
		await process_frame
		for wave in main.level.wave_count():
			sample = "display_" + mode + "_" + id + "_wave" + str(wave)
			main.raid.wave_index = wave # Explicit display fixture, not13 battles.
			var state: Dictionary = main._snapshot_data().duplicate(true)
			var fingerprint: String = main.battle_log.fingerprint()
			var schedules := var_to_bytes([main.level.spawn_schedule,main.level.waves])
			main._refresh_spawn_teach()
			_check(main.spawn_teach_label.text.begins_with("全关教学预览 · "),"static teaching is visibly distinct from current-wave clock")
			_check(main.spawn_teach_label.text.contains(main.level.beat_text),"original whole-level teaching content is retained")
			for route in main.level.route_cells:
				if main.level.first_route_delay(route) < 1.0: continue
				var label: String = main._route_chip_label(str(route),main._route_zh_short(str(route)))
				_check(label.begins_with("全关预览 · "),"route legend's total-table seconds declare preview context")
			if id == "radio":
				_check(main.echo_callout.get_node("Tag").text.begins_with("全关教学预览 · "),"legacy echo map label declares teaching preview")
			main.fail_reason = "escape" # Static advice fixture only; no terminal claim.
			main._alarm_pulled_unarmed = false
			var advice: String = main._fix_one_line()
			_check(advice.begins_with("全关教学建议 · ") and not advice.contains("改一处就能赢"),"authored advice is scoped teaching, without guaranteed outcome")
			main.fail_reason = ""
			_check(main._snapshot_data() == state and main.battle_log.fingerprint() == fingerprint and var_to_bytes([main.level.spawn_schedule,main.level.waves]) == schedules,"text refresh preserves state/source/original schedules")
			context_rows.append({"scope":"explicit display fixture","mode":mode,"level":id,"wave":wave,"teaching":main.spawn_teach_label.text,"advice":advice})

func _capture(label: String) -> void:
	main._update_hud()
	if is_instance_valid(view): view.refresh()
	for _i in 5: await process_frame
	await _modal_capture(label)

func _radio_reference() -> void:
	await _scene("3d")
	sample = "original_radio_late_escape_reference"
	main._load_level("radio",false,false)
	await process_frame
	if DisplayServer.get_name() != "headless": await _capture("teaching_radio_first_scout")
	for index in 3:
		for stash in main.raid_stashes:
			if main.WeaponCatalogScript.family_of(stash.kind) == ["rifle","mg","scout"][index]:
				main.operators[index].receive_item(stash.kind,stash.amount)
				break
	main.raid_prepare_ref([1,4,5],[270.0,90.0,270.0],{"grenades":0,"mines":0})
	main.raid_force_alarm()
	for wave in 2:
		while main.phase == main.Phase.WATCHING and main.sim.tick < 12000: main._sim_tick()
		_check(main.phase == main.Phase.SWEEP,"original reference early wave clears " + str(wave))
		if main.phase != main.Phase.SWEEP: return
		main.raid_vacuum_loot()
		if wave == 1:
			# Original actor drop API in legal SWEEP; no invented target/phase/HP.
			# Removing all held guns sets knife by the original backpack logic.
			for op in main.operators:
				for kind in op.pack.firearms():
					_check(bool(op.drop_from_pack(kind).get("ok",false)),"reference SWEEP drop succeeds")
		main._on_sweep_commit()
	while main.phase == main.Phase.WATCHING and main.sim.tick < 12000: main._sim_tick()
	_check(main.phase == main.Phase.FAILED and main.fail_reason == "escape","actual original third-wave runner escapes")
	if main.phase != main.Phase.FAILED or main.fail_reason != "escape": return
	var source = main.battle_log
	var spawn: Dictionary = source.events.filter(func(e: Dictionary) -> bool: return e.type == "spawn" and int(e.wave_id) == 2)[0]
	var escape: Dictionary = source.last_of_type("escape")
	_check(int(spawn.actor_id) == 5 and int(spawn.tick) == 30 and escape.actor_id == spawn.actor_id and escape.wave_id == spawn.wave_id,"actual late escape belongs to original echo5/spawnlocal30")
	_check(main._fix_one_line().begins_with("全关教学建议 · ") and main.result_label.text.contains("全关教学建议"),"actual fail panel distinguishes authored advice from event facts")
	_check(main.fail_dossier_text().contains("关卡背景 · ") and not main.fail_dossier_text().contains("截获 · "),"preset dialogue is background, not an intercepted actual event")
	var audit := {"scope":"actual original reference3waves, authored gun grants/cover snaps/directticks/vacuum/drop API; not normal input","spawn":spawn,"escape":escape,"intel":main.intel.records.duplicate(true),"actual_fail_body":main.result_label.text,"actual_advice":main._leak_advice_line(),"actual_hint":main.intel.latest_hint(),"static_context_fixed_only":true,"live_escape_timing_audit_pending":true}
	context_rows.append(audit)
	var path := "res://build/asset_review/pr15-runtime/teaching-radio-late-escape-record.bin"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(var_to_bytes({"attempt_id":source.attempt_id,"events":source.events,"snapshots":source.snapshots,"terminal_tick":source.terminal_tick,"terminal_reason":source.terminal_reason,"playback_schema":source.playback_schema,"playback_snapshots":source.playback_snapshots,"playback_terminal_tick":source.playback_terminal_tick,"intel_records":main.intel.records}))
	file.close()
	var sha := FileAccess.get_sha256(path)
	if DisplayServer.get_name() != "headless": await _capture("teaching_radio_actual_last_escape")
	main._on_continue_pressed()
	_check(main.phase == main.Phase.SETUP and FileAccess.get_sha256(path) == sha,"original retry starts SCOUT and preserves saved prior reference bytes")
	context_rows.append({"scope":"original retry callback","advice":main.leak_advice_text(),"teaching":main.spawn_teach_label.text,"saved_reference_sha256":sha})
	if DisplayServer.get_name() != "headless": await _capture("teaching_radio_retry_scout")

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
	var file := FileAccess.open("res://build/asset_review/pr15-runtime/static-teaching-context-report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"checks":checks,"failures":failures,"rows":context_rows,"captures":captures,"scope":"Static teaching preview/legend/map tag/advice/background only. Matrix assigns wave/fail flags; actual radio reference grants/snaps/directticks/vacuum/legal actor drops ->late escape/retry. Actual leak timing is audit only, unresolved here. Not26 battles/normal/full recording3D/FX/A3/audio/device acceptance."},"  "))
	print("STATIC_TEACHING_CONTEXT_TEST checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
