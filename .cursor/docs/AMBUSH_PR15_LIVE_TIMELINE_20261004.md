# PR15 本波路线时间条与payoff

生产修复 **f0208ebd25481c43e7c7ae5242d7e03c010c1cc5**，完整正式源码 **cdbed4c5949a50cd696b48d8b6d6becbb3adc5dd**。live观战条使用原pending_spawns的actor/route/delay/spawned与原local clock；SCOUT使用原raid当前波定义，caption明确第X/Y波。due但尚未执行生成的tick仍pending/echo，而不是提前0.05s消失。payoff按原事件中保存的attempt_id/wave_id筛选本波，保留原local tick，不重绑current run、去重或改写旧event_id/seq/timestamp/payload。HUD刷新与即时callback一致；SWEEP/REPLAY隐藏条清空dots/payoff并停止pulse。全关教学总表仍保留、明确标“全关预览（教学总表）”，不叠加本波实际事件时间。旧默认timeline_marks参数行为与缺spawned字段widget回退保留；未称本片做了完整旧原件兼容QA。

作者正式负向 **ee151102dd2af5ee7f4dc235a8a3bfde4685eac1 H1158/463 actual exit1/SCRIPT ERROR0/ERROR0**，实际命中本波dots/due提示、前波与foreign attempt同seq高光、SCOUT/教学总表及隐藏残留。六关13波×3D/旧2D矩阵明确赋phase/index/tick/spawned与synthetic events，**不是26实战**；另有原radio三波reference（授本关原匣枪、cover snap/direct tick/vacuum），原三次SWEEP、原暂停/seek/exit SCOUT。停在末波SWEEP，不抽离WON、不叫正常输入或新完整record3D验收。

固定正式 **H1159/0、R1164/0，各actual exit0/SCRIPT ERROR0/ERROR0**。H UUID55b44768b9054664b16fc6b99a1ae1fe，R UUID0f80e1c5c55442109c948f62bd34f9ce；包装器先私有UUID/XDG、guard通过。正式比negative多1项布局/ALERT1.4判据；不能冒称同总数。R多2个原生pause/resume与3个PNG保存检查。原事件fields与snapshot/sim clock在每个display判据/历史seek前后保持；saved reference bytes在原replay exit开始新attempt后保持，既有begin_attempt会清空active singleton log，这个原行为未改。

开发失败完整保留：8abb测试Variant推断parse actual1/SCRIPT ERROR2/ERROR1，无suite逻辑数；f020 H1158/0 actual0，但R1126/2 actual1/E0/S0在直接tick推进后按钮布局旧，XTest坐标954,673.5误中原abort；74cc H1159/0 actual0、R1127/2 actual1/E0/S0虽原HUD刷新却Container deferred sort未等帧，仍误中abort。两张FAILED原PNG都目检、原输入/退出与原因单列，不称视觉green、不把未写出的R reference bytes挪用旧H。最终只修测试HUD布局settle，生产f020不变；cdb原生坐标822,673.5确实pause/resume。

正式3张1280×720原始物理PNG全核hash、目检3：第3/3波paused t1.4，原echo id5/wave2/local30对应本波dot0.5，只有本波first_fire灰/local64；没有旧暗3.6/回5.2或前波payoff。history seek到846时源绑定/paused transport且无live条；原退出回新SCOUT第1/3，dot主0/0.6与flank0.4，无旧payoff。**截图仍有SCOUT IntelStore/fix_one静态“灯塔回波5.2s”提示**，已明确总表语境另审，不能借本条green称所有HUD/情报建议事实关闭。其他静态教学/chatter也不在本gate。

独立只读比较ee15与f020两份H reference：各51事件，剔除各次不同attempt_id/event_id后seq/wave/local/global/playback time/actors/targets/position/payload全部相同，bytes hash未变，两份terminal=-1/末波SWEEP。actual exit0/E0/S0另列，不并入1159/1164。正式无新PCK/APK；自己的Xorg91809准确SIGTERM actual0，三次R共享Xorg原日志无损gzip，不动其他display。

[全部实际命令/UUID/退出/范围](evidence/20261004-pr15-live-timeline/validation.json)、[hash清单](evidence/20261004-pr15-live-timeline/file-manifest.json)、[独立计划](AMBUSH_PR15_LIVE_TIMELINE_PLAN_20261004.md)。正式命令：

```bash
AMBUSH_TEST_SOURCE_SHA=cdbed4c5949a50cd696b48d8b6d6becbb3adc5dd bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 live_wave_timeline_test.gd --headless
DISPLAY=:112 AMBUSH_TEST_X11_DISPLAY=:112 LIBGL_ALWAYS_SOFTWARE=1 AMBUSH_TEST_SOURCE_SHA=cdbed4c5949a50cd696b48d8b6d6becbb3adc5dd bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-live-godot.sh live_wave_timeline_test.gd --render
```

父端新增独立QA结果只归其原fixed3b源（3b4976d1f4348d828a95bb627b2fb57c8501934d），不拼作者数：railcut normal1389/0、新record3D2839/0、作者原record3D10496/0，各actual0/E0/S0限定通过，metadata1932另列；不重开railcut已闭范围。depot normal1201/2 actual1/E0/S0保留两P2，新record3D2463/0、作者原record3D9539/0 actual0并不能取消失败，metadata1713另列。RESULT-1 minimal4/2与LOOT-1 minimal4/1各actual1，前者无mine却两处假高光，后者mine1误+1弹。a794中性结果、0bfe本波chip各原fixed作者H/R先前交付，父端独立QA仍进行，本片不代关闭。railcut真正repack证据继续原fixed3b，depot/radio仅铺雷无trigger保持。

下一独立片是BattleLog loot formatter：原depot mine事件f3bbcc8550a908a5e5740cfa16df238b:1:38、相邻frame mine0→1/ammo8保持已由作者只读检查（actual0独立源inspect），先自身negative→按kind/amount的文本最小修→固定H/R与原bytes保持；**不是inventory修复、不混a794gate**。之后按[同候选六关/FX/A3计划](AMBUSH_PR15_SAME_CANDIDATE_FX_A3_PLAN_20261004.md)继续固定单一candidate六关13正常波/新record3D、完整3D FX/艺术、A3云指标/优化回归、装备触控/旧2D、45cue六声景实际耳听与可追溯APK；均未完成，不提前设备/APK最终验收。llvmpipe/Dummy不代设备性能或耳听。

所有权/接口：唯一主集成作者保持main/HUD/input/presenter/ViewState/replay/loader/shared tests单写；R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义保持，无资产源/GLB/Blender/atlas/生产manifest制作diff、不跑build_yard_kit、不全并WIP。可并行独立包：父端安排fixed cdb live专项QA（readonly副本/独立XDG/display）、a794/0bfe既有QA、R5艺术只读审查；需要制作或FX新包先报父端，优先6.1-sol、不自行astra。Draft/Open不merge/生产/height/G，Notion由指定管理者。网页GPT PLAN/REVIEW unavailable。
