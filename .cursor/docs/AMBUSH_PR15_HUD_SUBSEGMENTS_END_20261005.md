# PR15 HUD内部子诊断 END / 唯一候选冻结

2026-10-05，按父端44a034接续授权与[启动前声明](AMBUSH_PR15_HUD_SUBSEGMENTS_EXECUTION_20261005.md)完成。生产source1ec3198e9c0db367af96fc264604c5a286003b5e/tree1e8af45ee23098f763acc139b56f8f7e0f41665a仍原样；本diagnostic未实施产品优化。旧dab yard e850原bin、paired consumer tick6339/wave0/frame792/SCOUT/空隐藏事件列表不变，无新producer/资产生成/同Sitev4部署。

**触控HUD一次主刷新中确实执行两遍，成本重复且可复现，下一单候选消除REPLAY相邻重复刷新。** 不是整帧唯一瓶颈、不把HUD占root约90%说整帧90%。原44a034首P0超时actual1/混合开销仍保留；本轮连续自动调度P0 **78.755877秒/actual0**，没有改写旧失败。新软件环境仍官方4.7.2/Compatibility/WebGL2/ANGLE Vulkan SwiftShader/Dummy/1280×720/scale1/standard、镜头35°/55°；不是手机/GPU纯计时。

## 实际流程与有限预算

`python3 /tmp/pr15-web-controls/hud-subsegments-1ec-20261005/supervisor.py` 自动依次运行原native只读selection（Guard UUID aba898fa931441fcad8b201a48a3899f）、official cached QA export、pack audit、browser P0、OFF ON ON OFF、原Space返回WON及END。从 **17:51:02.096530至17:57:18.456884 UTC，376.360358秒/总cap600**，全部supervisor子actual0/无timeout。browser PID172645、工具session34196最终actual0，live Godot/Chromium0/ports12815–12817 closed，唯一窗口已安全END后才制作候选。

P0真实ON paused root/getter calls0、presenter正；短自然advance7样本每样本capture8/insideHUD8/touch2/style50，真实计时>0；随后OFF reset、同原record/domain/fullcfg/checkpoint/canonical及20骨/socket。固定Packed池2048行×30列，溢出无效，实际无溢出。所有helper实际加载前字节封存，克服旧P0 helper初始未封存的限制；没有运行原producer、注入终点或开启complete profile。

| RUN | UTC START→END | wall s | static/advance rows | actual exit |
| --- | --- | ---: | --- | --- |
| 1 OFF |17:52:21.306707→17:53:34.111255|72.803989|50/47|0|
| 2 ON |17:53:34.111677→17:54:46.979648|72.867352|50/47|0|
| 3 ON |17:54:46.980338→17:55:59.704181|72.723085|50/48|0|
| 4 OFF |17:55:59.704634→17:57:13.235206|73.529923|49/48|0|

每RUN<90秒，每窗warm2/collect20，≥12实际样本；测量窗无RPC/输出/截图/磁盘，after flush才指纹/截图。ON stamps的interval是elapsed inclusive、非VM self/GPU。新增HUD getter count/time、insideHUD和insideTouch capture count/time、touch refresh/style count/time；scope depths/lookup/branch/counters与采样器OFF亦有。内部capture与style嵌套touch，不能相加，off的计时0仅表示timer disabled。

## 具体区间与采样扰动

| ON推进，每真实root callback | RUN2 median/p95 ms | RUN3 median/p95 ms |
| --- | --- | --- |
| root |21.2/25.3|21.15/29.5|
| HUD |19.1/23.2|18.95/27.4|
| HUD内全部capture（8次） |5.9/6.4|5.9/6.4|
| touch refresh（2次） |8.7/9.6|8.5/11.4|
| style（50次，含在touch） |4.9/5.8|4.85/5.6|
| capture in touch（2次，含在上述capture及touch） |1.5/1.6|1.5/1.6|

完整tails/count/row时序在analysis.json和sub-analysis.json。全部正式ON样本重复8/8/2/50/2的上述count；static所有HUD子count0。touch占HUD累计 **44.8631%/45.2361%**，全部capture **31.4063%/29.9431%**，style **25.1164%/24.6627%**；这些不是全帧占比，嵌套项不加。非重叠分区只有touch-inclusive、capture-outside-touch与HUD其余/计时开销，原sum另存。

post-draw static median OFF1/ON2/ON3/OFF4=399.25/399.85/404.3/402.1ms，advance=425.1/427.0/422.55/420.05ms。推进ON/OFF相邻 **+0.4470%/+0.5952%**，OFF重复漂移−1.1880%、ON漂移−1.0422%；static+0.1503%/+0.5471%、OFF漂移+0.7138%。这轮方向一致且扰动小于所观察重复漂移，仍不能精确拆出净观察成本或CPU/GPU原因；旧混合开销不被覆盖。保100µs非零计时粒度限制与未知未覆盖worker/draw/wait；各软件post间隔远超30/60FPS预算，目标仍未过。

各轮原record/domain/fullcfg/checkpoint与返回WON一致，view_tick=tick/自然单调，snapshot/装备/20骨/socket/frame身份无fail。4原static PNG逐张目检/原RGBA全部一致，均与前44a034同canonical图相同。62DOM trusted/62engine输入、console/page/SCRIPT/ERROR0，ReadPixels警告保留。旧源/波次/事件没有挂到当前run_id。

QA PCK **57,145,852B/SHA852a217b1b9643989c32a2d335cacf42a357ea192715e1772748319218f04b9f**，官方export actual0/E0/S0。相对44a034 HUD-QA的973payload只改main.gdc/touch_hud.gdc/observer.gdc三个仪器compiled条目，其他payload全部MD5核且字节不变；未改presenter/资源/manifest/loader/规则。根源等价身份仍1ec与旧dab producer分列，QA包没部署。

## 唯一候选与实施前对照合同

源码现 `_update_hud`结尾连续 `_ensure_touch_hud(); _refresh_touch_hud(); _apply_phone_world_ink()`；ensure函数无条件已调用_refresh_touch_hud。实测2 touch/50style与此调用链吻合，两个正式ON重复且触控刷新约占本HUD45%。选择**仅REPLAY省第二次相邻touch refresh**，保ensure内一次；其他phase两次保持。不同时做历史frame缓存、样式缓存、移除paint/list/降资产/改frame advance。这个候选没有读取器状态/缓存invalidations，也不改装备或规则。

实施前冻结：main单一生产diff；基线A=1ec，候选B单改main。先native A/B同原yard与真旧schema1选帧/同tick source switch/当前battle_log毒化/paused/seeks/event focus/Space返回、完整状态cfg/checkpoint，以及最终全部按钮styles/text/rect/visible/disabled/modulate/历史frame/20骨/socket对照；原source bytes保留。候选已有history/equipment/source-text/lifecycle/旧reader等受影响门在独立Guard下每门cap60，失败停止，不乱跑fullsmoke。

接着另一个明确budget **A/B配对包总≤600秒**，同官方cache/QA fixture，只一个main差；4 fresh串行ABBA/common OFF sampler，static+advance warm2/collect20/≥12样本/run≤90/cap2048，测量窗无额外profiler/RPC。对子count预期2→1、50→25只有actual observer出现才报告；case setup counts/PCK/SHA/实际tick/callback/不利pair/tail/重复漂移/像素/所有边界全保。若整帧收益不稳定，报告局部重复工作消除与实际限制，不能称净帧性能/A3达标。只有合同与对照实际合格才固定候选交父端独立QA，不在独立QA前发布Site。

此END时生产候选尚未实施；后续有独立固定SHA与实际结果，不把本仪器当优化。证据在[evidence/20261005-pr15-hud-subsegments-end/manifest.json](evidence/20261005-pr15-hud-subsegments-end/manifest.json)，132文件/4,640,798字节均核验，所有原件/receipt-vault/SHA保留，不重复原19MB bin或QA PCK。archive路线停止、server内容/hash差未知/正式origin身份待；最终samecandidate13、听感/fullsmoke/all-art/A3/APK/设备依旧待，资产接口无请求/无变。
