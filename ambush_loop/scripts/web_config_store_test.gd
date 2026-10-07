extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Store := preload("res://scripts/web_config_store.gd")
var checks := 0
var failures := 0

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("WEB_CONFIG_STORE: " + label)

func _run() -> void:
	var gs = root.get_node("GameSettings")
	gs.set_muted(true)
	gs.mark_tutorial_seen("yard")
	gs.record_win("yard", 2)
	var original := Store.snapshot()
	var decoded := Store.decode(original)
	_check(decoded.ok, "both original ConfigFiles checkpoint validates")
	_check(decoded.files[Store.NAMES[0]].contains("muted=true"), "audio and tutorial settings retained")
	_check(decoded.files[Store.NAMES[1]].contains('level_id="warehouse"'), "next mission retained")
	gs.set_muted(false)
	gs.record_win("warehouse", 1)
	_check(Store.restore(decoded.files) == OK, "checkpoint restores both original files")
	gs.load_settings()
	_check(gs.muted and gs.has_seen_tutorial("yard"), "restored actual settings load")
	_check(gs.progress_level_id() == "warehouse" and gs.mission_entries()[1].unlocked, "restore preserves next mission access")
	_check(Store.snapshot() == original, "restore retains exact original text bytes")
	for invalid in ["null", "{}", JSON.stringify({"schema":2,"files":decoded.files}), JSON.stringify({"schema":1,"files":{"../escape":null,"ambush_loop.cfg":null}}), JSON.stringify({"schema":1,"files":{"ambush_loop_settings.cfg":123,"ambush_loop.cfg":null}}), " ".repeat(Store.MAX_BYTES + 1)]:
		_check(not Store.decode(invalid).ok, "unsupported/malformed/unsafe checkpoint refused")
		_check(Store.snapshot() == original, "validation cannot mutate live files")
	var absent := Store.decode(JSON.stringify({"schema":1,"files":{"ambush_loop_settings.cfg":decoded.files[Store.NAMES[0]],"ambush_loop.cfg":null}}))
	_check(absent.ok and Store.restore(absent.files) == OK, "explicit absent progress restores without resurrection")
	_check(not gs.has_progress() and not FileAccess.file_exists(gs.PROGRESS_PATH), "old progress removed by authoritative tombstone")
	_check(FileAccess.get_file_as_string(gs.SETTINGS_PATH) == decoded.files[Store.NAMES[0]], "tombstone leaves settings intact")
	print("WEB_CONFIG_STORE checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
