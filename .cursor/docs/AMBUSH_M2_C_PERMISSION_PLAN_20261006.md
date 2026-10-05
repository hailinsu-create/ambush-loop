# M2-C 固定触发区与单次开火许可实验

2026-10-06，基线 `3d46d88`（B2/D1 整合）。状态：实施规格，尚未验收。实际外部 GPT PLAN `c2c_m2_c_manual_permission` iteration 0 已读取权威链，支持只改变 HOLD 的许可来源，不建立第二套开火系统。

默认 AUTO 原行为不变；院子 SETUP 战术视图可选择 MANUAL 实验，开战后不可切换。现有 Rect2 伏击区保持权威，入口边界表示预设线；手动模式仅参考、进入不自动许可。WATCH 按钮只排队一次请求，下一 fixed tick 冷却后、敌人移动前消费。仅 alive/visible 未许可 HOLD 队员 arm；ENGAGE 不变，目标/射线/射界/枪弹/冷却/投雷沿原路径。暂停可排队，恢复首 tick 消费；重复请求无效。

每 run 最多一条 team_fire_permission，记录消费 tick/实际 armed_ids；无人 HOLD 也记录空数组。AUTO 原 ambush_armed 不变。复盘只读事件；D1 存准备模式、恢复清空 queued/used，签名增加版本。不存战斗队列。

门：AUTO B2 结果/事件/HP/枪弹不变；MANUAL 入区不自动许可；原生触摸只排队、次 tick 消费、重复/模拟鼠标不重发；暂停、1×/2×相同 sim 指令同事件/终局；只读复盘边界；两尺寸/两场景按钮 >=48px、不穿透，非 MANUAL WATCH 隐藏；交战世界/装备/朝向仍冻结；失败恢复模式与空战斗队列。B2 部署/资源/路线、枪械和其他五关不改。

技术通过不代表人体工学胜出，未有人体对比前 AUTO 保持默认。随后 E 院子视听/只读 3D 复盘，F 四步实际操作引导及集成；手机/真人按用户要求暂缓。

## 实施证据

仅 main、两 HUD、日志格式、D1 mode 字段与独立门/runner 改动；未改枪械、寻路、投雷、B2 部署或关卡。模式藏在准备期战术视图，WATCH 才显示全队开火；命令均走唯一 apply_touch_command。

- import `a3b9c3c5346d4f11b9b54ee931990f50` 退出 0。
- 第一红门 `ce781be86be2444eb172dc1e88655a58` 退出 2，测试遗漏真实 SWEEP→撤离步骤、复盘把纯显示隐藏算成权威变更。修正测试签名为实际位置/HP/枪弹/背包/许可/日志，不放宽只读规则。
- 触屏红门 `ebcc56300aff42679df7aa81472adcf6`：准备模式正常，但 WATCH 刷新隐藏新增按钮。把按钮状态设置移动至实际 phase refresh 之后。
- `08e989101b90471089841cc98f532bae` 退出 0、stderr 空、PLAYER_DATA_UNCHANGED=1。真实补给与合法高台方案，两 HOLD+一 ENGAGE，许可消费 tick200/armed_ids[1,2]，完整事件/终局/HP/弹药 1×与2×一致（354/177 real frames）；只读复盘边界、两尺寸/两场景原生触摸/模拟鼠标、暂停排队、重复请求、冻结、D1 恢复模式不恢复队列、无人 HOLD 空事件通过。
- 前 C 基线 D1 `3d46d88` run `90e09a4986804d07bbc995a6ab95a3f7` 与 C run `7c5c164df34d43b7834f10650d263d99`：相同真实 AUTO 方案的完整事件、终局 tick/reason、实际位置/HP/武器/弹药池/背包哈希均 `eebea14acdbc017cae9b39b759a7c52725eef1df58cbef205a5780b6bea9db53`，退出 0、stderr 空、PLAYER_DATA_UNCHANGED=1。独立基线门固定此前测得值。

增强专项 `8f205c719b4043c6b1a48fdec1007bc1` 退出 0、stderr 空、PLAYER_DATA_UNCHANGED=1，包括 AUTO-HOLD 入区旧许可路径。完整 T3 回归 exit70 揭示旧 dock 重复 refit，修复专项已通过，完整复跑仍待验证。外部 C PLAN 已收到，当前 C 精确源码尚未独立 REVIEW；不能称 M2 完成。
