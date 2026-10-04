# PR15 有界安全点接续checkpoint

2026-10-04 **08:49:16 UTC**，按父端指示结束本turn；保全现有进程、隔离数据、日志和固定PCK，不启动新测试、不杀进程、不重复重跑。此文补充[INITIAL独立QA完整入口](AMBUSH_PR15_INITIAL_QA_CHECKPOINT_20261004.md)，后者包含六raw SHA/bytes/attempt/自然cfg与所有旧失败范围。主工作树`/workspace/ambush-pr15`；原`/workspace/ambush-loop`不改。游戏source HEAD **f3a906fef21e3f0970851b0e615f94346202466a** 已普通push并ls-remote/PR15读回，clean；该提交仅新增FX-A1a计划/共享负例/明确wrapper入口，**没有FX生产实现**。当前生产main最后修改是箭头fixed d9c。

## 已固定可交QA

- INITIAL source **a05fa959093ef5b6733466091a04fbb46647f97b** / evidence **4d0f1b3de9f6e5f302a10e44c63d01df852210b7**：官方4.7.2同PCK、fresh原标题正常六关13波与credits原生滚动/返回 **1193/0 actual0 E0/S0**；92图核hash/看11、386inputs，六新raw与自然cfg。metadata **15807/0 actual0**仅builtin bytes_to_var，不能称render。INITIAL PCK SHA313cf1b607f15ce88909bc01674da509c600110d032b8dc450b40e3fffa3fb9b。
- 静态教学正式source **fcf40a97606c148ec6dcb87a2b20dfa39100458e** / evidence **a3df5281768973156e033d3168b7552ab5d763e9**：负H138/R141各80failactual1→fixed各0actual0 E0/S0，26 display fixtures非实战。
- escape正式source **877decb0ea14d6c3c0a833e4d6948c7ee549514f** / evidence **4b82fbf0acba15a0de9fed35bd60d7d8003b465a**：负H18/R21各8failactual1→fixed H70/R73各0actual0 E0/S0；实际第三波echo0.5s/15.9s、retry历史第三波；旧/缺/坏context中性，原event identity与模拟保持。
- smoke共享testfix **8906ff5d595a08e614fb02c8d19277867b00e865** / evidence **2d4b90b4809554b430682029483b6ec3f2e43aff**：有界原launch-modal/radio-SCOUT函数actual0 E0/S0。完整原a05actual54/E1/S0、9f一帧Back54/E1/S0、b62df6cecddb9e3f69ae08a0ec718c88b69f3cb2等待原tween后到radio actual62/E1/S0保留。**full smoke仍未通过**，8906修的是测试fixture，没有生产Title/timeline改动；没有修后整轮复跑。
- 实际native箭头生产fixed **d9c67256545a227c78bf5c3264818b8ad86b2c78** / evidence **57668ec9fe444d8cdfef70da46c6c33d6b2f5bc9**：shared negative83f H26/4actual1→fixed26/0actual0；原a05新yard真实R4404/1与加强Left oracle诊断4140/2actual1保留。fixed新PCK+相同9aceae外部检查器+原a05yard raw真实short **4140/0 actual0 E0/S0**，physical0/logicalRight2971→2977、Left返回2971，8图hash/看1。short明确不含whole。d9c PCK bytes23497556/SHA **b133a1c8aac17fb46ba1455ba1585768c65bb82fbca5d5c0131f7d8004a731ab**、一次import/export各actual0；只REPLAY缺physical箭头回退，其他shortcut/modal/phase/原±6、record/live/sim保持。

## 正在运行，直接接管

08:49:16核对时实际进程与argv已封[process snapshot](evidence/20261004-pr15-safe-checkpoint/processes.json)。以下耗时是该时刻的elapsed，不是预计结束时间；没有任何最终exit/report则不称green。

| 进程 | 工具session / PID | 当时阶段与实际耗时 | 原日志 / 实际exit文件 |
| --- | --- | --- | --- |
| 六a05原件完整3D consumer_d9c | **46384 / 100120** | elapsed620s，yard步骤后已进入warehouse，warehouse原生Right5988→5994/Left返回5988，当前whole；尚无最终report/exit。日志当时FAIL0/E0/S0只是未结束片段 | `/tmp/pr15-d9c-record3d-all-r.log` / `.exit` **尚不存在** |
| FX-A1a共享source负例 consumer_f3a | **39946 / 100567** | elapsed116s，原reference六关已到depot，当前86条缺descriptor FAIL；该功能尚未实现，expected negative。但最终checks/failures/exit尚无，不编造 | `/tmp/pr15-shot-fx-negative-h.log` / `.exit` **尚不存在** |
| 自有Xorg | **8227 / 98510** | :116，elapsed2536s；两轮native复验/长轮使用，保持pc105/us与软件渲染 | `/tmp/pr15-a05-record3d-Xorg.log` / `/tmp/pr15-a05-record3d-Xorg.stdout` |

六记录Guard UUID **992bc5e87f13408e99e54d13d739137b**；output `/tmp/pr15-d9c-record3d/ambush_loop/build/asset_review/pr15-runtime/native-record3d-992bc5e87f13408e99e54d13d739137b/`。生产res代码/资产/autoload全部来自冻结d9c PCK；loose staged wrapper只增加明确entry/shim指向external `-s`。external fixture **9aceae7a15b82e2bbe1c36905dc91a530da7cadda53f54c8566ca705ea5311ac**；`/tmp/pr15-d9c-record3d/receipt.json`、`all-manifest.json`、`native_record_replay_test.gd`、`godot-pck-external`必须保持。每份whole0→原terminal自然2x，无手调advance/sim tick；480000ms是每份whole测试预算，非性能门。cloud CPU cgroup4core、Mesa25.0.7 llvmpipe LLVM19.1.7；软件云慢帧，不是卡死或设备FPS证明。原件目录固定，producer_a05和consumer_d9c分列，旧normal包不可写。

实际启动命令：

```bash
DISPLAY=:116 AMBUSH_TEST_X11_DISPLAY=:116 LIBGL_ALWAYS_SOFTWARE=1 \
AMBUSH_TEST_SOURCE_SHA=d9c67256545a227c78bf5c3264818b8ad86b2c78 \
AMBUSH_CONSUMER_STAGE=fixed-d9c-pck-six-a05-native-records \
AMBUSH_RECORD_SOURCE_SHA=a05fa959093ef5b6733466091a04fbb46647f97b \
AMBUSH_NATIVE_RECORD_MANIFEST=/tmp/pr15-d9c-record3d/all-manifest.json \
AMBUSH_NATIVE_RECORD_DIR=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75 \
bash /tmp/pr15-d9c-record3d/ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-d9c-record3d/godot-pck-external native_record_replay_test.gd --render

AMBUSH_TEST_SOURCE_SHA=f3a906fef21e3f0970851b0e615f94346202466a \
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_source_test.gd --headless
```

负例Guard UUID **05688f4d549f4cb580e353d4b5196d9e**；最终output `ambush_loop/build/asset_review/pr15-runtime/shot-fx-source-05688f4d549f4cb580e353d4b5196d9e/report.json`，继承campaign原参考流程/基线terminal-event-count断言，授枪/snap/directtick/vacuum显式，非normal native。原wrapper/shell在进程退出后实际写对应`.exit`。续任务先poll两个原session/检查exit，封完整日志/report/原件hash/图，之后才改源码/fixture；不要重跑。Xorg等实际native全部结束后按exact argv/display/log只关自有PID，保留actual退出证据。

## 下一步和范围

1. 收取两个现有实际结果。六原件未完成不能称六关3D通过；若新failure先封原失败再归因，不重复旧closed scope。FX负例缺descriptor不是新生产故障，而是A1a新功能负向门。
2. 按[FX-A1a接口计划](AMBUSH_PR15_SHOT_FX_DESCRIPTOR_PLAN_20261004.md)实现原成功callback确认、原末弹换枪前武器/ActorPose、实际伤害后HP差的`payload.fx` schema1；保持BattleLog2/playback2/原身份/时钟/统计。当前只做了计划/test，无生产实现。然后A1b只读R5枪口/有限池actualR与暂停/seek/1x2x/旧缺字段中性；A2工具/烟/脚尘、A3实际指标/优化、FINAL同source全门/newnormal13/new6record3D、可追溯APK。
3. INITIAL QA可并行独立只读；静态教学/escape与六新原件各固定source，不能拼FINAL FX。父端已closed cdb/392/旧railcut等不重开。old schema1真实yard raw兼容、最终完整smoke、FINAL正常旅程/FX-A3/APK仍未验。

资产所有权/接口：R5source29749157c5db064bfea626c3ed9d75d9a1791ece、交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义保持；ArtSource/v2/build_yard_kit.py/共享atlas/角色GLB/Blender/生产manifest不编辑或重跑，未全并WIPf7c30。主集成仍唯一main/input/HUD/presenter/ViewState/replay/runtime-loader/shared test写者，未自行派astra。没有权限/外部阻塞；Android工具链仅只读审查，未安装/导出/签名/APK、未改个人配置/凭据。耳听与设备按全部计划后置。PR15 Open Draft、unmerged；普通push授权，不merge/生产/height/G。网页GPT PLAN/REVIEW unavailable。
