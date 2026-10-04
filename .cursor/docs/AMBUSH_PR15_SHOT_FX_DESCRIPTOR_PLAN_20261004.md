# PR15 FX-A1a 成功射击源接口

2026-10-04。[完整FX/A3计划](AMBUSH_PR15_SAME_CANDIDATE_FX_A3_PLAN_20261004.md)的首个可验证片。INITIAL a05/箭头d9c与六原件长轮使用冻结PCK、外部9aceae检查器；此片新源码不得混入该长轮或称FINAL同source。父端可同时独立只读INITIAL QA。

保持BattleLog schema2/playback2、原type/seq/event_id/attempt-wave/local-global-playback/统计/模拟。原fire事件在try_fire前，原returning_fire冷却也为true，先确认成功fired_shot/return_fired同步callback，再于原伤害调用返回后写独立`payload.fx` schema1。每次只挂显式原event引用和原log；上下文同步结束即清除，未知/迟到callback不得追挂最后event，更不得把旧event挂current run_id。武器/模型/位置/facing/原ActorPose采样在成功callback、原末弹自动repack/pistol替换之前保存；actual HP before/after/delta由原后端节点读，不计算名义伤害或补造命中。

fx字段保存原event身份、level、source/target group/id/pos、source clock domain=playback及原playback_tick、R5 revision、原visual_weapon与copy pose。lifecycle以后按frame.playback_tick/60决定，不用pose_clock或wall tween。old/missing/future/bad descriptor中性关闭；原bytes不升级。melee可记录成功/实际HP差，枪口火/tracer仅已知firearm，不把刀当枪。敌人枪仅原展示映射，仍无枪械玩法。目标group显式避免同actor_id的ops/enemies混淆。

先新Guard共享source test，实际原reference六关/原sim/APIs产生原事件，负向缺descriptor→新增同步源记录→固定H；原六关terminal/event count、装备/伤害/胜负继续核原基线。追加真实original weapon末弹同枪pack/pistol、false try_fire/cooldown/no-context/重复与后波身份边界，fixture授枪/直接tick明确不是native normal。source片不称3D画面/FX集成通过；随后A1b专门保存pose只读R5枪口采样、muzzle/tracer/actualhit finite池，ALERT pause、seek/repeat/source/reset/1x2x/LOD与旧schema1中性以及actualR图。six a05 raw和旧包不可写。

主集成单写main/replay/presenter/ViewState/测试/runtime loader；ArtSource/v2/build_yard_kit.py、GLB/Blender/atlas/生产manifest完全不改不重跑，R5/20bones/socket/3LOD/52语义保持。后FX-A2→A3实际raw指标/优化→FINAL同source全门/newnormal13/new6record3D→可追溯APK；耳听设备后置。不merge/生产/height/G，网页GPT PLAN/REVIEW unavailable。
