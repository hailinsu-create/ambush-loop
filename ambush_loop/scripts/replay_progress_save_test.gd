extends SceneTree
## Paired WON persistence fixture and original input handlers. Not a new victory or whole replay.
const Guard := preload("res://scripts/test_storage_guard.gd")
const Store := preload("res://scripts/web_config_store.gd")
const RECORD_FIELDS := ["attempt_id", "events", "snapshots", "terminal_tick", "terminal_reason", "playback_schema", "playback_snapshots", "playback_terminal_tick"]
var checks := 0
var failures: Array[String] = []
var rows := []
var main: Node
var settings: Node
var source: BattleLog
var source_bytes: PackedByteArray

func _init() -> void:
	if not Guard.check():
		quit(91)
		return
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("REPLAY_PROGRESS_SAVE_FAIL ", label)

func _saved() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(settings.PROGRESS_PATH)
	var progress := {}
	for section in ["progress", "stats"]:
		var values := {}
		if cfg.has_section(section):
			for key in cfg.get_section_keys(section):
				values[key] = cfg.get_value(section, key)
		progress[section] = values
	return {"checkpoint": Store.snapshot(), "progress": progress, "settings_text": FileAccess.get_file_as_string(settings.SETTINGS_PATH), "next": settings.progress_level_id(), "complete": settings.is_campaign_complete(), "muted": settings.muted}

func _record_bytes() -> PackedByteArray:
	var fields := {}
	for field: String in RECORD_FIELDS:
		fields[field] = source.get(field)
	return var_to_bytes(fields)

func _key(code: int) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	main._unhandled_input(event)

func _run() -> void:
	settings = root.get_node("GameSettings")
	settings.pending_level_id = "railcut"
	settings.mark_tutorial_seen("railcut")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	for _i in 6:
		await process_frame
	main = current_scene
	main.set_process(false)
	var path := OS.get_environment("AMBUSH_REPLAY_SAVE_RECORD")
	_check(FileAccess.file_exists(path), "actual original record fixture exists")
	if not FileAccess.file_exists(path):
		quit(1)
		return
	var raw: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(path))
	source = BattleLog.new()
	for field: String in RECORD_FIELDS:
		source.set(field, raw[field])
	source_bytes = _record_bytes()
	main.battle_log = source
	main.phase = main.Phase.WON
	main.pending_result = "win"
	main._flush_pending_result()
	var settled := _saved()
	_check(settled.next == "depot" and not settled.complete, "original victory settlement advances to depot")
	for repeat_i in 2:
		main._on_replay_pressed()
		main._process(0.1)
		_check(_saved() == settled, "paired WON replay retains exact checkpoint before return")
		_key(KEY_SPACE)
		_check(main.phase == main.Phase.WON and _saved() == settled, "paired WON replay return remains idempotent")
		_check(_record_bytes() == source_bytes, "paired WON replay preserves original record")
		rows.append({"case": "settled_repeat", "repeat": repeat_i, "saved": _saved()})
	main._on_replay_pressed()
	var before_mute := _saved()
	_key(KEY_M)
	var after_mute := _saved()
	_check(main.phase == main.Phase.REPLAY and after_mute.muted != before_mute.muted, "original M command changes audio during replay")
	_check(after_mute.progress == before_mute.progress and after_mute.next == "depot", "WON replay M preserves all progress and stats")
	_check(_record_bytes() == source_bytes, "WON replay M preserves original record")
	rows.append({"case": "WON_replay_M", "before": before_mute, "after": after_mute})
	main._return_to_title()
	for _i in 6:
		await process_frame
	_check(current_scene.scene_file_path == "res://scenes/title.tscn" and settings.progress_level_id() == "depot", "original Title route retains depot continue pointer")
	# Active mission history still saves its active mission when audio changes.
	settings.pending_level_id = "pump"
	settings.mark_tutorial_seen("pump")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	for _i in 6:
		await process_frame
	main = current_scene
	main.set_process(false)
	main.battle_log.add_snapshot(0, main._snapshot_data())
	for return_phase in [main.Phase.SETUP, main.Phase.SWEEP, main.Phase.FAILED]:
		main.phase = return_phase
		main._on_replay_pressed()
		_key(KEY_M)
		_check(settings.progress_level_id() == "pump" and not settings.is_campaign_complete(), "active mission replay keeps its current continue target")
		main.phase = return_phase
	var result := {"checks": checks, "failures": failures, "rows": rows, "source": OS.get_environment("AMBUSH_TEST_SOURCE_SHA"), "record_sha256": FileAccess.get_sha256(path), "scope": "guarded paired pending-WON and active-phase fixtures; original handlers; not ordinary producer, whole, renderer or device acceptance"}
	var output := OS.get_environment("AMBUSH_REPLAY_SAVE_OUTPUT")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(result, "  "))
		file.close()
	print("REPLAY_PROGRESS_SAVE checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
