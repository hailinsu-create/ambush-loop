# PR15 正常接续warehouse：两波、SWEEP补给与埋雷

正式固定source **b27ff62e34e4a822c278f737e7a088a0ff48e5ea**，game tree **7757913c5f598e813cbcb46971f120b7339802b5**。本片只改test-only原生旅程driver和窄范围进度复制助手；相对89267636，`ambush_loop`仅`first_visit_journey_test.gd`、`seed_player_progress.py`变化，生产main/input/R/loader/表现/资产均无diff。普通推送与GitHub HEAD核对结果由最终交付回执为准。PR15仍Draft，不merge/生产/混height/G。

原真实d7 yard旅程135/0产生的两份ConfigFile按原字节归档，再复制到新UUID的XDG；没有合成解锁、record_win、直接载关、授枪/改位置/HP/ammo、reference/vacuum、跳胜或快进模拟。原title Continue进入warehouse；原三枪匣kar98k7/BAR20/springfield6和手雷、原掩体1/3/5、键盘转向、原弹药包给MG、F入伏、两次原警报/暂停/自然清波，SWEEP走近掉落与原匣补给/工具埋雷，最后原撤离→WON→Continue→下一夜CTA→pump首次两页教学。1280×720/100%，独占自有Xorg112/XTest、原main.tscn，以官方4.7.2 PCK隔离staging启用已有a0_preview；原工程/导出配置未改。source-derived策略不是陌生人试玩。

## 实际验证

| 证据 | 实际结果与范围 |
| --- | --- |
| 固定b27原生旅程 | **270/0**，actual exit0，SCRIPT ERROR0 / engine ERROR0；UUID **3ac52362bbc54ae3bfa20fad84ad3a75**，124次XTest，14张native Window crop独立图名与hash，全部核hash/实际看8。 |
| 实际波次 | warehouse wave0 **339tick/18event**，wave1 **863tick/58event**；最终global terminal **1203**、**62事件**。两个波次均由原ALERT自然抵达SWEEP，原extract写入pump进度。MG最终HP88，未声称全员满血。 |
| SWEEP掉落 | 第一波一次原生走近同时领取4/32 ammo，原loot事件各自seq18/19；步枪弹匣5→10、弹池5→41。第二波继续实际走近领取2/2 ammo及4 rifle_ammo，各自seq58/59/60，共五条原loot事件。 |
| 原匣补给/地雷 | 原ammo8匣使MG pool20→28（弹匣仍20）；原mine1匣后，走到邻格/原ToolButton选择/实际整数空地点击，mine1→0、raid_mines0→1。SWEEP新雷保留到下一波，原mine事件wave1 local356/global696、seq39，敌2触发。原弹药包仅验证分配，`ammo_pack_used=false`，未证明耗尽后自动补弹被触发。 |
| 真实录制只读元数据检查 | **4574/0**、actual exit0/SCRIPT0/ERROR0，独立UUID **7495fa1479c1465992c36b8b57a93b54**，无gameplay autoload的空项目+guard/private XDG。核事件attempt/seq/唯一存储identity、全局/播放单调时间、固定波偏移0/340、1034个原frame_seq/schema2、阶段0→1→5→1→5→3、实际下一波mine及末端/原字节不变。仅检查原序列化数据，不播放模拟、不验新录制3D回放画面。 |
| 官方导入/导出包 | 固定b27 import/export/外层shell实际均exit0，SCRIPT/ERROR0。PCK **23425820 bytes**、SHA256 **006a8b91d62a6da63b5bb8bea4a7367837eef645c4cdaa95459cfbb590b19509**，不是APK/设备验收。 |

精确命令、环境、UUID、原日志/实际exit、包、输入、图hash与目检清单在[validation.json](evidence/20261004-pr15-remaining-journey/run-b27/validation.json)；原生主命令：`AMBUSH_JOURNEY_START=resume AMBUSH_JOURNEY_SCOPE=warehouse bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-remaining-b27-godot first_visit_journey_test.gd --render`。wrapper、包导入/导出argv与收据一并归档。源d7进度hash为cfg **02c3b271f6e96a32296417eff2133e38158a7ab2b6d02becce2e8df91f0e5683**、settings **09bc2383fdcf558236d9310adec90ef4695b6c267f33221fe599025590ed2ef6**，原run文件再次比对未变；新run启动时也检查复制字节。

实际Native schema2录制：attempt **2a53f1c40c480b06c4b12c24c9416bbb**，1034帧、playback terminal **7796**；原二进制 **15311216 bytes**、SHA256 **63fccaa28ed9ff9f90729f458ebf695f05bac57cac9be0d58ec28c54ef17a08c**，以[native-player-warehouse-record.bin.gz](evidence/20261004-pr15-remaining-journey/run-b27/native-player-warehouse-record.bin.gz) lossless保存。区别于旧reference六源和schema1原件，不混称同一战斗或把source-native元数据检查说成3D自动播放通过。

## 保全的开发轮次

b467原生45/1、exit1/ERROR0：warehouse掩体1投影被原铁砧身体挡住，实际picker op:2正确选人；driver改用原镜头按钮露出目标。bfc155/2、exit1/ERROR0：第一波实际339/18与真实搜刮/原ammo补给抵达；原MG rotate_by限制8°，180→0只能落近4°，旧uniform15/精确0判据错误；mine浮点预览空地、实际整数(697,527)落在自己的body边界，正确op:1选择重置工具。e37改用实际发送像素及1px余量、原8/15°最近可达朝向，实际成功埋雷；整轮250/1、exit1/ERROR0停在恢复部署时，因为driver又点了未移动夜枭脚下已占据pad中心，13个镜头角均正确op:3，不是已关闭cover回归。b27保留未移动的原pad，仅恢复实际走出的两人；连续A/D使用同一XTest，等待两次真实process_frame处理，无modal fade、无直接改朝向/模拟快进。三轮失败原日志/截图/包/存档均保留并排除正式通过，开发13图只实际看5，不与正式14图相加。

父端独立fixed d7已限定关闭cover5 P2，无新P1/P2：native142/H76/实际窗口86三次exit0/ERROR0、16图核/看9、943 tracked文件逐字节一致；与作者d7 135/H25/R38单列。本片未重开/重跑已关cover、title、auto/text；父端独立artifact未在此工作区读取。网页GPT PLAN/REVIEW unavailable。

## 接续与边界

正常主线目前实际yard2波（fixed d7）+warehouse2波（fixed b27）分别有源与原生证据；**pump/railcut/depot/radio其余9波仍待**，不是同一候选完整六关13波通过。下一片扩展通用resume起始关，以[ending-player-progress/manifest.json](evidence/20261004-pr15-remaining-journey/run-b27/ending-player-progress/manifest.json)中自然写出的pump存档接原title Continue，继续SWEEP补给和正常输入。只清掉yard/warehouse，未预解锁后面四关。

可独立并行包：固定b27的正常warehouse复验，以及此Native record的只读3D历史绑定/阶段/事件/自动回放复验；使用独立副本/私有display/XDG，不编辑主集成文件。本片无需新资产件，资产接口继续固定R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281。制作源/GLB/atlas/Blender/生产manifest归资产作者，不改不重跑、WIP不全并。完整3D FX、A3云预算/优化、艺术验收、耳听0/45 cue与0/6声景、同候选最终fullsmoke/可追溯APK仍待；云llvmpipe/Dummy不代设备FPS/耳听。全计划后设备顺序保持，无环境阻碍。

本轮自己的Godot已实际全部退出；只关闭精确匹配自有Xorg112/PID79513/日志路径的服务，actual exit0。Xorg原日志lossless gzip、原hash及配置归档；全部证据manifest另列。
