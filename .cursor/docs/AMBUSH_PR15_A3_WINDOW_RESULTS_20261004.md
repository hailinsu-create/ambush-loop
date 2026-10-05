# PR15 真实Window前置与开销对照

2026-10-04。主作者独占Window，父端QA7与Xorg146已实际结束；本轮完成仪器前置，正式六关A3尚未启动。单engine串行，官方4.7.2，独立显示:124。网页GPT PLAN/REVIEW unavailable。

代码初稿b832587e9097acc78f69be4486cdf8587a014385未运行，经source-only审查修为 **42249dfd4e753c2d994bea4aa8c2d0f73159ce44**。实际Window consumer **1dabd57d6694ef4630c9362086048ae818d3fd9f** 是文档提交，game tree与42249完全相同：`afd420c76a93d2af163d4805a774135799bfe6d8`。离线分析硬化 **7c968f4baa6bb1b0d2fdaf3486d67e4daa46cb54** 仅Python，在两个engine自然结束后分析同一原raw；不冒称新Window运行。

新完整proof SHA256 `771ed8c6b1b6208942c843452805044adf9bf9cc57c1df9108e307b8d19cbcdb`，986 tracked source/986 warm imports/官方engine/原schema1记录before-after全核。旧b832 proof仅保留为未运行历史，没有复用。原schema1 producer874d350/5418800bytes/SHA1de456c1…为caller-declared来源、实核bytes，不用它伪称新FX记录。

## 实际命令与结果

先 `python3 ambush_loop/scripts/prepare_a3_provenance.py --engine /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --output /tmp/pr15-a3-window-controls/provenance-1dab.json --record yard=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin --producer-sha 874d3501fdd2b34b0966472e22a9e43a28a1b3dd --include-import-cache`，actual0。

两条真实Guard命令均设置AMBUSH_TEST_SOURCE_SHA=1dabd57d6694ef4630c9362086048ae818d3fd9f、AMBUSH_A3_GAME_TREE=afd420c76a93d2af163d4805a774135799bfe6d8、AMBUSH_A3_PROVENANCE_FILE=/tmp/pr15-a3-window-controls/provenance-1dab.json、DISPLAY=:124：

```bash
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 a3_collector_probe_test.gd --render
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 a3_collector_overhead_test.gd --render
```

probe UUID4372677ae2654d29a8119d065301949d，**37/0 actual0 E0/S0**；three original nonoverflow chunks35/27/56raw、20/19/14accepted，三个原CSV不覆盖、absoluteframe/usec递增，两次合法reset，restart只有一个callback，Title实际释放原host与newyard绑定newattempt，collector freed后实际disconnect，source/warm/engine/receipt保持。三张原1280×720 Window crop outside timing全部hash并逐图查看：yard/真实Title/reboundyard。图用于场景与生命周期核验，不是完整艺术、normal13或设备接受；原HUD其他节点仍有显示状态，未声称所有像素静止。

overhead UUID0b223a23a4d145438bb1aa6e441d9752，**168/0 actual0 E0/S0 windows16**；两family各ABBA+BAAB八条件，每条件2s untimed settle/4s requested timing，实际各组32.615101/32.749987s。公共cadence16列/32768/4194304numericbytes常驻两侧；collector59列/32768/15466496numericbytes，完整buffer family baseline无实例，resident family相同buffer常驻但off没有collector callback。sampler重接在collector前；samebackend/fullpresenterframe/camera/config哈希before-after保持。688原cadence行/441accepted，八collector chunk346原行；cold/transition/settle仍封存不作accepted。

离线原分析器1dab和硬化7c分别actual0，原raw unchanged。命令为 `python3 ambush_loop/scripts/summarize_a3_window_controls.py --project /workspace/ambush-pr15/ambush_loop --report /workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/a3-overhead-window-0b223a23a4d145438bb1aa6e441d9752/report.json --log /tmp/pr15-a3-window-controls/overhead-1dab.log --exit-file /tmp/pr15-a3-window-controls/overhead-1dab.exit --output /tmp/pr15-a3-window-controls/overhead-summary-hardened.json`；硬化绑定exactfamily indexes/distinctpaths/named59header/全部numericfinite/timer≥0/monotonic/计数/lifetimeflags/原receipt hashes/相同cadence condition receipt，保每block counter分布。不存在新engine或67功能重跑。

## 实测含义与限制

所有16窗口render counter中位数同589draw/89533primitives/1400objects；每block min/max/quantile保留。这证明本控制的median负载匹配，不是每frame geometry或像素相等证明。主线程main与presenter自动process均关闭；camera focus0/yaw35/pitch55/size24，1280×720/scale1、standard、max_fps0、记录actualvsync0、Dummy audio。驱动打印一次不支持切换V-Sync warning，保原log，不能只根据请求说禁用成功。

| family | baseline/attached interval median | callback median/max | 四adjacent block delta范围 |
| --- | --- | --- | --- |
| full buffer | 142.484/141.083ms | 221/330µs | -8.8635…+2.330ms |
| resident callback | 141.256/139.2455ms | 221/521µs | -6.2785…+0.261ms |

四对顺序差与资源漂移大于本callback计时，不能据负delta声称加仪器更快或零开销，也没有把callback_usec从interval相减。各family样本108/110及111/112，短窗口p95/p99与linear(n-1)q仅描述原sample；无独立frame CI、长期稳定或手机FPS结论。完整buffer paired RSS_start差5.083136…25.194496MB，resident差-1.282048…10.911744MB；RSS包含allocator/page residency/其他engine驻留变化，不是buffer payload的精确归因，不减去payload。

环境AMD EPYC7763，可见5CPU/cpuset0-4、cpu.max400000/100000、memory.max17179869184；仅visible mountroot，不证明host独占。Mesa25.0.7 llvmpipe LLVM19.1.7，Compatibility/OpenGL3、X11；GPUtime unavailable/pipeline support unknown/raw0不能证明没有编译。warm imports已核，不称coldimport/engineboot全成本。采集器callback可在这些有界原Window条件工作，后续正式A3仍带开销和漂移限制，不因本片接受动态战场。

两个Godot session28956/11950均自然actual0已收取。owned Xorg124 PID117451按UID1000/精确实际argv核验后SIGTERM，wrapper session17194 actual0已收取；无待poll，无自有activeengine/display，旧常驻:99未动。首两ownershipcheck因/usr/bin/Xorg launcher路径假设安全拒绝signal，读launcher确认/usr/lib/xorg/Xorg后才关闭。原external CSV检查先错误用字符串1匹配实际1.0而assert失败，仅数字parse修正，无engine重跑/数据更改。两项保在原receipt说明，不当产品反例。

[证据manifest](evidence/20261004-pr15-a3-window-controls/manifest.json) 99列出文件/3982214bytes（manifest自身另计）全部sha/bytes核验，包含全部raw/metadata/log/actualexit/proofs/原3PNG/固定source/两个offlineanalysis/只读报告/source修正历史/容量/Xorg收尾。差分只七个test-only脚本/allowlist路径，生产源、R5/ArtSource/build_yard_kit/GLB/Blender/atlas/assetmanifest保持。原readiness功能67/0范围独立不相加。

## 待验与直接下一步

正式六关A3尚未启动。先实现并固定test-only六关真实source workload：原reference资源/snap/直接推进均标untimed，timed用original live callbacks/明确暂停历史render；列实际SCOUT/ALERT/SWEEP/WON/FAILED/REPLAY、8yaw/35&65pitch/近远与两policy代表性组合、成功shot/blast/保存移动cue来源，source身份与池峰值。不得复制或伪造FX填池；old INITIAL只兼容，不作新FX负载。按有界chunk保存cold/transition/firstFX及warm，START/END报告source/config/unsupported与llvmpipe范围。

再基于实测选独立优化，同输入/原记录/原terminal/HP/ammo/inventory对照；FINAL锁同source全门/fullsmoke/new正常13波/六新完整1×2×3D与pause/seek/eventfocus/旧schema1→可追溯fullgame APK。完整枪/姿态/LOD/战场艺术/长期驻留仍未接受；需要制作改动先由独立资产工作者验交commit，不编辑或重跑制作源。Draft不merge/发布生产/height-G，耳听/模拟器/真机按用户顺序后置。
