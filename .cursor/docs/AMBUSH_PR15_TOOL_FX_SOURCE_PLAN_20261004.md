# PR15 A2 确认爆炸源接口独立计划

2026-10-04，父端射手P2作者9f修复已交20f、flight源53/H119/R128已交fec。此源接口尚未实现/实证。主集成单写main/VisualSnapshot/ViewState/回放/shared tests，不动制作源/GLB/Blender/atlas/生产manifest。

来源边界：真实RaidGrenade._detonate先_done=true再同步detonated；只绑定此确认信号，投掷/缺节点/消失/kill都不生成blast。创建时注册稳定attempt-wide tool_id、kind/variant/原owner ID、creation wave；爆炸时冻结实际level/attempt/wave/playback2 tick/phase/位置/半径，creation-wave与confirmation-wave分别保存，不能将旧事实绑当前run_id。登记只保存弱tool link/纯值source，original object snapshot ID不作tool identity。登记上限64，recent48、180ticks，未知/失效/foreign log/重发信号fail-closed且不影响原攻击。没有BattleLog新事件/seq或修改旧mine payload。

grenade保持原_on_grenade_boom loops、selected传伤害归因、实际enemy.apply_fire与op.take_damage，各次调用前后保存actual HP差/受害group-id-pos；不使用名义damage代actual cover/MG差，不clamp overkill。无victim实际爆炸仍可保存空victim列表。descriptor提交须在原_check_win末尾前，保持source callback的phase/clock，即使死者信号已同步进入SWEEP或mark_terminal。

mine为独立kind：创建时登记owner，原sim_check仍决定actual first victim/伤害。调用前只读收集HP，返回真实victim后检查spent/原mine事件canonical identity/位置/受害actor ID，关联原event_id与seq；实际mine事件actor是受害enemy而target=-1，不能作为owner或枪口。Tripwire尚不在本source范围，不伪装库存mine。

主作者只读调用链：enemy.apply_fire→kill→_on_enemy_died→_check_win可能同步进入SWEEP并原HP+10；op.take_damage→died→wipe可同步advance_phase_boundary/mark_terminal，但终局snapshot在_finish_sim_tick pending_result后记录。原grenade callback还要继续原friendly loops，必须精确各调用前后取HP且保留原顺序。mine sim_check→_trip→真实damage/dead→原triggered→返回victim→main原mine event，原_finish_sim_tick随后snapshot。_extract_win独立命令路径提前mark_terminal+snapshot；工具command_update先_tick_raid_grenades、之后每.1s保存frame。以上为源码核对，未实证全部终局排序；6.1-sol第二审计因capacity失败，无其运行结论。

保存接口：VisualSnapshot独立tool_fx_schema=1/tool_fx近期纯值列表，descriptor schema1/confirmed/tool_id/effect_id/seq、kind/variant、born level/attempt/wave/owner、原确认clock_domain=playback/playback_schema2/clock_tick/phase/position/radius/victims。mine另explicit original_event identity，grenade不伪造BattleLog event_id。ViewState从bound snapshot复制本列表、原source opaque token用于cache invalidation，旧缺/future明确neutral；本片只保存源，没有3D blast/smoke/dust视觉通过。

先Guard实际负向接口测试证明原攻击/HP/ammo/count但缺descriptor，再最小source实现；固定源实际无victim/bounce/友伤cover-MG/overkill、多工具同tick、spent单次、SCOUT/SWEEP/ALERT pause、terminal snapshot、跨wave/foreign-log/old字节及参考campaign不变。未实证项目保持待验。后source reader/有界blast烟尘池与实际Window图，再A3/FINAL/APK。Draft不merge/生产/height/G，耳听/设备后置，网页GPT PLAN/REVIEW unavailable。
