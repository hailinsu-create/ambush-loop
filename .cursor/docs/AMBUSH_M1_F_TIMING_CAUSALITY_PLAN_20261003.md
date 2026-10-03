# M1-F 火力时机因果门

日期：2026-10-03。来源：原游戏 GPT 项目对话 `c2c_7f3a` iteration 0 的正式 M1-D 至 M1-I PLAN、已确认的《游戏设计规划 v2》第 98 行附近保留的“见敌即打 / 入伏再打”，以及用户本轮继续完成不依赖他人的 M1 工作指示。本文承接 [M1-D 至 M1-I 路线](AMBUSH_M1_D_TO_I_ROADMAP_20261002.md)，只规划桌面自动化 F 门。

## 目标

证明“见敌即打（ENGAGE_ON_SIGHT）”与“入伏再打（HOLD_FOR_AMBUSH）”在同一院子情境下产生可解释的、权威模拟时序差异，而不是只变按钮文案或演出。等待模式必须在敌人尚未入伏区时保留弹药、不记录射击；敌人进入院子伏击区后，真实模拟先记录 `ambush_armed`，随后在权威射击事件中开火。

## 范围与非目标

- 新增独立隔离 gate `m1_yard_timing_causality_gate.gd`，并加入 PowerShell / shell 隔离 runner allowlist。
- 两组场景保持真实院子几何、同一队员、同一把从真实补给箱拾取的枪、同一弹药起始量、相同队员位置/朝向、相同敌人 ID/生命/路线和射界；唯一战术变量是 fire mode。
- 敌人走同一条极短但真实的模拟路径：先处于 `ambush_zone` 外、且在枪械射程/方向/LOS 内，再实际移动进入 zone。通过 `_sim_tick()` 生成 `BattleLog`，不直接调用私有 arming 函数或手工写战斗日志。
- 对照记录首个 `fire` 事件 tick/target、`ambush_armed` 顺序、实际弹药变化与目标 HP。两模式对同一目标造成的单发伤害相同；等待模式首枪不得早于进入 zone 的武装事件。
- 不改伤害、射程、敌人速度、警报节拍、伏击区大小、火力 UI 或模拟时钟；不以动画耗时作结论。

## 实施与验收门槛

1. 先在真实 yard 运行态寻找一对相邻开放路线点：outside 点位于 `level.ambush_zone` 外，inside 点位于区内；两点均可由本关拾取的核心枪合法攻击。若找不到，gate 应失败并报告具体几何缺口，不能清空地形或修改武器数据凑结果。
2. 即时组：正常进入 WATCHING 并推进一个确定性模拟 tick；在 enemy 仍位于 zone 外时，检查有且仅有目标有效的 `fire` 事件、子弹消耗一次且目标 HP 按现有武器伤害下降；本组不应出现 `ambush_armed`。
3. 等待组：重置为同一关卡基线并重做真实箱子拾取，唯一差异是 `HOLD_FOR_AMBUSH`。推进到敌人实际穿过边界；边界外每个 tick 都不得开火/扣弹/伤害。zone 检测后的 tick 必须先记录 `ambush_armed`，再记录该队员对同一目标的 `fire`，随后只消耗一发并造成与即时组等量的单发伤害。
4. 校验 `damage_per_shot`、`range_px`、队员位置/朝向、敌人 ID/生命与场景定义在两组相同；有效目标始终处于射界。仅 fire mode、第一发 tick 和相应事件序列不同。
5. gate 输出稳定 `M1_YARD_TIMING_CAUSALITY_OK` 标记并验证测试存档守卫；wrapper exit 0。若发现真实生产缺陷才改逻辑，并按影响补跑 C3、C2、C1、B2、feel 和完整 smoke；纯 gate 改动至少跑 F、D/E 与相关时机隔离栈。

## 风险与待人事项

- `_sim_tick()` 先检查伏击区、后移动敌人，因此敌人刚在本 tick 跨入区时会在下一 tick 被识别和武装。Gate 必须尊重此权威次序，以事件 tick 证明，不得把跨区动画时刻误作已经武装。
- `HOLD_FOR_AMBUSH` 的 `fire_permitted` 与 `BattleLog` 可能受计划冻结/重试影响；测试必须从真实 SETUP 火力选择与警报入口开始。
- 本计划沿用原 D–I 总 PLAN。用户要求暂缓需人的部分，因此新的外部 GPT 逐切片 REVIEW 暂未执行；本计划和后续本地通过均不代表外部批准。
- vivo 真机、5 位非开发者试玩及设备依赖的 AudioTrack 根因仍待补，不能由 F 桌面 gate 替代。

## M1-F 实现与桌面验证结果（2026-10-03）

源码 Draft PR #20：[`2010829`](https://github.com/hailinsu-create/ambush-loop/pull/20)，分支 `codex/m1-f-timing-causality`，以 E PR #19 对应分支为 base。只新增隔离 gate 与两种 runner allowlist，没有改生产战斗逻辑、武器伤害或射程。

最终隔离 run `97aed94aefe94d56bcf673448f3a4fe7`，Godot 4.7.2，wrapper exit 0，`PLAYER_DATA_UNCHANGED=1`。标记 `M1_YARD_TIMING_CAUSALITY_OK real_crate=1 same_weapon=1 same_geometry=1 outside_immediate=1 hold_waits=1 armed_before_fire=1 equal_damage=1 equal_range=1 real_retry=1`。同一院子、同一队员/位置/朝向、真实搜索所得同款枪与相同弹药、相同敌人 ID/生命/路线下，即时模式在伏击区外开火；等待模式在进入区前不消耗弹药、不伤敌，入区后权威日志先记 `ambush_armed`、同 tick 再记 `fire`，单发伤害相等。两次试验之间使用真实中止→继续重试清理。

附加隔离回归：D run `11f3ab9f60db45279895db1adea04955` exit 0，E run `a22ec167913d490bb22fdfe620b28c20` exit 0。首次 gate 测试曾因夹具在正常拉警报之前加入敌人而被生产 `_queue_spawns()` 清除；按真实启动顺序将夹具移至警报后，并尊重 60Hz 固定步长；这仅修正了 gate，没有生产缺陷或平衡值变更。

**边界：** 以上是桌面确定性模拟证据，不代表外部 GPT REVIEW、真机或玩家理解度通过。下一切片见 [M1-G 两种有效方案与失败反例](AMBUSH_M1_G_TACTICAL_SOLUTIONS_PLAN_20261003.md)。vivo、5 位非开发者试玩及设备依赖的 AudioTrack 仍暂缓；M1 整体未退出。
