# A1.2 独立资产候选 R4：十枪握持与过渡 — 2026-10-02

十枪、三角色、三 LOD 的专用握持／抬枪回位／换弹接触候选已完成真实 Godot 播放检查。**功能候选可审查采用；运行时接入、完整实战和最终美术质量仍未验收。** 程序化近脸暂保留既有品质限制，本片没有继续脸部雕改。

## 固定交付与范围

- 基线 R3：`8a1fbe98e4f00ea5209c38d4e0749b1f992f9326`；冻结原始 WIP 为 `f7c30f9f7f0c2d53513191235f3a719a251e3a4c`。历史见 [R3](R3_README.md)、[R2](R2_README.md)。
- **被测资产／生成器／真实枪族播放 fixture：`194d9c41aaddbf014f05c70c14d40c09e6d8131b`**。后续交付只补说明、证据、源图相机范围和独立 CPU sampler 检查；不改变这51 GLB、枪族 profile 或 Godot 播放代码。
- 独立分支 `fix/asset-actors-dot-20261002`，工作区 `/workspace/ambush-actors-dot`；占用 `ArtSource/v2/build_actors.py`、`actors.blend`、`actor_acceptance/` 与候选台账51 GLB。未推送 PR15，未合并／部署／模拟器／真机测试。
- [42 保护路径](r4_evidence/protected-paths.json) 与 R3 字节一致，包含共享 manifest／loader／main／presenter／view_state／replay／测试、yard源／GLB／blend／atlas和三张 actor atlas。
- 共享 `art/v2/actors_manifest.json` 仍停留 R1。主作者审查 [资产台账](catalog_candidate.json)、[枪族合同](firearm_profiles_candidate.json)、[表现时序候选](firearm_runtime_contract_candidate.json) 后接入；不要用旧共享台账 hash 验证 R4。`v2_actor_atlas` 材质保持，[分流候选 patch](material-routing.candidate.patch) 未应用共享 loader。

## 动作与兼容接口

原12动作的名字、时长和实际 key 语义在21个人物 GLB全部保持，见 [21×12 比对](r4_evidence/legacy-clip-compatibility.json)。20骨层级／rest／inverse binds、人物几何／法线／UV／权重／材质不变。1 cell=1m，+Y up、-Z forward、ground origin与world_space一次转换不变；visual_only不写模拟状态。

新增40个可选 clip：六姿态组各 `ready_*/aim_*/fire_*/raise_*/lower_*`，以及十个 `reload_contact_<weapon_id>`；七人物各三 LOD均有52动作。Thompson因垂直前握把单独用姿态组，逻辑仍属于SMG。

| 枪 ID | 姿态组 | 专用接触 |
| --- | --- | --- |
| m1911 / luger | pistol | 左手围握右手，枪族平均照准高度，两型号最大眼线差4mm |
| m1_garand / kar98k | rifle | 前托支撑与机匣上部接触 |
| thompson | thompson | 垂直前握把与弹鼓侧部接触 |
| mp40 | smg | 前托支撑与弹匣底部接触 |
| bar / mg42 | mg | 支撑肩前伸；BAR弹匣、MG42侧部接触 |
| springfield / kar98k_zf | scout | 瞄准镜高度与枪栓柄接触 |

三角色 `operator_rifle/operator_mg/operator_scout` 均检查全部十枪；role 0/1/2、rifleman／normalenemy／firstrifle与四敌人映射不变。身份合同见 [contract.json](contract.json)。

**现有 socket 全部保留**：[30个装备 GLB 比对](r4_evidence/socket-compatibility.json)。手挂点仍 hand.R／hand.L `(0,.035,0)`、X+90°；R3眼点／地雷 grip 不再移动。每枪只新增可选 `pose_support`、`sight`、`reload_contact` marker；新增动作应读这些实际节点，不能继续把左掌硬套旧长枪 -.26m 支撑点。枪口仍读原 `__socket_muzzle`，由实际 gun.global_transform 转世界坐标。

抬枪／回位各0.3s，端点对齐 ready／aim 的 phase0；开火实际导入时长0.233333s；换弹接触1s、.40–.60相位保持接触并返回aim。暂停／回放／2倍速按历史相位采样，不以动画长度限制模拟射速。

基线游戏 `operator.gd:try_fire` 在空弹时立即补包或切手枪、发事件并设置冷却，**没有独立换弹状态**。`reload_contact_*` 只提供闭手伸向现有枪体位置的候选，没有弹匣／枪栓／弹链机械动画，也不提交弹药。主作者根据真实历史事件选择是否采用，不能从回放中的当前活体弹药猜换弹。十枪真实 shot_interval／reload_s 的只读出处与 hash 在表现时序候选中；快速连发、任意中途取消、换枪和上身 locomotion mask 尚待主作者运行时验证。

## 真实动态、源图与测量

[Godot枪族报告](r4_evidence/firearm-report.json)／[日志](r4_evidence/firearm-verified.log)：4.7.2 Compatibility、Mesa llvmpipe，实际 AnimationPlayer.advance 播放25相位，**90配置／540接触行／360端点／90项2倍速／880截图，零失败**；R3同镜头对照另310截图。LOD0／2有近远动态，LOD1有数值接触；每枪近景含三角色。左右掌、眼线及枪口数据取实际导入节点，非重建猜测矩阵。

BoneAttachment需要树入口注册和场景更新：fixture等两帧进入树，并在每次advance后等场景帧再读实际挂枪位置。省略更新的诊断检查曾失败，已拒绝；不能把Skeleton强制更新直接当作挂枪节点已完成更新。

Godot最大支撑误差 **2.045mm**，换弹接触 **0.708mm**，aim/fire眼线 **4.001mm**，右握把0；门槛分别15mm／15mm／35mm。全骨过渡端点最大变换差 `3.04e-7`，2倍速相位／姿态检查误差0。手枪aim旧支撑误差264.67mm、Thompson58.31mm；新候选两者aim均不足0.001mm。**挂点数值不等于静态手指形状或机械动作的艺术批准。**

| 家族 | 前后握持像素 | 实际近景动作循环 | 远景 LOD2 |
| --- | --- | --- | --- |
| pistol | [M1911](r4_evidence/m1911-grip-before-after.png)／[Luger](r4_evidence/luger-grip-before-after.png) | [M1911视频](r4_evidence/m1911-lod0-cycle.mp4) | [视频](r4_evidence/m1911-lod2-cycle.mp4) |
| rifle | [M1](r4_evidence/m1_garand-grip-before-after.png)／[Kar98k](r4_evidence/kar98k-grip-before-after.png) | [M1视频](r4_evidence/m1_garand-lod0-cycle.mp4) | [视频](r4_evidence/m1_garand-lod2-cycle.mp4) |
| smg | [Thompson](r4_evidence/thompson-grip-before-after.png)／[MP40](r4_evidence/mp40-grip-before-after.png) | [Thompson视频](r4_evidence/thompson-lod0-cycle.mp4)／[MP40](r4_evidence/mp40-lod0-cycle.mp4) | [视频](r4_evidence/thompson-lod2-cycle.mp4) |
| mg | [BAR](r4_evidence/bar-grip-before-after.png)／[MG42](r4_evidence/mg42-grip-before-after.png) | [BAR视频](r4_evidence/bar-lod0-cycle.mp4)／[MG42](r4_evidence/mg42-lod0-cycle.mp4) | [视频](r4_evidence/mg42-lod2-cycle.mp4) |
| scout | [Springfield](r4_evidence/springfield-grip-before-after.png)／[KarZF](r4_evidence/kar98k_zf-grip-before-after.png) | [Springfield视频](r4_evidence/springfield-lod0-cycle.mp4)／[KarZF](r4_evidence/kar98k_zf-lod0-cycle.mp4) | [视频](r4_evidence/springfield-lod2-cycle.mp4) |

视频是实际播放捕获的八间隔采样，按原动作时长布局并插入0.3s aim停留；30fps量化与末帧保持后总长2.167s。片段间终点重复帧省略，没有插值伪造动作，也不是实战视频。30张三角色握枪特写和十张换弹接触特写在本证据目录；1658原始PNG（含462回归与六源图）的 [hash索引](r4_evidence/capture-index.json) 指向独立交付目录 `/workspace/deliverables/actor-repair-20261002-r4/`。

Blender实际源材质／clay front/side/rear各一张：[十枪侧面](r4_evidence/guns_material_side.png)、[clay](r4_evidence/guns_clay_side.png)。源相机初轮裁掉外侧列，证据提交修正了取景并实际重渲染；最终六图覆盖十枪。[源报告](r4_evidence/source-firearms-report.json)中mesh validate无修正。

## 重建、回归与预算

[重复](r4_evidence/semantic-repeat.json)／[raw与仓库核对](r4_evidence/raw-repeat-tracked.json)：独立Blender4.3.2两次51 GLB、三贴图、两候选台账全部逐字节一致；51语义hash也相同。无Decimate，精度1e-6，8项语义 [反证](r4_evidence/semantic-falsification.json)通过。blend路径／元数据不宣称raw相同。

[变更分类](r4_evidence/change-classification.json)：21人物只增动画；20枪GLB增加marker，其中Thompson／BAR／MG42双LOD另补后握把。十工具GLB语义不变，六项只有exporter名序metadata变化，四项raw亦未变；没有yard再生成。静态枪的weights fingerprint含位置，其六项变化来自几何，不是人物权重重绘。

[完整二进制审计](r4_evidence/binary-slerp.json)：22/51、零违规，21 skins×52 clips×25=27300蒙皮样本，最低点-4.19mm（门槛-15mm）。审计按声明STEP及四元数SLERP采样，取代原归一线性近似；[五个已知角度／STEP断点检查](r4_evidence/animation-sampling-check.json)通过，依据 [Khronos插值定义](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#appendix-c-animation-sampler-interpolation-modes)。[90配置CPU接触](r4_evidence/firearm-binary-slerp.json)也零失败；raw glTF与Godot导入动画的键间最大值不同，接收以Godot实测为准，未声称逐key等价。

[回归报告](r4_evidence/engine-report.json)真实导入全部51与七人物各52动作，462截图零失败。日志HEAD是整理前未发布73251f6；[provenance](r4_evidence/provenance.json)已核对其fixture源码及全部GLB与194d9c4字节相同，73251f6不是额外交付提交。所有最终命令实际退出0，无mesh-invalid／Godot mesh warning；可选Draco缺失与虚拟显示VSync提示保留在日志。

人物预算8000/4000/1800不变，原人物三角数保持R3；枪3000/1500、工具2000/1000全部通过。新增后握把后Thompson1068/340、BAR1048/348、MG421596/576，每模型仍一个surface。旧16人物+16步枪fixture为66draw calls／71084 primitives；不代表真实场景FPS、动画资源内存或手机预算通过。

## A1.2剩余责任与运行入口

[机器责任表](acceptance_ownership.json)保存完整边界：

| 待验项目 | 负责者 |
| --- | --- |
| 审查台账／材质分流，按历史枪ID选clip，四敌人行为映射 | PR15主作者 `01a0fcab-4daa-716b-8d26-e998edbb30bd` |
| 装备事件、快速连发、中途取消／换枪、行走上身mask与过渡 | 主作者运行时接入；dot提供资产缺陷修复 |
| 刀刺、投雷、诱饵专用放置、尸体拖拽、死亡接触品质 | dot后续资产切片；当前haul仍弹药包carry |
| 静态闭手、近脸／服装、十枪历史轮廓与机械准确性 | dot资产制作，父任务／主作者最终艺术评审 |
| 六关暮色遮挡／身份／枪口VFX，LOD切换，完整回放pause/2x，场景与动画内存预算 | 主作者与父任务云端验收 |
| 手机30/60FPS、压缩、热／触控 | 父任务在完整制作接入后安排设备验证，当前按用户指令暂缓 |
| A1.2最终闭合 | 父任务汇总主作者集成与dot证据；本包不能独立标全通过 |

从仓库根运行独立检查：

```bash
blender -b --python-exit-code 1 --python ambush_loop/ArtSource/v2/build_actors.py -- --output-root /tmp/actors-a
python3 -m ambush_loop.ArtSource.v2.actor_acceptance.validate_firearms --project /tmp/actors-a --profiles /tmp/actors-a/firearm_profiles_candidate.json --output /tmp/firearms.json
DISPLAY=:97 bash ambush_loop/ArtSource/v2/actor_acceptance/run_review.sh /path/to/Godot_4.7.2 /tmp/firearm-review ambush_loop/ArtSource/v2/actor_acceptance/catalog_candidate.json "$PWD/ambush_loop" "$PWD/ambush_loop/ArtSource/v2/actor_acceptance/firearm_review.gd"
```

需要独立显示与隔离fixture；不运行旧build_yard_kit.py。外部GPT PLAN/REVIEW unavailable；无艺术approve。**实际运行时样本review通过仍不是完整实战通过。**
