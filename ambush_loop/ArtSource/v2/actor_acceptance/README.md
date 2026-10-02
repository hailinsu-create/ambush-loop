# A1.2 独立角色／武器资产候选 R2 — 2026-10-02

16 个人物 LOD 重建差异已闭合：新版本两次独立 Blender 4.3.2 进程导出的 **51/51 GLB 文件 hash 和语义 hash 一致**，三张人物纹理与候选台账也逐字节一致。Godot 4.7.2 的导入和资产样本检查通过；**写实战术风格、完整实战和手机性能仍未通过验收**。

## 固定基线与采用范围

- 冻结 WIP：`f7c30f9f7f0c2d53513191235f3a719a251e3a4c`。R1 已交付：`0242c983e8ae972b58b4f7afe9d08084b8f421c6`；[R1 历史报告](R1_README.md) 与 `evidence/` 保留，不能混作本版证据。
- R2 资产与实际 Godot 检查提交：`dc83a730542d6848b8860056e921e9156b7140c6`。后续本目录证据与 Blender clay 曝光调整不改变这些资产或 Godot 检查代码。
- 独立分支 `fix/asset-actors-dot-20261002`，占用 `/workspace/ambush-actors-dot`。没有推送 PR15、合并、部署、模拟器或真机测试。
- 采用范围为 `ArtSource/v2/build_actors.py`、`actors.blend`、`actor_acceptance/`、候选台账列出的 51 个角色／枪械／工具 GLB 和三张 `actor_*` 纹理。
- **共享 runtime 与 manifest 没有写入。** `art/v2/actors_manifest.json` 仍是 R1；采用新资产后，主作者需审查 [catalog_candidate.json](catalog_candidate.json) 再更新其台账／运行时。不要用旧台账 hash 验证 R2。
- 新旧台账的身份／骨架／动作名与时长保持兼容；手雷、地雷、诱饵、弹药包新增真实 grip 等节点，haul 改为携包样本，原地动作与 root 无位移保持不变。
- [保护范围 hash](r2_evidence/protected-paths.json)：41 受保护路径与 R1 字节相同；actor albedo 属于独占资产，颜色调整被明确记录。yard atlas、18 个旧 yard GLB、yard_kit.blend、build_yard_kit.py、共享 loader/manifest/main/presenter/view_state/replay/隔离测试保持不变。

## 重建差异的原因与语义 hash

[旧复测的逐文件分类](r2_evidence/semantic-prior-repeat.json) 实测 51 项中 16 不一致，全部涉及真实几何／法线／UV，绝非只有时间戳、JSON 顺序或无关序列元数据。骨架、inverse binds、动画、材质、插槽和 mesh 变换语义均一致。在两次旧产物的共同顶点位置，16 项的骨影响集合差异均为 0；包含位置的 weights fingerprint 随几何变化，不能把它误报成独立的权重重绘。

根因是对称壳体的 Decimate 折叠选择。R2 删除角色、枪械和工具的 Decimate：各 LOD 按固定分辨率／特征层直接生成，四边面 FIXED、n-gon EAR_CLIP 三角化，规范化 UV、micron 浮点精度与二进制排序。复测还发现手雷 LOD1 的同类问题，一并修复。

[最终二次导出](r2_evidence/semantic-final-repeat.json) 为 51/51 raw 与 semantic 相同；并非只放宽检查。`semantic_hash.py` 保留有向三角形 winding、重复数量、位置、法线、UV、命名骨影响、rest/inverse binds、动画 key/插值、材质、插槽和 mesh 变换；忽略 buffer／节点／关节／vertex／triangle 顺序以及无引用 vertex。精度明确为 `1e-6`，限本包 one-mesh GLB 契约，不宣称任意 glTF 场景等价。

[8 个反证测试](r2_evidence/semantic-falsification.json) 验证顺序／无关 generator 字符串变化可通过，而移动 vertex、改法线／UV／骨影响／动画 key／rest／材质必须失败。`.blend` 包含独立构建路径和 Blender 文件元数据，未宣称其 raw hash 相同；可复现验收对象是 GLB、纹理与逻辑路径台账。

## 本次明确修复与实际像素结论

- 连续 loft 夹克替代重叠胸腹球体，spine/chest 混合权重；降低浅亮布料／皮肤／钢铁 albedo，去除 radio 重叠双背包与 hood 重叠背壳。
- 优先 aim/fire 提高握把、前伸支撑肩、头靠枪托，缩短长枪枪托以适配骨架；[新侧面 LOD0](r2_evidence/priority_lod0_yaw270.png)、[LOD2](r2_evidence/priority_lod2_yaw270.png) 可与 R1 `evidence/priority_lod0_yaw270.png` 对比。眼点至照门枪线最大 15.05 mm；仅优先 M1 样本验证，其他枪种不套用该结论。
- M1 去掉借用的球形 bolt knob，改独立 operating-rod handle；[CMP 官方实物服务资料](https://thecmp.org/sales-and-service/services-for-the-m1-garand/) 用于确认基本部件。十枪的完整历史轮廓与型号准确性仍待验收。
- 刀尖改成与刀身连续的 3 mm 扁平尖刃，修复原锥形尖比刀身厚的缺陷。
- pickup/deploy 深蹲后接近地面；携包双手间距改 0.12 m，携包位于身前，新增工具实际握把／工作点。实测手雷 ground origin 约 2.04 mm、地雷约 0.93 mm；携包双手支撑误差小于 0.001 mm。
- 实际查看了优先侧面／正面／LOD、源材质与 clay、12 动作首／中／末接触表及走路四分之一相位、工具双 LOD 中间帧和全部人物 LOD2 动作表。见 [动作 1](r2_evidence/priority-actions-1.png)、[动作 2](r2_evidence/priority-actions-2.png)、[工具 fit](r2_evidence/tool-fit.png)、[全部人物 LOD2](r2_evidence/all-actions-lod2.png)。**462 PNG 捕获成功不是 462 项画质批准。**
- 已看像素仍有脸部卡通感、肩肘球形接缝、脚步缺少自然 heel/toe 转移；LOD2 袖管／口袋明显简化。death 是收臂后的刚性倒下，背包支撑躯干，与自然人体死亡表现仍有差距。手套没有可动画手指骨；刀／诱饵仅测挂点 fit，未通过专用握持动作品质。写实门槛仍开放，不能把 technical pass 包装为 A1.2 全通过。

## 坐标、骨骼、插槽与材质接口

[contract.json](contract.json) 与候选台账为机器可读入口。rifleman→operator_rifle；normalenemy→enemy_patrol；firstrifle→m1_garand。角色枚举 0/1/2 与 patrol/flank/sneak/echo 身份保持原契约。

1 cell = 1 m，+Y up、-Z forward，人物 ground origin，现有 world_space 负责坐标／朝向。7 人物 × 3 LOD 的 20 骨、命名父子关系、rest/inverse binds 相同；权重归一最多四影响，夹克连续混合、肢体与配件主要刚性段。visual_only 不写模拟／碰撞／导航／LOS／回放。

长枪使用 hand.R，局部平移 `(0,.035,0)` 与 X+90°，hand.L 同规格。武器支撑点 `(0,0,-.26)`；枪口读 `<asset_id>__socket_muzzle` 并经 gun.global_transform 变换。工具以 grip marker 校正挂点：`tool.position = palm_offset - attachment_basis * tool_local_grip`。携包另读 support_hand。工具 fit 只验证姿态／挂点，拾取、放置、收枪、死亡掉落事件仍需运行时实现。haul 当前是弹药包 carry 样本，不能代表尸体拖拽。

glTF 不保存 looping；主作者按候选台账将 idle/walk/run/aim/crouch/crouch_walk/haul 设为循环，其他动作单次。PBR 材质名 `v2_actor_atlas`，albedo sRGB，normal/ORM linear，normal_scale .4，ORM R=AO1、G=roughness、B=metallic，metallic scalar1。全局 yardatlas 强制覆盖仍不适用；[材质分流候选 patch](material-routing.candidate.patch) 仍仅供审查，本次未写共享 loader。

## 证据、预算与未验收边界

[二进制审计](r2_evidence/binary-final-a.json)：22/51、零违规，21 skins × 12 clips × 25 时刻 = 6300 个实际蒙皮样本。最低点 -4.19 mm，四肢端点差最大 0.003 mm；在 -15 mm 判定门槛内，并非连续所有帧无穿插证明。

[Godot 报告](r2_evidence/engine-report.json) 与 [日志](r2_evidence/engine-final.log)：4.7.2 Compatibility / Mesa llvmpipe，51 实际导入、462 captures、0 failures。包含三 LOD × 八方位，近远／暮色，12 优先动作 × 25 帧，全部人物各动作各 LOD 中间帧，工具 2 LOD × 5 阶段。所有最终导出／二进制／语义反证／Godot／源渲染命令退出 0，没有 mesh-invalid／Godot mesh warning；虚拟显示不支持 VSync，导出打印未启用的可选 Draco 库缺失。

共同步枪 holds_gun 样本的最大支撑误差仍为 36.53 mm（约束 40 mm），不能称精准双掌贴合。工具握把误差 <0.001 mm 是坐标绑定检查，不能证明手指的自然握持。16 人物+16 枪参考 fixture 为 **66 draw calls、72944 submitted primitives**，低于 R1 的92501；没有院落／HUD／实战／手机帧率结论。纹理内存与实际设备 30 FPS/60 FPS、完整六关、回放、冻结时间、动作衔接、枪种 overlay、完整装备事件和真实风格评审均未闭合。

每模型一个 surface；字符预算 8000/4000/1800，枪 3000/1500，工具2000/1000。实测：

| 资产 | LOD 三角面 |
| --- | --- |
| operator_rifle | 6510 / 2764 / 1492 |
| operator_mg | 6874 / 3128 / 1504 |
| operator_scout | 6298 / 2684 / 1416 |
| enemy_patrol | 6510 / 2764 / 1492 |
| enemy_flank | 6304 / 2672 / 1416 |
| enemy_sneak | 6390 / 2720 / 1472 |
| enemy_radio | 6542 / 2796 / 1524 |
| m1911 | 352 / 116 |
| luger | 396 / 128 |
| m1_garand | 816 / 256 |
| kar98k | 856 / 268 |
| thompson | 760 / 256 |
| mp40 | 740 / 264 |
| bar | 740 / 264 |
| mg42 | 1288 / 492 |
| springfield | 960 / 344 |
| kar98k_zf | 1048 / 368 |
| knife | 104 / 40 |
| grenade | 368 / 108 |
| mine | 168 / 124 |
| decoy | 280 / 116 |
| ammo_pack | 264 / 72 |

原始 462 PNG 与日志存于 `/workspace/deliverables/actor-repair-20261002-r2/`，逐图 SHA 见 [capture-index](r2_evidence/capture-index.json)。本包的自动技术结果、已看像素、仍未验项已区分；没有设备测试或环境阻断。

## 可复现命令

生成器强制指定独立 output root；不再默认重写共享 actors_manifest：

```bash
blender -b --python-exit-code 1 --python ArtSource/v2/build_actors.py -- --output-root /tmp/actors-a
blender -b --python-exit-code 1 --python ArtSource/v2/build_actors.py -- --output-root /tmp/actors-b
python3 ArtSource/v2/actor_acceptance/validate.py --project /tmp/actors-a --catalog /tmp/actors-a/catalog_candidate.json --output /tmp/binary.json
# 从仓库根运行模块：
python3 -m ambush_loop.ArtSource.v2.actor_acceptance.semantic_hash --first /tmp/actors-a/art/v2/models --second /tmp/actors-b/art/v2/models --output /tmp/repeat.json
# 资产采用后，从 ambush_loop 运行隔离 fixture：
DISPLAY=:97 bash ArtSource/v2/actor_acceptance/run_review.sh /path/to/Godot_4.7.2 /tmp/actor-review ArtSource/v2/actor_acceptance/catalog_candidate.json
```

Blender source review 使用 6 张真实 clay／材质 front/side/rear；clay 曝光单独降低避免白色过曝，材质曝光为0。源码图噪点来自CPU Cycles 8 samples，非最终美术图。
