# VS-PLAY6：敌人反应 / 负伤 / 弹药（差距报告 fix #6）

- 日期：2026-10-17
- 分支：`vs/g3`（Pages；**不合并**）
- 状态：**已实现 / 本机隔离测试已绿**
- 提交：`47ce7ea`（PLAY-6 + 截图捕获加固；金标 hash 在 `c17b6b3`）
- 来源：差距报告 fix #6；ADR-TRIGGER §3.4 / DEV_PLAN W5

## 目标

起爆后存活敌人寻最近掩体（N 格内）、对可见队员还击（精度随距离/掩体）、小队强度低于阈值则向地图边缘逃跑；逃脱计泄漏并抬高 `next_night_alert`。队员有 HP（负伤=射速/精度惩罚）；弹药按搜集套件有限并显示在队员卡；复盘原因覆盖压制/逃脱（如「3号被压制，左翼一人逃脱」）。保持确定性；方案 A 可胜但不再轻松 S；方案 B 谨慎可胜。

## 范围

- **做**：`NightSim` 掩体/还击/逃跑/HP/弹药；复盘原因；队员卡弹药/负伤；W7 测试；金标重算；截图 cover_fire / wounded / leak_review。
- **不做**：联网；FOW；改院子几何；合并 `vs/g2`。
- **附带小修**：复盘卡实心暗底（~92% 不透明）+ 细边框，避免地图透字。

## 金标变更理由（必须）

PLAY-6 把起爆后战斗写进 `NightSim` 日志（`enemy_seek_cover` / `enemy_in_cover` / `enemy_fire` / `op_wounded` / `enemy_flee` / `ammo_empty` 等），并改为按 RPM 脉冲消耗弹药。事件集与时序变化 → **必须重写** `data/golden/hashes.json`。t0 仍为 **520 / 560**（PLAY-4 节奏未动）。详见 [W2 断言数与金标](VS_W2_COUNT_AND_GOLDEN_20261017.md)。

## 验收门槛

| 项 | 期望 |
| --- | --- |
| W2 | 绿；金标 t0 520/560；hash 已更新并文档说明 |
| W3–W6 | 绿（W6 评级允许 A 非 S） |
| W7 | cover / return-fire wound / flee+leak / ammo_empty / A 非完美 / B 可胜 / 确定性 |
| 截图 | `greybox_cover_fire.png`、`greybox_wounded.png`、`greybox_leak_review.png` |
| Pages | push `vs/g3` |

## 非目标

- 第七夜 / FOW / 联网
- 改武器扇形或院子纸面几何
