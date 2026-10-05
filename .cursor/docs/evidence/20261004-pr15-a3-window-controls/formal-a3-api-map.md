# Formal A3 workload API map — source-only

Fixed source 1dabd57d6694ef4630c9362086048ae818d3fd9f; game tree afd420c76a93d2af163d4805a774135799bfe6d8. Read A3 collection plan and existing reference/smoke/main/replay/three-pool source. No engine/import/Xorg/benchmark/production/asset edits; no raw measurements. Parent's16-condition Window is separate and not accepted by this report.

## Minimal test-only architecture

Use one isolated Guard test driver, frozen source/import receipt, unique output/display owned by main author, one engine serially. Attach A3 collector before production scene. Existing `a3_window_context.freeze` stops BOTH main and presenter and is appropriate stationary plumbing control only: DO NOT use it as the dynamic formal workload. The six-level phase workload must leave presenter refresh and original main callbacks enabled during live dynamic measurements; pause/freeze explicitly labelled separately.

Keep setup/reference grants/directticks/source inspection/checksum/camera changes/settling/screen capture/row reconstruction/seal outside measured segments. Collector reads presenter.frame after draw; don't call ViewState.capture in timed callback. Source selection outside timing may read capture/reader APIs and copied immutable archive for inspection, but never insert manufactured FX descriptors or alter actual stored source to populate pool.

Phase enum actual values: SETUP0=SCOUT, WATCHING1=ALERT, FAILED2, WON3, REPLAY4, SWEEP5. Record both phase and recorded_phase; REPLAY4 can display recorded any phase. Actual level identity main.level.level_id, never main.level_id.

For each valid chunk: untimed mark -> apply source/config/camera -> settle -> timed mark -> natural process frames for fixed recorded-clock window or explicitly stationary dwell -> untimed mark -> stop -> verify backend/record boundary and proofs -> save unique chunk -> assert source/buffer/lifetime/hashes -> reset accepted buffer -> mark restart boundary -> start. Keep cold first chunk and invalid partial artifacts. Define workload receipts with reference/normal/oldproducer-newconsumer scope and original event/attempt/wave/frame/clock/asset revision.

## Six-level reference phase producer sequence

Reusable strategy `campaign_replay_test.gd CASES`:

- yard [1,2,5]/[90,180,180]
- warehouse [1,3,5]/[180,0,180]
- pump [1,4,5]/[90,0,180]
- railcut and depot [1,4,5]/[270,270,180]
- radio [1,4,5]/[270,90,270]

Original `_battle(main,case,fps,speed,rotate)` is useful behavior/source producer, NOT ready-made performance driver: stops main/presenter, calls synthetic `_process`, `steps_for_frame`, `_sim_tick`, reference preparation/vacuum and extensive assertions. Reuse its sequence outside timing, not its loop elapsed as FPS.

Per-level API order:

1. settings.mark_tutorial_seen(level) and main._load_level(level,false,false); await queued cleanup. These are explicit controlled API/tutorial fixtures, not fresh native journey. Initial driver can use settings.pending_level_id and original scenes/presentation/yard_3d.tscn.
2. SCOUT original capture: original main.set_process(true), view.set_process(true), wait natural frame callbacks; optional original main._select_op(i), main._command_move_selected(main.grid.cell_to_world_center(cell)) for real saved command movement; don't assign actor.moving/pose/clock. Original main._process handles command motion/record advancement and pickups; label API move rather than native touch.
3. main.raid_prepare_ref(slots,facings,extra) explicitly grants authored role kit and snaps cover; warehouse main._play_hold_pack(1); depot/radio main._try_place_tripwire(cell7,11) as existing reference strategy. Record grants/snap fixture. main.raid_force_alarm() -> verify WATCHING. Use original callback loop during dynamic collection; no main._sim_tick in measured window.
4. Per authored wave, main.sim.set_speed(1.0) for primary; original main process runs actual shots/routes until SWEEP. Collect unpaused WATCHING and a separately controlled paused WATCHING window (original pause controls/API, preserve clock/pool ages); do not conflate pause with frozen stationary costs.
5. SWEEP legal command movement/loot possible. If producing canonical reference source outside timing, main.raid_vacuum_loot() consumes authored drops then main._on_sweep_commit(); label vacuum/reference, never normal pickup. Otherwise run actual _command_move_selected/engine pickup timing explicitly. Last commit reaches original WON via _extract_win; do not set phase=WON.
6. Seal complete log before _load_level resets/clears it. Store real BattleLog bytes/hash without modifying or upgrading source. Original scenario source expected terminals/events from campaign fixture can be behavior comparison, but revised input/windows may produce extra legitimate command/loot events; compare same input domain rather than forcing historic totals.

For full normal final evidence use existing first_visit_journey_test.gd all scope/unique label: original Title Start/mission/brief/tutorial/knife pickup/deploy/sweep/native CTA/credits, no source grants. This is distinct from reference producer and must run final source after optimization. No need to call its input helpers inside A3 callbacks.

## Camera/policy matrix

Camera API `view.rig.yaw_deg`, `pitch_deg`, `view_size`, `focus`; call rig.apply_pose outside timing. Actual clamp pitch35..65, orthographic size12..36 (size is camera extent, not render resolution). Minimum declared matrix per selected phase/source: yaw [0,45,90,135,180,225,270,315], pitch [35,65], size [12,36], policy [standard,power_saving] =64 views per phase. Six levels/6phases means2304 phase-pose-policy combinations if full Cartesian, before events/speeds. If representative sampling reduces it, publish exact coverage and omissions instead of all-matrix claim.

settings.set_quality_tier("standard"/"power_saving") before segment, original view.refresh() outside timing; natural refresh continues when dynamic. Saving changes workload selection but not source/HP/record, so reuse SAME bound replay source/event tick for policy pair. Fix camera focus target and record focus values; don't move game actors for prettier/cheaper views. For live event peak rare transient shots, use same complete replay source to reproduce angle matrix instead of timing distinct battles as matched event loads.

## Real shot/blast/dust sources, no copied FX

SHOT: campaign_replay_test producer generates actual events; shot_fx_source_test validates `event.payload.fx` schema1/confirmed/event_id-attempt-wave-seq/clock playback/source_group-source_id/target/position/visual weapon/R5 saved pose and actual hp_before-hp_after damage. main._try_fire_with_recorded_fx is actual success seam; main._on_op_fired_shot and _on_return_fired are callbacks. Do not call emit callbacks alone to pretend a shot occurred; pre-try fire event may exist without confirmed success. Use source events confirmed descriptor and original actual backend HP/ammo evidence. Source event clock/sequence must select compatible original frame; use `main.replay.playback_time(event)` and source snapshots around that clock. Pool update via presenter refresh only, no direct injected frame.

BLAST: real main._throw_grenade_from(op,destination) consumes inventory and creates original RaidGrenade; `_tick_raid_grenades` -> real fuse/detonated -> `_on_recorded_grenade_boom`/_on_grenade_boom produces confirmed tool_fx. Mine original receive_item grant + `_select_op` + `_try_place_inventory_mine(actual target position)` + `_tick_raid_mines` produces actual kill/mine and confirmed descriptor. Such setup is explicit source-reference fixture. Empty grenade explosion may have NO BattleLog blast event; tool descriptor actual confirmed original object/position/clock is valid, don't invent victim event. Existing tool_fx_source_test _throw/_blast and _damage/_empty_and_duplicate/_mine establish these actual seams; `_blast` advances sim/playback directly and must be outside timing. tool_fx_mine_reference_test legal actual mine part can be reused; its cloned corrupt second descriptor is ONLY negative boundary, never peak load. tool_fx_source_boundary_test _capacity creates66 actual grant/throw/fuse tools: explicit artificial stress, not natural peak. Publish natural observed peak and stress separately.

DUST: movement_dust_test _history_and_phases uses reference alarm then original `_sim_tick` until saved enemy walking, plus SWEEP `_command_move_selected` and `_process` until real operator moves. These are actual source clock/pose API fixtures outside timing. For measured live use natural original callbacks. Reader `movement_dust_frame.active(frame)` requires saved movement schema/playback/source group/id/position/direction/moving/clock; actor flags or copied frame edits cannot create purported real source. Record SCOUT/SWEEP command clock versus ALERT simulation clock; battle tick remains frozen while legal command movement progresses. Pause/seek shouldn't age dust via wall time.

Three public pool interfaces `update_frame(frame,power_saving)` are renderer APIs, not source production entry. Use normal presenter.refresh to bind source. `diagnostics()` deep-copies active/scope: outside timing only. Timed scalar counts from `_active.size` etc. Capacities actual shot12/saving4 (36 mesh nodes), tool8/saving2 (40mesh nodes), dust24/saving6 (48mesh nodes). Record actual active/source candidates/limited output and rejection deltas separately; pool cap is not natural battle peak. Unknown/old source missing descriptors stays neutral.

## FAILED/Title/replay APIs

Real API abort: original reference SCOUT prepare/alarm -> WATCHING -> main._on_abort_pressed() -> FAILED reason abort, then main._on_continue_pressed() for retry; original Title main._return_to_title() releases scene/pools. Smoke `_assert_fail_paths` also sets op.take_damage999 and flushes pending result to force wipe: original domain callback but explicit damage fixture, not naturally lost firefight. Natural escape/wipe needs actual authored bad plan/no-kill battle and original engine outcome; don't set main.phase or _show_fail_result to manufacture FAILED measurement. Record fail reason and exact original terminal/source; abort clears pools by design, so FAILED zeroFX alone doesn't demonstrate natural lethal/escape peaks.

Original `_on_replay_pressed()` requires actual allowed recorded source, binds `main.replay.log` and sets phase. ReplayPlayer.bind(log), set_tick, set_speed, play/pause are APIs; bind resets speed2 and may initially scrub terminal, so explicitly set_speed(1/2), play(true) for whole playback. Main.set_process(true) and presenter true -> original main._process naturally calls replay.advance(delta)/_apply_replay_scrub. Do not call advance or sim ticks manually during whole1x2x timing. Deadline is safety timeout, not FPS acceptance.

Replay source timeline has command/SWEEP intervals: max_tick=playback_terminal_tick for continuousPB; never battle_terminal as playback end. Same playback timestamp selects last frame; requested tick differs from actual selected frame_seq. For chosen phase/effect views: replay.pause(); replay.set_tick(t); main._apply_replay_scrub(); view.refresh outside timing; measure labelled paused source render, preserve actual frame/event/version. Whole1x2x needs natural complete0->terminal with live/sim/source unchanged and original phase/wave/event identities. Do not mutate BattleLog or borrow foreign live bodies. Original `_exit_replay_to_setup()` clears/restores setup; preserve producer source archive before reset.

Original INITIAL a05 six records and schema1 are compatibility only: hash pin bytes, separate producer/consumer, source missing final FX remains neutral. New source reference log gives authentic actual descriptors but not final normal13; final new native producer records same accepted source are needed for final FX/complete1x2x acceptance. Keep all three evidence classes distinct.

Remaining implementation risks: canonical A3 driver isn't existing campaign fixture elapsed; snapshots/event metadata can advance under normal main process, so compare originals before/after replay and equivalent domain outcomes for live, not frozen backend digest equality while live. Full matrix duration/capacity require sealed bounded chunks; don't overflow/reset away cold artifacts. Preserve invalid source/partial/timed-window errors. Standard/saving pair must prove source identity and same pose/config/backend counters with support caveats, collector overhead controls distinct from dynamic cost. All metrics remain environment-local llvmpipe, no mobile/ear/device/production claims.
