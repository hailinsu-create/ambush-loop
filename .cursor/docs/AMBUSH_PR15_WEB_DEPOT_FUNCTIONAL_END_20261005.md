# PR15 depot 作者有界功能 END（2026-10-05）

从真实depot存档完成同一新刀具attempt的两波自然SWEEP/WON、原录像完整1×/2×及radio交接/首次教学/解锁/保存刷新/安全Title。初producer请求因短波pause竞态actual1，保留原件后在原900秒预算内同attempt续完；不称所有请求全绿、第二波producer暂停检查或独立QA通过。本报告替代 [producer历史检查点](AMBUSH_PR15_WEB_DEPOT_PRODUCER_CHECKPOINT_20261005.md) 的当前RUNNING状态。

固定生产 **8532c4c3084d1a5672bbe28dc96e1c02522a8f05** / game tree **45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85**，14策略size/blob/SHA在运行前与全部END后实核保持；有界计划 **2569eeeee16520e8f8edf7de7920ffa8e7a56830**、producer证据 **f4ac6cb1f65660ede4206056b14e0c497d750f21** 已normal push/readback。本片无production、runtime manifest/loader、制作源或生成输出改动；只读QA指出的railcut计时表述另行澄清，原证据不重写。

## 来源与实际命令/退出

原profile `/workspace/.ambush-loop-env/web-fresh-native-dab-20261005`，同origin `http://127.0.0.1:12815/index.html`、1280×720/DPR1/default desktop、one-page、无fixture query。原Title实际全文核对cfg050864ec…、settings5610ba…、public checkpoint38792659…、next depot/seen=true/四关cleared/completefalse，actual0，不清storage/不seed。复用QA-v2完整Title PCK **64,662,184B/SHA f02f9042f42d5fd08f286bbecfc386295bfb20fd677413d86c1bc33ae5a99e21**；既有只读桥/warehouse bin/注册缓存差异保持，冷fixture未执行，不称production bit-identical。

浏览器启动实际命令 `python3 /tmp/pr15-web-controls/depot-native-8532-20261005/browser_controller.py`；各请求通过该controller stdin `{label,script}`，脚本在同控制目录。表中完整请求耗时由不可变回执start/end计算，不能与helper内部或callback计时混称。

| 请求/脚本 | 实际退出与范围 |
| --- | --- |
| `initialize-depot-original-profile` / `initialize.py`首loaded版本 | actual1/0.001749s：缺Path导入，Title/producer未开始；原loaded bytes封存 |
| `initialize-depot-original-profile-v2` / 补导入版本 | actual0/5.188227s，原Title配置/公开checkpoint exact |
| `produce-depot-natural` / `produce_depot.py` | actual1/406.797203s，第二波自然SWEEP前后pause后置断言失败；原phase/tick/输入/图保留 |
| `resume-depot-same-budget` / `resume_depot_after_pause_race.py` | actual1/0.941939s，原copy API拒绝非终局record；未产生partial bin、未绕过 |
| `resume-depot-original-terminal` / `resume_depot_original_terminal.py` | actual0/47.557029s；同原attempt/原时钟搜刮与撤离WON，总producer619.2766775990021s/cap900，含失败诊断时间 |
| `depot-whole-natural-1x` / `whole_depot_1x.py` | actual0；完整请求 **671.674396s**，helper内部631.0486499019898s，原输入→自然terminal callback **625.7599s**；cap1043.7s |
| `depot-whole-natural-2x` / `whole_depot_2x_full.py`+`driver_whole_full_fingerprints.py` | actual0；完整请求 **358.689574s**，helper内部321.7844062850054s，callback **316.1377s**；cap536.85s；完整内部before/terminal-after RPC指纹独立封存 |
| `depot-save-unlock-radio-reload` / `depot_boundary.py` | actual0/96.970303s，原radio交接、首次两页、任务行、两个cfg全文/public checkpoint精确reload、新刀具Continue及安全Title |
| `depot-browser-final-proof` / `finish_depot.py` | actual0/0.057187s；收尾前8原回执独立再封，原回执未改 |
| stdin `{"label":"close-depot","close":true}` | close receipt actual0、最终PTY actual0，browser/server/context正常END |
| `python3 /tmp/pr15-web-controls/depot-native-8532-20261005/run_depot_offline_audit.py` | wrapper/native actual0、20,714 checks/0 failures、ERROR0/SCRIPT_ERROR0、实际隔离守卫通过 |
| `python3 /tmp/pr15-web-controls/depot-native-8532-20261005/seal_depot_evidence.py receipts`，再 `seal_depot_end_full.py end` | 各actual0；8原回执finish前复制，最终10原回执/vault/SHA exact，14pins/原bin/旧59证据再核、全部live0/portsclosed/lockabsent |

## 同原attempt自然战斗与录像

attempt **1f32042b812907b6d833285e37ad9a5c**，原Continue刀具SCOUT，无重复教学；原取M1 Garand8/BAR20/Springfield6、手雷和唯一mine，cover1/4/5面270/270/180、原MG弹包UI；原走近cell7,11铺雷携带1→0/地面0→1，恢复部署。第一自然SWEEP12:08:08.707822 UTC/local536，原三ammo loot 2/5/2（seq27/28/29）令灰狼弹量至11；第二波原alarm于12:09:31.411000进入ALERT，短波local102自然进入SWEEP，实际pause点击已在phase5，后置paused断言失败，不是游戏FAILED。固定原失败后继续同一原SWEEP，末波原mine1 loot seq38与原撤离WON；末HP100/100/100、ammo8/16/6、灰狼携mine1、MG pack usedfalse。

八原字段终局bin：**17,939,460bytes/SHA 02a8b05a334c4c83279e01d5f0d7323265e4da540baf31a1b900eac917e4368e**，schema2/1303frames/40events/global terminal10137/local terminal639/win，validation[]，原100trusted/100engine输入。全部END后原件再核不变。原事件实际波0/1为30/10，fire13（灰狼9/BAR4）、kill4、loot4、spawn4、no_engage13、door1、terminal1；**mine0/repack0**，不把铺设、末波mine搜刮或包未耗尽当触发/补弹专项通过。原结果图为中性“油库封锁完成”。

两轮均原Replay/pause/speed/真实slider Home/resume，自然0→10137，无手动set_tick补whole；1278/644观察行单调、attempt/rate固定、逐行view_tick=replay tick，实际terminal 3D各 **15checks/0failures**。原record/domain保持是当轮helper断言；2×完整内部before/terminal-after指纹也实际封存并在END后独立比较domain/record/校验结果相同。**1×内部开始前和terminal-after完整RPC指纹未各自落盘**，保留原packet、断言、全观察流和返回WON后的完整fingerprint，不回填；独立QA如需完整指纹应另开新轮，不能当本轮原件。

callback比例 **1.9793903099820112**，原录制模拟时长168.95s，软件WebGL实际仍慢于模拟，非FPS/帧预算通过。原ArrowLeft/Right保持暂停、Space回原WON另列。1×自然过程中实际截到保存的第二波ALERT，图前后wave1/phase1、tick6447→6504均playing=true、viewtick对齐，未暂停/seek；该图已看，只是原录像视觉，**不能代缺失的第二波producer paused-ALERT图**。

纯reader逐帧核1303保存frame的身份/单调全局时间/level/wave/phase、supported pose、只读ViewState完整actor值及事件cutoff、原序列化bytes保持，20,714/0；原local tick reset1，保存阶段0:0=571、0:1=91、0:5=171、1:1=18、1:3=1、1:5=451。离线set_tick仅原件reader契约，不代whole或逐帧renderer。

## 保存、回执与生命周期

原WON Continue→radio handoff/CTA→首次教学0/1两页→Title全部六关可出击（前五cleared，radio未clear）→sameorigin reload全文两个cfg/公开checkpoint exact→原Continue新刀具SCOUT且无重复教学→安全Title。未生产的教学preview **212d3ec4573e30624dec0240b908b7ba** 与刷新后preview **1617ef2a49dd96c302a656dae3e66d1a** 分列，不拼进depot录像。最终next radio/index5、complete=false、前五各loop1/perfect；cfg SHA **83fe9ff9f602c229851615c760919f31f437f2ace37cd23e5adc244adee9955c**，settings **9301c4e5a6be0d02e8d4274e92cad786790dce801903f7cbb330686757fefa0e**，公开checkpoint **14052356db56d3ebc0f87c3a6825999bc70ae1ea9db03415bdea62e57db36d77**。仅原教学新增seen_radio；音量1/mutedfalse/force_touch_hudfalse/standard保持。最终150+10 trusted/engine各160，console error0/pageerror0/GL invalid0、原ReadPixels warnings4保留。

controller exec使用独立runtime字典、请求/receipt在main局部，每次执行前保存request和loaded脚本SHA，完成立即exclusive-create原receipt/vault副本/内容SHA；重复label拒绝。收尾前外部utility再复制8原回执，END后全部10回执/逐份seal/vault/预收尾副本/producer固定原件重核 exact。本片boundary/finish/close各有独立原回执，没有二次改写endpoint。3个方法actual1均原样保留；旧railcut原boundary/首finish独立回执缺失与endpoint损失不补造。

WINDOW_START **12:01:16.248288** / ENGINE_START **12:01:17.739678 UTC**，唯一PID160947/session19685/12815、one-page。安全Title后 browser END **12:35:47.245912 UTC**、最终PTY0；随后才独占native原bin审计 START **12:36:20.563246** / END **12:36:23.536551 UTC**、actual0、unique private user://守卫。最终engine/browser/server均END、live0/12815与12816closed/profile lock absent；没有关闭非自有Xorg或其他资产工作者环境。窗口已归还。

## 封存范围与下一包

producer [manifest](evidence/20261005-pr15-web-depot-producer/manifest.json) **59数据文件/23,984,722bytes**（f4ac6cb固定，7原PNG）；最终 [manifest](evidence/20261005-pr15-web-depot-functional-end/manifest.json) **75数据文件/10,916,494bytes**（全部此前活动driver/HTTP/controller日志、原请求/loaded脚本/退出、2×完整指纹、whole/保存/生命周期、8预收尾回执、native原件结果、10新PNG）。逐文件size/SHA实核；共17原PNG实际逐张已看，无图同名覆盖。manifest本身不计数据文件数，原17.9MB录像引用固定producer包，不制造新record。

生产8532/tree45b/QA-PCKf02保持，私有Site v3无重复部署，Draft PR15/open/unmerged，不merge/生产发布/高度规则/APK。资产工作者仍独占角色源/generator/atlas/GLB/Blender，版本化manifest/clip/socket/LOD接口保持，无制作件或WIP接入。只读QA对旧171证据/32图/2628观察流的限定结论单列，不升独立引擎验收；railcut完整请求516.087025/276.847443s已澄清，pump最终PTY未知/冷before-domain未全存、父QA143/1/PCK+128B/旧PNG损失继续保留。GPT PLAN/REVIEW unavailable。

原剩5波本片自然完成depot2，下一真实radio存档仍需3波；先处理短波pause驱动判据，使用新有界包，不改规则。yard当前whole、同候选正常13/全6×1×2×/A3实速/fullsmoke/FINAL/世界touch与锁门/正式origin/耳听/设备/APK未验。父端接回窗口后可独占安排原bin引擎语义与railcut隔离1×2×完整指纹最小QA，未启动它；只读源码/策略/已封证据可独立并行。当前无新确认的产品阻碍，方法缺口与独立QA尚未解决，不能称全计划或性能通过。
