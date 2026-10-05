# PR15 REPLAY重复touch刷新最小候选 END / 独立QA交窗

2026-10-05，依[启动前合同与逐次方法修正](AMBUSH_PR15_REPLAY_TOUCH_CANDIDATE_EXECUTION_20261005.md)完成。测量依据[子诊断95ddfad](AMBUSH_PR15_HUD_SUBSEGMENTS_END_20261005.md)。固定产品候选 **95daa05d0ccfc4e6bd357060b1f34c2a863c2041 / game tree e331ee32dfa61f8b7143d3af89715ba0f3d0cc32**，A=1ec3198e9c0db367af96fc264604c5a286003b5e/tree1e8af45ee23098f763acc139b56f8f7e0f41665a。仅main.gd三行新增/一行替换：REPLAY保留ensure内部touch刷新，省相邻第二次；不加frame/style缓存，其他phase调用不变，规则/资产/manifest/loader无变。

**局部重复工作消除已证实，净整帧稳定收益和A3未证实。** B正式两轮均getter8→7、touch2→1、style50→25，最终原UI/frame/装备/骨骼合同一致。推进postdraw中位两pair −1.1863%/−0.8894%，但B的p95均更差、重复漂移约1%；不能只报中位或称唯一瓶颈/30或60FPS通过。原44a034首P0超时与混合OFF/ON扰动保留。Site仍v4/1ec；本候选未部署，独立QA未运行。

## 原生实际结果及限制

原生pure A/B runtime tracked953文件逐SHA核，唯一差main；45个import sidecar另核A/B等价，消费stage不含非runtime原blend。原生各门独立UUID/actual Guard/Dummy，必要共享门经run_isolated_test.sh；每门cap60。命令/argv/真实Popen退出及原日志在[native manifest](evidence/20261005-pr15-replay-touch-native/manifest.json)。原结果不靠退出码映射或“checks打印OK”替代。

| 实际消费者或门 | 实际结果 | 限定 |
| --- | --- | --- |
| pure A/B final HUD oracle | 两侧226检查/0失败/30场景/actual0，32.4047与27.9458秒；两侧raw JSON SHA均1c32fcbd2b915daf276c654e56417cb7583d6faffe574db6f15fd2b098a54136 | 官方--fixed-fps60控制fixture回调/动画，场景首处理前freeze；最终全控件style/font/text/rect/visible/disabled/modulate/历史frame/20bones/socket严格equal，无Tag/FlashLabel字段排除；非自然whole/性能 |
| 原presentation_contract | 84,048检查/actual0/E0/S0，51.3648秒 | 现有受控核心历史门 |
| 原equipment_freeze monolithic | **cap60 timeout/actual−9**；晚到66 OK不计通过 | 初runner只kill父bash，子引擎/tee后来已Z；已核关闭，不能称安全END在60秒内；后续runner用自有process group关闭 |
| 原设备冻结断言partition | 18+18+18+12=66 unique原断言，各actual0/E0/S0，43.3384/42.8414/43.7887/23.6327秒 | 原fixture/handler/assertion，只有state列表与legal tail分组；合计153.6012/240；ALERT/暂停ALERT/REPLAY拒绝、SCOUT/SWEEP合法；**非原monolithic时间过** |
| 真旧schema1 reader | 17检查/0失败/actual0/E0/S0，7.0328秒 | 原1de456 bin，三选帧、旧HUD、FX中性/当前clock毒化/containers与档案未升级 |
| 原source-text monolithic | 初入口缺fixture配置actual1；配置后**cap60 timeout/actual−9**，整组全关 | 原参考producer所在整门未完成，原因成本未独立计时，不把它说唯一原因 |
| 原记录source-text消费者变体 | 374检查/0失败/64自然callbacks/actual0/E0/S0，40.5255秒 | 继承原来源/事件文本/聚焦/1×2×自动回调/重绑定断言；只_prepare改为原e850 schema2 yard，现代标签original_yard；与原1de456 schema1双向绑，不重打producer，非reference生成通过 |
| 原command_pose_clock | 28检查/0失败/actual0/E0/S0，23.5393秒 | SCOUT/SWEEP移动、历史姿态时钟 |
| 原rendered presentation_lifecycle | 32检查/0失败/actual0/E0/S0，46.1713秒 | 原Back优先背包、取消生命周期/回放输入/聚焦圈；两PNG逐张目检，受控render fixture，不是战场/设备接受 |

原生总窗口最终END **18:37:13.497435 UTC**。helper修正失败原件（Parse、过宽full visual snapshot返回断言、无active属性SCRIPT_ERROR+cap、不同场景/动画时刻的严格UI差异、未成立hidden Tag排除reader）全部保留；最终A/B全字段equal由第八次受控调度取得，不抹平早期失败。full visual snapshot返回只允许明确既有slot-null现场visible true→false，所有其余字段及原containers/完整cfg核同；不宣称整个snapshot完全不变。三个FX source instance tokens先逐个断言实际绑定源，再在跨引擎A/B输出移除；attempt/wave/seq/tick/装备/历史身份保留。

原生证据 **131文件/11,227,062B**，十份大raw JSON仅gzip无损存储，原bytes/SHA与每份roundtrip exact保留，未覆盖原件。native manifest范围已明确为对应消费者行为断言通过，两个原monolithic时间cap仍失败，不能绿成全部原共享suite。

## Web fresh ABBA实际流程

实际命令 `python3 /tmp/pr15-web-controls/replay-touch-abba-95daa-20261005/supervisor.py`，导出→pack audit→fresh A P0→A B B A→各Space返回原WON→owned END自动连续调度。START **18:38:35.533252** 至END **18:46:54.943698 UTC**，**499.410443/600秒**（含冷启动、输入/指纹、所有idle、4次context关窗）；工具session42652最终actual0，supervisor browser实际0/E0/S0/无timeout，ports12815–12817 closed/live Godot+Chromium0。引擎窗口已交还，后续仅离线读/封存。

首P0总起点后 **81.051696/120秒，actual0**：共同OFF static负count/natural advance A真实8/2/50正count、同canonical/完整指纹中性。原子诊断两个ON真实计时/ON→OFF reset仍引用原件，本性能A/B不另加ON profiler。正式共同OFF固定2048×30池，保lookup/branch/depth/count/sampler，Time字段0表示disabled；B减少调用也会减少随调用的OFF仪器工作，不能将配对结果当无仪器生产CPU收益。

仍原dab yard **e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5 /19,025,696B/1622frames/30events/t12678**，paired saved consumer；producer/consumer A/B分列，无新胜利。静态6339/wave0/frame792/recorded SCOUT、空隐藏event list；官方4.7.2/Compatibility/WebGL2/Dummy/1280×720/scale1/standard/yaw35/pitch55、ANGLE Vulkan1.3 SwiftShader Subzero。不同自然推进实际tick范围如下，不称逐行同轨迹或全13波。

| RUN | 正式wall s | static/advance rows | advance tick范围 | static median/p95 ms | advance median/p95 ms |
| --- | ---: | --- | --- | --- | --- |
| A1 |72.953145|49/47|6434–6802|405.2/456.9|429.9/459.7|
| B2 |73.494886|50/47|6435–6803|401.1/423.7|424.8/491.7|
| B3 |73.135203|49/46|6434–6794|404.7/429.2|429.05/509.9|
| A4 |73.627797|50/45|6434–6786|400.9/417.9|432.9/489.2|

每正式run<90，static/advance各warm2/collect20，≥12样本，无overflow，采样窗无RPC/输出/截图/磁盘；after flush才全指纹、canonical和截图。static子calls0；advance每个正式A样本8capture/insideHUD8/touch2/style50/insideTouch capture2，每B样本7/7/1/25/1。root/HUD inclusive时间本轮OFF不计；不重复将子诊断约45% touch累计HUD区间或约90% HUD累计root说成全帧。

静态相邻B/A中位 **−1.0118%/+0.9479%**，A/B重复 **−1.0612%/+0.8975%**，方向混合；静态没有root/HUD调用，不能归因这个省调用。推进中位 **−1.1863%/−0.8894%**，A/B重复 **+0.6978%/+1.0005%**；p95 B491.7>A459.7及B509.9>A489.2，不利尾部全保。净稳定收益未建立。**383个postdraw间隔全超33.333ms/16.667ms，SwiftShader的30/60FPS目标仍未过**，不以wall减inclusive给GPU。

四轮前/后/Space返回WON原record/domain/完整settings cfg/public checkpoint exact；自然tick单调、view_tick=tick、装备/frame/20骨/socket无fail；static整个canonical含最终touch styles/UI严格equal。**4 PNG逐张目检且921,600 pixels/每pair changed0**，RGBA均898200abef16404997ecf1254d0b2c4c7eebf10e1151ca0b63bb5ecac81fd718，与前diagnostic canonical相同。**98 DOM全isTrusted/98 engine**，console/page/SCRIPT/ERROR0；每context4个ReadPixels警告共16保留，不称无warning。普通Web source切换可达性未由这些控制fixture证明。

两个cached官方QA exports实际0/E0/S0；973payload全部MD5核。A **57,147,116B/PCK SHA21b5c1050583c073b4e8fefc2ef656ffa6d68c97fb04c85b9a37abc310058b64**，B **57,146,748B/SHA501fb33b93fa4367421c6712bbcbd2d7cbfa43446953bb9f3d511f3d3d6ca19c**。相对封存sub-QA共同只改observer.gdc（额外只读最终touch属性）；A/B只改main.gdc，metadata/assets其余payload全部字节同。每实际加载helper先复制，END逐字节核冻结控制一致。

离线 `analyze.py` actual0，[Web evidence manifest](evidence/20261005-pr15-replay-touch-abba/manifest.json) **119文件/7,471,482B** 全bytes/SHA核，original requests/receipts/immediate vault/全部raw/四PNG保留，不重复原bin/PCK。分析与封存均在owned END后，未续开引擎或扩600预算。

## 独立QA与其余待验

下一由父端独立QA读固定95daa及完整正负证据，优先实际最终HUD/来源切换/输入/保存合同、两原monolithic cap失败范围及不利p95/重复漂移。可复用native pure stage `/workspace/pr15-replay-touch-candidate-95daa-20261005` 与QA Web A/B artifacts `/workspace/pr15-web-artifacts/95daa05d0ccfc4e6bd357060b1f34c2a863c2041/touch-abba-qa-20261005/`；后者有声明observer/原bin/paired cfg，不是production export或新producer。候选production release新包未导出、独立QA未过；独立合格前不重复发布Site。

archive授权下载失败路线停止，原因未知、server hash差/origin身份门未填；不得换路绕403或以本地32/0代替server。最终samecandidate六关13自然波与六whole、完整旧schema1 whole、fullsmoke/all-art/人工听感/最终A3/APK仍待，模拟器/真机保持全部计划之后。支持范围不是最终完整战场/设备性能接受。

资产接口保持R5既有20骨/weapon_hand/socket/3LOD/52语义与已验交付，未修改/重跑ArtSource v2生成脚本、共享atlas/角色GLB/Blender/音频/六关场景；本片无新增资产包请求。PR15仍独立Draft，不merge、不生产发布、不混高度射击分支。
