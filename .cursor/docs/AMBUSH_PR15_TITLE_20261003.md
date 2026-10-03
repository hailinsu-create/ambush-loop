# PR15 title200 全入口修复与验证

固定源码 **226505fb7cc424fb8ff955e94f98f086835b2423**。本片与实际fixed15c formal29独立，未重跑29项；历史报告和schema1 fixture交付仍为a2188f9，不将这些旧验证归到新标题代码。

## 实现

原主菜单受固定垂直偏移限制，Journal插入后在真实1600×720/200%（可用640×360）把Help和Quit推到屏外。现使用真实ScrollContainer/VBox布局，字号按可用窗口限制，版本与日期邮戳自动换行，保留全部五个按钮、原文案、信号和实际游戏场景入口。intro保留fade/旋转/pulse，移除与容器冲突的绝对纵向动画。键盘焦点跟随滚动；modal内部Tab循环、关闭后恢复原焦点。

帮助、六关任务选择、逐关简报和退出确认按实际viewport限尺寸，标题与返回/接受按钮固定，完整正文可滚动。档案同样限尺寸，完整六夜和叙事保留并换行，关闭后恢复焦点。原PauseOverlay设置页保持原实现。原Continue/Accept仍进入main.tscn的实际SCOUT；原退出按钮仍绑定_confirm_quit，测试需要真实退出收据。

## 负向与开发

固定测试ea54a613e07118cb812f1e54dcb961e3d643baad、原生产title：195/44、实际exit1/ERROR0，8PNG留存。实际Help=(170,369,300,48)、Quit=(170,427,300,48)；帮助强制最小1141×1236、档案800×548、任务/简报超出实际viewport。负向包含一项测试夹具错误：实际接受Yard后进度合法保存为Yard，测试仍错误期待Continue进入radio；现通过原record_win(depot)重新建立目标radio进度，不更改生产Continue。其余实际几何/点击失败保留。早期GameSettings CLI解析错误以及开发FlowContainer枚举类型错误日志分别留存；后者停止自有引擎，exit143，不是完成的UI测试。首次直接执行非executable包装器返回126，随后改用bash；不将其归为引擎运行。

提交前开发200%一组372/0、实际exit0/ERROR0、215原生输入/8PNG，原退出button回调真实结束引擎。精确未提交源副本及candidate.patch留存；不能称固定226完整矩阵通过。

## 固定源码正式范围与状态

**固定226正式8组2391/0、实际exit0、SCRIPT ERROR0/引擎ERROR0；原button退出收到真实信号并结束引擎。UUIDbb2364214600482d9a540ecfb77515a1，72物理PNG全部留存核hash、1119原生输入。** 两窗口1280/1600×720、100/200%、desktop/force-touch HUD偏好共8组。原生Linux XTest点击、wheel、Tab/Enter/Escape/M；force-touch只是原设置偏好，非手机触控。fresh Continue禁用、合法进度Continue进入radio SCOUT、Accept进入yard SCOUT；所有六关简报/返回、帮助全正文末尾/关闭/Back、档案六夜/末尾/关闭/Back、任务Back、退出取消/原设置/原实际退出；progress hash保持，focus后台往返，实际窗口resize。

额外独立keyboard退出probe **7/0、实际exit0、SCRIPT ERROR0/引擎ERROR0**：Escape→Tab→Tab→Enter触发原生产quit，原信号收到且引擎结束。UUIDe86556c0629c4df0b334c953fa066a14，4原生键事件。本轮仅一个native输入/渲染作业使用自有Xorg :112；Godot4.7.2 official、GL Compatibility、Dummy音频、Mesa llvmpipe，隔离包装器/UUID守卫。

```bash
bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-full-godot title_menu_viewport_test.gd --render
AMBUSH_TITLE_EXIT_ONLY=keyboard bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-full-godot title_menu_viewport_test.gd --render
```

[证据目录](evidence/20261003-pr15-title/)保存负向、失败、开发、固定源码log/exit/report/PNG与摘要。[正式完整receipt](evidence/20261003-pr15-title/validation.json)与[file manifest](evidence/20261003-pr15-title/file-manifest.json)已生成；全部2个本片正式run收齐实际exit。4张contact覆盖72正式帧overview已看，另看正式100%首屏和1600/200%menu末屏、radio简报及help正文末屏4张native；不称逐字/艺术全验。独立title QA由父端安排，尚未运行；原SCOUT/ALERT/SWEEP冻结与formal29仍按各自固定源范围解释。

## 同步与所有权

GitHub只读确认PR15 Draft/Open/unmerged、head仍a2188f988e525263dbdf3968e9edd8153326c52f；此后Git认证失败未恢复，未换凭据/helper/remote，未自动重试/改走其他写入渠道。本片源码/测试目前仅本地提交，不能称已同步。Library官方materialize失败未恢复，未重试/绕过；官方LibraryID无。旧schema1原fixture已在a218 Git证据路径，source874d3501fdd2b34b0966472e22a9e43a28a1b3dd，SHA2561de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12、5418800bytes；历史重建因Crypto UUID及真实启动时钟不同，只能复现旧格式/行为统计，不能保证原hash。

资产接口固定源29749157c5db064bfea626c3ed9d75d9a1791ece / 交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义。ArtSource/GLB/atlas/制作manifest/Blender输出未改未重跑；主集成title/runtime/presenter/replay/loader/共享测试单写者，独立制作资产验收后接收，WIP不全合并。

下一步：本片作者验证和真实退出收据已完成，交父端独立title QA；恢复原Git认证后同步。当前无未完成测试队列，不继续占用完成的formal队列。完整3DFX→autoREPLAY2×（尚未实现）→A3预算/合批/LOD→六关正常玩家旅程与原两focus裁切→同候选fullsmoke/QA/可追溯APK继续；耳听0/45cue、0/6声景及设备/模拟器仍待，全计划之后安排设备验证。不merge/生产，不混height/G，不写Notion/Library。GPT PLAN/REVIEW unavailable。

父端本轮报告fixed15c独立fullrecord limited pass、无P1/newcontinuousP2；59PNG hash/已看19和其217/224/14028/5477/128/84、旧schema1精确232比较单独记录在parent-qa-scope.json，不与作者29次/75图相加。该结果不覆盖新title226；旧lastSWEEP/WON同1415限制保留。autoREPLAY2×仍未实现，受控2×播放检查不能称此功能已完成。


后续同步收据：父端明确授权仅一次原配置正常push重试，实际exit0；GitHub只读核对d7b2149c64a39f94eb82bcd7c59a3a35cb92cc9b、Draft/Open/unmerged。上述only-local为历史失败状态，现title源码与证据已同步；未改credential/helper/remote/身份，Library仍未恢复。全部Godot结束后自有Xorg112正常关闭exit0。
