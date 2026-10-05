# PR15 A3仪器修正切片

2026-10-04，接43908安全checkpoint及父端指示：先本地代码/headless检验，固定候选后报；父端当前两个reader/render窗口结束并协调串行窗口前，不启动正式performance引擎。此片仅test-only仪器，不修改游戏运行代码或R5制作资产。

目标：将动态rows改为预分配有界数值表、计时覆盖采集写入、明确采集器payload/static/RSS口径；为monitor写supported/unsupported/unknown及冷帧可用性；生产场景切换前接入post-draw钩子；source/engine/全部tracked游戏文件与可选producer原record在计时窗外核实际SHA256。满表/错源/缺presenter保留明确失败/排除，不能静默覆盖原冷行或制造phase零指标。

验收：官方4.7.2隔离wrapper headless功能检验（不作performance量测），覆盖真实来源receipt及错commit/hash/record负向、headless/enum缺失/release/Compatibility pipeline支持矩阵、有界容量/溢出首行保留/完整CSV输出、提前钩子与无主场景/释放host生命周期、无source字段写入。预分配内存与计时范围不推GPU/手机FPS；真正Window冷帧/采集开销对照/六关正式A3仍待父端串行窗口。

官方依据：[Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html)说明部分monitor受debug/release影响及可延迟更新；[RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html)说明渲染计数初始帧可能尚不可用，OpenGL没有RenderingDevice；[PackedFloat64Array](https://docs.godotengine.org/en/stable/classes/class_packedfloat64array.html)说明64位紧凑存储。该文档支持范围解释；具体4.7.2行为以实际headless/后续Window证据为准。

最新作者功能候选 **f81ded755c813d69b16ed17f0dc7e9c5bee8de7c**，game tree **eead812c4f45a2cc198cdc7a59422d5bc88bddea**。官方4.7.2隔离Guard headless **48/0、actual exit0、ERROR0/SCRIPT ERROR0、Unicode messages0**，UUID **9d675ee749ad4f48856d53de34de3842**。本片没有Window、真实post-draw量测、冷渲染帧、正式A3或设备接受。

动态row数组改为启动前预分配的PackedFloat64Array；59列，默认32768行，固定数值payload15,466,496 bytes。符号最多1024、segment receipt最多512。计时覆盖标量/counter写入及row_count推进，最终耗时字段写入和return不含；不是全帧CPU/GPU时间。记录payload、分配前后static及自己的Linux RSS非计时边界；metadata/字符串/分配器仍驻内存，不能只减payload就声称排除所有仪器开销。RSS原FileAccess按0-length procfs读不到，经真实40/1证实后改按行读取。

enum缺失、headless render及release static/orphan明确supported=false/raw -1；pipeline enum可读但后端支持未证明时supported=null/status unknown，raw0不作无编译成本证据。前两draw未就绪另有row标记，设置/window/scale/limiter/vsync逐行；缺host仍保留raw并标不可用。probe钩子在生产scene切换前挂入；engine启动/autoload及冷资产导入仍不在该范围，真实Window冷帧与有无仪器开销对照待验。

Python helper在源码冻结且tracked project与HEAD一致后生成实际size/SHA256/Git mode、独立consumer/game tree、engine及可选原record；GDS逐项读actual bytes并重建完整Git blob/tree SHA1，比对外部已锁的AMBUSH_A3_GAME_TREE。非空子集/重复路径/外目录/错tree/错文件均拒绝。当前**981 tracked文件/117,564,312 bytes**及**986现存warm imported文件/55,647,094 bytes**前后匹配，imported完整清单也校验不漏文件；没有重导入或重跑制作。原schema1记录5,418,800 bytes/SHA256 **1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12** 未改。producer commit874在helper仍是caller-declared；正式记录须和原作者封存manifest匹配，不将hash一致自动当producer来源证明。engine146,414,384 bytes/SHA256 **8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e**。

48项是明确headless手动_sample()，所有raw.measured=0。实际原yard加载、冻结main自动process后读已捕获presenter.frame，原log/HP/ammo/工具库存/位置子集保持；原Title释放host后旧绑定中性无错误。容量12的功能夹具故意填满并溢出11次，首冷行不覆盖、payload5,664 bytes不增长，保存12行/59列精确CSV。**该raw chunk是complete_buffer=false/run_incomplete=true，save返回ERR_INVALID_DATA，是预期拒绝证据，不是可接受性能数据。**源码/cache/record post-run proof失败也拒绝，raw/metadata先保全；reset要求成功原数据封存，未封/无明确确认的坏chunk不能reset。明确acknowledge后仅用于功能测试复用，整轮run_overflow_rows/run_incomplete永不归零，既有raw路径不能覆盖。有效非溢出Window chunk接受路径、实际开销与长驻留仍须正式前Window控制验证。

| 固定源 | 实际结果 | 是否通过 |
| --- | --- | --- |
| b27bc8d48d4d58d74577c6bad8eba0d3d650a81a | actual1/E1/S1，无Guard/无suite，weakref类型推断报错 | 否 |
| 210f8358a64976176b24bc619d1c59bc3f71b6b2 | actual1/E1/S1，无Guard/无suite，同weakref报错；补Array未解决 | 否 |
| cfcfa281f8584de2132c12e77a103b7a149d462d | Guard40/1、actual1/E0/S0，Linux RSS两端-1 | 否 |
| b2ac13a0b0020f9a0edd3cb16cae5d02a5a0f907 | Guard40/0、actual0/E0/S0，后续只读审查提出完整manifest/reset门遗漏 | 当时功能限定通过，非最终仪器/性能 |
| 6e51282619b36129dee4e4f05e74f885cf742d91 | Guard1/1、actual1/E0/S0，12 Unicode NUL messages，Git tree不匹配 | 否；NUL改原byte append |
| f81ded755c813d69b16ed17f0dc7e9c5bee8de7c | Guard48/0、actual0/E0/S0/Unicode0，完整tree/cache/坏chunk保存门 | 作者headless功能通过，非Window/A3 |

首轮曾误归因Array，实际weakref(main)返回Variant；已显式WeakRef并保留两次编译失败。没有把actual0或E0当作带S1/Unicode无效轮green。只读6.1-sol针对固定b2检查，无engine/仓库修改；建议推动完整tree/cache/封存门，**未独立复验f81的48项**。

实际正式命令（仅此headless功能轮）：

~~~bash
python3 ambush_loop/scripts/prepare_a3_provenance.py \
  --engine /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
  --output /tmp/pr15-a3-instrumentation-fixed/provenance-f81.json \
  --record yard=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin \
  --producer-sha 874d3501fdd2b34b0966472e22a9e43a28a1b3dd --include-import-cache
AMBUSH_TEST_SOURCE_SHA=f81ded755c813d69b16ed17f0dc7e9c5bee8de7c \
AMBUSH_A3_GAME_TREE=eead812c4f45a2cc198cdc7a59422d5bc88bddea \
AMBUSH_A3_PROVENANCE_FILE=/tmp/pr15-a3-instrumentation-fixed/provenance-f81.json \
bash ambush_loop/scripts/run_isolated_test.sh \
  /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
  a3_collector_contract_test.gd --headless
~~~

[完整manifest](evidence/20261004-pr15-a3-instrumentation-fixed/manifest.json)保存六固定源原log/actual exit/receipt/脚本、实际corrupt receipt/CSV/metadata、只读报告及八个生产blob与4484相同证明：74文件/6,056,505 bytes，逐hash复核。没有PNG/截图/设备数据；本作者全部headless session已收取，无自有engine/Xorg待poll，正式performance未启动。

父端通知QA所有engine与Xorg145actual0结束，可预约A3单engine窗口；但新blast raw-envelope P2优先：fixedf2/71同probe22/6 actual1E0/S0，仅snapshot.schema/playback_schema/wave_id/frame_seq及data.phase/wave_count单项float即可强转接受，正常writer/UI坏字段路径未证。当前f81仍继承原ViewState，**P2尚未修**；先真实空爆/单帧合法PB2控制复现→仅tool_supported转换前门修复→旧schema中性/原bytes回归，再Window仪器有效chunk/开销控制→正式A3。父端blast readerpool123/ring30、dust H132/Window167/ALERT5各actual0E0/S0限定另列；旧Window178/5为ROI中心空洞probe错误保全，不称wholeblast green。父端53PNG原件看/保留，但合包缺PNG，不虚称本仓库收到或本作者看过。

后续正式performance开始/结束及时报父端，保持同宿主单engine控制CPU争用；llvmpipe不推手机FPS。A3/优化→FINAL fullsmoke/newnormal13/六新全1×2×3D→可追溯APK仍待。R5/制作源/GLB/Blender/atlas/production manifest及单写接口、SCOUT→ALERT→SWEEP、Draft不merge/生产/height/G和耳听设备后置保持。
