# T4 侦察警报带入埋伏 · P1 结果（2026-10-20）

切片：把侦察阶段结束时携带的警报档带入 NightSim 等待/起爆（可选 plan 键 `start_alert`）。
本页数值为本机 headless 实测，来自 `w4_scout_carry_test.gd`（`run_isolated_test.sh` 包装器，exit 0）。

口径：
- `quiet` / 缺省 / 非法值 → 不写 `start_alert`，事件流与金标逐字节一致（W2 74/0 零变化）。
- `suspicious` → tick 0 发 `alert_change` reason=`scout_carry`；不预占 `second_suspicious` 计数（`suspicious_count` 保持 setup 的 0），仍可标准伏击。**新增轻代价**：整夜岗哨/巡逻锥体发现距离 ×`CARRY_SUSPICIOUS_RANGE_MUL`（仅携带 suspicious 时生效，与当前 alert 档无关）。
- `area_alert` → 同 tick 0 事件；标准伏击不可得（`standard_ambush_eligible=false`）；巡逻切 `alert_route`。
- `global_alert` → 同 area 两项；首个 WAIT tick 由既有 `_step_trigger` 触发 `trigger=alarm` 进入起爆。

固定 tick 0 事件顺序：`sim_start` → `mine_place` → `phase=wait` → `alert_change(scout_carry)`（仅非 quiet）。

> 区域警戒下 A 第 29 tick 升全图警报：所有者认可保持，列为盲测待调参。

## 结果表（A/B × 四档，8 行）

| 方案 | 携带档 | outcome | trigger | standard_ambush | kills | escapes | wounded | dead_ops | reason |
|------|--------|---------|---------|-----------------|-------|---------|---------|----------|--------|
| A | quiet | win | cross_marker | true | 6 | 0 | 1 | 0 | clear |
| A | suspicious | win | cross_marker | true | 6 | 0 | 1 | 0 | clear |
| A | area_alert | win | alarm | false | 6 | 0 | 1 | 1 | clear |
| A | global_alert | win | alarm | false | 6 | 0 | 1 | 1 | clear |
| B | quiet | win | mine_detonate | true | 6 | 0 | 1 | 0 | clear |
| B | suspicious | win | mine_detonate | true | 6 | 0 | 1 | 0 | clear |
| B | area_alert | win | mine_detonate | false | 6 | 0 | 1 | 0 | clear |
| B | global_alert | win | alarm | false | 6 | 0 | 1 | 1 | clear |

（实测起爆 tick：A quiet/suspicious=520、A area=29、A global=0；B quiet/suspicious/area=560、B global=0。）

## 起疑轻代价：quiet vs suspicious 诊断对比（最终倍率 ×1.3）

`wait_exposed_ticks` = WAIT 阶段判定为暴露的 tick 数（仅诊断，不入 summary、不发事件）；`first_exposed_tick` = WAIT 首次暴露 tick（-1=从未）。

| 方案 | 携带档 | wait_exposed_ticks | first_exposed_tick | standard_ambush | trigger | detonate | outcome | dead_ops | wounded |
|------|--------|--------------------|--------------------|-----------------|---------|----------|---------|----------|---------|
| A | quiet | 59 | 0 | true | cross_marker | 520 | win | 0 | 1 |
| A | suspicious | 59 | 0 | true | cross_marker | 520 | win | 0 | 1 |
| B | quiet | 31 | 359 | true | mine_detonate | 560 | win | 0 | 1 |
| B | suspicious | 560 | 0 | true | mine_detonate | 560 | win | 0 | 1 |

选定警觉指标：**`wait_exposed_ticks`（次选 `first_exposed_tick`）**。B 案 suspicious 全程暴露（560 tick、tick 0 起），远差于 quiet（31 tick、359 起）；A 案该机制下无变化（其两员本就在锥体内）。`alert_change→suspicious` 计数未用作判据——tick 0 的 `scout_carry` 事件本身即 +1，倍率=1.0 时也会「变差」，属混淆项。

## 倍率测量过程（先测再定）

对 plan A/B 各跑 quiet 与 suspicious 完整局，读 `wait_exposed_ticks` / `first_exposed_tick`：

| 倍率 | A quiet→susp (wait/first) | B quiet→susp (wait/first) | A/B standard_ambush | 判定 |
|------|---------------------------|---------------------------|---------------------|------|
| 1.0（反向对照） | 59/0 → 59/0 | 31/359 → 31/359 | true/true | 无变化，成本断言 FAIL |
| 1.2（初选） | 59/0 → 59/0 | 31/359 → 31/359 | true/true | 两案指标与 quiet 相同，不达标 |
| **1.3（最终）** | 59/0 → 59/0 | 31/359 → **560/0** | true/true | B 明显变差，标准伏击保留 |
| 1.4（上限） | 59/0 → 59/0 | 31/359 → 560/0 | true/true | 与 1.3 相同（B 已饱和），不再上调 |

最终取值 `CARRY_SUSPICIOUS_RANGE_MUL = 1.3`：A、B 在 suspicious 下 `standard_ambush` 均为 true，且 B 的可观测指标（`wait_exposed_ticks` 560 > 31、`first_exposed_tick` 0 < 359）比 quiet 差，满足「轻代价 + 标准伏击保留」两条。

## 结论

- **可胜门通过**：`area_alert` 携带下 A、B 均 `outcome=win`；`global_alert` 携带下 A、B 均 `outcome=win`。被发现有代价但不判负。
- **标准伏击仍可得**：`suspicious` 携带下 A、B 均 `standard_ambush=true`（起爆 tick 回到 520/560），符合规划要求；不预占 `second_suspicious` 计数。
- **起疑：轻代价（发现距离 ×1.3），标准伏击保留**：suspicious 携带整夜扩大岗哨/巡逻锥体发现距离；B 案 WAIT 暴露从 31 tick 增至 560 tick、首次暴露由 359 提前到 0。A 案本就在锥体内、该机制下无额外代价。
- **代价体现在**：`area_alert`/`global_alert` 携带局 `standard_ambush=false`（失去标准伏击），A 的起爆被警报提前（29/0），A 的部分携带局与 B global 出现 1 名队员阵亡（`dead_ops=1`）；wounded=1 为常态还击结果。
- **安静路径零变化**：`start_alert=quiet` 与不带键的 log hash 完全相等（A、B 各验一次），W2 金标 74/0 不变；倍率仅在 `start_alert=suspicious` 时生效。
- **未过的门**：无。

## 备选：suspicious_count=1（更重）

若起疑携带预占 `second_suspicious` 计数（`suspicious_count=1`），实测两案都失去标准伏击，偏离本切片规划。记录上一轮实测如下，**需所有者拍板**：

- A suspicious → outcome=`win` / trigger=`alarm` / standard_ambush=`false` / dead_ops=1 / 起爆 tick 298。
- B suspicious → outcome=`win` / trigger=`mine_detonate` / standard_ambush=`false` / dead_ops=0 / 起爆 tick 560。
