# M3 前本地开发收尾

## 2026-10-07 最新终态与外审修正（覆盖下方历史状态）

12:31终态：原聊天实际读取iteration7，STATE DONE，REVIEWED_SOURCE ec832057582c1ad567cc1aa3bc72b7437bfac45b，PRODUCTION_CORRECTION1d27c42。GPT通过只读包核实三项iteration6问题均修复：终态历史定位且不seek、中性回放姿态明确标注、candidate48逻辑px；此前magnify/纯预览、墙分区、事件索引、模态与opt-in保持正确。实际读取execution_output93，stdout不是wrapper证据，终态后检另据receipt。批准仅限本次本地P2–P5收尾，不覆盖手机/人体触摸/热内存/最终美术/M2或M2.5整体，也不关闭c2c_a619。所列本地回归与外审已完成，报告同步后停用本次回归跟踪；设备列表仍空，真机待连接后继续。默认3D仍false，旧红灯/聊天/连接/B1脏工作区保留。

12:16续收：B1连接doctor全绿，原聊天真实内容仍为iteration6。已准备只读包 `.cursor/review_packets/m25-closeout-ec83205`：完整archive解包遇中文文档路径错误，另对scripts/project.godot定向archive成功解包exit0；评审所需脚本以该定向包为准，不声称整仓解包无误。iteration7执行摘要与smoke stdout已记录。原聊天填写并Enter提交iteration7成功返回，但随后DOM两次读取超时，**消息送达/新回复未确认**；禁止重复发送。原c2c_a619 checkpoint、dirty B1源码和连接未改。下次只读取原聊天末尾核验iteration7，不重跑已绿回归。设备/真人仍未验。

2026-10-07 11:46终态：冻结测试源码ec832057582c1ad567cc1aa3bc72b7437bfac45b（生产1d27c42）的完整六关b213d0b5e3974424a21c484e079d283e已从统一会话20164取得最终退出0：yard/warehouse/pump/railcut/depot/radio均raid won，SMOKE_OK_RAID_LOOP、SMOKE_OK_TYPICAL_LOOPS、SMOKE_SLICE_COMPLETE齐全；TEST_RUNTIME_ERRORS=0、PLAYER_DATA_UNCHANGED=1、TEST_ENGINE_EXIT=0、SEQUENTIAL_WRAPPER_EXIT=0 ENTRY=smoke_test.gd。对应Godot进程已结束。新源Forward+、复盘生命周期、准备恢复与完整六关所列门均有绿灯，不再等待此长组，不重复启动。旧红灯保留。精确新源GPT复审仍待，设备仍无ADB连接、APK未安装，真人门未验；不宣布M2/M2.5或M3入口通过，跟踪暂不停用。

新源恢复aaf8a58b8cc8445a86e96bf8543564e4已取engine0/runtime_errors0/player unchanged1/SEQUENTIAL_WRAPPER_EXIT0完整终态。队列20164进入完整六关 `b213d0b5e3974424a21c484e079d283e`，console10792/子引擎38540，仍运行。用户重连手机后短时可读，随后再次offline；新源APK已备妥、尚未安装，见荣耀报告，不阻断本地长组。

2026-10-07 11:16续收：ec83205新源复盘run2a0a3ec991d7421dae13f538569ad708已取得完整完成、engine0、runtime_errors0、PLAYER_DATA_UNCHANGED1及SEQUENTIAL_WRAPPER_EXIT0。同会话20164自动进入恢复run `aaf8a58b8cc8445a86e96bf8543564e4`，PID38624；尚未取得恢复终态，之后仍为同源完整smoke。不要重复启动或改生产依赖。

新源顺序队列统一会话20164，首门复盘run `2a0a3ec991d7421dae13f538569ad708`，engine PID38756；后续run由同会话自动依次产生，必须取SEQUENTIAL_WRAPPER_EXIT及包装器后检，不能重复启动。原自动跟踪中的会话32544已完成，本节覆盖其旧运行提示；继续跟踪20164。手机断连不阻断此本地队列。

新冻结ec83205的第三次Forward+收尾f72a5e3…已从32625取得完整终态：新增历史定位、不seek、首快照前反例、中性姿态、两尺寸candidate以及3D A/B胜利均通过，runtime_errors0/player unchanged1/engine0/wrapper0。1280×720摘要截图已目视检查。下一顺序队列：新源复盘生命周期→准备恢复→完整smoke；任何失败立即停在失败门，不改冻结生产依赖，仍不把旧六关结果当新源通过。

最新冻结 `ec83205`：生产仍为1d27c42，仅补齐测试fire事件必需target_id字段。`ea76b921fd7f46f9bb35000ed1fedfc7` 虽engine0/完成标记，但格式化测试事件缺target_id造成runtime_errors1、wrapper94、player unchanged1，保留红灯。第三次Forward+收尾 `f72a5e3fc2624a208de9390c4a64028c`，会话32625，正在运行；它的终态覆盖下方“正在执行”历史描述。

旧冻结生产源f8ad51c完整六关run `e4e3c93d3b7540a3ba4231fd5aa7e467` 已从会话32544取得最终证据：六关胜利、SMOKE_OK_RAID_LOOP、SMOKE_OK_TYPICAL_LOOPS、SMOKE_SLICE_COMPLETE，TEST_RUNTIME_ERRORS0、PLAYER_DATA_UNCHANGED1、TEST_ENGINE_EXIT0、WRAPPER_EXIT0。不能据此批准后续新源。

旧源准备恢复单独run `c5f9d4d0a1e14916ac2ec7100a1cff56` 会话20197终态：两案20次恢复、原生恢复/重开、库存守恒及其他关拒绝全部完成，runtime_errors0、player unchanged1、engine/wrapper0。高点10次计时727–1745ms，保留旧5253ms红灯，不改5000ms阈值。

本轮原GPT聊天已真实读到iteration6，上次消息已送达，不重复发送。它指出：结算事件定位使用最终live位置；回放把存活演员全部显示瞄准；摘要candidate开关无48逻辑px下限。生产修正 `1d27c42`：事件tick二分历史查询独立于是否进入REPLAY且不seek；缺失历史动作字段时明确标“复盘静态姿态”而不是猜测动作；candidate最小高48。新增实际终态历史定位/不seek/早于首快照/中性姿态/小窗开关门。新冻结源码 `2dc4d63` 仅另修测试显式Vector2类型。

首次新源门run `e4bb9daae03b4c08b9d1b7f8161ee8ed` 保留红灯：新测试历史位置变量类型推断失败，runtime_errors1、engine/wrapper1、player unchanged1。修正后Forward+ run `ea76b921fd7f46f9bb35000ed1fedfc7`，会话43574，正在执行；不得在它运行时修改生产依赖。随后必须新源复盘生命周期/恢复和完整六关回归，旧绿灯不替代新源验证。外审发现已实现修正，但新修正尚无GPT批准。

用户已恢复手机测试，荣耀首轮见AMBUSH_HONOR_M25_DEVICE_20261007.md；本轮ADB命令长时间卡住，停止本轮卡住的只读客户端并对该设备reconnect后列表为空，没有卸载/清档。手机长稳/dp/胜利仍待；真人门继续暂缓。默认3D发行值仍false。当前不能宣布M3前全部完成。

用户本轮要求做完 M3 前开发；真机与真人门维持暂缓，其他不得据此跳过。当前基线 ab5c0e2，沿原分支推进，不另起项目。

切片顺序与验收：

1. P2 操作完整：明确朝向手柄、候选位置/朝向射界查询（纯参数化、无临时改动权威对象）、补给上下文前往搜索与目标身份验证、左右手及安全区布局。
2. P3 回放成本：有序事件窗口二分、历史查找与 rewind/重复 tick 反例；dirty 重建及节点平台；质量档和声音设置复用原系统。
3. P4 院子样板：合并相邻阻挡为连续墙体、保留逻辑边界与拾取语义；角色基础步态/搜索/开火/倒地表现、仅显示层遮挡轮廓，不透明化改变 LOS。
4. P5 3D 流程：三人开战摘要与非保证胜利提醒，事件失败定位在 3D 镜头可用，引导文案适配，候选默认 3D 开关（保留回退，发行默认受设备门控制）。
5. 冻结源码；专项/Forward+ 布局/两案/资源/复盘/取消/六关完整隔离回归；复审精确 Git archive，保留原 GPT 聊天和检查点。最终同步 GitHub 并核对 SHA。

可选挑战按 GPT 原规划降为扩展，不阻塞本地收尾；不改规则、不增关卡、不自由旋转相机、不加入动态体积雾。不能把桌面证据写成手机或真人结果；外审不可用如实记 unavailable。

本文件随每一切片更新已实现、已验证和剩余门，历史红灯保留。源码/包装器退出/存档后检均须核对，脚本错误即使 engine=0 仍红灯。

## 本轮实现与冻结

- P2 实现 `179b7eb`：独立朝向手柄，纯参数化候选位置/朝向几何查询，未执行预览明确标注；点击队员不再隐式启动朝向拖动；上下文搜索绑定补给实例与位置，仍由原寻路/搜索通道发放资源；左右手持久设置。`f8ad51c` 补 magnify 取消/迟到 release 隔离、应用失焦取消及 48 逻辑像素按钮下限。
- P3 实现 `f8ad51c`：事件窗口 stateless lower-bound 二分（重复 tick/回退不依赖游标），历史快照按 tick 缓存，隐藏的纯 MapDraw/RoutesDraw 停更并可恢复。保留前轮补给实例复用和固定 FX 上限。质量按钮复用持久设置；仅改变表现，不改射线/胜负。桌面同步耗时不是手机帧时。
- P4 实现 `f8ad51c`：阻挡格按同类连续矩形合并为墙，精确分区且保留逐格拾取边界；原创角色增加固定节点步态、搜索、瞄准、开火后坐、命中颜色、倒地和接地标记；侧翼背包可辨，单位标签不受前景遮挡但不暴露未激活敌人。属于程序化样板，不宣称达到真人美术评价。
- P5 实现 `f8ad51c`：三人弹药/朝向/许可开战摘要，模态阻断地图输入，显示“覆盖不保证命中或胜利”；候选默认 3D 可显式勾选并持久化，发行默认仍 false；事件定位复用原记录位置并同步 3D 相机和复用定位标记；院子引导文案适配 3D。可选挑战保持后续扩展。
- 最新完整 SHA `edf58e5e980e7e8bd5777f21ed4a553b6a44dd65`，与 `f8ad51cbb9408cb6acfb35d1b48c4310c035227a` 仅独立收尾门夹具不同，生产运行源码相同。完整 smoke 启动于 f8ad51c 后不改其生产依赖。

## 测试证据（不覆盖设备/真人门）

| 门 | run | 当前结论 |
| --- | --- | --- |
| 3D 接缝/资源/镜头/候选朝向 | e53909850ac949e89011202ebcd56a5b | 完整完成，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1；早于最终 magnify/按钮修正 |
| 首轮 Forward+ 收尾、墙体/窗口/摘要/两案 | c970298fd05949fa81d5b98e90f1f216 | 完整完成，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1；早于最终修正 |
| 首次最终夹具 | 39b96364757741ddbe4ecc072bd22303 | 保留红灯：engine/wrapper2，runtime_errors0，存档未改；960 物理尺寸与逻辑坐标混用，未改游戏布局 |
| 修正后 Forward+ 收尾 | ec139b24820b45348560c5493637f203 | 完整完成，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1；手柄 GUI 实际入口、缩放取消/迟到抬起、48逻辑像素、960×540/1280×720截图、精确墙分区、6000事件重复tick/rewind、摘要只读、候选偏好重载、3D A/B真实胜利、不隐式回2D、事件标记均通过 |
| 最新六关全量 smoke | e4e3c93d3b7540a3ba4231fd5aa7e467 | 正在运行，不登记通过；包装器统一会话32544 |
| 复盘生命周期 | 4768e7678c434b3ea658fd06238a8c30 | 完整完成，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1；native/manual checkpoint/free position/single owner/exact restore/fresh restart/readonly均通过 |
| 准备恢复（与长组并行） | 3cb15475f18c454482c9394f578f1859 | 保留红灯：engine/wrapper2，runtime_errors0，PLAYER_DATA_UNCHANGED1；10次恢复中 repeat5耗时5253ms超过5000ms，其余库存/朝向/只恢复一次/原生UI/其他关拒绝均通过。不能据并行负载直接豁免；待其他测试结束后单独复验，不改阈值 |
| 冻结后 3D 接缝 | d6c6f89cf0594e0cb8e2dd6f5fa73ce2 | 完整通过，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1 |
| 冻结后战术数据 | c5f53a1c1d114aeb917b24a3ade6553e | 完整通过，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1 |
| 冻结后 3D 信息 | 93e6c3a874344975acafc32991e46a4e | 完整通过，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1 |
| 冻结后确认/取消八类 | 5064b871dd274e2dae2d9a1d32fadca1 | 完整通过，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1 |
| 冻结后院子引导 | 45df2b1a786345d5a830f3cd1a7bdc52 | 完整通过，engine/wrapper0，runtime_errors0，PLAYER_DATA_UNCHANGED1；真实资源/部署/战斗/复盘重试及其他五关引导保留均通过；矩阵会话40443已结束exit0 |

截图位于各 run/m1-i-screens，实际已检查最新 960×540 操作布局和 1280×720 摘要/方案 B。48 Godot 逻辑像素不等于 Android 实际 48dp，设备测试暂缓。

## 外部评审

本轮实际读取原聊天 iteration5 对 `46ed6ad` 的三个问题：朝向预览与射界不一致、magnify 未取消候选、质量按钮高度40。上述已修复并由最新专项覆盖。GPT肯定前轮补给缓存、二分快照和权限/冷却快照字段；这不是当前整阶段批准。

iteration6 已在原聊天编辑框填写，按 Enter 的调用超时，随后同页内容读取也超时；**送达与新回复均未确认**。保留原聊天、c2c_a619、连接和 dirty reviewer checkout，不重复发送。独立源码包 `.cursor/review_packets/m25-closeout-edf58e5` 放在 B1 只读评审工作区，当前代码外审待核验，不宣称通过。

## 仍待退出门

本地：六关完整终态、准备恢复单独复验与最终 GitHub SHA 核对；复盘/专项矩阵已完成。外审新源回复待核对或如实unavailable。设备：Android dp/误触、兼容/低档帧时、热/内存/后台/长稳。真人：艺术/声触反馈评价与五人盲测。后两类按用户暂缓，不阻断本地开发，但正式默认3D、M2/M2.5整体验收和进入M3发行门仍不关闭。

## 自动续收尾

原 `ambush-p0` 跟踪已完成后处于 PAUSED；本轮沿用它更新为“Ambush M3 前回归收尾”，同聊天 ACTIVE，每15分钟检查有意义变化。任务明确保留运行中长组、不重复启动/终止、不改冻结生产依赖；等全量与矩阵结束后单独复验准备恢复；失败按必要缺陷闭环，成功补终态并同步后停用。通知仅限完成、失败、需要授权或重大可操作变化。不需用户重复说继续。

代码/报告截至0c24ca01c65a5d43adadbabc25d12b8a48c2e8aa已推送并远端SHA核对一致；本段更新随后另作纯文档提交。没有改动已有未跟踪Godot UID文件，没有安装/卸载手机应用，没有伪造APK或真机验收。
