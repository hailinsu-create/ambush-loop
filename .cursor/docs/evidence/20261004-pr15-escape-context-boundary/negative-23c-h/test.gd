extends SceneTree
## Read-only actual877 source plus explicitly corrupt saved-context fixtures.
const Guard := preload("res://scripts/test_storage_guard.gd")
const ViewState := preload("res://scripts/presentation/view_state.gd")
const RAW_SHA := "cf77a08654aff89561723944176e38dcb7aa8b1b8d0a897cf77f39685b7a6c09"
var checks := 0
var failures := 0
var rows := []
var captures := []
var main: Node
var directory := ""

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("ESCAPE_CONTEXT_BOUNDARY_FAIL " + message)

func _wave(record: Dictionary, wave: int) -> Dictionary:
	var copy := record.duplicate(true)
	copy.escape_context.wave_id = wave
	for key in ["spawn", "escape"]:
		var event: Dictionary = copy.escape_context[key]
		event.wave_id = wave
		event.event_id = "%s:%d:%d" % [event.attempt_id, wave, event.seq]
	return copy

func _clock(record: Dictionary, tick: int) -> Dictionary:
	var copy := record.duplicate(true)
	copy.escape_context.escape.playback_tick = tick
	return copy

func _probe(store: IntelStore, record: Dictionary, label: String, valid: bool) -> void:
	store.records = [record.duplicate(true)]
	var before := var_to_bytes(store.records)
	var context := store.validated_escape_context(store.records[0], "radio")
	var line := store.leak_advice_line(LevelDef.by_id("radio"), "回波")
	var correct: bool = not context.is_empty() and line.contains("历史第3波") and line.contains("0.5") and line.contains("15.9") if valid else context.is_empty() and line.contains("未确认") and not line.contains("历史第")
	_check(correct and var_to_bytes(store.records) == before, label+" valid="+str(valid)+" actual="+line)
	rows.append({"case":label,"scope":"Explicit saved-context validator fixture over original877 values","expected_valid":valid,"advice":line,"validated":context,"memory_unchanged":var_to_bytes(store.records)==before})

func _render_cases(cases: Array) -> void:
	root.size = Vector2i(1280,720)
	root.position = Vector2i.ZERO
	root.content_scale_factor = 1.0
	var settings = root.get_node("GameSettings")
	settings.pending_level_id = "radio"
	settings.mark_tutorial_seen("radio") # Cold consumer only.
	settings.set_force_touch_hud(false)
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	await process_frame
	await process_frame
	main = current_scene
	main.set_process(false)
	main.presentation_3d.set_process(false)
	for row: Dictionary in cases:
		main.intel.records = [row.record.duplicate(true)]
		main._update_hud()
		main.presentation_3d.refresh()
		var before: Dictionary = main._snapshot_data().duplicate(true)
		var sim_state := [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum]
		var memory := var_to_bytes(main.intel.records)
		var advice: String = main.leak_advice_text()
		var result: String = main._leak_result_line()
		var expected: bool = advice.contains("历史第3波") and result.contains("第3波漏网") and result.contains("0.5s出发") and result.contains("15.9s逃逸") if row.valid else advice.contains("未确认") and result.contains("未确认") and not advice.contains("历史第") and not result.contains("第4波")
		_check(expected, "original3D HUD/result "+str(row.label)+" actual="+advice+" / "+result)
		_check(main.presentation_3d.frame.level_id == "radio" and main.presentation_3d.frame.actor_asset_revision == "29749157c5db064bfea626c3ed9d75d9a1791ece", "original cold3D world/R5 binding "+str(row.label))
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		_check(main._snapshot_data()==before and [main.sim.tick,main.sim.speed,main.sim.paused,main.sim._accum]==sim_state and var_to_bytes(main.intel.records)==memory, "display keeps live/sim/saved memory "+str(row.label))
		var image := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
		var path := directory+"/"+str(row.label)+".png"
		_check(image.save_png(path)==OK, "actual Window capture "+str(row.label))
		captures.append({"id":row.label,"path":path,"sha256":FileAccess.get_sha256(path),"capture_source":"Native DisplayServer Window crop"})

func _run() -> void:
	var path := OS.get_environment("AMBUSH_ESCAPE_CONTEXT_RECORD")
	if FileAccess.get_sha256(path) != RAW_SHA:
		print("ESCAPE_CONTEXT_SOURCE_HASH_MISMATCH")
		quit(2)
		return
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	var retained := var_to_bytes(raw)
	var original: Dictionary = raw.intel_records.back().duplicate(true)
	var fourth := _wave(original,3)
	var stalled := _clock(original,int(original.escape_context.spawn.playback_tick))
	var cases := [{"label":"original_third","record":original,"valid":true},{"label":"invalid_fourth","record":fourth,"valid":false},{"label":"invalid_stalled_playback","record":stalled,"valid":false}]
	var store := IntelStore.new()
	for row: Dictionary in cases: _probe(store,row.record,row.label,row.valid)
	directory = "res://build/asset_review/pr15-runtime/escape-context-boundary-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	if DisplayServer.get_name() != "headless": await _render_cases(cases)
	if var_to_bytes(raw)!=retained or FileAccess.get_sha256(path)!=RAW_SHA:
		_check(false,"actual original877 raw/value modified")
	root.get_node("AudioDirector").pause_for_background()
	var file := FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),"producer_source_sha":"877decb0ea14d6c3c0a833e4d6948c7ee549514f","raw_sha256":RAW_SHA,"checks":checks,"failures":failures,"rows":rows,"captures":captures,"source_unchanged":FileAccess.get_sha256(path)==RAW_SHA and var_to_bytes(raw)==retained,"scope":"Read-only actual877 archived escape/retry source; explicit corrupt context and cold3D formatter fixtures. No new battles/native input/fullrecord/FX/A3/FINAL/device acceptance."}, "  "))
	file.close()
	print("ESCAPE_CONTEXT_BOUNDARY_TEST checks=%d failures=%d output=%s" % [checks,failures,directory])
	quit(0 if failures == 0 else 1)
