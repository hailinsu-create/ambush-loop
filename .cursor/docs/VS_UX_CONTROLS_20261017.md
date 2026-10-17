# VS UX 操作修复（差距报告 · 操作审计）

- 日期：2026-10-17
- 分支：`vs/g3`（**不合并**）
- 来源：`controls_audit`（对照 main 0.6.28 @ `c1aaf27`）
- 状态：**已实现并 headless 验证** PR-1…5；sim/金标不变。PR #57 → `vs/g2`。

## 切片与提交

| # | Commit | 内容 |
| --- | --- | --- |
| 1 | `31dd885` | GestureRouter：抬起执行、22 px 阈值、触摸/鼠标去重、拖离取消 |
| 2 | `eaa3310` | 底部头像栏 + 0.8 格命中 + 脉冲选中环；点选不改朝向 |
| 3 | `aa06230` | 等待重瞄：幽灵扇形、松手一次 `request_operator_facing`、拖回取消 |
| 4 | `8e774a0` | 布阵工具栏 [队员][地雷][触发线] + 独立起爆芯片；越线一笔拖；幽灵确认/拖落位；入场即就位 |
| 5 | `1537565` | HUD≥88 设计 px、右下拇指主按钮、字≥24、开发者菜单、起爆长按、重启进暂停确认 |

## 验收（W8 + 全套）

| Suite | passed | exit |
| --- | ---: | ---: |
| empty | OK | 0 |
| W2 sim/golden | 73 | 0 |
| W3 greybox | 57 | 0 |
| W4 scout | 27 | 0 |
| W5 combat fx | 19 | 0 |
| W6 review | 25 | 0 |
| W7 combat | 22 | 0 |
| W8 controls | 86 | 0 |
| **合计断言** | **309** (+ empty) | 全绿 |

W8 覆盖：抬起 tap、触摸去重、拖取消、长按、0.8 格命中、抖动不改朝向、重瞄一次订单、工具芯片/合法格、越线一拖、幽灵确认、触控尺寸、暂停重启确认、长按起爆。

## 截图证据

`DISPLAY=:1` 窗口截图（非 headless dummy）：

- `setup_toolbar_highlights.png` — 地雷工具 + 合法格高亮 + 工具栏/头像
- `wait_reaim_ghost.png` — 等待重瞄幽灵锥 +「转向 2s」+ 长按起爆
- `phone_844x390.png` — 844×390 手机横屏布局

产物副本：`/opt/cursor/artifacts/screenshots/`、`ambush_vs/build/ux_controls_capture/`。

## 非目标

- 改 NightSim / 金标（未改）
- 相机捏合（审计 PR-8）
- 侦察路径预览（审计 PR-6）
- 合并 `vs/g2`
