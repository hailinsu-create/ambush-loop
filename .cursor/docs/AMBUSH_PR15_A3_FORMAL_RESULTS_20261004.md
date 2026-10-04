# PR15 A3 六关原始云端负载结果

2026-10-04。本切片完成六关 A3 实际来源采集与离线核验，生产性能优化尚未实施。PR15 保持 Draft，不合并、不发布，不引入高度射击分支。结果替代 [workload 计划](AMBUSH_PR15_A3_ACTUAL_SOURCE_WORKLOAD_20261004.md) 中“4a8 修复未运行、正式轮未开始”的当前状态；其中旧失败与来源限制继续有效。

## 固定来源与实际执行

- 原始运行 consumer：`a90eb0798914c023f5c8902303c72f2619abd7c2`。
- 采样窗修复代码：`4a8ed5e60136e3cb813c371cd4efd07e03101d1b`，只改测试仪器；生产、模拟时钟、手雷引信、资产制作不变。
- 游戏树：`ec73ed78833b5608919ae98e39ba7a58c4e03f41`。
- 官方 Godot：`4.7.2.stable.official.ed1daf0bf`，executable SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`。
- fresh 来源收据 SHA256：`518a491147e611af930253111744d382230853a30184070ea3dc0c5bac52d882`；988 个 tracked 工程文件、986 个完整 warm import、engine、旧 schema1 原件前后匹配。旧记录只核原 bytes，本 A3 没有加载它，不能借此称旧记录兼容通过。

先同冻结 a90 运行 warehouse 修复预检：UUID `f82c7c15662d4846849e8845b23ef77a`，START `18:56:33` / natural END `19:05:00 UTC`，**4064 checks / 0 failures，actual exit 0，anchored ERROR 0 / SCRIPT ERROR 0**。strict 离线 actual0：1742 raw / 1350 accepted / 108 segments / 96 unique historical views / 10 原 PNG，全部 hash 核验并逐张查看。先前失败的 SCOUT-command 窗口实际 wall `2.706116s`、3 个 measured phase0 样本，排除首帧保留。原参考两波315/876、global1191、67 events、WON。

其后保持同一 source/HEAD/engine/warm 收据，开始全六关独立新轮：UUID `bc8eae712ba64d45884041cc92e7f7e5`，**START `2026-10-04T19:06:43Z` / natural END `2026-10-04T19:54:21Z`，23559 checks / 0 failures，actual exit 0，anchored ERROR 0 / SCRIPT ERROR 0**。实际引擎 PID121842 自然结束，wrapper session27222 completion actual0 已收取；owned Xorg125/PID118843 在 END 后核 owner/argv，仅关闭该进程，session23446 completion actual0 已收取。常驻 Xorg99/PID1764 未动。本轮无并行 Godot/perf/QA 引擎，无 kill/restart，无中途代码或 HEAD 变更。

实际命令如下；不是另起或重复运行的命令建议：

```bash
# START/END/actual exit/log 包装脚本保存了完整环境变量和唯一原始调用。
bash /tmp/pr15-a3-window-controls/run-a90-all.sh
# 脚本里的实际 Guard 入口：
bash ambush_loop/scripts/run_isolated_test.sh \
  /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
  a3_campaign_metrics_test.gd --render

# END 后，对同一原 report/raw/receipt 做严格离线核验；actual exit 0。
python3 ambush_loop/scripts/summarize_a3_campaign.py \
  --report ambush_loop/build/asset_review/pr15-runtime/a3-campaign-bc8eae712ba64d45884041cc92e7f7e5/report.json \
  --proof /tmp/pr15-a3-window-controls/provenance-a90-all.json \
  --output /tmp/pr15-a3-window-controls/a3-all-a90-analysis.json

# 同一 END 原数据的 p99/RSS 补充分析；actual exit 0，无新 Godot。
python3 /tmp/pr15-a3-window-controls/extra_campaign_stats.py \
  --report ambush_loop/build/asset_review/pr15-runtime/a3-campaign-bc8eae712ba64d45884041cc92e7f7e5/report.json \
  --strict /tmp/pr15-a3-window-controls/a3-all-a90-analysis.json \
  --root /workspace/ambush-pr15 \
  --output /tmp/pr15-a3-window-controls/a3-all-a90-extra.json
```

## 来源、覆盖与原件

strict 实际通过：**6 levels / 13 waves / 10047 original raw rows / 7782 accepted rows / 650 declared segments / 576 unique representative historical views / 60 original PNG / 12 original archives**。每关独立 collector/chunk/instance，局部 callback sequence 与全局 ticks_usec 合并身份；overflow/symbol overflow 均0。首帧、cold、untimed、正常 phase transition 原行全部保留，accepted 不覆盖这些原行。每声明窗口至少3个实际 requested-phase measured 样本，新 receipt 的实际 count 与 wall 下限严格匹配。SOURCE proof 与 source/presenter/backend/hash/camera/policy/record/frame/seq/wave/phase 同域核验，无把前一失败轮 partial 拼成全绿。

| 关卡 | 原 wave terminal | global terminal | 原 BattleLog events | 原终端 |
| --- | --- | ---: | ---: | --- |
| yard | 1056 / 227 | 1283 | 34 | WON |
| warehouse | 315 / 876 | 1191 | 67 | WON |
| pump | 231 / 676 | 907 | 34 | WON |
| railcut | 117 / 602 | 719 | 38 | WON |
| depot | 566 / 391 | 957 | 35 | WON |
| radio | 574 / 391 / 448 | 1413 | 51 | WON |

这是原 API/reference preparation 和自然 main/presenter callbacks：untimed 显式 tutorialseen、授枪/工具、reference cover snap/vacuum helper；timed SCOUT movement、ALERT 自然模拟到 SWEEP、pause、commit、WON。没有直接 timed tick、时钟加速或补造 FX。另各关原 API grenade 消耗库存，原 fuse/boom 后保存 confirmed tool，再原 alarm/abort 得到 FAILED(reason=abort)。这不是自然火拼失败、新正常玩家 journey 或自然 progress 验收。

历史来源取实际保存的 SCOUT 移动、ALERT confirmed shot、SWEEP 移动、WON、confirmed tool、FAILED，每来源2策略×8 yaw代表性 pose，交替 pitch35/65与extent12/36；每关96/all576。每来源完整64 Cartesian pose 中仍省略48。REPLAY 自动1x/2x仅各3秒有界窗口，不是整轮回放。PNG每关10张，包括 live SCOUT/pause/WON/abort 和六来源的 first standard/yaw0 图，不是576窗口全截图。

60 原 PNG 全部按 report SHA 核验并通过 view_image 逐张检查，无改图或仅凭 montage。Yard/warehouse/pump/railcut/depot/radio 主题、HUD、选取的移动/confirmed-shot/tool 可见；地图居中、近 extent12 的终局历史视图把部分角色裁到边缘或画外，depot/radio 的 FAILED 原图尤其明显。保留原图和逐张 [visual ledger](evidence/20261004-pr15-a3-actual-source/formal-a90-all/visual-review.json)，不把这一代表性采集视角当全部角色艺术或事件聚焦验收。Radio 原 WON frame 还有实际保存的爆炸/烟环；没有因标签为 WON 就清除历史效果。

正式包 [manifest](evidence/20261004-pr15-a3-actual-source/formal-a90-all/manifest.json)：120 listed files、103391168 bytes（manifest本身另计），SHA256 `ae17b43c15676e8ccfe5aa01e2b4d597dec9d0c978c2a8edd9da721f9821624c`。包含逐字节原 output、12 archives、60 PNG、6 raw+metadata、report、strict/补充分析、actual exits/logs/start/end、receipt、冻结测试源码/双 Guard、owned-display closure及只读后续计划。Warehouse 预检另包，结果不与正式轮累加。

## 云端预算结果

本域1280×720/scale1、maxfps0/actualvsync0、Linux13/X11、Mesa25.0.7 llvmpipe LLVM19.1.7、gl_compatibility、Dummy audio、official debug executable；main/presenter 自动 process，SceneTree未暂停。可见CPU EPYC7763、5CPU/cpuset0–4、quota400000/100000、memory.max17179869184，不能证明独占宿主。warm import核验不等于 cold asset import 或 cold boot。

下面为13波各原 live-ALERT 段的 requested-phase postdraw 原间隔，单位ms；实际 transition rows仍留原raw，未混入这些统计。不同 segment 的样本数不同；这些尾部百分位是描述本轮数据，不表示长期稳定置信界限。

| 原 segment | n | median ms | p95 ms | p99 ms | max ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| yard wave0 | 127 | 827.662 | 934.877 | 1188.781 | 1562.952 |
| yard wave1 | 27 | 329.780 | 993.854 | 1142.502 | 1182.466 |
| warehouse wave0 | 34 | 885.332 | 972.567 | 1061.565 | 1104.837 |
| warehouse wave1 | 108 | 652.597 | 1022.789 | 1129.305 | 1735.237 |
| pump wave0 | 23 | 941.589 | 1016.331 | 1055.004 | 1065.638 |
| pump wave1 | 83 | 465.084 | 950.391 | 1007.913 | 1058.621 |
| railcut wave0 | 9 | 949.164 | 1055.478 | 1092.204 | 1101.386 |
| railcut wave1 | 74 | 635.698 | 1024.580 | 1074.113 | 1079.433 |
| depot wave0 | 65 | 405.458 | 998.946 | 1009.224 | 1010.452 |
| depot wave1 | 47 | 883.866 | 960.039 | 995.748 | 997.262 |
| radio wave0 | 66 | 656.340 | 1011.460 | 1029.950 | 1050.500 |
| radio wave1 | 47 | 355.176 | 1012.146 | 1049.247 | 1063.417 |
| radio wave2 | 54 | 666.620 | 991.072 | 1349.969 | 1709.817 |

650声明段中每个已汇总 requested-phase 原样本超过33.333ms与16.667ms的比例均为100%，云端目标预算未达。短 entry/SCOUT/pause/SWEEP/advancingREPLAY 多只有3样本，不能据此概括尾部或 pause 成本。`TIME_PROCESS` monitor有更新延迟，不能与同row postdraw interval等同，不能作为函数CPU profile或相加减。GPU time unavailable、pipeline unknown；不从高 draw count、低 physics monitor 或软件渲染推定唯一CPU/GPU瓶颈，也不减去 collector time制造校正FPS。

同关 exact saved confirmed-shot/source/backend/frame/pose/配置一致的 yaw0，两策略本轮 median 如下：

| 关卡 | standard n / median ms | power_saving n / median ms |
| --- | --- | --- |
| yard | 11 / 175.271 | 11 / 176.636 |
| warehouse | 10 / 182.749 | 10 / 196.519 |
| pump | 10 / 197.698 | 9 / 204.706 |
| railcut | 10 / 192.746 | 10 / 196.132 |
| depot | 9 / 202.631 | 9 / 200.510 |
| radio | 9 / 216.410 | 9 / 221.735 |

仅 depot 略低、其余方向相反；短而顺序执行的窗口，无重复交错A/B控制，不能称省电策略普遍提速或统计显著。也不能跨a44/a90不同source/phase/window做优化效果比较。

每collector packed storage15466496bytes。全轮首次ready RSS264286208bytes，radio save RSS1061249024bytes；后关ready包含前关原archives/driver/cache驻留。全raw对象/节点/资源观测max最高6803/2164/749，orphan nodes各关全row0。资源/内存/节点原first/last/max与所有RSS marks在补充分析，随 level/不同资源和resident drivers变化，既不证明泄漏也不证明无泄漏/长期驻留通过。FX为postdraw观测占用，不保证捕获两个低帧率回调之间的所有短flash或绝对战斗峰值。

## 下一切片与未验门

下一独立运行时优化候选：`asset_library.asset_record()` 当前公开返回 deep copy 保留；`model_path/has_asset` 与 presenter category 查询改用内部validated catalog的窄scalar读取，避免反复复制64clip metadata。这是已读源码机会，尚无实测成本归因或性能提升结论。只动运行时主作者文件，保持revision/LOD/unknown/invalid boundary、public复制隔离、material/release/reload、骨骼/socket/animation fallback、source/pose/FX/模拟状态完全等价。先 meaningful parity/实际回归，再冻结 baseline/candidate 与同原record/config/sourceframe/payload，单engine交错重复A/B/ABBA、足量样本，另测 advancing pose，比较分布/RSS/resources，保失败原件。具体 [readonly admission](evidence/20261004-pr15-a3-actual-source/formal-a90-all/readonly-a3-budget-review.md) 不代表已实施。

FINAL尚未完成：同最终source的全部相关shared gates、full smoke、新原native正常玩家六关13波与fresh六record、每条新record分别完整自动1x与2x、实际旧schema1兼容、全部十枪动作/3LOD与五主题艺术/长期驻留/耳听。INITIAL旧source成功、短transport和本API/reference结果不补这些门。

资产接口保持：资产作者独立source/GLB/Blender/atlas/asset-author manifests，提交准确source/export commit、逐文件SHA、manifest版本、骨骼/socket/64clip/LOD规格、实际参考证据后按验收范围接收；不全合WIP。当前引用的build_actors.py/build_environment.py制作源在checkout缺失，技术hash符合不等于艺术接受。只读资产接口和FINAL步骤随正式包保存。

APK仅只读工具链计划：匹配4.7.2 templates/SDK仍未设置；Java21已在环境，不能仅缺17就定硬阻塞。fullgame导出必须保Title主场景并开启现有`mobile,a0_preview`使完整3D运行，不直接复用把主场景改为preview_boot的旧预览导出。下载/安装/导出/签名/设备本轮均未做；APK后续附source/engine/template/tool/stage/import/boot签名与artifact证据。模拟器/真机继续按用户顺序在全计划之后讨论。

旧负向不撤销：5b305 yard410/2 actual1、e871缺tree启动1/1 actual1、同e871 grenade2940/2 actual1、a44正式all8189/2 actual1（只有yard/warehouse、后4关未跑）。各原source/raw/PNG/actual退出均在旧包；失败说明驱动采样/fixture问题，不借绿label否定或重写。新轮与旧轮保持独立身份。本报告不宣称A3优化、FINAL、全计划、战场艺术、安卓30/60FPS或设备性能已验收。
