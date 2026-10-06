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

## 正在运行的完整回归

- Godot 4.7.2，正常 `run_isolated_test.ps1` 包装器，独立 data 目录；未直接调用清档 smoke。
- run：`eb477ca62f3b4f108186a1bd1c6bd84b`，测试源码为上述 `6f9a6dc`。
- 控制台 PID 6452，实际 Godot 子进程 PID 13168；进程 ID 只适用于本次运行，后续需核对 command line/父子关系。
- 统一执行会话 ID `73583` 可用时通过 `write_stdin` 取最终包装器输出；`run.log` 只有引擎输出，不能把它当作包装器退出/存档后检记录。
- 已记录 `SMOKE_OK_GESTURE_PAN` 并进展到后续随队/触屏项目；完整终态、六关循环、engine/wrapper exit 和 `PLAYER_DATA_UNCHANGED=1` 尚待获得。
- 这条历史 smoke 的随队段耗时较长，`touch_feel_056` 实际 141400ms。进程继续消耗 CPU、后续标记有推进，不能因暂时没有日志就算死锁或终止它；这也不是手机 3D 帧时证据。
- 用户此前要求“回归跑完告诉我”；已设置本聊天 15 分钟跟踪，运行中不重复启动、无可操作变化时保持安静，完成或失败时写终态并通知。自动跟踪 ID `ambush-p0`。

终态日志根：`ambush_loop/build/ambush_test_runs/eb477ca62f3b4f108186a1bd1c6bd84b/`。完整通过需核对正常结束标记、六关实际结果、无未解释错误、engine/wrapper 0 和存档后检，不用只通过 pan 代替全量通过。

## 剩余工作

先收完整回归终态；手机连接后采集实际院子 3D 的 CPU/GPU/帧时、触摸、内存与热稳定基线，再决定优化目标。下一代码切片按已有 GPT PLAN 做 P0 计时采样和 P1A 小型只读权威查询，再 P1B 绘制。当前没有手机性能结论、没有默认 3D 新功能交付、没有 M2/M3 完成声明。
