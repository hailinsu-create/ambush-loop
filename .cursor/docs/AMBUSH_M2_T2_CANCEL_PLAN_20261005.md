# M2-T2：系统取消触摸防误触切片

日期：2026-10-05。用户要求继续开发，手机暂缓。范围仅系统取消事件，不改变玩法规则。

## 前置证据

桌面 T1 已保存在源码 e1bc3189728313e3e2fca1d580ca1f778b20a5dd，代码 PR #27 依赖 PR #25。完整 smoke run fe2da4ceeff643489c5fd6a3af49436e 退出 0，六关循环、SMOKE_SLICE_COMPLETE、SMOKE_OK_RAID_LOOP 与最终存档后验均通过。原外部 GPT c2c_8d37 iteration12 实际 DONE 范围仅桌面 T1。

本文接续 T1 恢复计划，不替代设计 v2、真机退出门或 B2 玩法计划。

## 问题与有限范围

main.gd 的 InputEventScreenTouch 原路径只检查 pressed，不检查 canceled。系统取消可能进入普通松手路径，错误创建 tap/sprint 意图；延迟 drag 也可能重新登记已取消手指。

目标：系统取消必须清除待确认指令、预览与相关手势状态，取消后的延迟拖动/松手不得重新激活，新的正常按下必须恢复可操作。

不改变触摸阈值、镜头计算、转向半径、确认语义、弹药、部署、战斗或冻结方案。

## 真实 GPT PLAN

原对话 c2c_ba05 iteration0 已通过精确游戏工作区读取 main.gd 和 m2_touch_intent_gate.gd，确认缺少 canceled 分支。要求先获得失败测试，再做最小输入状态修复，复跑专项门。后续 REVIEW 必须针对当前差异和实际输出，不用旧 T1 DONE 代替。

## 实施与验收

1. 新增普通按下、已暂存意图、镜头拖动、转向、长按掩体、双指取消一指测试；补充奔跑待执行和工具意图反例。
2. 每种情况检查无意图/预览，相关 pending/hold/pan/pinch 状态清理，取消指从 touches 移除，没有移动、部署、资源和模拟 tick 变化。
3. 注入取消后的迟到 drag/release，检查不能恢复手势、镜头、转向或世界指令；双指中另一指松开同样不能创建指令。
4. 复用相同手指编号重新按下应正常预览，随后取消仍免费。
5. 生产修复仅提前处理 canceled，隔离已取消指的迟到事件，并在新按下解除隔离。
6. 通过隔离包装器获得专项 exit 0、完成标记和 PLAYER_DATA_UNCHANGED=1；红、绿输出都记录给外部 GPT。
7. 专项通过后才启动新完整 smoke。真机仍待接入，桌面合成事件不等于 Android 手势实测。

## 当前状态与下一步

已实现最小取消事件修复，源码 8728081b444aaafdbd2a45cf23a023668ae2847a，Draft PR https://github.com/hailinsu-create/ambush-loop/pull/28 依赖 PR #27；远端 SHA 已核对一致。

测试先红后绿：首次类型推断错误 run 878b8edd327f4fe98671f26bb9d76c7d 不作为行为红证据；真实行为失败 run 07f1bbd48dba4b99a57165b2f088a111 退出 1；修复后 run 4d278ea5cca4465faae9a270d37d0289 退出 0，八种取消场景、迟到事件隔离、新按下恢复与原 T1 断言均通过，M2_TOUCH_CANCEL_OK、M2_TOUCH_INTENT_OK 和 PLAYER_DATA_UNCHANGED=1 均有实际输出。

原外部 GPT c2c_ba05 iteration1 实际读取输出 37–39 和精确两文件差异，返回 DONE，无专项阻断项。此 DONE 仅针对取消触摸专项，不等于新完整回归、Android 或整个 M2 验收。

2026-10-05 新代码完整隔离 smoke 已结束。run ID `1c56f9deac944a879250e161de0a0579`，Godot 4.7.2，实际退出码 0；六关 yard/warehouse/pump/railcut/depot/radio 均通过，`SMOKE_SLICE_COMPLETE`、`SMOKE_OK_SWEEP_FIRST_HINT` 与 `PLAYER_DATA_UNCHANGED=1` 存在，stderr 为空。完整日志在 `ambush_loop/build/ambush_test_runs/1c56f9deac944a879250e161de0a0579/`；摘要捕获于 `%TEMP%/ambush_m2_t2_full_smoke.txt`。

T2 的定向取消触摸门与完整桌面回归均通过。随后外部 GPT 任务 `c2c_7e27` iteration 0 独立读取精确代码、此报告和 run 目录，确认源码 `8728081` 的桌面完整回归干净且没有 T2 代码阻断。该复核不代表 Android/真机或整个 M2 完成。

GPT 建议下一切片为 [M2-T3 触屏目标尺寸与界面输入归属](AMBUSH_M2_T3_TOUCH_TARGET_PLAN_20261005.md)。详细执行顺序和退出标准单独存档；本轮只完成规划，未实现 T3。手机继续暂缓，PR #28 保持 Draft。
