# B2 双向随队补验与诊断交接

日期：2026-09-30，跨日更新至 2026-10-01。状态：外部 GPT 规划和新增测试代码评审已完成；四项定向门通过，完整 smoke 达限中断、未验收完整回归。此文件承接六小时计划的设备不可用替代路线；不改变原定 360 分钟执行窗口及两小时决策、最后 45 分钟交接记录。

## 范围与依据

用户要求继续开发并加入外部 GPT 评审；已授权将相关手机日志、截图交同一项目评审。游戏玩法基线仍为设计 v2。原六小时窗口已结束，当前续做未完成项；本切片限 75–90 分钟，优先补桌面 B2 缺口和交接。

外部 GPT 在原项目对话读取 C2C iteration 7 的实际输出后，建议：保持历史 AudioTrack 根因未解决，停止使用不匹配符号；仅补真实下坡随队和双向断坡 scheduler 反例，执行隔离门后留下设备不可用交接。此反馈是规划，不是对新测试代码的批准。

## 当前诊断事实

- 完整 Godot 4.7.2 Android template_debug/arm64 符号构建 exit 0，耗时 02:50:26.29；重建库 Build ID 为 `f4a54bf106d04f551f8ba43f03fa1ada8ace1526`，历史 tombstone / code80 APK 的库 ID 为 `379cc52e73d31af89517a529d3bbc6108b808986`。不匹配，未接受任何 addr2line 行号。
- 随后的版本信息增量构建句柄已不存在，且对象、动态库时间仍早于源文件修改；没有证明其完成。不能把生成文件的时间戳修改当作成功重链。
- 历史 code78 的 AudioTrack SIGSEGV 仍未定因。保留五个 Godot PC：`0x2f8f814`、`0x34c1db4`、`0x349d77c`、`0x349b7e4`、`0x12f7b1c`。下一次 native 调查需要精确匹配的原库符号，或带已登记符号的新库产生的新样本。
- 先前 code80 / `0.6.30-font-cache-diag` 设备记录与 GPT iteration 5/6 复核确认 Accept → Yard、至少 3 分钟存活；短时内存约 PSS 533 MiB、native heap 306 MiB、RSS 650 MiB。这些是先前样本，不是本次实时测量，不能证明长时稳定性或字体缓存与旧退出存在因果关系。
- 本次 mDNS 无已授权 vivo 服务，已知无线地址重连失败；ADB 当前 USB 设备型号为 AAP-AN00，与此前 vivo X Fold2 不同。未把该设备作为 vivo 验收替代品。当前手机包身份、带声音 30 分钟连续/60 分钟累计运行仍待验证。

## 单一实现切片

仅修改 B2 分支的 `ambush_loop/scripts/m1_b2_yard_height_gate.gd`，保持生产移动、音频与地图代码不变。

1. 同一真实 yard 场景通过 `_tick_squad_follow()` 调度上坡、下坡；运行真实队员运动，验证每段 world-space 路径合法且确实跨过唯一坡道。
2. 在相同 fixture 移除唯一坡道，保留已选择的另一层跟随目标，连续调度 80 次。任何产生的路径和实际运动都必须合法；允许原高度层内移动，但不得到达另一层。
3. 完成 marker 分为 `follow_up`、`follow_down`、`follow_up_disconnected`、`follow_down_disconnected`，不再用含糊的 `follow=1` 表示所有方向。

## 验证和提交

先跑 focused B2 门，再跑 B1、高度、R45 和完整 smoke；全部经隔离包装器，并记录 exit code 与 `PLAYER_DATA_UNCHANGED=1`。生产代码未变，测试通过只证明桌面覆盖；真机双向随队、坡道/台面可辨识性和 Android 稳定性仍独立未验收。

测试源文件已推送 Draft PR #6，提交 `2205b3f02f9e2ae4031610f39f0230162bf5cfdd`，`git ls-remote` 确认远端 SHA 一致。本规划及执行证据通过独立文档提交进入 PR #3；文档推送尚待完成，不代表主线合并。

### 实际桌面证据（跨日续做至 2026-10-01）

| 隔离门 | Run ID | 结果 |
| --- | --- | --- |
| B2 双向随队及断坡 | `4cdb90673058409ba8e9a1464664705c` | exit 0，四个方向 marker 均为 1 |
| B1 坡道寻路 | `dcd5bf64332b4c6a8c59f3af93af9469` | exit 0 |
| 基础高度数据 | `5de8461f854c4895a9505dfaf3fa3f5c` | exit 0 |
| R45 | `071c874c199f46c492f4762735528381` | exit 0 |
| 完整 smoke | `29ac853d16ad4855998f47392784ab8e` | 计划截止后主动中断，包装器 exit -1，不计为通过 |

以上已结束的包装器均记录 `PLAYER_DATA_UNCHANGED=1`。B2 实际上坡为 `(14,10)` → `(16,12)`，下坡为 `(15,10)` → `(16,9)`；实际轨迹各经过唯一坡道 `(15,13)` ↔ `(15,12)`。双向断坡均保留对侧目标并运行 80 次真实调度，未越层。

完整 smoke 于北京时间 2026-10-01 00:04:09 启动。本次续做仍遵守 75–90 分钟范围，预留交接，设测试等待截止为北京时间 01:00；届时若仍未取得退出码，仅中断本次隔离 Godot 测试，保留日志，并明确记为中断/未通过，不能借用此前完整冒烟通过记录替代本次结果。

实际到截止仍无 `SMOKE_SLICE_COMPLETE`；核对 PID 29896 的启动时间、可执行文件与本项目 `smoke_test.gd` 命令行后，只停止该独立测试进程。包装器 exit -1，最终仍有 `PLAYER_DATA_UNCHANGED=1`，日志保留。最后输出为 `SMOKE_OK_WEST_FOLLOW_REAR`；此前已通过边走边跟随、队形停步保持与 touch feel 0.5.10 等部分检查，但剩余检查和六关完整循环未获得完成证据。此次属于计划达限中断，不是观察到断言失败；同样不能声称无回归。下一轮先补完这项完整门，勿重复或冒认此次结果。

中间两次严格测试失败保留：`657ec75cd52e4a63b1c3aab8bf3dd23d` 下坡正例失败，`7e3b1c6633644d8ba6579dac0d9600bf` 上坡正例失败。原因排查指向测试间的跟随转向/到达缓存和起点目标保持语义，不能据此宣布生产移动缺陷。最终 fixture 每方向调用现有 `reset_follow_dest_flips()`，选择真实 formation anchor，并仅设置跟随目标；移动路径仍完全由真实调度器生成、逐段验证。失败输出和最终输出均交 C2C iteration 8。

### 外部 GPT 独立评审

在既有项目对话中，GPT 确认读取 iteration 8 输出项 9–14，并仅审查新 gate 相对 `340b819` 的差异，未把镜像中既有诊断改动混入本轮结论。反馈：没有阻塞项；设置的是 formation 目标而非 movement path，真实调度、运动和方向坡道 trace 均未被绕过；状态重置提高用例独立性；保留对侧旧目标的双向断坡测试不是空洞通过。

非阻塞建议：将来补一次调度/拒绝状态观测，进一步证明断坡时确实处理旧目标。此次不因此扩展生产代码。评审明确限定为桌面 integration coverage；smoke 尚未结束时不能宣布完整回归全绿，更不能宣布 Android 稳定或完整 B2 验收。

### iteration 9 交接复核及下一轮规划

外部 GPT 实读中断输出与本报告，确认 completion boundary 一致：四项定向门 exit 0；完整 smoke 未出现完成 marker，主动中断 exit -1，不能计 PASS；隔离存档保持不变不等于无回归。code80 的旧短时样本也不能外推长时稳定性。

下一轮只补未完成验收，不启动 M1-C/M1-D 或新关卡：

1. **完整隔离 smoke（建议预算 60–90 分钟）**：新建一次独立 run，从头完成 `smoke_test.gd`；不得拼接本次部分输出。成功同时要求 `SMOKE_SLICE_COMPLETE`、包装器 exit 0 和 `PLAYER_DATA_UNCHANGED=1`。再次达限则保留最后 marker、耗时及进程状态，仍标为未完成。
2. **目标设备包身份与 B2 画面（设备恢复后约 30–45 分钟主动操作）**：确认原 vivo X Fold2、包名及 versionName/versionCode，再取院子上坡、下坡、SMG 可达/拾取、双向随队、横屏平台及唯一坡道可辨识证据。另一 USB 型号和桌面结果不可替代。
3. **带声音稳定性**：目标设备 30 分钟连续、60 分钟累计；覆盖 Accept → Yard、前后台恢复和 Back，保存 PID、时间范围、ExitInfo、同期内存与游戏日志。未复现只证明该样本时长内未复现，不能写 AudioTrack 已修复。

历史 native 调查仅接受精确匹配的原库符号，或符号已保存、包身份已记录的新 native binary 的新崩溃样本；不根据不匹配 PCs 猜函数，不因此修改 WAV/loop/stream 生命周期。若下一轮 vivo 仍不可用，完整 smoke 结束后停在“桌面回归完成、设备验收待补”，不继续扩张桌面实现范围。本机 Android 诊断 worktree 仍有未提交改动；本次只提交 gate 与文档，后续接手先核对独立诊断差异，勿覆盖。

## 2026-10-01 完整隔离冒烟补验

按 iteration 9 规划新建独立 run `0e588b66cd504c8ea11d3f03d6d6a5c8`，从头执行 `smoke_test.gd`，没有拼接前次中断输出。最终同时取得：

- `SMOKE_OK_TYPICAL_LOOPS yard,warehouse,pump,railcut,depot,radio`
- `SMOKE_SLICE_COMPLETE`
- 包装器 exit 0
- `PLAYER_DATA_UNCHANGED=1`

因此桌面完整回归门现已通过；此前 run `29ac853d16ad4855998f47392784ab8e` 仍保留为达限中断记录，不以新结果改写历史。新 run 覆盖院子、仓库、油泵、铁路、油库、电台的完整典型循环，并通过触屏、跟随、生命周期、音频提示、视觉可读性和失败路径等既有检查。

同日 ADB 已重新识别目标 vivo X Fold2：serial `10AD4L182J001DB`、型号 `V2266A`、产品 `PD2266`，无线服务为 `192.168.1.25:39047`。设备查询时 `com.ambushloop.game` 不存在，未由本轮执行卸载或清数据。已校验此前获授权的 code80 APK：`com.ambushloop.game`、versionCode `80`、versionName `0.6.30-font-cache-diag`、证书 SHA-256 `7079e51f…a1c8`、文件 SHA-256 `F91CB08B…EEEA`。安装命令已提交，当前停在 vivo 系统安装风险确认页；未取得 `Success` 前不记录为已安装，也不启动真机验收。

当前边界更新为：桌面回归完成；目标设备包安装、B2 横屏画面与上下坡随队、30 分钟连续/60 分钟累计带声音稳定性仍待完成。历史 AudioTrack SIGSEGV 仍未定因，Build ID 不匹配结论不变。

外部 GPT iteration 10 已实读该 run 的执行输出及本报告，确认新 run 是独立从头执行，桌面 completion boundary 可以从 iteration 9 的 incomplete 更新为 complete/pass。结合此前 B2、B1、height、R45 定向门 exit 0，本轮要求的 desktop regression gates 已完成；这仍不等于完整 B2 或 Android 验收。

后续真机证据链固定为：安装命令明确 `Success` → 设备端复查 code80 身份 → Title / briefing / Accept / Yard → 横屏平台与坡道、角色双向上下坡、SMG 拾取、真实 follow-up/follow-down → 带声音 30 分钟连续、60 分钟累计，并覆盖一次前后台与 Back。开始/结束记录 PID、包身份、时间、内存和 fresh `ApplicationExitInfo`。未复现只能写该时长与指定生命周期内未复现，不能写 AudioTrack 已修复。

## 仍需完成

恢复此前 vivo 设备后，先确认包身份，再做带声音任务切换、前后台、Back 与连续运行；用同一版本保存院子实际上下坡、SMG 拾取、双向随队及画面证据。历史 native 崩溃未解决时，不标记音频已修复、B2 已验收或 PR 可合并。
