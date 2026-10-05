# PR15 fresh Web 原输入 driver 契约

2026-10-05。**SOURCE_PLAN；driver/观察桥实现、导出和实际 campaign 全部 UNRUN。** 父端将重活窗口交独立 QA 复验小配置存储，本包只读原代码、整理输入契约并做 Git/JSON 轻检；不启动 engine/browser/HTTP，不移动主 QA 工作树 `b46c31c008ae8dea700b3c36ad9b514e68b7e1ac`。网页 GPT PLAN/REVIEW unavailable。

本文件和[机器输入 spec](AMBUSH_PR15_WEB_NATIVE_INPUT_DRIVER_20261005.json)细化[83a7 fresh 计划](AMBUSH_PR15_WEB_FRESH_CAMPAIGN_PLAN_20261005.md)的 driver 部分，预算保持。旧计划正文里的 1d17/未发布段落属于历史准备；本包固定 **dab870595175eed37a6d2a012bc69a76062d48b0 / game tree 4f49a7c9cb5a789fbb570bceb947eab7df2eb54a**，同 Site 已是 version2。旧 a05 的 Library 缺包和独立 PCK +32B 未解不阻塞六份新 Web 记录的独立生产。

## 固定候选与所有权

生产候选使用已导出的完整 Title 工程：release PCK 38,082,080 bytes / SHA256 `2d8eac7f8be1d7931762f5c31364c5695eef912d23fd193a7389eb967af4c0b6`；WASM 39,514,754 / `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。已有 debug/release 实际导出结果见[存储修复报告](AMBUSH_PR15_WEB_STORAGE_REPAIR_20261005.md)，当前不再导出。Site source `aa19d5b03c014c3483a2b98320018ea3e4e02042`，version `appgprj_6ac2e89b4db08191b308c175371ee7c6~appgver_0011120092a88191bf67cace12146522`；发布成功不能替代生产 origin 实际浏览器验收。

Root 继续独占 main/runtime/presenter/ViewState/replay/UI/loader/共享测试和 Web 运输。制作源、generator、GLB、Blender、atlas、作者 manifest 仍归资产作者，本包不写不重跑。新 driver/controller/只读观察桥只在新的隔离 QA stage 与证据目录，不能成为正式资源或生产 autoload；不调用旧 `web_qa_bridge.gd` 的 load_record/restart_scout 等 mutation。

观察桥会改变隔离 debug 的 autoload/project/PCK，因此**其 PCK 另给 SHA，不能声称与已发布 PCK 字节相同**。建立生产 Git blob 固定清单；fixture 仅新增观察桥及登记的注册差异，导出后逐项审计 PCK 差异，非允许项即 BLOCKED。实际 source/game tree、fixture/bridge SHA、浏览器 profile/origin、视口/DPR、renderer 和 observer 开销分开记录。spec 的 source pin 取固定 dab 的原字节，不以新文档 commit 冒充重导出。

## 从原生 driver 迁移什么

只读参考 `first_visit_journey_test.gd` 的 `_collect/_world_click/_deploy/_mission/_sweep/_place_mine` 与原进度/记录格式；**不继承或运行它及父类测试**，不移植 resume seed、测试 fixture、XTest/OS.execute。原生 `_world_click` 会按实际物理像素检查 3D pick，并经原 ↷ 摄像机 UI 最多旋转 12 次；Web 也先检查 CSS→canvas→逻辑坐标和 DPR 映射，再发实际浏览器输入。

| 关 | 波数 | 队员 0/1/2 掩体 | 朝向 | 原输入策略补充 |
| --- | ---: | --- | --- | --- |
| yard | 2 | 1/2/5 | 90/180/180 | 三枪、队员0手雷，无弹药包 |
| warehouse | 2 | 1/3/5 | 180/0/180 | 队员1弹药包与 F；首波 SWEEP 取 ammo→1、mine→0，在 cell(24,5) 放雷 |
| pump | 2 | 1/4/5 | 90/0/180 | 队员1弹药包；首波 SWEEP 取 ammo→1 |
| railcut | 2 | 1/4/5 | 270/270/180 | 队员0弹药包、SCOUT 原背包 auto-grenade 关闭；掉落由队员2拾；首波 ammo→1 |
| depot | 2 | 1/4/5 | 270/270/180 | 队员1弹药包；队员0取 mine，在 cell(7,11) 原地雷工具放置后重新部署 |
| radio | 3 | 1/4/5 | 270/90/270 | 同 depot 取雷/放雷；末关原 credits/scroll/返回标题 |

这些是源代码提供的策略，并非陌生人 playtest。三枪按 rifle/mg/scout 家族在原 authored stashes 中找未取物，真实走路和 0.4s 搜索后核 collected/装备。数字键选择原队员；A/D 使用 MG 8°、其他 15°，误差≤半量子+0.01，最多 24 步。掩体索引用原数组，仍核真正 slot_id，不靠视觉相近替代。每个原地雷操作先走到相邻 cell(1,0)，再经原 ToolButton 切 TRIPWIRE，点击 ground，并观察矿数恰减1/现场矿数增1；最后原 UI 回 DEPLOY。

SWEEP 按原 loot_piles 顺序最多 20 个未取掉落逐一走近，观察 loot 事件和资源实际改变；不 vacuum。首波补给按表走原 stash 路径。每波是原 AlarmButton → ALERT 自然运行 → SWEEP；后续波由 SWEEP 原按钮进入 ALERT，不造 SCOUT。最后 SWEEP 原按钮撤离，必须实际 WON 且 waves_cleared 等原 wave_count，才能计胜利和导出记录。

## 真实输入与只读观察接口

所有玩家动作仅通过浏览器 trusted CDP 键鼠事件，原 UI 的现有回调自然处理。selector 返回当下可见/可用 Control 的 rect 和身份：Title start/continue、六 mission 行、brief_go、tutorial next、alarm/pause/speed/tool/pack、backpack auto/close、replay/scrub、camera ↷、handoff CTA、pause 返回标题、credits scroll/back。不能直接 emit pressed、调用 raid_force_alarm/load_level/record_win/mark_tutorial_seen、赋 phase/tick/HP/ammo/装备/朝向，或 DOM dispatchEvent/Input.parse_input_event。

只读接口限定 `state/controls/project_targets/copy_record_bytes/fingerprints`：当前 scene/level/phase/modals/attempt/wave、SimClock 与 main run token、实际 operator/stash/loot/cover/mine、原 GameSettings 读值、原两份 ConfigFile、公共 `ambush-loop.config.v1` checkpoint、ReplayPlayer transport 与历史身份。坐标使用 rig.project_logic/pick_at/pointer_over_ui，具体 getter 在实现时逐个源审计。桥仅写自己的 reply/序列化缓冲和观察统计；不调整游戏 Tree pause/process、不强制 sync/save，不用 observer 推进帧或回放。自身 Input trace 只能观察，不能 consume/重发。

UI 动作前核 modal、rect/disabled、目标 scene/level/phase 和 attempt；动作后等状态断言及两次真实 present，再截图。Web 控制器采用单调 wall 截止，不将引擎 timer 当唯一期限。phase/时间采样与截图身份记录，截图及 polling 尾部不塞进存储 800ms 或 whole terminal 时间。

## 连续 campaign、handoff 与 reload 的顺序

使用全新自有 profile、固定独立 origin/path；不 seed/import 旧 cfg/seen/unlock/record，不清用户或独立 QA 存储。初次 Title 六行仅 yard 可用、Continue 禁用，经原 Start→yard 行→简报 CTA→全部教学进入 knife-only SCOUT。保留同一 campaign profile，不能六关各起已解锁 fixture。

源码 `main._on_continue_pressed` 的 WON 分支先 `_load_level(next,false,false)`、`_save_progress`，再显示 night_handoff；handoff CTA 只 dismiss/finished，**下一关已在它下面加载**。因此每个非末关采用：

1. 实际 WON → 立即复制八字段原 record，封存字节/SHA/attempt → 原回放 whole 1×、2×与 seek/focus → 原 Space 返回 WON。
2. 原 Continue → 核 next SCOUT、handoff from/to → 原 CTA → 下一关全部首次教学；核自然 seen 保存、knife-only、无 armed 操作。
3. 原 Esc/暂停菜单“返回标题” → Title 六行 cleared/next/locked + 两 cfg 和公共 checkpoint 摘要 → 同 origin reload → 原 Continue 进入 next 的新 SCOUT attempt；教学已读不重复，仍 knife-only。
4. yard 后与最终 radio 后增加同自有 profile close/reopen 读回。每个下一关这段未 armed 的教学 preview attempt 明确登记为 abandoned-preview，不能与其 reload 后战斗 attempt 拼接；六份完成记录只引用各自实际获胜 attempt。

radio WON 后完成原 whole，再 Continue→credits，真实 wheel scroll 和原返回标题；reload/reopen 核 complete=true、六关 cleared/unlocked、Continue 禁用。设置在首次原设置 UI 及原 M 等输入改动，恢复 standard 后跑视觉；同时读回实际 GameSettings，而非只比较 localStorage 字符串。checkpoint/public readback 与 cfg 分开保存，FS 内存有文件不是刷新持久化证明。refresh 不承诺战斗库存/内存 replay 恢复。

## 六份新记录与 whole 门

在自然 WON 复制 `var_to_bytes` 的原八字段：`attempt_id/events/snapshots/terminal_tick/terminal_reason/playback_schema/playback_snapshots/playback_terminal_tick`。保留 Godot Vector/Variant 型，不经过 JSON 重建；附输入 trace、source/fixture/profile/origin/level/自然结果、帧/事件数和 SHA。失败尝试也封存，但不计入六份成功记录；每关获胜波属于同一个 attempt，全部获胜波合计 13。

原 ReplayButton 调用 bind 后立即自动 2×播放。因此每次 whole：原按钮进入 → 原 pause 停 → 原 speed/减号选目标 rate → 原 slider 最左真实回到 tick0（端点几何含 thumb）→ 观察 playing=false/tick0/rate 正确 → 原 pause 启动并计 wall → 自然 terminal/playing=false。1×和2×各完整独立一遍；暂停/P、左右与正反 scrub、原 event focus 单独计，不把 seek 到终点当 whole。记录 source SHA 与 live SimClock(tick/speed/paused/_accum)、main.run_id、domain HP/ammo/库存/位置指纹前后相同；合法返回 WON 的 progress 写入另列。

检查 playback_tick 非递减、wave 边界、唯一 attempt/wave/seq/event_id、frame_seq 连续、同 tick 最新帧和 future-event cutoff；历史 3D roots/20 bones/枪/工具与 actor/source 身份分阶段截图。原序列不要求事件数逐 tick 等旧 a05。原八字段字节 SHA 在复制/whole 后保持。true old schema1 独立旧记录门、实际生产 origin、触控生命周期、音频耳听、fullsmoke、all-art、A3预算、FINAL/APK/设备均不折算本包通过。

## 冻结预算、退出和封存

- 单项 UI/走路最多120 wall秒；单波自然 ALERT 最多300 wall秒；每关 producer 最多900 wall秒，含首次+最多2次原 FAILED UI retry，达到关预算立即停止，不叠加每个 retry 的900秒。
- 每个 whole 独立截止 `max(180, 6 * playback_terminal_tick / 60 / rate + 30)` wall秒；这是有界收尾门，不是30/60FPS预算或允许3×wall性能通过。
- action/wave/level/whole 每项都登记 START/END、actual exit、attempt、原 trace/console/network、UI前后身份和失败原件。PASS/FAIL/BLOCKED/UNRUN 按达到的范围记录；若无 bridge/transport/renderer 原结果，UNKNOWN，不写0。
- 不静默延时、提高战斗速度补绿、强制胜利或 cleanup 唯一原件。自然 FAILED 可经原 Continue 重试，新的 attempt 留独立记录；控制器错误不能盲目重发非幂等点击。
- QA 明确 END/归还窗口后，先隔离 bridge 静态审计/固定候选映射，再单关 yard packet 实际原输入和 whole，封存检查后同 profile 连续五关。始终单 engine/browser，不与独立性能 QA 重叠。当前没有 START，没有 bridge/export/browser pass。

支持的 Library 单文件 schema 与本八件批次仍阻塞的准确原因见[Library 阻塞报告](AMBUSH_PR15_LIBRARY_TRANSFER_BLOCKER_20261005.md)。接下来等独立 QA 归还窗口，不重开 SDK/JDK/APK 或设备测试。
