# PR15 接管、单写者边界与资产接口

日期：2026-10-02。接管基线：`b766da1c06b3312aac4f7120556d8cbd5d32b8d0`；PR15 为 Draft/Open，未合并。交接与实际远端已核对。执行顺序遵循 `AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md`；PR14 的完整详单和 inventory 来源为 `d69251be42d5f96c99da48a24a3923b62863f28f`。高度玩法 PR4–6/13/16 不在本实现范围。

## 所有权

| 负责人 | 独占范围 | 交付方式 |
| --- | --- | --- |
| 主集成代码作者（本任务） | `scripts/main.gd`、`scripts/presentation/`、`scripts/replay/`、公共输入接口、共享测试与隔离包装器、runtime manifest/loader、PR15 | 分别复现、修复、验证、提交；推送授权 PR 分支，不 merge |
| 资产工作者 `01a0fcac-42b5-7369-9ce6-aa223de910b0` | 角色制作源、角色/武器 GLB、Blender 输出、角色 atlas | 独立分支从 `f7c30f9` 修复；提交候选及验收证据；共享 manifest 改动仅提供候选 patch |
| Notion 管理工作者 | 项目页、工作包与验收状态 | 主集成者返回进度，不覆盖管理页 |

不编辑或重跑 `ArtSource/v2/build_yard_kit.py`，不编辑共享 atlas/角色 GLB/Blender 输出；不整体合并未验收 WIP。原作者已停止生产/测试并释放文件。资产制作与代码验证可在上述边界内独立进行；其他独立包需求向 dot 报告，由其安排。

## 资产交付接口

- 世界尺度：一格一米，Godot `+Y` 向上、`-Z` 向前；角色根在脚底地面中心，角色位移和朝向仅由模拟驱动。
- 保留候选资产 ID：三名 `operator_*`、四名 `enemy_*`、十枪和五工具。LOD 路径维持 `art/v2/models/<asset_id>_lod<n>.glb`；每件交付实际尺寸、三角面、surface 数和 SHA-256。
- 材质槽：yard 与 actor 图集分别命名；角色槽使用 `v2_actor_atlas`。actor Albedo/Normal/ORM 三张纹理路径、通道和尺寸必须明确，不隐式套用 yard 图集；发光槽单独声明。
- 共同骨架：交付实际 Godot 导入后的骨名、父子关系和根节点路径；所有角色/LOD 的骨架和 bind pose 一致。不得以脚本声明骨数代替导入检验。
- 动作：交付实际动画资源名、时长、循环标记及覆盖列表（idle/walk/run/aim/fire/pickup/death/crouch/crouch_walk/deploy/hit/haul）。全部为原地动作，无 root motion。声明尚未提供的动作，runtime 使用明确中性回退。
- 挂点：提交右手握持、左手辅助、武器枪口和工具挂点的实际节点或骨名及本地变换（position/rotation/scale）；附近/远及八方向握持、足底、枪口证据。
- 验收：无 invalid mesh 导出告警；源校验、重复导出、Godot 导入和动作验证分别有固定源、实际命令/退出码/完成标记。交付截图只是资产评审，战场接入由主集成者另测。
- manifest：独立候选台账可随资产交付；共享运行台账由主集成者验收后更新。未通过引擎/战場验证不能写为 integrated/verified。

## 首批代码切片与退出门

1. 多波回放：先用实际状态转换复现 tick 重置造成的混帧/未来事件；稳定 attempt/wave/seq 身份、全局回放时间或明确分段；旧单波记录保持兼容，缺失身份不绑定当前 `run_id`。
2. ALERT 装备冻结：复现 I 键、equip/pass/drop 与自动手雷策略入口；ALERT、暂停 ALERT、REPLAY 拒绝，SCOUT/SWEEP 合法；含真实 UI 信号和输入事件。
3. 3D 事件聚焦、Back 先关闭背包、触控取消生命周期；随后六关完整多波不变量与历史视觉字段。
4. 接收验收资产，再推进 A2 院子/HUD/事件、版本化全 3D 回放、A3 云端优化、A4 五关和完整 APK。每阶段继续云端运行、行为与视觉验证。

每个切片记录固定源码 SHA、命令、退出码、完成标记、已验/未验和下一步。样件/灰盒结果不能宣称战场集成或设备性能通过。全部计划制作/六关接入/云端验证完成后再讨论模拟器与真机，不在当前阶段启动。网页 GPT PLAN/REVIEW：unavailable。

## 当前状态

后续已迁入R1静态15件/30LOD并验证loader、实际渲染和空目录PCK，见 [静态切片](AMBUSH_PR15_STATIC_EQUIPMENT_20261002.md)。独立QA四项P2的反例已复现并由dot独立复验关闭，cc11bb0/71df99a修复与六关复验见 [复验修复](AMBUSH_PR15_REVIEW_FIXES_20261002.md)。历史队员HUD/手机时间轴已用a932/ed673ed作者验证，见 [固定源码/证据](AMBUSH_PR15_HISTORY_HUD_20261002.md)，dot独立复验关闭原头像/队员卡P2，新增C2Help提示泄漏以cf61721独立小片修复，30项反例16fail→0，HUD164/生命周期32退出0，见 [补片证据](AMBUSH_PR15_C2_HISTORY_HINT_20261002.md)，已由dot独立复验关闭。R2未落地即由最新R3替代：18dc381采用00b2708/8a1fbe9候选原字节及新台账，角色4362、静态273、PCK329退出0，见 [R3技术接收/战场计划](AMBUSH_PR15_R3_RUNTIME_20261002.md)。e7b8cfa已接R3实战/历史骨骼主路径，231战場、84039合同、10296六关及其余回归通过，见 [主路径报告](AMBUSH_PR15_R3_BATTLE_20261002.md)，环境建筑仍灰盒，不用旧R1/R2 hash验证新资产。355ea89独立音频45 WAV／原import已采用，4a00a91真实play／混音405及云端回归通过，见 [音频报告](AMBUSH_PR15_AUDIO_RUNTIME_20261002.md)，耳听仍0/45、0/6；另提出 [环境资产独立包](AMBUSH_PR15_ENVIRONMENT_INTERFACE_20261002.md) 由dot另派生产。完整资产与六关成品视觉仍待完成。

已核对交接、PR15、WIP 与 PR14 详单。独立集成工作树为 `/workspace/ambush-pr15`；本环境 Godot 4.7.2 路径为 `/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64`，版本输出 `4.7.2.stable.official.ed1daf0bf`。首批回放/装备审计已实际复现和独立修复，后续 Back/手势取消/3D 事件聚焦也已施工；具体固定源码和证据见 [runtime 报告](AMBUSH_PR15_RUNTIME_REPORT_20261002.md)。完整资产与六关 3D 接入待完成。

继承入口：[PR14 完整执行详单](https://github.com/hailinsu-create/ambush-loop/blob/d69251be42d5f96c99da48a24a3923b62863f28f/.cursor/docs/AMBUSH_ASSET_EXECUTION_PLAN_20261002.md) · [资产 inventory](https://github.com/hailinsu-create/ambush-loop/blob/d69251be42d5f96c99da48a24a3923b62863f28f/.cursor/docs/evidence/asset-audit-20261002/inventory.json)。已读取；后者为 c1aaf27 原资产静态盘点，不作为当前新资产集成验收。
