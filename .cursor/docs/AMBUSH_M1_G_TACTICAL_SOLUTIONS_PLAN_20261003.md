# M1-G 院子两种有效方案与失败反例

日期：2026-10-03。来源：用户确认的[设计规划 v2 第 6 节](AMBUSH_DESIGN_V2_20260928.md)、[院子高点与资源 ADR](AMBUSH_M1_YARD_HEIGHT_ADR_20260929.md)、[D–I 桌面续做路线 G 项](AMBUSH_M1_D_TO_I_ROADMAP_20261002.md)，以及用户要求先搁置需人的 M1 项、完成其余部分。本文件是桌面实现计划；不声称来自本轮外部 GPT 新 PLAN/REVIEW。

## 目标

在真实 yard 的两波任务中，用确定性自动化证明两种设计 v2 方案可各自覆盖预期威胁，并用反例说明“全员守主路”为什么会漏掉东廊侧翼。不能预设旧教学文案代表有效解，也不能只以静态扇形相交替代实际火力与结算。

## 要比较的配置

- **A：** 精准手（op3）合法走坡道占装卸高台，支援手（op2）在地面补主道，步枪手（op1）封侧巷/橙线。
- **B：** 支援手（op2）合法走坡道占高台形成另一条主射界；精准手（op3）看出口；步枪手（op1）护台阶。
- **失败对照：** 三人集中/朝向都覆盖红线主路，不专人覆盖东廊。必须由真实第三名侧翼敌人沿关卡 `flank` route 产生 `escape`，并记录未交战/位置、方向或射程原因；不能人为令敌人跳过战斗或直接写失败事件。

单元格候选只是试验起点，门禁以现有 `LevelDef` / `AmbushGrid` 真实几何和 gate 的实际路线移动结果决定是否有效。若候选导致失败，应按 BattleLog、`engage_block_reason`、弹药、队员位置及逃逸路线定位，再最小调整站位/朝向；不得改敌人速度、枪械伤害、射程或凭空增加弹药来凑通关。A/B 的差异必须落实到设计 v2 所规定的角色与路线分工。

## 实施边界

新增独立 `m1_yard_tactical_solutions_gate.gd`，加入 PowerShell 与 shell 隔离 runner allowlist。每个情境从真实 `main.tscn` / yard 开始；每名队员经正常移动路径抵达对应现有补给箱，以真实搜索/拾取取得枪；沿真实路径移动到计划位置，高台进入必须穿过 ADR 中唯一坡道。相同队员、弹药生成规则、敌人批次/route、模拟速度与胜负条件在 A/B 间保持一致。

用正常警报和 `_sim_tick()` / RaidState 波次流程运行两波；只通过真实 `_on_sweep_commit()` 进入下一波。按 `BattleLog` 核验敌人出生/路线、真实 `fire`、`kill`、`escape`、首枪 tick 和资源消耗。不可手工制造 kill、escape 或 battle events。多场景之间通过隔离的新场景/正式失败重试入口恢复，不复用上一局残留库存或敌人。

## 验收条件

1. **A/B 均须赢下 yard 两波：** 两名主路敌人（IDs 1/2）和一名侧翼敌人（ID 3）均由真实火力消灭，无逃逸、全灭或重复结算；终态为本局 `WON`，资源与事件记录自洽。
2. **A/B 必须体现约定站位：** op3/op2 谁占高台、op1 所护路线与 B 的出口/台阶职责可由最终位置、高度、朝向和实际 `fire` target 验证；高台移动路径确经坡道，不瞬移。两套配置不改变任何枪械伤害/射程。
3. **弱点仍存在：** 高台只改变既有遮挡/可见性；完整墙、射界、射程、弹药仍有效。至少保存高点无效目标/矮遮挡对照或现有 C2/C3 回归证据，不能宣称高台无死角。
4. **反例须失败且可解释：** 红线集中配置要在真实 `flank` route 的 escape cell 产生 ID 3 逃逸；日志/几何证明队员朝向、距离或路线覆盖不足，且队伍未因全灭、脚本跳过或测试夹具损坏而失败。
5. **回归与存档：** 测试必须通过隔离包装器，输出稳定 `M1_YARD_TACTICAL_SOLUTIONS_OK` 与玩家存档不变。若调整生产地图/玩法数据，按影响补跑 C3/C2/C1/B2、D/E/F、feel 和完整 smoke；纯 gate 变化至少重跑 G 及受影响隔离栈。

## 暂缓项与下一步

外部 GPT 对精确差异的新增 REVIEW、Android/vivo、五位非开发者试玩及设备依赖 AudioTrack 根因继续等待后续人类授权/参与，不由桌面 gate 代替。G 通过后开展 H 整关一致性，再做 I 的渲染证据；即使 D–I 桌面门完成，M1 仍须保留上述人类与设备退出条件。

## M1-G 实现与桌面验证结果（2026-10-03）

源码 Draft PR #21：[`da10638`](https://github.com/hailinsu-create/ambush-loop/pull/21)，分支 `codex/m1-g-tactical-solutions`，以 F 分支为 base。新增隔离 gate `m1_yard_tactical_solutions_gate.gd` 与 PowerShell/shell allowlist；未改生产玩法数据。

最终隔离 run `f13b9dc497df4d1c9e71a10881567c5d`，Godot 4.7.2，wrapper exit 0，`PLAYER_DATA_UNCHANGED=1`。成功标记：`M1_YARD_TACTICAL_SOLUTIONS_OK real_weapons=1 real_ramp=1 plan_a_win=1 plan_b_win=1 same_budget=1 flank_counterexample=1 explained_escape=1 two_waves=1`。A、B 均从真实枪械箱搜索拾取、按合法路线移动；高点队员实际走过坡道；两波各击毙 ID 1/2/3、零逃逸并获胜。主路集中反例由真实东廊 flank route 逃逸，日志记录未交战原因，失败原因是 `escape` 而不是全灭或测试夹具直接写入终局。

A/B 实际枪械弹药签名一致。需校准资源文档：`mg` 补给选择的实枪械为 MG42，模型载弹量为 50；这与早期 ADR 将通用 MG 预算写作 12 不同。G 只验证两案资源完全相同，未改数值；后续规划/截图按真实模型值记录，不将旧 ADR 数值当作 MG42 当前弹量。

## 当前状态

G 本地桌面门通过；外部 GPT 精确差异 REVIEW、Android/vivo、五位非开发者试玩及设备依赖 AudioTrack 继续待人/设备。下一步进入 [M1-H 整关一致性计划](AMBUSH_M1_H_END_TO_END_PLAN_20261003.md)，桌面门全过也不代表 M1 整体退出。
