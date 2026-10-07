# PR15 抓放接触与正浮空品质片

2026-10-03。运行修复固定源 `89fb34be2498123651bb7685dc55eb5aff6436f2`，后续只改专项测试的 `a575d9ec9b7eed1b934218a727c41c2a6d0ff226`；后者仅修证据的实际镜头参数和复制历史夹具的正式REPLAY入口，生产代码与89完全一致。本片18个正式run全部实际exit0/引擎ERROR0；9张最终实际帧已查看。代码a575已推送并核对PR15仍Draft/Open/未合并，独立品质复验仍待。继承[v2](AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md)，保持SCOUT→ALERT→SWEEP、原数值/路线/占格/拾取/14px follow/共享haul引用，不merge/生产/设备，不混G或height分支。

## 固定反例与修复

`e9c158cde7155e67aceaec134698a23faa2dff55`：原native MG同序两波、source enemy_flank#3与97步鼠标路径，render102项15失败、实际exit1。grab/release中段肩掌约0.559m，近地端点约1.196m，原臂段总长约0.592m，单靠手臂旋转无法触达。`86ea697524eff486812261f650f60dd78b107947`扩72组role/model/LOD/stance夹具，headless171项83失败。顺序姿态采样还暴露整姿命中缓存后保留上一层蹲姿的运行错误，不能把全部失败归为制作资产。原日志、JSON和三张负向实际帧保留于[evidence](evidence/20261003-pr15-corpse-pairing/)。

新增可选 `corpse_pairing_schema=1`，仅在已支持的R5角色、环境及contact1上启用；缺失/未知仍采用原姿态策略。GLB原clip与内嵌20cm回移保留且只采样一次。实际当前LOD蒙皮最低点规范到6mm；canonical LOD0与当前LOD联合bounds继续选择墙外方向。尸体代理root仍是复制的逻辑loot位置，不把显示补偿写回玩法。身体初次死亡、从未拖动而无anchor的旧展示路径保持，本片不声称全部死亡动作品质完成。

抓取0..0.2s伸手接近、0.2..1s握住抬起；放下0..0.5s握住落地、0.5..0.7s松手返回复制普通姿态。原逻辑抓放仍瞬时，不新增等待、20cm逻辑移动或拥有者锁。活动握持要求双掌/肩点<15mm，接近与松手返回明确未握住。髋腿/躯干使用原骨架姿态；手臂与腿的两段求解只转骨，不拉长骨段或缩放模型，脚点保留原动作目标。不可达或无墙解分别标记pairing/contact未解决，模型仍可见，不算通过。

整姿/分层采样缓存现在区分上一采样是否分层、是否被运行求解修改；每次刷新先恢复作者原姿态，防止程序姿态累积。bounds的新策略以局部骨架链采样，消除世界位置/朝向参与缓存的浮点误差；静态端点有限缓存，动态年龄不无限增长。近直臂小角度使用轴角旋转，避免Quaternion双向量构造把小旋转当作零留下约0.24mm误差。

## 实际验证与证据边界

Godot固定4.7.2/ed1daf0bf；每run独立UUID/XDG与StorageGuard。渲染是Xorg/Compatibility/Mesa llvmpipe/Dummy，不能证明安卓帧率或实际听感。实际命令/环境/退出、源码归属、日志和截图哈希汇总于[validation.json](evidence/20261003-pr15-corpse-pairing/validation.json)。

原native输入保留reference装备、先前loot vacuum等明确夹具条件；成功原Space/KEY2/H抓放再抓及97步导航成立，不是未加夹具的完整玩家旅程。17个native姿态测点含活动握持、伸手/返回、端点；16个复制的command事件年龄帧经真实REPLAY入口后，用独立0..15s测试时间轴做前后seek。该时间轴是验证夹具，不是已完成连续command生产录制。

独立stage矩阵72个hold配置、864个grab/release配置：3角色×4敌人模型×3LOD×2stance；动态每抓/放各6年龄点。沿用真实事件身份，显式修改模型/站姿/位置，在无墙stage测双手与蒙皮脚底；这不等于864条完整战场路径或所有角落验收。原native测点另以原砖墙实际蒙皮顶点检查尸体和搬运者，两者wallskin均0。

| 固定源实际run | 结果 |
| --- | --- |
| 89专项render，旧metadata收据另存 | 2694/0、exit0；9图。请求尺寸4/8实际均被原镜头限制为12，旧字段误填请求值；直接设REPLAY的夹具未执行瞬态HUD清理，不以此历史图验正式入口 |
| a575专项render | 2695/0、exit0，103.01秒；记录实际镜头/viewport，经原REPLAY入口；17native、72hold/864相位、原骨段/双脚/墙外、暂停/后台恢复、端点连续、复制历史/正反seek/live污染及旧未知版 |
| 原尸体 / 默认Scout墙接触 | 1203/0 headless、576/0 render，exit0；原拾取/取消/移动/共有haul/跨波保留 |
| R5角色 / 十枪 / 实战角色 | 21818/0 headless、7681/0 render、231/0 render，exit0；64clip、90枪配置与实际战场/旧R3历史 |
| 工具 / ALERT装备冻结 | 1041/0、66/0 headless，exit0 |
| command时钟 / 多波事件时间轴 / 原表现合同 | 27/0、66/0、84042/0 headless，exit0；headless时钟少于render两项图像检查 |
| HUD / 生命周期 / depot-radio限定quality | 164/0、32/0、106/0 render，exit0；R03已关闭的scope保持，不扩大响应式声明 |
| native MG精确墙路径 / 历史hint / camera input / 六关13波 | 25/0 render、30/0 render、23/0 headless、10332/0 headless，全部exit0；六关run393.07秒，yard1283/34、warehouse1191/67、pump907/34、railcut719/38、depot957/35、radio1413/51 |

新策略的native及矩阵body最低点约6mm；native活动握持最大肩掌误差<0.001mm，864相位矩阵活动握持最大约0.00026mm，脚底偏差<0.2mm。原legacy对照hold矩阵实际最低点从−1.23mm到101.03mm，不能用“未穿地”称接地。正式body范围0.005999982..0.006000027m；搬运者范围−0.000172590..0.000141411m。不改负向历史值。活动握持原两臂骨段误差<0.1mm；端点位置差<1mm、转角差<0.01rad。

9张正式图已全部实际查看：[抓中段touch](evidence/20261003-pr15-corpse-pairing/contact_quality_grab_half.png)、[放中段touch](evidence/20261003-pr15-corpse-pairing/contact_quality_release_half.png)、[抓desktop65°](evidence/20261003-pr15-corpse-pairing/contact_quality_grab_desktop_front.png)、[抓desktop245°](evidence/20261003-pr15-corpse-pairing/contact_quality_grab_desktop_rear.png)、[放desktop65°](evidence/20261003-pr15-corpse-pairing/contact_quality_release_desktop_front.png)、[放desktop245°](evidence/20261003-pr15-corpse-pairing/contact_quality_release_desktop_rear.png)、[复制历史touch](evidence/20261003-pr15-corpse-pairing/contact_quality_history.png)、[复制历史desktop](evidence/20261003-pr15-corpse-pairing/contact_quality_history_desktop.png)、[原MG握持](evidence/20261003-pr15-corpse-pairing/contact_qa_exact.png)。实际镜头size12、viewport1280×720；请求4不是合法size4近景。touch动作按钮仍部分遮住手部，desktop视图暴露手脚，不能把接触数值通过称全面自然艺术验收。独立作者/父端需在固定候选做自然姿势和原角落复验。

开发1..8及源码89早期metadata/直接phase历史图单列保存，均不取代a575最终报告；阶段6空attempt/wave0历史夹具与阶段5旧view.frame相位夹具错误保留为诊断，不归为生产回放失败。一次firearm headless命令实际exit2，被测试明确要求渲染的守卫拒绝；原log/exit保存，随后正确render7681/0，不冒称headless枪族通过。导入45原音频import被引擎重写后已按原候选逐文件恢复，本片不引入这些编辑。

## R03与剩余计划

父端报告b011 R03原depot遮挡和新cutaway1 radio整隐已独立闭合：241/0/ERROR0、19图看验、原69/14与106/164/32/23/84042/576Scout/25MG/10332复跑，无新P1/P2。该消息为父端报告，本作者不归为自己的新run。请求1600实际只1280，真正1600可用viewport未验；320物理缩放不是响应式，200%压力HUD裁切列最终验收；不重开原遮挡/整隐。旧unknown cutaway整隐回退及55/42部件绘制成本保持版本/预算边界。

下一步是本片固定候选独立品质复验；主作者继续剩余HUD实际viewport/200%裁切、完整3DFX/连续command时间轴、A3缓存/合批/动作和资源预算、六关13波视觉与正常玩家旅程，最后冻结同候选完整smoke/独立QA/可追溯APK。最新旧完整smoke仍7d34867、技术PCK仍91b9bdc，早于本片，不归当前；本片未导出新APK/PCK。耳听0/45 cue、0/6声景，本环境缺实际能力，后续完整可播放包交人员听验，不阻其它施工。设备/模拟器按用户顺序后置，网页GPT PLAN/REVIEW unavailable。

## 所有权与并行接口

唯一运行主作者负责main/presenter/ViewState/replay/HUD/loader/运行派生及共享测试。ArtSource/Blender/GLB/共享atlas/制作manifest仍独立资产作者所有；本片未编辑或重跑build_yard_kit.py/build_actors.py或制作输出，未整合资产WIP，也不写Notion。原R5/21角色GLB及20骨架、64clip、30装备/3atlas、ENV85文件/11依赖和45音频原字节保持。本片没有要求重新生产角色包。

可由父端安全并行分配：固定a575只读重现original MG抓/放/角落/LOD/历史的独立品质QA；完整可播放包的45 cue/六关声景耳听。主作者独占共享运行与测试写入，不自行派代理。若独立审图仍发现原rig不可自然达到的姿势，交资产作者最小角色/clip/骨架挂点版本接口，先验兼容再接收有限提交，不整体合WIP。


2026-10-03 本地P2内部边界续片：[schema2连续抓放报告](AMBUSH_PR15_CORPSE_BOUNDARY_20261003.md)。固定f7fcfdbab1adac3ff545ecadbe9b8d74ec9306d3，正式边界2978/0、36关键边界/1350整段probe/72旧schema1精确摘要；旧0/99fallback及history不升级。18正式run均exit0/ERROR0，含品质2695、合同84042、六关13波10332，原终局保留。四关键图+三品质图已看；边界三辅助PNG被后续通用名覆盖未保留，receipt明示，品质9图完整。作者验证通过，独立P2仍待；focus邻近镜头文字裁切、minimap/checklist叠层及FAILED/WON200列待。6a HUD5081限定结论保留，未称全HUD关闭。仅本地保存，Git/Library阻塞不绕过；资产制作diff为空。继续FX/continuouscommand/A3/完整旅程/同候选smoke-QA-APK，耳听/设备后置。
