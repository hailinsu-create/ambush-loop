# VS UX 布局修复（HUD resize → 地图占满）

- 日期：2026-10-17
- 分支：`vs/g3`（**不合并**）
- 接续：操作审计 PR-1…10 + 首轮布局容器化
- 状态：**已实现并 headless 验证**；sim/金标不变。PR #57 → `vs/g2`。

## 契约

- `MapHost` 占满「顶栏 + 右栏」之外全部空间；工具条/头像条为地图上半透明浮层，不挤占 MapHost。
- 手机（高 < 500）：右栏可折叠抽屉（约 32% 宽）；等待阶段自动收成右侧竖条圆钮（暂停/倍速/起爆）。
- 桌面等待：窄动作轨（无空右栏）。
- 队员卡两行：姓名行 + 完整短武器名芯片行。
- 地图缩放：手机 fit-height；桌面 cover 填满 MapHost（裁切溢出）。
- 布局测试：setup/scout/wait/result × 1280×720 / 844×390 — 无重叠；地图面积 ≥60%（等待 ≥75%）；折叠抽屉增大地图。

## 验证

| Suite | passed | exit |
| --- | ---: | ---: |
| empty…W7 | 同前 | 0 |
| W8（含 layout） | **167** | 0 |

截图：`setup/wait/scout/result` × 两尺寸 → `/opt/cursor/artifacts/screenshots/`。
