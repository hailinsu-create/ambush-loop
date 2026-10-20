# VS 复盘击杀归属单位名修复（2026-10-20）

| 字段 | 值 |
|------|-----|
| 状态 | **已实现 + 隔离 headless 测试已验证**；draft PR → `vs/g3`（不合并、不发布） |
| 分支 | `vs/fix-review-actor-label`（自 `origin/vs/g3` @ `0de03bc`；与 T2 PR #64 独立） |
| 代码提交 | `d98bd46` |
| 来源 | T2（PR #64）审查时发现：漏网用例复盘出现「队员 在首轮点杀了 5 人」 |
| 编码方式 | 本机 OpenCode CLI + `opencode-go/deepseek-flash`（`--variant max`，1 轮约 1.5 分钟）；人工审查后把测试 helper 改名 `_label_fresh_sim`（避免与 T2 的 `_fresh_sim` 合并后重名） |
| chatgpt | unavailable |

## 问题（已核实）

`review_builder.gd` 击杀归属句：
1. top_actor 取 kill 事件 actor 计数最多者，不区分是否方案内单位；非方案 actor（测试注入的 `test`、`system`、方案里没有的 `op_grenade` 默认值）经 `_op_label` 回退成裸「队员」。正常对局里 actor 都是方案单位，**主要在注入/异常 actor 时出现**。
2. 句子数字用**全队**首轮击杀 `volley_kills`，却挂在一个单位名下（例如合成用例 MG42 2 + Kar98k 3 → 原文「2号·Kar98k 在首轮点杀了 5 人」）——这是正常对局也会出现的错归属。
3. 名字后多一个空格（「X 在首轮」），与其它句式不一致。

## 改动

- `_compute_metrics` 新增 `volley_by_actor`（与 `volley_kills` 同窗口）；`_grade` 仍用全队 `volley_kills`，评级不变。
- 新增 `_is_known_actor`；top_actor 只在方案单位/地雷中选。单位自己首轮 ≥4 → 「X在首轮点杀了 N 人」（N＝该单位首轮数），否则「X扛下了主要击杀（N 人）」；没有已知 actor 时用全队措辞「首轮齐射点杀了 N 人 / 交叉火力完成清场（N 人）」。
- `_op_label` 不变；事件、金标、`night_sim.gd` 未动。
- `w6_review_test.gd`：25 → 38（合成 `_causes` 三例 + 空格检查 3 条 + 真实 sim 漏网例 2 条）。

## 验证（本机 Godot 4.7.2，`ambush_vs/scripts/run_isolated_test.sh`）

empty 0 · W2 sim 74/0（金标）· counterex 27/0 · aim 111/0 · W3 57/0 · W4 27/0 · W5 19/0 · **W6 38/0** · W7 26/0 · W8 controls 357/0 · blacklist 33/0 · W9 69/0，全部 exit 0。

反向对照：`review_builder.gd` 恢复为 `0de03bc` 版本后 W6 `passed=27 failed=11`、exit 1（「队员 在首轮点杀了 5 人」「2号·Kar98k 在首轮点杀了 5 人」「队员 在首轮点杀了 10 人」）；恢复新版 38/0。

## 遗留

- 与 PR #64 同改 `w6_review_test.gd`（`_run_all` 相邻行）与 `PLANNING_INDEX.md`，后合者需解一次小冲突；两边 helper 已不重名。
- 浏览器/真机看复盘卡：待验证。
