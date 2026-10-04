# PR15 历史契约与唯一 HUD 通知合批切片结果

2026-10-04。两项历史门实际复现后证实为测试漂移；固定修复 `f275178c0f60a7579685f9823894cafc3386f6da`，唯一生产候选 `541d06440a97dd77f8c484a8de2a0ce364a8d91e`（game tree `53ffc88566b1ce7bd40daa1ce847c838f04fbd85`）。候选只在 `touch_hud._apply_btn_style` 新增 begin/end_bulk_theme_override 和注释，保留每次新建的四份独立 StyleBox。主题通知从5次收为1次是明确行为变化；最终样式与固定像素另验。既有制作源、生成器、GLB、Blender、atlas、生产manifest、玩法及预算均未改。未 merge/deploy/APK/设备测试。

启动前声明与方法修正见 [执行契约](AMBUSH_PR15_HUD_DIAGNOSTIC_EXECUTION_20261004.md)。[原始证据清单](evidence/20261004-pr15-hud-diagnostic/manifest.json) 收452文件、48,695,690字节（不含清单本身），清单SHA256 `f238576ab223d8a30b49c78f3a3e787c30632399f1ff33f7effff3fd896348f7`。所有原件、负例、完整stdout、各run actual exit/E/S、独立UUID、源码与资源前后证明、原CSV/bin/PNG均保留。测量使用官方4.7.2、Dummy音频、X11/Compatibility/Mesa25.0.7 llvmpipeLLVM19.1.7；这是共享宿主云端Wall测量，不是手机/硬件GPU性能。

## 原失败与修复边界

原presentation_contract实际84042/2、actual1 E2/S0。三个完整原 Dictionary 对比每组30差异，恰在 FX attempt/event_id/pose.event_id 随机身份前缀；按各自原身份归一比较副本后完整 Dictionary 相等。测试先加原 FX attempt/wave/seq/event绑定检查，再沿用现有前缀规则归一副本；原件及非身份谓词保留。

原clock在第205行 enemies:3 SCRIPT ERROR 后挂起，核 UID/准确argv/自有runner祖先后收取SIGTERM，actual143 E0/S1；首次/proc/environ权限拒绝保留，未升级权限。挂起clock与功能contract-dump曾重叠约65秒，这些均不作为性能集合。实际正常回放入口tick0/playingtrue/wave0，原测试却直接索引第二波终局角色；显式seek max_tick后原27检查全过。修复加从0正常播放断言与明确终局seek，保留骨骼/历史原件/毒化当前clock检查。f275两原门history84045/0、clock28/0 actual0 E0/S0；这些不是产品全部正确或fullsmoke通过。

外置样式oracle首次混tabs/spaces解析失败actual1 E1/S1原件保留；仅修正fixture缩进与精确signal Callable解绑后再验。首profiler在GDS栈内启停虽471/0 actual0，但tcalls0仍约31–47秒/>100%污染，因此拒作profile接受；原driver/完整输出/两PNG保留。改native call_deferred栈外启停，OFF与ON同样await/prime/collector；修正P0 475/0 actual0/strict0、168raw/84accepted只作能力预检。无失败改绿或择优删除。

## 热点与观察开销

正式 `OFF ON ON OFF` 四fresh run，22:26:35.853571–22:31:30.079406 UTC，各actual0 E0/S0/strict0、总672raw/336accepted，跨run strict0。两ON推进各25 scrub/HUD、26 presenter.refresh、1250 `_apply_btn_style` 调用。scrub inclusive占两个已核非嵌套生产root（scrub+refresh）99.1499%/99.1549%；style self占HUD inclusive89.7386%/89.6209%，重复热点成立。其self含原生调用与阻塞，非纯VM CPU、全帧比例、独占CPU或唯一硬件瓶颈。静态scrub/HUD calls0，另有tag_plate成本，本切片不优化它。

ON/OFF两个相邻配对static中位+2.9304%/+4.7251%，advancing+2.2192%/+2.7061%。合并static OFF136.1935/ON140.7850ms，advancing OFF709.6780/ON728.0265ms；collector OFF239/236us、ON250/256.5us。OFF stdout各约.27MB（共同prime），ON1.38/1.40MB。每秒latest FRAME和停止ACCUMULATED分开，2226已加载signature包括零调用、无容量耗尽，sum disjoint self与累计header在打印精度内一致。边界含少数paused callback，不能把calls冒作accepted逐行对应。观察开销实报，不相减校正FPS；排名/输入稳定，未追加反向块。

## 单候选正式 ABBA/BAAB 对照

固定A=f275、B=541d，各988tracked/986warm/493字节不变loader sidecars；baseline独立sparse worktree，未import或生成。外置driver SHA256 `876e53dcc4fd2ce90c6bed20c8010d9996eeebae0d50fbe241c6ffe6f9fbc204`，不开profiler。继承59列collector/15,466,496numeric bytes、5秒warm、60static+24advancing、5秒minimum、30秒cap、首次排除，main/presenter自动callback，原record/tick253/frame43/20骨/socket/装备/backend/镜头/尺寸/policy保持。两个预检actual0/strict0；正式22:44:22.083027–22:53:06.634364 UTC，顺序ABBABAAB、全8轮actual0 E0/S0及逐run/跨run strict0，1272raw/672accepted（checks3640；warm排除行随实际callback数变化，接受门未变）。

| Window | A中位/p95/p99/max ms | B中位/p95/p99/max ms | 四相邻B相对A中位变化 |
| --- | --- | --- | --- |
| 固定历史static，各240accepted | 146.010 / 161.619 / 169.010 / 224.086 | 141.067 / 153.152 / 164.098 / 178.286 | −3.797%、+0.698%、−7.173%、−3.161% |
| 自动advancing，各96accepted | 732.842 / 784.350 / 874.675 / 1074.451 | 357.764 / 410.398 / 485.567 / 490.986 | −50.281%、−51.822%、−50.129%、−51.485% |

推进四配对方向一致，合并中位下降51.181%，支持此固定云端fixture里候选有效；static方向混合，不能宣称稳定static收益。100%接受行仍超33.333/16.667ms预算；不称A3性能验收通过。A静态run drift max/min8.018%、B3.075%，推进A1.861%、B5.443%；完整tail/RSS/不利pair在[strict结果](evidence/20261004-pr15-hud-diagnostic/controls/batch-formal-strict.json)。原begin/end input及全canonical frame/rig/source bytes一致；推进end tick452/453依宿主callback，明确是限定transport样本，非相同全程轨迹/完整回放/逐帧配对。

## 同候选功能、样式、视觉结果

| 541d gate | 实际checks/failures | actual exit / E / S | 原UUID |
| --- | --- | --- | --- |
| presentation_contract headless | 84045/0 | 0 / 0 / 0 | c3c8ca4be7464693a5f1705ae130fe28 |
| command_pose_clock headless | 28/0 | 0 / 0 / 0 | bb7f235a02794a6593d0f31a8df5239a |
| equipment_freeze headless | 66/0 | 0 / 0 / 0 | 1529c5b6c5b94aaea6b47856793babdc |
| actual old schema1 reader +3D/UI headless | 17/0、3 selections | 0 / 0 / 0 | faea7a2a15bf4a488ac5bef5c890a66b |
| presentation_lifecycle render | 32/0、2原PNG | 0 / 0 / 0 | a9b3c5c5fef047aaa29cb7eb4972e6c6 |

旧schema1真archive SHA256 `1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12`，producer874d350，选0/.5/1历史frame、HUD身份与中性adjunct、毒化当前clock不改历史、全部sourcecontainers/文件bytes保持。仅三个选帧读者，不冒称旧记录全程autoplay。装备门覆盖ALERT/暂停ALERT/REPLAY拒绝与SCOUT/SWEEP合法；生命周期门保留Back/触控取消/回放锁/来源切换/pause/seek/截图现有谓词，是Godot输入API云端证据，非浏览器或实际Android输入。

独立GUI consumer oracle A/B各855/0 actual0 E0/S0，覆盖24按钮×锁、完整StyleBox存储属性/font/modulate/四资源独立、保留引用变更不污染别钮、外来override下一次同键绘制恢复、24phase×flags表；A通知5、B通知1。两个原phase-style bin各2,596,024字节逐字节等，SHA256 `c7f725987dd2c063edfacfe1c881091e4157e88740d92452ecd1a58776e58fec`。仅fixture隔离门，不冒称正常战场完整验收。

34张原始PNG逐张核看，未改图/合成；8正式static RGBA完全一致，RGBA SHA256 `c6b3562649cf0b867d77f5d1c445de5322d300ea96a434b2cbac52238d7142ab`；PNG及pixel hashes见[视觉清单](evidence/20261004-pr15-hud-diagnostic/visual-equivalence.json)。推进保持可辨角色、历史卡片与transport，但其实际end/timing差异照报。自有Xorg:127/PID127821核UID+准确argv后SIGTERM关闭，wrapper actual0，全部Godot已自然结束，预存:99未动。外置driver只在证据中留存，未加入游戏树。

## 实际命令与下一主线

执行器与完整argv/UUID/起止/实际status均在controls。核心命令：

```text
python3 /tmp/pr15-hud-diagnostic/run-profile-control.py
python3 /tmp/pr15-hud-diagnostic/run-batch-formal.py
python3 /tmp/pr15-hud-diagnostic/run-candidate-regressions.py
bash <fixed-worktree>/ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-diagnostic/godot-hud-style phase_tools_test.gd --headless
python3 /tmp/pr15-hud-diagnostic/seal-hud-evidence.py
```

三正式driver最终实际0；functional单run supervisor自身Python返回0不等于子引擎通过，逐run JSON明确actual_wrapper_exit，五项驱动另核actual/E/S/timeout后才续。运行时run-functional.py曾增加选择shim/mode，最终文件SHA不能冒作较早baseline启动时封存SHA；实际argv/原stdout另保全。first-direct P0原driver/run/shim另留固定字节。

最新用户把交付顺序改为 **完整游戏HTML可玩站点→之后才APK**。本切片停止叠加优化；接下来核匹配Web模板、Title完整入口和Compatibility单线程、实际静态宿主及浏览器加载/音频手势/键鼠触控焦点/存档刷新恢复/回放/Web性能。完整六关13波与SCOUT→ALERT→SWEEP保留，旧preview不可替代游戏。六关新全程1x/2x、正常13波fresh录制、actual-schema1 whole、剩余fullsmoke/FINAL/all-art待；此HUD结果不填补这些验收。APK/JDK/SDK不作为本轮门槛。PR保持Draft、未合并，资产接口/制作所有权保持。
