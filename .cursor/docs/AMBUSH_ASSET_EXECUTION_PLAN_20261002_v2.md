# 写实资产实施顺序 v2

日期：2026-10-02。需求来源：用户明确要求“先完成全部计划工作，之后再说模拟器/真机测试”。本文件替代 PR #14 执行计划中 A0.3、A3 设备检查阻塞资产生产及六关推广的顺序；原资产清单、玩法边界、质量与真实性要求继续有效。

## 目标与范围

完成三名队员、四类敌人、共同骨架与当前行为动作、十种枪械及工具、十四类道具、六关建筑地表与声景、3D 特效、HUD、回放和设置接入。360° 水平旋转、35°–65° 俯角及缩放保持；暮色冷灰环境与局部暖灯、主流中端安卓 30 FPS / 高配可选 60 FPS 仍为目标。

不改变战斗数值、路线、可行走区域或胜负规则，不增加高度玩法、第七关、FOW 或联网。Blender 源与导出物可重建，表现只读模拟状态，回放不得读取当前活体来伪造历史。

## 新执行顺序

1. **A1.2 角色与动作**：共同骨架、角色差异、装备挂点、原地动作、LOD；源校验与引擎动作评审。
2. **A2 完整院子**：场景/道具/角色/特效/声音接入；HUD、安全区、设置；新旧回放兼容及完整战术循环。
3. **A3 云端部分**：合批、LOD、纹理与渲染预算检查；隔离行为测试、画面和动画评审，处理发现的问题。
4. **A4 其余五关**：仓道、泵站、信号楼、油库、电台的完整主题资产、照明与声景；六关云端回归。
5. **交付完整构建**：可追溯 APK、精选截图/视频、源提交和测试记录，更新同一实现 PR。
6. **最后安排设备阶段**：全部制作及接入完成后，再处理模拟器、努比亚 Z60 / Android 14、代表性中端机及持续运行。当前不启动模拟器，不要求用户安装灰盒或协助云端可完成的检查。

## 验证与风险

每一制作切片完成后继续做资源导入、针对性云端功能和视觉检查；修改交互/回放后测试对应契约，最终运行完整六夜回归。云端图形计数用于优化，不能证明手机 30/60 FPS 或热稳定性。设备阶段的结果在执行前一律标为“待验证”。后置设备检查可能发现 GPU/触控适配问题，届时修复，不用未知性能阻塞当前全部生产。

设置与战役进度分离；默认入口切换后保留开发用旧视图，回退不清档。新 PR 不自动合并。本次只是顺序变更，不把未实现或未检验的资产标为完成。

## 当前状态

A0 云端坐标/镜头/输入/冻结与六关基线已通过，灰盒 APK 已构建；A1 首批九件道具/建筑及十八个 LOD 已完成源管线与渲染评审。现从 A1.2 继续。设备验证统一移至上述第六步。网页 GPT PLAN/REVIEW：unavailable。


最新尸体片：[真实来源/肩掌/取消与纯回放报告](AMBUSH_PR15_CORPSE_RUNTIME_20261002.md)。ce932cc成功来源绑定/ground/held及真实H抓放先770/0；完整六关10332/3暴露age随capture浮点累加，bf1261c railcut1249/1明确只在两个年龄字段。3048294改domain原锚点后尸体770/合同84042/六关13波10332均0失败；91b9bdc仅扩实际移动/步态测试至1207/0和emptyPCK1766/0，运行树与304等价。复制bodyID/source wave不重绑，原任意loot haul/屏幕14px follow/自动ammo拾取和共享引用不变；内嵌20cm只采样一次。四张实际帧已看，72配对接触及−15mm最低floor门限通过，正向离地/自然艺术/墙碰撞/完整SWEEP玩家拖尸路径未称验收。当前技术PCK25618864 bytes SHA52e14b6b4189af54cb28086b0f36ec08f7201ba24a6be8fa2e823da376562378，非APK；环境重连旧exit句柄失效，304成功有pipefail后TEST_LOG证实0，两个FAILED退出码不冒称观测。HUD盖目标与radio整隐仍是下一必修，然后FX/continuous command/FAILED-A3/13波visual/最新fullsmoke/APK；生产源/GLB/atlas仍独立作者，最新fullsmoke7d34867、耳听设备后置。


最新独立P2：[成功丢弃取消报告](AMBUSH_PR15_DROP_CANCEL_20261002.md)。原518仍同帧投雷→drop rifle→普通更新拾回rifle导致旧throw复活，b082540真实headless6/1exit1；47f0634仅成功drop立即cancel一行修为6/0，6e9ed4c扩失败/同枪kit/ALERT拒绝13/0、完整render1047/0、装备66/0、尸体headless1203/0，3e09a82专项render7/0与恢复枪实际帧。所有实际exit/durable状态和原日志已存。尸体正文按518原receipt改最低−0.001234874m（原误0.003765）、最高0.101031780m，原receipt不改；自然接地/离地上限/墙contact/完整SWEEP玩家路径独立待验。制作资产无修改，既有PCK91早于此修复，最新fullsmoke7d34867；HUD/radio→FX/A3/13wavevisual/fullsmoke/APK继续，未merge/生产/设备。


2026-10-03 R02限定作者修复：[原生SWEEP墙接触报告](AMBUSH_PR15_CORPSE_CONTACT_20261003.md)。固定cd158166真实第二波H/原鼠标路径/朝+Y有363蒙皮顶点进砖墙17/1exit1，d7d291560a77ce112d3fe5f212e39e2d1143c132显式contact版本/共同显示转身修为render576/0，原尸体1203、合同84042、工具1041、冻结66、六关13波10332全部实际exit0；原终局/规则不变，5张真帧已看。独立墙QA、自然正向高度和全墙品质待验，R01由父端报告a325独立关闭；HUD/radio→FX/耳听/A3/13wave visual→单一候选smoke/QA/APK继续，设备后置。G另版、height PR13/16/17/18不合入；ArtSource/GLB/atlas/manifest未改未重跑。旧PCK91/完整smoke7d34867不归当前版本。

附加固定29898fd精确父端MG/force-touch/原生Space-H抓放再抓-鼠标路径复现25/0 exit0；真实flank#3原source(596.6511,207.7352)，97步后(592.2054,178.353)、逻辑90°，LOD0墙内skin顶点0。仅测试文件不同，生产代码等价d7；新MG帧已看，测试parse诊断22c单列保留不计通过。


2026-10-03 R03限定作者修复：[depot点击与radio整隐](AMBUSH_PR15_PRESENTATION_QUALITY_20261003.md)。负向c00ddef69/14实际exit1→4741c5f020965f9a4315fa8993da20474efc04f0正式106/0，桌面重复肖像不再盖depot原SWEEP566目标，radio18姿态保留几何、两LOD逐三角形位置/法线/UV/切线及材质完全保留；copied history/live污染/seek、旧缺失/未知version回退及历史卡片只读已验，四张正式图已看。HUD164/生命周期32/输入23/合同84042/六关13波10332/defaultcontact576/nativeMG25均实际exit0；开发属性重编码失败原日志另存排除验收。R03独立QA与SCOUT顶部文字拥挤仍待；missing/unknown cutaway保留旧整隐行为，55/42部件成本进入A3。父端报告68582原穿墙P2独立闭合但最高浮空97.64mm与中段约0.56m断握仍品质缺口，下一优先修断握，再剩余HUD/FX/A3/13wavevisual/同候选smoke-QA-APK。资产制作源/GLB/atlas/manifest未改未重跑，Notion由指定作者写；耳听0/45、0/6缺实际能力，设备后置。旧PCK91与完整smoke7d34867不能归当前版本，不merge/生产、不混G或height分支。


2026-10-03 接触品质续片：[抓放/正浮空报告](AMBUSH_PR15_CORPSE_PAIRING_20261003.md)。原e9 native MG102/15exit1、86矩阵171/83exit1→89fb34be2498123651bb7685dc55eb5aff6436f2运行修复；a575d9ec9b7eed1b934218a727c41c2a6d0ff226仅改专项测试实际camera参数和正式REPLAY入口，生产等价89，代码已推送核对PR15 Draft/Open/未合并。最终render2695/0/103秒、72hold/864相位、17native测点、双掌<0.001mm、body约6mm/搬运者脚底<0.2mm、原墙skin0、原骨段/端点/暂停/后台/复制历史/旧版通过；18正式run全exit0/ERROR0，9最终图已看，六关13波10332/0/393秒及原终局保持。矩阵/年龄/复制时间轴为明确fixture，不称全墙自然艺术或连续command已完成；独立品质复验待。实际camera size12/viewport1280×720，不将请求4/8写成实际。父端b011 R03原遮挡/整隐已独立闭合，真1600和200%HUD裁切待。下一剩余HUD/完整3DFX/连续command→A3/13波视觉与正常旅程→同最终候选fullsmoke/QA/APK；旧smoke7d34867/PCK91不归本片。资产源/GLB/atlas/manifest和R规则未改，无需新增R取舍；Notion指定作者负责，耳听0/45、0/6与设备后置。


2026-10-03 本地HUD续片：[真实窗口/200% HUD报告](AMBUSH_PR15_VIEWPORT_HUD_20261003.md)。固定6a519b3运行5081/0、42样本/51物理PNG/46原生XTest事件，实际exit0/ERROR0；保留aspect keep的1280逻辑宽及1600留黑，200%可用640×360。三正式图已看，其余图保存不冒称逐图验收；FAILED/WON、独立复验/六关完整旅程/fullsmoke/APK待。Git只读与connector成功但写凭证未恢复，停止auth/push重试，仅本地保存；P2抓放内部边界仍独立处理中，资产制作文件未改。


2026-10-03 本地P2内部边界续片：[schema2连续抓放报告](AMBUSH_PR15_CORPSE_BOUNDARY_20261003.md)。固定f7fcfdbab1adac3ff545ecadbe9b8d74ec9306d3，正式边界2978/0、36关键边界/1350整段probe/72旧schema1精确摘要；旧0/99fallback及history不升级。18正式run均exit0/ERROR0，含品质2695、合同84042、六关13波10332，原终局保留。四关键图+三品质图已看；边界三辅助PNG被后续通用名覆盖未保留，receipt明示，品质9图完整。作者验证通过，独立P2仍待；focus邻近镜头文字裁切、minimap/checklist叠层及FAILED/WON200列待。6a HUD5081限定结论保留，未称全HUD关闭。仅本地保存，Git/Library阻塞不绕过；资产制作diff为空。继续FX/continuouscommand/A3/完整旅程/同候选smoke-QA-APK，耳听/设备后置。


2026-10-03 最新交付状态：原配置唯一push重试成功并只读核对cf77f4db63605ff1e9846e1149f27ca6d461f458；先前onlylocal/authblocked均为历史状态，不推永久凭据健康。Library恢复未发生，不重试。HUD续片[北侧HUD报告](AMBUSH_PR15_NORTH_HUD_20261003.md)，运行816正式focus1702/0+viewport5081/0exit0，checkbox/minimap已分开，原两张镜头裁切原生133/0未复现仍待独立QA，FAILED/WON200另做。


2026-10-03 本轮限定HUD收尾：[终局与北侧叠层报告](AMBUSH_PR15_RESULT_HUD_20261003.md)。f2结果滚动首修后，80ce379补镜头层级745/24exit1与时间条1718/16exit1→固定7edd0db93243e1079d6af3e55da37bf2d5a97df1正式结果449/0、focus1718/0、viewport5081/0、合同84042/0、历史画面164/0、渲染生命周期32/0，全实际exit0/ERROR0，119最终PNG全部留存并核hash，三张最终图已看。原两张focus邻近裁切未复现/独立QA仍待，cf77 IK/HUD独立QA由父端安排；未称全部HUD/完整战场/设备通过。此前onlylocal/authblocked为历史失败，原配置重试成功后，本片普通push及git/connector只读核对7edd成功；Library未恢复不重试。资产接口/单写者/SCOUT→ALERT→SWEEP规则保持；未展开FX/A3，后续仍按父端分配推进。


2026-10-03 父端独立schema2 IK与北侧原矩阵已限定关闭，原focus文字与0ac终局新修QA待；旧cf77终局15/2及shader-cache错误不算green、不归0ac。继续[连续command切片计划](AMBUSH_PR15_CONTINUOUS_COMMAND_PLAN_20261003.md)：先真实ALERT/SWEEP两波录制与回放，保留原battle tick/seq/terminal统计，SCOUT前段留下一片；资产单写/规则边界保持，FX/A3/radio旅程/同候选最终构建按计划继续。


2026-10-03 父端已限定关闭0ac终局两P2；新radio200致谢子层P2优先[独立修复计划](AMBUSH_PR15_CREDITS_PLAN_20261003.md)，56/2中presentationclock误判排除。依赖47a645连续command已提交但仅开发98/0，formal/graphical/六关未运行；本片只修credits，再同候选整体formal。
2026-10-03 radio credits专项：源dedc8cfdcfd5662eb86fe337cfd80812234904ab，负向cd984a5 106/17exit1/引擎错误2→正式127/0exit0/ERROR0，11物理图与26原生输入，三次原radio三波fixture经原WON CTA进入、滚到底及100/200返回/Back200。原正文/终局footer/1413tick/51events保持，headless lifecycle30/0通过；[报告](AMBUSH_PR15_CREDITS_20261003.md)。独立QA待；继承47a645连续command仍仅开发98/0，下一片同47+credits整体formal，不能以本专项替代六关战场/设备通过。资产接口/制作所有权保持，Draft不merge/生产。


2026-10-03 同候选正式关作者完成：[完整报告](AMBUSH_PR15_FULL_RECORD_20261003.md)。固定15c0783059bb7c2f9e9cd9b7252a9343e71f4168，runtime d860056f2107836c08dfb375a034ebbe694baff6；29次全部实际exit0/ERROR0、75图核hash。SCOUT身份/真实采样保至报警、schema2播放+原domain不变，旧schema1实际874 fixture兼容。六关39reference波/mode、原terminal/events与30/60/2x camera对照保持；不是正常完整玩家旅程/完整3DFX/设备性能。23项checkpoint后只收session5976既有6项，不重跑有效项。失败/旧候选保全，fixture精确hash与历史源重建已写，无LibraryID/不绕过。父端fixed15c独立QA待；继承title200全菜单/Help返回/退出确认/键盘下一独立片，然后FX/A3。R5制作所有权、SCOUT→ALERT→SWEEP、Draft不merge/生产、height/G隔离保持。


2026-10-03 checkpoint：[title200全入口报告](AMBUSH_PR15_TITLE_20261003.md)，fixed226505fb7cc424fb8ff955e94f98f086835b2423：原menu+6brief/help/journal/settings/真实SCOUT入场/真实button与keyboard退出，8组2391/0+7/0、2runexit0/ERROR0、72PNGhash核对；作者通过，独立title QA待，Git认证失败后尚仅本地保存。fixed15c fullrecord29/75证据a218已推送，父端另报告limited QA通过（59PNG看19及其计数不相加）。完成队列已结束。继续完整3DFX/autoREPLAY2×（尚未实现）/A3与正常六关玩家旅程、最终同候选smoke-QA-APK；不把controlled2×fixture当auto功能、XTest当手机、llvmpipe当设备性能。资产制作输出未改，Notion/Library仍未写，不merge/生产，高度/G隔离，设备全计划后。

2026-10-04 六关结果事实独立片：[报告](AMBUSH_PR15_RESULT_FACTS_20261004.md)。原warehouse未续包/depot-radio未触雷正常反例保留；yard/railcut复合事件绑定不足仅源码审查。9918负向H193/80 exit1/E0/S0→固定a794正式H193/R221各0/exit0/E0/S0，统一中性结果不改规则/R/资产。五原bytes只读、六reference终局/旧2D仅结果，14PNG核/看7，FAILED原生滚到完整句；不能代正常同候选13波/历史3D/FX/艺术/A3/耳听/APK/device。radio末波提示的实际缺陷与其他总表教学/建议审查边界另片待，green不隐藏已知展示错。R5接口与单写者保持。

2026-10-04 本波待入场chip：[报告](AMBUSH_PR15_CURRENT_WAVE_HINT_20261004.md)。生产480修当前队列/原clock/入场前及due tick/REPLAY隔离；a091负968/271exit1→formal0bfe H971/R975各exit0/E0/S0，2最终PNG核/看2与2 XTest，36证据。480R972早green漏完整HUD刷新导致旧0.0s图保留为dev，最终三新增oracles真实显示paused第3/3波t1.4/pending0。13波矩阵两模式是reference display数据，不代26实战；一radio原域授枪/snap/directtick/vacuum原三波与52事件/843terminal保持，不代normal3D。live观战条总表dots另有实际矛盾、前波payoff只source审查，必须下一独立片修后才能全关当前波/最终candidate；[同候选六关/FX/A3计划](AMBUSH_PR15_SAME_CANDIDATE_FX_A3_PLAN_20261004.md)已保存，完整FX/艺术/A3/耳听/装备触控/旧2D/同候选13/APK/设备尚未验。资产所有权/R5接口保持。

2026-10-04 本波路线条：[独立报告](AMBUSH_PR15_LIVE_TIMELINE_20261004.md)。生产f020作用域原pending/current wave/attempt payoff/明确全关教学预览，ee15负1158/463exit1→formal cdb H1159/R1164各exit0/E0/S0；3正式图核/看3/2XTest，两个布局误中原abort的R失败和parse失败全保留。13wave两模式display matrix与radio三SWEEP/seek/exit是reference，不代normal/fullR；两份51事件字段只读一致/各末波非终局。SCOUT IntelStore5.2总表提示另审，不能称所有当前波HUD关闭。父端railcut原fixed3b native1389/record2839/作者原record10496各0限定通过保持不重跑；depot normal1201/2 actual1及RESULT/LOOT两个P2失败保全，新/作者record3D2463/9539各0不抵销。下一独立loot formatter文本，不改库存、不混a794gate，再同候选/FX-A3；APK/设备最终验收仍后置，资产源/GLB/atlas/Blender所有权及R5接口保持。

2026-10-04 loot文本：[独立报告](AMBUSH_PR15_LOOT_TEXT_20261004.md)。fixed392中央formatter按原kind/amount与catalog显示物品数量，枪amount携弹/未知或缺量不推断ammo；a190负H85/45actual1→H85/R86各0actual0/E0/S0，28kind/7边界、原depot事件:1:38与邻帧mine0→1/ammo8保持只读，history foreign-live/ItemList/fallback有界，1图核/看1，16证据。不是库存修复/normal/fullR或a794gate，父端fixed3b失败不取消，fixed392独立QA待。接[有界后续](AMBUSH_PR15_NEXT_SLICES_20261004.md)先静态情报教学语境审→同候选基线/真实成功射击FX-A1→工具FX/A3/最终candidate与追溯APK，不提前设备/APK最终验收；制作资产/R5所有权与接口保持。

## 2026-10-04 教学语境接续收据

作者固定fcf40a97606c148ec6dcb87a2b20dfa39100458e五显示入口仅明确全关教学/预览/静态建议/关卡背景，负ebe H138/80、R141/80 actual1→fixed H138/0、R141/0各actual0 E0/S0；六PNG核/看6、无XTest，display fixtures与原radio lateescape reference边界见[报告](AMBUSH_PR15_TEACHING_CONTEXT_20261004.md)。真实echo5第三波0.5s被写5.2s与mainhint已实际证实，另[Intel片](AMBUSH_PR15_ESCAPE_INTEL_PLAN_20261004.md)待修，不借教学green覆盖。父端a794/0bfe与radio原record3D最新限定QA归因见报告，cdb/392待独立QA。最终[统一候选证据清单](AMBUSH_PR15_UNIFIED_CANDIDATE_EVIDENCE_PLAN_20261004.md)为待执行门，旧各SHA计数不拼验收；完整FX/A3/新13波/sixnewrecord3D/APK仍待，R5/资产单写边界与耳听/设备后置不变。


## 2026-10-04 真实逃逸Intel及父端QA接续

作者fixed877decb0ea14d6c3c0a833e4d6948c7ee549514f新记忆追加保存spawn/escape事件身份及wave/local/global/playback context1，实际第三波echo5 0.5s出发/15.9s逃逸、原retry仍历史第3波；旧8参数/坏context中性回退不升级bytes，negative5ca H18/R21各8fail actual1→fixed H70/R73各0actual0 E0/S0，6物理图核/看6无XTest，49事件/快照/终端只读比较actual0，五旧native SHA不变。37证据及未验项见[报告](AMBUSH_PR15_ESCAPE_INTEL_20261004.md)，完整smoke/旧2D/统一新13波/六record3D/完整FX/A3/APK仍待。父端随后QA pwd exit0恢复、六旧包hash保持，cdb50/114/12三限定各0actual0（首814/1 actual1保全）、392原sameevent4/1→4/0/history3D41/0actual0限定关闭，无新prodP1/P2、无QA运行/阻塞；两scope不重开，fcf/877与统一candidate待独立接受，未给E/S计数不补推。资产/R5/单写边界保持、耳听/设备后置。

2026-10-04 初始单candidate a05云基线完成：官方单次PCK/hash固定，fresh六关13波原生旅程1193/0 actual0 E0/S0、六新record/自然cfg/实际credits scroll0→81/return封存166files，92图核/11图看，五旧raw不变。独立H装备66/生命周期30/时间67/旧FX30/六关reference14028各0；完整smoke actual54/ERROR1 journal模态fixture早停原失败保留。只读metadata15807/0不代六record真实3D。下一test-only修smoke流程及新记录3D→FX-A1/A2/A3→最终candidate全部门/完整normal13→可追溯APK，耳听设备后置；该初始基线不代最终FX/A3接受。详[报告](AMBUSH_PR15_UNIFIED_BASELINE_20261004.md)，R5/制作所有权/SCOUT→ALERT→SWEEP保持，不merge/生产/height/G。
