# VS-FX1 / PLAY-3：起爆战斗表现层

- 日期：2026-10-17
- 分支：`vs/g3`（Pages；**不合并**）
- 状态：**已实现 / 本机隔离测试已绿**
- 来源：差距报告 fix #3

## 目标

视图消费 `fire/hit/kill/mine_detonate/grenade_*`：枪口火、曳光、命中火花、地雷爆闪+轻震、尸体留场、分武器枪声、警报升档敌方喊叫；末杀慢动作；结算延迟约 2 s。

## 范围

- **做**：`view/combat_fx.gd` + greybox 绘制/音频/时序；W5 测试。
- **不做**：改 `NightSim` / W2 金标；复盘卡；G3 美术。

## 验收

| 套件 | 结果 |
| --- | --- |
| W2 | 61 |
| W3 | 57 |
| W4 | 27 |
| W5 combat FX | 19（plan A fire/kill 计数与 log 一致；bodies==kills；金标不变） |

截图：`trigger` / `midfight` / `bodies`。
