# PR15 下一最小热点诊断计划（只读盘点，未运行）

2026-10-04，接固定候选交付`1879f19fb03237fcd9d3daec7f89254086a5d3c9`。父端启用新的独立QA并接管性能窗口；**主作者本turn不运行任何引擎/profiler/采样/资源重活，不安装工具，不触碰QA进程或其文件**。当前只读源码、现有已封JSON与工具路径/权限配置、官方固定引擎源码和文档；仅提交本计划/索引。方案未实现、未编译、未实测，不能称profiling门通过。原metadata无稳定收益结论保持，不继续堆优化。Draft，不merge/deploy，资产与玩法数值不改。

QA目标仍为1879固定候选。本文后续docs-only提交保持其game tree`ff0de72e42f636e201983cf47aa24aa142a652bd`，不把文档HEAD混称新运行源码。源码consumer`a42ea2d7b50e79ee4a954ec9859a7281c577c174`、生产`cd352bfb3ad1f7b7c7863a115c5dec29fc02042a`；实际门、八轮raw、失败、39原图/412清单不改，见[已封结果](AMBUSH_PR15_A3_METADATA_SCALAR_RESULTS_20261004.md)。网页GPT PLAN/REVIEW unavailable；本地`.agents/skills`未提供可用内容，不阻碍只读盘点。

## 既有计时能证明什么

现有真正量测的边界是：相邻postdraw回调的墙时、collector自身写表耗时、引擎聚合monitor，以及窄render setup区间。**没有已验函数级CPU热点、场景树创建/释放计数、整viewport CPU时间、原生worker采样或GL timestamp数据**。下列是原已封同输入结果的读出，不是新测量：

| 原窗口 | wall interval中位A/B | render_setup中位A/B | draw / primitives / render objects中位A/B |
| --- | --- | --- | --- |
| static archived253/frame43，240行/版 | 139.493 / 139.950ms | 0.038 / 0.039ms | 342 / 83747 / 890，两版同 |
| advancing original1x，96行/版 | 729.650 / 722.412ms | 0.042 / 0.0435ms | 332 / 81409 / 879，两版同 |

static实际snapshot/pose/装备/镜头固定；advancing实际PB268..453/frame45..76，并且操作员死亡/姿态/FX和回放UI都会变化。推进比静态慢但draw/primitives中位较低，足以否定“仅看draw数就定位热点”的做法，**不足以定位脚本、GPU或唯一软件栅格瓶颈**。node中位1366→1383/resource473→476和orphan0不能证明创建频率、队列峰值或无泄漏。TIME_PROCESS更新语义不同于postdraw，不能做逐row函数归因或加减；collector自身中位约235..250µs亦不能从wall减成校正FPS。

固定engine源码明确：render setup计时在scene/canvas更新后结束，后续viewport绘制不在内；小setup值不能排除渲染/driver成本。[固定RenderingServer实现](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/servers/rendering/rendering_server_default.cpp#L72)。原报告“GPUtime unavailable”精确含义是**这些既有raw没有GPU计时证据**，不能推广为Compatibility没有GPU计时API。

## 已有入口盘点

| 入口 / 本地位置 | 已有证据与适用边界 | 现在的状态 |
| --- | --- | --- |
| `presentation/device_probe.gd`，presenter镜头巡检按钮 | 30秒巡检、前2秒排除、墙时p95/p99/draw/primitive；自动改yaw/pitch/extent，可能切LOD/遮挡，逐帧append且不做函数归因。适合镜头巡检，不直接作同输入热点对照。 | 既有入口；本turn未启动 |
| `a3_render_metrics.gd` | 原59列预分配32768行、15,466,496 numericbytes；first-frame exclusion/ready/完整source/warm/溢出拒绝已验。只采已有字段，不含函数栈或viewport计时。 | 保持不改 |
| `a3_cadence_sampler.gd` / `a3_collector_overhead_test.gd` | 公共16列sampler 4,194,304numericbytes；full-buffer与resident-callback开关控制已有168/0/16windows。旧样本main与presenter均冻结，不能直接接受动态profiler或新计时开销。 | 可复用协议；不能复用旧开销结论 |
| 已封`metadata_pair_external.gd` common4 | exact原record/253/frame43、canonical画面、真实20骨/socket/装备、backend/config、60static+24advancing/5秒warmup/5秒minimum/30秒cap；八轮原始结果已封。 | 可继承fixture；新诊断driver须另SHA/receipt，当前未写 |
| Godot本地脚本profiler | `--debug`激活本地debugger；`--profiling`在active debugger开启`scripts`。局部测量应在warmup之后用`EngineDebugger.profiler_enable("scripts",true,[])`，边界关闭并验证`is_profiling`；不能写成旧API`profiler_start/stop`。 | 固定源码/接口已读；本机runtime能力未测 |
| Godot编辑器Profiler/Visual Profiler | 前者显示脚本self/inclusive/calls；后者显示render域CPU/GPU类别。editor与远程协议也是额外进程/开销，首轮优先standalone本地profiler，暂不开editor。 | 文档入口，当前未启动 |
| RenderingServer viewport计时 | `viewport_set_measure_render_time(rid,true)`后读取`viewport_get_measured_render_time_cpu/gpu`，另保留setup；API默认未启用时0不能作无成本。需列全部实际被画viewport，不能只猜root。 | 当前项目未启用；实际valid/nonzero/延迟门待 |
| `--gpu-profile` / Compatibility timestamp | 固定源码有GPU-profile CLI路径、GLES-over-GL的`glQueryCounter`/延后取结果路径；CLI聚合输出不等于逐帧script profile，不作为首轮必需。 | source-only有入口，host支持未验 |
| 系统工具与权限 | 只读`shutil.which`：strace `/usr/bin/strace`；perf/pidstat/gdb/trace-cmd/bpftrace/apitrace/glxinfo未在PATH；`perf_event_paranoid=2`、`kptr_restrict=0`。这些不是perf_event_open权限/符号栈可用的实际探测。 | 不安装、不attach、不trace |

上述脚本路径相对`ambush_loop/scripts/`。原Guard仅接受既有entry/三参数，不能直接附加任意profile flags；未来沿用已审外置shim：精确替换原allowlisted A3 entry到新外置诊断driver，在两控制都追加同样的local-debug参数。新的shim/driver都另封SHA，并要求原Guard隔离UUID、source/tree/engine/warm/493sidecars成立。当前未创建shim/driver或新stage。

官方依据：[固定CLI启动](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/main/main.cpp#L3621)、[固定本地profiler](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/core/debugger/local_debugger.cpp#L36)、[EngineDebugger接口](https://docs.godotengine.org/en/stable/classes/class_enginedebugger.html#class-enginedebugger-method-profiler-enable)、[Profiler self/inclusive与开销](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html)、[Visual Profiler边界](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/debugger_panel.html#visual-profiler)。stable文档只辅助说明，实际启动/计时路径优先固定ed1daf源码，不把当前网页当作本机能力通过。

## 有依据的待测调用路径

| 候选路径 | 当前源码事实 | 要补的诊断证据 |
| --- | --- | --- |
| `main._process`→`_apply_replay_scrub`（5507、6665） | 自然replay.advance成功时调用；paused不走。调用`_paint_replay_snapshot`/事件列表/status/transport/HUD。paint先对ReplayLayer children queue_free，再建markers/Line2D/Labels；ReplayLayer挂在World，presenter只隐藏其canvas分支，不阻止这些脚本/节点操作。`event_list.clear/add_item`也重复。 | 每phase调用数、root inclusive、child self/inclusive与独立场景树churn证据；“隐藏但仍执行”不等于已证慢 |
| `presenter._process`→`refresh`（239、254） | 两窗自动refresh；ViewState历史数组/事件复制与freeze、ActorPose采样、actors/corpses/objects/FX/cones、遮挡周期与UI布局。 | refresh/各child函数self/inclusive、callcount；先区分capture、pose、对象/FX、遮挡，不盲目memoize |
| `ActorVisual.sample_layers/sample_pose`（95、65） | 有同pose早退；改变layered pose会采两层、骨骼读写、force/update_attachment。 | 两函数真实callcount/耗时，区分早退与实际采样；inclusive包原生API/wait，不能称纯GDScript计算 |
| `Assets.set_asset/mount_item/instantiate` | set_asset/mount_item有同资源早退；source看见`load`不证明每帧磁盘加载。 | 实际instantiate/miss调用数/resource path/IDs；不得用“不稳metadata收益”推断所有资源读取便宜 |
| live `VisualSnapshot.capture` / recording seams | SCOUT/ALERT实战另有记录/状态ful capture；回放ViewState读取保存data，不能以本回放profile归因live capture。 | 仅在第一门定位后，再单独同来源live phase诊断；不扩大本轮最小范围 |

行号均指1879/a42固定game tree；这些是可定位的源码机会，没有已验函数时长。旧[只读hotpaths](evidence/20261004-pr15-a3-actual-source/formal-a90-all/readonly-hotpaths-a44.md)保留历史，但其中metadata复制机会已在cd352测过且无稳定收益，不再作为下一无量测优化理由。

## 下一最小执行门：先脚本路径，不混工具开关

**启动前置：必须收到父端明确的QA结束与窗口归还通知。** 未收到期间只写文档；elapsed time、QA已开或agent idle都不算归还。收到后冻结QA接受的实际consumer/tree；若代码有变化，原1879数据只作历史，重新建立本轮source/record/cache/shim证明，不把它当同源码。官方4.7.2/Compatibility/Dummy、同host配额/实际driver/window/vsync/policy/原record/相同frame/rig签名；所有源数据和游戏参数保持。

1. **P0单次能力与输出预检（未运行）**：在隔离Guard中确认local debugger active、has_profiler("scripts")、enable/disable状态真实切换，收到BEGIN/FRAME/停止后的ACCUMULATED与函数signature/self/total/calls；frame数组与record/backend/rig保持，actual0/E0/S0。能力缺失或输出不全则封原失败停，不称profile有效。先在untimed阶段prime profiler内部存储，然后关掉，两侧保留相同已分配状态。固定源码本地profiler有32768个ProfileInfo容量，开启会排序/逐函数打印；打印量/写日志/tee/存储和函数计时都可能影响窗口。每秒stdout是当时frame数据，停止累计另列，不能把“一秒输出一次”误读为“一秒所有帧平均”。不能以全进程boot累计定位特定phase。
2. **P1唯一首轮诊断（未运行）**：同一生产source，四fresh UUID **OFF ON ON OFF**，每轮静态/推进两窗仍用common4原5秒warmup、60/24实际phase行、5秒minimum/30秒cap及first-row exclusion；新driver仅在边界开关`scripts`并添加清晰segment marker。相同local-debug启动、collector59列、scratch buffer和日志管道常驻两侧；OFF profiler inactive，ON active。区间前后停止profiling，源hash/序列化/完整树/RSS/PNG/JSON写入在untimed；原自然回调与replay时钟不动。所有打印/父进程记录开销保留，测OFF/ON wall/counters/RSS漂移，不相减成“真实FPS”。若profile扰动使30秒不足、cap触及、输出截断/容量用尽、同input失配，整轮无效保全，先修观察方法，不放宽原样本门或预算。
3. 先报告两次ON各phase的calls、root inclusive、child self/inclusive与observer占用；可定位的production-script root仅在证明互不嵌套后比较，例如自动`_apply_replay_scrub`与`presenter.refresh`，不把parent inclusive与child再相加。actor共享script函数的总calls不能自动分配到某个actor；script self是函数域耗时，原生调用/阻塞仍可能计入，不能当纯CPU cycles。若两次ON排名/覆盖或OFF/ON负载不稳，按预先声明追加逆序ON OFF OFF ON一次，完整保留，不选有利pair。再不稳则结论“观察不足”，不提交优化。

**首个可证伪假设H1**：在本有界推进回放中，`_apply_replay_scrub`路径是比`presenter.refresh`更大的生产脚本入口耗时来源。预声明判据：两次ON推进窗都能完整记录这两个非嵌套root；`_apply_replay_scrub`累计inclusive占二者累计inclusive合计>50%，并且静态对应calls接近0、推进随advance调用。若任一重复不满足，则H1未成立；即便成立，也只定位这条入口路径，**不能称整个frame>50%或唯一CPU瓶颈**。随后凭`_paint_replay_snapshot`/事件列表/HUD的实际child计时选择一个最小子路径。若反而refresh明显较高，转H2：其pose/capture/corpse/object/FX/occlusion中哪个在重复ON里占主要disjoint self，先量测而不同时改数个模块。优化前还须相同原record/pose/socket/HUD/source/模拟不变量和独立A/B回归。

## 渲染/软件栅格的独立第二门

P1仍不能解释墙时差异或需要区分渲染/native域时才进入；H1成立本身不排除这些成本。**不与P1 profiler开关同时变化**：先另P0验证viewport RID集合、计时enable、实际finite/nonzero输出和结果延迟，再同生产source以计时OFF/ON控制observer开销；尚未实现。保留原setup与draw/primitives/objects，新增aux表，不改59列CSV或原exclusion。GPU/viewport API的0只有“未启用/未更新/不支持/真零”待分辨，unknown时写支持状态与sentinel，不能当0成本。延后GL timestamp结果不能按当前row phase/tick强配；初期优先static原frame，若拿不到返回结果frame年龄则明确unknown，只作该固定source窗的区间数据，advancing不做逐帧归因。

固定GLES实现有GL查询并在后续帧取结果；证明“存在路径”，不证明本Mesa构建/当前driver/仪器启用时已可用。[固定GLES timing](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/drivers/gles3/storage/utilities.cpp#L304)、[固定viewport CPU/GPU边界](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/servers/rendering/renderer_viewport.cpp#L309)、[官方RenderingServer API](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-viewport-get-measured-render-time-cpu)。render-domain CPU只含该viewport渲染相关操作，可能包含原生提交/driver等待；同frame所有被画viewport及setup边界不重叠才可作render域汇总，仍不能与滞后monitor或墙时任意相加。

若渲染域显著且稳定，才提出**H3像素敏感性**：单独明确stationary fixture两侧都冻结main/presenter，用相同已实例化LOD/骨骼/世界/镜头frustum/宽高比，把输出A=1280×720与B=640×360按ABBA/BAAB八轮比较，profiler与viewport计时开关在两侧完全一致。这改变诊断输出分辨率，**不是玩法/生产quality或手机FPS优化**。必须实核资源路径/骨骼/source不变且draw/primitives/objects/HUD布局工作量匹配；resize若触发LOD、UI模式、遮挡或几何差异则拒绝“只变像素”的解释。预声明四相邻pair都在geometry匹配时降低wall中位≥20%才支持该fixture有明显像素相关成本；未满足则H3未成立。即便成立，也需viewport域/worker证据区分软件栅格、driver同步与CPU提交，不能断言llvmpipe是唯一瓶颈；冻结fixture不代自动回调/live战场。

原生证据后续另门：先在本方owned Godot PID核UID/实际argv，再低频或仅segment边界读取**自己的**`/proc/PID/task/TID/stat/status/comm`，记录thread CPU累积、fault/context switch、分辨率与sampling时钟/开销；不读QA PID，不用共享mountroot cgroup CPU归因。主线程与llvmpipe类worker占用可提供域线索，但线程名不是函数栈，CPU多线程时间不能加减wall。若仍需native stacks，perf目前未装且权限/符号未验；未来分别核用户态event、官方二进制符号/调用栈能力及ON/OFF采样扰动，缺失就保unknown，不改sysctl/CPU配额、不换engine/render backend制造收益。strace只解释IO/syscall，不能定位纯计算/软件shader热点，且attach本身有开销，不作首轮工具。[Mesa LLVMpipe官方说明](https://docs.mesa3d.org/drivers/llvmpipe.html)。

## 证据、停止条件与交接

后续每段须另封实际source/tree/engine/fixture/shim/loader-sidecar/warm清单、originalrecord SHA/attempt/wave/frame/clock、同canonical frame与actual20骨/socket/装备资源、raw/phase/profiler enable状态/call coverage/observer memory/输出字节数、每run actual exit与E/S、START/自然END/PID收取及display所有权。源码盘点、工具存在、网页说明、输出被打印均不自动成为可用profile。无效/超时/半轮、未满足反例判据和不利pair一并保存，不能只截top函数截图或将4静态/推进fixture称六关集成。测试自动进程/时钟不改，不删collector、不降预算、不重跑资产。任何后续开启API/sidecar要另冻结driver并先能力门，当前没有这样的提交。

**这次交付只包含只读盘点和未运行计划；目前性能窗口仍属于父端独立QA，主作者没有新Godot/editor/Xorg/profiler/attach/工具安装。** 待QA结束归还后先P0→P1并返回固定诊断证据，再决定是否存在足以支持下一单一候选的热点。FINAL全回归/fullsmoke/newnormal13/whole1x2x/oldschema1/all-art/fullgameAPK/最后耳听设备顺序仍未完成；资产作者的源/生成器/GLB/Blender/atlas/manifest所有权保持。
