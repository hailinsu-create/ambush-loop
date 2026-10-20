# T5c 攀爬小数秒 + 北梯等待期安全测量 · P1 结果（2026-10-20）

切片：攀爬入口秒数支持小数；只测量谷仓北梯从开局到起爆前的可见性，不改几何、不改 sim 规则、不改金标。
本页数值为本机 headless 实测，来自 `w8_controls_test.gd` 与 `w5b_ladder_safety_test.gd`（`run_isolated_test.sh` 包装器，exit 0）。

## 口径

- **攀爬秒数**：`greybox_controller.gd` 的 `_climb_access_seconds(entry)` 返回原始 `float`（缺省 `SimConstants.CLIMB_COST_S`）；`_climb_access_ticks(entry) = maxi(1, int(round(secs * TICK_HZ)))`，控制器写 `climb_ticks_left` 只走这个 helper。
- **文案**：`_fmt_secs(s)` 整数秒输出 `"3"`，非整数保留 1 位小数输出 `"2.5"`；入口文案、放置提示、开局「N 人攀爬中」都用它。现有 2.0/3.0 文案逐字不变（`"约 2 秒"` / `"约 3 秒"`）。
- **测量**：`w5b_ladder_safety_test.gd` 用 `NightSim.observers_seeing_cell()`（内部即暴露步使用的 `_observer_sees`）逐 tick 查询；只读，不写事件、不改 sim 行为。
  - 情形 1/2/3：跑真实方案 A（fixture + 与控制器一致的 `climbing/climb_from/climb_ticks_left`），直到 `sim.detonate_tick >= 0`。每 tick 在 `advance_one_tick()` 后查询，观察者位置与该 tick 暴露步一致；攀爬中按 ground 档查询。
  - 攀爬窗口取事件 `climb_start..climb_end`（北梯 0..59、东门 0..39）；「攀爬后到 t0」为 `climb_end+1..t0`。区域警戒 t0=29，攀爬未结束，窗口截到 t0。
  - 情形 4 驻留：**直接对格子做可见性查询**（不新增 op、不改事件流）。0..t0 在真实方案 A 的观察者/警报演化上查询；t0 之后用「无 op + manual 触发」的观察者时钟跑到 tick 900，让巡逻继续循环且夜晚不会提前结束。
  - 东门 (6,9) 对照：情形 1 用同一方案 A、仅入口改为东门（40 tick）；情形 4 对 (6,9) 做同样的格子查询。

## 任务 2 实测表

### 情形 1/2/3 + 东门对照（op_mg42）

| 情形 | 入口 | 携带档 | t0 | climb_start | climb_end | 攀爬窗口内被看见 tick 数 | 攀爬后到 t0 被看见 tick 数 | 首次被看见 tick（观察者） |
|---|---|---|---|---|---|---|---|---|
| 1 | 北梯 (5,12) | quiet | 520 | 0 | 59 | **0** | **0** | **none** |
| 2 | 北梯 (5,12) | suspicious（×1.3） | 520 | 0 | 59 | **0** | **0** | **none** |
| 3 | 北梯 (5,12) | area_alert | 29 | 0 | 未结束（>t0） | **0**（0..29） | 0 | **none** |
| 对照 | 东门 (6,9) | quiet | 298 | 0 | 39 | **32** | 0 | **0（patrol:west_patrol）** |

东门在攀爬第 0 tick 即被 `west_patrol` 看到，最终丢掉标准伏击（t0 提前到 298）；北梯在 quiet/suspicious/area 三种携带档下，起爆前均未被任何岗哨/巡逻看到。

### 情形 4a：驻留在真实方案 A 的 t0 之前

| 场景 | 格子 | 携带档 | 到 t0 首次被看见（观察者） |
|---|---|---|---|
| 北梯 | (5,12) | quiet | **none** |
| 北梯 | (4,12) | quiet | **none** |
| 东门 | (6,9) | quiet | **0（patrol:west_patrol）** |
| 北梯 | (5,12) | suspicious | **none** |
| 北梯 | (4,12) | suspicious | **none** |
| 东门 | (6,9) | suspicious | **0（patrol:west_patrol）** |
| 北梯 | (5,12) | area_alert | **none**（t0=29） |
| 北梯 | (4,12) | area_alert | **none**（t0=29） |
| 东门 | (6,9) | area_alert | **none**（到 t0=29） |

### 情形 4b：观察者时钟跑到 tick 900（首次被看见）

| 携带档 | 格子 | 首次被看见 tick（观察者） |
|---|---|---|
| quiet | (5,12) | **599（patrol:west_patrol）** |
| quiet | (4,12) | **599（patrol:west_patrol）** |
| quiet | (6,9) | **0（patrol:west_patrol）** |
| suspicious | (5,12) | **599（patrol:west_patrol）** |
| suspicious | (4,12) | **599（patrol:west_patrol）** |
| suspicious | (6,9) | **0（patrol:west_patrol）** |

> 之前「tick 600 回程巡逻会看到」的说法**成立**：实测首次看见是 **tick 599**，观察者为 `west_patrol`；tick 600 时已经在视野内。

## 结论

- **北梯起爆前安全**：方案 A 北梯在 quiet 与 suspicious 下 t0 均为 520，攀爬窗口（0..59）和攀爬后到 t0 的被看见 tick 数都为 **0**；首次被看见为 **none**。area_alert 下 t0=29，攀爬尚未结束，0..29 同样为 **0**。
- **东门起爆前不安全**：quiet 下攀爬窗口 0..39 中有 **32** 个 tick 被 `west_patrol` 看见，首次为 **tick 0**，t0 提前到 298。
- **驻留北梯最终会被看到**：若有人在 (5,12)/(4,12) 一直站到 900 tick，首次被看见为 **tick 599，观察者 `patrol:west_patrol`**；正常 3 秒攀爬在 tick 59 结束、t0=520，早于该暴露点，因此当前切片不需要改几何或规则。若以后把攀爬时长调到 ~30 秒以上，会重新暴露。
- **小数秒**：`{"climb_s":2.5}` → `_climb_access_seconds=2.5`、`_climb_access_ticks=50`；`2.04` → 41 tick（`round(40.8)`）；`3.0` → 60；缺省 `{}` → 40。`_fmt_secs(2.5)="2.5"`、`_fmt_secs(3.0)="3"`。场景级：运行时把 `barn_l2` 北梯 `climb_s` 改为 2.5 后，入口文案为「入口：北侧梯子（绕行，约 2.5 秒）」，方案 A 的 `climb_ticks_left=50`；json 文件未改。
- **金标**：W2 107/0 不变，`hashes.json` 未改；本切片只改控制器文案/取整和测试，不改 sim 事件。

## 验证

| 套件 | SUMMARY | 退出码 |
|---|---|---|
| w5b_ladder_safety_test | 39/0 | 0 |
| w8_controls_test | 405/0 | 0 |

其余套件按验收清单全量运行，见提交说明/最终回答。新测试的 `.uid` 按仓库惯例保留。
