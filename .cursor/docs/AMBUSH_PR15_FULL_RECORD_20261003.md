# PR15 完整三阶段记录正式关（作者验证）

固定实际测试源 **15c0783059bb7c2f9e9cd9b7252a9343e71f4168**；生产修复源 **d860056f2107836c08dfb375a034ebbe694baff6**。29次已实际结束，全部exit0/ERROR0。75张图留存并核SHA256。父端独立QA按fixed15c安排，尚未收到结果；本报告不关闭独立QA，也不称全计划或正常玩家全旅程完成。

## 行为与版本

67f连续SWEEP未记录SCOUT，首次报警丢SCOUT身份。1ab固定负向118/14、exit1、ERROR0实际证实。d860让SCOUT开始时创建并保存attempt，真实初帧、约0.1秒命令采样及报警前未采样边界保留至首次ALERT；原battle域的事件/快照仍在首次报警按原语义重置。playback_schema2以独立单调播放时间、全局frame_seq和保存的attempt/wave标记覆盖SCOUT→ALERT→SWEEP及终局。phase边界只加一个presentation tick，原BattleLog schema2、battle tick、波次offset、event seq及胜负/数值/grid/Nav/LOS/拾取不变。

REPLAY的event focus使用保存的playback_time与身份；SCOUT与firstALARM虽同battle tick0，历史回退仍清掉未来event ring。旧schema1真实二进制、旧battle域以及unknown/malformed保守回退通过，旧源不升级、不挂到当前run_id。暂停/后台不增加command时间或帧；REPLAY进入保存真实未采样边界。记录点root及20骨前后seek与被污染的当前活体隔离。中间0.05s检查为保存时钟驱动的姿态，不证明两个采样点之间root精确连续插值；约0.1s采样也不等于连续视频。

## 六关原reference完整多波

每mode各六关×3个reference attempt（60/1x、30/1x+camera、60/2x+camera），每attempt跑原全部2/3波；39个reference波/mode。使用原部署/给装备/vacuum辅助；30/60为受控ALERT步进参数，不是设备FPS。SCOUT实际4×0.1s、每SWEEP实际2×0.1s样本纳入记录；先执行原vacuum再等待，保持原拾取输入。计算和3D历史关键样本通过，不称正常玩家完整战場验收。

| 关卡 | headless | render | 原各波末tick | 原全局terminal/events | 连续play terminal |
| --- | --- | --- | --- | --- | --- |
| yard | 2515/0 | 2527/0 | [1056, 227] | 1283/34 | 1334 |
| warehouse | 2659/0 | 2671/0 | [315, 876] | 1191/67 | 1242 |
| pump | 1939/0 | 1951/0 | [231, 676] | 907/34 | 958 |
| railcut | 1684/0 | 1696/0 | [117, 602] | 719/38 | 770 |
| depot | 2068/0 | 2080/0 | [566, 391] | 957/35 | 1008 |
| radio | 3163/0 | 3179/0 | [574, 391, 448] | 1413/51 | 1477 |

每关三组结局、事件fingerprint、waves一致，headless/render fingerprint一致；六关原terminal/events与1ab生产未改的基线10332/0一致。38张native窗口历史图覆盖各关SCOUT、每波ALERT/SWEEP和WON；每图附playback_tick/frame_seq/attempt/wave/phase/header。两次绘制后读front buffer，已看六关38帧contact overview，第二/第三波header对应2/2、2/3、3/3；未称每张文字或艺术全验。

## 其余固定15c实际命令

| 入口/模式 | checks/failures | 实际exit | ERROR |
| --- | --- | --- | --- |
| command-headless | 217/0 | 0 | 0 |
| command-render | 224/0 | 0 | 0 |
| credits-render | 127/0 | 0 | 0 |
| lifecycle-render | 32/0 | 0 | 0 |
| presentation_contract-headless | 84042/0 | 0 | 0 |
| replay_timeline-headless | 67/0 | 0 | 0 |
| camera_input-headless | 23/0 | 0 | 0 |
| presentation_lifecycle-headless | 30/0 | 0 | 0 |
| equipment_freeze-headless | 66/0 | 0 | 0 |
| utility_runtime-headless | 1041/0 | 0 | 0 |
| command_pose_clock-headless | 27/0 | 0 | 0 |
| visual_snapshot-headless | 130/0 | 0 | 0 |
| replay_fx_lifecycle-headless | 30/0 | 0 | 0 |
| utility_runtime-render | 1047/0 | 0 | 0 |
| firearm_runtime-render | 7681/0 | 0 | 0 |
| visual_snapshot-render | 164/0 | 0 | 0 |
| replay_fx_lifecycle-render | 36/0 | 0 | 0 |

完整command headless217/render224：8真实SCOUT采样、16次back/forward及SCOUT菜单/后台冻结；8真实SWEEP采样、16次back/forward、暂停/后台、两波WON1283/34、实际FAILED escape928/19、abort0/3、源和当前状态不变、正常event seek、旧schema1实源及缺失/未知/6种malformed回退。7个root framebuffer文件留存，实际看SCOUT/SWEEP live/history、旧schema1和两个FAILED帧。旧HUD另一fixture的929不混入本fixture的928。

freeze66覆盖ALERT、pausedALERT、REPLAY拒绝与SCOUT/SWEEP合法；life30/32覆盖Back先关背包、取消/背包/menu/focus/reset解除touch ownership及下一独立tap、实际delay spawn focus/未来ring清除。触控为Input.parse事件，非物理手机。utility1041/1047包括R5工具和装备/成功丢弃取消；firearm7681包括90种gun/role/LOD配置、实际MG/空枪fallback和历史seek；visual130/164包括保存的历史装备/朝向/HUD/旧字段和只读对照。FX30/36只证明真实live wash/rim/static/tween进入history后取消、6关无旧效果回染，**不代完整3DFX/A3**。

credits127同候选复跑3次原radio三波1413/51、11物理PNG/26XTest、100/200 scroll/原按钮/Back及background隔离通过。已看三张overview，其余原生自动布局/行为检查；父端此前67f独立127/probe243/life30关闭仅为父端报告，不与本轮计数混合。

全部实际命令参数、环境、隔离UUID、exit、log和PNG摘要见[validation.json](evidence/20261003-pr15-full-record/validation.json)及每formal目录run.json。源5个production文件byte hash与d860核一致；15c之后交付只增加docs/evidence，game tree必须与15c完全相同。

## 旧schema1跨executor夹具

原二进制生成源 **874d3501fdd2b34b0966472e22a9e43a28a1b3dd**，实际command_record98/0、exit0/ERROR0，UUID0bcf92c368614cd386bd0be02ee9ad2b；5418800bytes，SHA256 **1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12**。旧域1283/34、旧播放1415、playback_schema1保持，当前读前读后hash相同。原文件随证据入Git。[来源/历史固定源重建](evidence/20261003-pr15-full-record/actual-schema1-874d350/README.md)含隔离导入、生成和检查命令；新Crypto attempt及真实启动时间使重建hash不同，只能重现格式/行为统计，不能冒称字节相同。当前full test允许指向新实际schema1文件。此轮没有重跑历史生成测试。官方LibraryID无；此前官方materialize失败，未重试、未绕过Library。

## 失败与已排队收尾

negative/development/preliminary/previous-*目录全部保全，各SHA独立计数。67 command98和1ab campaign10332基线真实exit0；67 campaign编辑运行中的Bash wrapper导致实际exit2，虽engine10332/0也排除。开发195/1因忽略真实启动SCOUT clock的错误oracle，195/0仍为提交前开发；b87 headless217的JSON被后续render覆盖、未留存，日志/退出仍保留。b87六关起帧oracle错误期待同tick第一帧，按已有last-state契约改为同时间最后帧；de27radio等待先于vacuum产生合法loot:448，多1event导致3172/3、exit1/ERROR3，生产未改。

7b3工具1041/1（空attempt夹具）和画面130/2（旧battle坐标）为已保存的新身份/播放时钟下的旧测试输入，15c修测试后分别1041/0和130/0；firearm headless明确拒绝模式exit2/ERROR1，没有配置断言。7b3 native单draw图在phase边界落后一帧，15c双draw及identity receipt实际图修正。旧失败与旧图均保留，未归入29项通过。

上一[安全边界checkpoint](AMBUSH_PR15_FULL_RECORD_CHECKPOINT_20261003.md)在23项时仍有6项render排队；随后只续同一session5976既有credits/lifecycle/utility/firearm/visual/FX，实际exit已收齐，无新增测试或重跑有效23项。全部29次完成后才整理证据与提交。

## 所有权与下一片

资产R5接口仍固定源29749157c5db064bfea626c3ed9d75d9a1791ece、交付ebedb829e3263abbeb6dd266905f24a3869fa281；20骨/socket/3LOD/52旧语义。ArtSource/GLB/atlas/Blender/制作manifest未改未重跑，runtime/presenter/replay/HUD/loader/共享测试归主集成，资产作者独立制作。

父端继承title200 P2：physical1600×720/200%/logical640×360，Help y369–417、Quit y427–475完全offscreen，XTest点击不开说明，原100%正常，源67f title.gd809，独立11/2exit1/ERROR0。当前title blob未改；**下一片独立修全菜单scroll/flow、Help返回、退出确认与键盘，100/200全journey**。父端独立QA针对fixed15c自行安排。之后完整3DFX、A3合批/LOD预算、正常六关玩家旅程、原两focus裁切、耳听0/45cue及0/6声景、同最终候选smoke/QA/可追溯APK仍待。Mesa llvmpipe不证明设备性能；设备/模拟器在全计划后，旧smoke7d34867/PCK91不归本源。GPT PLAN/REVIEW unavailable；保持Draft/Open、不merge/生产，不混height/G，不写Notion/Library。
