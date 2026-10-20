# 院子纸面关卡 v1.7（2026-10-20）

| 字段 | 值 |
|------|-----|
| 状态 | **纸面 v1.7（T7：4 个关键反例判负 + 西侧/手指格禁止落位）**；本机隔离 headless 已验证 |
| 前版 | [yard_paper_v1_6.md](yard_paper_v1_6.md) |
| 数据 | `data/levels/yard.json` version **8**；`data/fixtures/plan_a.json` MP40 朝向 **45°** |
| 金标 | `hashes.json` 已重生成；t0 仍 **520 / 560** |

## 改动（全部为“代定，盲测后可调”的数据字段）

| 项 | 旧 → 新 | 原因 |
|---|---|---|
| `cells` (11,6) | 主路 road → road + low cover | 晚 2s 起爆时头兵在 (11,6) 进掩体并停住；给“晚起爆”一个可解释的停顿点，配合南向脱出判负 T-A+2 |
| `enemies.spawns` F1/F2 | `enter_t_s` 16 → **17** | 东巷侧翼晚 1s 入场：理想 t0 下仍被 Kar 看住并清掉，但不再在 t0 前多打出一发打死 Kar；保持 BASE-A 评级 A |
| `operators[2]` MP40（fixture A） | `facing_deg` 90 → **45** | 不再覆盖主路南段（x≈11, y≥3）；南向脱出在“转错/换枪/晚起爆”时成为真实代价 |
| `cells` (7,4)/(7,5)/(7,6)/(8,4) | `no_place: true` + 原因 | B Kar 西侧无解格：显式禁止落位，控制器中文拒绝（原测试跳过） |
| `cells` (4,9)/(5,10) | `no_place: true` + 原因 | T6 遗留手指滑动格：高端±1 射界被墙挡/无法同时封锁主路与东巷，几何上无法保胜，改为明确禁止 |
| `cells` (9,6) | `no_place: true` + 原因 | T6 遗留 B Kar 东侧 ±1：硬核档必输，禁止落位 |
| `cells` (15,8)/(15,7)/(16,7)/(17,7) | `no_place: true` + 原因 | T6 遗留 B MP40 周边 ±1：硬核档必输，禁止落位（全 ±1 断言） |

`no_place_reason_zh` 文案：

- 西侧四格：`此掩体侧射界被挡，禁止落位`
- (4,9)：`此高点侧射界被墙挡住，禁止落位`
- (5,10)：`此高点无法同时封锁主路与东巷，禁止落位`
- (15,7)/(16,7)/(17,7)：`此格无法覆盖东巷退路，禁止落位`

控制器 `greybox_controller.gd`：`_move_selected_op` / `_handle_op_place_tap` / `scripted_place_operator` 均拒绝，`label_info` 显示原因；OP 工具合法高亮也排除这些格。schema `schema/level.json` 增加可选 `no_place` / `no_place_reason_zh`。

## 判负口径（T7）

- 严判组（默认硬核 assist=false）：`F-A60`、`T-A+2`、`T-A+4`、`W-A-MG→Kar` 全部 `outcome=="lose"`。
- 过渡门 `COUNTEREX_TRANSITION_GATE := true` 作为兜底；`TRANSITION_IDS` 目标为空，本轮 **为空**（4 例都直接判负）。T-A+4 无论哪条路 `standard_ambush` 必须 false（实测 false）。
- 其余 10 个命名门保持 D.3 成立，D.3 口径（逃脱≥1 / 清场 +50% / 受伤 +50%）未改。

## 实测（默认硬核，`w2_counterex_test.gd`）

| 用例 | outcome | 逃脱 | 清场 s | 受伤 | 阵亡 | 证据 |
|---|---|---|---|---|---|---|
| F-A60 | **lose** | 0 | 0.80 | 6 | 3 | 全队阵亡 |
| T-A+2 | **lose** | 1 | 1.80 | 2 | 1 | E1 南门逃脱 |
| T-A+4 | **lose** | 2 | 3.05 | 4 | 2 | 2 人南门逃脱；非标准伏击 |
| W-A-MG→Kar | **lose** | 0 | 0.80 | 6 | 3 | 全队阵亡 |
| BASE-A | win | 0 | 0.65 | 1 | 0 | 标准伏击 |
| BASE-B | win | 0 | 3.25 | 2 | 1 | 标准伏击 |
| T-A+0 / T-B+0 | win | 0 | 0.65 / 3.25 | 1 / 2 | 0 / 1 | 理想窗仍成立 |

其余 10 门（默认 OFF）：F-A30 lose、F-B30 lose、F-B60 lose、T-A-4 lose、T-A-2 lose、T-B-4 lose、T-B-2 lose、T-B+2 lose、T-B+4 lose、S-unscout-east lose；全部 `holds_strict=true`。

四档开局警报（quiet / suspicious / area_alert / global_alert）在 OFF 与 ON 两档都是 **wins=2**。

## 金标差异

| plan | 旧 hash | 新 hash | outcome | t0 | standard | 负伤/阵亡 | 清场 |
|---|---|---|---|---|---|---|---|
| A | `a89a0e5a…` | `42eae734…` | win | 520（不变） | true | 1/0（不变） | 0.55 → 0.65 |
| B | `d3f35826…` | `78285cce…` | win | 560（不变） | true | 1/1（不变） | 3.25（不变） |

原因：A 因东巷晚 1s + (11,6) 掩体，开火/击杀 tick 与清场时间改变（全歼、伤亡不变）。MP40 转向**不影响** BASE-A 事件流（反向对照：转回 90° 时 W2 金标照过），它只在晚起爆/换枪等反例里起作用（转回 90° → counterex 45/4）；B 的 fixture 未改，但关卡侧翼入场与 (11,6) 掩体改变事件流（结果、伤亡、清场不变）。

## G.1 与手指格

- 出版格 × 朝向 ±5°：全胜。
- 全 cover-pad ±1（含原西侧 4 格）：142 条断言全过；11 个无解格以 `no_place` + 控制器拒绝处理，`HARD_TIER_EXCEPTIONS` 已删除（目标为空）。
- 西侧原因逐格断言为 `此掩体侧射界被挡，禁止落位`，W8 另断言控制器拒绝与文案。

## T5 北梯结论（W5b）

未变，`w5b_ladder_safety_test.gd` 39/0：

- 方案 A 北梯 (5,12)：quiet/suspicious t0=520，攀爬 0..59 与攀爬后到 t0 被看见 **0 次**；area_alert t0=29，0..29 也是 0 次。
- 东门 (6,9) 对照：quiet 攀爬 0..39 被看见 **32** 个 tick，首次 tick 0，t0=298。

## 验证

`run_isolated_test.sh`，先 `--import`。全部 exit 0：

| 套件 | SUMMARY | 套件 | SUMMARY |
|---|---|---|---|
| empty | 0 | W5b | 39/0 |
| W2 | 107/0 | W6 | 25/0 |
| counterex | **49/0** | W7 | 30/0 |
| aim | **142/0** | W8 | **441/0** |
| W3 | 85/0 | blacklist | 35/0 |
| W4 / W4 carry | 27/0、39/0 | W9 | 80/0 |
| W5 | 22/0 | | |

## 遗留

- 截图/真机：T7 新几何与 no_place 提示的可读性待 720p 截图/真机确认。
- 过渡门当前为空；若盲测认为某例过严，可把它登记进 `TRANSITION_IDS`（win + 非标准 + C + 复盘点名）而不改 D.3 阈值。
