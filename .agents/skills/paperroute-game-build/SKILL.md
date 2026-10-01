---
name: paperroute-game-build
description: Build or review Ambush Loop visuals using its reproducible PaperRoute Blender pipeline, separate from gameplay changes.
---

Read the complete canonical skill at `.cursor/skills/paperroute-game-build/SKILL.md` before acting, then `.cursor/docs/SKETCH_PAPERROUTE.md` and `ambush_loop/ArtSource/README.md`. Those existing files remain the source of truth; this entry makes them discoverable in Codex Cloud.

Run `.codex/cloud/install-look.sh` during environment setup. Add `$HOME/.local/bin` to PATH. `blender-headless --python ambush_loop/ArtSource/build_yard_crate.py` runs the existing deterministic pipeline; `gltf-transform inspect ambush_loop/ArtSource/yard_crate.glb` checks its output. Never count existing generated art as a new successful cloud render.

When `AMBUSH_TOOLS_DIR` is configured, add its `bin` directory instead; do not redefine HOME. The installed Python launcher owns a private Xvfb display, propagates failures, times out after `AMBUSH_BLENDER_TIMEOUT` seconds (default 900), and waits for both children during cleanup. Preserve its real exit status. Setup must install the launcher and installers from the same exact revision; see `.codex/cloud/START.md`.

Keep Engine and Look in separate commits. For Look, deliver the generator, GLB, front/side/rear clay and shaded contact sheet, applicable iso/top bake, and an actual in-engine screenshot. A render without an in-engine screenshot is not gameplay acceptance. Do not redesign silhouettes, camera scale, or combat rules to conceal a visual defect.

Meshy remains optional and disabled until a real authorized key and supported CLI are available. Do not copy local credentials, invent availability, or spend credits without authorization. Keep operator silhouettes in the meantime.
