# PR15 初始单候选六关正常基线

2026-10-04。固定运行源码 **a05fa959093ef5b6733466091a04fbb46647f97b**，game tree **af63a0ba77a8c9e9a84af6e39d1ee4f0087f639a**。执行[基线计划](AMBUSH_PR15_UNIFIED_BASELINE_PLAN_20261004.md)，这是初始云基线；完整FX/A3改变源码后仍须冻结最终候选、重跑受影响门及最终完整正常旅程。本次不是最终计划验收，也不把旧分段/独立QA数字拼进来。

官方Godot4.7.2单次隔离源码import/export各actual0、ERROR0/SCRIPT ERROR0；原Title/main场景保留，仅staged Linux Desktop原a0_preview feature启用。PCK **23,493,668 bytes / SHA256 313cf1b607f15ce88909bc01674da509c600110d032b8dc450b40e3fffa3fb9b**；[完整构建命令与收据](evidence/20261004-pr15-unified-baseline/build/receipt.json)。没有跑资产制作脚本。

## 实际正常旅程

fresh隔离UUID **7b50d8a62bfd48dc9f741796d2ce9e75**，Guard在autoload前实际通过，独立Xorg:115、1280×720、100%、gl_compatibility/软件渲染/Dummy。同PCK从原标题Start/原简报/首次教学一路原SCOUT搜匣/部署与SWEEP走近拾取，六关13波WON/原CTA/自然progress/致谢原生滚动/返回Title。无授seen/unlock/枪/ammo/HP、无teleport/vacuum/directtick/reference准备。386次原生输入记录；source-derived策略不是陌生玩家playtest。**整轮1193 checks/0 failures，actual exit0，ERROR0/SCRIPT ERROR0**。[原日志](evidence/20261004-pr15-unified-baseline/native-all/pr15-a05-native.log)、[actual exit](evidence/20261004-pr15-unified-baseline/native-all/pr15-a05-native.exit)、[完整report](evidence/20261004-pr15-unified-baseline/native-all/first-visit-journey-report.json)。

```bash
DISPLAY=:115 AMBUSH_TEST_X11_DISPLAY=:115 LIBGL_ALWAYS_SOFTWARE=1 \
AMBUSH_TEST_SOURCE_SHA=a05fa959093ef5b6733466091a04fbb46647f97b \
AMBUSH_JOURNEY_SCOPE=all AMBUSH_JOURNEY_OUTPUT_LABEL=baseline-a05fa959093e \
bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-a05-godot first_visit_journey_test.gd --render
```

[shim原件](evidence/20261004-pr15-unified-baseline/build/pr15-a05-godot)固定该PCK、x11及Dummy。原生产ALERT/SCOUT/SWEEP进程与原输入执行；每波先正常暂停截图再正常继续，未手动推进模拟。

| 关卡 | 实际波local ticks | battle terminal | playback terminal | events / frames | 新原件SHA256 |
| --- | --- | --- | --- | --- | --- |
| yard | 450,225 | 676 | 4126 | 30 /553 | 4e27b9af88ad72199489ee11e987e1ab0e8200c47bc963e831f4c9eb1883c164 |
| warehouse | 339,863 | 1203 | 8317 | 62 /1099 | cba97cc34446a384d1853a6b7c7224afbd32c5c456ee215fbf5afffdc0015cfd |
| pump | 253,681 | 935 | 5376 | 34 /720 | e0faee3000b85ae795737dfd7b39e510e4a0670560d40a0a01890e5acfba2b46 |
| railcut | 195,1149 | 1345 | 6640 | 45 /896 | 19919a17225308894332b5cf9a849b4bc004792afa02f3c5e27d25b0f08f9628 |
| depot | 536,102 | 639 | 6313 | 40 /825 | 1720fe0dc83bfa2647d22c0dcc74b5bea35ac11db2ce25a141e3fb734d156d6d |
| radio | 591,123,129 | 845 | 6798 | 57 /898 | 69926921f672c941f66bc2885ba15e0484f37923e7addae0670047cae0653d22 |

六新record独立写入build/asset_review/pr15-runtime/baseline-a05fa959093e-UUID，gzip无损原件已封；不会覆盖五旧normal原件，五旧SHA只读复核全部保持。每关WON和radio-credits-return保存原自然cfg/settings bytes及manifest，复制hash全相同，不写回玩家数据。radio原致谢wheel0→81，实际打开/滚动/返回三图已核hash与目检；返回原Title且档案显示已切断。上栏t为当前末波local、正文为battle累计，LevelDef.mood_tag为关卡氛围标签，不误当当前wave名。

本轮railcut实见灰狼K98第二波local58最后一弹ammo0，原同枪ammo pack0→5/used=true；原repack event **80476d518907a35e66f2d5dee84e2535:1:28**，timeline254/playback4749。新warehouse原metadata有mine1事件；depot/radio未触mine、无trip/爆炸，不因铺设就宣称命中。正常未发生的FX正反例另reference验；metadata事件存在也不等于FX已集成。

92张物理Window截图全部核SHA、实际目检11（六WON、yard ALERT/SWEEP、radio致谢三张）；81张尚未逐图目检，不称全图已看。实际可见六关终局/累计时刻/真实第一枪/railcut续包、致谢固定标题/返回与滚动正文。本轮没有正常FAILED/真实escape，不能代877专项与最终边界门。自用Xorg按exact argv/display/log SIGTERM，关闭actual0，不动别人的display；glxinfo不存在，不编GPU基准。

## 独立阶段门与保留失败

| a05原源码H门 | checks/failures | actual exit | ERROR/SCRIPT ERROR | 范围 |
| --- | --- | --- | --- | --- |
| equipment_freeze | 66/0 | 0 | 0/0 | ALERT/paused ALERT/REPLAY拒绝，SCOUT/SWEEP合法 |
| presentation_lifecycle | 30/0 | 0 | 0/0 | Back/backpack、touch/focus/reset生命周期 |
| replay_timeline | 67/0 | 0 | 0/0 | attempt/wave/seq/global time与旧边界 |
| replay_fx_lifecycle | 30/0 | 0 | 0/0 | 既有2D wash/rim/tween清理；不是完整3DFX |
| campaign_replay | 14028/0 | 0 | 0/0 | 六关参考授枪/snaps/directticks/vacuum；不是新native原件3D |
| 完整smoke | 无最终总数 | **54** | **1/0** | 早停SMOKE_JOURNAL_RADIO，完整smoke未通过 |

命令、actual exits、UUID、原日志均在[core boundary](evidence/20261004-pr15-unified-baseline/core-boundary.json)。smoke原fixture仍有简报却直接open_journal，现有Title顶层模态锁拒绝，来源核对title.gd173/302与smoke_test.gd14258。此为源码解释；尚未执行修正，不能称修后绿色、更不能为测试开放生产锁。下一测试片加拒绝断言→原Back关闭简报→原journal，再实际完整smoke，旧54失败保留。

纯只读Godot bytes_to_var metadata门 **15807/0 actual0 E0/S0**，六原件schema2/原attempt-wave-seq-event_id/local-global-playback/frame_seq单调/SCOUT-ALERT-SWEEP-WON/终端/level/原SHA均保存。它不调用ReplayPlayer、无autoload/模拟/3D、不代真实回放。[原件metadata](evidence/20261004-pr15-unified-baseline/metadata-fixed/pr15-a05-metadata-fixed.json)。初始diagnostic15807/6 actual1保留：错误预期terminal_reason为won而实际原源码是win；未设置临时XDG导致引擎自有userdata/cache写入被拒，ERROR4/SCRIPT0。修正的只是外部检查器期望和自身XDG，玩家record/项目代码没改、没升级旧bytes。

[validation](evidence/20261004-pr15-unified-baseline/validation.json)及[file-manifest](evidence/20261004-pr15-unified-baseline/file-manifest.json)封存166文件，全manifest SHA复核actual0。作者专项归自己的固定a05来源，不取消既有源的原失败，不重开父端已闭cdb/392/旧railcut范围。

下一：有界smoke fixture→六新原件冷绑定实际3D auto1x/2x、seek/聚焦/source碰撞及旧schema1→成功射击descriptor/原枪口pose/实际HP差的FX-A1→工具/烟/脚尘FX-A2→A3基线/优化→冻结最终候选及同候选全门/完整normal13→可追溯APK。全部授权云计划后再耳听/模拟器/真机；未测不称通过。新3D检查器若新增测试源码，a05原件作为初始生产source、消费者新SHA分别记录，不能称最终同candidate接受。

R5source29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义保持；制作源/GLB/atlas/Blender/生产asset manifest不编辑/重跑。主集成单写main/input/HUD/presenter/ViewState/replay/loader/共享测试。6.1-sol只读FX审计已返回，source a05、没有编辑或测试，仅给成功callback/原装备/真实HP差/绑定playback时钟与R5只读取样接口建议；不计FX/A3验收。不自行派astra、Draft普通push、不merge/生产/height/G；网页GPT PLAN/REVIEW unavailable。
