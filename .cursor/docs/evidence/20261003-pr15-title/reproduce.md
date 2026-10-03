# Fixed title source / isolated native reproduction

Source226505fb7cc424fb8ff955e94f98f086835b2423, basea2188f988e525263dbdf3968e9edd8153326c52f. title-candidate.patch is an exact binary-safe Git diff for review; applying it is not publishing or a replacement for the fixed commit. Git auth previously failed; this package is local until original authenticated branch push is restored. No Library upload was attempted.

Godot4.7.2 official ed1daf0bf. One owned private Xorg112; do not use a shared display. Create an isolated worktree at the source, run editor_import via wrapper if needed, start private Xorg using xorg.conf at a free owned display, and point a wrapper to the pinned Godot binary with DISPLAY and AMBUSH_TEST_X11_DISPLAY set to that same private display. LIBGL_ALWAYS_SOFTWARE=1, X11, GL Compatibility, Dummy audio. Do not run native input concurrently on the display. run_isolated_test.sh creates unique XDG roots and rejects unsafe input.

```bash
bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-full-godot title_menu_viewport_test.gd --render
AMBUSH_TITLE_EXIT_ONLY=keyboard bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-full-godot title_menu_viewport_test.gd --render
```

The first run should cover8 real window/scale/preference combinations and exit through the original production Quit button; second uses Tab/Enter with original binding. GameSettings.record_win(depot) and tutorial seen flags are explicit isolated unlock/progress fixtures, not actual six-level victories. Existing full-record formal29 is not re-run. Linux XTest mouse/key input and forced HUD preference do not prove physical phone touch or performance.
