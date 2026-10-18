# VS-PLAY4：等待阶段重瞄与节奏（差距报告 fix #4）

- 日期：2026-10-17
- 分支：`vs/g3`（Pages；**不合并**）
- 状态：**已实现 / 本机隔离测试已绿**
- 来源：差距报告 fix #4（wait）

## 目标

等待阶段可玩：拖拽队员重瞄（接 `NightSim.request_operator_facing`，1 s/45°，转向指示与禁射）；接近敌军脚步音量随距离；夜间环境床；敌人进锥心跳/tension；院子首触约 20–30 s。

## 范围

- **做**：greybox WAIT 拖拽 → `request_operator_facing`；转向环；`g2_sfx_player` 脚步/ambient_yard/tension；`yard.json` `enter_t_s` +12 s；W2 转向测试；金标随节奏更新。
- **不做**：改 ADR 转向公式；合并 `vs/g2`；新关卡。

## 金标变更理由（必须写进 commit）

院子纸面原 t0_A=14 s（tick 280）/ t0_B=16 s（tick 320），首触偏短。PLAY-4 仅把 `yard.json` 各 spawn `enter_t_s` **+12 s**（E1 0→12 …），几何与行军速度不变 → **t0_A=26 s / tick 520**，**t0_B=28 s / tick 560**，落入规划 D7「进视野→杀伤区约 20–30 s」。因此重写 `data/golden/hashes.json` 并更新硬编码 t0 断言。

## 验收

| 套件 | 结果 |
| --- | --- |
| empty | 0 exit |
| W2 | **73**（含 wait-turn 12 断言；金标 t0 520/560） |
| W3 | **57** |
| W4 | **27** |
| W5 | **19** |
| 截图 | `/opt/cursor/artifacts/greybox_reaim.png`（等待中「转向」指示） |
| Pages | push `vs/g3` → deploy-greybox-pages |

## 非目标

- 第七夜 / FOW / 联网
- 改武器或杀伤区几何
