# PR15 有限REPLAY HUD分段测量计划（未运行）

2026-10-05，按父端“同私有Site更新之后先给有限分段计划”准备。当前source **1ec3198e9c0db367af96fc264604c5a286003b5e** / game tree **1e8af45ee23098f763acc139b56f8f7e0f41665a**，同私有Site v4已成功。**本计划没有实现timer补丁、导出instrumented包、启动profiler或采样；当前没有函数热点数据，更没有唯一瓶颈结论。** 原yard两速完整播放已独立END，软件功能墙时约3.18×记录长度不等于HUD耗时。

下一包只回答：当前REPLAY一次advance驱动的主刷新中，各声明区间的elapsed时间/call count分布是什么，计时器是否改变原行为或显著扰动帧墙时。它不是优化提案、六关A3正式验收或设备FPS测试；不先删旧2D、跳HUD、降角色/FX/视距、改advance或加缓存。

## 冻结输入与范围

复用已封原yard bin e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5，旧dab producer、新1ec consumer分列。沿用声明paired WON consumer、独立profile/UUID、真实原Replay/暂停/slider/Home/继续。原source/八字段、两cfg/checkpoint、场景、镜头/viewport/scale/标准质量、driver/引擎/资源/PCK全部记录；不打开真实complete profile。若父端QA/产品修改source，先重锁输入/树/差异，不沿用1ec为同源。

P0先只读原帧/event列表，选定并封存一个固定静态frame及一个自然推进区间（原attempt/wave/frame_seq/recorded_phase/PB范围、事件数、装备/骨架/FX签名）。不预编造tick。推进区间须留下≥40秒记录时间余量，测量时不能碰terminal/phase切换；找不到相应窗口则本包报告选择限制，不偷偷换其他原件。静态与推进的视觉/事件负载可能不同，**只在各自相同输入内比较OFF/ON，不能相减就归因“推进成本”**。

## 声明区间

行号是当前1ec的只读定位，不是耗时证据。优先在单独test-only stage按原函数调用顺序加最小计时，生产源不提交instrumentation；QA差异、source/compiled/PCK/原loader逐项证明。计时为 `Time.get_ticks_usec()` 区间elapsed，包含内部引擎调用/可能等待，不标成纯GDScript CPU self或GPU时间。

| tag | 实际入口 | 口径 |
| --- | --- | --- |
| root | main `_apply_replay_scrub`，6670；`_process`5514只有advance返回true才调用 | root inclusive、调用次数；paused正常可能0，不能为正控制强造调用 |
| select/slider | root的snapshot_at_or_before及set_value_no_signal区间 | 选择与slider成本，保原返回与信号语义 |
| paint | `_paint_replay_snapshot`6703 | 历史2D layer清理/重建的inclusive；隐藏不证明慢，不先移除 |
| list | `_fill_event_list`7289 | 原events_up_to/format/list更新区间分别标界；记录实际可见/隐藏、行数，不能由clear/add_item源码推断热点 |
| status | `_update_replay_status`6684 | 原历史格式/pose supported/文字检查inclusive |
| transport | `_refresh_replay_transport`6659 | 原按钮/phase chip更新inclusive，与HUD中的重复child调用要标明 |
| HUD | `_update_hud`7602 | 第一轮整体inclusive；必要且已测占比支持时才下一片细分timeline/checklist/intel/touch，不先铺全树timer |
| presenter | `presenter_3d._process`/`refresh`254 | 单列，避免把未计到的3D刷新算成HUD或拿root覆盖整个帧 |

root及child计时有嵌套，不能将inclusive列直接相加。声明的非重叠root区间与root remainder分列；remainder含未覆盖调用与计时开销，不能称CPU空闲。还须记录每frame调用次数、actualadvance、tick/selectedframe、actual view tick、presenter次数；paused static root0是有效负控制，presenter实际正计数才证明计时器活动。没有计到的worker/GPU/同步等待均unknown。

## 有界执行门

1. **P0能力/中性门≤120秒**：独立actual Guard，test-only patch完整diff，定长buffer/满池拒绝、reset/输出schema/positive timer与paused负控制；原record/domain/cfg/checkpoint与canonical画面/20骨/socket/装备签名保持。仪器缺source/timing/非空样本或破坏原调用时失败封存，不扩成优化。不会因解析成功就认runtime能力通过。
2. **一个source、四个串行RUN**：OFF→ON→ON→OFF，同一个instrumented source（OFF仍有branch成本，明确限制），每RUN只含上述静态与推进两窗口。每窗warm2秒、collect20秒；每RUN上限90秒，整个包含P0/启动/收尾上限600秒。正常输入重新定位相同frame/区间；每phase至少12个真实有效样本，不足即UNMEASURED，不无限延长或挑样补数。
3. **buffer/输出**：每窗口最多2048帧、固定tags，异常overflow即无效；量测时不逐帧print/磁盘append/图片截取/RPC全指纹，段后一次输出。原producer不再跑，record/domain/fullcfg指纹在段前后核，计时raw与观测frame/present cadence均封存。
4. **结果判断**：报告每tag inclusive median/p95/call count/零样本，以及独立postdraw wall分布、ON/OFF配对方向/漂移。仪器扰动若高于相同OFF重复漂移或方向不稳定，先方法修正；不能从OFF/ON数据直接断言某函数导致整帧慢，也不能把inclusive从wall扣掉当剩余GPU成本。只有稳定可复现的区间贡献才支持下一单一优化切片与同输入parity/A-B。

启动前补实际driver/patch/原frame区间/同host与软件renderer身份和cap原receipt；每RUN START/自然END/actualexit/E/S/Guard、独占window/HTTP/console、无效样本原因、原raw/hash/图像签名保全。结束收齐所有自有engine/browser/controller，再交父端独立QA。本计划本turn未运行；不自行起后续热点全量扫描或其他五关，不派agent/资源制作、不宣称全13/A3预算/设备已过。
