# PR15 静态教学语境专项报告

2026-10-04，生产及正式运行源码 **fcf40a97606c148ec6dcb87a2b20dfa39100458e**，游戏树fa8ea37ed09d37c537a044f99f079aa9684ad325。原beat/spawn_teaching加“全关教学预览”，总表秒数route chip加“全关预览”，旧2D echo map标签明确教学预览；静态fix_one加“全关教学建议”并去除获胜保证，预设chatter标“关卡背景”。只五个显示入口，不改关卡原文/总表/波次/事件身份/伤害/库存/SCOUT→ALERT→SWEEP。原unarmed动态警告、tutorial/briefing/role_why未在本片全覆盖。

| 固定运行 | checks/failures | actual exit | ERROR/SCRIPT ERROR | 归属 |
| --- | --- | --- | --- | --- |
| dev1221 H | 139/79 | 1 | 0/0 | 78静态oracle＋1未到实际escape；无终局事件保全，不称实际反例 |
| dev2da H | 138/81 | 1 | 0/0 | 80静态oracle＋1错误卸枪断言；真实第三波escape已达 |
| ebe38a1651e46bd239c8c37ba761d9a73897f579 H | 138/80 | 1 | 0/0 | 正式负向，纠正原clear保留枪的测试契约 |
| ebe38a1 R | 141/80 | 1 | 0/0 | 正式负向物理窗口，3PNG核/看3 |
| fcf40a9 H | 138/0 | 0 | 0/0 | 固定作者显示专项 |
| fcf40a9 R | 141/0 | 0 | 0/0 | 固定作者物理窗口，3PNG核/看3 |

每轮走run_isolated_test.sh，独立UUID/XDG，原Guard在autoload前通过；Godot官方4.7.2。R为独立:113 Xorg/1280×720、gl_compatibility/llvmpipe/Dummy，3D原场景/原HUD callback截图，无XTest native输入。自用Xorg93966按exact argv/display/log识别SIGTERM关闭actual0；不动其他display。实际命令/UUID/ERROR/退出/record/captures见[validation](evidence/20261004-pr15-teaching-context/validation.json)，原图hash及文件数见[file-manifest](evidence/20261004-pr15-teaching-context/file-manifest.json)。

六关13wave×3D/旧2D矩阵明确赋wave/fail flags，只是26组display fixture；每组原text refresh前后snapshot/log/关卡schedule bytes相同。旧2D echo标签与route helper是实际节点/formatter断言，不称完整旧2D正常旅程或tooltip实际点击验收。背景对白是原fail_dossier_text内容断言，没有本轮打开卷宗PNG，不借3图称已见背景页。

另原radio授本关枪/cover snaps/directticks/vacuum清前两波，合法SWEEP原收回部署到insertion（原reset_loadout保留装备枪），第三波echo5真实逃逸→原FAILED/重开SCOUT；不是正常输入/新record完整3D。49事件、escape local957/global1671，spawn wave2/local30/global744，terminal1671/playback1675；原retry begin_attempt后保存的旧reference bytes/hash不改。负向/修后3图各已核hash及目检：SCOUT仍为总表5.2s但明确教学预览，FAILED原静态建议明确教学建议；真实逃逸行和hint错误仍可见，明确未接受。该片成功不等于全部HUD/Intel事实已关闭。

只读H原record比较另列actual0：ebe与fcf两份events/snapshots/playback_snapshots/两终端/schema全部相同，仅把每源2个独立32hex attempt/utility scope及派生ID前缀做保持同一/不同关系的双射映射，seq/suffix/时刻/state/HP/ammo/payload不归一。最初只归一attempt/event_id导致snapshot两fail、actual1；诊断actual1发现utility/corpse随机身份，两失败脚本/日志保留，正式映射actual0且diff空。该结果不是原bytes相等，原各raw SHA独立保留，不改任何原件。[原比较证据](evidence/20261004-pr15-teaching-context/readonly-formal/formal.log)。

实际下一片反例已证实：该第三波敌5真实0.5s入场，旧FAILED写5.2s/碟台硬coded晚5.2，hint误写主路巡卫南闸，retry由15.95减总表5.2生成10.8s建议和保证获胜。静态前缀不掩盖这些错误；按[真实逃逸Intel计划](AMBUSH_PR15_ESCAPE_INTEL_PLAN_20261004.md)追加版本化保存source身份/波次/真实入场与逃逸时间、旧缺字段中性fallback，独立negative→fix→固定QA。此前手写“继续封暗道”转述误读勘正为实际“绊索封暗道”，原历史PNG/source/报告保留，不是两个runtime变体。

父端独立QA最新报告归因：a794 result原3b8/4→8/0、窗口82/0 actual0 E0/S0、10图已看；0bfe chip原a79441/14→41/0、3D reference621/0 actual0、2native/2图，result/chip P2限定关闭。fixed3b radio原record实际3D10855/0、417自然callbacks、2x终端6344，末波focus2992/0与nativepause3277/0、11图已看；原3277/1断言假阳性保留。非作者自跑/非同candidate13波验收；cdb live/392 loot待独立QA，原depot正常1201/2/minimal4/2及4/1仍保全。

之后按[统一候选证据清单](AMBUSH_PR15_UNIFIED_CANDIDATE_EVIDENCE_PLAN_20261004.md)冻结：先防测试输出覆盖旧normal原件，正常新13波/六newrecord实际3D→完整FX/A3优化回归→可追溯APK；耳听/设备按父端后置。旧各source分段绿不拼候选。唯一主集成代码单写者main/input/HUD/presenter/ViewState/replay/loader/共享测试，R5 source29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义保持；不碰源/GLB/atlas/Blender/制作脚本/生产asset manifest。父端可并行fixed只读QA，优先6.1-sol不自行astra；Draft普通push，不merge/生产/height/G，网页GPT PLAN/REVIEW unavailable。
