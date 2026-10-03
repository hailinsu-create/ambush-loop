# PR15 默认自动2×复盘交付

固定源码 `77000cae182ce9836d5ecc0926ed5178a0a012d7`，工程树 `670400771e5c2988855f7aebb048c3bff341cc0d`。默认原复盘按钮从记录起点自动2×，由实际main._process(delta)驱动独立历史时钟。绑定源不随live BattleLog更换；只读，不推进SimClock、不重算R。暂停/继续、1×/2×、P/+/-、slider/原左右6tick/事件定位后暂停，末端停在原WON帧并可重播；菜单冻结且关闭后按原状态恢复，应用focus返回保持暂停。

原终局Overlay会隐藏BottomBar：固定12a真实native负向27/2、exit1/ERROR0。因此同一个ReplayButton/原pressed信号转入原终局footer，进入REPLAY或重新setup返回原底栏。增加result viewport回归。生产全局快捷键仍用原unhandled路由；验证中明确释放HSlider/Button焦点后检测全局箭头与Space，自身GUI键盘行为保持。未加GUI前置shortcut处理。

## 固定源码正式结果

所有命令走 `bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-full-godot <entry> <mode>`；wrapper/Godot路径、私有Xorg配置、evdev键盘映射、完整实际命令/UUID/log/独立exit文件在 [validation](evidence/20261003-pr15-autoreplay/formal-77000ca/validation.json)。7次均实际exit0、SCRIPT ERROR0、引擎ERROR0。

| entry | 模式 | checks/failures |
| --- | --- | --- |
| replay_autoplay_test.gd | headless | 29/0 |
| replay_autoplay_test.gd | render | 168/0 |
| replay_timeline_test.gd | headless | 67/0 |
| equipment_freeze_test.gd | headless | 66/0 |
| presentation_lifecycle_test.gd | headless | 30/0 |
| presentation_lifecycle_test.gd | render | 32/0 |
| result_viewport_test.gd | render | 553/0 |

Headless覆盖30/60/240帧cadence、1×/2×、fraction/暂停/seek清债/非法delta/末端/重bind、歧义旧记录拒绝与真实schema1原件；host原回调替换live record仍使用原bound source。Native为原yard3D普通按钮进入+main真正开启process，每帧delta与floor累计120历史ticks/sec逐帧相等，两布局实际XTest pause/speed/slider/左右/P/菜单/重播/Space；事件seek与app focus用原API。两次native均自动到1430末端、stored WON/同attempt且停止，末端等待墙钟约49/48秒仅属软件render测试预算，不是帧率验收。

原reference部署/合法SCOUT与SWEEP移动fixture，两波1056/227、原终局1283与34事件保持；现代schema2连续历史末端1430，不拿它替代战斗R。真实schema1来自 `874d3501fdd2b34b0966472e22a9e43a28a1b3dd` 的原var_to_bytes文件5418800 bytes，SHA256 `1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12`，原1415末端、字节未变，未升级/降级构造冒充旧版。旧schema1最终SWEEP/WON同1415的固有限制保留。

## 证据边界

33PNG逐一hash核对：6自动回放native Window crop、26终局native Window crop、1生命周期root viewport图。作者实际看6自动入口/播放/末端、FAILED/WON 200%scrolled及focus图，共9张；移动播放图是raw捕获，截图时钟持续走，不称与之前probe最后一行完全同tick。末端先实际停止、再两draw稳定。报告有32条自动回放native输入、40条result native输入；生命周期输入为引擎parse事件，未称XTest或设备输入。其余24图只hash，不称逐张艺术审查。

原有效负向7c在原无时钟源6/2、exit1/ERROR0；d0a第一轮typed parser失败不算契约负向。开发24/0 H、原12a entry27/2，以及两轮Window未放原点pointer失败134/32、36/2全部保存；后两轮没收到Replay GUI信号，是fixture错误。旧私有X11 `base` arrow100/102造成166/8、167/2；30秒endpoint预算也过早到期，非终点图虽旧文件名含endpoint仍明示development nonterminal。仅自有:112改evdev arrow113/114，Window.position=0、释放GUI焦点后开发167/0，正式168/0。尝试过的GUI前置路由已撤回，patch留档。负向/开发/正式计数分开，[file manifest](evidence/20261003-pr15-autoreplay/file-manifest.json)可追溯。

所有测试队列实际完成；此片不重跑原有效formal29或旧title2391。后续title/Pause焦点修复已在固定 `4ba2bfd26a17ebbb1500f04c8fb267d852461f65` 另做六次专项，auto H29/R167、生命周期H30/R32全部actual exit0/ERROR0；自动时钟/main/BattleLog/presenter/ViewState源与固定770完全相同。该回归与上述正式770计数分开，见 [title焦点报告](AMBUSH_PR15_TITLE_FOCUS_20261003.md)。3ba自动回放证据交付的原配置push actual exit0与GitHub HEAD核对收据见 [sync-3ba6871](evidence/20261003-pr15-autoreplay/sync-3ba6871/receipt.json)。

未验：正常玩家胜利路径、oldschema1 native自动播放、完整3DFX/耳听、A3预算/全部新候选回归、APK/模拟器/设备性能。独立auto QA与title两P2修复独立QA由父端安排；不把原尺寸限定关闭当title整体完成。本checkpoint完成后先交付，不扩FX/A3。

资产接口保持R5固定骨架20骨/socket/3LOD/52语义，角色制作源、GLB、atlas、Blender与manifest均未改/未重跑；WIP未整体并入。不merge、不发布生产、不混高度。网页GPT PLAN/REVIEW unavailable。
