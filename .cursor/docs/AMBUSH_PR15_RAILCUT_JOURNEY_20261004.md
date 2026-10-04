# PR15 正常railcut两波与真实弹包耗尽

正式固定源码 **3b4976d1f4348d828a95bb627b2fb57c8501934d**，game tree **10ec85c1676785cd9a3938d9707db5c82b9f1ad1**。相对已推送2d5高光修复，游戏文件仅test-only `scripts/first_visit_journey_test.gd`变化：railcut原UI给灰狼弹包、背包关闭自动雷、夜枭搜刮、MG领取原ammo6，以及被动观察实际射击/补弹信号时检查原事件身份。生产main/input/R/presenter/ViewState/replay/loader/资产没有新增diff；旧cover/title/auto/text不重跑。

起点为030正常pump187/0在原WON/Continue/railcut两页教学自然写出的两份cfg/settings；SHA256 **2346856cfef799b6b140bc52ae766df8d030729b95f6e6d728978d55da949b78** / **bb25bfab3df63381939c14b7515ae538cddada5a9e7801e26cb1a6af88da7940**。经已存在seed助手逐字节核验复制到新UUID/XDG，原标题Continue进入railcut SCOUT。没有使用高光reference测试进度、合成解锁/seen、直接载关、改位置/HP/ammo、赠枪、造敌、reference/vacuum、快进或授胜。

## 实际结果

| 固定3b49作者证据 | 结果及范围 |
| --- | --- |
| 原title Continue→正常railcut两波→SWEEP搜刮→原撤离/WON→Continue/handoff CTA→depot实际两页教学 | **185/0，actual exit0，SCRIPT ERROR0 / engine ERROR0**；UUID **c24f91de73034aeeacf8edf277b4fd9e**，**49**次真实XTest，1280×720/100%、自有Xorg112、Godot4.7.2、llvmpipe/Dummy。 |
| 两波与结局 | local tick **195/1149**，global terminal **1345**、**45事件**；三人最终HP **97.6/100/100**，弹匣 **1/49/10**。部署原cover1/4/5，面270/270/180；策略从原路线/匣/掩体推导，不是陌生人试玩。 |
| 真正耗尽后的自动弹包 | 灰狼原Kar98k匣7发，原UI分配弹包不会重填匣；原I背包按钮关闭自动雷。第一波真实6枪后剩1发。第二波local **58**/global **254**最后一枪后观察到 **ammo0、used=false→ammo5、used=true**，同一Kar98k、同一角色1。原repack事件 **93d07e8fdaa687f28d8e05c9432f4724:1:28**，seq28、wave1、tick58、`same_weapon`，紧跟同角色同tick真实fire。此有界耗尽条件实际触发；不泛称其他武器/所有补弹分支通过。 |
| 原SWEEP补给分开记录 | W0夜枭走近同时领取ammo2/3，原loot seq21/22，scout匣6→10、池6→11，灰狼仍1发。原ammo6匣由MG领取，池50→56、匣50。W1夜枭原生领取ammo2及mg_ammo6，原loot seq42/43，scout池11→13及不匹配mg池0→6，当前scout武器保持；共四条原loot。补给不冒充耗尽包。 |
| 真实record只读检查 | **3906/0，actual exit0，SCRIPT/ERROR0**；独立UUID **bce7de620f584a8d9d6f23cb48373867**、空项目无gameplay autoload、guard/XDG先于engine。事件attempt/seq/原唯一identity、全局/播放单调时间、wave offsets0/196、896原frame ordinal/schema2、阶段0→1→5→1→5→3、terminal1345/last playback6641、原repack紧跟fire、原字节未变。仅元数据，**新记录实际3D播放待独立QA**。 |
| 原生图 | **14**张native Window crop，全部hash/1280×720/唯一ID核验，**实际看10**：原背包自动雷关、SCOUT、两次SWEEP/补给、W1暂停ALERT、WON、handoff、depot page1。有界输入/行为/UI验证，不代全美术/完整FX/设备性能认证。 |
| 官方包 | import/export/外层shell均实际exit0，完整engine日志SCRIPT/ERROR0；PCK **23435080 bytes**、SHA256 **f7601be2a9a60fc1dda5d2c36bb880cc3ec67d335efbae2d1d05f4c1556c8d1e**。只在隔离staging沿用a0_preview，原工程/导出配置与制作资产未改，不是APK。 |

主命令：`AMBUSH_JOURNEY_START=resume AMBUSH_JOURNEY_SCOPE=railcut bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-railcut-3b49-godot first_visit_journey_test.gd --render`。wrapper保留完整固定source/PCK/原030manifest、DISPLAY和实际engine参数；只读inspector的精确argv/环境/UUID另存。[validation.json](evidence/20261004-pr15-railcut-journey/run-3b49/validation.json) 与 [39文件hash清单](evidence/20261004-pr15-railcut-journey/file-manifest.json) 含原日志/actual exit、seed收据、图、源record和包收据。

原Native record attempt **93d07e8fdaa687f28d8e05c9432f4724**、896帧、playback terminal6641；raw **13717064 bytes** / SHA256 **154c69778d82b3d7a35b32d7d5ebd8782cd792cb9edad82544495a125af86e53**，lossless [gzip](evidence/20261004-pr15-railcut-journey/run-3b49/native-player-railcut-record.bin.gz) SHA256 **5386154b073847f2e03855ac467cd6e7dc6063856a17455801175f8ec013c2a6**。一轮正式运行，没有开发失败轮次或重复启动既有长任务。自己的Godot已退出，仅精确匹配Xorg112/PID86974/原日志路径关闭，actual exit0；日志/stdout均无损gzip并保留raw hash。

## 接续及边界

自然[depot存档manifest](evidence/20261004-pr15-railcut-journey/run-3b49/ending-player-progress/manifest.json)：cfg **309 bytes** / SHA256 **050864ec68d3819eb4275bce4e106ba64299f6635b648cf736f0e68903d57b7c**；settings **258 bytes** / SHA256 **5610ba32c76ec210bb5e3baf24ad8d17ad53702c14e9b05dd45cf0b3fd55042e**。自然cleared至railcut，depot教学seen来自实际两页Next，radio未预解锁/授seen。固定证据普通push并核远端后，接原title Continue推进depot两波、radio三波；[后两关计划](AMBUSH_PR15_DEPOT_RADIO_JOURNEY_PLAN_20261004.md)。当前各固定源yard/warehouse/pump/railcut各两波，余五波待；不称同候选六关13波全通过。

父端新增QA单列：fixed b27 warehouse限定通过，无新P1/P2，native1673/0及封存新记录实际3D换源10429/0，均actual0/ERROR0。fixed030 pump静态锁门文案P2由父端3/1、actual1/ERROR0确证，其正常输入与新记录3D未运行；高光已独立交付2d5/生产7a3/fixed b892作者H34/R41，父端修复QA仍待。作者计数、父端QA及各源码互不相加。原warehouse84、pump38、高光47证据文件逐字节hash重核未改；本片只追加railcut证据。

可并行独立包：固定3b49正常railcut输入与此原生record的实际3D换源/自动播放/seek/历史equip及repack表现QA，独立副本/display/XDG，不写主集成文件。R5资产源 **29749157c5db064bfea626c3ed9d75d9a1791ece** / 交付 **ebedb829e3263abbeb6dd266905f24a3869fa281**接口保持，无新增资产需求；制作源/GLB/atlas/Blender/生产manifest不改不重跑、WIP不全并。PR15保持Draft，普通push，不merge/生产/height/G。

完整3DFX、艺术、A3预算/优化/回归、耳听0/45 cue与0/6声景、同候选最终fullsmoke/可追溯APK待；llvmpipe/Dummy不代设备FPS/耳听，全计划后设备顺序保持。网页GPT PLAN/REVIEW unavailable，无现存权限或环境阻碍。
