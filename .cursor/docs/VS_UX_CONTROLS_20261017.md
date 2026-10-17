# VS UX 操作修复（差距报告 · 操作审计）

- 日期：2026-10-17
- 分支：`vs/g3`（**不合并**）
- 来源：`controls_audit`（对照 main 0.6.28 @ `c1aaf27`）
- 状态：**已实现并 headless 验证** PR-1…10；sim/金标不变。PR #57 → `vs/g2`。

## 切片与提交

| # | Commit | 内容 |
| --- | --- | --- |
| 1 | `31dd885` | GestureRouter：抬起执行、22 px 阈值、触摸/鼠标去重 |
| 2 | `eaa3310` | 底部头像栏 + 0.8 格命中 + 脉冲选中环 |
| 3 | `aa06230` | 等待重瞄：幽灵扇形、松手一次转向 |
| 4 | `8e774a0` | 布阵工具栏 + 起爆芯片；越线一笔拖；入场即就位 |
| 5 | `1537565` | HUD≥88、拇指主按钮、开发菜单、起爆长按、暂停重启确认 |
| 6 | `42c0b24` | 侦察路径预览 + 目的旗 + 侦察暂停 |
| 7 | `01a5e31` | 撤销/取消、Esc、长按删雷/线 |
| 8 | `55002b0` | 相机捏合缩放/平移/滚轮/夹紧 |
| 9 | `9bb2fe9` | 长按/悬停信息卡；清除 tooltip |
| 10 | `7eb1f90` | 桌面快捷键 + 帮助层 + 观察员眼睛 |

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
| W8 controls | **135** | 0 |
| **合计断言** | **358** (+ empty) | 全绿 |

## 截图证据

- `scout_path_preview.png` — 侦察路径虚线 + 耗时旗
- `zoomed_in_view.png` — 2× 缩放
- `info_card.png` — 信息卡（可见观察者）
- `phone_844x390.png` — 手机横屏布局

产物：`/opt/cursor/artifacts/screenshots/`、`ambush_vs/build/ux_controls_capture/`。

## 非目标

- 改 NightSim / 金标（未改）
- 合并 `vs/g2`
