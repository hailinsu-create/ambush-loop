# P0：浏览器评审恢复与平移回归修正

日期：2026-10-06。分支 `codex/m2-f-operable-guide`，Draft PR #35。用户已授权当前游戏工作区只读评审，并要求继续开发和修复。

## 已完成的限定切片

测试源码提交 `6f9a6dcf1f430ee29b6b27f4143f37f1ef96c913`，父提交 `e5bc650`；唯一代码变化为 `smoke_test.gd` 既有平移夹具。依据起始相机 X 偏移选择向范围内部拖动；保留手势归属、队员不移动、相机偏移必须变化三项断言。失败消息新增起点/终点/缩放。`main.gd` 和游戏规则未改变。

历史 run `650935fc8ec94d088bf098b3f7641c25` 没有记录起始镜头偏移，不能反向声称已证明卡在边界。源码显示固定向右拖动会减小镜头偏移；负向边界的外向拖动被合法 clamp 限制，旧断言存在前置条件问题。

## 实际外部 GPT 评审

原聊天 `https://chatgpt.com/c/6ac120c9-7a84-83ec-8f5a-b01fd6ba5442`。评审 host `ambush-loop-m2-b1` 的 doctor 全部健康，现有 connector 保留。使用 `git archive` 从精确 SHA 创建只读 packet `.cursor/review_packets/p0-6f9a6dc/`，含 receipt、smoke/main/包装器、旧红灯日志；packet 与执行工作树及 host HEAD 分开。

任务 `c2c_pre_m3_3d_plan` iteration 1，GPT 实际返回 `STATE: DONE`，scope 为 camera-pan smoke-fixture correction only，明确 verdict approve。评审读取指定 host/不可变材料，认为该改动合理测试“合法平移能改变镜头”，未通过直接设置偏移制造通过。三项行为断言仍有效，没有要求生产代码变更。

评审提示：该 smoke 只覆盖当前位置的一种合法内向拖动。P2 后续应独立覆盖左右平移、两侧边界内向/外向限制、双指归属与不发世界命令。本次限定批准不代表完整 P0/M2、手机性能或旧 `c2c_a619` 验收通过。

## 浏览器恢复证据和续用方法

旧 `cua.getTab` 自动读取入口连续超时。通过已选择 IAB 的文档化接口 `browser.tabs.get("1")` 获取现有标签，`tab.playwright.domSnapshot()` 实际读取历史规划和当前消息；折叠侧栏、核对结果、恢复侧栏验证了可执行 UI 操作。标签 ID 属于本次会话，后续须重新发现。

本次 fill 成功后，press 返回底层 Input.dispatchKeyEvent 超时，不能由此判断请求未发送。核对读取同样超时后，重载原聊天一次，再实际读取已出现的 EXECUTED 消息、GPT workspace 确认、最终限定 DONE；未重发该消息。保存原聊天和 `c2c_a619` 本地检查点，不额外建 chat/connector。新工作树没有自己的 session 不是旧评审失效的证据。

此记录确认本轮页面控制和评审链路恢复可用，不保证浏览器以后没有底层超时。额外创建且未配对的 F 本地服务已停止；保留已健康的 B1 评审连接。

## 完整隔离回归终态（2026-10-07）

- 原 run `eb477ca62f3b4f108186a1bd1c6bd84b` 的引擎日志已含六关胜利、`SMOKE_SLICE_COMPLETE` 与 `SMOKE_OK_SWEEP_FIRST_HINT`，但执行会话 `73583` 已不可读取，缺包装器退出码及存档后检证据；因此保留为“引擎日志完成、包装器终态未知”，不登记通过。
- 在确认原 Godot 进程已退出后，以 Godot `4.7.2.stable.official.ed1daf0bf` 和正常 `run_isolated_test.ps1` 隔离包装器重跑，run `8b29ceeef7104d11b07c905b30d590c1`。测试源码为获批提交 `6f9a6dcf1f430ee29b6b27f4143f37f1ef96c913`：复验时 HEAD 为文档提交 `38b6d38`，`6f9a6dc..HEAD` 的 `ambush_loop` 无差异，工作树 `smoke_test.gd` blob 与该提交相同（`89622e4639af8515c7303299eac95efa609daa46`）。
- 隔离 run 输出六关 `yard/warehouse/pump/railcut/depot/radio raid won`、`SMOKE_OK_TYPICAL_LOOPS`、`SMOKE_SLICE_COMPLETE`、`SMOKE_OK_SWEEP_FIRST_HINT`；stderr 为空。
- 统一执行会话 `91358` 正常结束、wrapper 退出码 `0`；包装器后检明确输出 `TEST_ENGINE_EXIT=0` 与 `PLAYER_DATA_UNCHANGED=1`。因此该桌面完整隔离回归通过，完整日志位于 `ambush_loop/build/ambush_test_runs/8b29ceeef7104d11b07c905b30d590c1/`。
- 本结果只验证 Godot 桌面隔离 smoke；手机 3D 性能和真人操作门仍待测，不代表 M2/M3 或 P0 所有手机工作已完成。自动跟踪 ID `ambush-p0` 在记录同步后停用。

## 剩余工作

手机连接后采集实际院子 3D 的 CPU/GPU/帧时、触摸、内存与热稳定基线，再决定优化目标。下一代码切片按已有 GPT PLAN 做 P0 计时采样和 P1A 小型只读权威查询，再 P1B 绘制。当前没有手机性能结论、没有默认 3D 新功能交付、没有 M2/M3 完成声明。
