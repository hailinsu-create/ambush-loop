# PR15 SWEEP 动作时钟正式补片

2026-10-02。dot 对 `a3e6e2` 的两份独立反例报告：SWEEP sim tick 停在1056，命令表现时钟0→0.8，近期 death 仍采0.016667，存活 scout 移动仍 fire。按当前切片边界先修，环境组装暂缓。

## 复现与修复

当前 R4 已取消格式2的 SWEEP fire；在 `e0f50dda2f12f8ae7cb8335dd91b98ced8d421ae` 实际首波、合法 scout 四格移动与近期 death 的正确反例，22项/11 fail、实际退出1。scout从(912,528)到(965.6662,528)，实际 action=walk；death、菜单/后台命令冻结、旧R3格式1的残留 fire/death 与未知事件 clock 仍失败。反例脚本/哈希/实际日志已保存在 [证据](evidence/20261002-pr15-command-pose/validation.json)。早期19/8包含首路径点零位移的测试误判，另一次21/1为纯旧格式测试拷贝了已死角色；都已修正并保留，不能拿这些数字当全部真实故障。

运行源码 `3ba263c4edfc41dd4a498bec100b1ecc2d14b215`：

- command/result 表现时钟独立推进，不改 sim tick、BattleLog 波偏移、event identity 或战斗数值。SCOUT/SWEEP 暂停菜单及应用离开时停止命令动作/时钟，返回继续；ALERT 保持原 SimClock 暂停和2×语义，REPLAY不推进当前时钟。
- 可选 `event_pose_schema=1` / `event_pose_clock_s` 将 battle 事件年龄锚接到 command 时钟，记录为纯数据。历史只读复制此字段，simulation 区段可加已记录采样间隔，command 区段不借活体/墙钟补时长；非数字/非有限/未知格式被拒绝。
- 已死角色以该事件年龄继续 fall；格式1与格式2的 command 阶段都取消过去 fire。旧 command 记录缺少跨域锚点则以完整 death 终态1.2s显示，避免站尸冻结，不编造旧中间时间。

截图焦点补片 `e52bf5c948d47730307dce6aa347f432407b3353` 与实际正常记录/终局回放补片 `c381258f9a62cd2ac4046704a47eccf1e1413c57` 只改测试。`git diff --exit-code 3ba263c4edfc41dd4a498bec100b1ecc2d14b215 c381258f9a62cd2ac4046704a47eccf1e1413c57 -- ambush_loop ':!ambush_loop/scripts/command_pose_clock_test.gd'` 退出0，运行字节均相同。

## 固定源实际结果

dot独立复验回报（2026-10-02，源98075ca7d6f0636f0aef5008c43ea785c1990049）：原dead/walk退出0，simtick1056保持、death0.016667→0.816667且20bone变、移动walk；独立68/0覆盖pause/background叠加、ALERT1×/2×、正常双波终局record、liveclock/weapon污染、倒退跨波seek。独立判定SWEEPclock P2闭合，无新运行P1/P2。仓库29/0复跑，首次29/2为PNG目录缺失且保留、不计通过。本段为父端报告，未冒称主作者重跑；连续SWEEP时间轴、FAILED/abort终局、当前全smoke/设备/耳听仍未验，R4全回归未独立重跑。

完整命令/cwd/run_id/退出码/哈希在 [validation.json](evidence/20261002-pr15-command-pose/validation.json)。Godot 4.7.2 `ed1daf0bf`，所有入口走独立XDG/StorageGuard，均实际退出0：

| 入口 | 结果 |
| --- | --- |
| `command_pose_clock_test.gd --render` | 3ba源24项；e52焦点补片24项；c381正常app记录补片29项（22原行为＋2实际捕获＋5正常双波/终局记录/回放），0 fail |
| `firearm_runtime_test.gd --render` | 7681 / 90 配置 |
| `actor_battle_test.gd --render` | 实际yard两波/历史角色231 |
| `presentation_contract_test.gd` | 84039 |
| `campaign_replay_test.gd` | 六关13个原波、三时步变体10296；原终局 tick/事件数逐关不变 |
| `visual_snapshot_test.gd --render` / `presentation_lifecycle_test.gd --render` | 164 / 32 |
| `equipment_freeze_test.gd` / `replay_timeline_test.gd` | 66 / 66 |
| `audio_runtime_test.gd --render` | 45 cue实际play/混音405；不是耳听 |
| 空物理工程 `asset_pack_test.gd` | 1476，包含 R4/旧R3/环境/音频实际资源 |

29项最终测试完成真实yard第二波与最后SWEEP，在不加_sim_tick的精确0.8s命令步进后，执行正常`_on_sweep_commit`撤离，真实终局snapshot保存command clock/age。正常`_on_replay_pressed`回放全部20骨/根/采样时间与终局记录一致；污染当前两个timer +100s仍保持历史骨姿与记录。另检验同一复制 command 记录前后seek，暂停/恢复/后台，以及未知事件时钟。这是实际main记录路径和逐记录姿态验证；尚未把SWEEP中间时长全部展开成连续UI时间轴。

技术PCK固定e52源：24,488,444 bytes，SHA256 `37a400617a819bd35456f0d62c98b004296d0b56bd07b51975282d66906b3959`，空目录1476退出0，不是最终APK。导出后的45音频import已恢复原输入。

实际两张目标捕获已看，kill事件原position为空，测试改用该记录中的enemy位置来聚焦；灰盒墙仍部分遮住倒地目标，数值20骨进度另验，不称清晰成品画面。失败开发日志、导入准备错误和反例保留。dot对本新P2的独立关闭尚待复验；不代其宣布关闭。

## 下一步与边界

环境85原文件/11依赖与loader已在a54d538/e0f50dd技术验过，实际40×22六关组装继续；遮挡应包括loot/死亡位置，仍不得改逻辑占格/路线。接R5 `29749157c5db064bfea626c3ed9d75d9a1791ece` / `ebedb829e3263abbeb6dd266905f24a3869fa281` 的事件clock/mask/cancel与刀/投雷/decoy/尸体；生产源/atlas/GLB由独立作者拥有，主作者只接收原字节与运行接口。完整command历史区段、HUD/FX、A3预算、六关成品、可追溯APK继续。最新全smoke仍7d34867固定副本，不归到本新源；耳听0/45、0/6，设备后置。保持Draft、不merge/生产发布/高度玩法。GPT PLAN/REVIEW unavailable。
