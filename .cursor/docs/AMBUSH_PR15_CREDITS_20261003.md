# PR15 radio 致谢布局与原生返回

2026-10-03，父端指定独立小片。生产源码固定 **dedc8cfdcfd5662eb86fe337cfd80812234904ab**。依赖的连续command **47a6454ed745c96a6da0b89867c37cf54c79d83d** 仅有提交前开发98/0；固定源command/完整六关/recordreplay/graphical尚未正式验证，本片的credits通过不能替代其验收。先返回父端供独立QA，下一片在47+credits同一候选立即整体formal。

## 实际反例与最小修复

父端原0ac末关radio200%真实P2为致谢标题裁切、返回按钮不可达。56/2中的另一项presentationclock误判排除，不算第二个实际缺陷。主作者固定 **cd984a5be7c38f823123f6d116f1859137b166a4** 实际负向106/17、exit1，10张物理图/7次原生输入全部留存并核hash：200%四种布局标题rect y=-34,height39，返回rect y=431,height44，均超出640×360可用视口；缺滚动容器且实际200原生返回失败。100原生返回正常，原生Escape两次能到真实title，但各触发一次旧scene脱离后get_viewport为空的脚本错误；实际引擎错误2条，不称ERROR0。

CreditsOverlay保持全部原文、CHAIN、六夜标签、颜色及finished→title绑定。面板按实际viewport限高/宽，标题与≥44px原返回按钮在scroll外固定，完整tag/六夜rail/正文放入scroll，resize与present重排。main仅将Escape消费输入移到handle_android_back之前，避免返回title后继续访问已脱离的viewport；Back目的地和顺序保持。制作资产/manifest没有修改或重跑。

测试先快速跑真实radio三波，再原生点击原WON“查看致谢”。首轮c73测试未等待Container重排便点击CTA，已终止exit143并排除；不是有效缺陷复现。cd测试补24帧及postdraw后原CTA正常打开，得到上述有效反例。ded测试增加journey编号，避免重复布局覆盖证据。

## 作者验证

| 分类 | 固定源或性质 | 实际结果 |
| --- | --- | --- |
| 实际负向 | cd984a5 | 106/17、exit1、引擎错误2；10图/7原生输入 |
| 开发 | 源码提交前工作树 | 127/0、exit0、ERROR0；11图/26原生输入 |
| 正式credits | dedc8cf | 127/0、exit0、ERROR0；11物理图/26原生输入全部留存核hash |
| 共享生命周期 | dedc8cf | headless30/0、exit0、ERROR0；render-only两张保存检查未运行 |

正式命令经仓库隔离包装器和Godot4.7.2：

```bash
bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot radio_credits_viewport_test.gd --render
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 presentation_lifecycle_test.gd
```

wrapper/private Xorg配置、各run实际log/exit/UUID、原JSON及PNG/hash见[evidence](evidence/20261003-pr15-credits/validation.json)。私有X11 :110，Mesa llvmpipe，物理1280×720与1600×720；200%为真实Window.content_scale_factor=2，aspect keep后可用640×360，不以项目base texture充当窗口截图。

正式credits隔离UUID d0e7cd1ee1a745199b8bf000a1a53ec6，生命周期501edf347f094ee793f8467ddf9e8723。作者已查看正式1600/200%首屏、1600/200%滚至末尾、1600/100%三图；其余8图留存核hash不称逐图艺术验收。200%标题rect[60,46,520,39]与返回rect[60,270,520,44]均在640×360内。原17失败全部通过，原生Escape两条runtime错误不再出现。

三次radio reference部署/tripwire/原vacuum辅助/实际三波/撤离（合计9个radio波），均保留原波内末tick[574,391,448]、全局terminal1413与51events。原native CTA三次，不直接present或emit_signal绕过入口；8个窗口/比例/输入偏好矩阵，另fresh100原生button返回与fresh200原生Escape返回，20次原生wheel至末尾。检查正文、原终局result文字与battlefooter、完整command snapshot不被resize/滚动改写，6个夜标签保留；100返回finished信号一次。仅实际LinuxXTest鼠标/键盘，两偏好不表示实体触摸验收。

## 与原base对照及边界

原0ac154528c395ed58124d02f5457d4e57e278468、47a6454及负向cd984a5的credits源blob完全相同：7fe964106f32b724a3f372fb7119e6fb38b859a6。负向运行在47继承树上，未冒称重新运行原0ac全工程；对照范围为原credits实现及相同radiofixture终局/文字/正文/footer。[最终对照](evidence/20261003-pr15-credits/baseline-comparison.json)实际核对负向与正式各三次终局的波tick/全局tick/event数/result/footer完全一致，十个正式布局的正文保持原摘要9f73477ffbd2608416f7fc4976b8b4f4a938bdfcfc59a66a09f814e20425f968，全部20个标题/返回control在实际视口内。47的BattleLog/ViewState/ReplayPlayer三个blob本片不变；main仅上述Escape顺序修复，不将继承command自动标为green。

这是末关referencefixture的致谢UI与返回专项，未称正常完整六关玩家旅程、完整13波战场视觉、设备性能或全部HUD关闭。父端已独立限定关闭此前0ac终局两P2、cf77 schema2 IK与eb153北侧原矩阵；原两张focus邻近镜头文字裁切仍待。正文滚动边缘裁切是可滚动窗口的一部分，完整正文必须实际能滚到末尾。

所有权：主集成独占main/presenter/ViewState/replay/HUD/runtime loader及共享测试；ArtSource/v2制作脚本、角色GLB/Blender输出/共享atlas/制作manifest归独立资产作者。R5接口源29749157c5db064bfea626c3ed9d75d9a1791ece、交付ebedb829e3263abbeb6dd266905f24a3869fa281，20骨/socket/3LOD/52旧语义保持；WIP不全并。SCOUT→ALERT→SWEEP、数值/grid/Nav/LOS/拾取/14px follow/瞬时grab-release/sharedhaul不改，Draft/Open不merge/生产、高度/G隔离。

尚待独立credits QA、47+credits整体formal、SCOUT警报前录制、完整FX/A3、六关13波视觉及正常旅程、同候选fullsmoke/独立QA/可追溯APK。耳听0/45cue、0/6声景，设备/模拟器在全部计划工作后。旧7d34867完整smoke/技术PCK91不能归当前候选；本片没有新APK/PCK。Library尚未恢复，不重试；GPT PLAN/REVIEW unavailable。完成普通push并只读核对后才称已同步。
