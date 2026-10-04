# PR15 FX-A1a 成功射击源接口报告

2026-10-04。正式candidate **1838951ef269c07da5d8062f547cee41b03bd374**；生产逻辑提交 **e0d392f61badcd8f209d84b7c4674a239910ceda**，183仅追加边界test/入口、生产module/main相同。实施[源接口计划](AMBUSH_PR15_SHOT_FX_DESCRIPTOR_PLAN_20261004.md)，可交父端独立QA，不等待完整FX/A3/APK。本片**source-only，没有3D FX池/画面实现或通过声明**，INITIAL原件consumer_d9c长轮仍是另固定PCK/source。

原fire仍先log再原try_fire，return_fired仍在原take_damage前log；没有更换统计/事件类型或模拟调用。新增ShotFxRecording一份同步上下文，显式原log/event/射手/目标/level/attempt/wave；成功原fired_shot/return_fired才确认，callback中在原伤害/末弹pack/pistol之前复制R5 model/visual_weapon/facing/pos与原ActorPose。原try_fire/resolve_return_fire返回后读actual HP before/after/delta，追加`payload.fx` schema1，再清全部节点/log/context引用。没有扫最后同tick事件、没有异步callback或current run_id重绑旧event。source groups ops/enemies显式分开，敌枪仍原展示映射，没有枪械玩法。刀可保存成功/HP差但projectile=false。没有BattleLog/playback格式升级、没有升级/重写旧raw。

fx接口：schema1/confirmed、原level/event_id/attempt/wave/seq、source/target group/id/原pos、clock_domain=playback/原clock_tick/playback_schema、原visual_model/weapon/actor_asset_revision/animation_schema/原pose、projectile、hp_before/hp_after/damage。lifecycle消费者后续只能用绑定frame.playback_tick，不能混pose_clock/walltime；旧/缺/坏/future描述符中性与finite池将在A1b实现和测试，当前尚未宣称完成。描述符增加会改变新保存bytes；原参考terminal/count与type-local-tick fingerprint保持，不冒称全payload/snapshot/bytes相等。

## 实际隔离命令与结果

官方4.7.2，全部Guard在autoload前通过、fresh UUID/XDG。原负source **f3a906fef21e3f0970851b0e615f94346202466a** H **4783/103 actual1 E0/S0** 保留；103 FAIL是新增descriptor合同缺失，其他原reference断言无失败，不称旧生产故障。first fixed e0 H **5607/0 actual0 E0/S0** 单列。

正式同183源码实际两门：

```bash
AMBUSH_TEST_SOURCE_SHA=1838951ef269c07da5d8062f547cee41b03bd374 \
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_source_test.gd --headless

AMBUSH_TEST_SOURCE_SHA=1838951ef269c07da5d8062f547cee41b03bd374 \
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_boundary_test.gd --headless
```

- source UUID **5add92bbe16241689fe293afea86376f**：**5607/0 actual0 E0/S0**。原六关参考共103 shot/return events，所有descriptor身份/原枪/pose/源clock/group/actual HP差核验，原terminal/count：yard1283/34、warehouse1191/67、pump907/34、railcut719/38、depot957/35、radio1413/51；与f3a的原type/local-tick fingerprint逐关相同。
- boundary UUID **57d0c5567eb542939dcc4d3f62f07c6b**：**45/0 actual0 E0/S0**。实际原backend ordinary/末弹同枪pack/自动pistol/致死/刀；原ammo与HP变化、source枪始终是末弹前的Kar98k、同枪pack refill、致死负HP差不误clamp、五case每个原event字段/payload移除新增fx后等于PRE-copy。false original try不注入fx/不改ammo-CD-HP/event；无上下文stray callback不能追挂last event；原wave改变/foreign log下实际成功call也不能重绑旧event。敌冷却aim=true但无新shot/damage，真实MG无遮蔽/原cover伤害差等于实测HP变化且不同nominal14，groups正确。

source/reference与边界均明确授枪/snap/directtick/vacuum/直接API fixtures，非native正常玩家旅程；有3D节点构造但headless不代渲染图。上述两门独立不相加当全计划green。[实际log/exit/report/fixtures/hash](evidence/20261004-pr15-shot-fx-source/file-manifest.json)、[原参考比较范围](evidence/20261004-pr15-shot-fx-source/original-reference-comparison.json)。没有本片新native旅程/老2D/完整smoke/最终全门验证。完整smoke54/62及8906 bounded0仍各原范围保留。

下一A1b只读R5 muzzle marker+保存原pose取样、muzzle/tracer/真实HP差impact有限池；严格source-clock/phase与old/missing/future中性、ALERT pause/seek/repeat/换源/reset/1x2x/LOD、实际R图/行为不变，不能从现body换后枪补旧shot。A2→A3实际指标/优化→FINAL同source全门/newnormal13/new6record3D→可追溯APK继续待。INITIAL正常a05/六newrecord只读消费另列，不拼183 FX-A1a成FINAL。

所有权接口：main/replay/sharedtests唯一主集成作者；R5source29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义保持；制作源/build_yard_kit/GLB/Blender/atlas/生产asset manifest未编辑/重跑，未全并WIP。父端旧closed scope不重开；Draft普通push，不merge/生产/height/G；耳听设备后置，网页GPT PLAN/REVIEW unavailable。

2026-10-04 来源边界后续替代：父端发现source183未校验真实shooter ID；作者50b exact负H3/1 actual1，fixed9f最小TYPE_INT/group-specific身份门后H3/0、合法boundary45/0、六关source5607/0均actual0 E0/S0，详[独立修复报告](AMBUSH_PR15_SHOT_FX_SHOOTER_20261004.md)。本页183原计数保留，只属原覆盖，不能称曾覆盖此错配；新9f也不代3D池/独立FX QA或FINAL。
