# G2 院子环境 / 武器 / SFX 资产批

| 字段 | 值 |
|------|-----|
| 门 | **G2**（所有者覆盖「真机+陌生人」门禁，本批先交付） |
| 方法 | 仓内程序生成（Pillow/numpy）；无付费/商店素材 |
| 生成 | `python3 assets/g2/generate_g2_assets.py` · `python3 assets/g2/generate_g2_sfx.py` |
| 许可 | 生成物 **CC0-1.0**；脚本 MIT（随仓库） |
| 主题 | WWII 夜伏；武器为可收集实体道具 |

---

## 资产表

### 地面 / 结构 tile（64×64，顶视夜景）

| 路径 | 用途 | 灰盒映射 |
|------|------|----------|
| `tiles/dirt.png` | 泥土地 | `ground` 默认 |
| `tiles/mud.png` | 泥泞 | `alley` |
| `tiles/cobble.png` | 石板路 | `road` / `gate_*` |
| `tiles/grass.png` | 草皮 | `ground` 稀疏交替 |
| `tiles/wall.png` | 墙 | `wall` |
| `tiles/fence.png` | 篱笆/围栏样张 | 道具位 |
| `tiles/high.png` | 高点/屋顶（黄描边） | `tier=high` |
| `tiles/ramp.png` | 坡道 | `ramp` |
| `tiles/tile_*.png` | 与 G1 文件名对齐的别名 | 加载兼容 |

### 道具

| 路径 | 描绘 |
|------|------|
| `props/shed.png` | 谷仓/棚屋顶视 |
| `props/crate.png` | 木箱掩体 |
| `props/sandbag.png` | 沙袋低掩 |
| `props/barrel.png` | 油桶 |
| `props/ammo_box.png` | 弹药箱（隐藏补给） |

### 武器（`weapons.csv` id）

| id | 图标 | 顶视道具 | 单位剪影 |
|----|------|----------|----------|
| `kar98k` | `weapons/icons/kar98k.png` | `weapons/sprites/kar98k.png` | `weapons/units/kar98k.png` |
| `mp40` | `weapons/icons/mp40.png` | `weapons/sprites/mp40.png` | `weapons/units/mp40.png` |
| `mg42` | `weapons/icons/mg42.png` | `weapons/sprites/mg42.png` | `weapons/units/mg42.png` |
| `grenade`（柄式手雷） | `weapons/icons/grenade.png` | `weapons/sprites/grenade.png` | `weapons/units/grenade.png` |
| `mine`（Teller） | `weapons/icons/mine.png` | `weapons/sprites/mine.png` | `weapons/units/mine.png` |

### SFX（22.05 kHz mono WAV，峰值归一 −6 dBFS）

| cue | 文件 |
|-----|------|
| Kar98k 射击 | `sfx/weapon_kar98k.wav` |
| MP40 射击 | `sfx/weapon_mp40.wav` |
| MG42 射击 | `sfx/weapon_mg42.wav` |
| 手雷投掷 / 爆炸 | `sfx/weapon_grenade_throw.wav` · `weapon_grenade_detonate.wav` |
| 地雷起爆 | `sfx/weapon_mine_detonate.wav` |
| 脚步 dirt/mud/cobble/grass | `sfx/foot_*.wav` |
| 警报四档 | `sfx/alert_{quiet,suspicious,area,global}.wav` |
| UI 点击 | `sfx/ui_tap.wav` |
| 埋伏起爆 sting | `sfx/ambush_trigger.wav` |

### 其它

| 路径 | 用途 |
|------|------|
| `contact_sheet.png` | 联络表（不进 Web 包） |

---

## 灰盒集成

- 开关：**G2 美术**（默认开）；关则回 G1 tile/单位。
- G1 锥/扇/标记/警报图标始终可叠加（可读性优先）。
- 警报档变化播放四档 SFX（补已知缺口）。

```bash
python3 ambush_vs/assets/g2/generate_g2_assets.py
python3 ambush_vs/assets/g2/generate_g2_sfx.py
```
