# PR15 正常pump两波：SWEEP与自然railcut接续

正式固定source **03063234d40792f3b71454a0d3d2ca07905ae2b2**，game tree **8d82125d2c2d56b5603a9e5bb529484281b0ed7a**。相对8149，本片游戏文件仅test-only `scripts/first_visit_journey_test.gd`变化：从已核验真实存档下一关ID接续、逐关有界scope、只读监听真实最后一发与原自动补弹信号、额外记录库存/HP及原pump ammo匣补给。生产main/input/R/presenter/ViewState/replay/loader/资产无diff，不重开已关闭cover/title/auto/text。证据交付仅追加文档与原收据；普通push与远端HEAD核对由最终回执确认，PR15保持Draft、不merge/生产/height/G。

本次起点是fixed b27正式warehouse胜利/原CTA/pump两页教学自然写出的cfg/settings，原字节SHA256分别 **a1952169fd685883c5b87fb318fbcf2d0041acff36b2c904f2004f5f729da60e**、**be93fd9c87c2900acdc56553780b9444e9a6a0bdd286e641f3d60dcfc304d7dd**。经原seed助手复制到新guard UUID私有XDG，原标题Continue直接进入pump SCOUT。没有合成解锁、教学seen授予、record_win、直接载关、改位置/HP/ammo、reference/vacuum、快进或授胜。旧真实manifest无next_level_id时读取同一hash核验ConfigFile；本次b27 manifest明确pump，未回退或重跑历史warehouse。

原SCOUT三枪匣M1弹匣8/BAR20/Springfield6、手雷2，原掩体1/4/5与键盘90/0/180（MG原8度量化），原UI给MG弹药包；默认门一直打开。原警报/暂停/恢复、实际engine两波清到SWEEP，走近领取掉落/搜索原ammo6匣，恢复部署后第二波、末波原撤离/WON/Continue/下一夜CTA与railcut实际两页教学。部署策略由原level_def.gd路线/cover/stash推导，不是陌生人试玩，也没有验证B闭门紫色备用路线。

## 实际验证

| 固定030作者证据 | 实际结果与范围 |
| --- | --- |
| 原生title Continue→pump两波→原撤离/WON→Continue/handoff CTA→railcut两教学页 | **187/0，actual exit0，SCRIPT ERROR0 / engine ERROR0**；UUID **5777ee8887964c7dbba55a7e13179be3**，65次真实XTest。1280×720/100%、自有Xorg112、Godot4.7.2原main及隔离PCK staging已有a0_preview。 |
| 实际波次 | local **253/681tick**，最终global terminal **935**、**34事件**；无失败/授胜。最后三人HP **78.7/77.8/100**，未声称满血。 |
| 原SWEEP搜刮/匣补给 | W0一次原生走近同时领取ammo3/2，原loot seq14/15，M1弹匣/池6→11；原ammo6匣MG池20→26、弹匣20。W1再原生走近领取Thompson20，原loot seq32，加入灰狼背包、原M1仍装备，共三条真实loot。 |
| 自动弹药包边界 | 原UI分配给MG；最终弹匣16、used=false，只读ammo_repacked观察为空。**没有实际耗尽自动补弹触发，不计通过**；地面搜刮/匣补给不能替代它。 |
| 真实schema2录制只读元数据 | **2978/0，actual exit0，SCRIPT/ERROR0**；独立UUID **dd8ec4a72a4d47cfa31da5caa39b74f6**、无gameplay autoload的空项目+guard/XDG。核事件attempt/seq/唯一identity/全局及播放单调时间、wave offsets0/254、684原frame ordinal/schema2、阶段0→1→5→1→5→3、terminal935/last playback5088及原字节未变。仅元数据，不运行模拟、不验新录制3D播放画面。 |
| 实际原生图 | **13**张native Window crop、独立ID/hash，全部1280×720/hash核对，**实际看10**（部署前、SCOUT、W0 SWEEP/补给、W1暂停ALERT/SWEEP/搜刮、WON/handoff/railcut page1）。有界运行与行为/叠层证据，不代全美术/FX/可读性认证。 |
| 官方导入/导出包 | import/export/外层shell实际均exit0，SCRIPT/ERROR0，完整engine日志归档。PCK **23427676 bytes**、SHA256 **8305ce5795c4035e131b3d95b7b63528321d2b7bd54d6ba53b7ea4ccb9d68332**，原工程/导出配置未改、资产生成器未跑，不是APK/设备性能验收。 |

精确argv、source、UUID、环境/guard、原日志/exit、图hash与目检清单、包与元数据范围在[validation.json](evidence/20261004-pr15-pump-journey/run-030/validation.json)，共[38文件hash清单](evidence/20261004-pr15-pump-journey/file-manifest.json)。原生主命令为`AMBUSH_JOURNEY_START=resume AMBUSH_JOURNEY_SCOPE=pump bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-remaining-030-godot first_visit_journey_test.gd --render`。只读inspector的空项目、GDScript、精确命令/私有UUID收据和实际输出另存，不代回放渲染验收。

真实Native record attempt **894a6545a9d49ac514f40adbad264e06**、684帧、playback terminal5088。原二进制 **9480140 bytes**、SHA256 **48f2305b9dcdc562a8d0cb9c2ce44ca02ea474c579e91116b75d187960d96eb4**，lossless [gzip](evidence/20261004-pr15-pump-journey/run-030/native-player-pump-record.bin.gz) SHA256 **271b6db376ab0c3bb3794646a2cb509984d356041d225631eb98d3d8fc1c0358**；与warehouse及旧reference/schema1分别记录。

## 新观察与历史保留

实际WON截图的原高光写“锁门后紫线改道被你罩住”，本轮门实际始终打开。源码`_fill_result_stats`直接读取关卡静态`highlight_hook`，pump该字段写死上述句子；因此结果高光存在可复现文案与实际策略不匹配。此test-only片未改生产文案/R，正常两波无阻碍；不能据此算闭门改线通过，也不声称结果文字全正确。该新观察可随固定source交独立QA确认，后续单独修结果高光措辞。

本片没有失败开发轮次，只有一次固定030正式native，未重复扩大测试范围。历史warehouse三轮45/1、155/2、250/1与b27正式270/0分别保留、不相加。[warehouse原收据勘误](AMBUSH_PR15_WAREHOUSE_RECEIPT_ERRATA_20261004.md)追加说明原run.json和validation分类pump3pages应为实际两页；**84历史文件大小/hash再次全核，原收据字节不变**，没有为勘误重跑warehouse或把第三页计为通过。父端已接固定8149/b27独立QA含新录制3D播放，尚未收到其结果。已关cover/title/auto/text不重新申报或重跑；此前各fixed-source作者与父端计数保持单列。

## 续玩接口与下一片

此轮自然[railcut ending-player-progress/manifest.json](evidence/20261004-pr15-pump-journey/run-030/ending-player-progress/manifest.json)保留原cfg263bytes/SHA256 **2346856cfef799b6b140bc52ae766df8d030729b95f6e6d728978d55da949b78**、settings242bytes/SHA256 **bb25bfab3df63381939c14b7515ae538cddada5a9e7801e26cb1a6af88da7940**。只自然清掉yard/warehouse/pump，进入并完成railcut教学；depot/radio未预解锁。下一片用同一通用resume、原title Continue推进railcut两波/SWEEP，随后depot两波、radio三波，共**三关7波待**。yard d7两波、warehouse b27两波、pump030两波有分别固定源的真实输入证据，不是最新同候选六关13波全通过。

可独立并行包：固定030正常pump旅程复验及此真实record的只读3D绑定/事件/阶段/自动播放QA，独立副本、display/XDG、不写主集成文件。自动耗尽补弹需后续合法正常输入实际触发才补验；若原三关正常路线未触发，单开真实低弹匣/合法策略专项，不伪造ammo=0或赠枪/自造敌人。本片无新增资产件。R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281接口保持，主集成代码单写；资产制作源/GLB/atlas/Blender/生产manifest不改不重跑、WIP不全并。

完整3D FX、A3云预算/优化、艺术、耳听0/45 cue与0/6声景、同候选最终fullsmoke/可追溯APK待；llvmpipe/Dummy不代设备FPS/耳听，全计划后设备顺序保持。网页GPT PLAN/REVIEW unavailable。本轮自己的Godot均实际退出，仅精确匹配Xorg112/PID84196/原日志路径关闭、actual exit0；原Xorg日志lossless gzip/配置/退出收据在上述清单。无现存环境阻碍。

证据写入Git后的全diff --check首次实际2：原Xorg stdout版本行自带尾随空白；改为无损gzip保留原stdout SHA256，不裁剪原字节。随后全diff检查以实际退出收据确认，测试源/工程树未变，无额外native运行。

后续父端要求的固定高光文案已在生产7a3修为pump中性实际结局，fixed b892作者H34/R41均actual exit0/ERROR0；开门/锁门/失败reference及真实030纯formatter范围见[pump高光专项](AMBUSH_PR15_PUMP_HIGHLIGHT_20261004.md)。未重写本轮030正常证据或将reference闭门算正常输入路线通过，独立QA待。
