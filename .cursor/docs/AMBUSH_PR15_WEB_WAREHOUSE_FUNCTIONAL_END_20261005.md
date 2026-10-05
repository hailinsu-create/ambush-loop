# PR15 warehouse 原输入完整回放与存档交接 END

2026-10-05，**有界 warehouse 功能包 END；日志中央遮挡待修，墙钟实时速率未验收**。用户恢复实际操作授权继续有效；本片按父端要求只接既存 session65568，未重打542秒producer，未启动后四关producer。仅增加文档/证据；生产固定 `dab870595175eed37a6d2a012bc69a76062d48b0`、game tree `4f49a7c9cb5a789fbb570bceb947eab7df2eb54a`，私有 Site v2未改，无merge/deploy/资产生成/paid/public/APK。

## 同一原记录的实际结果

原单页两波自然WON producer已固定在 `ec12181d133837bb2b45beb0463e0da79b8e228e`，542.2111071610125秒、actual0、validation[]。[producer报告](AMBUSH_PR15_WEB_WAREHOUSE_SINGLE_PRODUCER_20261005.md)与31件数据原件保持。原record **26,554,792 bytes / SHA256 `28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266`**，attempt `1289c65c34af63cf62707bf18ddc4cca`，schema2/win/62events/2072frames/t16102。此次复制文件与每次绑定前后SHA精确相同。

| 原 UI 实际门 | 结果与范围 |
| --- | --- |
| whole1 | 原ReplayButton→暂停/选1×/滑条Home回0→继续→自然terminal16102、playing=false；END07:32:42.459、actual0。输入至真实terminal callback **978.206秒**，controller总983.111503秒，独立deadline1640.2秒。2,022原观察行显示tick全等回放tick；frame checks19/0、record/domain未变 |
| whole2 | 原按钮另绑同记录→暂停/保持2×/原回0→继续→自然terminal16102；END07:42:23.496、actual0。真实callback **488.1532秒**，controller总493.236061秒，deadline835.1秒；1,016行、frame checks19/0、record/domain未变 |
| 原事件定位 | 原UI滑条、日志、露出左侧文字鼠标点击。波0 event `:0:14` / fire / actor1 / playback10482，波1 `:1:49` / fire / actor2 / playback15054；原回放暂停、3D环可见、frame checks17/0与19/0、attempt/wave/source/记录/模拟域一致；actual0 |
| 原交接/保存/刷新 | 原Space返回WON→Continue加载pump SCOUT后handoff，from warehouse/to pump→原CTA→pump实际教学**两页**→刀装preview→原Esc/标题。原任务列表与reload验证actual0、END07:50:53.188；yard/warehouse cleared，pump unlocked，railcut/depot/radio locked，next=pump、complete=false |
| 原继续与profile重开 | 刷新后原Continue进入新knife-only pump SCOUT、无重复教学；随后原Esc/标题。首reopen方法actual1（下面说明），控制器普通关闭actual0。独立有界同profile/origin原Title重开07:55:47.197→07:55:58.742 **actual0**；cfg全文/SHA、实际GameSettings、public checkpoint、全部任务按钮状态精确一致，无新producer |

whole完整播放未seek到终点、没有直接tick/process/force win、没有重打原自然胜利。seek/focus/左右箭头另列，不混入whole计时。316 browser trusted/316 engine输入及3982全回放观察行在进入新scene/刷新前保全；原刷新前总332/332输入另存，刷新后下一段10/10另列，不能把不同context计数相加为同一engine。

**实速与功能分开：** 268.366667秒record中含真实SCOUT准备空闲，不等结算20.1秒战斗。1×与2×的墙钟分别是理想模式时长的3.645035与3.637957倍；1×/2×实际wall比2.003891，说明此次倍速关系成立，但**实时速率门不通过/软件环境，非30/60FPS或设备性能接受**。1×playing行累计process delta268.2577秒、median0.133333秒，实际wall978.206秒；保留观测，不将该差异直接归因于单一游戏/renderer原因。没有放宽deadline、无限等待或tick jump补绿。

## 已证实的中央日志遮挡与方法负例

1. 首事件脚本使用`get_item_rect()`中心匹配相同编号，实际list滚动后`get_item_at_position()`命中编号偏移3：例如名义row3中心命中row6。脚本在点击事件前以“no original visible fire row”actual1退出。失败loaded-script与全部候选原行保留；**首失败receipt原路径与后来成功packet同名，被覆盖，完整原receipt已不在**。仅将实际tool stdout actual1明确转录至ledger，不重构/伪称原receipt保全。下一controller应将receipts/artifacts分目录。
2. 修正只读hit-index后真实鼠标点 `(1098,311)` 命中预期fire row6区域，但tick保持10788、focus_actor=-1。原负例receipt/截图保存。实际屏幕显示上层camera按钮覆盖EventLog；生产camera CanvasLayer4在HUD上方，panel位于右侧196起，EventLog右侧206起，范围重叠。**这是已复现的UI遮挡，未修复**，不能称日志交互全区域通过。
3. 随后仍用原滑条/日志，只点击可见左侧文字，按既有只读命中行y与单列区域验证，实际得到上述两波精确fire定位/3D环。没有调用`focus_latest_of_type`、`set_tick`或修改桥/生产。这一有限正例不消除中央遮挡。
4. 最后原profile reopen方法因事件脚本顶层行宽变量`pw`覆盖Playwright owner失败：旧context已close，随后`'int' object has no attribute 'chromium'`actual1。保留原失败脚本/receipt。收齐session65568普通END actual0/PID151305 absent/port111后，用独立有限Title-only脚本、稳定`browser_owner`变量重开同profile/origin；单页与精确存档actual0，未重新通关。后续recipe需局部变量/明确owner，避免exec globals泄漏。

[46件数据/脚本manifest](evidence/20261005-pr15-web-warehouse-functional-end/manifest.json)列13,939,113bytes，每件SHA/size均核对；它引用ec121原producer/bin而不重复归档。14张原PNG均实际查看：两whole terminal、两个方法负图、两波focus、handoff、pump两页教学、继续刀装SCOUT、两轮解锁列表、最终profile列表与Title。截图可见中文HUD和原3D仓道/泵站入口；没有称完整美术、所有武器动作、耳听/设备通过。运行receipt console error0/page error0；GPU ReadPixels warnings保留。调用异常与游戏运行错误分别记录。

## 实际命令、END与下一包

既存 controller 内依次执行 `whole_warehouse_single_1.py`、`whole_warehouse_single_2.py`（各actual0）；事件脚本初始geometry actual1、hit-index中央点击actual1、`warehouse_original_event_focus.exposed-left.py` actual0；`warehouse_boundary.py` actual0；`warehouse_end_probe.py` actual1。普通close消息令session65568输出SINGLE_BROWSER_END、实际exit0。另一次 `python3 /tmp/pr15-web-controls/fresh-native-resume-dab-20261005/warehouse_final_reopen_finite.py` session35870实际exit0/FINITE_ORIGINAL_REOPEN_END。两流程均精确PID absent，最终port12815 connect111；保留profile、原record、cfg与制作源，**当前自有engine/browser/server全部END**。轻检为recipe py_compile、46件manifest SHA/size、原record SHA、receipt结果/输入信任/whole不变式和git diff-check；未追加headless/Window重复测试。

下一独立代码切片优先修camera覆盖日志：建议日志可见时收起camera chrome，关闭日志恢复原camera状态，不改镜头姿态/战斗/record。这是**提案/UNAPPLIED**，需原中心鼠标正例与日志关闭后camera正常、两波历史/source不变等有意义回归；旧失败/raw/record不删，不重打warehouse producer。之后单窗口接原Title Continue的pump正常双波→railcut→depot→radio，六新记录、yard原记录whole、旧schema及FINAL门保持待验。fresh源pin变化时明确记录来源，历史消费不能冒充新自然关卡。

Library当前完整prepared helper network/no IDs、fallback条件不满足，独立PCK32/96字节差异仍待；不阻塞新记录Git交付。正式origin、触控取消/后台、耳听、all-art、实时速率/A3、fullsmoke/FINAL及可追溯APK均未通过。HTML先APK后；资产接口保持root所有runtime/presenter/replay/shared tests，作者所有ArtSource/generator/GLB/atlas/Blender及制作manifest，本片未编辑或重跑资产。
