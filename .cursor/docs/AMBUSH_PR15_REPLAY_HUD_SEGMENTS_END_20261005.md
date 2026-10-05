# PR15 REPLAY HUD有限测量 END

2026-10-05。父端接47445并明确返还唯一引擎窗口后执行[原计划](AMBUSH_PR15_REPLAY_HUD_SEGMENT_PLAN_20261005.md)。生产source **1ec3198e9c0db367af96fc264604c5a286003b5e** / game tree **1e8af45ee23098f763acc139b56f8f7e0f41665a**保持；本包只有外部QA stage计时、证据/规划，没有生产优化、规则/资源/manifest/loader变更或Site再部署。

**可复现的区间优先级是HUD内部；未定位HUD的具体子热点、稳定采样净开销或整帧唯一瓶颈。** 四轮OFF→ON→ON→OFF各actual0，完成有限测量；首P0超自己的120秒门、实际1保留，补充方法门9.13秒/actual0，不能把这一包写成“全部绿”。600秒总预算未重置，从17:22:16.891544至17:31:38.001729 UTC，**561.110196662秒**，browser controller实际exit0，全引擎/浏览器/自有HTTP END。385个post-draw间隔全部>33.333ms；本fixture性能目标未过，不是手机或最终A3验收。

## 固定输入、仪器与范围

旧producer **dab870595175eed37a6d2a012bc69a76062d48b0** / tree4f49与当前1ec consumer分列，没有新producer。原yard bin19,025,696B/SHA **e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5**，attempt **93a9671c444c749f102a04a728c963a5**，schema2/terminal12678。只读原件选择 tick6339、wave0、frame792、recorded SCOUT；余105.65秒，随后40秒原帧仍wave0/SCOUT。灰狼Kar98k、其余刀具和一sentry，原事件数0、列表0行且隐藏。该窗口不覆盖ALERT/SWEEP、密集事件、枪火/工具FX、其他关或全13波；不能用空列表的计时排除其他负载中的列表成本。

Stage `/workspace/pr15-hud-segment-stage-1ec-20261005` 基于已封yard paired consumer，保原完整两cfg和checkpoint；新profile `/workspace/.ambush-loop-env/web-hud-segments-1ec-20261005`，不打开complete campaign profile。独立原native选择UUID **779cc97292f14de09f031b5463d57f70** 实际Guard通过，actual0/E0/S0；Web独立profile与隔离存储另列，不冒称Web可使用native XDG Guard。引擎4.7.2 official ed1daf0bf、Compatibility/WebGL2、Dummy，1280×720/scale1/standard、镜头35°/55°。实际 renderer **ANGLE Vulkan SwiftShader Device(Subzero)**，软件环境不等于设备GPU。

QA stage逐blob核949 tracked exact；另有继承的45缓存音频import sidecars、QA project/export两项、两个计时脚本、源-only Blender省略，共50声明delta。未运行素材生成器/Blender/atlas/GLB。官方cached debug export实际0/E0/S0，PCK **57,144,620B/SHA20179ca0bb33d4fafc836857430cf85797228d8e22c4baa3d8e9aaa4ed65377d**。逐PCK payload MD5均核，旧yard QA973与新973只改 **main.gdc / presenter_3d.gdc / qa/event_log_observer.gdc** 三项；其余资源、metadata及loader字节相同。这是QA包，未部署。production PCK未被改写。

计时使用Time.get_ticks_usec，表示区间elapsed inclusive，可能含原生调用/等待，非纯VM self或GPU计时。root为原_apply_replay_scrub；select/slider、paint、events_up_to+title、list、status、transport、HUD按原顺序相邻分段。原列表表达式只分成相同顺序/相同值的临时变量，调用/参数与信号不改。相邻stamp区间和恰等root，remainder按构造为0，不代表“空闲0”；不能root与children相加。Presenter单列实际refresh inclusive，未涵盖整个_presenter._process、draw或worker。

OFF仍有相同get_node查询/分支、调用计数和固定缓冲采样，ON增加stamp及record_root写入；未与完全无仪器production做性能配对。为避免旧QA无界dict采样干扰，原observer的replay_rows保持空，替换为定长PackedInt64Array池，每窗最大2048行/固定20列与独立post-draw3列，满池拒绝；真实窗口未溢出，没有人为填满池负例。每窗warm2秒/collect20秒，段后一次flush；采样期间不RPC/截图/输出/磁盘写，原生输入来自原UI。共52DOM isTrusted/52 engine输入。原始非零elapsed的GCD100µs，多处0不能解释成成本为零；未独立测底层clock固有精度。

## 实际四轮结果

| RUN | 实际START→END UTC | wall s | static/advance rows | root/presenter advance calls | advance tick范围 |
| --- | --- | ---: | --- | --- | --- |
| 1 OFF | 17:26:41.092126→17:27:53.570866 |72.478086|49/46|46/46|6435–6795|
| 2 ON | 17:27:53.571365→17:29:06.290794 |72.718938|50/47|47/47|6435–6802|
| 3 ON | 17:29:06.291226→17:30:19.349206 |73.057358|49/47|47/47|6434–6802|
| 4 OFF | 17:30:19.349644→17:31:32.506777 |73.156573|49/47|47/47|6434–6802|

四轮各actual0、每轮<90秒。static原tick6339/暂停，root calls0、ON presenter50/49；这是有效负控制。advance原UI1×继续，所有样本actual root count1/自然tick单调/view_tick=tick，没触terminal/阶段边界；所有轮次从同6339起，warm与实时callback导致上述采样范围差异，**不是逐行同tick配对或同全程轨迹**。静态与推进负载不相减归因。

| ON advance区间 | RUN2 median/p95 ms | RUN3 median/p95 ms |
| --- | --- | --- |
| root inclusive |20.8/29.1|21.3/26.2|
| select+slider |0.5/0.6|0.5/0.7|
| paint历史2D inclusive |0.9/1.1|1.0/1.2|
| event select+title |0.0/0.1|0.1/0.1|
| list inclusive（空/隐藏） |0.0/0.1|0.0/0.1|
| status |0.4/0.5|0.5/0.7|
| transport |0.2/0.3|0.2/0.3|
| HUD inclusive |18.7/27.1|18.9/23.8|
| presenter refresh（单列） |3.0/3.4|3.0/3.3|

HUD占各ON root累计区间 **90.1203169% / 89.5282379%**；比例由区间sum计算，不是median相除或全帧占比。ON static presenter中位2.9/3.0ms、p953.1/3.4ms。共同row sampler median0、p950.1ms，ON2推进最大0.2ms；不计到的stamp/record_root/present回调等不能由该一项表示。实际所有count、零样本、tail、原rows/post timestamps在analysis.json及raw。

| post-draw | RUN1 OFF median/p95 ms | RUN2 ON | RUN3 ON | RUN4 OFF |
| --- | --- | --- | --- | --- |
| static |403.4/438.6|400.6/422.6|399.4/434.0|400.65/435.1|
| advancing |432.85/491.1|423.9/464.3|424.6/451.9|422.2/468.8|

静态相邻ON/OFF中位−0.6941%/−0.3120%，OFF重复漂移−0.6817%；推进 **−2.0677%/+0.5685%**，OFF重复漂移−2.4604%。推进方向混合且变化处于已观察漂移范围，**不能得出稳定正开销、把负变化称加速，或扣除净开销校正FPS**。主刷新中HUD排名在两个ON重复，但严格采样开销门未证实稳定；下一包先改方法并细分HUD，当前没有直接实施优化的子热点/净收益证据。post-draw包含未测线程/GPU/同步等unknown，不能用wall减root/presenter推出GPU成本或唯一瓶颈。

## 中性、图像、负例与证据

每轮前后原八字段record SHA/domain/full settings两cfg/public checkpoint一致，返回WON再核保持；actual3D endpoint frame checks无fail、原角色/装备/20骨/weapon_hand socket静态签名一致。两P0 PNG和四static PNG共6张逐张目检，P0前后及OFF1对其余三轮RGBA逐像素完全相同；推进终点签名单列随实际tick，不冒称推进像素逐帧一致/完整战场集成。

保留两个方法负例：

- 首PCK audit误期待res://前缀，实际1/chunk eb6943；原脚本及pck-payload-audit.json保留。只修allowlist到实际pack keys，v2 actual0，未再export。
- 首P0从总预算起点计时 **135.994285597s>120**，包含native/export和等待调度，actual1；计时器/paused/canonical/full fingerprint断言此前已通过，但不改绿。原START17:23:43.653428、END17:24:32.886396/receipt保留。补充门17:26:01.856955→17:26:10.992644，9.134342s/actual0，读取原ON8个positive presenter/paused root0与新OFF8个reset样本；仍在原600秒deadline内，未重启/延长。它是显式补充方法门，原P0时限违反保持。首initializer间接read helper未在首次加载时封存SHA，不能将后续文件冒称首helper快照；补充门实际加载helper字节已在loaded-controls封存并用于四轮。唯一helper修正是WON fingerprint允许非REPLAY frame_checks结构，未改计时/主源。

console error0/pageerror0/SCRIPT ERROR0/ERROR0；保留4条GPU ReadPixels警告，截图在采样窗外。预算内命令成功不代表帧性能通过。browser controller PID171560/session98149 END17:31:38.001729、实际PTY0；最后tool字段人工逐字段转录并标注stdout另存，不伪称完整raw tool对象。ports12815/12816/12817 closed，live Godot/Chromium0；新profile留存，原complete profile没动。

[证据manifest](evidence/20261005-pr15-hud-segments-end/manifest.json)：**139文件/6,348,952B**，全size/SHA再次核验；包含原request/receipt/vault/seal、loaded controls、timer diff、selection/Guard/export/PCK、所有raw、full边界、6原PNG、analysis与只读archive报告，不重复19MB原bin、不入库57MB QA PCK。实际命令：

```text
python3 /tmp/pr15-web-controls/hud-segments-1ec-20261005/run_native_export.py
python3 /tmp/pr15-web-controls/hud-segments-1ec-20261005/audit_pck.py
python3 /tmp/pr15-web-controls/hud-segments-1ec-20261005/browser_controller.py
  hud-initialize-P0: actual1（135.994s cap）
  hud-P0-recovery: actual0
  hud-run1-OFF / hud-run2-ON / hud-run3-ON / hud-run4-OFF: 各actual0
  hud-final-proof / hud-window-END: 各actual0
python3 /tmp/pr15-web-controls/hud-segments-1ec-20261005/analyze.py
python3 /tmp/pr15-web-controls/hud-segments-1ec-20261005/seal.py
```

native/export/analyze/seal各actual0；无新增其他关/全whole/产品回归假通过。下一[有限子诊断与条件候选](AMBUSH_PR15_REPLAY_HUD_CAPTURE_CANDIDATE_PLAN_20261005.md)只是计划，未实施/未运行。

## 同Site archive独立只读并行结果

按父端允许的只读并行由已有web_fs_source_readonly完成，未触引擎/浏览器/部署/产品。授权sites_get_site_version成功确认v4/source da59df8415b8f70690ea815bed8917948abd3160/server tar48,506,880B/13files/hash2502ad6f6acf036cd20bc97ff7306d2b0deaf9323410706fcc7a814502b57327。一次授权download_file给定file_00000000023881fd83dd75d29e7601de实际 **file could not be authorized or resolved**，没取得server原字节；不能将错误说成实际32MiB报错，32MiB上限另为已知能力限制。

原本地tar e62ee8b3ea3a3e54c0d04e712565e59286ba897f856639c9a8bebfceec1736e1逐成员实际读出13普通文件+2目录，11manifest项size/hash一致，PCK流拼接0eabd893…与WASM流解压fc74679e…匹配，**32/0静态核对**。server成员内容、独立SHA复算和差异原因仍unknown；不推断padding/repack、不绕origin403、不取/记录签名URL。脱敏[只读报告](evidence/20261005-pr15-hud-segments-end/archive-readonly/assessment.md)入证据；同私有Site仍v4/ACL不改，正式origin/PCK身份门仍待。

完整六关同最终候选13波、听感、FINAL/fullsmoke/艺术全帧/设备性能/APK等继续待验；本包不清这些格。原R5资源/制作所有权和SCOUT→ALERT→SWEEP保持，PR15继续Draft/不merge；无独立资产制作请求。
