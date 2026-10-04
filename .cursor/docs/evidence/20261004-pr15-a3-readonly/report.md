# PR15 A3 read-only collection proposal — 2026-10-04

Read-only inspection at observed HEAD da1b50a5c34c1ab01e4838df6d9dfe7c12e8aa52. Main author is changing source concurrently; this SHA describes this inspection, not a final candidate. Read AGENTS.md, execution v2, same-candidate FX/A3 plan, device_probe.gd, presenter/ViewState/pools, isolated runner, native journey pack/test, INITIAL baseline and six-record consumer reports. No engine launched, installs, source/asset edits, auth/adb/device operations or agents spawned. Only this owned report written. Proposal only: no raw runtime measurements, independent QA or performance acceptance.

## Existing hooks and gaps

- `scripts/presentation/device_probe.gd`: start/stop/step; Time.get_ticks_usec deltas, 30-second rotating/tilting/zooming rig, first two seconds excluded, raw frame_ms, p95/p99, global draw/primitive maxima, final texture memory, engine/OS/model/GPU/viewport and phase only at end. Writes user://a0_camera_probe.json. Mutates/restores camera only. No per-frame phase identity, pool peaks, resident memory trend, shader evidence, cold/warm distinction or multi-phase journey capture. Do not mistake its two-second exclusion for proven shader warm-up.
- `presenter_3d.gd:236` refreshes each `_process`; public `frame`, `rig`, `shot_fx`, `tool_fx` provide read-only collection hooks. `ViewState.capture` gives level_id/attempt_id/wave_id/frame_seq/local_tick/tick/playback_tick/phase/recorded_phase/replay plus version/revision fields. In replay report both phase and recorded_phase; replay UI phase is not the recorded combat phase.
- `shot_fx_pool.gd:157 diagnostics()`: capacity, mesh_nodes, cache size/capacity, sample_calls/rejected sockets/geometry, active descriptors/scope. `tool_fx_pool.gd:126`: capacity8/saving_capacity2, mesh_nodes40, shared meshes/material count, active/scope/rejected geometry. Diagnostics duplicate arrays: per-frame deep descriptor dumping adds allocation cost. Minimal active counts can be collected, but extending cheap count/high-water APIs is a main-author change. Dust pool still in progress; collect its actual final interface rather than invent one.
- `environment_battle_test.gd` already uses Viewport.get_render_info visible draw counters. Many fixtures await RenderingServer.frame_post_draw before snapshots; none is a complete A3 collector.

## API basis (official docs; confirm availability against exact 4.7.2 in main author's future run)

[Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html): use get_monitor with TIME_PROCESS/TIME_PHYSICS_PROCESS, RENDER_TOTAL_DRAW_CALLS_IN_FRAME, RENDER_TOTAL_PRIMITIVES_IN_FRAME, RENDER_TOTAL_OBJECTS_IN_FRAME, RENDER_TEXTURE_MEM_USED/RENDER_BUFFER_MEM_USED/RENDER_VIDEO_MEM_USED, MEMORY_STATIC and OBJECT_COUNT/OBJECT_NODE_COUNT/OBJECT_RESOURCE_COUNT/OBJECT_ORPHAN_NODE_COUNT. Object counters are counts, not byte usage; MEMORY_STATIC is not full process RSS. Some monitors lag or are debug-only: zero in release cannot establish zero cost. PIPELINE_COMPILATIONS_CANVAS/MESH/SURFACE/DRAW/SPECIALIZATION give available compile counters; record deltas and backend support, never turn unsupported zero into proof of no warm-up.

[RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html): frame_post_draw runs after viewport updates. Record get_current_rendering_method(), get_current_rendering_driver_name(), get_video_adapter_name/vendor/api_version(). get_frame_setup_time_cpu() reports CPU setup milliseconds; get_rendering_device() is null for OpenGL/headless, so Compatibility cannot rely on RD counters. Rendering counters require initial rendered frames. Post-draw intervals are wall-clock render cadence including stalls, not isolated GPU time. Do not call force_sync each sample because synchronization changes the workload.

Use existing `Time.get_ticks_usec()` for raw interval timestamps, Engine.get_version_info and Engine.max_fps, DisplayServer.get_name/window_get_vsync_mode, root Window size/content_scale_factor and rig pose for run metadata. Record actual resolution/scaling and limiter separately from measured cadence. Do not assume requested backend is actual backend.

## Minimal collector design (main-author implementation proposal)

A test-only Node connected once to RenderingServer.frame_post_draw, attached before original title flow, uses current_scene.presentation_3d when present. It reads the already captured presenter.frame; it never calls simulation/tick/record mutators or runs capture again. Keep scalar arrays/chunks and flush outside measured windows. No PNG/screen_get_image/assert loops, descriptor dumps or per-frame print during timing. Mark fixture operations/captures explicitly and omit their timings from gameplay summaries while retaining raw rows.

Suggested row:

```
{render_frame, ticks_usec, interval_usec, segment_id, measured, exclusion_reason,
 level_id, attempt_id, wave_id, phase, recorded_phase, frame_seq,
 local_tick, tick, playback_tick, replay, replay_speed, sim_paused,
 camera_yaw, camera_pitch, camera_size, environment_lod,
 draws, primitives, rendered_objects, texture_bytes, buffer_bytes, video_bytes,
 static_bytes, object_count, node_count, resource_count, orphan_node_count,
 process_sec, physics_sec, render_setup_ms,
 shot_active, shot_capacity, shot_cache, tool_active, tool_capacity,
 dust_active_or_null, policy, collector_usec}
```

Skeletal callback (not executed/compiled):

```gdscript
var last_us: int = 0
func sample_post_draw() -> void:
    var now := Time.get_ticks_usec()
    var interval_us := now - last_us if last_us != 0 else -1
    last_us = now
    var host := get_tree().current_scene
    if host == null or not ("presentation_3d" in host): return
    var view = host.presentation_3d
    if view == null: return
    var f: Dictionary = view.frame
    var row := {"ticks_usec": now, "interval_usec": interval_us,
        "level_id": f.get("level_id", ""), "phase": f.get("phase", -1),
        "recorded_phase": f.get("recorded_phase", -1),
        "attempt_id": f.get("attempt_id", ""), "wave_id": f.get("wave_id", -1),
        "frame_seq": f.get("frame_seq", -1), "playback_tick": f.get("playback_tick", -1),
        "draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
        "primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
        "texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
        "static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
        "node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}
    # Append scalar row into bounded chunks; flush after measured segment.
```

Prefer two rates: timestamp/render draw counters each post-draw; memory/count/pool metrics 5–10Hz plus segment-boundary/high-water queries. FX peaks can occur between coarse samples: main-author cheap per-frame active/high-water counters are more reliable than 10Hz snapshots. Keep collection overhead in receipt; instrumented vs uninstrumented repeat of identical original record/camera schedule determines distortion. Never silently skip unavailable fields; write null/support flag.

Process RSS separately from /proc/<owned-engine-pid>/status (VmRSS/VmHWM) and cgroup memory.current/limits; don't call object counts object memory. Capture /proc/cpuinfo summary, CPU allocation/cgroup cpu.max (actual read here: `400000 100000`, four CPU quota), concurrent load, software GL flags, display server and log GPU string. Other agents/tests sharing host invalidate clean timing comparisons even with separate display.

## Coverage and workload reuse

1. Freeze post-dust source SHA/game tree, asset/R5 revision, one PCK/hash and instrumentation fixture hash. Use `build_journey_test_pack.py` in independent checkout: clean-game guard, source copy, original title/main retained, only Linux Desktop custom_features=a0_preview, fresh isolated XDG import/export, exact actual exits receipt. It writes source/build and refuses existing SHA directory; do not rerun in main writer's tree.
2. Reuse `first_visit_journey_test.gd` native plan unchanged for fresh title -> six levels/13 waves -> natural WON/CTA/credits. It uses real XTest callbacks and no loadout/unlock/directtick grants. Scope all plus unique output label; own rendered x11 display is mandatory. Collect real SCOUT/ALERT/paused ALERT/SWEEP/WON; separately time unpaused active segments. Capture/settle/assert/native driver delays are overhead windows. Original old journey does not cover FAILED, all direction dwells, 60fps/2x configuration or every tool trigger: add bounded separately labelled workloads.
3. Existing six INITIAL original raw records were actually rehashed read-only here; all match producer a05 manifest:
   yard 4e27b9af88ad72199489ee11e987e1ab0e8200c47bc963e831f4c9eb1883c164
   warehouse cba97cc34446a384d1853a6b7c7224afbd32c5c456ee215fbf5afffdc0015cfd
   pump e0faee3000b85ae795737dfd7b39e510e4a0670560d40a0a01890e5acfba2b46
   railcut 19919a17225308894332b5cf9a849b4bc004792afa02f3c5e27d25b0f08f9628
   depot 1720fe0dc83bfa2647d22c0dcc74b5bea35ac11db2ce25a141e3fb734d156d6d
   radio 69926921f672c941f66bc2885ba15e0484f37923e7addae0670047cae0653d22
   Directory `/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75`, filenames native-player-LEVEL-record.bin; `/tmp/pr15-d9c-record3d/all-manifest.json` available. Original replay fixture `/tmp/pr15-d9c-record3d/native_record_replay_test.gd` has native pause/speed/seek and whole engine2x `_whole_engine_playback`, but repeated assertions/ClockProbe bookkeeping are functional workload overhead. Copy/adapt externally for lightweight A3 measurement; existing d9c shim binds OLD PCK and must not be reused for new consumer. Old records lack final new FX descriptors, so use them for compatibility comparison only; final FX peaks require new final-source native records or clearly labelled actual-domain reference positives.
4. For REPLAY separately label fixed old producer/new consumer and final producer=consumer. Run original full continuous1x and2x plus paused/seek at each phase, across waves/reset/return. Old fixture whole only2x does not establish full1x. FAILED requires a deliberate original native loss/abort flow or existing authentic failed record; reference fixtures are separately labelled and cannot fill normal coverage.
5. Camera cost: fixed yaw/pitch/zoom segments at six levels, all phases and peak FX; repeat exact schedule (eight yaw directions, pitch35/65 and near/far) for comparisons. Camera-only movement is presentation; do not change battle rules/sight distance/character scale to improve figures. Include standard and saving policy only if both exist in final source.

## Warm-up, reporting and future commands

Keep cold-start raw rows including initial shader/resource spikes. Separate later warm repeat of same scene/pose/FX path with same cache environment. Two initial seconds alone are insufficient; label phase entry, first-shot/tool/LOD/cutaway spikes and compile-counter deltas. Record cache paths and whether fresh/warm. Do not delete caches of other runs. Compile counters and elapsed times do not prove Android shader behavior.

For each same-input segment report sample count/duration, median/p95/p99/max interval, frames >33.33ms and >16.67ms, draw/primitives peaks, memory/count baseline/peak/post-reset, pool peaks/capacity/dropped/rejected if available, cold vs warm, instrument overhead and actual exits/errors. Keep raw rows and quantile method. Set budgets from measured baseline and explain optimization cost; historical 200 draw warning is not an established final numerical acceptance threshold. Compare terminal/events/ammo/HP/inventory/record hashes before and after optimizations.

Future commands (not executed; main author must create new fixed shim/collector first):

```bash
# Independent clean checkout/source. Uses existing script; captures build receipt.
python3 ambush_loop/scripts/build_journey_test_pack.py /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64
# /tmp/pr15-a3-fixed-godot must pin that NEW pack, x11, Dummy and external collector.
DISPLAY=:OWNED AMBUSH_TEST_X11_DISPLAY=:OWNED LIBGL_ALWAYS_SOFTWARE=1 \
AMBUSH_TEST_SOURCE_SHA=FINAL_SHA AMBUSH_JOURNEY_SCOPE=all \
AMBUSH_JOURNEY_OUTPUT_LABEL=a3-FINAL_SHA \
bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-a3-fixed-godot first_visit_journey_test.gd --render
# Separate replay harness: NEW fixed consumer pack and isolated allowlisted external entry.
DISPLAY=:OWNED AMBUSH_TEST_X11_DISPLAY=:OWNED LIBGL_ALWAYS_SOFTWARE=1 \
AMBUSH_TEST_SOURCE_SHA=FINAL_SHA AMBUSH_RECORD_SOURCE_SHA=PRODUCER_SHA \
AMBUSH_NATIVE_RECORD_MANIFEST=/tmp/OWNED/manifest.json \
AMBUSH_NATIVE_RECORD_DIR=/absolute/pinned/records \
bash /tmp/OWNED/ambush_loop/scripts/run_isolated_test.sh /tmp/OWNED/godot-pck-external native_record_replay_test.gd --render
```

Root runner currently rejects native_record_replay_test.gd; previous external allowlisted runner handles it. Extend only the main-author owned external/staged runner after review; never bypass isolation guard. Current journey can run as-is for behavior, but no A3 env flag/collector currently exists: commands alone do not yield proposed metrics. New instrumentation and lightweight workload implementation remain the actual blocker.

Use independent checkout/stage, fresh UUID/XDG directories and own Xorg/Xvfb display with fixed resolution; no existing display takeover. Separate display prevents native input/window collisions but not shared CPU contention. Serialize measurement against other engine work or record contention and restrict conclusions. Previous :115/:116 were closed per reports; their display numbers are not reusable proof of ownership. Cloud llvmpipe comparison is environment-local, never phone30/60FPS, thermal stability, ear-listening or FINAL acceptance.

## Inspection command evidence

Harmless read commands: `cat`/`sed` of named instructions/scripts/reports; `rg` searches for Performance/RenderingServer/frame intervals/probe/pool/journey interfaces; `git rev-parse HEAD` gave da1b50...; `cat /sys/fs/cgroup/cpu.max` gave 400000 100000; Python json.load of old manifest plus hashlib.sha256 of six raw files gave matches above. First broad rg call actual exit2 because nonexistent optional `ambush_loop/presentation` path; subsequent focused reads exit0. No engine command executed in this package. Official API docs fetched read-only, stable docs not a runtime validation of pinned4.7.2 symbols.
