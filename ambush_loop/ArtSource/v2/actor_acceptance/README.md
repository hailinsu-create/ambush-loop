# A1.2 独立角色／武器资产候选 R3 — 2026-10-02

本片修复优先步枪人物的球形肘膝接缝、鞋面分离、悬空枪吊环和低持枪双手偏离，补充实际 heel/toe 步态与暮色工业近远景对照。**技术样本通过；近景脸部、最终战术美术质量与完整实战仍未验收。** [R2 历史报告](R2_README.md)、[R1 历史报告](R1_README.md) 保留，不能混作本版证据。

## 固定提交与接收范围

- 冻结 WIP：`f7c30f9f7f0c2d53513191235f3a719a251e3a4c`；本片基线为已交付 R2 `812261a0d7c29446ab631108feec5389cec2950b`。
- **实际被测代码与资产：`00b270863ba5a2cd5425abf2a31e78965c72ae45`**。后续证据提交只改本目录说明／契约／证据，不改变已测生成器、GLB、动画或测试代码。
- 独立分支 `fix/asset-actors-dot-20261002`，工作区 `/workspace/ambush-actors-dot`；占用 `ArtSource/v2/build_actors.py`、`actors.blend`、`actor_acceptance/` 和候选台账列出的 51 GLB。没有推送 PR15、合并、部署、模拟器或真机测试。
- [42 路径保护报告](r3_evidence/protected-paths.json) 全部与 R2 字节一致：yard 源／blend／atlas／旧 yard GLB、三张 actor atlas、共享 manifest／loader／main／presenter／view_state／replay／测试。工业环境只复制既有 yard 资产到独立 fixture。
- **共享 `art/v2/actors_manifest.json` 仍停留 R1。** 主作者审查 [catalog_candidate.json](catalog_candidate.json) 后自行更新；不要用旧 manifest hash 检查 R3。全局 yardatlas 覆盖人物／枪仍错误；[材质分流候选 patch](material-routing.candidate.patch) 沿用，未应用共享 loader。

## 修复与可追溯像素

before／after 使用相同 Godot 相机、灯光、动作与相位。原始截图 SHA 和代码出处见 [capture-index](r3_evidence/capture-index.json) 与 [provenance](r3_evidence/provenance.json)。before 使用 R2 固定资产和本片新增 quality fixture；日志 SOURCE_SHA 是当时工作区 HEAD，不表示新 fixture 已存在 R2。

- 连续袖管／裤管替代肘膝球体，肩延伸进夹克，肘膝与腕／踝相邻骨混合权重。[蹲走关节对照](r3_evidence/crouched-joints-before-after.png)。七人物全部 LOD 采用共同生成方式；[21 项 rig 比对](r3_evidence/rig-compatibility.json) 的层级、rest、inverse binds 一致。
- 靴面改闭合 loft，沿鞋底接合，鞋帮／鞋带随 foot/shin 混合，实际抬脚像素没有旧悬空缺口。[heel/toe 对照](r3_evidence/heel-toe-before-after.png)、[靴部动画](r3_evidence/foot_walk-before-after.mp4)。按实际足部顶点计算地面抬升；二进制 97 相位脚 pitch 从近零变为约 -16.75°～+11.67°，见 [foot-pitch](r3_evidence/walk-foot-pitch.json)。仍是原地动画，不代表实战 world travel 已脚锁定。
- 双手改掌部、弯曲手指、连通拇指与腕袖口；长枪缩短 receiver、增加 stock wrist，吊环改附着枪身的 U 形结构。[M1 握枪对照](r3_evidence/rifle-grasp-before-after.png)。手指没有独立骨，不宣称开合、扳机事件或其他枪种握持通过。
- 低持枪斜横胸前，支撑手跟随共同枪轴；走／跑增加足滚动和髋部小幅横移，aim/fire 保持前向射击。[走路动画](r3_evidence/gait_operator_rifle_walk-before-after.mp4)、[跑步动画](r3_evidence/gait_operator_rifle_run-before-after.mp4)。视频由每动作 16 个真实 Godot 帧按台账时长播放，重复三次，是资产采样视频。
- skull/jaw 合并为连续轮廓，缩小眼／鼻／耳与头盔厚度。[正脸对照](r3_evidence/face-front-before-after.png)、[敌人近脸](r3_evidence/enemy-face-before-after.png)。重叠下巴和凸出眼球已减少；**新脸仍程序化、棱角与简化五官可见，不能标为写实质量通过**。
- enemy_patrol 增加横向 bedroll／breadbag 身份轮廓。暮色采用既有仓库／地面／油桶／院灯，冷环境光加暖灯：[4 m 近景](r3_evidence/industrial-near-before-after.png)、[10 m LOD2 远景](r3_evidence/industrial-far-before-after.png)。独立样本中制服／装备轮廓有区分；真实遮挡／HUD／六关镜头尚待集成。

源 Blender front/side/rear 各有材质和 clay 图：[材质正面](r3_evidence/source_material_front.png)、[clay 侧面](r3_evidence/source_clay_side.png)；[source-report](r3_evidence/source-report.json) 七人物各 20 骨／3 meshes，mesh validate 无修正。CPU Cycles 8 samples 有噪点，非最终宣传图。

## 主作者必须检查的接口

[contract.json](contract.json) 与候选台账为机器入口。rifleman→operator_rifle、normalenemy→enemy_patrol、firstrifle→m1_garand；role 0/1/2 与 patrol/flank/sneak/echo 映射不变。

1 cell = 1 m，+Y up、-Z forward，人物 ground origin，world_space 只转换一次。20 骨层级／rest／inverse binds、12 动作名与时长、手挂点及枪口／支撑 marker 不变；visual_only 不写模拟／碰撞／导航／LOS／回放。

| 接口 | R2 → R3 | 接入要求 |
| --- | --- | --- |
| sight_eye，head local | `(0.037,0.139,-0.110)` → `(0.037,0.139,-0.106)` | 眼点靠近新头部表面 4 mm；如运行时使用则更新 |
| mine socket_grip，tool local | `(0.115,0.035,0)` → `(0.115,0.075,0)` | +40 mm 配合闭合手套；读取 marker，避免旧硬编码 |
| mine pressure_plate | `(0,0.075,0)`，不变 | ground origin 与放置物坐标保持 |
| low-ready 方向 | 共同枪轴斜横胸前，约 20° 横向偏转／10° 下倾 | 由手骨与 mount 提供；aim/fire -Z 射击前向不变 |

hand.R / hand.L 局部平移 `(0,.035,0)`、X+90°，枪支 support `(0,0,-.26)` 保持。读取 `<asset_id>__socket_muzzle` 经 gun.global_transform 转世界；工具挂点用 `palm_offset - attachment_basis * tool_local_grip`。**工具 fit 是坐标样本，不是拾取／放置／收枪事件实现。** haul 仍是弹药包携行，尸体拖拽未验收。

材质仍 `v2_actor_atlas`：albedo sRGB；normal / ORM linear，normal_scale .4；ORM R=AO1、G=roughness、B=metallic，metallic scalar1。一个共享 StandardMaterial3D，每模型一个 surface，无 GLB 内嵌纹理。glTF 无 looping 字段；按台账设置循环，不将所有动作强制循环。

## 实测、差异与预算

[二进制审计](r3_evidence/binary-verified.json)：22 资产／51 LOD、零违规／退化三角形；21 skins × 12 clips × 25 时刻 = 6300 蒙皮样本。最低点 -4.19 mm，检测门槛 -15 mm；不证明连续所有帧或跨动作混合无穿插。

[Godot 报告](r3_evidence/engine-report.json) 与 [日志](r3_evidence/engine-verified.log)：4.7.2 Compatibility／Mesa llvmpipe，实际导入 51、截图 462、0 failures。包含三 LOD 八方位、12 动作各 25 帧、全部人物各 LOD 动作中帧与五工具双 LOD 五阶段。质量 fixture before／after 各 190 截图，[after 报告](r3_evidence/quality-report.json) 0 failures，含优先两人物近脸／握枪／步态与工业近远景。没有 mesh-invalid 或 Godot mesh warning；虚拟显示打印 VSync 不支持，Blender 打印可选 Draco 库缺失。

共同步枪持枪样本支撑误差最大 **0.505 mm**（R2 36.53 mm），aim/fire 眼点至照门枪线最大 14.64 mm。地雷 deploy 中点 ground origin 0.93 mm，工具 grip 误差 <0.001 mm；数字不能代替手指形状／事件验收。

16 人物 + 16 枪参考资产 fixture：**66 draw calls／71,084 submitted primitives**（R2 72,944）；不含整院／HUD／实战负载，不宣称手机 FPS／内存通过。每模型一个 surface，预算字符 8000/4000/1800、枪 3000/1500、工具 2000/1000，全部通过。

| 资产 | 三角面 LOD0 / LOD1 / LOD2 |
| --- | --- |
| operator_rifle | 5846 / 2852 / 1668 |
| operator_mg | 6210 / 3216 / 1680 |
| operator_scout | 5750 / 2752 / 1548 |
| enemy_patrol | 5902 / 2884 / 1700 |
| enemy_flank | 5756 / 2740 / 1548 |
| enemy_sneak | 5842 / 2788 / 1604 |
| enemy_radio | 5878 / 2884 / 1700 |
| m1_garand / kar98k | 1124/340；1164/352 |
| thompson / mp40 / bar | 1024/328；1004/336；1004/336 |
| mg42 / springfield / kar98k_zf | 1552/564；1268/428；1356/452 |

手枪／工具完整值见二进制报告。[R2→R3 分类](r3_evidence/change-classification.json)：角色几何／权重／动画、八长枪几何和地雷握点变更；**另 12 GLB 仅 exporter data-block 名序 metadata 变化**，两手枪与 ammo_pack／decoy／grenade／knife 双 LOD 所有语义组件完全相同。这 12 项明确纳入 51 文件台账，没有 yard 再生成。

两个独立 Blender 4.3.2 进程 **51/51 raw 与 semantic hash 一致**：[重复报告](r3_evidence/semantic-verified.json)；[raw-repeat-tracked](r3_evidence/raw-repeat-tracked.json) 另核对两构建、仓库产物、三纹理与台账字节相同。沿用 R2 固定 tessellation／无 Decimate／1e-6 语义精度，8 个 [反证测试](r3_evidence/semantic-falsification.json) 通过，未放宽检查。blend 内部路径／元数据不宣称 raw 可复现。

## 重做入口与未验事项

从 `ambush_loop/` 运行：

```bash
blender -b --python-exit-code 1 --python ArtSource/v2/build_actors.py -- --output-root /tmp/actors-a
blender -b --python-exit-code 1 --python ArtSource/v2/build_actors.py -- --output-root /tmp/actors-b
python3 ArtSource/v2/actor_acceptance/validate.py --project /tmp/actors-a --catalog /tmp/actors-a/catalog_candidate.json --output /tmp/binary.json
DISPLAY=:97 bash ArtSource/v2/actor_acceptance/run_review.sh /path/to/Godot_4.7.2 /tmp/actor-review ArtSource/v2/actor_acceptance/catalog_candidate.json
DISPLAY=:97 bash ArtSource/v2/actor_acceptance/run_review.sh /path/to/Godot_4.7.2 /tmp/actor-quality ArtSource/v2/actor_acceptance/catalog_candidate.json "$PWD" "$PWD/ArtSource/v2/actor_acceptance/quality_review.gd"
```

生成器强制独立 output root；不要用旧 build_yard_kit.py 重写广泛产物。最终导出／二进制／语义／反证／Godot／源渲染实际退出码均 0，见 provenance。848 原始 PNG 与构建保留于 `/workspace/deliverables/actor-repair-20261002-r3/`；仓库有精选前后图、三段实际采样视频、六源图和完整 hash 索引。

待验：最终近脸／写实质量、其他枪种／刀专用握持、world travel 脚锁与动作过渡、装备事件、死亡掉枪／尸体拖拽、真实遮挡与六关、回放／pause/2x 集成和 LOD 切换。外部 GPT PLAN/REVIEW unavailable；无艺术 approve。设备测试按指令暂缓。**截图捕获和运行时样本 review 通过均不等于 A1.2 或完整实战通过。**
