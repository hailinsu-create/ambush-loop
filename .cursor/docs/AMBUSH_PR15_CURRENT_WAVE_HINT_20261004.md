# PR15 本波待入场提示切片

生产修复 **480c2c4c14c72dc254d6d513f0985ac5505a99a4**；正式完整源码 **0bfe57cdd57e2b6dc40a1ec909535931c4e7cac7**（随后仅补测试HUD刷新与3个可见性断言）。main._next_wave_info从本波实际pending_spawns读取actor/delay/spawned，保留原local sim clock与FAILED情报cut资格。ALERT在原spawn真正发生前保持pending，含前一tick及已到时刻但尚未执行生成的tick；REPLAY不读取活体队列。原时刻表、生成/战斗/装备/日志/存档/资产未改。共用desktop/touch提示与表现tension cue随真实队列修正，不声明耳听通过。

原normal3b49 radio暂停末波t1.4s却说暗道2.2s的图/事件保全；原record第三波只有echo5/localtick30，raw SHA e584a89d86b60c2931e5d947b3ab2dba416801a4ea499f5b5685507ef8d7128f逐字节只读不升级。旧函数误遍历关卡总spawn_schedule；其他关本波原delay也被总表时间替代，固定negative **a0910379476ea4fb1ff3d4519451c6c16940ac35 H968/271 actual1/E0/S0**。显示fixtures不等于正常旅程复现：具体新负向还包括原转场到radio第三波的reference域，echo实际原event id5/wave2/tick30、原暂停84tick、三波原清场/抽离WON843。

生产480初H968/0 actual0，R972/0 actual0，却在目检发现auto process被停用的reference驱动只刷新chip/view，完整HUD仍0.0s，history API pause后transport文本也旧。保留两张原PNG/日志/source并单列dev，green没有覆盖可见时钟，不能叫最终视觉验收。**测试修正不改生产clock**：显式调用原_update_hud、原replay暂停callback，新增可见wave3/3/paused/t1.4/pending0、state/log保持、history暂停文本3项。最终source0bfe正式H **971/0** UUIDc6a5cd1a3a9b4dbd870f25b7e41b469b、R **975/0** UUID70e54380b8a34be9a0efb90a81420f98，各actual exit0/SCRIPT ERROR0/ERROR0。原968核心断言保留；原负向没有新增3项，所以两端数字不冒称相同脚本总数。

覆盖六关13波在3D/legacy2D的时钟display矩阵：明确phase/index/tick/spawned设值、原_queue_spawns与独立列出的actor/delay期望、0tick/生成前一tick/暂停/FAILED cut/本波全进场正反例，display保持snapshot/log/queue/clock；**不是26场实际战斗或全旧2D回归**。另一个原radio reference使用本关原匣枪械授予、cover snap、direct tick/vacuum，原三波生成/暂停/WON/REPLAY，显式注入未来活体queue后历史仍不取它且绑定source/bytes不改。不是新的normal/source-switch/完整auto/seek接受。

独立只读比较a091与480两份reference域record：各52事件/terminal843，去除各次attempt_id/event_id后其余全部字段完全相同（seq/wave/local/global/playback时刻、actor/target/position/type/payload均保留），源hash未变。新场次身份彼此独立，不重绑/合并/去重到current run。actual exit0/E0/S0，独立输出与脚本入证据，不合并入H971/R975计数。

R最终2张原始物理1280×720 PNG都核hash、实际目检：末波顶部完整“第3/3波 · 暂停 · t=1.4s · 敌1 待0”，没有原暗道提示；history原暂停transport、live待入场chip消失。2次XTest原按钮pause/resume留坐标/helper exit。此前dev2图也保留但不能借来证明最终clock；自用Xorg90563经精确SIGTERM actual0，覆盖两次R的共享Xorg session日志无损gzip留存。无新PCK/APK、性能/设备或艺术声明。

[36文件完整证据/实际命令与UUID/退出](evidence/20261004-pr15-current-wave/validation.json)、[hash清单](evidence/20261004-pr15-current-wave/file-manifest.json)。正式实际命令：

```bash
AMBUSH_TEST_SOURCE_SHA=0bfe57cdd57e2b6dc40a1ec909535931c4e7cac7 AMBUSH_NATIVE_RECORD_DIR=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 current_wave_hint_test.gd --headless
DISPLAY=:112 AMBUSH_TEST_X11_DISPLAY=:112 LIBGL_ALWAYS_SOFTWARE=1 AMBUSH_TEST_SOURCE_SHA=0bfe57cdd57e2b6dc40a1ec909535931c4e7cac7 AMBUSH_NATIVE_RECORD_DIR=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-wave-godot.sh current_wave_hint_test.gd --render
```

**仍有已确认的另一展示问题，不能全关当前波P2**：最终图中标“观战”的watch_timeline绑定当前elapsed却仍画总表主0/侧0.5/暗3.6/回5.2，而末波实际只有echo0.5；代码_refresh_watch_timeline读route_spawn_marks。前波payoff的local ticks也可能串到当前条（源码审查，未称新的normal复现）。本片只修待入场chip/其共享helper，不把该时间条计入green。下一独立live条片先negative→当前wave dots＋原attempt/wave payoff→固定H/R；SCOUT实际下一波预览也对原wave定义，旧event身份保持。debrief全attempt、静态教学/fix_one/chatter及IntelStore总表delay另审，不称已通过。

[同候选六关/FX/A3接续计划](AMBUSH_PR15_SAME_CANDIDATE_FX_A3_PLAN_20261004.md)把该live条修复作为完整当前波关闭与fresh全候选验收的前置；随后同候选原生13波＋新record3D、完整muzzle/tracer/impact/smoke/boom/dust、云预算/优化回归、全相关装备/触控/旧2D、艺术/45cue六声景实际耳听、可追溯APK。当前全部未验；设备全计划后。结果事实专项a794 H193/R221仍归原fixed source/c5aa交付，可立即独立QA；不把本片与它拼成已完成最终candidate全smoke。R5源29749157/交付ebedb829接口与制作所有权不变，无新资产件、未重跑源/GLB/atlas/Blender/manifest；独立包均只读副本/display/XDG，由父端分配优先6.1-sol。不merge/生产/height/G。网页GPT PLAN/REVIEW unavailable。
