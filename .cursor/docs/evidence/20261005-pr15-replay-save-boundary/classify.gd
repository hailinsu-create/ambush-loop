extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Store := preload("res://scripts/web_config_store.gd")
const FIELDS := ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]
var rows := []
var checks := 0
var failures := []
var main: Node
var source: BattleLog
var original_bytes: PackedByteArray
var gs: Node
func _init() -> void:
	if not Guard.check(): quit(91); return
	call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); print("CLASSIFY_FAIL ",label)
func _state() -> Dictionary:
	return {"checkpoint":Store.snapshot(),"progress":FileAccess.get_file_as_string(gs.PROGRESS_PATH),"settings":FileAccess.get_file_as_string(gs.SETTINGS_PATH),"next":gs.continue_level_id(),"complete":gs.is_campaign_complete(),"missions":gs.mission_entries(),"phase":main.phase,"campaign_complete":main._campaign_complete}
func _record() -> PackedByteArray:
	var d := {}
	for f: String in FIELDS: d[f] = source.get(f)
	return var_to_bytes(d)
func _same_config(a: Dictionary, b: Dictionary) -> bool:
	return a.checkpoint == b.checkpoint and a.progress == b.progress and a.settings == b.settings and a.next == b.next and a.complete == b.complete and a.missions == b.missions and a.campaign_complete == b.campaign_complete
func _return(label: String) -> void:
	var before := _state()
	main._on_replay_pressed()
	_check(main.phase == main.Phase.REPLAY,label+" original replay callback enters history")
	main._process(0.1)
	var during := _state()
	_check(_same_config(before,during),label+" history playback retains configs")
	_check(_record()==original_bytes,label+" history playback retains raw record")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	main._unhandled_input(key)
	var after := _state()
	_check(main.phase == main.Phase.WON,label+" original Space handler returns WON")
	_check(_record()==original_bytes,label+" return retains raw record")
	rows.append({"case":label,"before":before,"during":during,"after":after,"config_equal":_same_config(before,after),"input_scope":"controlled original handler event, not OS/browser normal input","source_sha256":FileAccess.get_sha256(OS.get_environment("CLASSIFY_RECORD"))})
func _run() -> void:
	gs=root.get_node("GameSettings")
	gs.pending_level_id="railcut"
	gs.mark_tutorial_seen("railcut")
	change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
	for _i in 6: await process_frame
	main=current_scene
	main.set_process(false)
	var raw: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(OS.get_environment("CLASSIFY_RECORD")))
	source=BattleLog.new()
	for f: String in FIELDS: source.set(f,raw[f])
	main.battle_log=source
	main.phase=main.Phase.WON
	main.result_panel.visible=true
	main.replay_button.visible=true
	original_bytes=_record()
	_return("cold_unsettled_WON")
	_check(not rows[-1].config_equal and rows[-1].after.next=="depot","cold first WON exit commits next depot")
	_return("settled_WON_repeat1")
	_check(rows[-1].config_equal,"already settled WON repeated exit retains exact configs")
	_return("settled_WON_repeat2")
	_check(rows[-1].config_equal,"already settled WON second repeated exit retains exact configs")
	gs.record_win("radio",1,true)
	var future=_state()
	_check(future.complete and future.next==null,"explicit adversarial future profile is actually complete")
	_return("injected_future_profile_old_WON")
	_check(not rows[-1].config_equal and not rows[-1].after.complete and rows[-1].after.next=="depot","injected unreachable future profile/old WON regresses by repeated record_win")
	var result={"checks":checks,"failures":failures,"rows":rows,"scope":"isolated controlled source/handler classification, cold prior source railcut original bin; adversarial future profile explicitly injected, no proof of normal UI reachability; not fresh producer, whole replay, renderer or performance acceptance","source":OS.get_environment("AMBUSH_TEST_SOURCE_SHA")}
	var file=FileAccess.open(OS.get_environment("CLASSIFY_RESULT"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "));file.close()
	print("REPLAY_SAVE_CLASSIFICATION checks=",checks," failures=",failures.size())
	quit(0 if failures.is_empty() else 1)
