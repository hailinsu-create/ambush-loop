# PR15 连续命令记录切片计划

2026-10-03。父端已收0ac并安排独立resultHUD复验，授权继续FX/版本化连续command/radio终章中的下一独立切片。先接真实ALERT→SWEEP→下一波/终局；SCOUT警报前记录留下一片，不同时改首次警报清日志与身份契约。

实际审计：main的command `_process`推进动作/移动后返回，没有add_snapshot；首次警报begin_attempt清掉SCOUT日志。已有command_pose_clock只证明选取/复制记录与终局快照正确，未证明SWEEP中间实际被生产录制。本片先以真实两波、普通command移动、暂停/后台/恢复和正常REPLAY反例确认。

新增可选playback_schema=1及独立playback_tick/frame_seq，BattleLog原schema2/tick/timeline_tick/wave_offset/event seq与terminal_tick保持原含义。旧domain快照/事件继续保留；新的播放快照流包含ALERT原帧与真实SWEEP约0.1s采样/提交边界/FAILED-WON末帧。command录制不得更新原_last_timeline_tick，也不增加模拟事件。大delta只记录已实际得到的状态，不补造中间动作/位置。

ALERT播放时钟随原_sim_tick逐tick推进，保持1×/2×；SWEEP随未暂停的实际command delta推进。暂停/后台/REPLAY停止录制和播放时钟。ViewState将播放坐标与原battle事件年龄分开；新command历史可在已记录相邻时刻间推进纯数据动作时钟，旧command记录保持原保守姿态。事件点击使用保存的播放时刻；旧/缺失/未知新schema降级原battle时间轴并保留源，不将旧记录升级。

验证：先提交测试和负向固定SHA，再修生产；检查实际移动多点被录、旧battle统计不变、跨波/终局、倒退/前进seek、同点20骨/根/源数据一致、当前clock/actor污染、旧/未知兼容、暂停/后台和1×/2×。每阶段跑隔离云端功能与实际渲染；必要合同/时间轴/旧command时钟/生命周期/六关13波回归，记录命令/exit/UUID/哈希。SCOUT前段、完整FX、radio正常旅程/A3/最新同候选smoke/13波视觉/APK仍待后续切片。

所有权：主作者独占main/presenter/ViewState/replay/HUD/loader/共享测试；制作源、GLB、Blender/atlas/manifest仍独立资产作者，R5 20骨/socket/3LOD/52旧语义保持。本片不重跑资产，不改数值/占格/路线/胜负/14px follow/瞬时抓放/共享haul，保持SCOUT→ALERT→SWEEP；Draft不merge/生产，高度/G隔离。耳听0/45、0/6；设备阶段仍在全部计划完成后。GPT PLAN/REVIEW unavailable。

父端独立checkpoint登记（主作者未冒称重跑）：cf77f4db63605ff1e9846e1149f27ca6d461f458的schema2 IK原P2关闭，116/0、36关键maxskin0.02138mm、1350样本6488/0、72schema1 hash同a575、pause/clock/history4321/0，全ERROR0；eb1531475d190b656f57a2e4c7cd098b0e3f30df北侧原重叠矩阵关闭2187/0/72时刻，cf77负向729/16exit1，focus1702/viewport5081通过。旧cf77终局15/2exit1并有3 shader-cache错误，不算green，也不据此断言0ac失败；0ac独立终局结论待。原两张focus文字/radio终章/完整旅程仍待。

当前状态：计划及实际生产反例待运行；下一步按固定源码验证并接独立QA。
