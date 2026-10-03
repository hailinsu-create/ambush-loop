# M1-C3 选中枪械队员高度覆盖实施计划

2026-10-02。原 GPT `c2c_d38a` iteration 0 实际 STATE: PLAN，核对工作区 `363712641ef7`；继承 C2 `e55a521` 的完整回归及 DONE。**已实现、定向测试通过，外部 GPT 已完成代码、自动化和五张原图的像素评审，iteration 2 实际 STATE: DONE（仅 C3）。** 此文替代 C3 预研的待确认状态。用户继续暂缓真机。

## 范围与理由

SETUP-only 的独立世界坐标 Node2D 图层，对当前选中、存活、可见的枪械队员采样 `_active_routes`，逐点调用 `in_fire_geometry`。使用独立小标记，不连线、不填面、不做其他队员并集。旧 aggregate killzone 和黄色方向扇形不改；几何覆盖不保证弹药/hold/冷却已允许开火。无持久缓存，不修改战斗、音频、路径、资源、冻结或回放。

生产仅 main.gd；新 `m1_height_coverage_gate.gd` 与两种隔离包装器。选择/转向/换枪/门/重置沿既有 killzone 刷新点同步；普通 SETUP command tick 比较实际选中队员位置，仅在其移动后刷新。掩体吸附临时 selected 恢复后明确刷新原身份，避免留下临时队员覆盖。阶段非 SETUP 必须清空/隐藏。

## 验证与证据

新门检查 LOW/FULL、地面与平台、混合高→低近高端 LOW 可通/近低端 LOW 拒绝、射程/朝向、未选中队员不贡献、近战抑制、重复刷新不累积；真实 ordinary move 和另一队员 snap 路径不手工兜底刷新；HP/弹药/朝向/路线/日志/tick 不因纯刷新改变。世界坐标与镜头 pan/zoom 不改变覆盖成员，无交互 Control。

隔离执行 C3、C2、C1、B2、feel focused UI；记录实际退出码和玩家数据不变。截图显示 LOW、mixed-tier、FULL、普通移动/镜头后的标记，Codex 目视和 GPT 独立评审。C2 已完成 fresh full smoke；本轮只观察移动并增加派生视觉，GPT 不要求再次六关 smoke。若改变共享移动语义/既有 killzone 行为或定向门有回归，再扩大回归。截图与 headless 结构门分别记录，不互相替代。

代码独立 C3 分支/PR，依赖未合并 C2 PR #16；文档独立 PR #9。精确镜像 C3 差异而非覆盖 dirty main；释放实际成功/失败输出供原 GPT 评审。C3 完成不等于完整 M1/B2、Android 或 AudioTrack 修复。下一步实现、测试、截图、送审，再更新此文和索引。

## 实际 GPT 截图工具修订

原 GPT iteration 0 明确 PLAN AMENDED：PowerShell 包装器可新增 `-Rendered`，仅允许 C3 gate，其他 entry/import 拒绝；默认仍 headless，保留原隔离与玩家数据 hash。C3 分别跑 headless 结构门和 rendered 截图门，不让渲染器存在决定几何通过。截图仅保存本轮 isolated run 输出目录，检查非空与 viewport 尺寸，实际目视及 GPT 评审。生产代码不区分测试渲染模式；shell 保持 headless-only。

## 实现、回归与实际评审

### 最终像素验收（覆盖下文历史 unavailable 状态）

2026-10-02 22:33 原聊天直接附加同一五张 PNG，未上传仓库到 Project、未新建/重连插件，源码与六项执行结果不变。原 GPT 实际查看全部五张 1280×720 图，明确 `STATE: DONE / TASK_ID: c2c_d38a / ITERATION: 2`，接受源码 `1de462aeb18665111849159945efc0f91d5144b5` 的 M1-C3。逐项确认灰狼身份、青色独立目标点与旧橙色并集/黄色扇形区别、LOW/near-high 有点而 near-low/FULL 无点、移动后镜头平移缩放仍世界锚定。无代码修正或额外回归要求。

图像附件是本轮送审路径修订，不是 `read_image` 工具发现故障的修复；原连接 doctor 全绿，该工具在 ChatGPT 中仍不可发现。直接附件的真实图像查看补齐像素门，不能以文件名、文字或大小代替。发送操作返回超时，但随后 DOM 核实消息、五附件和 DONE 已存在，未重复发送。下一开发切片需另取正式 GPT PLAN；PR #17/#16 仍 Draft、未合并，完整 M1/B2/Android/AudioTrack 不因 C3 DONE 自动完成。

评审记录：[原 GPT 对话](https://chatgpt.com/g/g-p-6ab943ae67ac81919bcbe3cd35ebe3b7-ambush-loop-collab/c/6aba7f25-906c-83ec-8054-159a82a62b20)。以下保留前次工具发现受阻的历史过程，以本节最终验收为准。

代码 [Draft PR #17](https://github.com/hailinsu-create/ambush-loop/pull/17)，分支 `codex/m1-c3-selected-coverage`，源码 `1de462aeb18665111849159945efc0f91d5144b5`，依赖未合并 PR #16。仅 main、新 coverage gate、feel gate 夹具、两份包装器五文件。生产 main 增加独立青色菱形点层；原 killzone 行为、战斗和音频未变。镜像保留旧诊断差异，不把 dirty main 当作 clean 源码；新 gate blob `df15d8d351ec8afdcc7d66ec5504fa7c9cfbe85c` 与 feel blob `8a13226dc194b26dc8013f777a0667327b687257` 与生产提交一致。

Godot 4.7.2 最终隔离执行均实际 wrapper exit 0 / `PLAYER_DATA_UNCHANGED=1`：

| 门 | run ID | 证据 |
| --- | --- | --- |
| C3 headless | `ded187408fe04e8eae94f79be58ba854` | `M1_HEIGHT_COVERAGE_GATE_OK`，真实 move/snap、混合高度、阶段/门/身份、只读与镜头不变性 |
| C3 rendered | `1aed218964934d3881cbbdd8ae839c3c` | 同结构门通过，五张实际 1280×720 PNG 非空；截图独立于结构验收 |
| corrected feel | `bd4960d7dd66452b9df9b2304195b3f2` | `FEEL_OK_WATCH_CINEMA`、`FEEL_GATE_OK` |
| C2 fire | `714bcee8750f4029837e9ef238b56fd6` | 敌我高度火力与原 BattleLog 回放边界 |
| C1 LOS | `153cdffbccda41f8a100b49d1e605d4a` | 高度插值与 legacy 边界 |
| B2 yard | `0fe3cd02ee624a73b3f09f65b93775da` | 上下坡随队与双向断坡反例 |

`-Rendered -Entry smoke_test.gd` 实际被包装器拒绝（exit 1），未启动 destructive smoke。shell 未在本轮执行。按实际 GPT PLAN，没有重跑第二次六关完整 smoke；继承 C2 的 fresh full 证据不伪称 C3 新跑。

失败保留：初次 `0b93e52847684526beb198a77e74ce9e` 使用错误 `_select_op(Object)`，PowerShell scalar splat 还把 `--headless` 拆成字符；仅停止精确测试引擎，wrapper exit 1/数据不变，修正 gate 参数与恢复显式默认 headless 分支后通过。首次 standalone feel `ec98af54d0ba4e718e6c4e263e5c37d6` exit 2 `watch_cinema_unused`；干净 detached C2 `e55a521` baseline run `b182b565d97542c7abbe6fd486c6a445` 重现相同失败，compound parent exit 1（不能伪称该 parent 是 exit 2）。原 GPT iteration 1 实际 correction PLAN：仅 feel 夹具用 `apply_weapon("rifle", true)`，保持真实部署/警报并明确断言 WATCHING，避免只看到无枪警告。生产警报/武器规则未改，最终 feel 通过。

截图首批被教学弹窗遮挡，后续批次仍有暂停处理导致的旧 portrait 选中态，均不作为最终图像证据。最终五张已在 Codex 逐张目视，教学弹窗关闭、侧栏和 portrait 都为灰狼、LOW 与 mixed-near-high 有离散点，mixed-near-low/FULL 无点，move/pan 仍有世界锚定点。[截图说明与原图](evidence/m1c3/README.md) 明确这是受控 yard 夹具，不是新关卡作者数据或手机画面。

原 GPT iteration 2 实际评审：code and automated regression side is clean，读取当前 scoped 差异与六项执行记录，并确认五张 PNG 存在；但当前会话工具未暴露 image-reading operation，因此**不能独立查看像素，未给 C3 DONE**。本机连接实现/构建已包含 `read_image` 且使用既有 workspace.read 权限，doctor green、服务在构建之后启动、强制更新检查为当前版本。保持同一对话/连接器，尝试精确工具发现；不得以文件大小/文字描述替代像素评审，不因页面超时重发 EXECUTED 或删除健康连接器。下一步仅补同一连接器的五张像素评审；如可用且通过，无需改代码或重跑已通过门。完整 M1/B2/Android、旧 AudioTrack 问题仍未闭环。
