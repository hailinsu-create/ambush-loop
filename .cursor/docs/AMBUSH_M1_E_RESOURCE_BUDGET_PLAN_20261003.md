# M1-E 资源因果与预算门

日期：2026-10-03。来源：原游戏 GPT 项目对话 `c2c_7f3a` iteration 0 的正式 M1-D 至 M1-I PLAN，以及用户本轮“把 M1 除了需要人的部分暂时搁置，其他都做完”的明确继续指示。本文承接 [M1-D 至 M1-I 路线](AMBUSH_M1_D_TO_I_ROADMAP_20261002.md)，仅规划桌面自动化 E 门；不是游戏实现或 M1 验收证据。

## 目标

用隔离自动化证明院子战术样板的资源具备可解释因果：基础方案不依赖可选补给，可选补给确实支持不同路线，装备归属和弹药消耗可观察，弹药耗尽不会凭空射击/补弹，失败重试会恢复本局资源并且不会复制箱子。

## 范围与非目标

- 范围：真实院子定义、实际补给点生成/拾取、队员库存、弹药池、开火结果、失败后重新布置，以及独立隔离 gate。
- 优先只新增 `m1_yard_resource_budget_gate.gd` 与 PowerShell / shell runner allowlist；只有 gate 证明生产逻辑有缺陷时才修改生产代码。
- 非目标：改伤害、射程、武器平衡、背包 UI、关卡规模或玩家存档格式；不把预设测试库存当成真实箱子路径。
- 玩家持久数据不变，测试必须经隔离包装器运行；不得直接执行清档 smoke 脚本。

## 执行切片与验收门槛

1. 检查现有资源定义、初始化、拾取与重试语义，gate 通过正常的院子关卡/箱子/队员路径设置状态。
2. 建立基础资源情境：不提供手雷、地雷等可选补给时，核心计划仍有可完成的路线；测试须证明不存在默认装备或免费补弹造成的假阳性。
3. 建立可选补给情境：至少一种可选补给被真实拾取并归属明确，并通过权威战斗/事件结果证明其能支持基础情境之外的战术选择；不以 UI 数量或动画当作效果证据。
4. 消耗某队员的真实枪械弹药至零，验证最后一发只消耗一次，下一次射击被拒绝且没有隐式免费补给。
5. 通过真实失败→重试流程验证个人弹药/装备回到关卡基线，补给点重新生成且每类箱子恰好一次；重复拾取不叠加或复制库存。
6. gate 输出稳定成功标记，隔离包装器退出码为 0，记录实际 run ID 和 `PLAYER_DATA_UNCHANGED=1`。若只改 gate，跑 E、关联隔离栈与完整 smoke；若触及生产战斗/库存代码，按影响扩大回归至少包含 C3、C2、C1、B2、feel 与完整 smoke。

## 决策、风险与待人事项

- 不预先认定现有资源平衡有缺陷；“可选补给有实质作用”以可重复的权威结果证明。若当前场景无法构造公平对照，先报告证据缺口，不能调数值迎合测试。
- 每个枪械补给箱可能被最低装弹规则抬高到武器 `start_ammo`；gate 必须从真实运行态读取结果，避免把 crate `amount` 误作最终携弹量。
- 根据用户指示，当前只完成不依赖他人的本机/桌面任务。原 GPT 的逐切片复审未执行，待外部评审授权后补审；本计划不记录 GPT 新评审通过。
- vivo 真机、5 位非开发者试玩、旧 AudioTrack 根因分别依赖设备/受试者/设备日志，继续暂缓，不能由桌面门替代。

## M1-E 实现与桌面验证结果（2026-10-03）

源码 Draft PR #19：[`720511e`](https://github.com/hailinsu-create/ambush-loop/pull/19)，分支 `codex/m1-e-resource-budget`，以 D 分支为 base。新增独立 gate `m1_yard_resource_budget_gate.gd`，两个隔离 runner 均加入 allowlist；不改伤害、射程或武器数值。

隔离 run `ae585b42f63943728951d94cf864be64`，Godot 4.7.2，exit 0；成功标记 `M1_YARD_RESOURCE_BUDGET_OK real_crates=1 core_without_optional=1 ownership=1 ammo_exhaustion=1 grenade_area_effect=1 retry_reset=1 no_duplicate_stashes=1`，并有 `PLAYER_DATA_UNCHANGED=1`。从真实补给箱搜索/拾取 Kar98k 后，在没有任何投掷物时完成授权开火；打空弹匣后下一发被拒且无隐式补弹。真实手雷箱拾取后，投掷物模拟对范围内两名目标造成伤害并正确消耗一枚。两次真实失败→继续均核对个人资源和九类院子箱子恢复、未复制。

Gate 曾以失败 run `44cdff32e4aa444fb8bfa1cb86e3385d` 发现生产缺陷：`wipe_inventory()` 先清 `ammo_pool`，之后 `apply_weapon("knife")` 又将失败局枪械弹匣写回池（日志可见 `op2:knife:0:{"rifle":7}`）。已把最终清池移到换刀之后；最终 E gate 通过，重试库存打印为空。

库存生产改动后的共享回归也全部通过，均经隔离包装器：C3 `a521e991d4ad408595c9f001c10db493` exit 0；C2 `e137f59508ae4e44914f0e4a86feb260` exit 0；C1 `ecca8278838c4b3b82970bed8700a6c0` exit 0；B2 `c45de369fb3b4d2e94a129f839da6d4d` exit 0；feel `e78da09a55ef49ebb0b4a73b25e5d91e` exit 0；完整 smoke `796c8c24d6c343af8c914223b9e4e819` exit 0、六关全部胜利、`SMOKE_SLICE_COMPLETE`、`PLAYER_DATA_UNCHANGED=1`。全部仍是桌面自动化证据。

## 当前状态与下一步

E 代码与桌面验收通过，Draft PR #19 已推送。精确差异外部 GPT REVIEW 仍待授权，不把 Draft PR 当成已审或已合并。下一步执行 [M1-F 火力时机因果门](AMBUSH_M1_F_TIMING_CAUSALITY_PLAN_20261003.md)，然后按 D–I 总路线继续 G、H、I。Android/vivo、5 位非开发者试玩与设备依赖的 AudioTrack 根因仍暂缓；M1 整体未退出。
