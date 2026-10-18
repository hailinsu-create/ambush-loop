# Blender 无头 3D 动画模型 → 固定俯仰角 8 向 2D 精灵表渲染管线

在无 GPU 的 Linux 上用 Blender 后台模式（`blender -b`）把带骨骼动画的 3D 模型
（`.glb` / `.gltf` / `.fbx`）渲染成**固定俯仰角、多朝向、统一比例**的 2D 精灵表 PNG，
并附带一份完整的 JSON 元数据。另有一个不依赖 Blender 的后处理脚本用于转 WebP、
拼条带、俯仰角并排对比以及手机横屏比例模拟。

```
tools/sprite_render/
├── render_sprites.py   # 在 Blender 内运行，导入模型 / 渲染 / 输出精灵表 + JSON
├── postprocess.py      # 系统 python3 运行，webp / strip / compare / phone
└── README.md
```

---

## 1. 环境要求

- Blender 5.2 LTS（本管线在官方 Linux 便携版 `Blender 5.2.2 LTS` 上验证，本机装在 `/home/box/tools/blender`，解压后约 1.2GB；免费、无需账号）。
- 系统 `python3`：`Pillow >= 10`（需要 `ImageFont.load_default(size=...)` 与 WebP 支持）、`numpy`。
- `render_sprites.py` 只使用 Blender 自带模块 + `numpy`（**不依赖 Pillow**，内置了一个最小 PNG 写出器）。
- 无 GPU 也可运行：本机（8 核 CPU、无 GPU）实测 EEVEE 在 `-b` 下可用（软件 OpenGL）；若别的环境 EEVEE 黑图，脚本会自动回退（见 §6）。

---

## 2. 快速开始

以下示例使用测试模型 RobotExpressive（见 §10 授权）。

### 2.1 列出动作

```bash
blender -b --factory-startup -P render_sprites.py -- \
  --input /path/to/RobotExpressive.glb --list-actions
# ACTION Idle 0.0000 80.0000 loop
# ACTION Death 0.0000 23.0000 oneshot
# ...
```

### 2.2 渲染 Idle + Walking 的三个俯仰角

```bash
for p in 50 60 70; do
  blender -b --factory-startup -P render_sprites.py -- \
    --input /path/to/RobotExpressive.glb \
    --actions Idle,Walking --frames-map Idle=4,Walking=6 \
    --pitch $p --size 96 --ssaa 4 --engine EEVEE \
    --out out
done
```

输出：`out/RobotExpressive_p50_Idle.png`、`out/RobotExpressive_p60_Walking.png`、
`out/RobotExpressive_p60.json` 等。精灵表**行 = 朝向（dir 0..7）**，**列 = 帧序**。

### 2.3 转 WebP

```bash
python3 postprocess.py webp out/RobotExpressive_p60_Idle.png \
  --quality 80 --method 6 --report out/webp_report.json
```

### 2.4 抽一条朝向条带

```bash
python3 postprocess.py strip out/RobotExpressive_p60.json \
  --action Idle --col 0 --out out/strip.png --scale 2 --label --anchor-cross
```

### 2.5 三个俯仰角并排对比

```bash
python3 postprocess.py compare \
  out/RobotExpressive_p50.json out/RobotExpressive_p60.json out/RobotExpressive_p70.json \
  --action Idle --out out/compare.png
```

### 2.6 手机横屏模拟图

```bash
python3 postprocess.py phone out/RobotExpressive_p60.json \
  --action Idle --display-px 48 --out out/phone.png

python3 postprocess.py phone-compare \
  out/RobotExpressive_p50.json out/RobotExpressive_p60.json out/RobotExpressive_p70.json \
  --action Idle --display-px 48 --out out/phone_compare.png
```

---

## 3. `render_sprites.py` 参数表

所有参数放在 `--` 之后。按扩展名自动选择导入器（`.glb/.gltf` → glTF，`.fbx` → FBX）。

| 参数 | 默认 | 说明 |
| --- | --- | --- |
| `--input PATH` | 必填 | 输入模型路径 |
| `--actions A,B` | 全部 | 逗号分隔的动作名；缺省渲染全部动作 |
| `--list-actions` | - | 只打印动作名与帧范围后退出 |
| `--frames N` | 8 | 每个动作在帧范围内均匀取 N 帧 |
| `--frames-map Idle=4,Walking=6` | - | 逐动作覆盖取样帧数 |
| `--pitch DEG` | 60 | 相机俯角，度；`90`=正俯视，`0`=平视 |
| `--dirs N` | 8 | 朝向数，全部真实旋转模型，绝不镜像 |
| `--size PX` | 96 | 每格输出边长（像素） |
| `--ssaa N` | 4 | 先按 `size*N` 渲染，再用 numpy 做预乘 alpha 的 area 平均下采样 |
| `--engine EEVEE\|CYCLES\|WORKBENCH` | EEVEE | 渲染引擎 |
| `--samples N` | EEVEE 16 / Cycles 32 | Cycles 采样数（启用 OpenImageDenoise 降噪） |
| `--threads N` | 0 | 0=自动 |
| `--light night` | night | 灯光预设 |
| `--shadow` / `--no-shadow` | 关 | 接地软影；仅 Cycles 用 shadow catcher 平面，其它引擎跳过并记 `shadow=false` |
| `--forward +X\|-X\|+Y\|-Y` | `-Y` | 模型“正面”朝向的本地轴（见 §4） |
| `--out DIR` | `.` | 输出目录 |
| `--name NAME` | 输入文件名 | 输出前缀 |
| `--margin F` | 0.06 | 自动取景留白比例（相对画布边长） |
| `--ortho-scale S` | 自动 | 手动覆盖正交相机尺度（手动模式下不做自动取景） |
| `--anchor-y F` | 自动 | 锚点（世界原点/脚底）在画布中的纵向位置比例（从顶部起算）。缺省=自动紧凑取景：按所有帧×所有朝向的联合包围盒居中，锚点由此算出并写入 JSON；给定时按该锚点反推 `ortho_scale`；配合 `--ortho-scale` 时缺省 0.85 |
| `--anchor-x F` | 0.5 | 锚点横向位置比例 |
| `--lock-root` / `--no-lock-root` | 开 | 抵消根骨骼水平位移，让角色原地走 |
| `--oneshot A,B` | - | 强制某些动作按“非循环”取样（缺省名含 death/die/hit 也视为非循环） |
| `--also-frames` | 关 | 额外把每个单帧存到 `<out>/frames/<action>/<dir_name>_<i>.png` |
| `--no-fallback` | 关 | 禁止引擎自动回退 |

循环动作取样为 `[start, end)` 上的均匀 N 点（不重复首尾同帧）；非循环动作（如 Death）
取 `[start, end]` 含末帧。输出 PNG 为 8bit RGBA，`film_transparent=True`，色彩管理用
`Standard` view transform（避免 AgX/Filmic 的灰化）。

---

## 4. 坐标与朝向约定

- 世界：`+X=东（屏幕右）`，`+Y=北（屏幕上/远离相机）`，`+Z=上`。
- 相机固定在**南侧**（`-Y` 方向），正交投影，绕 X 轴俯视 `pitch` 度，方位不随朝向改变。
  因此 8 个朝向里光照方向统一（满足“固定侧光”）。
- 朝向编号与角度（从东逆时针，与游戏 `dir = round(facing_deg/45) mod 8` 一致）：

  | dir | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
  | --- | --- | --- | --- | --- | --- | --- | --- | --- |
  | 名称 | E | NE | N | NW | W | SW | S | SE |
  | 方位角 | 0° | 45° | 90° | 135° | 180° | 225° | 270° | 315° |

- 实现：导入后把所有根对象 parent 到一个位于原点的 `Turntable` Empty（保持变换），
  渲染每个 `dir` 时只把转台绕 Z 旋转 `φ = dir_angle - forward_azimuth`，相机与灯光不动。
- **forward 轴**：`dir=k` 时把模型 `--forward` 指定的本地轴旋到世界方位角 `k*45°`。
  在本测试模型上实测：RobotExpressive 的正脸朝 Blender 世界 `-Y`
  （头部黑色面罩 “Black” 材质面片质心在 `Y≈-0.97`，且头部面部表情形态键
  Angry/Sad/Surprised 移动的顶点也在 `Y≈-1.0`），故默认 `--forward=-Y`。
  这样 `dir=6 (S)` 时相机看到的正是角色正脸。其它模型如正面轴不同，用 `--forward` 调整。

---

## 5. 统一比例与锚点

1. 先对**本次要渲染的所有动作 × 所有取样帧 × 所有朝向**，用 evaluated depsgraph 取蒙皮
   变形后的世界顶点，投影到相机平面，得到全局包围范围 `h/v`。
2. 由包围范围计算全局 `ortho_scale`，并据此放置相机，使得：
   - 全部帧（所有动作 × 帧 × 朝向）共用同一比例尺与同一相机；
   - 世界原点 `(0,0,0)` 的投影（脚底锚点）在每帧都落在同一像素 `anchor_px`（左上为原点，写入 JSON）；
   - 缺省（自动）模式：横向以锚点为中心取对称范围（`anchor_x=0.5`，8 向切换时脚底不左右跳），
     纵向把联合包围盒居中，`anchor_y` 由此算出；四周各留 `--margin`。
3. 多个模型要共用同一比例尺（例如我方 3 职业与敌兵放在一起时身高可比）时，用
   `--ortho-scale S --anchor-y F` 手动固定，所有模型用同一组值渲染。

> 注意：正交相机俯角 `p` 下，竖直高度按 `cos(p)` 缩短、地面纵深按 `sin(p)` 缩短：
> 50° 时身高 ×0.64，60° ×0.50，70° ×0.34。俯角越大人物越“矮胖”、前后迈步越显长，
> 这是真实投影，不是 bug；A0 选俯仰角时需权衡（见 `compare_p*_8dir.png`）。

---

## 6. 灯光预设 `night`

全部集中在一个 dict（`LIGHT_PRESETS["night"]`）便于修改：

- **月光主光**：Sun，冷蓝白 `(0.75,0.82,1.0)`，强度 3.0，方向为“高位左前 45°”
  （从屏幕左上、略朝向相机一侧照来，高度角约 50°），软阴影角度 3°。
- **补光**：很弱的暖色 Sun `(1.0,0.8,0.55)`，强度 0.45（约主光 15%），从右后方。
- **环境**：World 背景深蓝 `(0.02,0.03,0.06)`，强度 0.6，让暗部不至于死黑；
  由于 `film_transparent=True`，背景本身不可见。
- **轮廓光（rim）**：从背后上方的冷色弱光 `(0.65,0.78,1.0)`，强度 0.5。
- 不加任何描边。

**引擎回退**：若请求 EEVEE 且首帧输出全透明或全黑（可见像素最大亮度 < 0.02），
脚本会打印警告并依次回退 `CYCLES → WORKBENCH`，把实际使用的引擎写进 JSON 的
`engine` / `engine_id`。`--no-fallback` 可关闭。

---

## 7. 输出文件与 JSON 字段

```
<out>/<name>_p<pitch>_<action>.png    每动作一张精灵表（行=朝向 dir0..7，列=帧序，格 size×size，无缝）
<out>/<name>_p<pitch>.json            元数据
<out>/frames/<action>/<dir_name>_<i>.png   仅 --also-frames 时输出
```

JSON 顶层字段：

| 字段 | 说明 |
| --- | --- |
| `source` | 输入文件名 |
| `pitch_deg` | 俯角 |
| `engine` / `engine_id` / `engine_requested` | 实际使用 / 实际 id / 请求的引擎 |
| `samples` | 实际采样数 |
| `ssaa` | 超采样倍数 |
| `frame_size` | `[w,h]` 每格像素 |
| `anchor_px` | `[x,y]` 锚点像素（左上原点） |
| `ortho_scale` | 正交尺度 |
| `light_preset` | 灯光预设名 |
| `shadow` | 是否写入接地影 |
| `forward_axis` | forward 轴 |
| `lock_root` | 是否锁定根运动 |
| `dir_order` / `dir_angle_deg` | 朝向名 / 方位角 |
| `actions.<name>.sheet` | 精灵表文件名 |
| `actions.<name>.rows` / `cols` | 行数（=朝向数） / 列数（=帧数） |
| `actions.<name>.loop` | 是否循环 |
| `actions.<name>.fps` | 建议播放 fps（按源帧间隔与场景 fps 换算） |
| `actions.<name>.frames[]` | 每格 `{dir, dir_name, col, source_frame, rect:[x,y,w,h]}` |
| `timing` | `total_render_s` / `frames_rendered` / `avg_s_per_frame` / `per_action_avg_s` |
| `blender_version` | Blender 版本字符串 |

渲染时每帧打印一行 `FRAME <action> <dir> <i> <seconds>` 便于 `grep`，结束时打印 `SUMMARY ...`。

---

## 8. `postprocess.py` 子命令

系统 `python3` 运行，不依赖 Blender。

| 子命令 | 说明 |
| --- | --- |
| `webp <sheet.png...> --quality 80 [--method 6] [--alpha-quality 100] [--lossless] [--report r.json]` | 转有损 WebP（保留 alpha），打印 PNG/WebP 字节数、像素数、KB/千像素，并可写 JSON 汇总 |
| `strip <meta.json> --action Idle --col 0 --out strip.png [--scale 2] [--label] [--anchor-cross]` | 取 8 个朝向的第 `col` 帧拼成一行，整数倍最近邻放大，背景深色夜间地面色 `(34,40,36)`，可画朝向名与锚点十字 |
| `compare <m1.json> <m2.json> <m3.json> --action Idle --out compare.png [--col 0] [--scale 1]` | 三个俯仰角各一行（左侧标注 `50deg` 等），每行 8 向 |
| `phone <meta.json> --action Idle --display-px 48 --out phone.png` | 生成 844×390 手机横屏模拟图：夜间地面背景 + 36px 淡网格；一行 8 向共用同一缩放比（最高那一向的非透明像素高度 = display-px），锚点（脚底）对齐地面线，LANCZOS 缩放；再一行 3 个 1:1 原尺寸对照；左上角写俯仰角 |
| `phone-compare <m1> <m2> <m3> --out phone_compare.png [--action Idle] [--display-px 48]` | 把三个角度的 phone 图上下拼成 844×1170 |

字体使用 `PIL.ImageFont.load_default(size=...)`，不依赖系统字体路径；文字只用 ASCII。

---

## 9. 已知限制

- **EEVEE 无 GPU**：本机实测可用；别的环境若黑图会自动回退。WORKBENCH 速度快但忽略
  灯光预设（使用 studio 光照与材质视口色），只适合预览/排版。
- **接地影**：仅 Cycles 的 shadow catcher 支持透明背景下的投影；EEVEE/WORKBENCH 下
  即使传 `--shadow` 也会跳过并在 JSON 记 `shadow=false`。**已知问题**：自动取景只按模型
  网格算包围盒，不含影子，`night` 主光高度角约 50° 时影子较长，会被格子边缘截断（见
  `engines_p60_robot.png` 第 2 行），且 WebP 体积约翻倍。正式出图前需二选一：取景把影子
  算进去，或改为只烘焙短的接触影（另加一盏近顶光只投影 / 后处理画椭圆落影）。
- **根运动锁定**：通过每帧抵消 armature 根骨 head 的水平位移实现；若模型把根运动写在
  对象层级（而非根骨）或没有 armature，则不生效。
- **材质表达**：Workbench 使用材质视口色（glTF 金属材质在 WB 下观感与 EEVEE 不同）。
- 不处理多材质复杂后处理、不描边、不做阴影贴花以外的地面。
- Blender 5.x glTF 导入器会额外生成一个无关的 `Icosphere` 助手对象（位于
  `glTF_not_exported` 集合，约 2m）。脚本在导入后**删除该集合内的所有对象**，
  并只保留本次导入新增的对象，避免污染渲染。

---

## 10. 实测耗时

实测环境：本机 8 核 CPU、无 GPU、15GB 内存；Blender 5.2.2 LTS；`--size 96 --ssaa 4`
（即每帧按 384×384 渲染再下采样），`night` 灯光，测试模型三角面 3.2k（RobotExpressive）/
4.7k（CesiumMan）。每帧耗时含设置姿势 + 渲染 + 读回 + 下采样；不含每次启动 Blender、
导入与 EEVEE 首帧着色器编译（每次运行约 15–20s 一次性开销）。

| 引擎 / 设置 | 每帧耗时（s） | 备注 |
| --- | ---: | --- |
| EEVEE，TAA 16（默认） | 1.78–2.13（p50/60/70 × 两个模型共 6 次运行，中位 ≈1.9） | 无 GPU 下 `-b` 可用，未触发回退 |
| EEVEE，TAA 8 | 1.25 | 边缘略毛 |
| EEVEE，TAA 64 | 4.57 | |
| EEVEE，TAA 16，`--ssaa 2`（192px 渲染） | 1.66 | 下采样后边缘更硬 |
| Cycles CPU，32spp + OIDN 降噪，`--shadow` | 2.22 | 带透明接地影 |
| Workbench | 0.21 | 不吃灯光预设，仅预览 |

**hero 1,848 帧预计（规划 13.4）**：EEVEE 默认 ≈ 1,848 × 1.9s ≈ 59 分钟（+ 每次运行十几秒开销），
Cycles 32spp ≈ 68 分钟。正式角色网格/贴图更重时按 2–3 倍留量 ≈ 2–3 小时，可夜间批量排队；
不需要 GPU。

**WebP 体积（p60 样例精灵表，未裁边的 96×96 格，Pillow `method=6`，`alpha_quality=100`）**：

| 质量 | 平均每帧（EEVEE 三张表，128 帧） | hero 1,848 帧外推 | 全量 2,672 帧外推 |
| --- | ---: | ---: | ---: |
| q70 | 1,085 B | 2.01 MB | 2.90 MB |
| q80 | 1,225 B | 2.26 MB | 3.27 MB |
| q90 | 1,561 B | 2.89 MB | 4.17 MB |
| q80，Cycles 带长影子 | 2,598 B | 4.80 MB | — |

对应 PNG（无损）约 4.0–5.4 KB/帧。注意：测试模型是低细节、少贴图的风格化模型，
带迷彩/装备细节的正式写实士兵会压得更差，外推值应视为下限；透明区域在 WebP 里几乎不占
体积，因此“按包围盒裁边打包”对文件体积帮助有限，主要省的是显存。


---

## 11. 授权

- 测试模型**不入库**。
- RobotExpressive 作者 Tomás Laulhé (Quaternius)，许可 **CC0 1.0**，
  来源 three.js 仓库 `examples/models/gltf/RobotExpressive`（https://github.com/mrdoob/three.js/tree/dev/examples/models/gltf/RobotExpressive）（修改：Don McCurdy
  加 morph target 并转换）。
- 人体比例测试模型 CesiumMan：Khronos glTF-Sample-Assets `Models/CesiumMan`，© 2017 Cesium，
  **CC BY 4.0**（可商用，需署名）；模型贴图上的 Cesium 标志属商标（LicenseRef-LegalMark-Cesium），
  因此**只作管线验证，不进游戏**。
- 两个模型都只用于验证渲染管线，**不进游戏、不入库**；渲染结果也不入库。
