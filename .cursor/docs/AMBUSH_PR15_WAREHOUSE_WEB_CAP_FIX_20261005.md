# PR15 warehouse Web 900秒负例与观察器修正

2026-10-05 最新：[多标签环境更正与原单页回归](AMBUSH_PR15_WEB_SINGLE_PAGE_CORRECTION_20261005.md)。d8原双波WON/record实际0/894.493s已保留，但ctx真实5页/3游戏使旧单引擎口径撤回；whole已环境中断非pass。当前只关自有surplus、保留cfg/profile，原新attempt1289单页回归中，首波已自然SWEEP339。

2026-10-05，用户恢复实际操作与修正。**首包 FAIL_PRODUCER_900；同步只读观察器已修，独立原UI回归 RUNNING，未预报通过。** 同源dab/game tree4f49/私有Site version2不变。仅仓库根QA文档/原件/外桥代码，不改生产游戏/资产，不merge/APK/public分享。

## 首包实际负例与晚到原件

原同profile/origin承接已封yard，原Continue进入warehouse的首次三页教学，knife-only SCOUT，同attempt `1c9e6cb757ca36a5f3950bf67d6acb0e`。整个玩法仅trusted CDP键鼠/原UI：三枪与手雷/原1-3-5掩体/180-4-180度、原MG弹包/F，波0自然SWEEP tick339，原ammo→1、mine→0及cell(24,5)放雷现场0→1、再部署进入波1。没有授予/赋HP-ammo-tick/skip/forced win。

producer实际 START05:58:41.655Z，receipt END06:13:41.562Z actual1 `level producer wall cap900 reached`。最后记录采样仍波1 ALERT，不能报900秒通关或延长原deadline。后续只读诊断06:15:20发现波1已自然SWEEP tick863，但在截止之后；波1确切SWEEP切换时间没有采到，不能回填为cap内。

第一次扫尾错误地在SWEEP发X：原 `_on_abort_pressed`仅ALERT允许，实际无效。120秒等待actual1如实保留；不是游戏不响应，也没有将此负例删除。随后独立短收尾用原最后SWEEP撤离按钮，06:19:48→原WON06:19:57，再复制原记录到06:21:32；**晚到WON只是唯一原件封存，不计producer PASS，不拼入固定回归的获胜记录。** Title正常返回/原存储保留，未清唯一profile。

晚到原[bin](evidence/20261005-pr15-web-warehouse-cap/run/warehouse-late-excluded-record.bin)：38,525,548bytes/SHA256 `77d7ed59d580de4a4cf98c292cd858542218e4834db8c94c4a90d868f950c30a`；schema2，win，59events/2793playbackframes，playbackterminal21867，原battle terminal1203。event attempt/wave/seq/event_id/time和frame_seq/timeline只读validation failures=[]。两波属于同一attempt，365s记录不是20.1s战斗统计，也不是whole/FPS通过。

实际 renderer `ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device (Subzero) (0x0000C0DE)), SwiftShader driver)`；Compatibility/WebGL2、Chromium headless、Playwright1.62/CSS1280×720/DPR1，Browser插件absent。旧llvmpipe数据与本包SwiftShader分别归因，均不代表用户设备。当前完整console6logs/error0/warning0/pageerror0，有界页面健康不代性能或全美术。原刀装与晚到WON图已实际查看；没有框架overlay。

[sealed manifest](evidence/20261005-pr15-web-warehouse-cap/manifest.json)：46数据文件/46,818,831bytes，含原38MB record、截图/输入/actual receipts、失败时实际加载driver及未修版本、外桥/导出/PCK审计、原Title10只读查询latencies、Library新失败。失败driver从唯一后续修改中去除两行未加载的world120门后，与运行时已记录SHA `1d5d4855208d361fcef3db1a449b6d97fb41f77886afb539d31260c333ec7327`精确匹配；不将续工文件冒充旧run代码。原profiles/私有helper输出/凭证不入库。

## 修正与有界回归

旧只读桥每次 `_dispatch.call_deferred`等待实际回调帧，随后控制器还核两次present；warehouse慢渲染使重复状态查询增加wall。首包78个two-present wait合计155.531s/median2.109s，**这不含前后RPC等待，不把该和称全部观察开销**。Title10样本旧RPC为403.8–514.0ms；足以复现读等待，无paired warehouse性能结论。

仅外QA桥改为同步执行只读dispatch，追加实际输入frame/present marker、原event list hit-test/定位状态的只读观察；不用有内部缓存写入的VisualSnapshot.capture作“只读”域指纹。保存SimClock/run、HP/ammo/pack/位置/selected/door/grid及工具数量等当前域，原record八字段hash单列。ItemList几何按[官方4.7 API](https://docs.godotengine.org/en/4.7/classes/class_itemlist.html)的只读get_item_rect/get_item_at_position处理，真实点击后仍核两次present；桥不点击/滚动/seek/推进帧。world reveal额外落实原计划单动作120秒门，level900未变。

先正常返回Title→owned browser/HTTP END0（06:22后端口111）→串行官方4.7.2同步桥导出06:24:12.847–06:24:17.526，actual0 E0/S0。新fixture PCK38,096,020/SHA256 `17711fe6f3677316cb8bddf4368a6c66063ca3d7d1c4e2a8c65f2f906fd707bd`，bridge `433d191181b311d09d011f8ba319b91aaee11833b2416a1c7124f924554d5b18`。原965/fixture967每payloadMD5全核，仅加bridge remap/gdc，原project.binary/uid_cache注册差异，无其他变化；fixture不称生产PCK字节相同。

重开同profile/origin实际两cfg/public checkpoint保留；同步查询10次9–29ms，同engineframe4/config/input计数不变，无玩家输入、无手动frame/tick。**只验QA API，不称设备FPS。** 原Start→已解锁warehouse行→简报→新knife-only SCOUT，已读教学不重开，新attempt `d8ba862ce497eb87f8d3fde463a5d35b`，进入actual0。这是合法原任务重玩与独立修正回归，不是抹掉旧900 deadline，也不是另起已解锁fixture。

新producer START06:27:44.154Z，原900预算独立有效，结果待填。之后原live记录仍在时做原ReplayButton及pause/speed/scrub/resume完整1×/2×与seek/focus，再原Continue/handoff/pump教学preview→Title→reload→新的pump战斗attempt。旧late原件和新成功attempt严格分列；任何失败仍留原件，不预造six/full-Web/FINAL通过。

## Library条件与其余待验

本轮prepared/create/finalize实际schema与callable仍存在；依据当前Library skill重新完整取三helper到新private目录，原八件路径/大小/hash与mutation顺序全复核，默认endpoint/proxy/auth不改。完整原批helper actual1：`hosted apps tools/list request failed: network`，stdout0，没有进入首次mutation/没有IDs；原failed stderr与新failed receipts均保留，不能以helper网络故障冒称prepared不可用、拆单或绕网络权限。旧原PCK+32/独立新+96B仍未归因，无一致性通过。

后四关、新六whole/seek-focus、旧schema独立兼容、正式origin/触控生命周期/自然后台/耳听、FINAL/fullsmoke/all-art/A3仍待。音试听和手感留用户最终验；APK后置、不新增制作资产/paid工具、不merge/public分享。下一步仅当前warehouse修正回归及逐关原输入接续。
