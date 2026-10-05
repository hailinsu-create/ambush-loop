extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Context := preload("res://scripts/a3_window_context.gd")
const View := preload("res://scripts/presentation/view_state.gd")
const OLD := "/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin"
const SHA := "1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12"
var checks:=0
var failures:=0
func _init() -> void:
    if not Guard.check():quit(91);return
    call_deferred("_run")
func _check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("HUD_OLD_RECORD: "+label)
func _run() -> void:
    root.size=Vector2i(1280,720)
    _check(FileAccess.get_sha256(OLD)==SHA,"actual original schema1 bytes before")
    var data: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(OLD))
    var source:=BattleLog.new()
    for key: String in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]:
        if data.has(key):source.set(key,data[key])
    _check(source.playback_schema==1 and not source.playback_snapshots.is_empty(),"genuine old playback1 stream")
    var source_bytes: PackedByteArray=var_to_bytes(data)
    var settings=root.get_node("GameSettings");settings.pending_level_id="yard";settings.mark_tutorial_seen("yard")
    change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
    await process_frame;await process_frame
    var main=current_scene;main.set_process(false);main.presentation_3d.set_process(false)
    main.battle_log=source;main.phase=main.Phase.WON;main._on_replay_pressed()
    _check(main.phase==main.Phase.REPLAY and main.replay.continuous_playback and not main.replay.playback_unsupported,"actual old app entry supported")
    var raw_before: PackedByteArray=var_to_bytes({"events":source.events,"snapshots":source.snapshots,"playback_snapshots":source.playback_snapshots})
    for ratio: float in [0.0,0.5,1.0]:
        main.replay.seek_ratio(ratio);main._apply_replay_scrub();main.presentation_3d.refresh()
        var frame: Dictionary=main.presentation_3d.frame.duplicate(true)
        var snap: Dictionary=main.replay.snapshot_at_or_before(main.replay.scrub_tick)
        _check(frame.replay and frame.playback_schema==1 and frame.attempt_id==snap.attempt_id and frame.wave_id==snap.wave_id and frame.frame_seq==snap.frame_seq,"actual legacy selected frame identity "+str(ratio))
        _check(frame.level_title==str(snap.data.get("level_title","历史关卡")) and frame.selected_id==int(snap.data.get("selected_id",-1)),"HUD belongs to saved legacy source "+str(ratio))
        _check(frame.shot_fx_schema==0 and frame.tool_fx_schema==0 and frame.movement_fx_schema==0,"original playback1 adjunct remains neutral "+str(ratio))
        main._pose_command_clock_s+=100.0;main._night_timer+=100.0
        main._update_hud();main.presentation_3d.refresh()
        _check(frame==main.presentation_3d.frame,"current-clock poison cannot change saved legacy view "+str(ratio))
    _check(var_to_bytes({"events":source.events,"snapshots":source.snapshots,"playback_snapshots":source.playback_snapshots})==raw_before,"source containers untouched")
    _check(FileAccess.get_sha256(OLD)==SHA and var_to_bytes(bytes_to_var(FileAccess.get_file_as_bytes(OLD)))==source_bytes,"original archive bytes never upgraded")
    print("HUD_OLD_RECORD checks=",checks," failures=",failures," selections=3 original_sha256=",SHA)
    main.queue_free();await process_frame;quit(0 if failures==0 else 1)
