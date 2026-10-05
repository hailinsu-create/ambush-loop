# PR15 正常depot两波与自然radio接续

正式固定源码 **3b4976d1f4348d828a95bb627b2fb57c8501934d**，game tree **10ec85c1676785cd9a3938d9707db5c82b9f1ad1**；沿用railcut同一官方PCK，没有重建包、修改代码/规则/资产或重跑railcut。本片正常两波与续玩完成，**实际mine触发、新record 3D与结果文案正确性未全部通过**，不称全green。

起点是railcut185/0原WON/Continue/depot实际两教学页自然写出的cfg/settings，原字节SHA256 **050864ec68d3819eb4275bce4e106ba64299f6635b648cf736f0e68903d57b7c** / **5610ba32c76ec210bb5e3baf24ad8d17ad53702c14e9b05dd45cf0b3fd55042e**。复制到新guard UUID/XDG，原标题Continue进入depot SCOUT；没有合成解锁/seen、直接载关、位置/HP/ammo授予、reference/vacuum、快进或授胜。

| fixed3b49作者证据 | 实际结果及边界 |
| --- | --- |
| 原title Continue→原枪/手雷/mine→部署/原包UI→两波原ALERT暂停/恢复→SWEEP真实搜刮→原撤离/WON/Continue/handoff→radio两实际教学页 | **205/0，actual exit0，SCRIPT/ERROR0**；UUID **0e3e0cb247b24d10b68e620317b07c08**，**55**次真实XTest，1280×720/100%、Godot4.7.2、llvmpipe/Dummy。两波local **536/102**，global terminal **639**、**40事件**。 |
| 部署与战斗 | 原M1匣8/BAR20/Springfield6、手雷2/mine1，cover1/4/5面270/270/180、原UI包给MG。最终三人HP100/100/100、匣8/16/6；原四firearm kill清场。源码推导策略非陌生人试玩。 |
| 原携带mine铺设 | 原生走近/Tab地雷工具在cell7,11即(240,368)消耗mine1→0，raid_mines0→1；SCOUT合法、恢复部署、跨波未重新授雷。**原record没有mine触发事件，不能计“绊索抽中”通过。**末波原地面mine1搜刮到背包是独立loot，不是退款/触发。 |
| 原SWEEP搜刮 | W0一次走近同时ammo5/2、loot seq27/28，灰狼弹匣/池2→9；另一原生走近ammo2、seq29，9→11。W1原生走近mine1、seq38，携带mine0→1/背包新增，当前M1保持。四原loot，没有假补弹。 |
| 自动包 | 原MG分配成功，最终BAR16发/used=false，真实ammo_repacked观察为空；本关耗尽包未触发，保持待验，不扩大railcut自然Kar98k单分支结果。 |
| 原record只读metadata | **3460/0，actual exit0，SCRIPT/ERROR0**；独立UUID **07e2171652d342df93a1ac16499f7985**、空项目/guard/private XDG。原attempt/seq/唯一事件identity、单调全局/播放时间、wave offsets0/537、794原frame/schema2、阶段0→1→5→1→5→3、terminal639/playback terminal6065及源bytes不变。没有模拟或回放渲染；实际新record 3D待QA。 |
| 图及包 | **15**张native Window crop，全部1280×720/唯一ID/hash重核，**实际看11**；有界行为/UI证据，不代艺术/全FX/设备性能。沿用精确3b49 PCK23435080bytes/hashf7601be2a9a60fc1dda5d2c36bb880cc3ec67d335efbae2d1d05f4c1556c8d1e，原import/export/shell实际0/ERROR0，收据复制明示复用、未重导出，不算新增build验证。 |

命令：`AMBUSH_JOURNEY_START=resume AMBUSH_JOURNEY_SCOPE=depot bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-depot-3b49-godot first_visit_journey_test.gd --render`。精确wrapper/PCK/自然seed/UUID、原日志/实际exit、图hash/目检、只读metadata在[validation.json](evidence/20261004-pr15-depot-journey/run-3b49/validation.json) / [40文件清单](evidence/20261004-pr15-depot-journey/file-manifest.json)。一轮正式native无开发失败，无重复启动长任务；自己的Godot已退出，精确Xorg112/PID87857/原日志路径关闭actual0，stdout/log无损gzip/raw hash。

Native record attempt **f3bbcc8550a908a5e5740cfa16df238b**、794帧，raw **10866596 bytes** / SHA256 **ec232057b98e04262fd60f4e44933c7545f396ded83be68a05cdea26b4ebb3e0**；lossless [gzip](evidence/20261004-pr15-depot-journey/run-3b49/native-player-depot-record.bin.gz) SHA256 **d97ae1fd939cfea3beeb1a535fe2ce8c6844d52d098699b1e35a49bf2a04ea10**，与railcut记录分别保留。

## 新文案问题与下一段

原WON实际图统计高光和正文都写 **“2.2s 西暗道绊索抽中”**，但原record mine事件0、两波均由原枪火清场；铺设不等于抽中。`main.gd:_fill_result_stats`对depot仍直接读静态highlight_hook，`replay/payoff.gd:highlight_result_line`仅pump已有中性分支，depot仍静态回退。本轮未改生产，明确保留实际新文案缺陷；正常清波/续玩通过不代全结果正确，后续事实文案小片需有未触发/真实触发反例并单独固定验证，R/模拟/资产不动。

自然[radio存档manifest](evidence/20261004-pr15-depot-journey/run-3b49/ending-player-progress/manifest.json)：cfg **351 bytes** / SHA256 **83fe9ff9f602c229851615c760919f31f437f2ace37cd23e5adc244adee9955c**；settings **274 bytes** / SHA256 **9301c4e5a6be0d02e8d4274e92cad786790dce801903f7cbb330686757fefa0e**。自然cleared至depot，radio教学seen来自实际两页Next，campaign仍未complete；下一片原title Continue正常radio三波/末波搜刮/原CTA致谢。已有各固定源正常yard/warehouse/pump/railcut/depot各2波，**radio3待，不称同候选完整13波**。

可并行fixed3b49正常depot复验及此record只读3D换源/auto/seek/historyequip QA，独立副本/display/XDG、不写主集成；附带确认本轮事实文案缺陷，避免把测试205/0当全面无缺陷。父端b27 warehouse限定native1673/3D10429通过与pump030文案确证3/1、b892修复QA待保持单列。原warehouse84/pump38/高光47/railcut39证据字节hash全重核未改。

主集成单写及R5资产源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281接口不变，无新增制作件；制作源/GLB/atlas/Blender/生产manifest不动不重跑、WIP不全并。完整FX/A3/艺术/耳听0/45cue与0/6声景/同候选fullsmoke/可追溯APK及全计划后设备仍待。普通push Draft/Open/unmerged，不merge/生产/height/G；网页GPT PLAN/REVIEW unavailable。
