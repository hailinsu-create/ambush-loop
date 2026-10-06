# M2.5/P1A：院子只读战术数据层执行记录

日期：2026-10-06
状态（2026-10-07 更新）：P1A 实现、冷却文案修正和 headless/Forward+ 定向桌面门通过；iteration 4 精确源码复审和六关全量回归仍待完成。用户要求跳过真机，本报告不宣称手机/触屏验收。

## 范围

把院子的射界、路线/高度样本、移动/掩体预览和目标状态整理为共享、只读查询，让 2D 与 3D 读取同一份权威结果。此切片不改变路径、射击、资源、战斗或结算规则；不实现 P1B 的完整战术地标/信息面板，也不算 M2.5 或 M2 完成。

- 分支：`codex/m25-p1a-tactical-data`
- 基线：`38b6d38`（`origin/codex/m2-f-operable-guide`）
- 实现提交：`c40a602485b530dda17da4e7a1886c634906a24d`
- 上一候选：`42315ba441a3b3aab2404e0f022f000560d45b11`
- 冷却文案跟进：`0e17f6f`，修改 presenter 与专项 gate；最终 headless 与 Forward+ 定向门均以此源码内容通过。

## 本次实现

1. 新增 `yard_tactical_display_data.gd`，暴露选中单位、路线/射界覆盖、移动预览、掩体预览和目标状态。数据查询复用 `OperatorUnit.in_fire_geometry`、现有路线/意图、掩体位置和网格 `tactical_revision`，不提交模拟状态。
2. 2D 覆盖样本改读共享数据；3D presenter 增加当前选中单位的名义射界、有限路线查询标记和固定信息卡，同时保留原地图拾取输入。
3. 将“名义武器范围扇形”明确标成 `weapon_envelope` 且 `line_of_sight_tested=false`；墙后目标仍由精确查询报 LOS blocked。目标状态用 `engagement_conditions_clear`，另列 `shot_cooldown_clear`，避免暗示此刻必能射击。
4. 缓存签名显式覆盖朝向、武器/弹药、近战、许可、射程、角度、冷却、位置、移动意图及掩体位置；路线适配器携带 authored `route_id`，不再由数组序号猜身份。
5. 专项 gate 加入缓存输入变更/复原、路线 ID、墙后目标、查询只读、3D 复用、地图输入穿透等断言。

## 验证结果

- Headless 专项：run `0ca6436080ad4c4182f734f4d6d4d755`，`execution_output` 85，Godot 4.7.2，退出 0，`PLAYER_DATA_UNCHANGED=1`。
- Forward+ 桌面渲染专项：run `7aec3544467d4446ac7a6a9729e7714b`，`execution_output` 86，Intel Iris Xe、1280×720，退出 0。截图已目视确认面板与底栏/引导不重叠，且标签明确为名义射界：`ambush_loop/build/ambush_test_runs/7aec3544467d4446ac7a6a9729e7714b/m25-p1a-screens/p1a-selected-fire-sector.png`。
- 前一候选 `42315ba` 的六关 smoke `a46802ebee5348169c7d061df3aee8b3` 已通过，但不是最终源码集成证据。
- 当前候选 `c40a602` 的全量桌面 smoke run `5a7b181cda9a4a11a0b3072308adc0c6` 使用隔离包装器运行中。尚未核实六关完成标记、引擎退出码与真实玩家数据未变，故总体回归状态为进行中。
- 冷却文案最终工作树 headless run `bc20d485470c450e8eda26343dddf91b` 与 Intel Iris Xe 1280×720 Forward+ 渲染 run `6ab81a0e19e64e468ed81852202ff400` 均退出 0，`PLAYER_DATA_UNCHANGED=1`；新增冷却态提示、恢复提示和权威状态无残留断言通过。渲染截图为 `ambush_loop/build/ambush_test_runs/6ab81a0e19e64e468ed81852202ff400/m25-p1a-screens/p1a-selected-fire-sector.png`。
- 当前 `c40a602` 全量桌面 smoke run `5a7b181cda9a4a11a0b3072308adc0c6` 仍在运行，最新进入 `touch_feel_0511`，没有最终六关完成标记或退出码；不可记作通过。
- 初次修正后曾有一次类型推断失败（`execution_output` 84）；显式标注动态 `Vector2` 类型后，最终候选专项测试通过。该历史失败保留，不计作最终源码通过。

## GPT 评审

原 GPT 规划评审 iteration 0 支持 M2.5/P1A 分层。精确候选 `42315ba` 的 iteration 2 源码审查指出四项问题：名义扇形不能冒称权威 LOS 查询；`fire_ready` 语义过强；缓存未直接纳入射程/角度等数据；路线 ID 不应由顺序推测。

上述四项均已在 `c40a602` 修正。对精确 `c40a602` 的 iteration 3 实际复审确认前三项风险已解决，另发现 3D 状态卡没有单独展示开火冷却。现已按建议修改：几何成立但冷却未清时显示“射击冷却中”，冷却清除后显示“交战条件满足”；gate 覆盖两种文案及查询后权威状态复原。最终工作树 headless 和 Forward+ 渲染门均通过；iteration 4 精确源码复审仍待发送/批准。原评审工作区 dirty checkout 与 `c2c_a619` 检查点未修改。

## 仍未完成

- iteration 4 精确源码复审结果及其要求的任何跟进。
- `c40a602` 候选 full smoke 完成与退出/存档隔离证据。
- P1B：预设朝向/拟议朝向覆盖、完整目标阻挡提示、补给与工具状态、入口/逃逸/许可地标，使主要战术准备信息在 3D 中完整可读。
- P2 触摸归属、双指镜头与就近确认流程；需真机核验按钮 dp/安全区与同一触摸不重复提交。
- P3 真实 Android 帧时、CPU/GPU、温度/降频和内存/节点平台测量。本轮按用户指示明确跳过真机，桌面 Vulkan 不构成 Android 性能验收。
- P4/P5 美术样板、默认 3D、可玩性与真人盲测，以及进入 M3 前的全部门槛。

## 下一步

先补跑冷却文案最终工作树 headless，完成当前 `c40a602` 全量桌面 smoke，提交并向原评审对话送审精确修正 SHA；若无新阻断，封存 P1A 证据并按计划推进 P1B。仍暂缓手机与真人项目，不把这次局部切片扩大成阶段完成声明。
