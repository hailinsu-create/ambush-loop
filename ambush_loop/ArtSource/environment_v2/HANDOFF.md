# PR15 独立环境候选交接

候选资产制作及独立云验证完成，可交主作者逐件采用。固定基线：`744cb01439bd98d69e816d39d2584067f49043b0`。自有分支：`feat/environment-dot-candidate-20261002`。资产代码及输出的固定提交：`50ef7883285c4419dbd8339b935433dc6bb5e3f8`；后续证据提交只增加本报告、哈希清单和证据，不改变该提交的模型、纹理或材质。

唯一主集成作者：`01a0fcab-4daa-716b-8d26-e998edbb30bd`。父任务：`01a0efe8-604e-7249-8093-d7921d952020`。本工作者只拥有 `ambush_loop/ArtSource/environment_v2/` 与 `ambush_loop/art/environment_v2/`。没有编辑共享 runtime、manifest、project、主测试、旧 yard kit、角色、武器、audio 或共享 atlas；没有推送 PR15、合并或部署。

## 精确采用范围

40 件原创新资产，80 个 LOD0/1 GLB，3 张独立 1024² PBR atlas，2 个可共享 `.tres` 材质。最小运行候选是 **85 个文件**，路径、字节数和 SHA-256 逐件列于 [adoption_files.json](../../art/environment_v2/evidence/adoption_files.json)。源台账 [catalog_candidate.json](catalog_candidate.json)、[placement_semantics_candidate.json](placement_semantics_candidate.json) 及 [exports.json](../../art/environment_v2/exports.json) 另列为元数据候选；它们不是共享 manifest。`sample/` 与 `evidence/` 仅用于审查，不要整体纳入玩家导出。

4 件已有基准资产按原字节复用：`oil_drum`、`sandbag_stack`、`field_radio`、`yard_lamp` 的 8 个 GLB 与 3 张 yard atlas。依赖真实 SHA 在采用清单及源台账中；没有在候选目录暗中复制或修改旧包。全部新几何、UV 与纹理字段为本任务原创程序源，供 Ambush Loop 项目及协作者使用，无外部模型、纹理、字体、品牌、付费服务或凭据；未另行声称公共开源许可。

原 14 类核对如下；9 个旧 sample 不能替代此表：

| 原类别 | 候选 asset_id | 来源 |
| --- | --- | --- |
| ammo_can | env_ammo_can | 新制，独立箱盖、loot_anchor |
| barbed_wire | env_barbed_wire | 新制；旧源 GLB 未有运行 PNG 引用 |
| fence_section | env_fence_section | 新制 |
| field_radio | field_radio | 原字节复用 |
| gun_case | env_gun_case | 新制空箱、独立箱盖；不含 R2 枪械 |
| handcart | env_handcart | 新制，cargo_anchor |
| jerry_can | env_jerry_can | 新制 |
| lamp_post | yard_lamp | 原字节复用 |
| oil_drum | oil_drum | 原字节复用 |
| rations_crate | env_rations_crate | 新制，独立箱盖、loot_anchor |
| sandbag | sandbag_stack | 原字节复用 |
| spare_tire | env_spare_tire | 新制 |
| wooden_barrel | env_wooden_barrel | 新制 |
| yard_crate | env_yard_crate | 新制，独立箱盖、loot_anchor |

可复用建筑包括砖/抹灰内外墙、转角、窗、独立门框/lintel 与门叶、装卸门框与滑门叶、可拆双坡/平屋顶、矮墙与栅门。地面包括混凝土、泥土、石铺装、钢板、碎石以及排水、路缘和接缝杂物。完整仓库壳为 6×4m，含四面墙、山墙、内部和真实装卸门孔，屋顶另件。其余主题通过独立地标、地面和围墙组合区分：

| 主题 | 主地标 | 候选范围 |
| --- | --- | --- |
| yard | 完整仓库壳 + 独立屋顶/双滑门 | 院子、14 类用途展示、混凝土/泥土与围墙 |
| warehouse | env_warehouse_gantry | 棚架、装卸构件、混凝土/钢板 |
| pump | env_pump_skid | 泵/电机/压力罐、管道与维护挂点 |
| railcut | env_signal_mast | 信号桅杆、轨道、碎石压床 |
| depot | env_depot_tank_pair | 双罐、罐背结构、混凝土/泥土 |
| radio | env_radio_antenna | 天线/碟背支架/Yagi/柜体、钢板地面 |

六套 `themes` 是 **12×12m 独立资产展场**，有完整摆放候选；未替换六关 40×22m 逻辑地图，不能称六关实战接入完成。

## 导出、材质与交互契约

复跑命令和工具版本见 [README.md](README.md)。本次使用现有 Blender 4.3.2、Python 3.12、Pillow 12.3.0、Godot 4.7.2 `ed1daf0bf`、Mesa llvmpipe Compatibility、ffmpeg；没有安装未知工具。源为可执行制作脚本，不以不可追溯的手工导出替代源。源及候选输出分别有 [SOURCE_SHA256SUMS](SOURCE_SHA256SUMS) 与 [GENERATED_SHA256SUMS](../../art/environment_v2/GENERATED_SHA256SUMS)。

1 格=1m，+Yup/-Zforward。每件台账列出尺寸、原点、LOD 三角面/surface/SHA、来源、材质槽、活动节点及真实 socket 的本地位置、旋转、父节点。根在地面中心，地表顶面 Y=0；屋顶保留组装高度，实例 Y 应为 0。所有模型 `visual_only`，没有物理/导航/LOS/高度收益；AABB 不决定逻辑占格。

新材质使用 `environment_v2_atlas` 与独立 `environment_v2_emission`；albedo=sRGB，无方向光烘焙；normal=OpenGL +Y 线性；ORM R=1、G=roughness、B=metallic。GLB 不重复内嵌贴图。旧 GLB 在 Godot 导入后材质槽为空，样本按冻结 surface 顺序绑定旧 atlas，旧灯 surface1 使用发光。主作者须明确处理旧包材质槽及新命名空间；本任务没有改共享 loader。

4 类箱盖具有独立 `__lid_pivot`，局部 X 旋转至 100/105°，有真实空心内腔。门/栅门的独立 `__leaf_pivot` 沿局部 Y 旋转，滑门沿局部 X 平移；lintel 不随门叶活动。门柄 socket 真实挂在活动 pivot 下，随叶运动，台账同时列父节点本地坐标及闭合态位置。GLB 没有 skeleton 或动画 clip，样本用这些真实节点示范动作；游戏命令/拾取事件未接入。地面、轨道、排水、门叶对齐及 LOD 策略见 placement 台账，均为主作者采用候选。

## 实际云验证证据

结构及复现：两次独立 Blender 进程的 **80 个 GLB、3 张 PNG、exports.json 全部逐字节一致**；2 个 `.tres` 另由两次实际 Godot ResourceSaver 导出、规范化外部引用标签后逐字节一致。源生成器 SHA 与 exports/catalog 一致。结构验证退出码 0，**1582 检查通过**；[structure_report.json](../../art/environment_v2/evidence/structure_report.json) 和 [reproducibility.json](../../art/environment_v2/evidence/reproducibility.json) 留存实际结果。

最终 Godot 4.7.2 真实导入退出码 0；最终 headless 实例验证退出码 0，**546 检查、0 issue**，覆盖新/复用 88 个 LOD 场景、实际面数/surface/尺寸、材质、socket/活动父节点、无碰撞及保存材质资源。见 [godot_headless_report.json](../../art/environment_v2/evidence/godot_headless_report.json) 与日志。图形实际捕获、Blender 源渲染、预算探针均退出码 0；完整执行清单见 [validation_receipt.json](../../art/environment_v2/evidence/validation_receipt.json)。早期两次中断日志明确标为 interrupted，不计通过。

实际 Godot framebuffer 保留 3519 个独立帧的哈希账本；44 个新/复用资产覆盖中性/暮色、8 yaw、35°/65°、近 LOD0/远 LOD1、clay，六主题覆盖相同方向及去屋顶图。最终采用像素由一次全量捕获及两次受影响范围重捕合成：最后石铺颜色修改重捕石铺/六主题/手机；最后 socket 父节点修改重捕动作/手机。静态几何材质未变的图保留，**不声称全部像素在最后提交之后重新捕获**。生成器与 runner 的每次 SHA、原脚本快照和退出码见 [capture_runs.json](../../art/environment_v2/evidence/capture_runs.json)。精选图已实际打开看像素，截图成功本身不作美术通过依据。

- [近/远像素矩阵](../../art/environment_v2/evidence/pixel_matrix_lod0_01.png)：各 LOD 各 11 页，覆盖全部 44 件；[远 LOD1 示例](../../art/environment_v2/evidence/pixel_matrix_lod1_07.png)。
- [六主题暮色](../../art/environment_v2/evidence/themes_dusk.png)、[中性](../../art/environment_v2/evidence/themes_neutral.png)、[去屋顶](../../art/environment_v2/evidence/themes_roof_removed.png)、[院子360°](../../art/environment_v2/evidence/yard_360.png)。
- [原生 800×450 手机尺寸 framebuffer](../../art/environment_v2/evidence/phone_yard_800x450.png)，不是桌面截图缩放；[Blender 源/灰模](../../art/environment_v2/evidence/blender_source_review.png)。
- [实际 Godot 节点动作 MP4](../../art/environment_v2/evidence/display_motion.mp4)：6 秒，1280×720，30fps；[动作关键帧](../../art/environment_v2/evidence/motion_keyframes.png) 含随门叶运动的金色 socket 标记。

## 预算及像素判断

80 个新 GLB 共 3,265,608 bytes，40 件 LOD0 合计 33,804 三角面。普通道具最高 1,948 面且最多 2surface；地标最高泵组 3,924 面。仓库壳 6surface 为四面墙/lintel/内部显示分组，棚架 2surface 为屋顶/棚架分离；简单墙和地表无需填无效三角面。新 3 张 atlas 含 mipmap 的未压缩估算 16,777,216 bytes。

独立展场在云 llvmpipe 下实际渲染探针如下；每场 55°、yaw35°，LOD0 span14m/LOD1 span20m。纹理计数各场 33,004,477 bytes，包含新/旧 atlas；不是安卓驻留或帧率测量。

| 展场 | LOD0 draw / primitives | LOD1 draw / primitives |
| --- | --- | --- |
| yard | 134 / 29292 | 134 / 13001 |
| warehouse | 104 / 15550 | 104 / 6919 |
| pump | 102 / 20376 | 102 / 10674 |
| railcut | 102 / 11946 | 102 / 5562 |
| depot | 96 / 10388 | 96 / 5742 |
| radio | 100 / 14754 | 100 / 7436 |

看像素后修正了过强金属/涂漆斑纹、实心弹药箱、仓库缺山墙、木桶散开木板/被埋箍、碎石格子感、石铺横向色带及门柄 socket 不随门叶移动；最终近远图能辨认仓库四面与出口、木桶箍、车轮、泵组、罐群和天线背面。冷灰/局部暖灯方向已建立，当前是可审候选，未取得整场写实美术最终接受。

仍须主集成作者处理的已观察限制：35° 某些展场方向的门框会挡泵组、平屋顶/墙会挡天线底座；运行遮挡/切屋顶尚未接入。手机尺寸下主要建筑与大件轮廓可读，微小弹药/电台交互细节需实际关卡的缩放/选择提示；远处铁丝与排水格栅很细，不能直接作为点选目标。4 件复用旧物尤其油桶/电台仍有旧 atlas 的较强斑纹，与新物材质存在差异；共享 atlas 未改，主作者决定统一美术方式。

## 未验项与采用责任

候选目录内制作/独立验证没有未解决阻塞。主作者后续负责逐件采用、asset→既有逻辑 ID、六关摆放/占格/碰撞分离、共享 manifest/loader、材质绑定、灯光预算、遮挡、运行 LOD、箱盖/门叶/loot 动作命令及导出包含。尚未验证主战场 SCOUT→ALERT→SWEEP、回放/重试、六关行为不变量、完整游戏性能或可追溯 APK；本包没有模拟器/真机测试，也不以资产验证等同六关实战、美术或手机性能通过。按用户顺序继续制作与主集成，设备讨论留在整体计划完成后。
