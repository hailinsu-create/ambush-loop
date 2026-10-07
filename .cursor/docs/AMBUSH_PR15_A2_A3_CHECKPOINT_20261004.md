# PR15 A2封存与A3仪器安全checkpoint

2026-10-04 14:39 UTC。父端要求在最近安全点先交完整可续作状态，不等待A3或FINAL结束。本checkpoint不是全计划完成声明。主工作树 `/workspace/ambush-pr15`，原 `/workspace/ambush-loop` 未改；唯一主作者继续负责main/input/HUD/presenter/ViewState/replay/runtime-loader/shared tests。PR15分支 `feat/rotatable-yard-a0-20261002`；交接前GitHub只读实际核对远端 **4484b6eb1d3770dacb7e3af53a7f32e1efc1db2f**，Open、Draft=true、merged=false。本次新增test-only仪器 **b429378c88ba21614d6564495755155badfa5e9c** 及下列封存证据，交付commit须以普通push后ls-remote/PR读回为准。

## 已封存的A2候选与作者限定结果

| 切片 | 固定生产 / 正式测试 / 证据交付 | 实际正式结果 | 证据范围 |
| --- | --- | --- | --- |
| 保存爆炸/有界烟池 | a9b8ee068aee6b8345baf7064d90f9c08d67a80c / f2f1f570d1da91d1e01d7a1d23ba86080d4b364d / da1b50a5c34c1ab01e4838df6d9dfe7c12e8aa52 | H3/0、H255/0、Window268/0、像素Window75/0，各actual0 E0/S0 | 四生产blob同；98文件/42,883,099 bytes；43原PNG全hash/逐图查看 |
| 保存移动近脚尘cue | f9cf844e327f53fc0e1a06daa55d90a5efbb6bbf / 71cfc20a877c9cbbfc272d15aa05c82f6f7090f7 / 4484b6eb1d3770dacb7e3af53a7f32e1efc1db2f | H35/0、H132/0、共享visual seam H130/0、Window184/0，各actual0 E0/S0 | 五生产blob同；75文件/20,479,600 bytes；21原PNG全hash/逐图查看 |

完整实际命令、UUID、源与行为限制分别见[爆炸烟池报告](AMBUSH_PR15_TOOL_FX_POOL_20261004.md)与[移动尘报告](AMBUSH_PR15_MOVEMENT_DUST_20261004.md)。本checkpoint重新检查两个manifest的所有文件size/hash，98/98及75/75一致，没有重跑有效suite。烟池8槽/省电2、40mesh；尘池24actor槽/省电6、48mesh。保存时钟与严格绑定reader、原phase/pause/seek/foreign-source/七authentic旧raw中性及Title释放是有界验证；尘cue由当前保存actor姿态派生，不是新增原落脚事件或持久尾迹。

爆炸环真实radius负H254/18、实际mine同victim事件重复引用负H3/1已先封后修。早期parser/Title S1与三次像素探针实际134/134/139无suite保留，不算green。移动原planned7/2、raw phase3/1保留；expanded35/0实际exit0但S1不算green，原moving字符串导致旧bool(String)，生产只补该已知字段TYPE_BOOL门。expanded pool132/2是测试误认为setup会新建log；正式测试明确新建独立foreign log后再执行原load，未改main，也不声称正常UI保留重置前同一对象。所有原失败、无效probe及fixture修正均在原manifest中，不拼入通过数。

这些实际Window图包括明确开放位置/工具授予/保存age/API、或原SCOUT移动但显式冻结main自动process。五yaw/pitch55/view12的off/on/off证据不代新正常六关13波、全枪/姿态/LOD、长驻留、完整艺术接受、完整1×/2×回放或设备性能。

## 父端独立限定QA单列

父端blast source固定ac543c528c1844b0d2d4710db89bdccf0ad79b0b与d75/640四生产blob一致：source119、toolidentity19、old/fixed stats各7，均actual0 E0/S0。父端105/0 E3/S1是无效fixture排除；作者旧249 S1/261缺正向control仍保留。该纯source限定通过没有独立PNG或reader/render/dust接受。

父端此前b563枪池H205/Window305、53flight H144/Window160均actual0 E0/S0，9f真实射手绑定同反例3/0与副作用10/0各actual0 E0/S0，分别限定闭合。作者计数与独立计数不相加，不借枪池render结果证明writer身份，不重开已关闭范围。父端通知已封存远端4484，将独立验证blast/dust两个固定reader/render门；**本checkpoint不替该待验结果宣称通过**。

## 当前仪器已实际结束，A3六关尚未启动

新增test-only collector/probe/wrapper入口在 **b429378c88ba21614d6564495755155badfa5e9c**；相关八个生产文件与4484逐Git blob一致，证明保存于[production-unchanged](evidence/20261004-pr15-a3-instrumentation/production-unchanged.json)。collector订阅原frame_post_draw、读已捕获presenter.frame和标量，不再次capture/simulate/record，不在计时窗口截图、深拷贝diagnostics或写CSV。

已完成的唯一仪器运行命令：

```bash
DISPLAY=:122 AMBUSH_TEST_SOURCE_SHA=b429378c88ba21614d6564495755155badfa5e9c \
bash ambush_loop/scripts/run_isolated_test.sh \
/workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 \
a3_collector_probe_test.gd --render
```

Guard UUID **f4d7bfe7ec4e403793487f205c659f5f**。3秒冻结SCOUT仪器探针 **4/0、20 raw rows、actual exit0、ERROR0/SCRIPT ERROR0**；断言csv列宽/正时间及原HP/库存/位置/log不变。source脚本、原log/exit、raw CSV、metadata、只读仪器审查及关闭receipt全部保存于[仪器manifest](evidence/20261004-pr15-a3-instrumentation/manifest.json)：11文件/84,145 bytes；本checkpoint逐项重新检查hash，11/11一致。

官方Godot4.7.2.stable.official.ed1daf0bf、Compatibility/OpenGL4.5、Mesa25.0.7/llvmpipe LLVM19.1.7、1280×720/scale1、DummyAudio。可见CPU5/cgroup quota4；fresh XDG shader cache但工程import cache已存在，collector在场景初始两帧后附加。首row标排除，其余19 measured rows：interval135398/145830/189502µs（min/median/max），collector74/91/360µs，draw median624/max627，primitives median90995/max91021，texture73,498,834 bytes，static median251,160,328 bytes，nodes1282/resources467稳定。这里只记录该20行本身，**不据三秒结果制定完整预算，不推手机FPS/热稳/正式A3接受**。

只读6.1-sol仪器审查提出以下必须在正式采集前修正的测量限制：

1. `collector_usec`当前在rows.append前结算，未包含append/缓冲增长；需覆盖完整采集开销并记录缓冲策略。
2. rows驻内存导致MEMORY_STATIC包含采集器自身增长；需预分配有界缓冲并区分测量器、引擎资源、进程RSS。static不是RSS。
3. 18个Performance enum可用不代表OpenGL后台计数器被支持；pipeline值0不能证明无编译成本，需明确supported/unknown状态。
4. 附加在前两帧之后，没捕获冷启动/首次scene尖峰；正式运行须在实际生产场景前挂入并保存冷/warm分类、fixture转换和首段排除标记。
5. 正式采集须锁producer/consumer/asset/hash及未改backend证明，处理切场景时旧presenter失效；正式串行运行前需与父端QA协调同CPU上无并行engine争用。

当前**本作者全部engine session已收取，无待poll engine**；probe session85534结束。只对自有Xorg122 PID113111按原argv/UID归属核对后SIGTERM，session55476实际退出0；[closure receipt](evidence/20261004-pr15-a3-instrumentation/Xorg-122-closure.json)已保存，之后ps确认该PID不存在。120/121此前也已实际退出0；不涉及其他人的display或进程。六关phase/镜头/真实FX峰值正式A3没有启动，当前没有A3长轮需接管。

## 接续顺序与独立包

1. 修正上述test-only采集器与元信息，先做小型仪器正向验证并固定source；在父端4484独立QA结束或可确认串行窗口后启动正式A3。旧A2正负向证据和父端已closed限定门保持，不为采指标重复重开。
2. 执行[A3采集计划](AMBUSH_PR15_A3_COLLECTION_PLAN_20261004.md)：固定source六关SCOUT/ALERT/SWEEP/WON/FAILED/REPLAY、实际原source枪火/爆炸/移动峰值、8方向/35与65pitch/近远、标准/省电策略，保留所有raw post-draw intervals、draw/primitives/纹理/static/RSS/节点资源/池峰值及冷warm尖峰。转换/截图/夹具在timing summaries中明确剔除，raw不删。reference授kit/原API阶段单列，不能写成正常玩家旅程；引擎串行、记录CPU争用，llvmpipe只用于同环境比较。
3. 先实测，再选必要单片优化；同source/原record/输入/镜头/分辨率/策略对照，原terminal/events/HP/ammo/inventory与旧raw hash保持。没有实测支撑前不据20行探针作产品优化或A3完成声明。
4. 收敛后锁FINAL candidate，全门与完整smoke、新正常Title→六关13波→WON/CTA/自然progress/credits；封六份新raw，再完整真实1×/2×3D、pause/seek/eventfocus/跨wave/source/旧原schema1。INITIAL a05正常1193/0、consumer_d9c旧六whole2×29976/0仍是各自旧source范围，不拼FINAL；完整1×未完成。旧fullsmoke54/62失败保留，8906只是有界testfix，修后完整smoke仍待。
5. 再产生可追溯fullgame APK：工具链只读审查发现匹配JDK17/SDK36/build-tools36/官方4.7.2 templates尚缺；Java21/keytool存在。需在授权workspace内实际安装/模板/export/signature验证并封source/engine/template/package ABI/公开证书指纹/APK hash/actual exits。旧preview exporter会改boot，不可直接当全游戏构建。当前未安装/导出/签名/adb/模拟器/真机；全部生产工作完成后再讨论设备，耳听0/45、0/6未验。

可并行的独立包：父端已安排固定4484 reader/render QA；采集器修正后可安排只读计时/元信息/原record接口审查，不能同时跑占CPU的A3/QA engine。APK工具链来源/版本/hash只读整理与艺术候选复核可并行，实际shared runtime/test由主作者单写。没有待批准的非阻碍产品取舍；完整战场艺术/全十枪姿态LOD、长驻留、新正常13波/新全回放、完整smoke/A3/可追溯APK仍未验，不把样本通过写成全战场/设备通过。

## 资产接口与授权边界

R5制作源 **29749157c5db064bfea626c3ed9d75d9a1791ece**、交付 **ebedb829e3263abbeb6dd266905f24a3869fa281**、20骨/socket/3LOD/52语义接口保持。独立资产工作者拥有ArtSource/v2/build_yard_kit.py、共享atlas、角色GLB/Blender输出及生产asset manifest；本轮未编辑或重跑，未全并未验WIP f7c30f9f7f0c2d53513191235f3a719a251e3a4c。需要艺术修订时给该所有者独立接口包，主作者只接验收过固定提交。SCOUT→ALERT→SWEEP、原模拟、ALERT装备冻结、历史身份/旧记录兼容保持；授权普通push PR15、不merge/生产、不混height/G/PR4–6/13/16。未改个人配置/凭据、未派astra。
