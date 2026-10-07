# M3 前本地开发收尾

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
| 冻结后院子引导 | 45df2b1a786345d5a830f3cd1a7bdc52 | 统一会话40443正在执行，尚未通过 |

截图位于各 run/m1-i-screens，实际已检查最新 960×540 操作布局和 1280×720 摘要/方案 B。48 Godot 逻辑像素不等于 Android 实际 48dp，设备测试暂缓。

## 外部评审

本轮实际读取原聊天 iteration5 对 `46ed6ad` 的三个问题：朝向预览与射界不一致、magnify 未取消候选、质量按钮高度40。上述已修复并由最新专项覆盖。GPT肯定前轮补给缓存、二分快照和权限/冷却快照字段；这不是当前整阶段批准。

iteration6 已在原聊天编辑框填写，按 Enter 的调用超时，随后同页内容读取也超时；**送达与新回复均未确认**。保留原聊天、c2c_a619、连接和 dirty reviewer checkout，不重复发送。独立源码包 `.cursor/review_packets/m25-closeout-edf58e5` 放在 B1 只读评审工作区，当前代码外审待核验，不宣称通过。

## 仍待退出门

本地：六关完整终态、复盘/准备恢复包装器后检、最终专项矩阵与 GitHub SHA 核对。设备：Android dp/误触、兼容/低档帧时、热/内存/后台/长稳。真人：艺术/声触反馈评价与五人盲测。后两类按用户暂缓，不阻断本地开发，但正式默认3D、M2/M2.5整体验收和进入M3发行门仍不关闭。

## 自动续收尾

原 `ambush-p0` 跟踪已完成后处于 PAUSED；本轮沿用它更新为“Ambush M3 前回归收尾”，同聊天 ACTIVE，每15分钟检查有意义变化。任务明确保留运行中长组、不重复启动/终止、不改冻结生产依赖；等全量与矩阵结束后单独复验准备恢复；失败按必要缺陷闭环，成功补终态并同步后停用。通知仅限完成、失败、需要授权或重大可操作变化。不需用户重复说继续。

代码/报告截至0c24ca01c65a5d43adadbabc25d12b8a48c2e8aa已推送并远端SHA核对一致；本段更新随后另作纯文档提交。没有改动已有未跟踪Godot UID文件，没有安装/卸载手机应用，没有伪造APK或真机验收。
