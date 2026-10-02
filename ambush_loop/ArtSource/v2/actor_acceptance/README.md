# A1.2 独立资产候选 R5：工具动作与成对拖拽 — 2026-10-02

刀刺、投雷、诱饵放置和尸体抓取/拖拽/放下的源动作与交互合同已提供。**只作为可审查的资产候选；实际事件时钟、遮罩、取消与六关实战由主作者验收。** 本片没有继续雕改近脸、手指或武器机械。

## 范围、接口与实际能力

基线 R4 `c4c21708a2e06d3a7eaefbb8ab6bfeee31f5073d`，历史报告见 [R4](R4_README.md)。独立分支 `fix/asset-actors-dot-20261002`、工作区 `/workspace/ambush-actors-dot`。只提交自己的生成器/源blend/验收目录与21个人物GLB；30装备GLB、三actor atlas及42共享保护路径逐字节保留。未改共享manifest/runtime、未推送PR15、未merge/deploy/device。

原20骨、rest/inverse binds、旧52动作名字/时长/key语义、全部现有socket兼容。1m cell、+Y up、-Z forward、ground origin、WorldSpace一次转换不变。新增12可选动作，所有七人物/三LOD各64动作；不要修改旧haul的弹药包carry含义。

| 动作 | 时长 | 合同与关键事件 |
| --- | --- | --- |
| utility_ready | 2.4s loop | 空手工具就绪基姿；实际工具动作时主作者隐藏/收起枪械visual，不改装备或背包逻辑 |
| knife_stab | .8s | 单次前刺；.40–.60命中姿态窗口；读既有knife__socket_tip；不是割喉专用编排 |
| grenade_throw | 1s | 抬臂、向前释放、回位；release=.5；读实际grip世界变换；示例释放后隐藏工具，没有伪造飞行/爆炸 |
| decoy_place | 1.2s | 下蹲伸手放置；.40–.60握把在地面高度，release=.5；实例保留释放位置 |
| corpse_grab / corpse_release | 1s / .7s | 角色从ready到拖拽持姿、再放下；body配合lift/lower |
| corpse_drag | 1.2s loop | 双手向后、原地拖拽步态；角色world travel仍来自历史位置 |
| corpse_prone / corpse_dragged | 1.2s loop | 俯卧/倾斜持尸静态候选；共用20骨 |
| corpse_lift / corpse_lower | 1s / .7s | 独立body起落；prone↔dragged端点合同 |
| death_prone | 1.2s | 俯卧落地并保持；源码逐帧按真实蒙皮最低点抬升，不是ragdoll |

[动作/挂点合同](utility_profiles_candidate.json)、[只读实际代码能力](utility_runtime_contract_candidate.json)包含来源hash、相位、门槛与集成责任。工具仍挂hand.R `(0,.035,0)` / X+90°，扣除**实际旧grip节点**；没有移动任何旧socket。尸体新增marker是现有upper_arm.L/R骨上原点的BoneAttachment定义，不加骨、不替换已有挂点。持尸对齐两肩marker中点与现有左右掌中点，保留共同facing；身体姿态根骨不动。新的prone/lift/lower/death内部已有20cm局部后移，避免头部贴入抓取者靴子，**不要再加runtime20cm修正**。

冻结实际代码和新姿态有明确边界：刀melee会即时发fired_shot，岗哨knife技能直接knock_out；手雷即时创建、初次飞行.18s后有弹跳；诱饵即时在目标点出现且没有投掷飞行；拖尸跟随LootPickup，偏移是屏幕轴(0,14)，没有完整身体ID/姿态/朝向记录。冻结view_state.events为空。新1s投雷的.5s预备动作不能阻塞模拟，远点诱饵不能新增靠近/伸手距离规则，也不能从当前活体对象补造回放历史。

## 固定源与最终真实证据

**被测资产/生成器/utility Godot fixture：`29749157c5db064bfea626c3ed9d75d9a1791ece`**。报告提交只增加证据、独立可复核脚本和说明，不更改这51 GLB、blend、profile或播放fixture。

[Godot动作报告](r5_evidence/utility-report.json)/[日志](r5_evidence/utility.log)：4.7.2 Compatibility、Mesa llvmpipe，实际AnimationPlayer.advance25相位，**108动作配置、63成对拖拽配置、72全20骨端点、9项2倍速/暂停、226截图，零失败**。动作配置为12clips×3roles×3LODs；成对配置为7body×3roles×3LODs。四azimuth的LOD0/2、地面侧视和手部近景均保留；LOD1有数值验收。

工具握把最大误差0.000274mm，双肩0.285mm，诱饵落地0.467mm，刀尖前伸至少330mm，投雷准备至释放至少614mm。持尸最低点-1.740mm；导入蒙皮522项地面检查最低点-11.166mm，均高于声明-15mm门槛，**没有声称绝对零地面穿入或自然手指抓握**。端点最大0.700mm（death导入门槛1mm），其余门槛0.1mm；暂停/2x误差0。

[完整Godot回归](r5_evidence/engine-report.json)/[日志](r5_evidence/regression.log)：全部22资产/51LOD真实导入，七人物/三LOD/64动作按规范相位检查，462原12动作回归截图，零失败。[原始GLB审计](r5_evidence/binary.json)22/51零违规；[工具/63成对/72端点审计](r5_evidence/utility-binary.json)零失败。最终命令实际退出0，无mesh-invalid/Godot mesh warning；日志的虚拟VSync和可选Draco缺失保留。

[源clay侧面](r5_evidence/utility_source_clay_side.png)/[源材质侧面](r5_evidence/utility_source_material_side.png)，front/side/rear共六张实际Blender源图。8-sample CPU用于接触/形状检查，有噪点，不是成品艺术批准。

| 动作 | 实际LOD0像素 | LOD0动态 | LOD2动态 |
| --- | --- | --- | --- |
| 刀刺 | [手部](r5_evidence/knife_stab_operator_rifle_contact_close.png) | [视频](r5_evidence/knife_stab-lod0.mp4) | [视频](r5_evidence/knife_stab-lod2.mp4) |
| 投雷 | [释放点](r5_evidence/grenade_throw_operator_scout_contact_close.png) | [视频](r5_evidence/grenade_throw-lod0.mp4) | [视频](r5_evidence/grenade_throw-lod2.mp4) |
| 诱饵 | [地面/握把](r5_evidence/decoy_place_operator_rifle_contact_close.png) | [视频](r5_evidence/decoy_place-lod0.mp4) | [视频](r5_evidence/decoy_place-lod2.mp4) |
| 抓尸 | [清开靴子的首帧](r5_evidence/corpse_grab_lod0_00.png) | [视频](r5_evidence/corpse_grab-lod0.mp4) | [视频](r5_evidence/corpse_grab-lod2.mp4) |
| 拖拽 | [地面侧视](r5_evidence/pair_enemy_patrol_ground_side90.png)/[双肩](r5_evidence/pair_enemy_patrol_contact_close.png) | [视频](r5_evidence/corpse_drag-lod0.mp4) | [视频](r5_evidence/corpse_drag-lod2.mp4) |
| 放下 | [末帧](r5_evidence/corpse_release_lod0_08.png) | [视频](r5_evidence/corpse_release-lod0.mp4) | [视频](r5_evidence/corpse_release-lod2.mp4) |
| 俯卧死亡 | [末帧](r5_evidence/death_prone_lod0_08.png) | [视频](r5_evidence/death_prone-lod0.mp4) | [视频](r5_evidence/death_prone-lod2.mp4) |

14视频均来自实际九相位截图，按原时长做稀疏pose保持，末帧30fps保持，编码帧数/时长见[videos.json](r5_evidence/videos.json)。不是插值生成或实战录像；688原始Godot PNG的[hash索引](r5_evidence/capture-index.json)指向`/workspace/deliverables/actor-repair-20261002-r5`。

## 验收与可复现边界

数值以最终真实Godot报告为准：手握实际工具GLB节点，尸体肩marker是实际BoneAttachment，地面测试取导入Skin bind/weights与当前骨矩阵。手持工具的无骨mesh另按实际全局变换计算；不把null Skin当成功。静态held-body每相位读取实际平移，复用其已验证固定蒙皮地面值。

原始GLB审计使用既有SLERP/STEP采样；全21 skins×64动作×25相位=33600蒙皮样本。LOD人物8000/4000/1800、枪3000/1500、工具2000/1000、每mesh一个surface全部保留。新增12动作使总GLB由28,033,880到32,944,492字节（最终预算报告记录实际值）；这不是导入动画内存或设备FPS预算通过。

端点一般门槛0.1mm；Godot导入后的death终止姿态与prone起姿存在约0.7mm平移误差（[独立复核](r5_evidence/endpoint-probe.log)），预先记录1mm门槛，原始GLB端点仍按0.1mm检查；不宣称raw glTF和导入后的全部键间值相同。夹持/身体地面分别按0.1mm/15mm，双肩接触15mm；静态闭手的视觉品质另列限制。

独立重建两次51 GLB/三贴图/三个候选台账逐字节一致，blend保存路径元数据不宣称raw一致。[旧52兼容](r5_evidence/old52-compatibility.json)、[变更分类](r5_evidence/change-classification.json)、[预算](r5_evidence/resource-budget.json)、[保护路径](r5_evidence/protected-paths.json)可复核。所有人物几何/法线/UV/权重/材质/rest没有变更，装备没有重生成差异。

首轮被拒绝的缺陷是诱饵约41mm悬空、持尸肩错位/压地、grab端点脱节、death中途穿地，以及源像素发现的头/靴重叠；已修正并重建。fixture初轮误把挂载工具mesh当skin，显式advance也不能用于模拟暂停；这些诊断输出不作为通过证据。实际pause检查是暂停后跨场景帧保持姿态。外部GPT PLAN/REVIEW unavailable；无艺术approve。

## 剩余责任

[完整机器责任表](acceptance_ownership.json)。主作者负责审查候选台账/材质与历史事件接入、上身遮罩、连发/中途取消/换枪、实际body拾取/释放碰撞与路线、LOD切换、六关暮色/身份/枪口VFX/完整回放与场景/动画内存。dot保留资产缺陷修复责任及近脸/静态手指/历史枪形与机械、手雷stiel/mills/mk2型号的质量缺项。无机械reload仍是R4明确限制。父任务组织艺术评审、最终A1.2汇总和生产接入后的设备阶段；当前按用户指令没有模拟器/真机。

## 重现

```bash
blender -b --python-exit-code 1 --python ambush_loop/ArtSource/v2/build_actors.py -- --output-root /tmp/actors-r5-a
python3 -m ambush_loop.ArtSource.v2.actor_acceptance.validate_utilities --project /tmp/actors-r5-a --profiles /tmp/actors-r5-a/utility_profiles_candidate.json --catalog /tmp/actors-r5-a/catalog_candidate.json --output /tmp/utility.json
DISPLAY=:97 bash ambush_loop/ArtSource/v2/actor_acceptance/run_review.sh /path/to/Godot_4.7.2 /tmp/utility-review ambush_loop/ArtSource/v2/actor_acceptance/catalog_candidate.json "$PWD/ambush_loop" "$PWD/ambush_loop/ArtSource/v2/actor_acceptance/utility_review.gd"
```

需要独立显示；fixture隔离user数据，不运行共享玩法，不运行build_yard_kit.py。动画/交互样本通过不能代替实战/A1.2完整验收。
