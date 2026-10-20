# 仓道 P1 结果（T9 第 1 步，2026-10-20）

| 字段 | 值 |
|------|-----|
| 范围 | **只做 sim 层 + 数据 + 金标 + 测试/文档**；控制器、地图渲染、简报、`?level=` 场景验收留到下一轮 |
| 关卡 | `data/levels/warehouse.json`，id `warehouse`，version 1，网格 24×16 |
| 方案 | `plan_warehouse_a.json`（宽扇 MG42）、`plan_warehouse_b.json`（Kar98k + 雷/手雷） |
| 金标 | `data/golden/hashes_warehouse.json`，t0 **520 / 540** |
| 测试 | `w2_warehouse_counterex_test.gd` 25/0；`w3_level_contract_test.gd` 65/0（yard 部分仍 40） |
| 运行 | Godot 4.7.2，先 `--headless --path ambush_vs --import`（exit 0），再走 `run_isolated_test.sh` |

## 两案（默认硬核 assist=false）

| 方案 | outcome | standard | t0 | 逃脱 | 清场 s | 负伤 | 阵亡 | 谁在打 |
|---|---|---|---|---|---|---|---|---|
| A 宽扇压制 | **win** | **true** | 520 | 0 | 0.75 | 1（MP40） | 0 | MG42 清 E1–E4；MP40 清 F1/F2 |
| B 窄扇点杀+封后 | **win** | **true** | 540 | 0 | 2.15 | 0 | 0 | 地雷 E1/F1；手雷 E2/E3/F2；Kar98k E4 |

两案都按“等敌人入伏”设计：A 手动 26s，B 由近门地雷在 27s 起爆。B 的 Kar98k 只负责最后一个漏网者，雷/手雷负责封后。

## 命名反例（两档还击 ON/OFF）

OFF = 默认硬核（无软顶）；ON = 还击辅助。受伤 = `wounded + dead_ops`。`holds` 为 D.3（逃脱≥1 / 清场 +50% / 受伤 +50%，相对同案 BASE）。

| 用例 | OFF outcome | OFF 逃脱 | OFF 清场s | OFF 受伤 | OFF 阵亡 | ON outcome | ON 逃脱 | ON 清场s | ON 受伤 | ON 阵亡 | OFF holds |
|---|---|---|---|---|---|---|---|---|---|---|---|
| BASE-A | win | 0 | 0.75 | 1 | 0 | win | 0 | 0.75 | 1 | 0 | — |
| BASE-B | win | 0 | 2.15 | 0 | 0 | win | 0 | 2.15 | 0 | 0 | — |
| **F-WA30** | **lose** | 4 | 0.75 | 2 | 0 | lose | 4 | 0.75 | 2 | 0 | true |
| **T-WA-4** | **lose** | 1 | 4.35 | 2 | 1 | lose | 1 | 2.65 | 1 | 0 | true |
| **W-WA-MG→Kar** | **lose** | 4 | 1.60 | 3 | 1 | **win** | 0 | 19.65 | 2 | 0 | true |
| **S-WA-no-dock** | **lose** | 4 | 0.75 | 1 | 0 | lose | 4 | 0.75 | 1 | 0 | true |

严格判负组（`STRICT_LOSE_IDS`）：`F-WA30`、`W-WA-MG→Kar`。两例在 OFF 都 `lose`，且 `standard_ambush=false`，失败证据为逃脱/阵亡。其余两个命名反例（`T-WA-4`、`S-WA-no-dock`）在 OFF 也 lose，同时满足 D.3（逃脱≥1）。**四个命名反例全部 lose，超过“至少 2 个”的要求**；没有使用过渡门。

补充：`W-WA-MG→Kar` 在 ON 档会变成 win（19.65s），说明这条换枪代价依赖硬核还击；测试只对 OFF 严格断言，ON 只打印对照。

## 金标

| plan | hash | outcome | t0 | standard | 清场 |
|---|---|---|---|---|---|
| A | `0f69df6f3796e7f39234d90babddc657a538ebf01ba5831c340092301ede022d` | win | 520 | true | 0.75s |
| B | `1662e6342d3b0037b15d89f326b811f2c4283e9a4284ca09461fedd74680a3d4` | win | 540 | true | 2.15s |

同一方案连跑两次哈希一致，且与 `hashes_warehouse.json` 一致（`w3_level_contract_test.gd`）。

## 对 `night_sim.gd` 的改动

只做了一处“关卡数据驱动”的最小泛化：起爆时 yard 专属的剥队几何改为读取可选 `level.peel`：

- `flank_min_x`（缺省 17）、`flank_lane_y`（缺省 8）、`rear_min_y`（缺省 12）；
- 缺省值与原硬编码完全一致；warehouse 显式写 `{"flank_min_x":999,"rear_min_y":999}` 关闭该几何；
- 没有改任何规则、阈值、tick 顺序或事件字段。

**yard 金标不变证据**：改后 `w2_sim_test.gd` 107/0（金标全过）、`w2_counterex_test.gd` 49/0；直接跑 yard 两案仍为：

- A `42eae734e82f29e7be5e1a2ff0afeaacd63ead16c18c624f4d0548b0961f201e`，t0 520，win/standard；
- B `78285cce74d846569dca3aceba3c5ec4a7536b1ccf41311aa5042cb80f79fa84`，t0 560，win/standard。

`yard.json`、yard fixtures、`hashes.json`、yard 断言值均未修改。

## 全量测试（全部 exit 0）

| 套件 | SUMMARY | 基线 |
|---|---|---|
| empty | exit 0 | — |
| W2 sim | 107/0 | 107 |
| counterex | 49/0 | 49 |
| aim | 142/0 | 142 |
| W3 greybox | 85/0 | 85 |
| **W3 level contract** | **65/0** | yard 部分仍 40；warehouse +25 |
| **W2 warehouse counterex** | **25/0** | 新 |
| W4 scout | 27/0 | 27 |
| W4 scout carry | 39/0 | 39 |
| W5 combat FX | 22/0 | 22 |
| W5b ladder | 39/0 | 39 |
| W6 review | 25/0 | 25 |
| W7 combat | 30/0 | 30 |
| W8 controls | 442/0 | 442 |
| W8 briefing blacklist | 35/0 | 35 |
| W9 playtest | 80/0 | 80 |

## 遗留

- 控制器/灰盒地图仍按 yard 的关卡加载与坐标预设工作：`greybox_controller.gd` 的预设写死 `plan_a/plan_b`、headless 侦察坐标、`frame_yard()` 等；`review_builder` 的 yard 理想 t0 520/560 也还没按关读。下一轮让控制器支持非 yard 关卡（地图渲染、货台/近门落位、简报、`AMBUSH_LEVEL=warehouse` 场景断言）。
- warehouse 还没有 720p 截图/真机证据；本轮只验证 sim 与数据/测试。
- 未提交、未推送（按本轮要求只改工作区）。
