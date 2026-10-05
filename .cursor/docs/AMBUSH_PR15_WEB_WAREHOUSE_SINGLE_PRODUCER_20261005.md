# PR15 单页面 warehouse 原输入检查点

后续已完成[warehouse功能包END](AMBUSH_PR15_WEB_WAREHOUSE_FUNCTIONAL_END_20261005.md)：原whole1/2自然终点actual0、两波露出文字focus与原save/handoff/reload/profile重开通过；全部自有流程END。中央日志遮挡已复现待修、实时wall速率未验收。下方07:19为原封存检查点，不能当当前运行状态。

2026-10-05 07:19:16 UTC，**PRODUCER PASS / 原 UI whole1 RUNNING，尚未通过**。本包是仓库有界检查点；用户恢复实际操作的授权持续有效，QA 保持 idle，root 独占引擎窗口。模型容量恢复未替换环境、重启浏览器或重跑已完成动作。

生产固定 `dab870595175eed37a6d2a012bc69a76062d48b0`，game tree `4f49a7c9cb5a789fbb570bceb947eab7df2eb54a`。本切片仅证据/文档；私有 Site v2、所有资产、生产源/PCK不变。现有隔离只读 QA 桥 SHA256 `433d191181b311d09d011f8ba319b91aaee11833b2416a1c7124f924554d5b18`，QA PCK `17711fe6f3677316cb8bddf4368a6c66063ca3d7d1c4e2a8c65f2f906fd707bd`，不同于生产 PCK。

## 已实际完成

自有 persistent profile 首次输入前关闭恢复的 surplus，assert `len(context.pages)==1`；whole1 入口再次验证只有一个 localhost 游戏页。原存档加载与之前自然 WON 的两份 cfg 文本/SHA精确相同；未 seed 存档。原 Title Start→已解锁 warehouse 行→简报→新 knife-only SCOUT，已读教学未重复；首次 warehouse 原教学此前已纠正为三页。

本次 attempt `1289c65c34af63cf62707bf18ddc4cca`：

| 实际门 | 结果 |
| --- | --- |
| 原输入 producer | START 07:00:43.408；自然 WON 07:09:45 左右；producer wall **542.2111071610125 秒**，原 900 秒门内，无 retry；archive 完成 receipt 07:10:03.579 actual0 |
| 第一波 | 原 ALERT 07:04:04.401→自然 SWEEP 07:04:27.646，sim tick339 |
| 第二波 | 原补弹/地雷 cell(24,5)/再部署→ALERT 07:07:40.660→自然 SWEEP 07:08:43.172，sim tick863；原走近掉落、原撤离 WON |
| 原记录 | **26,554,792 bytes / SHA256 `28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266`**；schema2 / win / 62 events / 2,072 frames / playback terminal16102，validation failures `[]` |
| 输入与域 | browser trusted244/244，engine trace244，同 attempt；只读 post-producer 查 record SHA未变，actual0 |
| 屏幕 | 已实际查看 warehouse_won.png：3D仓道、中文结算、解锁泵站、下一关/返回标题/时间轴复盘原按钮；不把截图称手机性能或耳听验证 |

记录含真实 SCOUT 准备空闲，playback268.37秒不等于结算 battle20.1秒，也不等于 wall/FPS。renderer 实测 ANGLE/Vulkan/SwiftShader；本包不作设备性能验收。[原记录与31项数据manifest](evidence/20261005-pr15-web-warehouse-single-producer/manifest.json)及[producer 原件](evidence/20261005-pr15-web-warehouse-single-producer/run/warehouse-producer.json)可逐项核 SHA/size。

## 原 UI whole1 当前运行

07:15:42.973 原 ReplayButton→原暂停/倍速/滑条/Home→tick0、paused、speed1→原继续，自然播放。07:19:15.249 最近只读观察 tick3104/16102、playing=true；**尚无完成 receipt，不计 whole1 PASS**。实际 deadline `max(180,6*(16102/60)/1+30)`；未手动 tick、seek endpoint 或跳过 SCOUT。whole2、事件聚焦、原 Continue→pump handoff/教学、Title/reload与其余关均待实跑。

[活进程检查点](evidence/20261005-pr15-web-warehouse-single-producer/checkpoint-running.json)：唯一自有 controller PID151305，exec session65568，port12815；原 profile `/workspace/.ambush-loop-env/web-fresh-native-dab-20261005`，原 controller `/tmp/pr15-web-controls/fresh-native-resume-dab-20261005/browser_controller_single.py`。**保持该命令运行，恢复时先 poll65568，不能另启浏览器争抢窗口。** driver-actions 原件持续写入 tmp；封存文件明确是07:19检查点前的完整行快照，非整段回放完成原件。

实际执行：现有 controller 内 `produce_warehouse_single.py` actual0；随后以真实文件路径执行 `after_warehouse_probe.py` actual0，再执行 `whole_warehouse_single_1.py` 当前运行。一次把脚本文本误作文件路径的 dispatch actual1/Errno36在游戏动作前失败，原receipt保留；改为路径后actual0。它不是游戏失败或第二次 producer。早先 d8 多标签自然 WON 是环境混杂包，whole中断；900超时及late记录仍独立保留，均未改写成此次 PASS。

下一步 poll 原 whole1→在自然终点且记录/域/3D帧检查通过后原 whole2→原事件列表聚焦→原存档/解锁/reload边界，再继续 pump/railcut/depot/radio。Library当前 prepared route helper仍network阻塞且无IDs，fallback条件不满足；PCK32/96字节差异仍待。HTML先、APK后，不merge/deploy扩范围、不制作资产/paid/public分享、不称 FINAL/A3/设备测试通过。资产接口仍由root负责 runtime/presenter/replay/shared tests，资产作者独占源资产/生成器/GLB/atlas。
