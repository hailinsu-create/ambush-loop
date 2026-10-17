# VS-W4a / PLAY-2：侦察搜集阶段 v0

- 日期：2026-10-17
- 分支：`vs/g3`（Pages 重部署；**不合并** `vs/g2`）
- 状态：**已实现 / 本机隔离测试已绿**
- 来源：差距报告 fix #2；接 PLAY-1 空白布阵

## 目标

夜色起手在南门入场：行走开箱、接近揭示隐蔽补给（MG42），再「开始布阵」进入 PLAY-1，套件带入布阵卡。

## 范围

- **做**：`ScoutSim`（独立于 `NightSim`）、SimGrid A*（移植 main `RaidPathfinder` 思路）、灰盒 SCOUT UI、夜时 90 s、暴露升警、W4 测试。
- **不做**：改埋伏金标 / `NightSim.begin_wait` 规则；弹药消耗；攀爬代价进 scout（后续）；G3 美术。

## 契约

1. 开局 `UiPhase.SCOUT`；队员在 `squad_insertion`。
2. 点选→点格 A* 行走（0.5 格/s）；站上补给自动开箱（2 s）。
3. `visibility:hidden` 仅在 Chebyshev ≤2 揭示；开箱后 MG42 进共享套件，布阵卡才可装备。
4. 夜时预算 90 s；到期自动 `finish_scout("budget")` → 布阵。
5. 行走被岗哨/巡逻看见按 ADR-ALERT 阈值升警（仅 scout 时钟；埋伏仍从安静开始）。
6. 「开始布阵」把手中套件交给 PLAY-1。

## 验收

| 套件 | 结果 |
| --- | --- |
| W2 | 61 passed（金标不变） |
| W3 | 57 passed |
| W4 scout | 27 passed（开箱产量、范围揭示、MG42 锁定、预算到期、金标不受影响） |

截图：`scout_start` / `crate_opened` / `hidden_found` / `setup_mg42`。
