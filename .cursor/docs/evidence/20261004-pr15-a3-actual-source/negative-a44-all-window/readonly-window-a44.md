# Read-only a44 Window sample failure

Source a44a33ee348fa53e1b1c6d539d7ffcf114e4283c; UUID fc18ecaa395e453aa7708e3aa20e9a44. Existing report8189checks/2failures/completefalse. Outcomes yard and warehouse each2waves;192 matrices retained. Four later levels did not run. No engine/test/import/display/benchmark or raw/source modification performed.

warehouse-live-SCOUT-command wall duration2.041791seconds. Exactly3 raw rows:

| frame | ticks_usec | interval_usec | measured | phase | exclusion |
|---|---|---|---|---|---|
|3|504488713|1674853|0|0|first_frame_after_segment_transition|
|4|504643062|154349|1|0|empty|
|5|505548467|905405|1|0|empty|

All three have main_auto_process1 and render_counters_ready1. Timed mark at503507557usec/frame_boundary2. Thus the minimum3 actual phase samples fails correctly: only2 accepted SCOUT samples. First row is intentionally excluded because its interval crosses the prior segment boundary; preserving that exclusion is required. Counter readiness/provenance is not the observed rejection. Warehouse CSV SHA59fab42bd215e87215807fe6d1f9aac549079515bafff9f904d853a7262a6a2d;1737rows/1350accepted, overflow0, symboloverflow0, validfalse. Environment reports llvmpipe LLVM19.1.7/opengl3. Long and variable observed render intervals explain why a2second wall dwell need not yield four postdraw callbacks. Raw does not isolate renderer time from callback/source/other CPU work, so this is not a measured GPU causal attribution.

Minimum test-only repair: each bounded _dwell marks once and captures starting row_count, then retains natural automatic callbacks until wall elapsed>=requested seconds AND original command elapsed>=requested command_seconds AND at least3 newly appended actual measured rows for this label and requested phase (or actual replay phase4 for source matrices). Read only appended rows/maintain incremental cursor; require row4==1, matching label, phase and source identity, not merely total row_count or process_frame count. Observe postdraw-completed rows: process_frame wakes before all rendering work for that frame, so an incremental prior-postdraw count is conservative; alternatively use frame_post_draw after collection ordering is known. Keep cold/first exclusions untouched. Use explicit30wallsecond deadline for dwell, save actual elapsed/count/timeout receipt, fail if any required bound remains unsatisfied, and preserve partialraw. Only constant scalar counting belongs in measured callbacks; do not hash/deepcopy/export inside timing.

Keep live ALERT full-wave loop separate: current original phaseWATCHING natural termination to SWEEP,180wallsecond cap, retained transition rows. Do not prolong a finished wave, pause/reenter/retick/replace phase or synthetic FX merely to obtain samples. If a naturally short ALERT wave yields fewer3 accepted ALERT rows, report that failure; do not count transition-phase rows. Stable SCOUT/SWEEP/WON/FAILED/paused histories can extend dwell while recording the actual longer window.

Risks: adaptive dwell changes realized durations and weights samples by renderer throughput; record requested/actual durations and summarize by phase without claiming fixed-duration equivalence. Motion can finish during extendedSCOUT/SWEEP, so3phase samples alone does not ensure every sample contains moving dust; original source-selection/positive-pool gates remain essential. Requirement phase can disappear before3samples; bounded failure must remain explicit. Thirtyseconds is only a cap and can be overshot by a blocked callback; no engine intervention should hide this. Longer windows can approach buffer capacity; lifetime overflow must remain sticky and old negative evidence preserved. New source proof and fresh all-level execution required after repair.

Evidence commands: read-only Python json/csv extraction of report and warehouse raw/metadata; sed/rg of driver dwell/liveALERT and collector postdraw first/readiness/measured logic. No fresh runtime result claimed.
