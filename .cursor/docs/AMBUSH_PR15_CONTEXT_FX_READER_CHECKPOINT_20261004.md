# PR15 P2交付与FX-A1b.1安全checkpoint

2026-10-04。父端要求先有界交固定context修复，不能等待全FX/A3。本checkpoint结束前已完成的所有自有engine均自然退出，自有Xorg:116/117均精确关闭actual0；没有要接续poll的engine/session，不启动新pool长轮。Draft普通push/远端核对后由父端继续同任务，非全计划完成。

## 可现在独立QA

P2正式source **f0ed44311775fa87ee63ebb911c7b11e12e65ab1** / production3d30b1309ebcf09a01d17e344b4d900942b67bca / evidence **e3797c5994bacec56a858c580960fb0a44877aeb**：[完整命令/原负例/8正式图与83文件收据](AMBUSH_PR15_ESCAPE_CONTEXT_BOUNDARY_20261004.md)。原877保存raw只读，负H3/2、有效R18/4actual1 E0/S0；fixed同source H57/R82、原radio referenceH70/R73各0actual0 E0/S0。保存level wave_count上界、明确event2/playback2间隔≥local，不硬等原927/928；真实第三波0.5→15.9/retry/源attempt保持。父端旧877 min3/2及R49/2失败保留。fcf静态教学limited29/0/R40/0/四图看两包单列，不补额外hash、不重开旧scope。

FX-A1a可独立QA：source **1838951ef269c07da5d8062f547cee41b03bd374** / evidence **f01298fd0c58c98bf7b7451d0b989b62665c686a**：[报告](AMBUSH_PR15_SHOT_FX_SOURCE_20261004.md)。sourceH5607/0、boundary45/0各actual0 E0/S0，103真实reference shot descriptor、原末弹pack/pistol/actual damage/false/scope；仅metadata，不是3D FX池。

INITIAL新六record长轮已经原session自然完成，不再“运行中”：producer **a05fa959093ef5b6733466091a04fbb46647f97b** / consumer **d9c67256545a227c78bf5c3264818b8ad86b2c78** / evidence **a323c3ae19dea041d69d65f197777502c170e934**：[报告](AMBUSH_PR15_NATIVE_RECORD3D_20261004.md)。固定原官方PCK/9aceae external harness **29976/0actual0 E0/S0 records6**；whole2x每关0→原terminal，76seek/78native，56物理图hash/看6、原raw/live/sim保持。完整1x未跑。121文件hash/bytes/tracked复核通过，原a05 arrow4404/1/diag4140/2与smoke54/62继续保留，不能拼FINAL。

## 当前新增纯读取小包

FX-A1b.1 source **577550a48cb7de2cd90b6f6ef670b401c8f4e910**，game tree见[收据](evidence/20261004-pr15-shot-fx-frame/receipt.json)。新 `presentation/shot_fx_frame.gd` + ViewState独立opt-in字段，没有接入presenter池，main/source FX/原BattleLog/R5未改。

原Guard实际命令从 `/workspace/ambush-pr15`，环境 `AMBUSH_TEST_SOURCE_SHA=577550a48cb7de2cd90b6f6ef670b401c8f4e910`：

```bash
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_frame_test.gd --headless
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 visual_snapshot_test.gd --headless
```

实际reader **87/0 actual0 E0/S0 UUID5b435d3d808b436aab3854f1340366bd**；现有visual/history seam **130/0 actual0 E0/S0 UUID3b506829bd344b7e901bd90ce47cd4c6**。只有一个实际原backend Kar98k成功fixture（授枪/位置/直接API明确），另是显式坏数据/版本/time/identity矩阵。0/2/5/8ticks合法、9或未来中性；按playback age、不借pose/local clocks或当前gun/targets，重复读取/原log/ammo/HP/sim保持；旧缺fx不升级。**没有3D池、muzzle采样或FX窗口/完整六关/native/fullrecord/FINAL/A3验收**。

负015 source接口不存在H1/1actual1 E0/S0，说明planned feature缺失，不归新生产bug；development433/532两次H83/5actual1 E0/S0保留。后者实际frame token **-9223371953941772632**：Godot RefCounted ID为合法负整数，原正数假设误拒绝全部正例。577改成opaque非零typed integer，补event/descriptor identity类型及保存wave_count界限，不把token当事实event identity。两fail日志/代码/JSON与fixed/seam证据完整封存 [目录](evidence/20261004-pr15-shot-fx-frame/)，不删或当green。

只读FX审计未见明确正常路径阻塞，但提出一个**尚未实际复现**的strict bad-field缺口：可选 `pose.preserve_upper_world_basis` 存在时应TYPE_BOOL，现reader未校验而ActorVisual会bool转换。下一片先以非bool明确负例复现，再拒绝；缺字段保持默认true，合法true/false保留。这个接口不完整点明确待验，不将87/0称完整FX合同已关。审计只读未跑引擎，不能当独立runtime QA。

## 直接接续步骤与所有权

1. 从本checkpoint HEAD正常接续，不重启/重跑已闭P2/旧QA。先仅新增optional bool负例→最小gate→固定H，再A1b.2有限池。参见[已推计划](AMBUSH_PR15_SHOT_FX_FRAME_POOL_PLAN_20261004.md)。
2. 原保存pose取样体逐步检查 `set_asset` / `mount_item` / `sample_layers` 返回，再校验当前model/revision/weapon/finite socket；失败中性关闭，不能读先前模型/枪口。缓存最多48纯值，加入实际LOD或明确固定LOD，以及原descriptor equality；token+eventID+hash不能代完整相等。12标准/4省电slot、无wall tween，补1x/2x/pause/seek/source/原legacy与实际R再称该包通过。
3. A1b→A2工具/爆炸/烟/脚尘→A3实际指标/优化→最终固定source全门/fullsmoke/新normal13/新六record→可追溯APK。耳听/设备后置。尚未实施pool或开始FINAL长轮。

安全并行6.1-sol APK只读报告已收：[封存报告](evidence/20261004-pr15-shot-fx-frame/apk-toolchain-readonly-report.md)。当前所查路径无JDK17/匹配4.7.2 templates/SDK36 build-tools36；Java21在。历史A0 manifest不是当前APK/已装工具；现 `export_a0_preview.py` 指向preview_boot，最终须独立full-game staging导出与完整source/template/SDK/JDK/embedded payload/signature公开指纹/actual exit收据。此包没有安装/导出/钥匙/设备操作。缺工具链是后续APK需处理事项，当前P2/FX source工作无阻。

资产边界不变：主集成main/input/HUD/presenter/ViewState/replay/runtime-loader/shared tests唯一作者；制作工作者独立ArtSource/v2/build_yard_kit.py、atlas、角色GLB/Blender及生产asset manifest，未重跑或全并f7c30。R5 source29749157c5db064bfea626c3ed9d75d9a1791ece / deliveryebedb829e3263abbeb6dd266905f24a3869fa281 /20骨/socket/3LOD/52语义保持。P2、A1a可现在分别独立QA；后FX实际帧给艺术评审，A3固定candidate给独立量测。Draft/Open/未merge，未发布/混height/G，网页GPT PLAN/REVIEW unavailable。
