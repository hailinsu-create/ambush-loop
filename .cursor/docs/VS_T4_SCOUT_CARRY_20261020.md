# VS T4 侦察警报带入埋伏（2026-10-20）

| 字段 | 值 |
|------|-----|
| 状态 | **已实现 + 隔离 headless 测试已验证**；draft PR → `vs/g3`（不合并、不发布）。携带力度为**规划建议初值**，待所有者拍板 |
| 分支 | `vs/t4-scout-carry`（自 `origin/vs/g3` @ `0de03bc`；不依赖 T1/T2） |
| 代码提交 | `683b55e` |
| 需求来源 | `NEXT_PLAN_20261018.md` T4（Notion 规划页 3fdb407a692a81b08c58d007e8cf7800） |
| 编码方式 | 本机 OpenCode CLI + `opencode-go/deepseek-flash`（`--variant max`），2 轮（约 12.5 + 1 分钟）；人工审查 diff |
| chatgpt | unavailable |

## 契约变化（声明）

- **替代** `VS_W4A_SCOUT_GATHER_20261017.md` 第 5 条「仅 scout 时钟；埋伏仍从安静开始」：侦察结束时的警报现在带入埋伏。该旧文档保留不改，以本文件为准。
- `plan` 新增**可选**键 `start_alert`（quiet / suspicious / area_alert / global_alert；缺省、空、非法值 → quiet）。fixture 不带该键 → 事件流逐字节不变，金标不动（W2 74/0；测试另验 quiet 与缺省 log hash 相等）。
- tick 0 事件顺序：`sim_start → mine_place → phase(wait) → alert_change(reason=scout_carry)`（仅非 quiet）。

| 携带档 | 埋伏开局 | 效果 |
|---|---|---|
| quiet | quiet | 与现状一致 |
| suspicious | suspicious | 起疑开局，80 tick 无暴露回安静；**不**预占 second_suspicious 计数，标准伏击仍可得 |
| area_alert | area_alert | `standard_ambush_eligible=false`；巡逻走 `alert_route`、岗哨朝向切 `alert_route.facing_deg`（既有机制） |
| global_alert | global_alert | 同上 + 首个 WAIT tick 由既有 `_step_trigger` 触发 `trigger=alarm`，未入场敌人走 `alarm_route` |

## 改动

- `ambush_vs/sim/night_sim.gd`：成员 `start_alert`、`_valid_start_alert`；`begin_wait` 应用携带。不改阈值、`_step_alert`、几何。
- `ambush_vs/scripts/greybox_controller.gd`：`carried_alert`；`begin_setup_from_scout` 记录 `scout.alert`，顶部条「侦察带入 · 警报：…」+ 中性提示；`_start_wait` 写入/擦除 `plan.start_alert`；`_restart_scout`、`_load_preset` 重置为 quiet（重试不污染，有断言）。
- 新测试 `ambush_vs/scripts/w4_scout_carry_test.gd`（31 条）；`run_isolated_test.sh/.ps1` 白名单加入。
- 结果表 `ambush_vs/docs/SCOUT_CARRY_P1_RESULTS_20261020.md`。

## 实测（本机 headless）

| 方案 | 携带 | outcome | trigger | standard_ambush | 起爆 tick | 阵亡 |
|---|---|---|---|---|---|---|
| A | quiet | win | cross_marker | true | 520 | 0 |
| A | suspicious | win | cross_marker | true | 520 | 0 |
| A | area | win | alarm | false | 29 | 1 |
| A | global | win | alarm | false | 0 | 1 |
| B | quiet | win | mine_detonate | true | 560 | 0 |
| B | suspicious | win | mine_detonate | true | 560 | 0 |
| B | area | win | mine_detonate | false | 560 | 0 |
| B | global | win | alarm | false | 0 | 1 |

- 可胜门：area / global 携带下 A、B 均胜（ADR-ALERT 决策 5「被发现不直接判负」）。
- 「安静 vs 被看见结果不同」：area/global 两组在 A、B 上 standard_ambush 都由 true 变 false（A 还提前起爆 + 阵亡 1）。
- **suspicious 携带对现有 A/B 结果无可见代价**（与 quiet 同结果）。备选更重方案 `suspicious_count=1` 实测：A → alarm、起爆 298、阵亡 1、标准伏击失去；B → 标准伏击失去。按规划「标准伏击仍可得」取轻方案；**力度待所有者拍板**。

## 验证（`ambush_vs/scripts/run_isolated_test.sh <godot> <entry>`）

empty 0 · W2 sim 74/0（金标）· counterex 27/0 · aim 111/0 · W3 57/0 · W4 27/0 · **W4 carry 31/0（新）** · W5 19/0 · W6 25/0 · W7 26/0 · W8 controls 357/0 · blacklist 33/0 · W9 69/0，全部 exit 0。

反向对照：`night_sim.gd` 恢复 `0de03bc` 版后 W4 carry `passed=14 failed=12`、exit 1（含 `Invalid access … 'start_alert'`）；恢复新版 31/0。

## 遗留

- **CI 不跑 W4 carry**：需改 workflow（T3 权限）。步骤补丁已备 `/workspace/ambush/t4-ci-w4carry-step.patch`（本机，`git apply --check` 通过），并入 T3 一次提交。
- 携带力度（尤其 suspicious 轻/重、area 下 A 29 tick 即升全图）需所有者拍板。
- 浏览器/真机看 SETUP 顶部条与提示：待验证。
- 下一项 T5（高点攀爬代价）同改 `night_sim.gd`，应在本 PR 合并后的 `vs/g3` 上做。
