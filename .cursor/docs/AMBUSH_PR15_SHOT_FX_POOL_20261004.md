# PR15 有限3D枪火池固定交付

2026-10-04。固定源码 **b563000daa8ae0a5ce559d95a45078e3666f2aaf**，Godot工程tree **b6c6b0083d5e7877ef6eeeaea76d4d33a91d6017**。继承成功源A1a正式183/e0、reader577与可选bool修复866，不把它们的计数相加。此片完成有界作者验证，独立FX运行QA及最终全战场接受待验。

`presenter_3d`持有`ShotFxPool`；仅消费保存的已知FX1、连续playback2、原attempt/wave/seq/event_id、R5/animation3、实际HP差。保存原模型/枪/pose通过单hidden ActorVisual采样原muzzle，检查三个setter、实际身份和有限socket，失败关闭；不使用post-repack/pistol或当前目标补旧事件。固定采样LOD0，六类实际成功源的LOD0/1/2 muzzle差均为0m；此结果不是全部十枪/全部姿态LOD验收。

固定12槽、36 MeshInstance3D、三共享低面mesh和三material，全部关闭shadow；省电最多4条且禁tracer。缓存最多48条纯值，source scope变化清除，hash只预筛、完整descriptor相等才复用。flash3/tracer6/actual-hit9 ticks来自原playback age；暂停保持、seek重复重建可见集、SCOUT/SWEEP/终局清除。命中球以保存二维目标映射1.05m躯干锚点显示，只认actual damage>0；它是命中cue，未引入3D碰撞/射高/新伤害。刀、false attack和enemy cooldown中性。

| 固定b563正式运行 | UUID | 实际结果 |
| --- | --- | --- |
| shot_fx_pool_test --headless | 766e978ffc72452384c5c9222ec239c6 | 224/0、actual exit0、ERROR0/SCRIPT0 |
| shot_fx_pool_test --render | c715c73a92b44f2793d3a36546996df7 | 236/0、actual exit0、ERROR0/SCRIPT0；12 Window PNG核hash/看12 |
| shot_fx_visible_test --render | 03f2ea0ec9a14169b0e45bcb17ce0a47 | 47/0、actual exit0、ERROR0/SCRIPT0；16 Window PNG核hash/看16 |

全部走`run_isolated_test.sh`且Guard先于autoload通过。实际官方引擎4.7.2.stable.official.ed1daf0bf，二进制SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`；OpenGL4.5 / Mesa25.0.7-2+deb13u1 / llvmpipe LLVM19.1.7，1280×720、scale1、Dummy audio。无XTest/native输入、无耳听。H/R总耗时106.946/139.401秒是整个测试耗时，不是战场帧性能。

实际覆盖：原授枪/位置/HP/预log/direct attack fixtures中的ordinary、末弹pack、自动pistol仍旧Kar98k、lethal负HP、knife、enemy MG/cover实际伤害、false-hold/cooldown；单原muzzle采样与保存目标/身份/实际HP、ALERT暂停30 draw frames、真实focus生命周期函数、原REPLAY入口/1×/2×/暂停30帧/前后重复seek、当前foreign实际pistol枪击不污染原bound历史；同身份不同source/位置及枪+pose的明确保存descriptor fixtures；缺marker、溢出、零damage、阶段和版本边界；20条同clock容量fixture最新12/省电4、60条cache48、180次repeat固定nodes/resources；原abort清sampler model、原return-to-title释放pool/one sampler/36 nodes及mesh/material weakrefs。

真实旧schema1原件SHA `1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12` 与INITIAL a05六个原native raw均实际只读加载、首尾原枪击中性、内存与文件hash未升级。旧兼容消费期间current有真实foreign pistol枪击。旧六原件精确SHA在test的INITIAL表及report；归producer a05，不能称此次新六关或新record。

较远128px真实LOS/原成功攻击，在yaw0/35/125/215/305同frame on/off Window像素对照；muzzle ROI改变129/139/132/144/133像素，独立tracer中点26/35/29/37/32，命中区94/104/101/96/66。age0/2/5/8/9/0图确认闪光、弹道、命中各自消退及恢复；这一帧fixture不代自然连续战斗或全武器艺术接受。

所有旧失败保留：544 planned interface H1/1 actual1 E0/S0；fa2测试静态类型解析actual1、未入Guard；c517开发H218/0另列。cd607 H224/3 actual1 E1/S0中，finite坐标1e38使派生length inf并触发RenderingServer非finite transform；f953派生geometry门先于任何mesh可见/transform写入。另两失败是测试foreign reset清了同saved log，fixture先detach current新BattleLog，生产reset不改。f953 H224/R236实际0、12图看12只归该固定源；565可见性R47/1 actual1 E0/S0证实yaw0小impact像素0；b563只把hit cue直径0.16→0.44m且随保存age微扩，深度遮挡/锚点/事件/伤害保持，正式47/0另列。两无效开发启动（缺/usr/bin/time actual127、目录typo的自有R engine actual143）不算suite结果，日志/退出/10已生成图及精确PID终止理由保全。

复验命令如下，独立QA必须使用自己的display/XDG/output。测试包装器自行创建fresh隔离UUID：

```bash
export AMBUSH_TEST_SOURCE_SHA=b563000daa8ae0a5ce559d95a45078e3666f2aaf
export AMBUSH_LEGACY_RECORD_FIXTURE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin
export AMBUSH_INITIAL_RECORD_ROOT=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_pool_test.gd --headless
DISPLAY=:118 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_pool_test.gd --render
DISPLAY=:118 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_visible_test.gd --render
```

外部executor可从`.cursor/docs/evidence/20261004-pr15-unified-baseline/native-all/native-player-<id>-record.bin.gz`解压原bytes到独立/tmp目录并将INITIAL_RECORD_ROOT指向它；不能重建/改字段冒称同原件。旧schema1原bin已入Git。记录metadata、命令、日志、actual exits、固定reader/pool/presenter/ViewState/tests/wrappers、28正式图及旧失败见[evidence manifest](evidence/20261004-pr15-shot-fx-pool/manifest.json)。自有Xorg :118 PID104937在全部自有测试自然exit0、撤场和图核验后精确argv SIGTERM，session97699实际close0；没有停止其他worker。

资产接口保持R5 source29749157c5db064bfea626c3ed9d75d9a1791ece、accepted20骨/socket/3LOD/52语义。主集成单写新presentation、presenter/ViewState、运行loader/共享测试；制作源、GLB/Blender/atlas/生产manifest无修改、无重跑。可并行固定b563只读FX运行QA或28真实帧的艺术评审；需要制作改动时仅由资产作者在独立分支生成并提交验收过的包。

未验：全部十枪/全部姿态与自然加载驻留峰值、自然重试换关全路径、六关最终正常13波/new sixrecord/full1×、最新完整smoke/统一全门、A2烟/尘/爆炸、A3持续指标/优化、APK/设备。短repeat节点稳定不代泄漏长期或安卓FPS。下一[A2源/池计划](AMBUSH_PR15_TOOL_FX_PLAN_20261004.md)，再A3实际量测/FINAL统一回归/可追溯APK。父端f0ed context独立QA已限定关闭、不重开。网页GPT PLAN/REVIEW unavailable；Draft不merge、不生产、不混height/G，耳听/设备在全部计划后。
