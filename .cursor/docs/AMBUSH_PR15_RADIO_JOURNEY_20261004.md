# PR15 正常radio三波与自然全关进度

正式固定源码 **3b4976d1f4348d828a95bb627b2fb57c8501934d**，game tree **10ec85c1676785cd9a3938d9707db5c82b9f1ad1**；沿用railcut/depot精确官方PCK，没有新增游戏代码、R/模拟/资产修改或重导出。正常三波与原致谢入口完成；**结果文案、当前波提示及新record 3D仍有待项，不称全green或同候选六关smoke**。

起点是depot205/0原WON/Continue/radio实际两页教学自然写出的cfg/settings，原字节SHA256 **83fe9ff9f602c229851615c760919f31f437f2ace37cd23e5adc244adee9955c** / **9301c4e5a6be0d02e8d4274e92cad786790dce801903f7cbb330686757fefa0e**。复制到新guard UUID/XDG，原标题Continue进入radio SCOUT；没有合成解锁/seen、直接载关、改位置/HP/ammo、授枪/自造敌、reference/vacuum、快进或授胜。策略从原匣/cover/routes推导，不是陌生人试玩。

| fixed3b49作者证据 | 实际结果及范围 |
| --- | --- |
| 原title Continue→原装备/携带雷/部署/包UI→三波原ALERT暂停/恢复→各波SWEEP走近搜刮/归位→原撤离/WON→原CTA致谢入口 | **210/0，actual exit0，SCRIPT/ERROR0**；UUID **2025624ae15544f190287bbaefe3a304**，**57**次真实XTest，1280×720/100%、Godot4.7.2、llvmpipe/Dummy。三波local **591/123/129**、global terminal **845**、**57事件**。 |
| 原部署/战斗 | Kar98k匣7/MG42原匣50/Springfield6、手雷2/mine1，cover1/4/5面270/90/270，原包给MG。最终三人HP100/100/100、匣4/50/4、原五firearm kill。第三波只生成echo id5，原spawn local tick30、global746/seq47；该波三fire都来自灰狼，MG没有开火。三波清场不代“铁砧等5.2s回波”策略验证。 |
| 原mine与耗尽边界 | SCOUT原工具铺cell7,11，携带mine1→0、raidmine0→1；**原record mine/trip事件0**，实际触雷未验。MG50发/包used=false、ammo_repacked观察为空，本关耗尽不计通过；不扩大railcut真实Kar98k单分支耗尽结果。 |
| 原SWEEP五loot | W0走近先ammo2/5、seq35/36，灰狼匣/池1→8；另走近ammo2/seq37，8→10。W1decoy1/seq46入背包，当前Kar不变。W2radio_part1/seq55按原拾取逻辑将背包decoy1→2，当前Kar不变；不声称自造电台修复行为或赠资源。 |
| 原record只读metadata | **3766/0，actual exit0，SCRIPT/ERROR0**；独立UUID **6dc561b25f234c51b7df93d422b65fc5**、空项目/guard/private XDG。原attempt/seq/唯一identity、单调全局/播放时间、wave offsets0/592/716、841原frame/schema2、阶段0→1→5→1→5→1→5→3、terminal845/playback6344与源bytes不变。仅元数据，没有模拟或回放渲染；实际新record 3D待QA。 |
| 原事件事实另读 | 独立只读UUID **1ecc7e3810b748acbd224f7f06ebf17b**、actual exit0/ERROR0；保存原spawn/fire/kill/mine/trip数组和源hash未变。确认末波echo已入场、三fire角色1、mine/trip0；不相加到metadata3766计数，不代3D播放。 |
| 原图/致谢边界 | **16**张native Window crop全部1280×720/唯一ID/hash核验，**实际看10**，覆盖SCOUT/铺雷、三SWEEP/搜刮、末波暂停ALERT、WON。原native CTA后`credits_overlay.is_open()`断言通过，但原3b49 driver没有保存致谢打开后的crop、独立open字段或滚动记录，**不计本轮致谢页面视觉/全文滚动验收**；不拿旧reference credits专项替代它。 |
| 官方包 | 复用精确3b49 PCK23435080bytes/hashf7601be2a9a60fc1dda5d2c36bb880cc3ec67d335efbae2d1d05f4c1556c8d1e；原import/export/shell实际0/ERROR0收据保留，未重导出，不算新增构建验证，不是APK/设备性能。 |

命令：`AMBUSH_JOURNEY_START=resume AMBUSH_JOURNEY_SCOPE=radio bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-radio-3b49-godot first_visit_journey_test.gd --render`。精确wrapper/source/PCK/自然seed/UUID、原日志/actual exit、图/包与只读metadata/事件事实另读见[validation.json](evidence/20261004-pr15-radio-journey/run-3b49/validation.json) / [46文件hash清单](evidence/20261004-pr15-radio-journey/file-manifest.json)。一轮正式native，无失败开发轮次或重复启动长任务；自己的Godot均退出，精确Xorg112/PID88383/原日志路径关闭actual0，stdout/log均无损gzip/raw hash。

Native record attempt **dd6ac61197ad62d444517e1a34f728e9**、841帧；raw **12372912 bytes** / SHA256 **e584a89d86b60c2931e5d947b3ab2dba416801a4ea499f5b5685507ef8d7128f**；lossless [gzip](evidence/20261004-pr15-radio-journey/run-3b49/native-player-radio-record.bin.gz) SHA256 **07b99d9a1997005c1b18c7437d7c567d461c394a9911388057321c1ec16fc2f3**。与旧schema1/reference及本轮railcut/depot原记录分别保留。

## 两项真实展示问题

1. 原WON统计和正文仍写 **“5.2s 灯塔回波，绊索抽中”**，但原mine/trip0、MG未开火、末波2.15s清场。`main.gd:_fill_result_stats`和`replay/payoff.gd:highlight_result_line`对radio仍取静态教学hook，与depot未触雷却写抽中同类。原图/数据保全，本片未改生产，后续事实文案小片独立测试提交。
2. 末波暂停ALERT实际t1.4s图显示 **“下一波：暗道还有2.2s”**；该波唯一echo敌早在tick30入场，没有暗道待生成。源码`main.gd:_next_wave_info`遍历`level.spawn_schedule`关卡总表，而原`pending_spawns`/模拟来自当前wave。实际图、源和原spawn数组共同证实展示错用总表；后续独立修提示来源，不改原时刻表、R、tick或事件身份。其他读取总表的展示点先审计，不把推测算复现。

## 进度及接续

自然[完成存档manifest](evidence/20261004-pr15-radio-journey/run-3b49/ending-player-progress/manifest.json)：cfg **392 bytes** / SHA256 **bd858eed12b54c69ef40eb3b6e4d97a5ed9fb2fe74b72bdf79f39199f92a3d55**；settings **274 bytes** / SHA256 **9301c4e5a6be0d02e8d4274e92cad786790dce801903f7cbb330686757fefa0e**。实际cfg `complete=true`、cleared六关、loop1；这是自然正常进度链，不是授全关或新一轮存档。

正常玩家各固定源现有yard d7两波、warehouse b27两波、pump030两波、railcut/depot/radio3b49共七波，分别保留原输入/存档接续，**全13波链已有分段证据，尚非同一最终候选从fresh开始完整smoke**。本轮制作源/GLB/atlas/Blender/生产manifest、R及原游戏代码不改；主集成单写、R5资产源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281接口保持，无新增制作件。

父端最新QA单列：固定b27 warehouse限定native1673/0、作者原件实际3D10429/0，各actual0/ERROR0。固定030 pump native **1110/1、actual1、E0/S0**，唯一已知事实文案；正常两波/新record回放/railcut教学到达，作者原件独立3D绑定 **6716/0、actual0**。固定b892文案旧反例 **3/0**、独立三结局 **47/0**均actual0/E0/S0，原生滚动FAILED卷宗实际看到“泵站尚未封锁”，相关文案P2独立关闭；**030旧失败不改全绿，不把不同SHA当同candidate**。作者b892原R41的FAILED句未视觉覆盖边界仍保留，父端新增覆盖独立列；父端artifact未在本工作区读取。

可并行独立包：fixed3b49后三关正常输入及各自原record实际3D换源/auto/seek/历史equip/真实repack表现QA，独立副本/display/XDG、不写主集成；确认上述两项展示缺陷。下一按[展示事实修复计划](AMBUSH_PR15_FACTUAL_DISPLAY_PLAN_20261004.md)分别修结果高光/当前波提示，随后完整FX/艺术、A3云预算/优化与回归、修复版全装备触控/旧2D、耳听45cue/六声景、同最终候选fullsmoke/可追溯APK；设备仍在全计划之后。llvmpipe/Dummy不代设备FPS/耳听，网页GPT PLAN/REVIEW unavailable；普通push Draft、不merge/生产/height/G。
