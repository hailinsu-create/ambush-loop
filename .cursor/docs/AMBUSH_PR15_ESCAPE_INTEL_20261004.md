# PR15 真实逃逸情报专项报告

2026-10-04，生产/正式运行源码 **877decb0ea14d6c3c0a833e4d6948c7ee549514f**，game tree64c347294bbcec18096b435243ce0d1e486d6ec0；接[教学语境](AMBUSH_PR15_TEACHING_CONTEXT_20261004.md)之后，执行[真实Intel计划](AMBUSH_PR15_ESCAPE_INTEL_PLAN_20261004.md)。新逃逸记忆只追加escape_context schema1（不是BattleLog schema1）：复制已有实际spawn/escape完整事件、level/原attempt/wave/actor，原事件/时刻/路径/模拟/库存/存档不改，原BattleLog schema2/playback2保持。FAILED/原retry SCOUT按保存的原local tick显示入场与逃逸，不使用LevelDef总表/当前wave/当前run。echo明确回波/碟台，road名不再硬coded晚5.2/3.8；建议陈述历史事实与检查射界，去掉无依据的获胜保证与总表减法期限。

| 固定运行 | checks/failures | actual exit | ERROR/SCRIPT ERROR |
| --- | --- | --- | --- |
| 5ca6bc966f2b3a89044d1a95208bedba4cfeb912 H | 18/8 | 1 | 0/0 |
| 5ca6bc9 R | 21/8 | 1 | 0/0 |
| 877decb H | 70/0 | 0 | 0/0 |
| 877decb R | 73/0 | 0 | 0/0 |

每轮官方4.7.2、run_isolated_test.sh、独立UUID/XDG，Guard在autoload前实际通过。negative8是实际身份/FAILED/hint/retry建议/旧记录错误推算及接口缺失的断言数，不是8个独立bug；接口缺失时有52个边界断言guard跳过，所以负向与修后checks不同。所有命令/actual exits/UUID/raw SHA/范围在[validation](evidence/20261004-pr15-escape-intel/validation.json)，[file-manifest](evidence/20261004-pr15-escape-intel/file-manifest.json)封存原件，未改以前正常记录。

原radio授本关枪/cover snaps/directticks/vacuum两波/合法SWEEP原收回部署→原第3波echo5实际escape→原FAILED/原retry新SCOUT，是reference不是normal输入。原spawn wave2/local30/global744/playback747/seq43，原escape同attempt/wave/actor local957/global1671/playback1675/seq47，terminal1671/playback1675/49events。新记忆保存原完整event_id/seq/local/global/playback；retry begin_attempt后旧来源仍不等于新attempt，FAILED事实行仍指历史第3波，不重绑currentrun去重。

R为独立:114 Xorg、1280×720、gl_compatibility/llvmpipe/Dummy、原3D场景/HUD截图，无XTest。负向3图与修后3图全核hash/目检6：负向实见第3波5.2s出发/主路巡卫/重开10.8建议；修后实见“第3波漏网：回波 · 敌5 · 0.5s出发 · 15.9s逃逸 · 碟台夹缝”和回波0.5s flash。重开首波HUD仍显示“历史第3波 · 回波敌5 · 0.5→15.9s”，28字原chip裁剪截尾，核心历史波次与两时刻可见；完整语义文本另断言，不称所有建议尾字均可见。首SCOUT静态“全关教学预览 · 灯塔回波5.2s · 绊索封暗道”保留预览角色。自用Xorg94792按exact argv/display/log识别SIGTERM关闭actual0，不动其他display。

兼容与边界实际执行：IntelStore原8参数记录shape/bytes不升级；缺/未知schema、非Dictionary/稀疏context、负时刻/逆时刻/错误offset、错actor/attempt/wave/event_id/seq/type/route、缺spawn/corrupt payload等25case及foreignlevel拒绝显示确认来源，回退“旧情报 · 侧翼敌4 · 波次/入场未确认”，不猜1.4/2.2/5.2/10.8。合法context完整复制、caller/返回值/path修改不污染保存source，原MAX5/短path拒绝保持。text display前后snapshot/HP/ammo/newlog/旧memory bytes相同。旧summary/hint/path字段原样可读，不把缺身份旧cache转换成新确认事件。

只读两份H reference比较actual0/E0/S0，49事件、sim快照、command/playback快照、schema和两终端全部相同，diff空；每源2个随机attempt/utility scope与派生ID前缀双射映射保持身份关系/后缀，不归一时刻/state/payload。新增Intel context及hint文本不在战斗域比较，不称原bytes相等：负向raw7737780bytes/SHA6ceba5e149daa1ef48f5fabdfaa6729c1f8121cc27b1df79aa3f41372d742a05，fixed H7739088/SHAc640d5b4cfeef855282cdb67488816eae8d79fc25fba89595d1b352a8297623a；保存raw和每次retry hash保持另证。既有warehouse/pump/railcut/depot/radio五native原件SHA再次只读核验全部相同，source bytes不升级。[只读日志](evidence/20261004-pr15-escape-intel/readonly-formal/formal.log)。

更新旧smoke文本契约：全关静态建议/背景前缀、真实事件时刻/保存attempt、旧8参数中性回退，保留原actor/route/进度断言，不为green改关卡总表。**完整smoke本片未执行**，下一统一候选必须实际运行；legacy2D、explicit foreign live同actor/seq log碰撞、alt/flank/sneak/main各真实escape变体、卷宗完整滚动/focus生命周期不在本片全部覆盖。原freeze/Back/touch/replay既有限定QA不代本source，normal13/六newrecord实际3D/完整FX/A3/耳听/设备/APK待。

父端a794 result/0bfe chip P2限定关闭与fixed3b radio原record3D10855/focus2992/nativepause3277各0归因在前报告及统一清单，非作者本轮自跑/非同candidate13波；cdb live/392 loot/fcf教学/本877 Intel独立QA待，旧depot失败与radio3277/1假阳性保全。后按[统一候选证据清单](AMBUSH_PR15_UNIFIED_CANDIDATE_EVIDENCE_PLAN_20261004.md)：先隔离新旅程输出不覆盖旧原件，完成QA新缺陷与完整FX后冻结，同候选新13波/六record实际3D、A3预算优化回归、可追溯APK；耳听/设备按父端后置。

主集成main/input/HUD/presenter/ViewState/replay/loader/共享测试单写；R5 source29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义保持，不编辑/重跑制作脚本/源/GLB/Blender/atlas/生产asset manifest，不全并WIP。父端可并行固定只读QA、优先6.1-sol不自行astra；Draft普通push，不merge/生产/height/G，网页GPT PLAN/REVIEW unavailable。

2026-10-04 随后父端QA来讯更新，替代上段cdb/392“待QA”状态：QA实际pwd exit0恢复、六旧包hash不变；fixedcdb timeline限定关闭，minimal50/0、修正expect后3D114/0、旧字段payoff12/0均actual0，**首轮814/1 actual1保留，不能拿子矩阵称该整轮green**；fixed392 loot原sameevent4/1→4/0、history/3D41/0 actual0限定关闭。父端称四新包read hash/截图已看，无新生产P1/P2、无QA运行/阻塞；来讯未给这些轮次ERROR/SCRIPT计数，不推断补0。是父端独立QA归因，非作者自跑。两个已闭scope不重开，fcf教学/877Intel与统一candidate13波/设备仍未独立接受。
