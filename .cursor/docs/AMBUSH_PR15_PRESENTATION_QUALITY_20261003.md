# PR15 depot目标遮挡与radio天线整隐

2026-10-03，R03限定作者修复。继承[v2执行顺序](AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md)，保留SCOUT→ALERT→SWEEP和六关13波原数值、路线、占格。固定负向源码 `c00ddef85377b5baed302f0c53c61344b859eb27`；固定修复/正式测试源码 `4741c5f020965f9a4315fa8993da20474efc04f0`。父端已独立关闭具体depot遮挡及新schema1 radio整隐，完整HUD品质未称完成。

## 实际复现与修复

实际depot原第一波终局SWEEP566：reference装备[1,4,5]、朝向[270,270,180]、原绊线(7,11)，镜头focus零/yaw270/pitch35/size24。队员1的身体投影(684.9999,449.7303)和脚部(684.9999,468.1612)被重复C2肖像条覆盖；原生队列鼠标点击选中错误队员。其余两名原目标正常。修复让3D桌面保留左侧原角色卡，关闭重复的中央肖像条；手机原肖像和旧2D桌面仍保留。三名真实目标身体/脚部无UI阻挡、picking身份正确、原生点击选择正确队员。

实际radio原SCOUT：reference装备[1,4,5]、朝向[270,90,270]，focus零，yaw330/345/0×pitch35/55×size14/24/30共18姿态。旧天线单一网格的巨大AABB包含内部空隙；其遮挡判定在330/345的12姿态把整个天线藏掉。固定负向69项14失败、实际exit1：depot两项和radio十二项，日志/图像完整保留。

修复仅在显示层按已制作的断连实体拆分天线，LOD0为55部件、LOD1为42部件，逐实体使用自己的cutaway包围盒。十八姿态均保留天线可见几何；330/55°时只隐藏实际遮挡的2部件，345°近远图已实际查看。两档全部三角形、顶点、法线、UV、切线逐值一致，所有部件仍引用原atlas材质；GLB/atlas/生成源没有修改。独立原grid、Nav/LOS与墙接触canonical LOD0 bounds保持。

直接从解码数组重建ArrayMesh曾使法线/切线重新量化，开发期95项2失败；不能放宽断言算通过。最终复制原packed position/normal/attribute块并仅重映射索引，保留原压缩AABB/UV scale作为解码基准，另用实体bounds做cutaway/GPU culling。使用固定Godot4.7.2的ArrayMesh序列化surface接口；引擎升级时须回归该接口。缓冲布局依据[Godot RenderingServer文档](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html)和[ArrayMesh原实现](https://github.com/godotengine/godot/blob/master/scene/resources/mesh.cpp)，实际兼容性由固定引擎测试证明。

可选历史字段 `environment_cutaway_schema=1` 选择本算法；presenter把该字段纳入布局身份。缺失/未知版本保持原未拆网格和旧cutaway行为，不能称旧记录的整隐也已修复。历史只使用复制的layout/door/actor数据，forward/backward seek恢复相同显示，污染live grid/level/actor不影响历史；兼容回退不修改记录。UI布局使用当前客户端，历史卡片原生点击仍只读。

## 固定源码正式验证

每run有独立UUID/XDG与StorageGuard；实际命令、源码SHA、退出码、原日志和哈希见[validation.json](evidence/20261003-pr15-presentation-quality/validation.json)。以下从仓库根运行；渲染使用Compatibility/Mesa llvmpipe云软件环境，不是手机性能证明。

| 包装器实际命令 | 实际结果 | 主要范围 |
| --- | --- | --- |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/bin/godot-capture presentation_quality_test.gd --render` | 106/0，exit0 | depot原目标/原生点击、radio18姿态/两LOD逐三角形属性和材质、live污染历史/seek、缺失/未知版、桌面/手机/1280及请求1600（实际viewport仍1280，真1600未验）、历史卡片只读；四张图 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/bin/godot-capture visual_snapshot_test.gd --render` | 164/0，exit0 | 历史HUD、手机时间轴、旧/未知记录及只读 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/bin/godot-capture presentation_lifecycle_test.gd --render` | 32/0，exit0 | 原生I/Escape/Back、触控取消/额外手指隔离/下一独立点击、后台/菜单/重置、ALERT及REPLAY拒绝、3D事件聚焦 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 camera_input_test.gd` | 23/0，exit0 | UI接触归属、取消、后台丢release、双指与恢复 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 presentation_contract_test.gd` | 84042/0，exit0 | 原坐标/姿态/picking/战斗合同 |
| `AMBUSH_CONTACT_SCOPE=qa_exact bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/bin/godot-capture corpse_contact_test.gd --render` | 25/0，exit0 | 原native MG/source敌人#3/两波/Space-H抓放再抓/97步鼠标路径、原facing及wall skin0 |
| `AMBUSH_CORPSE_CONTACT_SCOPE=qa_exact bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/bin/godot-capture corpse_contact_test.gd --render` | 576/0，exit0 | 此变量不被脚本识别，实际运行默认Scout完整72配置/contact/history；不是MG精确复现，保留原命令而不改写成正确变量 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 campaign_replay_test.gd` | 10332/0，exit0 | 六关13波30/60/2x与原终局，不是正常玩家全旅程 |

四张正式帧已实际查看：[depot SWEEP低角](evidence/20261003-pr15-presentation-quality/quality_depot_sweep_low.png)、[radio345°近景](evidence/20261003-pr15-presentation-quality/quality_radio_yaw345_pitch35_size14.png)、[radio345°远景](evidence/20261003-pr15-presentation-quality/quality_radio_yaw345_pitch55_size30.png)、[污染live后的历史radio](evidence/20261003-pr15-presentation-quality/quality_radio_history.png)。保留负向69/14原日志/三张图及开发parse、错误中段插入、属性重编码/stride失败；开发run均排除固定源验收。

## 剩余品质与执行顺序

父端已独立支持关闭具体depot重复肖像挡目标和新schema1的radio整隐；其余完整HUD品质仍待。SCOUT顶部标题/路线/选中提示仍拥挤；未穷举全部六关旋转角/镜头焦点/长文本/机型UI，也不是完整HUD成品。部件数增加是A3合批/缓存/资源计数输入，当前未量出设备30/60FPS；不能为了计数再次藏掉整个地标。

父端2026-10-03消息报告68582的R02原穿墙P2独立闭合：原native MG同序401实际wall skin→0，32/0及全新portable目录再32/0，MG72配置/16H端点及history387/0、四合法corner48sample133/0（位置fixture），默认576/原尸体1203/合同84042/工具1041/冻结66/旧2D/六关10332均exit0，无新P1/P2。此为父端报告，本作者没有把其未入本树的原raw当作者新run。原P2关闭不等于全接触品质完成：最高正浮空97.64mm、grab/release中段肩掌约0.56m断握，自然握持/全墙/最终构建/设备仍待。

下一品质片优先复现并修约0.56m可见断握，保留原20cm一次/墙外摆放/旧schema兼容/逻辑haul规则；再整理剩余HUD顶部层级，推进完整3DFX/continuous command timeline、A3预算、六关13波逐波视觉和正常玩家旅程，最后冻结同一候选跑完整smoke/独立QA/可追溯APK。真实耳听仍0/45、0/6；本环境没有实际耳听能力，需独立人员补门槛，但不阻其它施工。现有完整smoke7d34867与技术PCK91b9bdc早于当前修复，不能归到4741；本片未导出新APK/PCK，设备/模拟器继续依用户顺序后置。不merge/生产、不混G或height PR13/16/17/18。

## 所有权与资产接口

唯一主作者拥有main/presenter/ViewState/replay/HUD/loader/运行派生与共享测试。独立资产工作者继续拥有ArtSource、Blender、GLB/atlas与制作manifest；本片未编辑或重跑制作源，原环境85文件/11依赖、R5角色、30装备/3atlas和45音频PCM/import未变。天线源无需重导出，接受原50ef788/9c06f04的static triangle mesh/材质；运行派生只用于env_radio_antenna且按历史字段显式版本。未来非triangle/skin/blendshape资源保持原样，不丢动画数据。A3缓存/合批由运行主作者另片实现。

可供父端并行分配：固定4741独立只读R03反例/两LOD/旧版本/历史/触控复验，45 cue及六关声景实际耳听；本作者不派代理，也不写Notion。若自然断握确需资产新动作，只接独立路径、版本化manifest/hash和骨架/旧clip/挂点兼容验收后的最小提交，不直接合并资产WIP。


独立R03更新：父端报告b011自探241/0/ERROR0，19图已看，原baseline69/14exit1及106/164/32/23/84042/576Scout/25MG/10332复跑通过，无新P1/P2。原scope已闭合，不重开旧遮挡/整隐。320物理缩放不等于响应式；请求1600实际帧仍1280，真正1600可用viewport未验；200%压力图HUD裁切列最终viewport/HUD验收。以上是父端消息报告，新raw不在本作者artifact，不混作者新run。
