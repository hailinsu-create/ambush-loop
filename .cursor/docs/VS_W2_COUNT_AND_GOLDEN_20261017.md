# W2 断言数 61→73 与金标说明（2026-10-17）

分支：`vs/g3`。供 PLAY-5/PLAY-6 交接；不另开 ADR。

## 61 → 73 从何而来

PLAY-3 文档记 W2 **61**（当时无 wait-turn 用例）。PLAY-4 在 `w2_sim_test.gd` 增加 `_test_wait_turn_blocks_fire`：

| 断言主题 | 约增 |
| --- | --- |
| 90° 转向 → 40 tick、`can_fire` 关闭、朝向保持 | 6 |
| 转向结束后恢复开火 | 3 |
| 45° 再转 + `_step_fire` 禁射/恢复 | 3 |
| **合计** | **+12** → **73** |

无删旧用例；只加 PLAY-4 契约。PLAY-5 未再改 W2 计数（仍 73）。

## 金标是否变过

| 提交窗口 | `hashes.json` | 原因 |
| --- | --- | --- |
| PLAY-3 及以前 | t0 280/320；旧 hash | 纸面 v1.2 默认 spawn |
| **PLAY-4** `c5bcd63` | **t0 520/560**；hash 重写 | 仅 `yard.json` `enter_t_s` **+12 s**（D7 20–30 s 首触）；几何/行军速度/计划不变 |
| PLAY-5 `82aa445` | **未改**金标 | 复盘卡只读日志，不进 `NightSim` |
| **PLAY-6**（本切片） | **已改** hash；t0 仍 520/560 | 起爆后掩体/还击/逃跑、队员 HP/弹药、按 RPM 扣弹进入 `NightSim` 日志 → 事件集变化。新 hash 见 `ambush_vs/data/golden/hashes.json`；理由见 [PLAY-6](VS_PLAY6_ENEMY_REACT_20261017.md) 与下方 DECISIONS |

PLAY-4 金标理由原文：`.cursor/docs/VS_PLAY4_WAIT_UX_20261017.md` §金标变更理由。

## DECISIONS（PLAY-6 金标）

1. **改 hash，不改 t0**：院子 `enter_t_s` 与 PLAY-4 节奏保留；仅战斗解析改变日志。
2. **弹药按 RPM 脉冲消耗**：旧实现每 tick 扣 1 发会在有限弹匣下误杀方案 B；改为 `fire_accum` 满 1.0 扣一发，金标随之重算。
3. **方案 A 允许非 S**：还击负伤/清场变慢后评级 A 仍算通过；不再要求无伤 S。
4. **还击软顶**：每名敌人最多造成 1 次队员命中，避免方案 B 被压成不可胜。
