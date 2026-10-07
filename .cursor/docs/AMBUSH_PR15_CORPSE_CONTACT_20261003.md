# PR15 原生 SWEEP 拖尸墙面修复

2026-10-03。R02 作者修复与限定验证；父端已报告原穿墙P2独立闭合，仍不是全部尸体品质验收。继承 [v2执行计划](AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md)，已只读读取 [07玩法设计](https://app.notion.com/p/3eecc07750878107b969ef8df5b7b1ef) 与 [08整改台账](https://app.notion.com/p/3eecc077508781ce9d67f94c601f6ef7)。R保留六关13波数值、路线、占格及SCOUT→ALERT→SWEEP；G0–G5仍另版设计，本片不采用height PR13/16/17/18。父端已报告a325的R01 drop独立关闭，本片不重开该缺陷。

## 实际反例和固定修复

负向源码 `cd1581662b8f9cddac7b323e1b536e5eb8a8f040`（只加测试/隔离包装器）：真实yard两波敌人正常死亡，第二波原kar98k掉落用原生H抓取；原生鼠标经(592,112)寻路至(592,176)，右键朝+Y，363个实际蒙皮顶点进入原砖墙AABB。17项1失败，实际engine/wrapper退出1；独立UUID隔离通过。与父端旧518的401顶点反例分别保留，模型/LOD及夹具不强行归为同一数量。

明确夹具：首波沿用campaign的原loot vacuum；第二波用六格满包及初始靠近掉落设置，确保枪械不被原自动拾取提前收走。之后H、鼠标命令、寻路、负重和14px follow走生产入口，未生成假尸体、手动改尸体路径或关闭原拾取。此结果不是从标题起的完整玩家旅程。

固定修复/测试源码 `d7d291560a77ce112d3fe5f212e39e2d1143c132`：

- 新增可选 `corpse_contact_schema=1`；历史使用自己的字段、环境revision/layout、grid和door状态。旧/未知contact版本继续旧摆放，不向旧记录补当前算法。
- 对有搬运anchor的尸体，从固定R5 LOD0蒙皮姿态取得包围范围；选择最接近原朝向、与场景实体bounds留15mm间隙的方向。搬运者和尸体共同在显示层转身，保留双方手掌/肩点配对。原反例逻辑朝向仍90°，显示约180°，尸体沿墙摆放。
- 场景接触bounds取同帧版本化组装的固定环境LOD0，忽略cutaway visible与镜头LOD；门叶采用记录开闭角。尸体的根仍为原loot逻辑位置，显示子节点位移每帧重置，前后seek不累加。
- 原角色逻辑facing/position、负重、移动、原屏幕轴14px跟随、自动拾取、共享haul引用、枪/手雷消耗、墙占格/Nav/LOS、战斗事件和终局保持。

## 作者验证

首六个正式正向命令运行在d7d29156；附加精确MG复现运行在29898fd，生产树与d7等价（仅测试文件不同）；每次由隔离包装器分配独立UUID，实际退出0，完整日志和哈希见 [validation.json](evidence/20261003-pr15-corpse-contact/validation.json)。

| 实际命令（均从仓库根运行） | 结果 | 范围 |
| --- | --- | --- |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/bin/godot-capture corpse_contact_test.gd --render` | 576/0，exit0，5张实际帧 | 实际第二波输入反例0穿墙顶点；Scout单角色站/蹲×3档LOD×12朝向72组合，双手接触<15mm、最低顶点≥−15mm、固定墙bounds、原状态不变；墙边抓放、暂停/后台、复制历史、live污染和旧/未知版本 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 corpse_runtime_test.gd` | 1203/0，exit0 | 既有3角色×4敌人×3LOD×2姿态、实际移动/取消/来源/共享引用与旧回放 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 presentation_contract_test.gd` | 84042/0，exit0 | 48,416 picking samples/72 poses及原战斗1056tick/22event合同 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 utility_runtime_test.gd` | 1041/0，exit0 | 工具/drop/equip/cancel既有完整headless回归 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 equipment_freeze_test.gd` | 66/0，exit0 | ALERT/暂停/REPLAY冻结 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 campaign_replay_test.gd` | 10332/0，exit0 | 六关13波30/60 FPS、2x、历史只读与原终局 |

六关固定终局tick/events仍为yard1283/34、warehouse1191/67、pump907/34、railcut719/38、depot957/35、radio1413/51；30/60FPS与2x全部状态/事件一致。此campaign仍为原reference装备/loot-vacuum夹具，不称正常玩家全流程。

附加父端精确旧518路径：`AMBUSH_CONTACT_SCOPE=qa_exact bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/bin/godot-capture corpse_contact_test.gd --render`，固定测试源 `29898fdbacdc078038914a066c9bbaf6c1b5bd6b`，25/0、exit0。强制touch HUD，正常receive_item填合法枪/工具槽，原生队列Space进第二波、KEY2选MG、H抓放再抓、点击东移/寻路和右键；真实enemy_flank #3 wave1、source(596.6511,207.7352)，97步后逻辑(592.2054,178.353)，facing90.000057°、显示180.000057°，LOD0实际蒙皮进入砖墙AABB为0。每个鼠标目标先确认非UI。独立旧518的401 triangle-parity失败由父端保留；本次0 AABB内顶点为保守墙接触验证，不声称重跑父端32项脚本。额外[MG实际帧](evidence/20261003-pr15-corpse-contact/contact_qa_exact.png)已看，主修复代码未再变。新增测试22c9c44曾因screen类型推断parse失败exit1，日志留development并排除验收；29898fd显式Vector2后补跑成功。

负向实际命令为上述headless绝对Godot路径配 `corpse_contact_test.gd`，固定cd158166，17/1 exit1。导入成功0后45份audio import已恢复原候选字节；无制作资产变更。渲染为Compatibility/Mesa llvmpipe云软件渲染，不是设备性能结论。

已实际查看上述MG帧与 [held](evidence/20261003-pr15-corpse-contact/contact_held.png)、[放下起点](evidence/20261003-pr15-corpse-contact/contact_release_0.png)、[放下中段](evidence/20261003-pr15-corpse-contact/contact_release_35.png)、[地面](evidence/20261003-pr15-corpse-contact/contact_release_70.png)、[历史](evidence/20261003-pr15-corpse-contact/contact_history.png)。尸体在墙外保留完整显示，手/肩及高度另有实际蒙皮验证；画面中旧桌面角色卡与重复文字仍在，归下一R03切片。历史采用复制command快照测试，尚非连续SWEEP时间轴整体验收。

## 未验范围和下一步

本片目标位置/矩阵均找到摆放位置；若任何候选方向都不容纳，代码保留尸体并标 `contact_resolved=false`，不能记通过。未穷举全部地图紧角、每个模型在每堵墙和初始未搬运死亡位置；未改变anchor为空的原死亡摆放。自然动作、正向悬空上限与全部SCOUT/SWEEP玩家路径仍待品质复验，最低≥−15mm不能代替这些门槛。旧schema兼容保留旧摆放包含已知穿墙行为，显式版本1才使用新修复。

下一主作者小片先桌面/横屏HUD遮挡与radio天线整体cutaway，再完整3D FX/连续command时间轴、耳听、A3、六关13波逐波视觉、冻结单一候选后的完整smoke/独立QA/可追溯APK。现有技术PCK源91b9bdc早于drop和本修复；最新完整smoke仍7d34867，均不归给当前HEAD。设备/模拟器继续后置。未merge、未生产发布。

## 单写者和资产接口

| 所有者 | 本片边界与交付 |
| --- | --- |
| 唯一主集成作者 | presenter/view_state/visual_snapshot、corpse sampler/接触派生、隔离测试和PR15；不编辑模拟数值或新G规则 |
| 独立角色作者 | R5制作源/21GLB/共享atlas；本片仅只读原29749157/ebedb829资产，不编辑/重跑build_yard_kit.py、build_actors.py或Blender |
| 独立环境/音效作者 | 保持环境50ef788/9c06f04与音频86df/355ea89原文件；若需新候选，独立路径/分支、manifest/hash、版本与接触/LOD证据后由主作者最小接收 |
| 父端dot/独立QA/Notion维护者 | 可并行只读固定d7d29156原墙反例与品质检视；Notion只由指定维护者写。本作者未自行派代理或重复接资产制作 |

资产无需为本墙反例重导出。接触接口仍使用原20骨、upper_arm.L/R肩点、support_hand/weapon_hand旧socket、R5内嵌20cm偏移一次。若后续发现狭角无法共同转身，由独立资产作者提供可选折腿/紧凑拖尸候选并验旧键/骨架/几何/挂点兼容，运行接口另版本化，不整体并资产WIP。


2026-10-03状态更新：父端报告68582原native MG/source #3同序97步401 wall skin→0、独立32/0及全新portable再32/0，MG72配置/16H端点/历史387/0与四合法corner48sample133/0（位置fixture）无新P1/P2，原墙P2scope闭合。父端未入本树的raw不混为本作者新run；最高浮空97.64mm、grab/release中段肩掌约0.56m断握、自然握持/正浮空/全墙/same-candidate构建/设备仍待品质优化。本作者随后4741的默认contact576/0及精确nativeMG25/0实际exit0。具体HUD/radio已由[品质小片](AMBUSH_PR15_PRESENTATION_QUALITY_20261003.md)106/0修复；下一优先可见中段断握，再顶部HUD/FX/A3/13波视觉/最终同候选交付。


2026-10-03 接触品质续片：[抓放/正浮空报告](AMBUSH_PR15_CORPSE_PAIRING_20261003.md)。原e9 native MG102/15exit1、86矩阵171/83exit1→89fb34be2498123651bb7685dc55eb5aff6436f2运行修复；a575d9ec9b7eed1b934218a727c41c2a6d0ff226仅改专项测试实际camera参数和正式REPLAY入口，生产等价89，代码已推送核对PR15 Draft/Open/未合并。最终render2695/0/103秒、72hold/864相位、17native测点、双掌<0.001mm、body约6mm/搬运者脚底<0.2mm、原墙skin0、原骨段/端点/暂停/后台/复制历史/旧版通过；18正式run全exit0/ERROR0，9最终图已看，六关13波10332/0/393秒及原终局保持。矩阵/年龄/复制时间轴为明确fixture，不称全墙自然艺术或连续command已完成；独立品质复验待。实际camera size12/viewport1280×720，不将请求4/8写成实际。父端b011 R03原遮挡/整隐已独立闭合，真1600和200%HUD裁切待。下一剩余HUD/完整3DFX/连续command→A3/13波视觉与正常旅程→同最终候选fullsmoke/QA/APK；旧smoke7d34867/PCK91不归本片。资产源/GLB/atlas/manifest和R规则未改，无需新增R取舍；Notion指定作者负责，耳听0/45、0/6与设备后置。
