# Ambush Loop cloud start

1. Run `.codex/cloud/install.sh`; it pins Godot 4.7.2 and performs the required first editor import.
2. Read `AGENTS.md` and `.cursor/docs/PLANNING_INDEX.md` before editing.
3. Run destructive tests only through `ambush_loop/scripts/run_isolated_test.sh`.
4. First verify the real Accept-to-Yard transition:
   `ambush_loop/scripts/run_isolated_test.sh "$HOME/.local/bin/godot" accept_cta_flow_gate.gd`
5. For gameplay changes, run the relevant focused gate and then the full smoke through the same wrapper.
6. Cloud results are desktop/headless evidence only. Android APK, touch, audio, memory, and vivo device acceptance remain local gates.
7. Never commit APKs, signing files, secrets, device logs, or personal phone data.
