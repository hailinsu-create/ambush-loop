# PR15 A3 readiness与固定receipt作者功能候选

2026-10-04 16:28 UTC，父端把实际Window窗口暂交aa8独立QA，明确本轮只补readiness/receipt和headless轻检。作者未启动Xorg、Window或performance；唯一headless合同已actual0结束、句柄收取，无本作者待poll。正式A3没有开始时间、采集配置或进程。

固定test-only源码 **8b37c31b0bc833c51862e4eb9ae01ca10bb3ffca**，game tree **a4990e991d1b3b635d76c454ab3e16d319ffa43d**。原b63封存未应用patch现应用为候选，旧封存事实保留；代码变化只有a3_render_metrics.gd与a3_collector_contract_test.gd。原main/ViewState/presenter/三FX reader及pool共九production blob逐项与b63相同，typed生产aa8仍可固定QA，R5制作/GLB/Blender/atlas/productionmanifest没有修改或重跑。

实际官方4.7.2 Guard headless合同 **67/0，actual exit0，ERROR0/SCRIPT ERROR0**；UUID **908a622a5ae94a7aa38361a1130adcbb**。只一次有界功能轮，没有Window、自然render帧、开销或六关性能结论。源/runtime/receipt/log/exit/只读报告/九blob证明封在[34文件manifest](evidence/20261004-pr15-a3-ready-receipt/manifest.json)，3,963,207bytes全部核hash，没有PNG。

measured行现在明确要求actualpresenter有效、非首转换行、render counters-ready、完整source且非空warm-import proof。前两draw不就绪保留raw但排除；headless仍全部不测，空warm清单明确reason=warm_import_proof_incomplete。save要求before/after receipt实际SHA相同且两端非空warm清单，不允许各自valid的换版receipt冒充同一来源。坏chunk原CSV/metadata先封存、ERR_INVALID_DATA拒绝，默认reset拒绝；已有整轮overflow/incomplete不清零。

新增功能控制均明确手动_sample：原yard自动process关闭，读取已有presenter.frame；两合法非overflowchunk先save OK、reset成功，再新path save OK，原第一CSVhash保持、全局frame/time递增。另两owned receipt副本只在计时外操作：source有效但warm清单空；同source/engine/cache/record字段但hook后增加receipt note而bytes换版。后者两个proof各自verified=true仍被receipt-stability门拒绝。原backend/库存/events/记录、原receiptbytes和环境变量保持。旧源码曾错误接受这两种chunk只是原代码审查，本轮没有重跑旧源码反例，不扩大为普通玩家可达故障。

| 实际raw chunk | 行数 | buffer/proof有效 | receipt固定 | warm完整 | 保存结果 |
| --- | --- | --- | --- | --- | --- |
| 原capacity12故意overflow11 | 12 | false | true | true | ERR_INVALID_DATA |
| 合法first | 2 | true | true | true | OK |
| 合法reset后的second | 2 | true | true | true | OK |
| 空warm清单 | 2 | false | true | false | ERR_INVALID_DATA |
| hook后换receipt | 2 | false | false | true | ERR_INVALID_DATA |

20原raw行均59列、measured0、render-counter-ready0；逐CSV实际SHA和metadata一致，callback字段有限非负，但数值不作性能统计。合法buffer seal不等于render/performance接受。实际982 tracked文件117,580,488bytes/986现存warm imported55,647,094bytes及engine/旧schema1record before-after匹配；原receiptSHA256 **1ef3414165fa19b605875a6ba4bdd58b8b57399d0ef3ae0855287324edcf817f**。warm-cache没有重新导入，不是cold import或engine boot测量。producer874在helper仍caller-declared，原record和封存manifest对应关系单列。

实际命令（仓库根，source已commit且测试期间HEAD/代码冻结）：

```bash
python3 ambush_loop/scripts/prepare_a3_provenance.py --engine /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 --output /tmp/pr15-a3-ready-receipt/provenance-source.json --record yard=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin --producer-sha 874d3501fdd2b34b0966472e22a9e43a28a1b3dd --include-import-cache
AMBUSH_TEST_SOURCE_SHA=8b37c31b0bc833c51862e4eb9ae01ca10bb3ffca AMBUSH_A3_GAME_TREE=a4990e991d1b3b635d76c454ab3e16d319ffa43d AMBUSH_A3_PROVENANCE_FILE=/tmp/pr15-a3-ready-receipt/provenance-source.json bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 a3_collector_contract_test.gd --headless
```

现有6.1-sol只读工作者针对8b source报告未找到阻碍性source问题，但没有engine或读取本轮67结果，不冒称独立测试接受。actualcounter-ready、真实post-draw seal/reset/restart/Title解绑和paired开销仍待。

最小Window计划已经准备，**必须等父端QA结束通知后执行**，步骤详[Window控制计划](AMBUSH_PR15_A3_WINDOW_CONTROL_20261004.md)。先扩原probe为真实两个chunk/reset/restart/原Title释放再yard重绑（当前probe仍未扩），同时将该entry的Window音频改为wrapper Dummy；固定新driver/source并新prepare完整receipt，不能沿用8b旧receipt。配置拟官方4.7.2、Compatibility、独立owned display、1280×720/scale1、standard、原camera固定、uncapped并记录实际vsync；实际driver能否变vsync按raw，不虚称成功。记录source/tree/engine/cache/backend/adapter/cgroup/画面配置与unsupported矩阵：pipeline兼容后端仍unknown，OpenGL无RD GPU计时，release static/orphan若unsupported保留-1，不用0作无成本。先有效Window功能门通过，再公共cadence采样器两侧同驻、完整buffer有无与同buffer attached/unattached ABBA/BAAB控制；它们仍是冻结yard仪器控制，非正常六关性能。

Window两步结束封存后再正式A3 START报固定来源/实际配置/unsupported和owned进程，END报实际exit/raw/hash/限制，所有performance与父端QA串行。正式六关phase/camera/actualsource FX峰值及同record/standard-saving预算→必要独立优化→FINAL同候选全门/fullsmoke/new正常13波/六新sealedraw真实全1×2×3D→可追溯APK仍待。llvmpipe绝不作手机30/60FPS或热稳；自然艺术/全枪姿态LOD、耳听与设备阶段未验。Draft PR15普通push，不merge/生产/height-G，资产单写接口保持。
