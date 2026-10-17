# VS UX 布局修复（HUD resize 后重叠）

- 日期：2026-10-17
- 分支：`vs/g3`（**不合并**）
- 接续：[VS UX 操作修复](VS_UX_CONTROLS_20261017.md) PR-1…10
- 状态：**已实现并 headless 验证**；sim/金标不变。PR #57 → `vs/g2`。

## 契约变化

- 右栏：不透明固定宽约 30%（1280 下），`ScrollContainer` 自上而下：工具芯片 → 起爆芯片 → 紧凑队员行 → 套件摘要；底部固定主按钮。
- 地图：仅占左侧（顶栏 / 工具条带 / 头像条带之外），HUD 控件不得压住 `MapHost`（头像条与顶栏除外）。
- 合法格：仅当前工具合法格；大片时只淡填色，不画满院网格描边。
- 布局测试：setup/scout/wait/result × 1280×720 / 844×390，可见交互/标签矩形无重叠（父子与滚动裁剪除外）。

## 验证

| Suite | passed | exit |
| --- | ---: | ---: |
| empty | OK | 0 |
| W2 | 73 | 0 |
| W3 | 57 | 0 |
| W4 | 27 | 0 |
| W5 | 19 | 0 |
| W6 | 25 | 0 |
| W7 | 22 | 0 |
| W8（含 layout） | **160** | 0 |

截图：`setup_*` / `wait_*` / `scout_*` / `result_*` @ 1280×720 与 844×390 → `/opt/cursor/artifacts/screenshots/`、`ambush_vs/build/ux_controls_capture/`。
