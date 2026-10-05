# PR15 A2 实际确认爆炸源

2026-10-04。生产实现固定 `d75b045a786337909ce5abe9074e91fad84085b5`；新增边界测试并只修测试调用参数后，正式源/参考/冻结候选 `640a9840bb89012306017e5c01ea4e0452daba57`，边界正向control补强候选 `ac543c528c1844b0d2d4710db89bdccf0ad79b0b`。三者四个生产文件字节一致；本片没有 blast/smoke/dust 3D reader 或渲染池，不作为该视觉阶段通过。

实际 RaidGrenade 创建时登记弱工具引用、原 owner、稳定 attempt-wide tool_id、creation wave/clock；原同步 detonated 信号 bind 实际工具，在原伤害前固定实际确认 wave/playback2 clock/phase/position/radius，原伤害 loops 后保存各 victim 实际 HP 差及独立 effect seq。无 victim 的实际爆炸也记录；投掷、飞行、消失、kill 不作确认。原 selected 的伤害归因保持。原库存 mine 仍由 sim_check 决定实际 victim，记录原 mine event_id/seq/受害 actor/-1 target；不新增 BattleLog.events、不修改原 mine payload 或统计。

VisualSnapshot 保持 visual_schema1，新增独立 tool_fx_schema1 与近期纯值列表。registry64/recent48/window180 playback ticks；完成移除 weak link，跨 wave 取消 recent。实际未爆工具可跨原 next-wave API；创建 wave 与确认 wave 分开保存，run_id 增长不重绑旧事实。同 attempt 换实际 log 对象也取消 registry。ViewState 只从当前选中/bound snapshot 复制 adjunct，版本/容器不合则中性；逐 descriptor 严格 reader 留后片。

原特殊时序保持：最后敌人死亡可先同步进入 SWEEP 并给队员 +10 HP，然后执行 grenade 友伤，因此按每次真实 damage 调用前后取 HP。Operator 原死亡将 HP=1 clamp 到0，保存实际差1而非名义过杀量；敌方原负 HP 仍保存。真实 wipe 确认源 clock49/phaseALERT1，随后 terminal50，最后快照50保存完成 source 与三名实际 victim。没有为了 presentation 改原回血、过杀、终端或快照顺序。

负向与实际运行结果：

| 固定 source / suite | checks/failures | actual exit | ERROR / SCRIPT ERROR | 性质 |
| --- | --- | --- | --- | --- |
| 2a72a0d planned source H | 21/4 | 1 | 0/0 | 已封原负：四处尚缺 descriptor，原 HP/库存/统计通过；未重跑 |
| d75b045 development source H | 46/0 | 0 | 0/0 | 首轮生产开发，不代正式 |
| 5fa1b85 boundary H | 249/0 | 0 | 0/1 | 无效：夹具漏传 setup 的两个参数；部分 coroutine 跳过，不能计通过 |
| 640a984 original source H | 46/0 | 0 | 0/0 | 正式实际空爆/cover-MG/过杀/mine/wipe |
| 640a984 source boundary H | 261/0 | 0 | 0/0 | core边界完成；八坏字段夹具缺合法transport control，不计该门验收 |
| ac543c5 source boundary H | 263/0 | 0 | 0/0 | 正式完整边界，含合法one-frame control及typed坏版本/容器 |
| 640a984 six reference source H | 5607/0 | 0 | 0/0 | 六关原reference shots/原终局与事件数量保持 |
| 640a984 equipment freeze H | 66/0 | 0 | 0/0 | 原装备phase冻结回归 |

计数从 planned21 到46是 descriptor 出现后深入字段分支实际执行，并非同21断言集合。boundary249是 SCRIPT ERROR 后部分执行的无效计数；修参数后的261实际跑完，但坏字段矩阵未先证明复制记录合法；ac543将一帧复制fixture frame_seq置0，并加合法control和1.0错typed版本后263/0才接受该矩阵。640源46/参考5607/冻结66均自然结束且E0/S0；ac仅改测试，生产blob逐项一致证据保存，未将测试SHA冒写成640新运行。所有原日志、真实 exits、JSON、固定代码与审计归因保留于 [manifest](evidence/20261004-pr15-tool-fx-source/manifest.json)。

正式实际命令（官方4.7.2，fresh UUID/XDG，Guard先于autoload）：

```bash
AMBUSH_TEST_SOURCE_SHA=640a9840bb89012306017e5c01ea4e0452daba57 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 tool_fx_source_test.gd --headless
AMBUSH_INITIAL_RECORD_ROOT=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75 AMBUSH_LEGACY_RECORD_FIXTURE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin AMBUSH_TEST_SOURCE_SHA=ac543c528c1844b0d2d4710db89bdccf0ad79b0b bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 tool_fx_source_boundary_test.gd --headless
AMBUSH_TEST_SOURCE_SHA=640a9840bb89012306017e5c01ea4e0452daba57 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_source_test.gd --headless
AMBUSH_TEST_SOURCE_SHA=640a9840bb89012306017e5c01ea4e0452daba57 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 equipment_freeze_test.gd --headless
```

boundary中66次投掷均为实际原 helper/fuse/bounce，同 tick64登记/48保留/seq16–63，容量满的其余两次原攻击仍发生；结算释放后下一真实工具 seq64。180/181保存窗以明确原 clock API 夹具测，不称吞吐/FPS。未爆工具经原 next-wave API 继续确认，但夹具未自然清该波；同 attempt/foreign log 拒绝重绑且原记录 bytes 保持。SCOUT/SWEEP 原 command _process 推进工具而不推进 sim.tick；暂停 ALERT 原 toggle +30显式 _process 保持 fuse/flight/HP/log/adjunct，解除后实际确认。

原 REPLAY/terminal seek 读到 immutable 保存 victims；实际 foreign current blast 不能替换 bound history。六种 corrupt version 与三种坏容器为明确复制字段夹具，只验结构门。六份 a05 INITIAL 原件与一份原 schema1 只读，首末 frame 中性、文件/内存 bytes 均不升级；这些原件不含 tool_fx。当前未验逐 descriptor 坏字段/几何 finite/实际3D视觉，不能因容器门通过宣称 reader 完整。

6.1-sol固定 d75 只读复审未发现正常调用链明确 P1/P2，确认上述终端顺序、owner/weaklink/mine身份及历史 seam；没有独立运行，不算 QA 验收。首轮 development46与正式640 source46/reference5607/freeze66、ac boundary263均是作者实际运行。

父端新归因：9f actor P2 同字节原1833/1→9f3/0，补副作用10/0 actual0 E0/S0，合法A metadata与A ammo3→2/HP100→52/唯一伤害前callback及B ammo/错误eventbytes保持，限定关闭；正常玩家错配可达仍未证。父端核963files/旧20packs一致。作者45/5607仅作者运行。b563 pool与53 flight尚待独立 render，不借本源片通过。

未验与下一步：逐字段严格 reader、有限 blast/smoke/dust 真 render/窗口目检、自然长驻留/全部工具与十枪、A3指标/优化、FINAL同 source fullsmoke/正常六关13波/六新原件1×2×完整3D、可追溯APK。原 HP/库存/统计保持的显式 backend/reference夹具不代正常战场集成或设备性能。R5/ArtSource/GLB/Blender/atlas/production manifest 未改未重跑；无 merge/生产/height/G，耳听设备后置。

正式UUID：640 source a2bb003905934f02a5e2412683dca66a、reference9f0e4bd2e1d64dd7af44e6cddb3b352f、freeze f568de9b728740ad8f61f5701d03d8d1；ac boundary d8c20c2ad619491686dc4734a523657c。参考原值yard1283/34、warehouse1191/67、pump907/34、railcut719/38、depot957/35、radio1413/51，103实际shot描述不变。本作者所有本片engine已自然结束，无待poll或Xorg；下一池实现/实际render另固定源，不升级旧负向或旧记录。
