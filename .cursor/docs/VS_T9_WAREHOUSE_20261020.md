# VS T9 仓道第二关（sim 层）2026-10-20

| 字段 | 值 |
|------|-----|
| 状态 | **已实现，本机隔离 headless 测试已验证**；仅工作区，**未提交/未推送** |
| 分支 | `vs/p1-level2`（基于 T7 `vs/p1-yard-v17`，已合入 T8 `vs/p1-level-framework`） |
| 范围 | 只做 sim 层 + 数据 + 金标 + 测试/文档；控制器/地图支持非 yard 关卡留到下一轮 |
| 纸面 | [`ambush_vs/docs/warehouse_paper_v1.md`](../../ambush_vs/docs/warehouse_paper_v1.md) |
| 结果 | [`ambush_vs/docs/WAREHOUSE_P1_RESULTS_20261020.md`](../../ambush_vs/docs/WAREHOUSE_P1_RESULTS_20261020.md) |

## 改动

- 新关 `ambush_vs/data/levels/warehouse.json`（id `warehouse`，version 1，24×16）：长廊、货台高点 `(3..5,10..11)` + 东梯/北梯 access、近门盲区（货堆 `18,10..12` + 实体门框 `19,9`）、东/西/南三个出口、E1–E4 纵队 10/13/16/19s、F1/F2 侧翼 19/20s。
- 两套 fixture：`plan_warehouse_a.json`（MG42 宽扇 + MP40 补盲，t0 520）、`plan_warehouse_b.json`（Kar98k 窄扇 + 地雷/手雷封后，t0 540）。默认硬核档均 `win` + `standard_ambush`。
- 金标 `data/golden/hashes_warehouse.json`（A `0f69df6f…`，B `1662e634…`，t0 520/540）。
- `sim/levels.gd` 注册 `warehouse`（path / golden / fixtures）。
- `sim/night_sim.gd` 最小泛化：起爆剥队几何读取可选 `level.peel`（缺省 17/8/12 = yard 原值）；warehouse 显式关闭。事件流/规则/阈值未改，yard 金标未变。
- `w3_level_contract_test.gd`：t0 改从各关金标读；命名反例改 per-level 表。yard 部分断言仍 40，warehouse +25，总计 65。
- 新 `w2_warehouse_counterex_test.gd` 25/0，打印两档对照；加入 `run_isolated_test.sh/.ps1` allowlist。
- 新纸面/结果文档；`schema/level.json` 增加可选 `peel` 字段说明。

## 验证

先 `--headless --path ambush_vs --import`（exit 0），再跑隔离套件；全部 exit 0：

| 套件 | SUMMARY |
|---|---|
| empty | 0 |
| W2 / counterex / aim | 107 / 49 / 142 |
| W3 greybox | 85 |
| W3 level contract | 65（yard 40 + warehouse 25） |
| W2 warehouse counterex | 25 |
| W4 / carry | 27 / 39 |
| W5 / W5b | 22 / 39 |
| W6 / W7 | 25 / 30 |
| W8 / blacklist / W9 | 442 / 35 / 80 |

yard 金标直接对照：A `42eae734…` t0 520；B `78285cce…` t0 560（与 T7 一致）。

## 遗留（下一轮）

- 控制器 / 灰盒地图按关卡数据工作：预设 fixture、headless 侦察坐标、`frame_yard()`、`review_builder` 理想 t0、`aim_snap` 地标等仍是 yard 硬编码（T8 文档已列清单）。
- warehouse 的 720p 截图/真机未验证。
- 本文件与相关代码仅本地保存，未 commit/push，未同步 GitHub。
