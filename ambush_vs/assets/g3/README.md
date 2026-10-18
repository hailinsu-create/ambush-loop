# G3 高细节美术（项目自有源图）

| 字段 | 值 |
|------|-----|
| 门 | G3 美术批（灰盒可玩；所有者要求替换简略 G2 PIL） |
| 源 | `src/` 项目自有 AI 成图（`LICENSE.txt`） |
| 管线 | `python3 scripts/build_g3_assets.py`（确定性裁切/抠像/无缝/WebP） |
| 灰盒 | HUD「美术」循环 **G3（默认）→ G2 → G1**；G1 锥/扇/标记始终叠加 |

## 源文件

| 文件 | 用途 |
|------|------|
| `tex_*.jpg` | 地面/墙/屋顶纹理 → seamless 256 WebP |
| `tex_roof_slate_left_shingle_right.jpg` | 左半石板、右半木瓦 |
| `props_sheet_magenta.jpg` | 4×2 道具（品红抠像） |
| `units_sheet_magenta.jpg` | 4×2 单位（上游击/下德军） |
| `weapons_sheet.jpg` | 五武器图标（暗底抠切） |
| `yard_concept.jpg` / `yard_map_concept.jpg` | 情绪参考（不进运行时） |

## 输出表（节选）

| 路径 | 说明 |
|------|------|
| `tiles/{mud,grass,cobble,planks,stonewall,roof_*}.webp` | 256px 无缝 |
| `props/*.webp` | 沙袋/箱/桶/车/棚顶 |
| `units/friendly_*.webp` / `enemy_*.webp` | 带队伍描边 |
| `weapons/icons/{kar98k,mp40,mg42,grenade,mine}.webp` | `weapons.csv` id |
| `fx/lantern_glow.webp` / `vignette.webp` / `high_edge.webp` | 夜景/高点可读 |

重跑：

```bash
python3 ambush_vs/scripts/build_g3_assets.py
```
