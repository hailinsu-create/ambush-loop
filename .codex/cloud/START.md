# Ambush Loop cloud start

1. Run `.codex/cloud/install.sh`; it pins Godot 4.7.2, verifies the official release archive's SHA-512 before extraction, and performs the required first editor import.
2. Read `AGENTS.md` and `.cursor/docs/PLANNING_INDEX.md` before editing.
3. Run destructive tests only through `ambush_loop/scripts/run_isolated_test.sh`.
4. First verify the real Accept-to-Yard transition:
   `ambush_loop/scripts/run_isolated_test.sh "$HOME/.local/bin/godot" accept_cta_flow_gate.gd`
5. For gameplay changes, run the relevant focused gate and then the full smoke through the same wrapper.
6. Cloud results are desktop/headless evidence only. Android APK, touch, audio, memory, and vivo device acceptance remain local gates.
7. Never commit APKs, signing files, secrets, device logs, or personal phone data.
8. Run `.codex/cloud/install-look.sh` in environment setup for pinned Blender 5.2.2 and glTF tools. Put `$HOME/.local/bin` on PATH. Use `.agents/skills/paperroute-game-build/SKILL.md` for Look work; preserve the existing ArtSource pipeline and Engine/Look separation. Linux graphics-library dependencies and actual rendering must be checked in the published environment.
9. Use `.agents/skills/ambush-web-gpt-review/SKILL.md` and `.codex/cloud/WEB_REVIEW.md` for external PLAN/REVIEW. Verify exact source revision before accepting any response; the old local connector does not automatically follow this branch.
