extends SceneTree

## Focused acceptance gate for R45: the SWEEP action hint appears once per
## attempt and is cleared when SWEEP ends. Always run through the isolated
## wrapper so user:// points at disposable test data.

const TestStorageGuard := preload("res://scripts/test_storage_guard.gd")


func _init() -> void:
	if not TestStorageGuard.check():
		quit(91)
		return
	call_deferred("_run")


func _run() -> void:
	var ver := str(ProjectSettings.get_setting("application/config/version", ""))
	print("R45_GAME_VERSION ", ver)
	if ver != "0.6.29":
		push_error("R45_BAD_VERSION %s" % ver)
		quit(90)
		return
	var err := change_scene_to_file("res://scenes/main.tscn")
	if err != OK:
		push_error("R45_NO_MAIN %s" % err)
		quit(2)
		return
	await process_frame
	await process_frame
	var main = current_scene
	for _i in 8:
		await process_frame
	if main == null or main.level == null or main.level.level_id != "yard" or main.raid == null:
		push_error("R45_BAD_BOOT")
		quit(2)
		return

	main._start_setup(false, false)
	main._enter_sweep()
	var first_hint := "搜尸 · 准备下一波"
	if main.flash_text() != first_hint:
		push_error("R45_FIRST_HINT text=%s" % main.flash_text())
		quit(78)
		return
	if first_hint.length() > 16:
		push_error("R45_HINT_TOO_LONG len=%s" % first_hint.length())
		quit(78)
		return

	main._begin_next_wave()
	if main.flash_text() != "":
		push_error("R45_HINT_CARRIED_INTO_WAVE text=%s" % main.flash_text())
		quit(78)
		return
	main._enter_sweep()
	if main.flash_text() == first_hint:
		push_error("R45_HINT_REPEATED_WITHIN_ATTEMPT")
		quit(78)
		return

	main._start_setup(false, false)
	if main.flash_text() == first_hint:
		push_error("R45_HINT_CARRIED_INTO_SETUP text=%s" % main.flash_text())
		quit(78)
		return
	main.raid.wave_index = main.raid.wave_count(main.level) - 1
	main._enter_sweep()
	var last_hint := "搜尸 · 空格撤离"
	if main.flash_text() != last_hint or last_hint.length() > 16:
		push_error("R45_LAST_HINT text=%s len=%s" % [main.flash_text(), last_hint.length()])
		quit(78)
		return
	main._extract_win()
	var extract_hint := "零逃逸 · 撤离封锁"
	if main.flash_text() != extract_hint:
		push_error("R45_EXTRACT_HINT text=%s" % main.flash_text())
		quit(78)
		return

	print("R45_GATE_OK first_once=1 clear_wave=1 clear_setup=1 clear_extract=1 max_chars=16")
	quit(0)
