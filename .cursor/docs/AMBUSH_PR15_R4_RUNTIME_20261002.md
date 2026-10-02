# PR15 R4 枪族动作正式运行切片

2026-10-02。已按 A1.2 接入独立作者的十枪专用动作及上身分层，当前为技术运行验收。候选源 `194d9c41aaddbf014f05c70c14d40c09e6d8131b`、交付 `c4c21708a2e06d3a7eaefbb8ab6bfeee31f5073d`，51 GLB 原字节采用，生产源/Blender/共享 atlas 未编辑或重跑。

PR15 运行提交 `85da9ab258554a08e9afc87202fe3c4d51b497a8`；PCK 测试补片 `c04a6f547d78061e15a6c70daffbe0819a7bc0b2`；正常 HUD 捕获补片与最终源 `20cdc8ccfe887f6f64eda9fc64769294fa7de371`。正式回归在隔离工作树的固定生产源 `5ecefe0e3f2c1da119257edcfbfc796783ebfa09` 上执行，最后两个测试补片固定为 `448ecf0d5e15d693cfba56ce45eaab0a5495771b`；补片只动测试及 UID。cherry-pick 后 `git diff --exit-code 448ecf0d5e15d693cfba56ce45eaab0a5495771b 20cdc8ccfe887f6f64eda9fc64769294fa7de371 -- ambush_loop` 退出 0，整个工程树均相同。工程树 `0c0262d1c205b8deadcf910f07b13341a01d7008`。不是把未测的新运行实现归到旧源。

## 实际行为

记录格式 2 固定枪族/版本/时钟，ready→raise→aim、lower、射击脉冲和真实同枪补包使用历史字段与已发生同 attempt/wave 的事件。快速 MG 脉冲按实际记录的射速压缩，不限模拟射速。死亡、搜索、拖拽、工具、换枪及 SWEEP 取消旧枪动作；坏字段/未来事件不借活体补齐。下身 locomotion 保持，12 个上身骨采专用动作，补偿 hips 倾斜使蹲姿枪/手/眼线一致。暂停、2×、seek、LOD 使用同一显式记录时钟。

记录格式 1 的 R3 十二动作保持，21 人物原几何/20 骨 rest、bind 及 252 旧动作逐字节只读对比相同，76 原装备挂点和三 atlas 不动。六个新增后握把的枪 GLB 对应旧 R3 原文件保存在 `art/v2/replay_r3/`，旧录像不会悄悄替换几何；未知版本继续明确中性回退。

实际 main 中最后一发会立即换手枪：事件保存射击前的枪、实际射速/补包时长和音效 cue，声音也使用射击前 cue，避免 MG 最后一发播放手枪声。没有延迟伤害、改弹药或枪射程。

## 固定源实际验证

所有命令、run_id、退出码、日志哈希见 [validation.json](evidence/20261002-pr15-r4-runtime/validation.json)，均通过隔离包装器和 StorageGuard。Godot `4.7.2.stable.official.ed1daf0bf`；云端渲染 Compatibility / Mesa llvmpipe，音频 Dummy 驱动真实 AudioServer 混音。

| 入口 | 实际结果 |
| --- | --- |
| `firearm_runtime_test.gd --render` | 7681 项/十枪×三角色×三 LOD 90 配置，真实 MG42 连发、立即手枪切换、暂停及历史 seek；HUD 捕获补片后再跑 7681，退出 0 |
| `actor_visual_test.gd --render` | 52 clip 真实采样 17802，退出 0 |
| `actor_battle_test.gd --render` | 真实 yard 两波、历史角色及枪/骨姿/LOD 231，退出 0 |
| `visual_snapshot_test.gd --render` / `presentation_lifecycle_test.gd --render` | 164 / 32，退出 0 |
| `asset_library_test.gd --render` | 333 / 15 件 / 30 LOD，退出 0 |
| `presentation_contract_test.gd` | 84039，退出 0 |
| `campaign_replay_test.gd` | 六关完整原多波 10296，原终局 tick/事件数不变，退出 0 |
| `equipment_freeze_test.gd` / `replay_timeline_test.gd` | 66 / 66，退出 0 |
| `audio_runtime_test.gd --render` | 45 cue 实际 play/真实混音 405，282624 捕获帧，全部非零且有限，退出 0 |
| 空物理工程 `asset_pack_test.gd` | 1380，十枪 profile、52 clip、六旧枪几何与姿态/枪口、45 音频资源，退出 0 |

PCK `/tmp/pr15-r4-runtime.pck`：21,503,140 bytes，SHA256 `610a641d4d1e5275d03c177298f89578ee7abcec743bacaac57621653878201f`。固定 export 源 448ecf0 与 PR15 最终源工程树完全相同；这是技术资源包，最终 APK 另做。编辑器/导出后的 45 WAV import 输入已恢复候选原字节。

已实际看四张捕获：实际 MG 射击、即时手枪切换、历史 MG、历史近景，均在 [证据目录](evidence/20261002-pr15-r4-runtime/validation.json) 中列出 SHA/源及 viewed。角色与记录枪身份可见，建筑仍灰盒，HUD 重复/遮挡待 A2 整体施工。开发失败及修复日志保留，不删除负例：蹲姿枪轴倾斜 5 fail；fixture 枚举笔误；generic MG 点超出真实 MG42 射程。只修表现/测试布置，没有修改射程或玩法数值。

## 所有权、未验与下一步

主作者继续独占 main/presenter/ActorPose/ViewState/replay、运行台账/loader、共享测试与 PR15。资产作者交付原字节及候选接口；没有整体合并其分支。R5 源 `29749157c5db064bfea626c3ed9d75d9a1791ece` / 证据 `ebedb829e3263abbeb6dd266905f24a3869fa281` 已读交接，接入事件 clock/mask/cancel 及刀/投雷/decoy/尸体动作另验。环境 `50ef7883285c4419dbd8339b935433dc6bb5e3f8` / `9c06f04cf7795faf69d9d69d0f853f30ccf80838` 最小 85 文件和 11 冻结依赖已只读核对，下一片接真实六关 loader/材质/地表/建筑与历史布局。

连续艺术品质、枪械机械细节、耳听 0/45 和 0/6、Windows 包装器执行、完整环境/HUD/FX、A3 云端预算、最终 APK 均未验。最新完整 smoke 仍为 7d34867 固定副本，不归到本源。制作及全部云端验证后再设备阶段；不 merge/不生产发布/不混高度玩法。GPT PLAN/REVIEW unavailable。
