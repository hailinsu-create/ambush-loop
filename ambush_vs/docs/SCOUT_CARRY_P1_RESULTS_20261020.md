# T4 侦察警报带入埋伏 · P1 结果（2026-10-20）

切片：把侦察阶段结束时携带的警报档带入 NightSim 等待/起爆（可选 plan 键 `start_alert`）。
本页数值为本机 headless 实测，来自 `w4_scout_carry_test.gd`（`run_isolated_test.sh` 包装器，exit 0）。

口径：
- `quiet` / 缺省 / 非法值 → 不写 `start_alert`，事件流与金标逐字节一致（W2 74/0 零变化）。
- `suspicious` → tick 0 发 `alert_change` reason=`scout_carry`；不预占 `second_suspicious` 计数（`suspicious_count` 保持 setup 的 0），仍可标准伏击。
- `area_alert` → 同 tick 0 事件；标准伏击不可得（`standard_ambush_eligible=false`）；巡逻切 `alert_route`。
- `global_alert` → 同 area 两项；首个 WAIT tick 由既有 `_step_trigger` 触发 `trigger=alarm` 进入起爆。

固定 tick 0 事件顺序：`sim_start` → `mine_place` → `phase=wait` → `alert_change(scout_carry)`（仅非 quiet）。

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

## 结论

- **可胜门通过**：`area_alert` 携带下 A、B 均 `outcome=win`；`global_alert` 携带下 A、B 均 `outcome=win`。被发现有代价但不判负。
- **标准伏击仍可得**：`suspicious` 携带下 A、B 均 `standard_ambush=true`（起爆 tick 回到 520/560），符合规划要求；不预占 `second_suspicious` 计数。
- **代价体现在**：`area_alert`/`global_alert` 携带局 `standard_ambush=false`（失去标准伏击），A 的起爆被警报提前（29/0），A 的部分携带局与 B global 出现 1 名队员阵亡（`dead_ops=1`）；wounded=1 为常态还击结果。
- **安静路径零变化**：`start_alert=quiet` 与不带键的 log hash 完全相等（A、B 各验一次），W2 金标 74/0 不变。
- **未过的门**：无。

## 备选：suspicious_count=1（更重）

若起疑携带预占 `second_suspicious` 计数（`suspicious_count=1`），实测两案都失去标准伏击，偏离本切片规划。记录上一轮实测如下，**需所有者拍板**：

- A suspicious → outcome=`win` / trigger=`alarm` / standard_ambush=`false` / dead_ops=1 / 起爆 tick 298。
- B suspicious → outcome=`win` / trigger=`mine_detonate` / standard_ambush=`false` / dead_ops=0 / 起爆 tick 560。
