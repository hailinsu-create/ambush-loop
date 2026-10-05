# M2-I0 院子 3D 素材来源记录

## 固定来源

- 协作者来源分支：`origin/feat/rotatable-yard-a0-20261002`
- 本次读取的来源提交：`eb50a736da09038bda49d96a3e15c33389a83317`
- 来源资产清单：该提交中的 `ambush_loop/art/environment_v2/manifest.json`
- 清单记录的资产生成提交：`50ef7883285c4419dbd8339b935433dc6bb5e3f8`
- 清单记录的交付提交：`9c06f04cf7795faf69d9d69d0f853f30ccf80838`
- 清单称环境几何与材质字段由项目自有 Blender 程序生成（Blender 4.3.2），无外部模型依赖。
- 清单使用说明为“供 Ambush Loop 及项目贡献者使用”，并明确“没有单独的公开再许可声明”。因此本记录只确认素材来源和来源分支内容，不额外推断更广泛的版权/再授权范围；向项目外再分发前仍需确认权利。

## 本切片实际引用的来源文件

以下 Git blob ID 已逐项与固定来源提交比较，工作区字节对应的 Git 对象均与来源相同：

| 文件 | 来源 Git blob |
| --- | --- |
| `models/env_ground_concrete_2m_lod0.glb` | `601bde4e238e0985c1feeffbba0bba3b9e9c6539` |
| `models/env_warehouse_shell_lod0.glb` | `73d8107b5190e2b308fcc89e27f2fae99a334712` |
| `models/env_yard_crate_lod0.glb` | `1f73d72fb4b02a551bef7667cc32254fe74eb7bd` |
| `models/env_ammo_can_lod0.glb` | `a097e3ce330683896db20d27d1ab0808b32a2e4a` |
| `materials/environment_v2_atlas.tres` | `10b8ae4c6de326aba64559bac520b38f5c277d5f` |
| `textures/environment_v2_albedo.png` | `16482fd92d4c43c03b5b473d0449e0ca89b01f2b` |
| `textures/environment_v2_normal.png` | `e3fa717fa112fe01dd232bdc5cae9fc995c51515` |
| `textures/environment_v2_orm.png` | `5b87b34d2d5bbb0d4ff5db222dbbc99b0923710b` |

本地 `res://` 引用均保留在 `ambush_loop/art/environment_v2/`；未复制 PR #15 的其他关卡资产、制作源、证据包或运行框架。本记录不代表 PR #15 已合并，也不代表其他素材已获本地复验。

## 使用边界

这些模型、贴图和材质仅供 I0 院子显示。它们没有物理、寻路、战斗视线或高度权威；逻辑格、高度层、坡道、拾取身份与命令仍来自本地玩法状态。显示资源缺失时允许退回简单几何，不应阻塞模拟。

I0 开发入口为 `ambush_loop/scenes/presentation/yard_i0_3d.tscn`；项目默认主场景未改。自动化显示证据见 `.cursor/docs/evidence/20261005-m2-i0-yard-preview.png`。
