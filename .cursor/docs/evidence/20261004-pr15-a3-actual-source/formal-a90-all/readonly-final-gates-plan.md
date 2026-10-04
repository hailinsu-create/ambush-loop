# FINAL same-source executable interfaces — read-only plan

No tests, engine/import/export, repository changes or fixtures were executed/created. Current running A3 warehouse remains exclusively owned by root. Commands below are future execution templates, not receipts or claimed successes. Freeze the final production source F and HEAD:ambush_loop tree T after all repairs; tests/consumer changes must be tracked separately and their game tree equivalence proven.

## 1. Existing build and fresh native producer

Existing scripts/build_journey_test_pack.py takes one absolute Godot argument, refuses dirty ambush_loop, builds into ambush_loop/build/player_journey/<F first12>/ (refuses an existing directory), copies staged game excluding .godot/build/ArtSource/docs, enables only staged Linux Desktop a0_preview, then runs actual isolated import and export-pack. Future command:

    python3 ambush_loop/scripts/build_journey_test_pack.py /absolute/Godot_v4.7.2-stable_linux.x86_64

It records build.log, failure receipt on nonzero subprocess, and receipt.json with source/tree/engine/PCK details. Hash receipt/PCK and imported resources; preserve actual source/import/export commands and exits. Do not reuse INITIAL a05 PCK as FINAL. A0 feature changes in staging must be declared and compared; this is a test PCK, not Android build/production art acceptance. Build helper does not run destructive smoke; gameplay must still use Guard.

Existing first_visit_journey_test.gd is rendered/native only (headless quits2). Use a newly reviewed engine shim equivalent to archived INITIAL shim, binding exactly the freshly built FINAL PCK, x11 and Dummy; this shim is a necessary main-author staging deliverable, not an existing generic FINAL wrapper. Guard template:

    DISPLAY=:<owned> AMBUSH_TEST_X11_DISPLAY=:<owned> LIBGL_ALWAYS_SOFTWARE=1 \
    AMBUSH_TEST_SOURCE_SHA=<F> AMBUSH_JOURNEY_SCOPE=all \
    AMBUSH_JOURNEY_OUTPUT_LABEL=final-<F first12> \
    bash ambush_loop/scripts/run_isolated_test.sh /absolute/new-final-pck-shim first_visit_journey_test.gd --render

Do not set AMBUSH_JOURNEY_START=resume or AMBUSH_JOURNEY_SEED_RECEIPT for fresh FINAL. Wrapper creates independent UUID and XDG_DATA_HOME/config/cache, exports AMBUSH_TEST_DATA_ROOT/RUN_ID and prints TEST_RUN_ID/DATA_ROOT/ENTRY/LOG. all requires a new independent output label; existing output is refused. No direct destructive entry invocation.

Producer output: JOURNEY_OUTPUT=res://build/asset_review/pr15-runtime/<label>-<UUID>; first-visit-journey-report.json, native-player-<level>-record.bin, viewport PNGs, per-level player-progress directories with original cfg/settings bytes and manifest, radio credits return checkpoint. first_visit lines445-476 seal raw and verify actual credits open/native wheel scroll/return Title. Existing producer is ordinary Title/main/native UI and engine callbacks, without grant/vacuum/directtick/reference helpers. Verify six levels, waves2/2/2/2/2/3, normal WON and CTA, natural progress, actual credits open/scroll/return; report only reached states. source-derived strategy is not stranger usability evidence.

Termination: actual process exit0, FIRST_VISIT_JOURNEY_TEST failures0, complete six/13 evidence and required CTA/progress/credits rows, Guard proven before autoload, ERROR0/SCRIPT ERROR0. A green exit alone is insufficient for completeness. Seal actual producer command, F/T/PCK SHA, UUID, raw SHA for six records, clocks/attempt/wave/events/frame counts, cfg copies and PNG hashes/view receipts. INITIAL a05 manifest and 1193/0 remain historical comparison evidence only.

## 2. Existing external native consumer and missing whole1x implementation

Archived executable interface: .cursor/docs/evidence/20261004-pr15-native-record3d/fixed-d9c-six-r/{staged-wrapper.sh,godot-pck-external,external-fixture.gd,boundary.json,producer-manifest.json}. It is outside current shared Guard allowlist: archived staged wrapper alone allows native_record_replay_test.gd. Its engine shim hardcodes old d9c PCK and /tmp fixture, so it is NOT directly reusable as FINAL.

External fixture env interface:

    DISPLAY=:<owned> AMBUSH_TEST_X11_DISPLAY=:<owned> LIBGL_ALWAYS_SOFTWARE=1 \
    AMBUSH_TEST_SOURCE_SHA=<final consumer source> AMBUSH_CONSUMER_STAGE=final-six-whole \
    AMBUSH_RECORD_SOURCE_SHA=<F> AMBUSH_NATIVE_RECORD_MANIFEST=/absolute/final-producer-manifest.json \
    AMBUSH_NATIVE_RECORD_DIR=/absolute/fresh-final-JOURNEY_OUTPUT \
    bash /absolute/reviewed-final-staged-wrapper.sh /absolute/final-pck-external-shim native_record_replay_test.gd --render

Do not set AMBUSH_RECORD_DIAGNOSTIC_SHORT=1. Existing fixture verifies explicit producer manifest/source/raw SHA, cold scene binding, seeks, native pause/speed/event focus, source/live/sim unchanged and records all six. Output NATIVE_RECORD_OUTPUT=res://build/asset_review/pr15-runtime/native-record3d-UUID with report/boundary/PNG/input evidence. It exits0 only if failures0 and returned record count equals manifest count.

Critical missing implementation: _whole_engine_playback lines305-331 hardcodes speed2, one whole pass and120ticks/s expectation, with wall deadline480000ms. Short1x transport segments are NOT whole1x. Main author must add separate complete natural-engine1x AND2x per each fresh record, restart from0, correct60/120 rate oracles, actual terminal/frame identity/source-unchanged evidence, deadlines reflecting actual playback/source/environment and explicit timeout failure. Bound callbacks or seek-to-terminal do not substitute. Record phase crossings, pause/repeat/backward/forward seek/event focus and source-switch neutrality; all final producer raw bytes must remain unchanged. Track external consumer source/fixture/wrapper SHA and F game/PCK SHA separately; do not claim an external fixture changes production source silently.

## 3. Real schema1 compatibility (existing shared entry)

full_command_record_replay_test.gd accepts AMBUSH_LEGACY_RECORD_FIXTURE to a retained actual schema1 raw binary. It verifies original playback1415/domain terminal1283/events34, sampled identity and repeated root/20bone signatures across seeks and captures full_actual_schema1_history. Template:

    AMBUSH_TEST_SOURCE_SHA=<F> AMBUSH_LEGACY_RECORD_FIXTURE=/absolute/authentic-schema1.bin \
    bash ambush_loop/scripts/run_isolated_test.sh /absolute/final-source-or-pck-shim full_command_record_replay_test.gd --headless

Run rendered counterpart with owned display for actual compatibility images. Preserve producer provenance and before/after raw SHA; do not infer actual old record from synthesized schema1 dictionaries. This existing test provides bounded genuine legacy compatibility; it does not automatically provide complete whole1x/2x legacy playback, which needs an explicitly added requirement/driver if FINAL requires it.

## 4. Fullsmoke and shared regression entry interfaces

    AMBUSH_TEST_SOURCE_SHA=<F> bash ambush_loop/scripts/run_isolated_test.sh /absolute/Godot smoke_test.gd --headless

Use full entry, not smoke_contract_test.gd as replacement. Require actual exit0, SMOKE_OK_RAID_LOOP and SMOKE_SLICE_COMPLETE, no ERROR/SCRIPT ERROR, plus full expected path/report confirmation. Existing code contains more than one slice-complete branch, so a marker alone does not prove full coverage. Prior failed fullsmoke and bounded testfix results cannot be combined into FINAL pass.

No aggregate shared-suite shell entry was found in scripts during this audit. Existing allowlisted per-entry Guard execution is the concrete interface:

    AMBUSH_TEST_SOURCE_SHA=<F> bash ambush_loop/scripts/run_isolated_test.sh /absolute/Godot <allowlisted_test.gd> --headless

Use --render with owned display where native/Window required; native first_visit refuses headless. Main author must freeze an explicit suite manifest of required entries and actual mode/commands/exits, covering current source-boundary/FX pools/raw envelopes, equipment freeze, corpse/runtime/contact/pairing, command/history/replay timeline/lifecycle, presentation/input/HUD/result/credits, actor/firearm/environment, storage/contracts and old2D relevant gates. Current run_isolated_test.sh lines7-11 are the source of truth for callable entries; do not invent a generic --all command. Full regression should run serially after A3, with own UUID/output isolation. Add any external FINAL consumer allowlist only in reviewed staging or an explicit main-author test slice.

## 5. Required proof and non-substitution checklist

All final receipts: frozen F/T, engine version+SHA, staged differences, exact commands/env, actual import/export/runtime exits, PCK path/hash/size, original and imported-resource inventory proofs, source/run UUID, XDG/Guard evidence, owned display/process closure, E/S counts, raw/PNG/report hashes and physical image review count. Freeze input/fixture/source proofs before running; elapsed time, printed completion, collector seals or detached jobs do not prove termination. Keep negative/development runs separately.

Cannot substitute: INITIAL a05 producer, d9c archived whole2x, old reference13wave fixtures, static display matrices, A3 representative/3second replay chunks, short1x/2x transport checks, seek-to-terminal, bounded legacy seek checks, old fullsmoke, cross-source QA sums, hash-only/viewport screenshots without required native behavior. None of the planned gates were executed by this audit.
