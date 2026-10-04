# Read-only movement dust audit

Source: 00c6c6976a75179612c8c4f75c7118c0d898e99f. No engine, tests, repository edits, or asset operations.

Strict saved-data seam gap: ViewState movement_supported (view_state.gd:33) does not validate raw data.phase as TYPE_INT. The envelope normalizes recorded_phase via int(data.phase) at line 40, so a saved phase=1.0 with valid simulation-domain/movement1 data can reach movement_dust_frame.gd:15 as typed integer 1. Similar raw snapshot schema/wave fields are normalized at lines 41-43. ReplayPlayer bind validates playback_tick strictly but normalizes other envelope fields (replay_player.gd:33-37). This is a static corrupt-history concern, not a reproduced normal runtime defect. Add movement-specific raw envelope gates without changing old replay behavior, and verify a selected saved snapshot with malformed phase/schema/wave fields.

Raw actor copying is before defaults: view_state.gd:98-108 copies original types into movement_fx_actors, independently of actor defaults. Reader checks active/alive/moving bools, typed identity/stance/sprinting, action consistency, finite coordinates, duplicate identity and domain/phase agreement.

Clock is selected saved pose_clock_s plus historical snapshot_delta, with command/simulation domain gates. Positions remain selected snapshot positions; this is a moving-pose cue, not interpolated path or historic footfall trail.

Pool has fixed 48 mesh nodes / one shared mesh / 24 transparent slot materials. No wall clock or tween. Every update hides all puffs, then validates derived centers/directions/clock cycles and all puff positions/scales before writes. Source/scope changes clear visibility. Materials are rewritten for every occupied slot. No normal-path P1/P2 identified from source alone.

No independent render, resource release, natural travel, full13, A3 or device validation claimed.
