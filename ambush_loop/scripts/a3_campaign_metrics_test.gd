extends SceneTree
## Actual domain sources. Reference grants/API inputs are explicit, never native-normal evidence.
const Guard := preload("res://scripts/test_storage_guard.gd")
const Collector := preload("res://scripts/a3_render_metrics.gd")
const Context := preload("res://scripts/a3_window_context.gd")
const View := preload("res://scripts/presentation/view_state.gd")
const Shot := preload("res://scripts/presentation/shot_fx_frame.gd")
const Tool := preload("res://scripts/presentation/tool_fx_frame.gd")
const Dust := preload("res://scripts/presentation/movement_dust_frame.gd")
const Space := preload("res://scripts/presentation/world_space.gd")
const CASES := [["yard",[1,2,5],[90.0,180.0,180.0]],
    ["warehouse",[1,3,5],[180.0,0.0,180.0]], ["pump",[1,4,5],[90.0,0.0,180.0]],
    ["railcut",[1,4,5],[270.0,270.0,180.0]], ["depot",[1,4,5],[270.0,270.0,180.0]],
    ["radio",[1,4,5],[270.0,90.0,270.0]]]
var checks := 0
var failures := 0
var directory: String
var receipt_sha: String
var main: Node
var collector: Node
var source_before: Dictionary = {}
var source_after: Dictionary = {}
var segments: Array = []
var chunks: Array = []
var records: Array = []
var captures: Array = []
var outcomes: Array = []
var stopped := false
var selected_levels := 0
var collector_lifetimes: Array = []
var command_receipts: Array = []

func _new_collector() -> void:
    collector=Collector.new();root.add_child(collector)
    collector_lifetimes.append({"chunk_index":collector_lifetimes.size(),"collector_instance_id":collector.get_instance_id(),
        "engine_frames_at_hook":Engine.get_frames_drawn(),"ticks_usec_at_hook":Time.get_ticks_usec(),
        "identity_scope":"raw frame is this collector's monotonic callback sequence; join chunks by unique instance/chunk and global ticks_usec, not a reused run_id"})

func _init() -> void:
    if not Guard.check(): quit(91); return
    call_deferred("_run")

func _check(ok: bool, message: String) -> void:
    checks += 1
    if not ok: failures += 1; print("A3_CAMPAIGN_FAIL " + message)

func _wait(seconds: float) -> void:
    var deadline := Time.get_ticks_usec() + int(seconds * 1_000_000)
    while Time.get_ticks_usec() < deadline: await process_frame

func _untimed(label: String, reason: String = "fixture_or_transition") -> void:
    collector.mark(label,false,reason)

func _log_bytes(log: BattleLog) -> PackedByteArray:
    return var_to_bytes({"attempt_id":log.attempt_id,"events":log.events,"snapshots":log.snapshots,
        "terminal_tick":log.terminal_tick,"terminal_reason":log.terminal_reason,
        "playback_schema":log.playback_schema,"playback_snapshots":log.playback_snapshots,
        "playback_terminal_tick":log.playback_terminal_tick})

func _archive(label: String) -> Dictionary:
    var path := directory+"/"+label+"-record.bin"
    _check(not FileAccess.file_exists(path),"unique original source archive " + label)
    var file := FileAccess.open(path,FileAccess.WRITE)
    if file==null:_check(false,"source archive opens " + label);return {}
    file.store_buffer(_log_bytes(main.battle_log));file.close()
    var result := {"label":label,"path":path,"sha256":FileAccess.get_sha256(path),
        "level_id":main.level.level_id,"attempt_id":main.battle_log.attempt_id,
        "terminal":main.battle_log.terminal_tick,"reason":main.battle_log.terminal_reason,
        "playback_terminal":main.battle_log.playback_terminal_tick,
        "frames":main.battle_log.playback_snapshots.size(),"events":main.battle_log.events.size(),
        "scope":"original controlled API/reference recording; no native normal/progress acceptance"}
    records.append(result)
    return result

func _capture(label: String) -> void:
    _untimed(label+"-capture","screenshot")
    await RenderingServer.frame_post_draw
    await RenderingServer.frame_post_draw
    var picture := DisplayServer.screen_get_image(root.current_screen).get_region(Rect2i(root.position,root.size))
    var path := directory+"/"+label+".png"
    _check(picture.get_size()==Vector2i(1280,720) and picture.save_png(path)==OK,"actual original Window capture " + label)
    captures.append({"path":path,"sha256":FileAccess.get_sha256(path),"scope":"untimed actual Window API/reference/historical view"})

func _dwell(label: String, seconds: float, receipt: Dictionary, immutable: bool = false) -> void:
    var before: String = Context.digest(_log_bytes(main.battle_log)) if immutable else ""
    receipt["configuration"] = Context.workload(main)
    receipt["level_id"]=main.level.level_id
    receipt["attempt_id"]=main.battle_log.attempt_id
    receipt["wave"]=main.battle_log.wave_id
    collector.mark(label,true,"",receipt)
    var begin := Time.get_ticks_usec()
    await _wait(seconds)
    var end := Time.get_ticks_usec()
    _untimed(label+"-boundary")
    if immutable: _check(Context.digest(_log_bytes(main.battle_log))==before,"original recorded source immutable " + label)
    segments.append({"label":label,"requested_seconds":seconds,"actual_seconds":float(end-begin)/1_000_000,
        "receipt":receipt,"source_immutable":immutable})

func _command_walk() -> bool:
    var receipt := {"level_id":main.level.level_id,"attempt_id":main.battle_log.attempt_id,
        "wave":main.battle_log.wave_id,"phase":main.phase,"candidates":[],"accepted":false}
    command_receipts.append(receipt)
    if not main._is_command_phase():return false
    for index: int in [0,2,1]:
        var op: OperatorUnit=main.operators[index]
        var candidate := {"operator_index":index,"id":op.op_id,"alive":op.alive,
            "visible":op.visible,"locked":op.locked,"position_before":op.global_position,"destinations":[]}
        receipt.candidates.append(candidate)
        if not op.alive or not op.visible or op.locked:continue
        main._select_op(index)
        var origin: Vector2i = main.grid.world_to_cell(op.global_position)
        for offset: Vector2i in [Vector2i(3,0),Vector2i(-3,0),Vector2i(0,3),Vector2i(0,-3),Vector2i(1,0),Vector2i(0,1)]:
            var destination := origin+offset
            if main.grid.is_blocked(destination.x,destination.y):continue
            var point: Vector2 = main.grid.cell_to_world_center(destination)
            main._command_move_selected(point) # Original A* API may route around an obstacle; no artificial LOS gate.
            candidate.destinations.append({"cell":destination,"moving_after":op.is_moving()})
            if op.is_moving():
                receipt.accepted=true
                receipt.selected_id=op.op_id
                receipt.destination=destination
                return true
    return false

func _live_reference(case: Array) -> bool:
    var id: String = case[0]
    main.set_process(false)
    _untimed(id+"-original-load")
    main._load_level(id,false,false)
    root.get_node("GameSettings").set_quality_tier("standard")
    main.presentation_3d.set_process(true)
    main.presentation_3d.rig.reset_view()
    await process_frame
    await process_frame
    _check(main.phase==main.Phase.SETUP,"actual original SCOUT " + id)
    _check(_command_walk(),"legal original SCOUT command starts movement " + id)
    main.set_process(true)
    await _dwell(id+"-live-SCOUT-command",2.0,{"kind":"original live command callbacks","phase":0,"scope":"API command, not native input"})
    await _capture(id+"-live-SCOUT")
    main.set_process(false)
    _untimed(id+"-reference-resource-snap")
    main.raid_prepare_ref(case[1],case[2])
    if id=="warehouse":main._play_hold_pack(1)
    if id in ["depot","radio"]:main._try_place_tripwire(main.grid.cell_to_world_center(Vector2i(7,11)))
    main.raid_force_alarm()
    _check(main.phase==main.Phase.WATCHING,"actual original alarm reaches ALERT " + id)
    if failures>0:return false
    var wave_ends: Array=[]
    for wave: int in main.level.wave_count():
        main.sim.set_speed(1.0)
        main.set_process(true)
        if wave==0:
            await _dwell(id+"-live-ALERT-entry",2.0,{"kind":"original live simulation callbacks","phase":1,"wave":wave,"speed":1.0})
            _check(main.phase==main.Phase.WATCHING,"reference still ALERT for pause control " + id)
            main._on_pause_pressed()
            var pause_tick: int=main.sim.tick
            var pause_source := Context.digest(_log_bytes(main.battle_log))
            await _dwell(id+"-paused-ALERT",2.0,{"kind":"original pause API; main/presenter still process","phase":1,"wave":wave},true)
            _check(main.sim.paused and main.sim.tick==pause_tick and Context.digest(_log_bytes(main.battle_log))==pause_source,"pause freezes original sim/source " + id)
            await _capture(id+"-paused-ALERT")
            main._on_pause_pressed()
        var label := id+"-live-ALERT-wave%d" % wave
        var live_receipt := {"kind":"original live simulation callbacks, no direct ticks","phase":1,"wave":wave,"speed":1.0,
            "level_id":id,"attempt_id":main.battle_log.attempt_id,
            "configuration":Context.workload(main),"boundary_scope":"actual transition-phase rows retained; phase summaries select actual phase1"}
        collector.mark(label,true,"",live_receipt)
        var start := Time.get_ticks_usec()
        var timeout := start+180_000_000
        while main.phase==main.Phase.WATCHING and Time.get_ticks_usec()<timeout:await process_frame
        var end := Time.get_ticks_usec()
        _untimed(label+"-finish")
        main.set_process(false)
        segments.append({"label":label,"actual_seconds":float(end-start)/1_000_000,
            "receipt":live_receipt,"source_immutable":false})
        _check(main.phase==main.Phase.SWEEP,"original live wave reaches SWEEP " + id+" "+str(wave))
        print("A3_CAMPAIGN_STAGE level=%s wave=%d phase=%d tick=%d" % [id,wave,main.phase,main.sim.tick])
        if failures>0:return false
        wave_ends.append(main.sim.tick)
        main.raid_vacuum_loot() # Original reference helper, outside timing; never called a normal pickup.
        if wave==main.level.wave_count()-1:_check(_command_walk(),"legal last SWEEP command starts movement " + id)
        main.set_process(true)
        await _dwell(id+"-live-SWEEP-wave%d" % wave,2.0,{"kind":"original live SWEEP command callbacks","phase":5,"wave":wave,"vacuum_before_window":true})
        main.set_process(false)
        main._on_sweep_commit()
    _check(main.phase==main.Phase.WON and main.raid.waves_cleared==main.level.wave_count(),"all authored reference waves reach original WON " + id)
    outcomes.append({"level_id":id,"wave_ends":wave_ends,"waves":main.raid.waves_cleared,"phase":main.phase,
        "terminal":main.battle_log.terminal_tick,"events":main.battle_log.events.size(),"reason":main.battle_log.terminal_reason})
    await _capture(id+"-original-WON")
    main.set_process(true)
    await _dwell(id+"-live-WON",2.0,{"kind":"original terminal presentation callbacks","phase":3},true)
    main.set_process(false)
    return failures==0

func _begin_history() -> bool:
    _untimed("original-replay-entry")
    main._on_replay_pressed()
    main.replay.pause()
    main.set_process(true)
    main.presentation_3d.set_process(true)
    _check(main.phase==main.Phase.REPLAY and main.replay.continuous_playback and main.replay.log==main.battle_log,"original replay binds exact current produced source")
    return failures==0

func _select_source(phase: int, feature: String) -> Dictionary:
    var best: Dictionary={}
    var score := -1
    for snap: Dictionary in main.replay.log.playback_snapshots:
        if int(snap.data.phase)!=phase:continue
        main.replay.set_tick(snap.playback_tick)
        var frame: Dictionary=View.capture(main)
        _check(frame.recorded_phase==phase,"actual selected last-at-tick frame retains requested recorded phase")
        if frame.recorded_phase!=phase:continue
        var active: Array = Shot.active(frame) if feature=="shot" else (Tool.active(frame) if feature=="tool" else (Dust.active(frame) if feature=="dust" else []))
        if active.size()>score:
            score=active.size()
            var focus: Vector3=Vector3.ZERO
            if not active.is_empty():
                var position: Vector2 = active.front().get("source_pos",Vector2.ZERO) if feature=="shot" else active.front().position
                focus=Space.logic_to_world(position)
            best={"tick":snap.playback_tick,"frame_seq":frame.frame_seq,"wave":frame.wave_id,
                "recorded_phase":phase,"feature":feature,"active_saved_candidates":active.size(),
                "frame_sha256":Context.digest(var_to_bytes(frame)),"focus":focus,"attempt_id":frame.attempt_id}
    _check(not best.is_empty(),"original recorded phase exists " + str(phase)+" "+feature)
    if feature in ["shot","tool","dust"]:_check(score>0,"original confirmed saved feature exists " + feature+" phase="+str(phase))
    return best

func _matrix(level_id: String, label: String, choice: Dictionary, archive: Dictionary) -> void:
    if choice.is_empty():return
    for policy: String in ["standard","power_saving"]:
        for index: int in 8:
            _untimed(label+"-pose-policy-settle")
            root.get_node("GameSettings").set_quality_tier(policy)
            main.replay.set_tick(choice.tick)
            main._apply_replay_scrub()
            var rig: Node3D=main.presentation_3d.rig
            rig.focus=choice.focus
            rig.yaw_deg=index*45.0
            rig.pitch_deg=35.0 if index%2==0 else 65.0
            rig.view_size=12.0 if index%4<2 else 36.0
            rig.apply_pose()
            main.presentation_3d.refresh()
            await _wait(0.4)
            var frame: Dictionary=main.presentation_3d.frame
            _check(frame.frame_seq==choice.frame_seq and frame.attempt_id==archive.attempt_id and Context.digest(var_to_bytes(frame))==choice.frame_sha256,"same original selected frame and source at every policy/pose " + label)
            var segment := "%s-%s-yaw%d" % [label,policy,index*45]
            await _dwell(segment,2.0,{"kind":"paused exact historical source render with original main/presenter processing",
                "source_archive":archive,"selected_source":choice,"policy":policy,
                "coverage":"16 representative poses: eight yaw at alternating35/65 pitch and12/36 extent, both policies; not64 Cartesian views"},true)
            if index==0 and policy=="standard":await _capture(level_id+"-"+label+"-source")
            var stop_path := OS.get_environment("AMBUSH_A3_STOP_FILE")
            if not stop_path.is_empty() and FileAccess.file_exists(stop_path):stopped=true;return
            if failures>0:return

func _primary_history(level_id: String, archive: Dictionary) -> void:
    if not _begin_history():return
    for spec: Array in [[0,"dust","SCOUT-saved-move"],[1,"shot","ALERT-confirmed-shot"],[5,"dust","SWEEP-saved-move"],[3,"none","WON-original-source"]]:
        var choice := _select_source(spec[0],spec[1])
        await _matrix(level_id,level_id+"-"+str(spec[2]),choice,archive)
        print("A3_CAMPAIGN_STAGE level=%s historical_source=%s failures=%d" % [level_id,spec[2],failures])
        if failures>0 or stopped:return
    _untimed(level_id+"-replay-speed-transport")
    main.presentation_3d.rig.reset_view()
    root.get_node("GameSettings").set_quality_tier("standard")
    for speed: float in [1.0,2.0]:
        main.replay.set_speed(speed);main.replay.play(true)
        main._apply_replay_scrub()
        await _dwell(level_id+"-REPLAY-live-%dx" % int(speed),3.0,
            {"kind":"original natural replay advance, bounded3s only; not whole playback","phase":4,"speed":speed,"source_archive":archive},true)
        _check(main.replay.scrub_tick>0,"original replay naturally advances " + level_id+" "+str(speed))
        main.replay.pause()
    _check(Context.digest(_log_bytes(main.battle_log))==archive.sha256,"primary source archive exact after all history controls " + level_id)

func _tool_attempt(case: Array) -> Dictionary:
    var id: String=case[0]
    _untimed(id+"-separate-tool-reference")
    main.set_process(false)
    main._load_level(id,false,false)
    main.presentation_3d.rig.reset_view()
    await process_frame
    await process_frame
    var owner: OperatorUnit=main.operators[0]
    owner.receive_item("grenade",1) # Separate explicit one-tool resource fixture, no invented descriptor.
    var target: Vector2=Vector2.INF
    for y: int in 22:
        for x: int in 40:
            var point: Vector2=main.grid.cell_to_world_center(Vector2i(x,y))
            var distance: float=owner.global_position.distance_to(point)
            if main.grid.is_blocked(x,y) or distance<110.0 or distance>150.0 or not main.grid.has_los(owner.global_position,point):continue
            if main.operators.any(func(op:OperatorUnit)->bool:return op.global_position.distance_to(point)<100.0):continue
            target=point;break
        if target.is_finite():break
    _check(target.is_finite(),"original source has safe authored open tool destination " + id)
    if not target.is_finite():return {}
    _check(main._throw_grenade_from(owner,target),"actual original throw consumes explicit fixture inventory " + id)
    main.set_process(true)
    await _dwell(id+"-live-original-grenade-fuse",2.0,
        {"kind":"original SCOUT grenade fuse/boom callbacks","phase":0,"scope":"explicit one-grenade API/resource fixture, not natural battle peak"})
    main.set_process(false)
    var confirmed: Array=main.battle_log.playback_snapshots.filter(func(snap:Dictionary)->bool:return not snap.data.get("tool_fx",[]).is_empty())
    _check(not confirmed.is_empty(),"actual fuse recorded confirmed tool source " + id)
    main.raid_force_alarm()
    _check(main.phase==main.Phase.WATCHING,"original tool attempt can enter ALERT for abort " + id)
    main._on_abort_pressed()
    _check(main.phase==main.Phase.FAILED and main.battle_log.terminal_reason=="abort","original API abort records FAILED " + id)
    await _capture(id+"-original-FAILED-abort")
    main.set_process(true)
    await _dwell(id+"-live-FAILED-abort",2.0,{"kind":"actual original abort terminal presentation, not natural firefight loss","phase":2},true)
    main.set_process(false)
    return _archive(id+"-tool-and-abort-reference")

func _seal(label: String) -> void:
    _untimed(label+"-seal")
    collector.stop()
    var path := directory+"/"+label
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
    var error: Error=collector.save(path,{"segments":segments,"scope":"controlled actual source A3; not native normal/device/FINAL"})
    _check(error==OK,"actual source/buffer/receipt seal " + label)
    var receipt: Variant=JSON.parse_string(FileAccess.get_file_as_string(path+"/metadata.json"))
    if not receipt is Dictionary:_check(false,"actual chunk metadata exists " + label);return
    _check(receipt.chunk_source_and_buffer_valid and receipt.receipt_stable and receipt.warm_import_proof_complete and not receipt.run_incomplete and receipt.run_overflow_rows==0,"actual complete valid metric chunk " + label)
    _check(receipt.raw_sha256==FileAccess.get_sha256(path+"/raw.csv") and receipt.rows==collector.row_count and receipt.metadata.source_proof_before.receipt_sha256==receipt_sha and receipt.source_proof_after.receipt_sha256==receipt_sha,"actual raw/count/fixed receipt hashes exact " + label)
    var accepted := 0
    var by_segment: Dictionary={}
    for index: int in collector.row_count:
        var row: Array=collector.row_at(index)
        _check(row.size()==59,"actual exact raw protocol width " + label)
        if row[4]==1:
            accepted+=1
            _check(row[31]==1 and row[34]==1 and row[2]>0 and row[5]=="" and is_finite(row[30]) and row[30]>=0,"actual accepted source row ready/finite " + label)
            if not by_segment.has(row[3]):by_segment[row[3]]=[]
            by_segment[row[3]].append(row)
    var summaries: Array=[]
    for declared: Dictionary in segments:
        if not str(declared.label).begins_with(main.level.level_id+"-"):continue
        var measured_rows: Array=by_segment.get(declared.label,[])
        var spec: Dictionary=declared.receipt
        var phase_rows: Array=measured_rows.filter(func(row:Array)->bool:return row[9]==spec.phase) if spec.has("phase") else measured_rows
        _check(phase_rows.size()>=3,"every declared timed window has actual phase samples " + str(declared.label))
        _check(measured_rows.all(func(row:Array)->bool:return row[6]==spec.level_id and row[7]==spec.attempt_id and (row[9]==4 or row[8]==spec.wave) and row[32]==1),"actual timed rows retain original level/attempt and live wave with automatic main callbacks " + str(declared.label))
        if spec.has("speed") and spec.get("phase",-1)==4:
            _check(phase_rows.all(func(row:Array)->bool:return row[15]==spec.speed),"actual requested transport speed " + str(declared.label))
        if spec.has("selected_source"):
            var selected: Dictionary=spec.selected_source
            var configuration: Dictionary=spec.configuration
            _check(measured_rows.all(func(row:Array)->bool:return row[9]==4 and row[10]==selected.recorded_phase and row[7]==selected.attempt_id and row[8]==selected.wave and row[11]==selected.frame_seq and row[13]==selected.tick and row[20]==spec.policy and row[17]==configuration.yaw_deg and row[18]==configuration.pitch_deg and row[19]==configuration.view_size and row[32]==1),"actual matrix raw exact source/phase/pose/policy " + str(declared.label))
            var column: int=21 if selected.feature=="shot" else (25 if selected.feature=="tool" else (27 if selected.feature=="dust" else -1))
            if column>=0:_check(measured_rows.any(func(row:Array)->bool:return row[column]>0),"actual rendered pool positive for selected original source " + str(declared.label))
        summaries.append({"label":declared.label,"accepted":measured_rows.size(),"requested_phase_samples":phase_rows.size(),
            "transition_phase_rows_retained":measured_rows.size()-phase_rows.size()})
    _check(accepted>=3,"actual accepted metric rows exist " + label)
    var first_usec: int=int(collector.row_at(0)[1]) if collector.row_count>0 else -1
    var last_usec: int=int(collector.row_at(collector.row_count-1)[1]) if collector.row_count>0 else -1
    if not chunks.is_empty():_check(first_usec>chunks.back().last_usec,"different collector chunks advance global monotonic time")
    chunks.append({"path":path,"raw_sha256":FileAccess.get_sha256(path+"/raw.csv"),"rows":collector.row_count,
        "accepted":accepted,"save_error":error,"valid":failures==0 and error==OK,"segment_summaries":summaries,
        "first_usec":first_usec,"last_usec":last_usec,"collector_instance_id":collector.get_instance_id(),
        "segment_receipts":receipt.segments.size(),"segment_capacity":Collector.SEGMENT_CAPACITY,
        "symbol_overflow":receipt.symbol_overflow,"run_overflow_rows":receipt.run_overflow_rows})

func _run() -> void:
    if DisplayServer.get_name()=="headless":quit(2);return
    directory="res://build/asset_review/pr15-runtime/a3-campaign-"+OS.get_environment("AMBUSH_TEST_RUN_ID")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
    Context.configure(self)
    for case: Array in CASES:root.get_node("GameSettings").mark_tutorial_seen(case[0])
    receipt_sha=FileAccess.get_sha256(OS.get_environment("AMBUSH_A3_PROVENANCE_FILE"))
    source_before=Context.proof(receipt_sha)
    _check(source_before.get("window_control_verified",false),"complete fixed loaded-source receipt before scene")
    if failures>0:_finish();return
    _new_collector()
    change_scene_to_file("res://scenes/presentation/yard_3d.tscn")
    await process_frame
    await process_frame
    main=current_scene
    var scope := OS.get_environment("AMBUSH_A3_LEVEL")
    _check(scope.is_empty() or CASES.any(func(case:Array)->bool:return str(case[0])==scope),"requested actual level scope exists")
    if failures>0:await _seal("invalid-scope");_finish();return
    for case: Array in CASES:
        if not scope.is_empty() and scope!=case[0]:continue
        selected_levels+=1
        if not await _live_reference(case):
            _archive(str(case[0])+"-partial-reference")
            await _seal(str(case[0])+"-partial")
            break
        var original := _archive(str(case[0])+"-primary-reference")
        if original.is_empty():await _seal(str(case[0])+"-archive-failure");break
        await _primary_history(case[0],original)
        if failures==0 and not stopped:
            var tools := await _tool_attempt(case)
            if not tools.is_empty() and _begin_history():
                for spec: Array in [[0,"tool","confirmed-tool-source"],[2,"none","FAILED-abort-source"]]:
                    var choice := _select_source(spec[0],spec[1])
                    await _matrix(case[0],str(case[0])+"-"+str(spec[2]),choice,tools)
                    if failures>0 or stopped:break
                _check(Context.digest(_log_bytes(main.battle_log))==tools.sha256,"tool/abort original source exact after history " + str(case[0]))
        await _seal(str(case[0])+"-actual-source-metrics")
        print("A3_CAMPAIGN_LEVEL_END level=%s checks=%d failures=%d stopped=%s" % [case[0],checks,failures,stopped])
        if failures>0 or stopped:break
        if case!=CASES.back() and (scope.is_empty()):
            var old_id: int=collector.get_instance_id()
            var old: WeakRef=weakref(collector)
            collector.queue_free()
            await process_frame
            await process_frame
            _check(not is_instance_valid(old.get_ref()) and RenderingServer.frame_post_draw.get_connections().all(func(item:Dictionary)->bool:return item.callable.get_object_id()!=old_id),"accepted sealed collector releases lifetime tables/disconnects before next level")
            if failures>0:break
            _new_collector() # New lifetime only after previous raw+metadata archived; no overflow/reset erasure.
    source_after=Context.proof(receipt_sha)
    _check(source_after.get("window_control_verified",false),"same fixed source/engine/warm receipt after source workload")
    if scope.is_empty() and not stopped:_check(outcomes.size()==6 and outcomes.reduce(func(total:int,item:Dictionary)->int:return total+item.waves,0)==13,"all six original reference levels/thirteen waves measured")
    if not stopped:
        _check(segments.filter(func(item:Dictionary)->bool:return item.receipt.kind=="paused exact historical source render with original main/presenter processing").size()==selected_levels*96,"all declared sixteen-pose/six-source views completed for selected levels")
    _finish()

func _finish() -> void:
    if is_instance_valid(collector):collector.stop()
    var environment := Context.environment()
    environment.scope="original live callback/API-reference and exact historical source workload; main/presenter process automatically during timed windows; not stationary controls/native normal/device/FINAL"
    var file := FileAccess.open(directory+"/report.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"format":1,"source_sha":OS.get_environment("AMBUSH_TEST_SOURCE_SHA"),
        "receipt_sha256":receipt_sha,"source_proof_before":source_before,"source_proof_after":source_after,
        "checks":checks,"failures":failures,"stopped":stopped,"level_scope":OS.get_environment("AMBUSH_A3_LEVEL"),
        "complete":failures==0 and not stopped and outcomes.size()==selected_levels and selected_levels>0,
        "environment":environment,"chunks":chunks,"segments":segments,"records":records,"captures":captures,"outcomes":outcomes,"command_receipts":command_receipts,
        "collector_lifetimes":collector_lifetimes,
        "scope":"original live callback reference/API sources + exact paused recorded16-pose/policy views, bounded3s natural1x/2x; no whole/native normal/device/FINAL acceptance",
        "limitations":"post-draw FX peaks can miss between-frame simulation events; representative16 views omit48 Cartesian combinations; warm imports not cold boot; llvmpipe/GPUtime unavailable/pipeline unknown"},"  "))
    file.close()
    print("A3_CAMPAIGN_METRICS_TEST checks=%d failures=%d levels=%d stopped=%s output=%s" % [checks,failures,outcomes.size(),stopped,directory])
    root.get_node("AudioDirector").pause_for_background()
    quit(1 if failures>0 else (3 if stopped else 0))
