# 独立环境资产候选

固定基线 `744cb01439bd98d69e816d39d2584067f49043b0`；候选分支 `feat/environment-dot-candidate-20261002`。所有新增文件局限于本目录和 `art/environment_v2/`。主集成作者负责逐件采用及共享runtime/manifest接入。本包没有修改玩家工程设置、玩法、角色、武器、音频、共享atlas或旧yard kit。

40件原创候选 / 80个独立LOD：10类原道具缺口、12个通用建筑部件、8个地表/接缝部件、完整仓库壳与独立屋顶、5个主题地标、管道/轨道/壁灯。原14类逐行映射见 [catalog_candidate.json](catalog_candidate.json)：油桶、沙袋、电台、灯柱复用4件基准，不生产R2枪械或手持工具。旧barbed_wire有源GLB，但无旧运行PNG引用，不能把它说成既有可交互对象。

几何、纹理均由本任务原创程序生成，无外部模型、纹理、字体、品牌、付费服务或用户凭据。使用条件：为Ambush Loop项目及其协作者使用；不额外声称本仓库未给出的公共开源许可。复用旧件沿用项目现有使用条件；其源/GLB/纹理路径和真实SHA明确列出，不暗中修改或复制旧输出。

## 可复现命令

在仓库根目录使用 Blender **4.3.2**、Python **3.12**、Pillow **12.3.0**（实际版本见证据）、Godot **4.7.2.stable.official.ed1daf0bf**。只使用现有工具，无安装动作。

```bash
blender -b -t 2 --python ambush_loop/ArtSource/environment_v2/build_environment.py
python3 ambush_loop/ArtSource/environment_v2/build_catalog.py
blender -b -t 2 --python ambush_loop/ArtSource/environment_v2/build_environment.py -- --output /tmp/environment-v2-export-b
python3 ambush_loop/ArtSource/environment_v2/validate_exports.py --compare /tmp/environment-v2-export-b
python3 ambush_loop/ArtSource/environment_v2/prepare_review.py /tmp/environment-v2-review
/path/to/Godot-4.7.2 --headless --editor --path /tmp/environment-v2-review --import
/path/to/Godot-4.7.2 --headless --path /tmp/environment-v2-review --script res://art/environment_v2/sample/export_materials.gd
ENV_REVIEW_OUTPUT=/tmp/environment-v2-frames /path/to/Godot-4.7.2 --display-driver x11 --rendering-method gl_compatibility --audio-driver Dummy --path /tmp/environment-v2-review -- --capture
blender -b -t 2 --python ambush_loop/ArtSource/environment_v2/render_blender_review.py
python3 ambush_loop/ArtSource/environment_v2/assemble_evidence.py /tmp/environment-v2-frames
python3 ambush_loop/ArtSource/environment_v2/inspect_matrix.py /tmp/environment-v2-frames
ffmpeg -framerate 30 -i /tmp/environment-v2-frames/motion_%03d.png -c:v libx264 -pix_fmt yuv420p ambush_loop/art/environment_v2/evidence/display_motion.mp4
```

图形捕获需可用X11/Mesa；本云环境已有dummy Xorg配置和软件llvmpipe。启动说明只记录本次实际依赖，不代表其他环境已准备。复制器只将候选及明确的旧件依赖复制到临时工程；无游戏autoload、存档或主测试调用。源码脚本是唯一制作依据，编辑mesh可先在Blender运行生成器后保存独立blend，但手工源若采用必须由主作者另存并登记来源。源脚本哈希与两次独立输出字节校验见证据。

## 采用契约

- **坐标**：1格=1m，+Yup/-Zforward。根在地面中心；地表顶面Y=0。屋顶保留组装高度，不能再把实例Y设为3，否则会重复抬高。
- **材质**：新GLB保留具名PBR槽 `environment_v2_atlas`，灯单列 `environment_v2_emission`。三张独立1024²贴图和2个`.tres`候选材质只通过材质绑定一次共享，没有嵌入每个GLB。ORM R=1（无烘焙AO）、G=roughness、B=metallic；法线OpenGL +Y、线性；albedo为sRGB，不含方向照明。使用mipmap/linear filter。示例在 `art/environment_v2/sample/review.gd`，共享loader不支持新命名空间，须由主作者接入。
- **旧件注意**：冻结基准导出仅含placeholder名称，Godot实例的材质资源为空。样本按已审计的surface顺序给旧灯surface1应用发光，其他旧surface应用yard atlas；主作者采用时也要处理这个旧包问题。本任务不修共享loader。
- **活动节点**：箱盖节点 `env_<class>__lid_pivot`，局部X轴0→100/105°；门/栅门 `__leaf_pivot`，局部Y轴旋转；装卸门叶同名pivot沿局部X平移。每个节点、轴、初始局部变换及范围都在台账。门框的lintel与门叶属于不同显示分组/GLB；不要把lintel作为门叶一起旋转。
- **挂点**：`__socket_<name>` 是真实导出Node3D，台账为明确`parent_node`下的本地Godot轴位置/旋转，并给出`asset_closed_position_m`闭合态参考。门/栅门/滑门的handle_anchor真实挂在活动pivot下，随门叶运动。对齐门叶的hinge节点到门框socket，不要把门叶根直接放在hinge坐标。loot/handle/cargo/maintenance/warm_light的语义明确；复用旧件挂点仅在原台账中，无实际导出socket节点，不伪造其存在。
- **逻辑分离**：所有模型`visual_only`，无CollisionObject3D、导航或高度收益。参考尺寸不等于逻辑占格；禁止从AABB自动生成阻挡或LOS。门叶展示不自行改变泵站门路线，箱盖展示不自行触发拾取。ground/decoration/cover/loot/door均需由主作者映射已有逻辑ID。
- **组合**：逐件placement语义在`placement_semantics_candidate.json`：铁路压床顶面为Y=0，轨头/路缘为视觉抬高；排水格栅建议搭配显示地表开口，不能据此改变可走格。六套themes是12×12m资产展场，非40×22关卡摆放图。每关有不同地标和地表/围墙组合；不要将这些展场直接替换原关卡或称为六关接入。
- **LOD**：每件LOD0/1独立GLB，保留root、pivot和socket名称。草案建议camera span>24m用LOD1、<20m用LOD0，2m迟滞；尚未写入共享运行，主作者依据实际视距统一安排。小地面LOD可相同，避免为“降面率”破坏平面。

预算是工程候选门槛：普通道具≤2000面且≤2surface，建筑/地标≤5000面。仓库壳6surface服务四面墙、lintel和内部单独显示；棚架2surface分离屋顶。简单墙和地面低于建议面数下界，无必要补无效几何。三张atlas含mipmap未压缩估算16MiB；这是资产估算，不是手机驻留实测。

查看 [交接报告](HANDOFF.md) 获取固定提交、精选实际像素、源/输出SHA、实际退出码、已发现缺陷和未验项。样本资源检查、六关实战、整场美术与手机性能分别验收；本包不声称后面三项通过。
