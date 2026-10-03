# M1-H 院子整关一致性门

日期：2026-10-03。承接 [D–I 桌面路线](AMBUSH_M1_D_TO_I_ROADMAP_20261002.md) 及 G 的真实双波方案。仅处理可自动验收的本机桌面部分；外部 GPT 新评审、Android/vivo、真人试玩与依赖设备的音频稳定性按用户要求暂搁。

## 目标

用新鲜隔离进程验证完整院子闭环：真实补给搜索/拾取 → 经现有关卡几何合法登台 → 部署与选中覆盖预览 → 正常警报冻结计划 → 模拟权威开火、伤害及资源消耗 → 两波结果 → 只读回放 → 真实逃逸失败 → 正常“继续”重试。并以同一初始计划比较 1× 与 2× 的权威结果；2× 只能缩短现实帧数，不得改写固定模拟步长、火力、伤害、资源或路线结算。

## 实施与证据

- 独立 gate `m1_yard_end_to_end_gate.gd`，只经隔离 runner 启动，加入 PowerShell/shell allowlist。
- 成功方案沿用 G 的院子 A 配置，真实搜索步枪/MG/侦察枪箱；高点队员从坡道登台；在警报前生成当前选中队员实际 coverage preview，并记录可见采样点。用真实敌人路线位置核对至少一项 preview 覆盖点；战斗中核对 fire target 处于实际武器有效几何，且真实 kill、ammo 消耗和队员生命值变化一致。
- 分别以 1× 与 2× 固定步进跑完两波。每波进入 WATCHING 后均显式设定测试倍速（生产逻辑会在下一波重置到 1×）。序列化并比较有序权威事件、terminal reason、各队员生命/弹药、敌人 kill/escape、波次数和资源变化。2× 另外必须用更少现实 frame 执行相同模拟 tick 数；不把动画帧或 wall-clock 精度当战斗结果。
- 在成功终局进入正式回放入口。逐项比对回放绑定的 BattleLog、事件与存档/战斗权威状态在回放前后不变；退出回放后仍是 WON，终局胜负与击杀/逃逸数相符。若事件时间线不能表达跨波数据，以失败证据记录并修正最小范围。
- 另起干净 yard 场景做可解释的主路覆盖失败（真实 flank 敌人逃逸），检查终局 `escape`；调用正式 Continue 后回到 SETUP，清空尝试库存/战斗态，并重新生成且不复制院子箱子。失败路径不人为写入事件、伤害、escape 或终局。
- 最终需 `M1_YARD_END_TO_END_OK`、隔离 wrapper exit 0、`PLAYER_DATA_UNCHANGED=1`，记录精确源码 SHA/run ID。仅新增 gate 时重跑 H 与受影响的 G/F/E/D 栈；生产代码变更时按影响补跑 C3/C2/C1/B2、feel 与完整 smoke。

## 不声称的内容

桌面 gate 不验证真机触控/性能/音频，不代替五位未参与开发者的盲测，也不构成外部 GPT 对新差异的批准。D–I 桌面全过后，M1 整体仍需逐项完成设备、人类评测及历史 AudioTrack 调查，并按既有 PR 依赖链审查/合并。

## M1-H 实现与桌面验证结果（2026-10-03）

源码 Draft PR #22：[`e2c98d2`](https://github.com/hailinsu-create/ambush-loop/pull/22)，分支 `codex/m1-h-end-to-end`，以 G 为 base。最终 Godot 4.7.2 隔离 run `07c27f6c70a74fd696a74b60b5d089d5`，exit 0，`PLAYER_DATA_UNCHANGED=1`。成功标记：`M1_YARD_END_TO_END_OK real_crates=1 legal_ramp=1 preview=1 authoritative_fire=1 ammo_damage=1 two_wave_win=1 speed_equivalent=1 replay_read_only=1 real_escape=1 real_retry=1`。

两次独立真实 yard 成功情境分别以 1×/2×跑完相同 1129 个固定模拟 tick；两案事件序列、11 次真实开火、三名敌人击杀/零逃逸、队员实测血量变化与弹药结余完全一致。1×使用 1129 个测试现实帧，2×使用 565 帧。每波切换后通过实际速度按钮处理器重新应用倍速。枪击目标通过现有武器几何，并与真实选中路线覆盖预览采样点相符。回放包含权威胜利终局且不会改变事件日志、队员资源或胜负状态。第三个独立场景从真实补给与警报流程进入 flank 逃逸失败，再调用正式 Continue；返回 SETUP，清理尝试库存/战斗状态并恢复唯一一组原始补给箱。

该 gate 仅增加测试代码和两个隔离 runner allowlist；未改生产游戏逻辑。H 已完成本机桌面验收，不代表外部 GPT 复审或 M1 全面通过。

## 当前状态与下一步

H 本地桌面门通过，Draft PR #22 已创建。继续执行 [M1-I 渲染可读性与方案差异证据](AMBUSH_M1_I_VISUAL_EVIDENCE_PLAN_20261003.md)。
