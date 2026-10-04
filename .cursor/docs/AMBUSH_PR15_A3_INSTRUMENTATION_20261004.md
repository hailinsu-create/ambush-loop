# PR15 A3仪器修正切片

2026-10-04，接43908安全checkpoint及父端指示：先本地代码/headless检验，固定候选后报；父端当前两个reader/render窗口结束并协调串行窗口前，不启动正式performance引擎。此片仅test-only仪器，不修改游戏运行代码或R5制作资产。

目标：将动态rows改为预分配有界数值表、计时覆盖采集写入、明确采集器payload/static/RSS口径；为monitor写supported/unsupported/unknown及冷帧可用性；生产场景切换前接入post-draw钩子；source/engine/全部tracked游戏文件与可选producer原record在计时窗外核实际SHA256。满表/错源/缺presenter保留明确失败/排除，不能静默覆盖原冷行或制造phase零指标。

验收：官方4.7.2隔离wrapper headless功能检验（不作performance量测），覆盖真实来源receipt及错commit/hash/record负向、headless/enum缺失/release/Compatibility pipeline支持矩阵、有界容量/溢出首行保留/完整CSV输出、提前钩子与无主场景/释放host生命周期、无source字段写入。预分配内存与计时范围不推GPU/手机FPS；真正Window冷帧/采集开销对照/六关正式A3仍待父端串行窗口。

官方依据：[Performance](https://docs.godotengine.org/en/stable/classes/class_performance.html)说明部分monitor受debug/release影响及可延迟更新；[RenderingServer](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html)说明渲染计数初始帧可能尚不可用，OpenGL没有RenderingDevice；[PackedFloat64Array](https://docs.godotengine.org/en/stable/classes/class_packedfloat64array.html)说明64位紧凑存储。该文档支持范围解释；具体4.7.2行为以实际headless/后续Window证据为准。

当前：准备实现/检验；六关正式A3尚未启动，没有自有engine/Xorg待poll。后续先固定仪器报告，再在父端安排的窗口单engine采实际六关；必要优化→FINAL fullsmoke/newnormal13/六新全1×2×3D→可追溯APK。父端4484独立QA与旧limited closures单列，原失败/无效probe不删，不重开旧closed门。R5资产所有权、SCOUT→ALERT→SWEEP、Draft不merge/生产/height/G及耳听设备后置保持。
