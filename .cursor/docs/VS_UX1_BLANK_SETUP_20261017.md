# VS-UX1：空白布阵起手（PLAY-1）

- 日期：2026-10-17
- 分支：`vs/g3`（Pages 重部署；**不合并** `vs/g2`）
- 状态：**已实现 / 本机隔离测试已绿**（W2 61 / W3 56）；CI/Pages 随 `vs/g3` `66b21ae` 推送
- 来源：所有者试玩差距报告 fix #1（`gap_report` VS-UX1）

## 目标

让玩家在开始等待前自己做计划：空白板起手、选武器、点格放置、自设地雷/越线、示例方案收进二级入口。

## 范围

- **做**：`greybox_controller.gd` / `greybox.tscn` / `greybox_map.gd` 呈现；`yard.json` 增加纯呈现字段 `squad_insertion`；W3 新断言。
- **不做**：改 `sim/` 规则、W2 金标、scout/搜集、MG42 拾取、复盘卡、G3 美术继续打磨。

## 契约（视图/控制器）

1. 开局不载入预设 A/B；三人站在 `squad_insertion`（南门入场）。
2. A/B 藏在「示例方案」按钮后。
3. 三人中文卡 + 起始套件选武器；MG42 置灰，提示「需在隐蔽补给点找到」。
4. 点选 → 点合法格放置（尊重 `tier` / `high_slots` 高亮）；拖拽设朝向。
5. 玩家自放地雷与越线；默认起爆类型来自 `yard.json.default_trigger`。
6. 「开始等待」在未放满队员（及条件未就绪）时禁用，一行中文原因。
7. 「再来一局」保留上一局计划。
8. 隐藏补给：`visibility:"hidden"`（兼兼容 `hidden:true`）开局不绘制。

## 验收

- W3：未触碰开局不可开始；脚本化放置能跑到结算；MG42 不在起始套件。**56 passed, exit 0**
- W2：金标哈希不变。**61 passed, exit 0**
- 截图：`play1_blank` / `play1_mid` / `play1_wait` / `play1_result`（artifact）
- Pages：已推 `vs/g3` → `66b21ae`，等 Actions 部署

## 非目标（后续切片）

- VS-W4a scout + 开箱拿 MG42
- VS-FX1 起爆表现
- VS-UX2 等待微调
- VS-W6a 复盘卡
