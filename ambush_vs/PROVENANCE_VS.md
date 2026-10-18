# Ambush VS — 素材与文件来源（PROVENANCE）

竖切（VS）目录 `ambush_vs/` 从 `main` 新建；可复用素材按清单自 CB5 tip 选择性拷贝。
本文件记录每个拷贝文件的来源分支、完整 SHA 与源路径。新写文件标为「本分支新建」。

## 基线

- 目标分支：`vs/core`（自 `main@c1aaf27c23f8f711f23305bf6f3223c38cb69098`）
- 素材来源分支：`codex/cb5-migration-closeout-20261008`
- 素材来源 tip SHA：`7879040c718cb6b6a05c5900cd7d0f01ce9fa21d`（PR #50 tip）
- 拷贝策略：保留源文件字节；不拷贝 Godot `*.import`；不合并旧 PR、不改玩法模拟逻辑。

## 自 CB5 tip 拷贝的文件

| 目标路径（ambush_vs/） | 来源路径 | 来源分支 | 来源 SHA |
| --- | --- | --- | --- |
| `ui/fonts/DejaVu-LICENSE.txt` | `ambush_loop/ui/fonts/DejaVu-LICENSE.txt` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `ui/fonts/DejaVuSans.ttf` | `ambush_loop/ui/fonts/DejaVuSans.ttf` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `ui/fonts/NotoSansCJKsc-Regular.woff2` | `ambush_loop/ui/fonts/NotoSansCJKsc-Regular.woff2` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `ui/fonts/OFL.txt` | `ambush_loop/ui/fonts/OFL.txt` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `ui/fonts/README.md` | `ambush_loop/ui/fonts/README.md` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `ui/fonts/web_ui_font.tres` | `ambush_loop/ui/fonts/web_ui_font.tres` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/alarm.wav` | `ambush_loop/art/audio_v2/alarm.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/alarm_stinger.wav` | `ambush_loop/art/audio_v2/alarm_stinger.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/ambient_depot.wav` | `ambush_loop/art/audio_v2/ambient_depot.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/ambient_pump.wav` | `ambush_loop/art/audio_v2/ambient_pump.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/ambient_radio.wav` | `ambush_loop/art/audio_v2/ambient_radio.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/ambient_railcut.wav` | `ambush_loop/art/audio_v2/ambient_railcut.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/ambient_warehouse.wav` | `ambush_loop/art/audio_v2/ambient_warehouse.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/ambient_yard.wav` | `ambush_loop/art/audio_v2/ambient_yard.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/barrel.wav` | `ambush_loop/art/audio_v2/barrel.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/body_drop.wav` | `ambush_loop/art/audio_v2/body_drop.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/crate_lid.wav` | `ambush_loop/art/audio_v2/crate_lid.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/door.wav` | `ambush_loop/art/audio_v2/door.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/echo_ping.wav` | `ambush_loop/art/audio_v2/echo_ping.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/empty.wav` | `ambush_loop/art/audio_v2/empty.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/escape.wav` | `ambush_loop/art/audio_v2/escape.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fail.wav` | `ambush_loop/art/audio_v2/fail.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire.wav` | `ambush_loop/art/audio_v2/fire.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_bolt.wav` | `ambush_loop/art/audio_v2/fire_bolt.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_garand.wav` | `ambush_loop/art/audio_v2/fire_garand.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_mg.wav` | `ambush_loop/art/audio_v2/fire_mg.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_mg42.wav` | `ambush_loop/art/audio_v2/fire_mg42.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_ping.wav` | `ambush_loop/art/audio_v2/fire_ping.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_pistol.wav` | `ambush_loop/art/audio_v2/fire_pistol.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_scout.wav` | `ambush_loop/art/audio_v2/fire_scout.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_shotgun.wav` | `ambush_loop/art/audio_v2/fire_shotgun.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/fire_smg.wav` | `ambush_loop/art/audio_v2/fire_smg.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/foot.wav` | `ambush_loop/art/audio_v2/foot.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/handoff.wav` | `ambush_loop/art/audio_v2/handoff.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/hit.wav` | `ambush_loop/art/audio_v2/hit.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/kill.wav` | `ambush_loop/art/audio_v2/kill.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/knife.wav` | `ambush_loop/art/audio_v2/knife.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/leak.wav` | `ambush_loop/art/audio_v2/leak.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/loot.wav` | `ambush_loop/art/audio_v2/loot.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/manifest.json` | `ambush_loop/art/audio_v2/manifest.json` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/night_enter.wav` | `ambush_loop/art/audio_v2/night_enter.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/op_death.wav` | `ambush_loop/art/audio_v2/op_death.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/return_fire.wav` | `ambush_loop/art/audio_v2/return_fire.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/select.wav` | `ambush_loop/art/audio_v2/select.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/spawn.wav` | `ambush_loop/art/audio_v2/spawn.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/stealth_bed.wav` | `ambush_loop/art/audio_v2/stealth_bed.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/tension.wav` | `ambush_loop/art/audio_v2/tension.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/trip.wav` | `ambush_loop/art/audio_v2/trip.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/ui.wav` | `ambush_loop/art/audio_v2/ui.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/whistle.wav` | `ambush_loop/art/audio_v2/whistle.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/win.wav` | `ambush_loop/art/audio_v2/win.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/audio_v2/win_stinger.wav` | `ambush_loop/art/audio_v2/win_stinger.wav` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/manifest.json` | `ambush_loop/art/environment_v2/manifest.json` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/materials/environment_v2_atlas.tres` | `ambush_loop/art/environment_v2/materials/environment_v2_atlas.tres` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/materials/environment_v2_emission.tres` | `ambush_loop/art/environment_v2/materials/environment_v2_emission.tres` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ammo_can_lod0.glb` | `ambush_loop/art/environment_v2/models/env_ammo_can_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ammo_can_lod1.glb` | `ambush_loop/art/environment_v2/models/env_ammo_can_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_barbed_wire_lod0.glb` | `ambush_loop/art/environment_v2/models/env_barbed_wire_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_barbed_wire_lod1.glb` | `ambush_loop/art/environment_v2/models/env_barbed_wire_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_curb_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_curb_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_curb_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_curb_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_depot_tank_pair_lod0.glb` | `ambush_loop/art/environment_v2/models/env_depot_tank_pair_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_depot_tank_pair_lod1.glb` | `ambush_loop/art/environment_v2/models/env_depot_tank_pair_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_door_frame_lod0.glb` | `ambush_loop/art/environment_v2/models/env_door_frame_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_door_frame_lod1.glb` | `ambush_loop/art/environment_v2/models/env_door_frame_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_door_leaf_lod0.glb` | `ambush_loop/art/environment_v2/models/env_door_leaf_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_door_leaf_lod1.glb` | `ambush_loop/art/environment_v2/models/env_door_leaf_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_drain_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_drain_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_drain_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_drain_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_fence_section_lod0.glb` | `ambush_loop/art/environment_v2/models/env_fence_section_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_fence_section_lod1.glb` | `ambush_loop/art/environment_v2/models/env_fence_section_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_gate_leaf_lod0.glb` | `ambush_loop/art/environment_v2/models/env_gate_leaf_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_gate_leaf_lod1.glb` | `ambush_loop/art/environment_v2/models/env_gate_leaf_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_cobble_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_ground_cobble_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_cobble_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_ground_cobble_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_concrete_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_ground_concrete_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_concrete_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_ground_concrete_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_earth_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_ground_earth_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_earth_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_ground_earth_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_gravel_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_ground_gravel_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_gravel_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_ground_gravel_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_steel_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_ground_steel_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_ground_steel_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_ground_steel_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_gun_case_lod0.glb` | `ambush_loop/art/environment_v2/models/env_gun_case_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_gun_case_lod1.glb` | `ambush_loop/art/environment_v2/models/env_gun_case_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_handcart_lod0.glb` | `ambush_loop/art/environment_v2/models/env_handcart_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_handcart_lod1.glb` | `ambush_loop/art/environment_v2/models/env_handcart_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_jerry_can_lod0.glb` | `ambush_loop/art/environment_v2/models/env_jerry_can_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_jerry_can_lod1.glb` | `ambush_loop/art/environment_v2/models/env_jerry_can_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_loading_frame_lod0.glb` | `ambush_loop/art/environment_v2/models/env_loading_frame_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_loading_frame_lod1.glb` | `ambush_loop/art/environment_v2/models/env_loading_frame_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_loading_leaf_lod0.glb` | `ambush_loop/art/environment_v2/models/env_loading_leaf_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_loading_leaf_lod1.glb` | `ambush_loop/art/environment_v2/models/env_loading_leaf_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_low_wall_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_low_wall_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_low_wall_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_low_wall_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_pipe_elbow_lod0.glb` | `ambush_loop/art/environment_v2/models/env_pipe_elbow_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_pipe_elbow_lod1.glb` | `ambush_loop/art/environment_v2/models/env_pipe_elbow_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_pump_skid_lod0.glb` | `ambush_loop/art/environment_v2/models/env_pump_skid_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_pump_skid_lod1.glb` | `ambush_loop/art/environment_v2/models/env_pump_skid_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_radio_antenna_lod0.glb` | `ambush_loop/art/environment_v2/models/env_radio_antenna_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_radio_antenna_lod1.glb` | `ambush_loop/art/environment_v2/models/env_radio_antenna_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_rail_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_rail_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_rail_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_rail_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_rations_crate_lod0.glb` | `ambush_loop/art/environment_v2/models/env_rations_crate_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_rations_crate_lod1.glb` | `ambush_loop/art/environment_v2/models/env_rations_crate_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_roof_flat_4m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_roof_flat_4m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_roof_flat_4m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_roof_flat_4m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_roof_gable_4m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_roof_gable_4m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_roof_gable_4m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_roof_gable_4m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_seam_debris_lod0.glb` | `ambush_loop/art/environment_v2/models/env_seam_debris_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_seam_debris_lod1.glb` | `ambush_loop/art/environment_v2/models/env_seam_debris_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_signal_mast_lod0.glb` | `ambush_loop/art/environment_v2/models/env_signal_mast_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_signal_mast_lod1.glb` | `ambush_loop/art/environment_v2/models/env_signal_mast_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_spare_tire_lod0.glb` | `ambush_loop/art/environment_v2/models/env_spare_tire_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_spare_tire_lod1.glb` | `ambush_loop/art/environment_v2/models/env_spare_tire_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_brick_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_wall_brick_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_brick_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_wall_brick_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_corner_lod0.glb` | `ambush_loop/art/environment_v2/models/env_wall_corner_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_corner_lod1.glb` | `ambush_loop/art/environment_v2/models/env_wall_corner_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_lamp_lod0.glb` | `ambush_loop/art/environment_v2/models/env_wall_lamp_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_lamp_lod1.glb` | `ambush_loop/art/environment_v2/models/env_wall_lamp_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_plaster_2m_lod0.glb` | `ambush_loop/art/environment_v2/models/env_wall_plaster_2m_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wall_plaster_2m_lod1.glb` | `ambush_loop/art/environment_v2/models/env_wall_plaster_2m_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_warehouse_gantry_lod0.glb` | `ambush_loop/art/environment_v2/models/env_warehouse_gantry_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_warehouse_gantry_lod1.glb` | `ambush_loop/art/environment_v2/models/env_warehouse_gantry_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_warehouse_roof_lod0.glb` | `ambush_loop/art/environment_v2/models/env_warehouse_roof_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_warehouse_roof_lod1.glb` | `ambush_loop/art/environment_v2/models/env_warehouse_roof_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_warehouse_shell_lod0.glb` | `ambush_loop/art/environment_v2/models/env_warehouse_shell_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_warehouse_shell_lod1.glb` | `ambush_loop/art/environment_v2/models/env_warehouse_shell_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_window_bay_lod0.glb` | `ambush_loop/art/environment_v2/models/env_window_bay_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_window_bay_lod1.glb` | `ambush_loop/art/environment_v2/models/env_window_bay_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wooden_barrel_lod0.glb` | `ambush_loop/art/environment_v2/models/env_wooden_barrel_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_wooden_barrel_lod1.glb` | `ambush_loop/art/environment_v2/models/env_wooden_barrel_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_yard_crate_lod0.glb` | `ambush_loop/art/environment_v2/models/env_yard_crate_lod0.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/models/env_yard_crate_lod1.glb` | `ambush_loop/art/environment_v2/models/env_yard_crate_lod1.glb` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/textures/environment_v2_albedo.png` | `ambush_loop/art/environment_v2/textures/environment_v2_albedo.png` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/textures/environment_v2_normal.png` | `ambush_loop/art/environment_v2/textures/environment_v2_normal.png` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |
| `art/environment_v2/textures/environment_v2_orm.png` | `ambush_loop/art/environment_v2/textures/environment_v2_orm.png` | `codex/cb5-migration-closeout-20261008` | `7879040c718cb6b6a05c5900cd7d0f01ce9fa21d` |

合计拷贝文件数：138（不含本文件与新建骨架）。

## T1 同仓字节拷贝（Web 导出）

> T1（Web 音效导出修复）将下列 6 个运行时 cue 以**同仓字节拷贝**复制到 `assets/audio_v2/`，来源为 `vs/g3`。原因：Web 预设的 `exclude_filter` 排除 `art/*`，运行时引用必须放在 `assets/` 下才能进包；`art/audio_v2/` 仍为许可与来源记录。

| 目标路径（ambush_vs/） | 来源路径 | 来源分支 | 来源 SHA |
| --- | --- | --- | --- |
| `assets/audio_v2/hit.wav` | `ambush_vs/art/audio_v2/hit.wav` | `vs/g3` | `0de03bc3892464578d2d9b5a8d9106522172b27b` |
| `assets/audio_v2/body_drop.wav` | `ambush_vs/art/audio_v2/body_drop.wav` | `vs/g3` | `0de03bc3892464578d2d9b5a8d9106522172b27b` |
| `assets/audio_v2/alarm.wav` | `ambush_vs/art/audio_v2/alarm.wav` | `vs/g3` | `0de03bc3892464578d2d9b5a8d9106522172b27b` |
| `assets/audio_v2/kill.wav` | `ambush_vs/art/audio_v2/kill.wav` | `vs/g3` | `0de03bc3892464578d2d9b5a8d9106522172b27b` |
| `assets/audio_v2/tension.wav` | `ambush_vs/art/audio_v2/tension.wav` | `vs/g3` | `0de03bc3892464578d2d9b5a8d9106522172b27b` |
| `assets/audio_v2/ambient_yard.wav` | `ambush_vs/art/audio_v2/ambient_yard.wav` | `vs/g3` | `0de03bc3892464578d2d9b5a8d9106522172b27b` |

本节合计：6。

## 本分支新建（非拷贝）

- `project.godot`、`export_presets.cfg`、`icon.svg`（icon 视觉同 main `ambush_loop/icon.svg`，作 VS 占位）
- `scenes/boot.tscn`、`scripts/boot.gd`
- `scripts/empty_test.gd`、`scripts/test_storage_guard.gd`
- `scripts/run_isolated_test.sh`、`scripts/run_isolated_test.ps1`
- `art/audio_v2/LICENSE`（CB5 tip 缺失，按 manifest CC0-1.0 补回）
- `PROVENANCE_VS.md`、`THIRD_PARTY_NOTICES.md`、`README.md`
- `sim/pathfinder.gd`：逻辑改编自 `ambush_loop/scripts/raid/pathfinder.gd`（main / tip `989f8ebb5bdf5f6ff2bef3542f93349c06f40117`），改为 `SimGrid` 可变宽高；非字节拷贝
- `sim/scout_sim.gd`、`scripts/w4_scout_test.gd`：PLAY-2 侦察阶段（本分支新建）
- `view/combat_fx.gd`、`scripts/w5_combat_fx_test.gd`：PLAY-3 战斗表现（本分支新建）；枪口样式参考 `ambush_loop/scripts/fx/muzzle_flash.gd`（非字节拷贝）
- 额外 SFX 使用已入库 `art/audio_v2/{hit,body_drop,alarm,kill}.wav`（见上表 CB5 拷贝）

