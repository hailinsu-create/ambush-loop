# PR15 最终候选剩余验收矩阵与合批顺序

2026-10-05最新：[首绘制反证/撤回touch候选END](AMBUSH_PR15_REPLAY_FIRST_DRAW_END_20261005.md)。父端95daa QA严格同步E6/首process后隐藏layout E3、帧收益不稳，原失败保持。native原按钮首postdraw反证UI/17对像素一致但完整raw state29差/strict实际1且Web范围未覆盖，不称候选接受；固定撤回产品b74f1fc/tree1e8与1ec产品树精确same。下一旧真实mine/repack原件呈现；不继续同类小优化，不部署Site仍v4；既有1ec历史证据按原范围沿用，不为docs/撤回同产品树重打旧producer/whole。完整QA包路径仍待。

2026-10-05追加：[最小REPLAY touch候选END](AMBUSH_PR15_REPLAY_TOUCH_CANDIDATE_END_20261005.md)固定runtime95daa05/tree e331，较下文基线1ec仅main省相邻第二刷新；已有producer/whole cohort不拼成此候选最终13。已完成有界子诊断与fresh ABBA/原消费者最终HUD等价，源码调用2→1/style50→25；不利p95、约1%漂移与两原monolithic cap60失败保留，两个对应行为变体通过，不称原时间门通过。owned engines/browser END18:46:54/live0，下一父端独立QA；production release新包/Site更新尚无，独立合格前不发布。原samecandidate13/核心fullsmoke/全艺术/听感/A3/APK/设备与archive身份门仍待，下文历史入口保留。


2026-10-05。父端已读 radio 作者完整终态 `6cbb71ade950238f9a55e1f2ec8c4c3285980cb4`，接管唯一引擎窗口，独立验证 `1ec` 普通回放存档修复及真实刷新/关闭重开。**本片只有只读盘点、文档和未运行 spec；没有启动 Godot、浏览器、HTTP、导出、采样、音频或设备，也没有新增功能、资产、部署。必须收到父端 QA END 与明确归还窗口后才执行下一包。** 时间流逝、agent idle 或旧 END 不代表归还。

盘点对象的产品 source 为 `1ec3198e9c0db367af96fc264604c5a286003b5e`，game tree 为 `1e8af45ee23098f763acc139b56f8f7e0f41665a`。它是当前候选，尚不是全部门通过的 FINAL。后续 docs HEAD 与实际运行 source 分列；QA 若产生产品修复，先锁定新 source/tree/PCK，再启动受影响包。继承[执行 v2](AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md)、[统一候选契约](AMBUSH_PR15_UNIFIED_CANDIDATE_EVIDENCE_PLAN_20261004.md)和[同候选/FX/A3计划](AMBUSH_PR15_SAME_CANDIDATE_FX_A3_PLAN_20261004.md)。本文更新剩余工作顺序和证据复用方法，未降低原验收门槛。

## 本次实际只读核对

`python3 -` 读取既存 producer JSON/manifest、计算六份原 bin 的 SHA256/bytes，并用 `git rev-parse <source>:<path>` 对照 A3 metadata consumer `a42ea2d7b50e79ee4a954ec9859a7281c577c174` 与当前 `1ec` 的十八个源 blob，**actual exit0**。六份 bin 共 **104,359,464 bytes**，全部与原 manifest 及 producer receipt 精确相同；十八项中十六项相同，仅 `main.gd` 和 `presenter_3d.gd` 不同。具体路径和完整 blob/SHA 见[只读 inventory](evidence/20261005-pr15-final-acceptance-readonly/inventory.json)。本次没有重新解码 bin、播放、渲染或生成任何 runtime acceptance。

文档/spec静态校验先因二进制浮点精确相等断言 **actual exit1**；`6*(12678/60)+30` 实际为1297.8000000000002，十进制预算1297.8未错。保留[方法负例](evidence/20261005-pr15-final-acceptance-readonly/static-exact-float-negative.json)，以绝对容差1e-9比较后[静态检查actual0](evidence/20261005-pr15-final-acceptance-readonly/static-plan-checks.json)，`git diff --check` actual0；[manifest](evidence/20261005-pr15-final-acceptance-readonly/manifest.json)封四份JSON/17,134bytes。未修改预算、原bin或运行receipt，静态检查不计Godot测试通过数。

相同项包括 operator、landmine、weapon catalog、asset library、ViewState、shot/tool FX frame/pool、BattleLog/ReplayPlayer/VisualSnapshot、shot/tool recording、audio director/assets。这说明这些模块的历史有界证据可在原范围内复用，**不说明跨模块最终集成已经通过**。A3 后 presenter 新增 Web 旧 canvas 隐藏与日志/镜头布局；main 还涉及 Web storage 和已结算 WON replay 保存保护。旧 A3 数字不代表当前画面负载，旧普通存档行为不覆盖新修复。相对 `f0d97457faa81b94a51cae12c40e07987267c738`，当前产品新增变化只有 `_save_progress` 的 WON replay guard；后续 radio 提交没有再改产品。

索引/PR 里 radio 2×完整请求墙时 `295.778995s` 是抄写误差，本片更正为原 END 表的 **295.779271s**。helper **257.061855s**、输入至自然 terminal callback **250.603400s** 不变；原 receipt、manifest 和计时结果不修改。

## 已覆盖与剩余门

| 门 | 已有实际覆盖，保留其范围 | 仍需执行与原因 | 可复用/失效边界 |
| --- | --- | --- | --- |
| 1ec 普通存档修复 | 作者普通 WON→Replay→M→Title→Continue，旧源回 warehouse/新源入 pump；canonical URL 真刷新各 actual0。paired 回归旧15/2→新15/0，config store22/0；radio complete profile 的刷新与有限重开另实际通过 | 父端正在做同修复的独立普通刷新/关闭重开；**作者 M 场景关闭重开未用 radio complete 重开替代**。冷历史首 Space 的结算侧效与普通已结算胜利分列 | 不重跑已封负例。只补 QA 实际范围；未拿到的父 QA4a4b 完整包不能冒称本地全文收齐/验收。若修 main/storage，再跑对应普通路径和保存门，不自动重跑全部资产专项 |
| yard whole | fresh Web 原输入两波450/225自然 WON；bin `e850…`、schema2、1622frames/30events/t12678；解锁/真实 reload/reopen 有证据 | **这份原件完整1×/2×从零自然至 terminal 尚未运行**。下一有界包补 current consumer；不为补 consumer 缺口重打424.705秒 producer | 原 dab producer/bin 可原样绑定 current consumer，标明两端不同 source。旧 INITIAL 2×及其他 yard fixture 全播不能替这份原件 |
| mine/repack 自然专项 | 旧正常 native warehouse 真 mine，旧正常 railcut 真 Kar98k 耗尽→same_weapon repack（wave1/local58/seq28）；A2 source/reader/pool 受控正反例另已通过。近期 Web radio mine/repack/throw0，MG未开火，depot 也不能据放雷宣称触发 | 冻结候选需要普通输入产生并封存实际 mine victim/HP/库存/事件，以及真实最后一枪、ammo0→start_ammo、used false→true、same weapon 的 repack。优先把两个案例纳入最终 fresh 旅程的合法阶段；若先做独立战术包，明确进度来源与隔离 profile | 旧自然原件可用于 current consumer 的事件/FX/回放验证，仍是旧 producer。fallback pistol `weapon_switch` 不代 same_weapon；放置不代引爆，接口 fixture 不代自然操作。源/策略未变不重打所有旧自然反例 |
| 同最终候选六关13波 | 旧 a05 fresh native 六关13波；最近 Web 六关链来自 dab、8532、1ec 三个 game tree。radio 1ec 三波及完整1×/2×、credits、complete/save/reload/reopen 已有严密功能证据 | 必须在最终 source/PCK 收敛后，一份新 fresh 存档从原标题/首次教学一路六关13波、自然 WON/CTA/存档/致谢。当前旧五关加新 radio **不能组成同最终候选 cohort** | 原分段旅程保持已验，不推翻；最终 radio 再跑是“同一 fresh cohort”契约所需，不是此前 radio 无效。docs-only 或完全相同 game tree 不产生新重跑理由 |
| 六新原件完整3D | INITIAL consumer d9c 六件完整2×、76seek；近期 warehouse/pump/railcut/depot/radio 各原件1×/2×功能已实际跑过，radio 1ec 完整前/terminal/返回WON指纹已封 | 最终 fresh 六件要各自产生、原字节先封，再在同最终 consumer 完整1×/2×、多波/阶段/事件聚焦、暂停/seek/退出/换源及记录/模拟域不变。可按每关 WON 合批消费，避免后补 loader | 既有五件不用为“历史补绿”全部重播。历史内部指纹/receipt缺口如 depot1×仍保留；不能拿新截图回填旧时刻。metadata不代3D，终点骨架检查不代所有帧/像素 |
| 装备冻结/生命周期/共享集成/fullsmoke | ALERT/paused ALERT/REPLAY拒绝与 SCOUT/SWEEP合法、Back先关包、touch cancel/focus、连续 command、六关 reference 等历史专项有证据；完整 smoke 历史实际exit54/62失败，仅8906有界合同fixture修正 | 最终候选跑一次核心共享组合及**完整 smoke**，封独立 Guard/命令/actual exit/E/S；正常13波与 reference矩阵分列。测试若失败，保存反例、修最小源、重锁并重跑影响门 | 不重复29个历史 run 仅因新docs SHA。只读相同 blob 可支持沿用各负向边界；最终跨模块集成、未曾完整通过的 smoke 仍不能省。不同模块变更按触发/调用链决定影响，不按“所有旧测试名”机械重跑 |
| 呈现/艺术 | R5角色/武器/20骨/socket/LOD、尸体配对、HUD/日志、A1枪火池、A2爆烟/移动cue均有有界作者证据与部分父独立限定QA；radio/depot 原画面已查看 | 最终六关实际窗口：必要桌面/触控尺寸、近景握持/接触/遮挡、各阶段/HUD、历史事件FX/跨波，逐图记录所见与未见。旧 A3 depot/radio FAILED 近景裁切仍是整体呈现待验输入 | 用完整旧 mine/repack/shot/throw 原件取得 current renderer 同一事件画面；不重新做资产 turnaround。dust是保存pose确定性cue，不是新增落脚事件/持久尾迹。合成场景通过不叫全战场艺术接受 |
| A3性能/优化 | a90 六关13 reference波原23559/0、650segments/60图、云 frame budget超限；A41ff/Ba42八轮 ABBA/BAAB全0，窄metadata优化方向混合、无稳定收益；软件 functional 倍速成立 | 先 current source 最小热点能力门与 OFF/ON/ON/OFF 采样，定位后才决定单片优化；同输入域行为/画面 parity 与配对比较。收敛后最终六关/六phase、标准/省电/代表方位/实际峰值和持续样本预算门只跑一次，样本规则启动前固定 | 重用旧原件和 canonical frame/装备/镜头作为 consumer workload，不为每个A-B再重打13波。旧仪器方法/边界可复用，但新增 runtime profiler能力/开销不能推定。GPUtime unknown、llvmpipe、短样本不叫手机30/60FPS。预算未达即保持失败 |
| 人工听感 | 45 WAV/import与路由、ALERT duck/pause/seek/lifecycle、Dummy 实际非零有限 PCM 工程验证405/0；旧captured mix可用 | **实际人工0/45 cue、0/6声景**。最终真实事件声景交人工，逐条记录听过/未听、遮蔽/失真/音量/loop seam；不以源码/波形/日志代耳听 | audio源相同可复用工程录音/路由证据；听评需绑定最终文件hash与实际混音状态。当前不启动音频，也不伪称工具能给人工判断 |
| 可追溯APK/设备 | 有历史 A0 APK 与工程 preset/工具链只读资料；不是本最终六关全游戏 APK | 云端全部授权阶段完成后，按同最终 source/tree/制作revision/官方引擎模板导出APK，actual命令/exit/package/version/ABI/PCK/APK hash及签名核验。其后再讨论/安排模拟器和真机、持续帧率/热/暂停恢复/触控 | 历史A0包、工具存在、云软件renderer不能替代最终build或设备证据。不提前测设备、不merge、不生产发布；本片不安装/导出/部署 |

## 原记录复用台账

下表元数据取原 producer/END 报告；本次只核文件字节/SHA/producer receipt 一致，没有新运行。完整路径/完整SHA/attempt在 inventory。producer source 表示生成记录时的产品，consumer source必须在后续实际绑定时另写；把旧 bin 交给新 consumer 不会生成新候选 producer 记录，也不得将旧 attempt/wave/seq/event挂到当前run_id。

| 原件 | producer source | bytes / SHA前缀 / terminal | 已有 whole | 当前合理用途 |
| --- | --- | --- | --- | --- |
| yard | dab8705 / tree4f49 | 19,025,696 / e850bb81 / 12678 | 此原件1×/2×未跑 | 下一 current consumer 原件完整回放 |
| warehouse | dab8705 / tree4f49 | 26,554,792 / 28c90902 / 16102 | 两速actual0；旧中央日志遮挡独立8532修复 | 历史兼容/当前事件或性能输入，不无端重打producer |
| pump | 8532c4c / tree45b8 | 11,203,052 / a0e5b232 / 6178 | 两速actual0；cold consumer与原campaign分列 | 历史consumer复用；旧producer最终PTY未知/部分指纹缺口保留 |
| railcut | 8532c4c / tree45b8 | 15,373,004 / b50e1f11 / 7610 | 两速actual0；父最小完整指纹QA另列 | 历史consumer复用；原作者receipt endpoint损失不重构 |
| depot | 8532c4c / tree45b8 | 17,939,460 / 02a8b05a / 10137 | 两速actual0；2×完整内部指纹封 | 1×两个内部指纹及wave1 producer paused图缺口保留；最终cohort补自己的证据 |
| radio | 1ec3198 / tree1e8a | 14,263,460 / fd78f1f5 / 7390 | 两速actual0；完整三时点指纹/935与473行/终点15/0 | 当前候选正常3波、whole与complete路径可直接沿用有界结论；fresh最终cohort契约另需新记录 |

真正旧 schema1 yard 原件 SHA `1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12` 的历史兼容消费保持；最终包补一次有界旧原件实际加载/播放和核心缺字段回退，别每个阶段重复旧全集。若仅docs且reader/blob未改，不产生新兼容重跑义务；若reader/loader/schema改变，按受影响契约补负向边界，旧原bytes不能升级。

## 合批与顺序

1. **父端1ec save QA END→归还窗口**：读实际source/原回执/结论及剩余范围；如有产品修复，先最小复现/修复/对应回归。未归还期间只有本只读计划。
2. **yard 原件 consumer 包**：只补此19MB bin的完整1×/2×，同包完整指纹/少量原事件聚焦/Space返回/只读audit/安全END；不夹其他五关producer、热点采样或资产生成。
3. **呈现/性能收敛与自然专项准备**：拿现有原 bin 作 current consumer workload，执行已有[热点有界方案](AMBUSH_PR15_A3_HOTSPOT_DIAGNOSTIC_PLAN_20261004.md)的最小能力/开销门，先实测再优化。用旧真实 mine/repack 原件补 current 事件画面并只读筹划合法自然战术。仅实证缺陷才写功能修复，资产问题交独立资产作者。诊断、必要优化、对应parity/QA在昂贵最终fresh13前结束。
4. **一次冻结最终candidate**：source/tree/官方4.7.2/PCK/QA增量/制作revision/环境/输入driver都固定。最终fresh六关13波普通操作优先包含 mine/repack 两个合法自然案例；发生即封，不为相同事件另跑重复专项。若策略未触发，标未覆盖，再限定独立自然案例，不能强造事件。每关WON封原件、全文cfg/settings/checkpoint，原Replay完整1×/2×可在该WON合批；确认返回幂等再原CTA继续。若WON回放影响后续旅程，拆consumer，仍引用同一新原件，不重做producer。
5. **最终集成/持续A3/独立QA合批**：同source核心共享组合、完整smoke、six新consumer缺口、真实旧schema1、必要UI/全艺术矩阵、六关A3正式门，只补未被本cohort实际满足的格子。失败保留；产品变化重锁候选及影响门，docs/evidence变化不重开全部旧门。尚无稳定优化或预算不达，明确A3未完成，不能以“测过”关闭。
6. **APK追溯→人工听感/设备后置**：最终云端门完成才产全游戏APK，提供审核用hash/签名/ABI链；再按用户“全部计划后再讨论模拟器/真机”的顺序交人工听评及设备包。独立人员可先只读评审已封帧/音频文件，不占本引擎窗；当前不新派agent、不部署。

本次不建议重复 warehouse/pump/railcut/depot/radio 的旧producer和旧whole、A1/A2所有负向fixture、A3每个早期仪器轮或资产library全套，只因docs HEAD改变。必要的重跑理由是：缺失门、被改代码/运行包实际影响、最终fresh cohort要求、最终当前负载或真实设备差异；不能把历史不同source的计数相加当最终接受。

## 下一有界包：yard whole1×/2×，未运行

[机器spec](evidence/20261005-pr15-final-acceptance-readonly/next-yard-spec.json) status 为 `NOT_RUN_WAIT_PARENT_QA_END_AND_EXPLICIT_ENGINE_WINDOW_RETURN`。候选暂指1ec/tree1e8，收到QA返窗后再核，不自动视作已获接受。

- 输入：原 `.cursor/docs/evidence/20261005-pr15-fresh-web-yard-pause/run/yard-record.bin`，**19,025,696 bytes / SHA `e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5`**；attempt `93a9671c444c749f102a04a728c963a5`，schema2/win/terminal12678。旧 producer为dab/tree4f49；新consumer另锁，不重跑原producer。
- consumer专用新UUID/profile，保留真实已complete的原campaign profile不写。现有cold fixture只支持warehouse，**不能换路径就宣称yard已加载**；下一包需要明确声明yard-level loader、绑定八原字段、QA-vs-production payload增量和配对已结算WON cfg。此轮没有写或导出loader。配对后Replay/Space/cfg须精确；若采用未配对cold WON，首Space结算是明确侧效，不能宣称全程存档隔离。
- 标准完整请求预算：`max(180,6*(12678/60)/rate+30)`，**1×1297.8秒、2×663.9秒**，UI转场120秒。原Replay/Home/pause/选速/resume从0自然到terminal，未用seek终点/directtick/force win补绿；各rate独立request/helper/输入至callback墙时，不称性能接受。cap失守保留失败，不无限续时或重置总预算。
- 每速保存resume前、自然terminal、原Space返回WON后的完整record/domain/config指纹；原attempt/wave/seq/global/local/event identity与view clock单调对齐，source/live隔离。实际20骨/装备/位置和事件聚焦只对采样边界作断言，不冒称每帧每像素已审。先封原件SHA，再消费；不重绑旧event为新run。
- request/helper/owner controller均独立不可覆盖的START/END/vault；PNG逐图核对，全部命令actual exits/E/S与未知项分别报告。浏览器/controller END之后再经isolated Guard执行原bin只读native audit，最后收齐自有窗口END，交父端独立QA。不会信号/结束父端QA进程。

自然专项的策略准备是source推断，未实际复现：mine需活跃存活敌进20px真实调用sim_check/伤害120；SWEEP可合法调面向/站位，不能授雷/改敌/传送/手调sim_check。`_begin_next_wave` 会对HOLD队员无条件 `arm_ambush()`，所以“设HOLD就能拖住下一波”不是有效策略。repack需真正最后一枪耗尽后 `_try_ammo_pack`，MG42箱50发/少量敌不保证耗尽；优先低容量已合法取得的武器，考虑真实落弹补充和其他队员击杀。实际策略、独立attempt/cap/失败退出先封后跑，不预报必然命中；可在最终fresh旅程实际触发则直接复用该case，无需额外再跑。

所有权不变：唯一主集成作者负责 main/presenter/ViewState/replay/shared tests/runtime manifest-loader；R5 source `29749157c5db064bfea626c3ed9d75d9a1791ece`、交付 `ebedb829e3263abbeb6dd266905f24a3869fa281`，20骨/socket/3LOD/52语义接口保持。制作作者独占源/生成器/共享atlas/角色GLB/Blender；不编辑或重跑、不全并WIP。本片不产生新资产请求。PR15保持Draft，不merge、不发布生产，不混高度射击PR4–6/13/16。网页GPT PLAN/REVIEW unavailable。

2026-10-05 接续：父端1ec普通save限定QA END并归还窗口，两个favicon controller exit1保持；本矩阵的yard原件缺口现已由[05469 consumer END](AMBUSH_PR15_YARD_WHOLE_END_20261005.md)补齐自然两速/三时点指纹/native24690/0，未重打旧producer、不生成新最终cohort。随后新增明确同私有站更新授权，现[Site v4成功/ACL exact](AMBUSH_PR15_PRIVATE_SITE_V4_END_20261005.md)；原表未来Site/QA等待状态为当时盘点，当前以这两个END为准。下一[有限HUD分段计划](AMBUSH_PR15_REPLAY_HUD_SEGMENT_PLAN_20261005.md)未运行。其余最终fresh13/自然工具/fullsmoke/A3/all-art/耳听/设备/APK及server archive/正式origin PCK仍待，不因为上述两包完成而全计划接受。

2026-10-05 再接续：[HUD有限测量END](AMBUSH_PR15_REPLAY_HUD_SEGMENTS_END_20261005.md)原1ec consumer6339/792/SCOUT四轮OFF ON ON OFF各0、总561.11/600秒已END；HUD区间累计root90.12%/89.53%，postdraw推进ON/OFF−2.07%/+0.57%且OFF漂移−2.46%，净开销/具体子热点仍未确定，385间隔全超33.333ms。首P0超120秒actual1与补充方法门0、pack prefix负例1→0分列，六静态PNG RGBA exact/完整状态保存/139件证据，不是最终A3通过。下一[子诊断与条件scope-frame候选](AMBUSH_PR15_REPLAY_HUD_CAPTURE_CANDIDATE_PLAN_20261005.md)未实施/运行；生产source/tree/资产/Site v4不变。独立只读get version成功，但授权server archive下载实际无法授权或解析；本地32/0不填server成员/正式origin身份门。其余同最终候选13波/自然工具/fullsmoke/all-art/听感/APK/设备仍待。
