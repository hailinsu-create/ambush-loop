# PR15 R5 真实工具动作切片 — 2026-10-02

## 固定范围与所有权

生产代码源 `c5ec8ff7b668ba86d9c9a305ecec0bca0072e9c7`；测试UID/独立兼容脚本提交 `8b7a38c90a796ab42d7aec691c0aa69f801fc307`。R5角色源 `29749157c5db064bfea626c3ed9d75d9a1791ece`、独立交付 `ebedb829e3263abbeb6dd266905f24a3869fa281`。只复制验收过的21角色GLB，runtime台账自行更新；未全并候选分支，未编辑或重跑生产生成器/Blender/atlas。

基线PR15 `651f72bf650512b7291fe6a40715a87a5ce3ea10`。独立只读glTF gate检查51GLB、3atlas：21角色×旧52=1092完整键集合一致，骨架/rest/inverse bind/几何/法线/UV/权重/材质/原挂点语义不变，只增12可选动作；30装备GLB及3atlas逐字节相同，当前51GLB与immutable候选字节一致。复核脚本与helper hash在固定证据目录；不以生产者样本测试替代主路径。

## 已实现的实际行为

格式3/R5保留格式2/R4和格式1/R3读取，六旧R3枪仍单独保留。旧52动作的语义不变，旧记录不借用新工具事件。未知版本仍用既有中性回落。

- C2成功knock_out后记录刀击；真实OperatorUnit.try_fire的刀melee signal也记录。原即时伤害、拾取掉落、技能冷却不延迟；当前装备不改写，仅暂时显示刀。
- 手雷成功consume/setup/append后记录，自动ALERT和手动命令共用成功入口；原距离上限/.18s初次飞行/fuse/友伤策略不改。诱饵成功consume/即时生成后记录，远点放置仍无新增靠近或可达规则。
- 三动作从`.5s`即时命中/释放窗口播放余段：不借动画预备阶段推迟玩法。刀保留actual hand.R/grip/tip；雷/诱饵已生成后手部不再挂重复道具。站立静止诱饵用作者全身下蹲；其它动作和已有蹲姿用12骨上身遮罩，8骨腰腿/步态保留。目标方向只改变显示上身或静止放置朝向，不改实际facing/位置。
- 纯副本保留schema、独立SCOUT scope、原attempt/wave/seq、event_id、相位/时钟域、武器stamp、实际target和BattleLog seq floor。pre-ALERT attempt为空的原事件不会挂到后来的run_id；跨phase/wave/attempt/装备、死亡/搜索/搬运取消；移动取消静止诱饵。后续真实射击按原BattleLog身份取消，稀疏快照之间不延续旧工具姿势，未来/外波射击无权取消过去事件。
- 命令姿态用原command clock，ALERT用全局simulation clock与原2x；暂停/后台保持，历史用复制时钟和snapshot delta，current run_id/装备/位置/时钟污染不能改变历史骨姿。

## 正式证据与剩余门

正式命令/退出码/run_id/日志/截图SHA见同目录的固定validation.json；图像是Godot Compatibility/Mesa llvmpipe实际framebuffer。尚无成品艺术批准或手机FPS结论。测试库存、目标摆位、手动REPLAY binder是显式fixture；正常ALERT自动投雷快照来自原_sim_tick/add_snapshot，不能宣传为完整玩家流程或六关逐波工具视觉矩阵。

尸体grab/drag/release与body ID/来源/朝向/肩掌配对仍下一独立切片；此片未应用新death_prone，也未改变旧haul的弹药包含义。R5动作里的20cm已内置在局部髋骨，不再在runtime叠加；本片只验证工具动作零额外root/world位移，不能称尸体接触/offset已验收。

随后持续推进完整HUD/FX、连续SWEEP时间轴与FAILED/abort终局、A3预算和最终回归/APK。环境原50capture全wave0（yard10/其余各8），13wave仅运行/reference fixture覆盖；六关逐波视觉矩阵待补。软件draw172–424/primitives53826–168748，部分超过暂定200draw警戒，进入实际LOD/batch及导入动画内存优化；不推断设备性能。完整smoke最新仍7d34867固定副本。耳听0/45、0/6；全部生产和云端工作之后再安排模拟器/真机。外部GPT PLAN/REVIEW unavailable。


父端651环境独立复验无新增P1/P2，156项真实abort→FAILED→REPLAY与污染seek通过（归651源）；新质量问题desktop HUD遮战场与radio yaw345整根天线消失列后续必修。288帧软件静态旋转median190–388ms列A3云端初筛，不推手机性能。


同帧装备补片：`cdbf86b`在真实C2刀击后、同一帧连续两个成功背包装备回调得到4/1fail；`d53e54f525687543e51080eb8482663a5058c443`在成功装备回调立即cancel utility，正式4/0、完整工具1034/0（6capture）、ALERT/暂停ALERT/REPLAY拒绝与SCOUT/SWEEP合法装备66/0。这一行只擦除表现状态，不改装备结果或模拟事件。

测试适配：`abc6aed123abe37ea1b4f694e6ea4285fd234193`独立检查各尝试的utility scope唯一、所有波保存同一scope，再如原BattleLog身份字段一样仅移除跨尝试随机scope进行30/60FPS/2x比较。六关原测试10296/6fail与合同84039/2fail保留；适配后10332/0与84042/0，原终局tick/事件不变。`f687ea080b95593d8f01bdc23ce18447bfa69aa8`仅更新静态资源测试的旧R4硬编码来源；旧301/1fail日志保留，正式render333/0。各源区别和实际字节等价范围见validation.json，不能把所有旧run归为最新同源。


| 固定源码/测试片 | 实际退出0结果 |
| --- | --- |
| 8b7a38c（运行字节继承c5，仅补test UID） | 工具1030/0、枪族90配置7681/0、战场231/0、clock29/0、历史HUD164/0、生命周期32/0、音频405/0 |
| abc6aed（仅身份测试适配） | 六关13wave运行10332/0、合同84042/0、七角色×三LOD×64clip21818/0、冻结66/0、timeline66/0 |
| d53e54f（成功装备回调一行表现取消） | 同帧换枪4/0、完整工具1034/0及6张当前真帧、冻结66/0 |
| f687ea0（仅静态来源断言更新） | 静态render333/0；新PCK空物理工程1764/0，含64clip、六关两档组装与45 PCM |

PCK固定f687源25,584,156 bytes，SHA256`7e81d6fa6a22cbb5e02ac7e29ff955b07ee3a3ba3b42260f6e56161d4bc0c54e`，`/tmp/pr15-r5-tools-runtime.pck`；导出0、probe0（run2146158ee901451095a4df0245a12f84），45原import恢复且项目运行树diff退出0。技术包，不是APK。混合固定源均逐条标注，未将8b/abc整套结果称在d53之后全部重跑。

[证据台账](evidence/20261002-pr15-r5-runtime/validation.json)及同目录实际日志/六真帧已保存；六张当前图片已逐张看过，仍能看到已列的HUD拥挤/重复栏，不能称最终艺术或无遮挡体验通过。两轮开发夹具的错误日志保留；第二轮退出0但有SCRIPT ERROR明确不计正式通过，之后增加mask与两个交互阶段全部结束断言。
