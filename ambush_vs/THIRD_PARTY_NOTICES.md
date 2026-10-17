# Ambush VS — 第三方与素材许可台账（初稿）

本台账覆盖 `ambush_vs/art/` 与 `ambush_vs/ui/fonts/` 下入库素材。引入提交见分支 `vs/core`；逐文件路径与来源 SHA 见 `PROVENANCE_VS.md`。

| 路径 / 包 | 许可 | 来源摘要 | 状态 |
| --- | --- | --- | --- |
| `ui/fonts/NotoSansCJKsc-Regular.woff2`、`ui/fonts/OFL.txt` | SIL Open Font License 1.1 | Noto CJK（Debian `NotoSansCJK-Regular.ttc` face 2 → FontTools 无损重打包为 woff2）；自 CB5 tip `7879040c…` 拷贝 | 已入库；全文见 `ui/fonts/OFL.txt` |
| `ui/fonts/DejaVuSans.ttf`、`ui/fonts/DejaVu-LICENSE.txt` | Bitstream Vera + DejaVu 变更（见许可证文件） | DejaVu Sans 2.37；自 CB5 tip 拷贝 | 已入库；全文见 `ui/fonts/DejaVu-LICENSE.txt` |
| `ui/fonts/README.md`、`ui/fonts/web_ui_font.tres` | 项目说明 / Godot 资源 | 随字体包自 CB5 tip 拷贝 | 已入库 |
| `art/audio_v2/*.wav`、`art/audio_v2/manifest.json` | CC0-1.0（生成音频）；manifest 注明脚本侧 MIT（脚本未拷入 VS） | 程序化合成，无采样录音；自 CB5 tip 拷贝 | 已入库；**`LICENSE` 在 CB5 tip 缺失，已于 VS 补回 `art/audio_v2/LICENSE`（CC0 1.0 Universal 全文）** |
| `art/environment_v2/**`（GLB、贴图、materials、manifest） | 本项目原创程序化几何与材质；无外部付费依赖（见 manifest `usage`） | Blender 管线；自 CB5 tip 拷贝 | 已入库；非第三方，记入台账便于 CI 路径覆盖 |

## 引擎

| 组件 | 许可 | 说明 |
| --- | --- | --- |
| Godot Engine 4.7.2 | MIT | 开发/导出依赖；不入库引擎二进制 |

## 未纳入本切片

- `ambush_loop/art/v2` 角色/道具 GLB、旧 2D look、玩法脚本：未拷贝（许可或用途待 VS 灰盒阶段再清点）。
- 发行签名密钥：禁止入库（授权 A2）。

## 验收约定（后续 CI）

`art/` 下每个文件应能在本台账或 `PROVENANCE_VS.md` 找到对应记录。本文件为 W1 初稿，随素材增减更新。
