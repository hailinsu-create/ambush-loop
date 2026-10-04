# PR15 A2工具、烟、尘接续计划

2026-10-04，承接A1b固定b563有界作者验证。flight单位子片已实证并修复，确认blast保存接口已生产d75、正式640/ac验证；烟尘爆炸池仍未实现或运行。主集成唯一代码写者，制作资源所有权不变；不改变SCOUT→ALERT→SWEEP、BattleLog原events/seq/event_id/统计、伤害或手雷归因玩法。

只读6.1-sol源审计（f953、无引擎/编辑）与主作者核对：RaidGrenade._flight本身为0–1进度，presenter又除flight_duration；先以实际原sim_step/保存snapshot/3D位置做负向，证实后最小修展示单位并测试0/中段/落地/弹跳/旧记录。不能把源码推导记为已复现。

手雷原detonated(pos,radius,damage)是实际爆炸确认，当前无BattleLog爆炸事件，bounce后的pos已偏移8,6；投掷成功、飞行snapshot消失或kill都不能代爆炸。库存mine原actor是受害enemy、target=-1、position雷位，不是放置者；Tripwire直接kill另种语义。现有grenade damage传实时selected，FX新增原owner只在创建时保存，保持原实际伤害归因。

第二独立slice设计tool_fx schema1描述/稳定tool/effect identity/保存attempt-wave-level/playback2时钟、actual爆炸位置/radius/variant及每个原victim HP前后。优先由VisualSnapshot独立字段保存确认后描述，保持BattleLog事件数量/seq；mine可关联原mine event_id，grenade不得伪造战斗event_id。工具ID在创建时稳定，不依赖尚未出现的capture object ID。先证明实际callback到snapshot/终局的同步顺序，再选择有限最近描述的保存与回放接口；不凭名义damage倒推实际HP，不用current selected或后波live对象补旧记录。

第三独立slice实现有限blast/smoke池；烟明确由已确认blast或已保存成功muzzle源确定性派生，不虚构smoke工具。寿命仅绑定playback时钟，支持实际推进工具的SCOUT/SWEEP及ALERT，phase/terminal取消契约显式。旧/缺/未知descriptor中性。所有派生geometry finite，固定节点/共享资源/省电容量/满池最新优先，原暂停/seek/source/reset/退出无残留。

第四独立slice为表现型移动尘：从保存moving/stance/sprint与pose时钟确定性采样，明示不是原落脚事件；不借当前位置冒称历史足迹，不用原2D wall-delta粒子。若需要持久地面尾迹，先保存原落脚位置脉冲。每slice都有Guard actual负向→fixed H/R/实际Window目检及source/HP/ammo/sim/record不变，native正常路径留最终候选。

实际源正反例待验：无victim的真实爆炸、bounce后落点、友伤/掩体/过杀、多工具同tick、mine victim归因与spent单次、command期及ALERT暂停、terminal snapshot、跨wave/seek/source、旧原件中性、全部派生finite、资源撤场。每片固定SHA/actual exits/hash及未验范围；样本不代战场集成，库存在不代耳听，云llvmpipe不代安卓30/60 FPS。

A2之后A3先收同环境六关各phase/方向/实际峰值的raw frame intervals、draw/primitives/纹理/RAM/shader warmup/FX驻留，再预算与单片优化；最后统一fixed source全门/fullsmoke、正常fresh六关13波、六新原件实际3D全段1×/2×、再可追溯APK。工具链缺项后置，不阻代码；全部计划之后才安排设备。可并行b563固定只读FX QA/28实帧艺术评审，优先6.1-sol；不自行派astra，不让其写主文件或制作输出。网页GPT PLAN/REVIEW unavailable。

已完成有界flight子片：[fixed53报告](AMBUSH_PR15_GRENADE_FLIGHT_20261004.md)。负102 H119/R128各15fail actual1→53同原测试各0actual0 E0/S0、9正式Window图核/看9；仅一行presentation单位修复，原投掷/库存/轨迹/bounce/四authentic old midflight及六raw hashes不改。下一仍先确认blast source与终局snapshot时序、稳定tool/effect ID/actual victim HP，再有界烟尘池；不把flight片当blast或FINAL。

确认源片已完成[正式报告](AMBUSH_PR15_TOOL_FX_SOURCE_20261004.md)：640 H46/参考5607/冻结66、ac边界263各0actual0 E0/S0，生产blob一致；原2a21/4和5fa SCRIPT ERROR无效轮/640坏矩阵control不足全部保留。下一按[reader/池计划](AMBUSH_PR15_TOOL_FX_FRAME_POOL_PLAN_20261004.md)实际实现与render，source-only不算视觉/FINAL/A3。
