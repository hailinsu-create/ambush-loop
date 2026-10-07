# PR15 A2 保存爆炸与有界烟池

2026-10-04。生产固定 `a9b8ee068aee6b8345baf7064d90f9c08d67a80c`，像素探针修正固定 `f2f1f570d1da91d1e01d7a1d23ba86080d4b364d`；四个生产文件逐 blob 相同。实际爆炸源 d75 保持，main、VisualSnapshot、ToolFxRecording 相对上次交付767字节未改。这里是作者有界 reader/render 验证，不是完整正常战场、FINAL或设备性能通过。

ToolFxFrame 只读取绑定保存源：typed版本/clock/token、已知level、attempt/wave、canonical tool/effect IDs、创建早于确认、真实owner与victim HP差。grenade不造原event；mine必须匹配保存的真实victim event。坏项中性，重复tool/effect及指向同一实际mine事件的两份描述都中性；按保存seq排序后选最新有限项。原回放缺字段不补当前工具或角色，不升级旧原件。mine重复引用缺口由只读审计提出，作者实际3/1重现，再同测试3/0修复；正常writer/UI产生该重复路径尚未证明。

presenter拥有8槽/省电2槽，固定40 MeshInstance、3 shared mesh、10材质，全部关闭阴影。确认后短flash、保存半径压力环及有限烟团，只由保存playback age/seq/position/radius派生；普通3烟团、省电1，180 ticks后取消。派生位置/scale及length_squared有限门在写节点前执行。烟是爆炸表现，不是烟雾工具、持久足迹或新伤害。真实wipe的已确认源保留，abort、source/wave切换和Title撤场；暂停/seek不依赖壁钟。

实际结果单列，不能把不同source计数相加成FINAL：

| source / suite | checks/failures | actual exit | ERROR/SCRIPT ERROR | 判断 |
| --- | --- | --- | --- | --- |
| 922 planned pool parser H | 无套件 | 1 | 1/1 | 无效，未进入Guard |
| 02d planned pool H | 15/2 | 1 | 0/0 | 缺reader和presenter pool的原负 |
| 4ac initial pool H | 235/0 | 0 | 0/1 | 无效，测试调用不存在的Title API，不能算通过 |
| b932 actual ring radius H | 254/18 | 1 | 0/0 | 保存半径被unit ring乘2，实际mesh顶点/scale反例 |
| cba actual mine reference H | 3/1 | 1 | 0/0 | 两个不同tool/effect链接同一个真实mine event |
| a9 same mine reference H | 3/0 | 0 | 0/0 | 同实际源与原副作用断言通过 |
| a9 reader/pool H | 255/0 | 0 | 0/0 | 完整专项与原Title释放 |
| a9 reader/pool Window R | 268/0 | 0 | 0/0 | 13原Window PNG，hash/实际目检13 |
| b962 first pixel R | 无套件 | 134 | 0/0 | signal11/abort，完整回溯保留 |
| 99 retained Script pixel R | 无套件 | 134 | 0/0 | 同样abort，持有Script推测未得到支持 |
| 85 original pool pixel R | 无套件 | 139 | 0/0 | segfault，未保存PNG；未算green |
| f2 corrected pixel Window R | 75/0 | 0 | 0/0 | 30原PNG全hash/实际目检，五yaw同帧off/on/off |

后三轮无套件的探针都在原手雷排队删除、等待30帧后仍调用spent()，且早期落点(25,18)是南墙。85改开放落点与原pool路径仍segfault；f2只把实际spent布尔值保存到等待前，同探针才完整通过。不能将早期回溯直接认定为正常presenter崩溃，也没有证明仅临时Script引用造成引擎故障。所有无效/原负日志与真实exit封存，不用E0/S0替代自然退出与套件结论。

reader实际正向源含空爆、cover/MG友伤、enemy过杀、mine受害event及wipe终局。坏字段/缺字段/年龄-1,0,7,17,60,179,180、foreign actor数组只做明确复制夹具；不借current actor替换saved victim。pool真实三种来源分别age0/6/17/60/179/180/-1/restore0，实际unit ring顶点半径与保存radius相等；48份明确grenade复制容量选seq40..47，逆序不改变选择，省电选46..47。超大有限输入的派生overflow中性，100次重复更新保持40节点。真实foreign live blast不能替换绑定wipe记录；原暂停30绘制/abort/Title释放固定节点与弱引用通过。七authentic旧raw首末中性、文件hash和内存bytes保持。

Window使用官方4.7.2、1280×720原窗口裁切、gl_compatibility/Mesa25.0.7/llvmpipe LLVM19.1.7、DummyAudio。13张源/年龄图全部实际查看；直接API推进和seek未走完整HUD transport，部分HUD曾停留旧HP/tick，不计HUD正常旅程。新的f2空爆图在原ALERT暂停后等待原tween并更新HUD：实际开放cell(25,12)投向(25,17)，原fuse/bounce、明确库存授予和保存age控制。五yaw0/35/125/215/305，pitch55/view12；age0测flash/环复合，age60只剩smoke，未单独隔离flash与环。on变化像素分别1098/1099/1101/1099/1101与3223/3222/2655/3060/3009，十个off/off全0，ROI半径28/颜色阈值0.04；原HP/库存/位置/sim/log/snapshot均保持。未验证全部pitch/zoom/遮挡或艺术成品品质。

实际正式命令，Guard与fresh UUID/XDG由wrapper建立：

```bash
AMBUSH_TEST_SOURCE_SHA=a9b8ee068aee6b8345baf7064d90f9c08d67a80c bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 tool_fx_mine_reference_test.gd --headless
AMBUSH_INITIAL_RECORD_ROOT=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75 AMBUSH_LEGACY_RECORD_FIXTURE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin AMBUSH_TEST_SOURCE_SHA=a9b8ee068aee6b8345baf7064d90f9c08d67a80c bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 tool_fx_pool_test.gd --headless
DISPLAY=:120 AMBUSH_INITIAL_RECORD_ROOT=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75 AMBUSH_LEGACY_RECORD_FIXTURE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin AMBUSH_TEST_SOURCE_SHA=a9b8ee068aee6b8345baf7064d90f9c08d67a80c bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 tool_fx_pool_test.gd --render
DISPLAY=:120 AMBUSH_TEST_SOURCE_SHA=f2f1f570d1da91d1e01d7a1d23ba86080d4b364d bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 tool_fx_visible_test.gd --render
```

证据目录中的development-a9标签保留原名字，内容是上述已经自然完成的固定源专项，未改写为新source运行。[manifest](evidence/20261004-pr15-tool-fx-pool/manifest.json)包括原负/无效日志、实际exit、JSON、固定代码、blob equality、43 PNG和实际查看receipt。a9三轮UUID为4d4c37a102fd4d11b549a5e6293588f6/7daff272d4f44291af63df6520161ac9/577b958e40894f81962d3887af9f7b19，f2为11d4c82eb1ef463582ac4c72b800ee3a。所有本片engine已收尾；只关闭核对exact argv/UID属于本作者的Xorg:120 PID110024，session58039实际退出0，receipt保全。

父端独立结果另列：b563 H205/Window305各0 actual0 E0/S0，40原PNG/30unique实际查看，五yaw隔离muzzle/tracer/impact及稳定off、muzzle/pose/lifetime/source/cap/cache门限定关闭；不代9f writer身份证明。53 flight独立H144/Window160各0 actual0 E0/S0、11原图，旧102同probe144/20 actual1→53，原progress0.5/.18duration/.045×2step及原bytes保持，限定flight P2关闭。父端核964files保持，无新P1/P2；不与本作者计数相加。

下一片保存移动pose的有限脚步尘cue，然后A3真实指标/优化、FINAL同source fullsmoke、新六关13波正常输入、新六原件完整1×/2×3D回放、可追溯fullgame APK。blast完整1×/2×段、多波正常可见性、全部十枪/动作/LOD/长驻留、耳听/设备尚未验。R5源29749157/交付ebed、20骨/socket/3LOD/52语义不变，ArtSource/GLB/Blender/atlas/production manifest未编辑或重跑；runtime表现与测试仍由主集成单写，不merge/生产/height/G。可并行包：固定a9 reader/工具源有界只读QA，以及待锁定FX最终候选的A3 raw量测；制作端只接收真实帧与已验revision，不借turnaround替代战场。
