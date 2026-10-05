extends "res://scripts/a3_campaign_metrics_test.gd"
## Identical external fixture on two frozen clean worktrees, not a new battle.
const ORIGINAL_PATH := "/workspace/ambush-pr15/.cursor/docs/evidence/20261004-pr15-a3-actual-source/formal-a90-all/original-output/yard-primary-reference-record.bin"
const ORIGINAL_SHA := "426cf659c9fd10a47e53cd6ef28363e9e38ced0a6cb30c65cc844885104c4598"
const ORIGINAL_FRAME_SHA := "74b36012d278b2a0d7885b42879bf6ffac67298f508bae5b404c9affd7ca5d30"
const Actor := preload("res://scripts/presentation/actor_visual.gd")
var pair_rows: Array = []
const PROCESS_TOKENS := ["shot_fx_source_token", "tool_fx_source_token", "movement_fx_source_token"]

func _canonical_frame() -> Dictionary:
    var result: Dictionary = main.presentation_3d.frame.duplicate(true)
    for field: String in PROCESS_TOKENS: result[field] = 0
    return result

func _imports_match() -> bool:
    var path: String = OS.get_environment("AMBUSH_PAIR_IMPORT_METADATA")
    if FileAccess.get_sha256(path) != OS.get_environment("AMBUSH_PAIR_IMPORT_METADATA_SHA"): return false
    var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    for row: Dictionary in doc.files:
        if FileAccess.get_sha256("res://" + row.path) != row.sha256: return false
    return not doc.files.is_empty()

func _signature() -> Dictionary:
    var result: Dictionary = {}
    for key: String in main.presentation_3d.actors:
        var body: Node = main.presentation_3d.actors[key].get_node("Body")
        if not body is Actor: continue
        _check(body.skeleton != null and body.skeleton.get_bone_count() == 20, "actual rig20 " + key)
        if body.skeleton == null: continue
        var bones: Array = []
        for i: int in body.skeleton.get_bone_count(): bones.append(body.skeleton.get_bone_pose(i))
        var sockets: Dictionary = {}
        for slot: String in ["weapon_hand", "support_hand", "sight_eye"]: sockets[slot] = body.bone_socket(slot)
        _check(sockets.values().all(func(socket: Dictionary) -> bool: return not socket.is_empty()), "actual required bone sockets " + key)
        var item_sockets: Dictionary = {}
        for slot: String in ["grip", "muzzle", "pose_support", "sight"]: item_sockets[slot] = body.item_socket(slot)
        if body.equipped != null: _check(not item_sockets.grip.is_empty() and not item_sockets.muzzle.is_empty(), "required actual weapon sockets " + key)
        result[key] = {"body":body.global_transform,"asset":body.asset_id,"revision":body.asset_revision,
            "lod":body.lod,"item":body.equipped_id,"action":body.sampled_action,"time":body.sampled_time,
            "bones":bones,"sockets":sockets,"item_sockets":item_sockets,
            "body_path":body.model.get_meta("asset_resource_path", "") if body.model != null else "",
            "item_path":body.equipped.get_meta("asset_resource_path", "") if body.equipped != null else ""}
    return result

func _instances() -> Dictionary:
    var result: Dictionary = {}
    for key: String in main.presentation_3d.actors:
        var body: Node = main.presentation_3d.actors[key].get_node("Body")
        if body is Actor: result[key] = [body.get_instance_id(),body.equipped.get_instance_id() if body.equipped != null else -1]
    return result

func _measure(label: String, advancing: bool) -> void:
    _untimed(label + "-warmup")
    main.replay.pause()
    main.replay.set_tick(253)
    main._apply_replay_scrub()
    main.presentation_3d.refresh()
    await _wait(5.0)
    var source_digest: String = Context.digest(_log_bytes(main.battle_log))
    var backend_digest: String = Context.digest(Context.backend_bytes(main))
    var frame_digest: String = Context.digest(var_to_bytes(main.presentation_3d.frame))
    var process_token_values: Dictionary = {}
    for field: String in PROCESS_TOKENS:
        var token: Variant = main.presentation_3d.frame.get(field)
        _check(typeof(token) == TYPE_INT and token != 0 and token == main.battle_log.get_instance_id(), "original opaque token binding " + field)
        process_token_values[field] = token
    var canonical_frame_digest: String = Context.digest(var_to_bytes(_canonical_frame()))
    var signature_digest: String = Context.digest(var_to_bytes(_signature()))
    var instances_before: Dictionary = _instances()
    _check(source_digest == ORIGINAL_SHA, "exact original saved source bytes before " + label)
    var frame: Dictionary = main.presentation_3d.frame
    _check(frame.attempt_id == "ebb3b40c430e9939e054455f03a54e6f" and frame.frame_seq == 43 and frame.wave_id == 0 and frame.recorded_phase == 1 and frame.playback_tick == 253, "exact selected source identity before " + label)
    _check(Shot.active(frame).size() == 2, "two actual saved shot candidates before " + label)
    var frame_file: FileAccess = FileAccess.open(directory + "/" + label + "-canonical-frame.bin",FileAccess.WRITE)
    frame_file.store_buffer(var_to_bytes(_canonical_frame())); frame_file.close()
    for kind: String in ["raw-frame", "actual-rig-signature"]:
        var evidence: FileAccess = FileAccess.open(directory + "/" + label + "-" + kind + ".bin",FileAccess.WRITE)
        evidence.store_buffer(var_to_bytes(frame if kind == "raw-frame" else _signature())); evidence.close()
    _check(not _signature().is_empty(), "actual rigged actors exist " + label)
    if failures > 0: return
    var required_samples: int = 24 if advancing else 60
    var receipt: Dictionary = {"kind":"advancing original replay callbacks" if advancing else "paused exact saved frame with automatic callbacks",
        "phase":4,"minimum_measured_phase_rows":required_samples,"requested_seconds":5.0,"wall_limit_seconds":30.0,
        "configuration":Context.workload(main),"level_id":"yard","attempt_id":main.battle_log.attempt_id,
        "wave":0,"source_archive_sha256":ORIGINAL_SHA,"initial_frame_sha256":frame_digest,"initial_signature_sha256":signature_digest,"canonical_frame_sha256":canonical_frame_digest,
        "process_token_normalization":PROCESS_TOKENS,"formal_a3_process_raw_frame_reference":ORIGINAL_FRAME_SHA,
        "warmup_seconds":5.0,"scope":"bounded A3 candidate comparison, not whole replay/new normal/device"}
    if advancing:
        main.replay.set_speed(1.0)
        main.replay.play(false)
        receipt["speed"] = 1.0
    else:
        receipt["selected_source"] = {"tick":253,"frame_seq":43,"wave":0,"recorded_phase":1,
            "feature":"shot","active_saved_candidates":2,"frame_sha256":frame_digest,"canonical_frame_sha256":canonical_frame_digest,"attempt_id":main.battle_log.attempt_id}
        receipt["policy"] = "standard"
    collector.mark(label,true,"",receipt)
    var begin_usec: int = Time.get_ticks_usec()
    var cursor: int = collector.row_count
    var accepted: int = 0
    while Time.get_ticks_usec() - begin_usec < 30_000_000:
        await RenderingServer.frame_post_draw
        while cursor < collector.row_count:
            if collector.numeric_at(cursor,"measured") == 1.0 and collector.numeric_at(cursor,"phase") == 4.0: accepted += 1
            cursor += 1
        if accepted >= required_samples and Time.get_ticks_usec() - begin_usec >= 5_000_000: break
    var elapsed: float = float(Time.get_ticks_usec() - begin_usec) / 1_000_000.0
    _untimed(label + "-boundary")
    main.replay.pause()
    var end_tick: int = main.replay.scrub_tick
    segments.append({"label":label,"requested_seconds":5.0,"actual_seconds":elapsed,
        "actual_measured_phase_rows":accepted,"receipt":receipt})
    _check(accepted >= required_samples and elapsed >= 5.0 and elapsed <= 30.0, "unchanged exclusion and declared sample minimum " + label)
    _check(Context.digest(_log_bytes(main.battle_log)) == source_digest and FileAccess.get_sha256(ORIGINAL_PATH) == ORIGINAL_SHA, "record bytes untouched " + label)
    _check(Context.digest(Context.backend_bytes(main)) == backend_digest, "live backend immutable " + label)
    if advancing:
        _check(end_tick > 253 and end_tick < main.battle_log.playback_terminal_tick, "bounded natural advancing transport " + label)
    else:
        _check(Context.digest(Context.backend_bytes(main)) == backend_digest and Context.digest(var_to_bytes(main.presentation_3d.frame)) == frame_digest, "saved backend/frame immutable " + label)
        _check(Context.digest(var_to_bytes(_signature())) == signature_digest and _instances() == instances_before, "same actual bones/sockets/body/item across refresh " + label)
    await _capture(label)
    main.replay.set_tick(253)
    main._apply_replay_scrub()
    main.presentation_3d.refresh()
    _check(Context.digest(var_to_bytes(main.presentation_3d.frame)) == frame_digest and Context.digest(var_to_bytes(_signature())) == signature_digest, "exact original pose restored after window " + label)
    pair_rows.append({"label":label,"source_sha256":source_digest,"initial_backend_sha256":backend_digest,
        "initial_frame_sha256":frame_digest,"initial_signature_sha256":signature_digest,"canonical_frame_sha256":canonical_frame_digest,
        "process_token_normalization":PROCESS_TOKENS,"formal_a3_process_raw_frame_reference":ORIGINAL_FRAME_SHA,"initial_tick":253,
        "process_token_values":process_token_values,"bound_source_instance":main.battle_log.get_instance_id(),
        "end_tick":end_tick,"source_unchanged":Context.digest(_log_bytes(main.battle_log)) == source_digest,
        "restored_frame_sha256":Context.digest(var_to_bytes(main.presentation_3d.frame)),
        "restored_canonical_frame_sha256":Context.digest(var_to_bytes(_canonical_frame())),
        "restored_signature_sha256":Context.digest(var_to_bytes(_signature())),"advancing":advancing})

func _run() -> void:
    if DisplayServer.get_name() == "headless": quit(2); return
    directory = "res://build/asset_review/pr15-runtime/metadata-pair-" + OS.get_environment("AMBUSH_TEST_RUN_ID")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
    Context.configure(self)
    receipt_sha = FileAccess.get_sha256(OS.get_environment("AMBUSH_A3_PROVENANCE_FILE"))
    source_before = Context.proof(receipt_sha)
    _check(FileAccess.get_sha256("res://scripts/metadata_pair_external.gd") == OS.get_environment("AMBUSH_PAIR_FIXTURE_SHA"), "exact external fixture before")
    _check(_imports_match(), "complete identical loader sidecars before")
    _check(source_before.get("window_control_verified",false), "frozen production/source/engine/warm proof before")
    _check(FileAccess.get_sha256(ORIGINAL_PATH) == ORIGINAL_SHA, "original immutable archive input")
    if failures > 0: _finish(); return
    _new_collector()
    change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
    await process_frame
    await process_frame
    main = current_scene
    main.set_process(false)
    var source: BattleLog = BattleLog.new()
    var original: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(ORIGINAL_PATH))
    for key: String in ["attempt_id","events","snapshots","terminal_tick","terminal_reason","playback_schema","playback_snapshots","playback_terminal_tick"]: source.set(key,original[key])
    main.battle_log = source
    main.phase = main.Phase.WON # Explicit cold terminal fixture, no victory/progress accepted.
    _check(_begin_history(), "original replay entry binds archived source")
    main.replay.set_tick(253)
    main._apply_replay_scrub()
    var rig: Node3D = main.presentation_3d.rig
    rig.focus = Vector3(-6.5,0.0,-0.155217)
    rig.yaw_deg = 0.0
    rig.pitch_deg = 35.0
    rig.view_size = 12.0
    rig.apply_pose()
    main.presentation_3d.refresh()
    await _measure("yard-static-confirmed-shot",false)
    if failures == 0: await _measure("yard-advancing-original-replay",true)
    await _seal("yard-metadata-pair-metrics")
    source_after = Context.proof(receipt_sha)
    _check(FileAccess.get_sha256("res://scripts/metadata_pair_external.gd") == OS.get_environment("AMBUSH_PAIR_FIXTURE_SHA"), "same external fixture after")
    _check(_imports_match(), "same complete loader sidecars after")
    _check(source_after.get("window_control_verified",false), "same complete frozen proof after")
    _finish()

func _finish() -> void:
    if is_instance_valid(collector): collector.stop()
    var environment: Dictionary = Context.environment()
    environment["scope"] = "controlled archived original frame/advancing transport; main/presenter automatic callbacks; paired source versions, not new normal/whole/device"
    var file: FileAccess = FileAccess.open(directory + "/report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"format":1,"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),
        "source_game_tree":OS.get_environment("AMBUSH_A3_GAME_TREE"),"external_fixture_sha256":FileAccess.get_sha256("res://scripts/metadata_pair_external.gd"),
        "import_metadata_sha256":OS.get_environment("AMBUSH_PAIR_IMPORT_METADATA_SHA"),
        "receipt_sha256":receipt_sha,"source_proof_before":source_before,"source_proof_after":source_after,
        "checks":checks,"failures":failures,"environment":environment,"segments":segments,"chunks":chunks,
        "pair_rows":pair_rows,"captures":captures,"scope":"two fixed source versions; preserved originals; repeatedABBA/BAAB analyzed separately; no source intuition or mobile FPS claim"},"  "))
    file.close()
    print("METADATA_PAIR_TEST checks=",checks," failures=",failures," windows=",pair_rows.size()," output=",directory)
    root.get_node("AudioDirector")._stop_music_hard()
    if is_instance_valid(main): main.queue_free()
    if is_instance_valid(collector): collector.queue_free()
    await process_frame
    await create_timer(0.1).timeout
    quit(0 if failures == 0 else 1)
