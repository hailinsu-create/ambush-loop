# PR15 保存拾取事件的物品与数量

生产/正式源码 **392abf936b31ac7f868fec06a109f65fe91cbc6b**。BattleLog.format_event不再一律“+N弹”，使用原payload.kind/amount与既有WeaponCatalog中文名；工具/松散弹药/电台零件显示数量，枪械按原receive_item/backpack语义显示携弹量，不把8发当8把枪，也不推断actual gained。radio_part事件仍称电台零件，不借后端decoy转换改写语义。未知类型显示中性“物品（原标识）”，旧缺kind标类型未记录；缺/空amount是?，零/负值照原值显示，不max到1或填当前装备。只改文字，不改拾取/背包/弹池/战斗/时间/身份/存档/资产。

父端P2-DEPOT-LOOT-1 fixed3b minimal4/1 actual1/E0/S0保持；作者自身负向 **a19059915e83d8333f09581ff55e3efc3919e6c1 H85/45 actual exit1/SCRIPT ERROR0/ERROR0**，固定源 **H85/0、R86/0，各actual exit0/SCRIPT ERROR0/ERROR0**。负向45是新物品名/数量格式和UI入口的失败断言，包含原ammo有效语义的格式更改，**不是45个独立库存缺陷**。两端H同85 core，R另多1PNG保存检查；没有negative R、native正常拾取或新完整回放声明。

原正常depot正式源3b4976d1f4348d828a95bb627b2fb57c8501934d的二进制raw10866596bytes/SHA **ec232057b98e04262fd60f4e44933c7545f396ded83be68a05cdea26b4ebb3e0**只读。actual event **f3bbcc8550a908a5e5740cfa16df238b:1:38**，kindmine/amount1，wave1/local102/global639/playback6023；相邻原playback frame地雷0→1、弹药8→8。原四loot全按保存类型/amount验证，source events/fingerprint/原bytes不改，不重绑foreign run/当前武器。原gzip继续[原depot证据](evidence/20261004-pr15-depot-journey/run-3b49/native-player-depot-record.bin.gz)，不重录/升级旧件。

边界覆盖独立列出的28个已支持kind（十枪/六枪族、刀、ammo/六typed ammo、mine/grenade/decoy/radio_part）与7个未知/缺字段/空量/零/负量fixture；local旧tick与保存global tick不变。有效Dictionary payload是契约，本片没有覆盖损坏的非Dictionary payload/所有旧原件兼容。ALERT ItemList为明确text surface phase fixture，不是新战斗；随后实际原depot保存记录绑定到REPLAY，foreign live log故意ammo99，原历史mine定位状态/ItemList/RichText fallback均仍来自绑定原件，main snapshot及两source log不变。原焦点callback与source绑定只覆盖本事件文字/画面，不借它声称全事件/自动播放/seek/normal接受。

R一张原始物理1280×720 PNG核SHA **e2120dea6144af15e8e36648201180fbd1e9a8d9fbef20cc201f0397495c481b**、目检1：顶部“定位 · 10.7s 队员1 拾取 地雷（数量1）”，原事件日志同句，历史角色卡“弹8/16 雷1”。顶部暂停播放t100.4是原playback6023/60的命令回放时间，事件10.7是原global639/60，双时域原样保持；不是新时间修复。截图用原source绑定/focus/日志开关callback，无native XTest输入，不能称玩家正常输入流程。自用Xorg92921准确SIGTERM actual0，日志无损gzip留存，不碰其他display。

[16证据/实际命令/UUID/退出/范围](evidence/20261004-pr15-loot-text/validation.json)、[hash清单](evidence/20261004-pr15-loot-text/file-manifest.json)、[独立计划](AMBUSH_PR15_LOOT_TEXT_PLAN_20261004.md)。negative UUID864814ebb33a43a9b3ca4954cada3ec5；fixed H608bccca3bf74284b6b6ecd14d26b534、R a15c0eab59fd4793b7545856a750b63e，每次包装器私有UUID/XDG并先过guard。正式实际命令：

```bash
AMBUSH_TEST_SOURCE_SHA=392abf936b31ac7f868fec06a109f65fe91cbc6b AMBUSH_NATIVE_RECORD_DIR=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 loot_event_text_test.gd --headless
DISPLAY=:112 AMBUSH_TEST_X11_DISPLAY=:112 LIBGL_ALWAYS_SOFTWARE=1 AMBUSH_TEST_SOURCE_SHA=392abf936b31ac7f868fec06a109f65fe91cbc6b AMBUSH_NATIVE_RECORD_DIR=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-loot-godot.sh loot_event_text_test.gd --render
```

作者文字专项通过、fixed392独立QA待；原fixed3b depot normal1201/2 actual1/RESULT4/2/LOOT4/1各实际失败不取消，新record3D2463/0/作者原record9539/0各actual0与metadata1713分开。a794结果事实与0bfe chip父端QA继续，cdb live条H1159/R1164另片交付d363，均不拼成同candidate全接受。railcut原fixed3b normal1389/record2839/作者原record10496各actual0限定闭合保持，不重开已闭范围。本片不混RESULT-1/a794，不声明库存修复。

[下一有界切片与并行包](AMBUSH_PR15_NEXT_SLICES_20261004.md)：先审SCOUT IntelStore/fix_one等静态5.2/真实wave语境，再锁同candidate基线13正常波/新record3D并推进成功射击socket/muzzle/tracer/impact独立FX-A1；完整FX/A3/艺术/45cue六声景耳听/装备触控回归/旧2D/可追溯APK仍待，不提前设备/APK最终验收。唯一主集成作者保持main/HUD/input/presenter/ViewState/replay/loader/shared tests单写；资产源/GLB/Blender/atlas/生产manifest不改不重跑、WIP不全并，R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281及20骨/socket/3LOD/52语义保持。独立包由父端分配、优先6.1-sol、不自行astra。Draft不merge/生产/height/G，网页GPT PLAN/REVIEW unavailable；Notion由指定管理者。
