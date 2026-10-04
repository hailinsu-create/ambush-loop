# Read-only SWEEP fixture review — 5b305 / a31

Scope: source inspection and existing raw artifact decoding only. No Godot, test, import, display, benchmark, or repository edits were performed. Existing run UUID `cd10249808f647faa03046cb99993dda` ended actual1 with 410 checks / 2 failures, E0/S0. This report is not A3 acceptance.

## Confirmed cause

`ambush_loop/scripts/a3_campaign_metrics_test.gd:95` hard-selects operator index0 in `_command_walk()`. Original `main.gd:8133` rejects movement for a null, invisible, dead, or locked operator. Original SWEEP entry (`main.gd:12519`) unlocks and stops operators and heals only living visible operators; it does not resurrect dead ones. Selection does not imply eligibility.

Read-only Python decoding consumed all 5,589,244 bytes of the existing `yard-partial-reference-record.bin`. In actual last SWEEP (wave1, playback ticks1364–1397), operator id1 was dead, hp0, lockedfalse, at (496,240). Operators id2 and id3 were alive and unlocked (hp77.8 and100; positions (784,240) and (912,528)). Hence selected index0 cannot start movement, regardless of candidate destination. This is an ineligible fixture actor, not an observed SWEEP unlock failure.

Existing partial record SHA256: `ac389bcf6bbf4965c582cabfeeb8f74166a0b5f6031b4fa1e97a30f8bf06a187`. Attempt `e908860e460af718551b68ee11abf397`; terminal battle tick1283, win, playback terminal1398,237 frames,34 events. Existing report records two waves with wave-end ticks1056 and227. Original WON was reached; the later matrix did not run. Preserve these failures and partial evidence.

## Minimum correct fixture API change

In `_command_walk`, search actual operators for `alive && visible && !locked` (prefer scout index2 as the already passed movement-dust fixture does), select via original `_select_op(index)`, then issue original `_command_move_selected(destination)`, verifying the selected operator actually `is_moving()`. Continue to another eligible actor/destination when rejected. Do not mutate hp/alive/locked, movement paths, FX pool, dust, phase, or source snapshots.

Drop the extra `grid.has_los` prerequisite: original movement uses `RaidPathfinderScript.find_path` and permits routed movement. Keeping LOS narrows the fixture beyond the actual command contract and can falsely reject reachable destinations. The existing bounded destination search still may find no path on some levels; report a fixture failure unless original command succeeds, or search a bounded set of actual unblocked reachable cells through that command API.

`movement_dust_test.gd:153–191` demonstrates the existing legal route: naturally reach first-wave SWEEP, `_select_op(2)`, retain selected scout, `_command_move_selected(grid.cell_to_world_center(Vector2i(32,16)))`, advance original `_process(1/60)`24 times, then check movement, position change, unchanged battle tick and actual presenter pool actor id3. Its fixed yard cell is evidence of a passed yard fixture, not a universal six-level destination guarantee.

## Evidence commands

Read-only `rg -n` located `_command_walk`, `_command_move_op`, `_select_op`, `_enter_sweep` and `_history_and_phases`; `sed -n` read those source ranges. Existing `run.log` and `report.json` were read. Python `struct` decoded the existing Godot Variant archive without invoking the engine; entire byte consumption was checked. No new runtime outcome is claimed. Parent must rerun corrected fixed-source fixture before proceeding to formal matrices.
