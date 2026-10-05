# PR15 历史契约阻塞与 HUD 诊断执行契约

2026-10-04，接父端明确 QA END/窗口归还（21:25:18–21:50:47 UTC，全部 Godot/Xorg 已停）。继承 [d163 最小诊断计划](AMBUSH_PR15_A3_HOTSPOT_DIAGNOSTIC_PLAN_20261004.md)，原计划的“QA 占窗口”是当时状态，现已归还；不改旧记录。资产作者继续独占制作源/生成器/GLB/Blender/atlas/生产 manifest，主作者只改共享测试及测量后的至多一个运行时候选；不改玩法、预算、回放原件，不 merge/deploy/设备。

## 已实际复现与最小修正

原 source a42（与1879同 game tree ff0de72）Guard/Dummy/headless presentation_contract：84042/2 actual1 E2/S0，UUID c3125df1a3504b138ba44384b85aad4f；原 clock 唯一 SCRIPT ERROR 为第205行 enemies:3，UUID 7f1f6520a1b44c3a9d70e553e3997b7d，所有权按 UID/准确 argv/自有 runner 祖先核后 SIGTERM，actual143 E0/S1，不称自然结束或通过。首次 /proc/environ 读取被权限拒绝，未升级权限，后用上述祖先/UID/argv核验收取；失败日志和 stop receipt 保全。该挂起 clock 曾与 contract-dump 功能诊断重叠约一分钟；都不是性能数据，正式 profiler 必须串行。

外置派生 contract-dump 保留原 _battle/检查，原三个完整 Dictionary 二进制：每组比较恰30个差异，全部是 events[*].payload.fx.attempt_id/event_id/pose.event_id；只归一当前各自随机身份后其余所有值全等。clock 派生诊断保留27原检查，实际入口 tick0/playingtrue/wave0 不含第二波敌人，明确 seek max_tick 后原27/0 actual0 E0/S0。这两项是测试漂移证据，不是“已证明产品全部正确”。原失败不删除、不补绿。

固定仅测试源码 `f275178c0f60a7579685f9823894cafc3386f6da`，game tree `fae983e61e032abd93fbd99f9491c4a90ec57b17`：events 在比较副本上按现有随机前缀规则归一，并先检查原 FX attempt/wave/seq/event绑定；clock 加入口从0播放断言及显式终局seek，保留原骨骼/原件/毒化当前clock的谓词。原门实际 history84045/0（a6d5f5a6859943588709f808213daed3）/clock28/0（7f22d74aaeed41b2aba85a2c88e42894），各actual0 E0/S0，生产/资产 blob 未改。不是 fullsmoke/FINAL。

父端独立 QA 摘要只作其归属证据，不重建私有包：实际schema1选帧13/0、public-copy12526/0、六功能门actual0；其HUD连续直接调用每格n15，tick253/453的HUD中位412.768/429.765ms，含dispatch+call，不含绘制同步，未校准空探针，不是exclusive CPU、全frame比例或唯一瓶颈。本作者接下来用自动callback与独立开关观察补证。

## 当前 P0/P1（启动前声明，结果另封）

生产源码保持1879两productionblob，测试consumer先固定f275。官方4.7.2/local --debug/Dummy/X11GLCompatibility，自有Xorg:127，preexisting:99不动。外置driver沿用完整common4 原record426cf659、tick253/frame43、同20骨/socket/装备/规范化frame/backend/镜头1280×720/standard/自动main+presenter。原59列collector、15,466,496numericbytes、5秒warm、60static/24advancing实际phase行、5秒minimum、30秒cap及首次排除全部保持。完整988 tracked/986 warm/493loader sidecars/sourceengine/archive前后证明，driver/shim另 SHA；原件不更新。

P0 单次 ON 能力预检不进入正式集合；检查 active/has_scripts/is_profiling、prime 分配并关、两段实际开关及停止后的累计输出。prime与边界dump在untimed；每秒内建 latest-frame 输出及计时/排序/日志开销在ON里保留。两侧相同 --debug/日志/prime/collector驻留；OFF在两段inactive。profiling提供 HUD各函数/子阶段self/inclusive/calls，避免另外编辑生产main加入时钟探针。只在证明非嵌套生产root后比scrub/refresh，不把parent inclusive和child再相加；self含原生调用/阻塞，不称CPUcycles。

P0有效后 P1 四fresh UUID OFF/ON/ON/OFF，每轮完整static+advancing，各actualexit/E/S/全部raw/原PNG/逐段FRAME和ACCUMULATED保留，OFF/ON差异是观察扰动，不相减校正FPS。H1仍按d163，两ON完整推进scrub inclusive占scrub+refresh>50%才支持该入口相对更大；静态scrub应无自动调用。另报告_update_hud与所有实际child路径重复排序、calls覆盖、stdout字节、collector开销和RSS。首轮四run若排名/负载不稳，按原声明只追加一次反向ON/OFF/OFF/ON，不能择优。输出缺失/容量耗尽/样本或cap不足保全失败，不放宽门槛。

热点成立前不堆优化。只依重复实测选一个最小可反证生产改动，冻结A/B并在相同原fixture做交错原始/候选比较；还须等价画面/骨骼/socket/HUD/原件/backend和可变副本、旧schema1、source切换/pause/seek/lifecycle合法与拒绝回归。未知域再按d163独立viewport/像素/native门，不能只由draw计数或llvmpipe名称定因。此为启动前状态声明；后续有效profile及候选结果另见下文与结果报告。FINAL/fullsmoke/newnormal13/whole1x2x/all-art/fullgameAPK待。网页GPT PLAN/REVIEW unavailable。

## P0 方法修正（四轮正式开始前完成）

首direct-toggle P0 UUID69ec9e6f9fff4eff9cdbc7348d9ce1c2，471/0 actual0 E0/S0，但在VM函数内部开启导致 driver协程/开启函数出现tcalls0却约31–47秒和>100%行，整体累计分母失真；不计正式profile接受。原driver d0bc88、原log/raw/report/两PNG全部保留。改用native Callable.call_deferred在GDScript栈外启停，两控制同await转场；prime亦改，driver固定SHA256651a177878b3e03289a137c428c680160e7a3e271abcf63640f82ab457a5daf5。timed区间保持原collector样本门，profiler边界另覆盖启停转场的至多少数paused callback，所以函数calls与accepted行分别报告，不冒称逐row对应。

修正P0 UUIDf9cad980fe324785abbeea6c836c0cd8：475/0 actual0 E0/S0；严格原raw检查0，168raw/84accepted，actualstatic8.678887秒/advancing18.538093秒；两个原PNG已核看。每段2226signature（包括已加载但零调用函数，非“2226热点”），<32768；累计self非负且sumself与header一致（.003秒累计打印精度容差），不再出现boot时间冒入生产根。自动推进25scrub/HUD、1250style调用，scrub在scrub+refresh两非嵌套root占99.1516%，style self占HUD inclusive89.7231%；只是预检单轮候选路径，不作为重复热点或全frame比例。静态scrub/HUD calls0。latest-frame与停止累计分开，包含原生API阻塞而非pureCPUcycle。

P1正式OFF/ON/ON/OFF START22:26:35UTC，固定f275/651a driver，启动时按每run strict0才续；该四轮已结束（结果如下），不改源码/HEAD/资源。八原始fixture规则全部保持。四轮完成前不实施候选。

## P1 已结束 / 唯一候选与下一对照（正式八轮前声明）

P1 START22:26:35.853571/END22:31:30.079406UTC，OFF/ON/ON/OFF四fresh UUID每轮actual0 E0/S0/strict0，cross-run strict0；672raw/336accepted，所有规范化source/画面/rig/backend/config严格一致。两ON推进均25scrub/HUD、26refresh、1250style；scrub两root占99.1499%/99.1549%，style self/HUD inclusive89.7386%/89.6209%。style inclusive11.527335/11.599556秒、self11.514230/11.585872秒，HUD12.830856/12.927650秒，refresh.116560/.116752秒；这些不是全frame比例或纯VM计算。static自动scrub/HUD0，operator._ensure_tag_plate另占主要script时间，当前不优化它。

观察开销：两相邻ON/OFF配对static+2.9304%/+4.7251%，advancing+2.2192%/+2.7061%；aggregate wall中位static OFF136.1935/ON140.7850ms，adv OFF709.6780/ON728.0265ms。collector中位OFF239/236us与ON250/256.5us；不宣称零开销，不相减校正FPS。两个ON stdout各1.38/1.40MB，OFF各约.27MB（含共同prime）；同开关/管道/分配保持。输入与排名重复稳定，无需追加反向块；云预算仍未达。

唯一生产候选`541d06440a97dd77f8c484a8de2a0ce364a8d91e`，tree53ffc88566b1ce7bd40daa1ce847c838f04fbd85，仅touch_hud._apply_btn_style新增begin/end_bulk_theme_override及一行注释，四StyleBox仍每次新建独立资源，颜色/参数/modulate/phase/crouch/锁等逻辑原样；不增加cache/早退/共享可变样式。其意图是同按钮5次theme通知收为1次，这是明确的通知次数变化，最终属性与帧需实证等价。[官方Control接口](https://docs.godotengine.org/en/stable/classes/class_control.html#class-control-method-begin-bulk-theme-override)。不是已证收益。

baseline独立sparse worktree冻结f275，仅复制同字节既有cache/493sidecars，不import/生成；baseline/candidate各988source/986warm。可变样式门使用原f275方法作为oracle，所有按钮×锁、所有储存StyleBox属性/font/modulate、保留引用修改/另一按钮隔离/外来override再绘制修复，以及24phase×flags表。仅GUI consumer fixture，非normal战场；先A/B actual0，phase表二进制必须逐字节相等。首次oracle混tab/space解析actual1E1S1保全后仅indent与精确signal disconnect修正，不归产品失败。

随后两同输入Window预检各strict0，再独占八轮ABBA/BAAB，不启profiling，原common4样本门/画面和rig/原件/自动回调/59列保持；外置driver876e53dcc4fd2ce90c6bed20c8010d9996eeebae0d50fbe241c6ffe6f9fbc204另冻结。A/B frame/rig/backend完整同、启动tick253，推进end不同可因实际速率不同，明确非逐帧轨迹配对/whole。前后source证明、全部负原件/PNG/runtimes/RSS/不利pair保留；差异若无稳定方向则如实否证候选，不叠加优化。候选同源码history/clock/lifecycle/旧schema1回归待，不把原f275/QA1879计数转成541d。

## 当前交付主线

最新用户明确先交完整游戏 HTML 可玩站点，APK/JDK/AndroidSDK全部后置；六关13波与原玩法保持。此HUD切片已结束并封存，[最终测量与回归](AMBUSH_PR15_HUD_BATCH_RESULTS_20261004.md)。随后核匹配Web模板、完整Title入口、单线程Compatibility导出与实际静态宿主，再进行浏览器加载/音频手势/输入焦点键鼠触控/持久化刷新恢复/回放及Web性能验证，不把旧preview或原生门转作Web验收。Sites新建游戏预览默认私有，与已删dot状态站点无关。
