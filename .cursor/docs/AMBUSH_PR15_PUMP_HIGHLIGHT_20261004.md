# PR15 pump结果高光：只陈述已发生的结局

生产小修 **7a3eac6353e863dfe8d216cebef190d63f39d716**；正式验证源 **b89297ea249628e20c4674d4c776421a35ee50cd**，game tree **e597127be0c49a9b1a9c28424142088ce6fd51e4**。父端要求修030正常开门通关却WON显示“锁门后紫线改道被你罩住”的假高光。两处来源不同：统计直接读静态level.highlight_hook，正文Payoff即使没有route_choice也回退该目标；锁门但covered=false的失败又因hook_hit仅看事件存在而称“打中过”。

最小修复：只对pump，Payoff结果文字依据实际终局WON布尔返回“泵站封锁完成／泵站尚未封锁”，统计复用同一结果formatter。没有声称玩家关门、紫线改道已覆盖、无人受伤或弹包已用。原教学/brief的目标hook与其他关文案保持；原BattleLog基于实际covered=true写出的锁门终局事实保留。仅main._fill_result_stats和replay/payoff.gd结果分支改动，模拟、路线、枪/HP/ammo/冻结/资产无diff。测试新入口两平台注册，实际仅Linux验证，Windows未跑。普通推送/远端同步以最终回执为准，保持Draft、不merge/生产/height/G。

## 固定源实测

| 源与证据 | 实际结果 |
| --- | --- |
| 负向60af18172b7cbb5640001e5b89611870d08b0e92，原生产文案 | **34/14，actual exit1，SCRIPT ERROR0/engine ERROR0**。真实030原生记录只读formatter及三个reference域，14失败均为错误高光；开门赢907、锁门覆盖赢953、锁门未覆盖失败1489的实际domain终局及route_choice区别通过。 |
| 正式b892 H，UUID e977e9917e7a4a72abf90826cae41249 | **34/0，actual exit0，SCRIPT/ERROR0**。guard通过，原030记录原hash不变；两处正确中性结果、失败卷宗内容、snapshot/log fingerprint/SimClock不因formatter改变。 |
| 正式b892实际窗口，UUID c6d24100a79042abb7940e703f9f12a4 | **41/0，actual exit0，SCRIPT/ERROR0**。同三个reference域，原生XTest点击FAILED卷宗成功，完整战斗state保持；1280×720/100%，原生Window crop **4图全部核hash/实际看4**。WON开门/锁门中性高光已见；FAILED中性行在内容字段核验、原生入口/卷宗前部可见，未滚动到中性句，不称该句画面已目检。原生按钮坐标记录未单独持久化，实际native调用/exit检查与打开结果由固定脚本及报告保证。 |
| 7a3开发H/R，UUID6ba6c234888a450bb0100a8a2ec4d087/e68cbe545f754fd18400a0edabb1fa89 | **34/0、37/0，两次actual exit0/SCRIPT0/ERROR0**，三图核hash/看3；当时失败卷宗仅API字段，追加原生打开/第四图才固定b892。计数单列，不相加。 |
| 官方包，fixed b892 | import/export/外层shell实际均exit0，SCRIPT/ERROR0。PCK **23433752 bytes**、SHA256 **ab4e8543f0cd025c0076ff01e754a14c10c2eec2eca706e54bb1fb84c994d9e5**；只隔离staging已有a0_preview，原工程配置/资产生成器保持，不是APK/设备验收。 |

两个正式命令均为`AMBUSH_NATIVE_RECORD=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/native-player-pump-record.bin bash ambush_loop/scripts/run_isolated_test.sh <wrapper> result_highlight_test.gd <mode>`。H的wrapper为`/tmp/pr15-highlight-headless-godot`、mode `--headless`，另传`AMBUSH_TEST_SOURCE_SHA=b89297ea249628e20c4674d4c776421a35ee50cd`；R的wrapper为`/tmp/pr15-highlight-b892-godot`、mode `--render`，wrapper固定source与PCK。精确argv/env/guard/UUID/日志/actual exit、包日志lossless gzip和图在[validation.json](evidence/20261004-pr15-pump-highlight/validation.json)、[47文件hash manifest](evidence/20261004-pr15-pump-highlight/file-manifest.json)。三个域的terminal907/953/1489在负向、正式H和R完全一致。

**reference域限定**：使用原SCOUT门命令、raid_prepare_ref授枪/掩体快照、直接_sim_tick及vacuum到原SWEEP/extract/终局，不是正常原生玩家旅程或闭门路线的玩家操作/性能/艺术验收。030真实record只给纯formatter读，未绑定/渲染/改写历史，SHA256 **48f2305b9dcdc562a8d0cb9c2ce44ca02ea474c579e91116b75d187960d96eb4**不变；不能把此片叫Native record的3D回放通过。正常030旅程187/0、元数据2978/0仍分别记录，原38份与warehouse84份证据全部hash保持，未重跑旧cover/title/auto/text或重写原证据。

## 后续与边界

实现与作者专项通过，独立QA待。可独立并行固定b892/生产7a3两处结果文字复验、开门/锁门/covered=false反例，独立副本/private display/XDG，不写主集成文件。当前无新资产包需求，R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281及唯一主集成所有权保持；制作源/GLB/atlas/Blender/生产manifest不改不重跑，WIP不全并。

下一段依据[railcut计划](AMBUSH_PR15_RAILCUT_JOURNEY_PLAN_20261004.md)接**030正常旅程**自然railcut cfg/settings，不能使用本片reference胜利写出的进度。原title Continue、原三枪/cover/警报/暂停/真实SWEEP/补给/CTA/depot教学；合法原背包关闭灰狼自动雷、原包给灰狼、夜枭搜刮以观察真实耗尽补弹；分配弹包不会重填弹匣，初始原Kar7发，预测不能作通过。余railcut2/depot2/radio3共7波、真实自动ammo pack耗尽、FX/A3预算/艺术/耳听0/45与0/6/同候选fullsmoke/可追溯APK待，全计划后设备；llvmpipe/Dummy不代FPS/耳听。网页GPT PLAN/REVIEW unavailable。自有Godot均已退出，仅精确匹配Xorg112/PID85409/日志关闭actual exit0，原日志/stdout无损gzip/原hash与配置已留存，无环境阻碍。
