# 院子纸面关卡 v1.6（2026-10-17）

| 字段 | 值 |
|------|-----|
| 状态 | **纸面 v1.6（P0-1 切片 4：ALERT-global 可胜残局）** |
| 前版 | [yard_paper_v1_5.md](yard_paper_v1_5.md) |

## 相对 v1.5

| 项 | 变化 | 原因 |
|----|------|------|
| `road_tail` 格 | (10–12,**15**) `gate_n` | 离开出生格 (11,14)，避免警报后进场即脱出 |
| 全图警报 | 未入场敌人改走 `alarm_route` 战斗进场（ADR-TRIGGER §3.4） | D.3：每档警报 A/B 至少一案可胜 |
| 金标 | hash **未改**；t0 520/560 | 理想 A/B 不经 alarm 路径 |
| `yard.json` | version **7** | 出口格调整 |

## 验收

- BASE A/B 胜；ALERT-global **wins≥1**（实测 A/B 皆胜）；T-A−2 仍成立
