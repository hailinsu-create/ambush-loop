# A1.2 角色/武器资产修复验收包 — 2026-10-02

这是固定产物的技术修复与独立样本评审包，供 PR15 主作者验收集成。写实品质、完整战斗、回放和手机性能没有完成验收。

## 基线、边界和交付

- 来源：远端 `wip/asset-actors-handoff-20261002` 的指定冻结资产 SHA `f7c30f9f7f0c2d53513191235f3a719a251e3a4c`。远端交接文档 HEAD `a164aa0daa72e90c12b49c5600f06b22a5066202` 已核验，资产冻结点是其祖先。
- 实际渲染/导入/二进制验证源码：`ddba637d3f83813e3c763c00f3d10fca01294240`。后继证据提交只追加本目录的报告/截图/视频与字面候选 patch，不改资产或共享运行时。
- 独立分支 `fix/asset-actors-dot-20261002`，工作区 `/workspace/ambush-actors-dot`。没有推送 PR15、合并、部署、模拟器或真机测试。
- 产物：22 资产、51 LOD；7 人物、10 枪、5 工具。`enemy_heavy` 三个旧 WIP 文件被明确删除，换成三份 `enemy_sneak`，匹配实际 `patrol/flank/sneak/echo`；不更改敌人逻辑或战斗数值。
- `build_yard_kit.py` 只被作为 guarded helper 模块导入；未调用其 `main()`。旧 yard 图集、18 个旧道具 GLB、yard_kit.blend、共享 manifest/loader/main/presenter/view_state/replay/隔离包装器等 41 文件与 f7 基线逐字节相同，见 [保护范围哈希](evidence/protected-paths.json)。其他共享测试也没有改动。
- 仓库 AGENTS/README/当前设计与交接已读取。没有可读的本机 `.agents/skills` 条目；应用了仓库 `.cursor/skills/paperroute-game-build/SKILL.md` 的源图、clay 和引擎姿态评审流程。

## 实际修复与查因

1. 原日志 18 条 mesh-invalid 警告：降面生成重复面和未使用 corner/UV 数据。先三角化、清理退化几何，降面后 validate，再验证最终二进制索引/面积/法线/权重；新导出没有 mesh-invalid 警告。可选 Draco 库缺失仍会打印，未启用 Draco，不是网格验证通过的依据。
2. WIP 部分动画读到前一帧/前一动作父骨变换，出现 hit 深穿地、crouch 失真和起始帧断手。改为先计算全套绝对姿态，再显式求父子 rest/pose 的局部 basis。
3. 用实际骨段长度求 IK，约束手部可达范围、降低行走/跑步髋高；同步跑步两手；拾取屈膝。死亡收臂并按实际蒙皮表面求地面高度。保留原地动作，root 不动。
4. WIP `PLACEHOLDER` 导出实际不含命名材质。改为 `EXPORT + image_format NONE`：材质名 `v2_actor_atlas` 存在，GLB 不嵌入图集。共用的 actor PBR 与 yard 图集分流。
5. 武器导出真实命名节点 `<asset_id>__socket_grip/muzzle/support_hand`；刀有 grip/tip。修复 Blender 跨资产同名 empty 自动后缀问题。十枪加了可区分的构型细节：Garand 气体管/照门、Kar98k 枪管箍、MP40 折叠托、不同瞄镜长度等；历史外形准确度仍待评审。
6. 预算见下表；静态工具地面原点已归零，枪/刀保留握把原点。UV 保留图集 tile，按 bind-space 米坐标确定投影；二进制表面排序与 1e-6 精度规范化。

## 骨骼、身份、插槽、材质与坐标契约

以 [contract.json](contract.json) 和 `art/v2/actors_manifest.json` 为机器可读入口。

- 1 cell = 1 m，+Y up、-Z forward。人物 Node3D 位置来自现有 `world_space.gd`；旋转用 `facing_yaw()`，不加额外 180° 修正。visual_only 不写碰撞、导航、LOS、战斗、历史状态。
- 优先样本：rifleman → operator_rifle；normalenemy → enemy_patrol；firstrifle → m1_garand。实际角色枚举 0/1/2 → rifle/mg/scout；敌人 kind patrol/flank/sneak/echo → patrol/flank/sneak/radio。
- 所有 7 人物 × 3 LOD 共享 20 骨、父子关系、rest、inverse binds；GLB 权重归一、关节索引有效。当前服装段主要用单骨刚性权重，未达到精细连续蒙皮品质。
- BoneAttachment3D 在 `hand.R`，局部位移 `(0,0.035,0)`，局部 X 旋转 +90°；`hand.L` 同规格作为支撑手。长枪局部支撑点 `(0,0,-0.26)`，枪口读真实 marker，再经 gun.global_transform 变到 world_space。
- 手枪没有支撑手 marker。当前 shared hold 是长枪动作；手枪/SMG/MG/狙击/刀的专用握持 overlay 仍需制作并验收，不能拿共用长枪握持代表它们均已通过。
- glTF 不保存 loop 语义，需按台账给 idle/walk/run/aim/crouch/crouch_walk/haul 设置 LOOP_LINEAR；fire/pickup/death/deploy/hit 为单次。duration 已按 30 fps 实际帧数记录。
- pickup/deploy/haul 的枪械要收起/隐藏；death 要掉落/隐藏。样本按此处理，尚未实现实战装备/工具/尸体挂接。动作样件是 reach/fall 等表现，不能宣称物品接触事件或拖拽玩法已验收。
- actor albedo = sRGB；normal 与 ORM = linear；ORM G=roughness、B=metallic、R=常量 AO1，normal_scale=0.4。每模型 1 surface，所有角色/枪/工具共用 1 材质与 3 张 1024² 图；RGBA8 完整 mip 链约 16 MiB 是保守估算，非手机测量。
- [material-routing.candidate.patch](material-routing.candidate.patch) 是单独候选资料，未应用到共享 loader。实际在独立复制 fixture 中编译运行通过人物、枪、稳定枪口节点及旧 yard unnamed 材质 fallback，见 [候选日志](evidence/material-candidate.log)。由主作者审查后决定应用；共享 manifest 保持不变，独立 actors_manifest 不必自动合并。

## 逐项证据与实际退出码

- [二进制报告](evidence/final-binary.json)、[日志](evidence/final-binary.log)：退出 0，22/51、零违规；逐文件 SHA、三角面、无退化面、有限坐标、单位法线、UV 范围、权重、骨架/rest、marker 位置、12 动作轨道和循环接缝。21 个 skeleton × 12 动作 × 25 时刻 = 6,300 个蒙皮姿态样本。
- 最低蒙皮点：-0.00279 m（最坏约 2.79 mm 穿入；验证门槛 -15 mm）。最大四肢端点差：0.000003 m。循环首尾接缝为 0 至舍入精度。不是每一个连续时刻的无穿插证明。
- [完整 Godot 工程导入](evidence/final-project-import.log) 经原隔离包装器，退出 0；[独立 fixture 导入](evidence/fixture-import.log) 与 [Godot 日志](evidence/final-engine.log) 退出 0。固定版本 4.7.2，Compatibility / Mesa llvmpipe；没有 mesh 导入警告。虚拟显示不支持 VSync 的环境警告仍存在。
- [引擎报告](evidence/engine-report.json)：51 GLB 全部实际导入、骨/skin/动作采样，412 PNG 捕获，零失败。优先两人物 + 两步枪的 3 LOD × 8 方位；35°/65°、暮色、全部人物/装备的 LOD360/近远；全部人物各动作各 LOD 的中间姿态；优先动作每段 25 个视觉时刻。
- [12 段采样动作视频](evidence/clips/) 来自 Godot 实际渲染帧并按台账 duration 编码。它们是固定样本的采样序列，不是实战录屏。[姿态接触表](evidence/temporal-poses.png)、[全部动作](evidence/all-actions-lod0.png)、[优先 LOD](evidence/priority-lods.png)、[装备360](evidence/equipment-360.png)、[暮色360](evidence/dusk-360.png)。原 412 张的名称、SHA-256、尺寸索引见 [capture-index](evidence/capture-index.json)；原图留在独立交付目录。
- 共用长枪握持的最大支撑手误差：0.03652695 m。AnimationPlayer pause/2× 检查通过，限 fixture；没有检验实战时钟、冻结方案或历史回放。
- [源校验与渲染](evidence/source-report.json)、[日志](evidence/final-source.log) 退出 0：7 份可编辑人物、20 骨和源 mesh.validate；6 张 front/side/rear 的 clay/材质图。CPU Cycles 8 samples，不开 denoise，因此源图有采样噪点。
- [16 人物+枪的资产负载样本](evidence/reference_16_actor_load.png)：3 英雄 LOD0 + 13 敌人 LOD1 + 16 枪；实测 66 draw calls / 92501 submitted primitives。整个捕获集合最高 66 draw calls。它没有院子、HUD、特效、声音或战斗，不能替代实战 200 draw 警戒或手机 30/60 FPS 验收。

## 三角面账本

英雄/敌人统一上限 8000/4000/1800；枪 3000/1500；工具 2000/1000。台账和二进制计数相符。

| asset_id | LOD0 / LOD1 / LOD2 triangles | surfaces |
| --- | --- | --- |
| operator_rifle | 7960 / 3945 / 1736 | 1 |
| operator_mg | 7960 / 3945 / 1726 | 1 |
| operator_scout | 7960 / 3945 / 1738 | 1 |
| enemy_patrol | 7960 / 3945 / 1736 | 1 |
| enemy_flank | 7960 / 3945 / 1737 | 1 |
| enemy_sneak | 7960 / 3945 / 1738 | 1 |
| enemy_radio | 7960 / 3944 / 1735 | 1 |
| m1911 | 352 / 142 | 1 |
| luger | 396 / 164 | 1 |
| m1_garand | 900 / 428 | 1 |
| kar98k | 856 / 404 | 1 |
| thompson | 888 / 420 | 1 |
| mp40 | 868 / 410 | 1 |
| bar | 868 / 410 | 1 |
| mg42 | 1416 / 696 | 1 |
| springfield | 960 / 458 | 1 |
| kar98k_zf | 1048 / 504 | 1 |
| knife | 144 / 34 | 1 |
| grenade | 368 / 150 | 1 |
| mine | 168 / 46 | 1 |
| decoy | 148 / 35 | 1 |
| ammo_pack | 132 / 28 | 1 |

## 仍未通过或未验收

1. **重复生成未通过字节级一致性**：[重建报告](evidence/rebuild.json)。贴图相同；本次全部静态装备相同；16 个人物 LOD 哈希不同，涉及对称角点的降面/UV选择及导出拆点。未拿旧道具的哈希一致声明替代人物证据。必须使用冻结 GLB 哈希，重建另行二进制/引擎评审；继续处理人物 deterministic LOD 是后续任务。
2. 写实脸部/衣料、刚性分段关节、远景辨识和所有 10 枪的历史准确度需主作者视觉验收；此包没有自动“approve”。LOD360 已捕获，实战 LOD 阈值/滞回/切换/动态 AABB 未接入。
3. 专用枪族/刀握持、工具接触、收枪/掉枪、拖尸挂接及动画事件需集成验证。不能根据 reach 动作声称 gameplay pickup/deploy/haul 完整通过。
4. 六关实战、回放身份/装备/事件历史、暂停/2×与特效/声音去重未验。手机 FPS、热稳定、VRAM/压缩/触控后置未验；不启动设备测试。
5. 外部 GPT PLAN/REVIEW unavailable。未创建 PR、未 merge 或部署。

## 重现与集成

使用 Blender 4.3.2 和固定 Godot 4.7.2。构建仅在独立 worktree；读取此包冻结产物最可靠，不把未通过的重建称为同一哈希。

```bash
blender -b --python ambush_loop/ArtSource/v2/build_actors.py
python3 ambush_loop/ArtSource/v2/actor_acceptance/validate.py --output /tmp/actor-binary.json
bash ambush_loop/scripts/run_isolated_test.sh /absolute/Godot_v4.7.2-stable_linux.x86_64 editor_import
DISPLAY=:98 bash ambush_loop/ArtSource/v2/actor_acceptance/run_review.sh /absolute/Godot_v4.7.2-stable_linux.x86_64 /tmp/actor-review
blender -b -t 4 --python ambush_loop/ArtSource/v2/actor_acceptance/source_review.py -- /tmp/actor-source
```

父任务转交固定提交给主作者。由于 PR15 基线不含 f7 的 WIP 新文件，不能只 cherry-pick 最后一条“修改已有文件”的提交到它；应审查完整资产 diff/合成 patch，或先取 WIP 基线再顺序取三个修复提交和证据提交。候选材质 patch 单独审查应用。规划索引/共享接缝更新由主作者完成，避免本包越过“只提交资产源和生成范围”的边界。
