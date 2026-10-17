# G1 玩法可读资产（灰盒）

| 字段 | 值 |
|------|-----|
| 门 | **G1**（W2 金标绿之后） |
| 方法 | 仓内程序生成（Pillow PNG）；无付费/商店素材 |
| 生成脚本 | 一次性生成于 2026-10-17；可按本 README 规格重绘 |
| 用途 | 院子灰盒可读性：锥/扇、tile 档、单位剪影、警报/起爆图标 |

---

## 清单

| 路径 | 描绘规则 | ADR / TERMS |
|------|----------|-------------|
| `icons/alert_quiet.png` | 安静：无数值条；淡圆占位 | ADR-ALERT-01 §3.1；TERMS §5 |
| `icons/alert_suspicious.png` | 起疑：头顶 **?** | 同上 |
| `icons/alert_area.png` | 区域警戒：头顶 **?!** | 同上 |
| `icons/alert_global.png` | 全图警报：头顶 **!** | 同上 |
| `icons/trigger_see_first_enemy.png` | 起爆条件：见首个目标 | ADR-TRIGGER-01 §3.1 |
| `icons/trigger_mine.png` | 起爆条件：地雷 | 同上 |
| `icons/trigger_cross_marker.png` | 起爆条件：越线标记 | 同上 |
| `icons/trigger_manual.png` | 备选手动起爆 | 同上 |
| `tiles/tile_ground.png` | 地面档格 | ADR-HEIGHT-01 §3.1 |
| `tiles/tile_high.png` | 高点档：黄描边可辨 | ADR-HEIGHT-01 §3.3 |
| `tiles/tile_wall.png` | 墙/结构（挡视线） | ADR-HEIGHT-01 §3.2 |
| `tiles/tile_low_cover.png` | 低掩体（同层挡） | ADR-HEIGHT-01 §3.2 |
| `tiles/tile_ramp.png` | 坡道＝地面档 | ADR-HEIGHT-01 §3.1 |
| `units/friendly.png` | 队员剪影+朝向 | G1 单位可读 |
| `units/friendly_high.png` | 高点夜间剪影+黄描边 | ADR-HEIGHT-01 §3.3 |
| `units/enemy.png` | 行军敌人剪影 | G1 |
| `units/sentry.png` | 岗哨/巡逻可辨 | ADR-ALERT-01 M1 |
| `cones/vision_cone_ground.png` | 敌方发现锥（地面长） | ADR-ALERT-01 §3.3；橙锥 |
| `cones/vision_cone_high_ext.png` | ×1.5 高目标延伸（与地面锥区分） | ADR-HEIGHT-01 §3.3；ADR-ALERT ×1.5 |
| `cones/weapon_sector.png` | 友军武器扇形 | TERMS §2–3；ADR-HEIGHT 灰色缺口 |
| `cones/occlusion_gap.png` | 扇形灰色遮挡格填充 | ADR-HEIGHT-01 §3.2「被挡＝灰色阴影」 |
| `markers/marker_line.png` | `cross_marker` 线段 | ADR-TRIGGER-01 |
| `markers/mine.png` | 地雷落点 | ADR-TRIGGER-01；TERMS 杀伤区 |
| `markers/threat_slot.png` | 威胁槽标红（`alert_route` 预告） | ADR-ALERT-01 F3/M4 |
| `markers/click_preview.png` | 「点地面看谁能看见这里」高亮 | ADR-ALERT-01 A-05 |

---

## 渲染约定（灰盒视图）

1. **锥长**：地面用 `vision_cone_ground`；对高点目标叠加 `vision_cone_high_ext`（×1.5），颜色/线型与地面锥区分。  
2. **武器扇**：`cells_in_sector` 清视线格用扇形色；同锥内无 LOS 的格用 `occlusion_gap` 灰填（预览＝模拟）。  
3. **图标**：警报不做数值条；起爆类型四枚图标对应条件枚举。  
4. **手机**：单位剪影在 1280×720 / 6 寸横屏目标相机下可数朝向。

生成命令备忘（需 Pillow）：

```bash
# 见本仓库 Agent 会话中的 assets/g1 生成步骤；重跑时保持路径与上表文件名不变。
```
