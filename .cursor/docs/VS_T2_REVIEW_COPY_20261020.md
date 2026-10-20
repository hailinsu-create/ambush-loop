# VS T2 复盘卡跨夜文案清理（2026-10-20）

| 字段 | 值 |
|------|-----|
| 状态 | **已实现 + 隔离 headless 测试已验证**；draft PR → `vs/g3`（不合并、不发布） |
| 分支 | `vs/t2-review-copy`（自 `origin/vs/g3` @ `0de03bc`；不依赖 T1 / PR #62） |
| 代码提交 | `cf179ef` |
| 需求来源 | `NEXT_PLAN_20261018.md` T2（Notion 规划页 3fdb407a692a81b08c58d007e8cf7800）；Opus P1-8「跨夜字段降成日志、VS 内不生效」 |
| 编码方式 | 本机 OpenCode CLI + `opencode-go/deepseek-flash`（`--variant max`，1 轮约 1.5 分钟），人工审查 diff |
| chatgpt | unavailable |

## 范围

- `ambush_vs/sim/review_builder.gd`：删除读取 `summary.next_night_alert` 的分支；漏网逃脱统一显示中性文案「有 N 人漏网逃脱，杀伤区或朝向还有缺口」。玩家可见复盘不再出现「下一夜警报将升高」。
- `night_sim.next_night_alert` **保留**为日志/数据字段（`w7_combat_test.gd` 数据断言不变），UI/复盘不再读取。
- `ambush_vs/scripts/w6_review_test.gd`：+8 条断言（25 → 33）
  - Plan A / B 复盘 causes+timeline 不含「下一夜」；
  - 漏网用例（照 W7：plan_a、skip_fire/skip_enemy_fire、起爆后杀到剩 1 人）：前置 `escaped_ids` 非空、`next_night_alert != quiet`（数据字段仍升档），复盘不含「下一夜」且含「漏网/逃脱」；
  - 场景复盘卡 `review_card_text()` 不含「下一夜警报」「警报将升高」。
- 范围外未动：`greybox_controller.gd` 的「下一夜套件」搜尸 stub 文案、`night_sim.gd`、金标、workflow。

## 验证（本机，Godot 4.7.2，`ambush_vs/scripts/run_isolated_test.sh`）

| 套件 | 结果 | exit |
|---|---|---|
| empty_test | — | 0 |
| w2_sim（金标） | 74/0 | 0 |
| w2_counterex | 27/0 | 0 |
| w2_aim_tolerance | 111/0 | 0 |
| w3_greybox | 57/0 | 0 |
| w4_scout | 27/0 | 0 |
| w5_combat_fx | 19/0 | 0 |
| **w6_review** | **33/0**（基线 25） | 0 |
| w7_combat | 26/0 | 0 |
| w8_controls | 357/0 | 0 |
| w8_briefing_blacklist | 33/0 | 0 |
| w9_playtest | 69/0 | 0 |

反向对照：把 `review_builder.gd` 恢复为 `0de03bc` 版本后跑 W6 → `passed=32 failed=1`、exit 1，失败行为
`leak review has no 下一夜 copy got=…|有 1 人漏网逃脱，下一夜警报将升高|…`；恢复新逻辑后 33/0。

金标：事件日志哈希只覆盖 `log.events`，改复盘文本不影响；W2 金标通过。

## 遗留 / 待验证

- 浏览器/真机看漏网局复盘卡：待验证（headless 已覆盖文本）。
- 若所有者要求彻底删除 `next_night_alert` 字段（规划第 5 节授权项 9），另开切片连带改 `night_sim.gd` 四处与 `w7_combat_test.gd:165-168`。
- 观察：漏网用例复盘里出现「队员 在首轮点杀了 5 人」——`_op_label` 对该 actor 没取到单位名（回退成「队员」），与 T2 无关，未改，留给 A10/UI 文案切片核对。
- 下一项：T3（需 workflow 权限，未做）→ T4 侦察警报带入埋伏。
