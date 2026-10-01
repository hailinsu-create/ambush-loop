# 云端开发、网页评审与 PaperRoute 迁移交接

日期：2026-10-01。用户要求将游戏开发、原网页 GPT 审核/规划和 PaperRoute 一并迁移；仅本游戏，不涉及其他项目。

## 范围与保留规则

- 云端候选分支 `codex/cloud-main`，Draft PR #7；包含 B2 桌面补验、规划历史及 Android 诊断改动。发布分支不等于合并主线或真机验收。
- 保留网页 GPT 原 Project、对话和历史反馈；新增可发现技能与精确 SHA 的 PLAN/REVIEW 契约。现有本地 C2C 连接和 Android 诊断会话不覆盖。
- 保留 `.cursor/skills/paperroute-game-build/`、`SKETCH_PAPERROUTE.md`、`ArtSource` 脚本、GLB 和样板。新增 `.agents/skills/` 入口与云端 Blender 5.2.2、glTF CLI 4.5.1 安装脚本，不重做美术、不修改玩法。
- 不迁入本机绝对路径配置、OAuth 凭据、签名密钥、配对码或个人手机数据。Meshy 无授权密钥时继续跳过；不自动购买/调用收费生成。

## 当前证据与缺口

已验证：Godot 首次 editor import 后，本地隔离 Accept-to-Yard 门通过；官方 Blender 归档与校验文件可访问；原 C2C doctor 正常，原网页对话 DOM 成功读取。上述不是云端工具或新代码网页批准。

本次打包检查：两个安装脚本经 Git Bash `bash -n`，退出码 0；`git diff --check` 退出码 0。`install.sh` 会串行安装 Godot 与 Look 工具，Shell 文件固定 LF；不以语法检查冒充 Linux 安装/渲染通过。

2026-10-01 后续：用户完成 GitHub 授权。云端页面确认本游戏仓库可选，已保存 `Ambush Loop Cloud` 环境，编号 `6abdb7e5d66c8191842afe8f89853403`。配置 universal/Ubuntu 24.04、手动安装、容器缓存、任务运行期网络关闭；安装/维护阶段可联网。未添加密钥。保存后的详情页已核对安装与维护命令。环境列表另有同仓库同名条目，保留未删除。

安装入口固定迁移提交 `c8a9fa4806fb95173b7f6ce2481c50a1dab96ef2` 的两个安装脚本，安装 Linux 图形依赖并执行。首轮使用 `git fetch origin` 提取失败：该云容器没有可用的 `origin` remote。后续引导改为固定提交的公开 GitHub raw 文件下载，不依赖云容器 remote；默认 `main` 尚无脚本时也能引导。后续维护使用任务检出的仓库脚本。

已通过官方 CLI 在 `codex/cloud-main` 提交首个验证任务：
https://chatgpt.com/codex/tasks/task_e_6abdba17e8788332b9ce551703a9ee4b

任务要求核对精确 SHA、工具版本、隔离 Accept-to-Yard 门，以及临时副本中的道具生成/glTF 检查；禁止改玩法、推送、合并或冒充外部批准。首轮状态由 PENDING 转为 ERROR，网页日志确认 Linux 系统依赖已安装，随后 `git fetch origin` 失败，Godot/Blender 安装和测试尚未执行；不算迁移通过。

修正后的设置命令已保存并重新读取确认；可复现副本为 `.codex/cloud/environment-setup.sh`。重新提交验证任务，目标代码 `2933da0b4a7a97703a599e5a50f5989d0b2f68c6`：
https://chatgpt.com/codex/tasks/task_e_6abdbc4d29308332be5ab93be3bcc26a

新任务提交成功，不代表实际工具安装或测试已通过。任务指令中的精确提交是它提交时的分支状态；后续文档提交不得被当作该任务评审过的代码。

重试后网页日志确认 `Godot Engine v4.7.2.stable.official.ed1daf0bf` 已启动导入工程；随后页面从“正在设置环境”进入任务执行，出现“Capturing import logs with exit codes”和读取 PaperRoute `build_yard_crate.py` 的记录。原 `origin` 引导阻塞已越过。最后观察时任务仍执行中，CLI 为 PENDING、没有 diff；尚无最终隔离门退出码或新渲染验收报告，不将运行中写为通过。

此前记录的 `https://chatgpt.com/remote/task_e_6abdbc4d29308332be5ab93be3bcc26a` 路径在手机端显示 404，不能作为有效入口；该旧任务应从 Codex Cloud 任务列表打开。后续任务使用新版 Cloud task URL（见下方实时状态）。

仍待验证：该任务实际安装和运行结果、Linux Godot 门、Blender 渲染及 glTF 检查、同提交的首次网页 PLAN/REVIEW、APK 和 vivo 真机门。浏览器动作偶发超时，操作后重新读取已核对保存结果；不再将“云环境未创建”作为当前阻塞。

## 下一步与验收门

1. 云环境绑定本仓库、`codex/cloud-main`，运行 `.codex/cloud/install.sh` 和 `.codex/cloud/install-look.sh`。需要 GitHub/账户授权时才找用户；不索取 token。
2. 保存 Linux 安装和隔离门的实际退出码。若缺图形依赖，在环境安装官方 Linux 系统依赖；不要以历史素材代替新渲染。
3. Look 独立切片重生成一件道具，检查 GLB、turnaround、iso/top、引擎截图；提交来源脚本与可复现证据。Engine 独立回归，不改变冻结契约。
4. 网页审核必须读取精确云端 SHA；按 `.codex/cloud/WEB_REVIEW.md` 验证来源，反馈入库并更新本索引。不通则 unavailable，不能虚构批准。
5. 发布环境后从该分支启动单个切片，Android 验收保持本机待办，旧 AudioTrack 根因不标记修复。

此文件补充迁移与工作流，不替代设计 v2 或当前 B2/Android 质量门。

## 2026-10-01 实时 Cloud 复验状态

已发布环境 `ambush-loop`，仓库 `hailinsu-create/ambush-loop`，任务使用 `codex/cloud-main`。设置页显示网络范围为“包管理器 + 5 个指定域名”（`api.github.com`、`downloads.godotengine.org`、`github.com`、`godotengine.org`、`release-assets.githubusercontent.com`），未配置密钥；不是“全部不受限制”。

从该环境创建的云任务：

- 标题：`执行云端迁移验收测试`
- 任务：https://chatgpt.com/codex/cloud/tasks/task_e_6abddca04260833297732b1f9fd73797
- 检出源：`codex/cloud-main`，提交 `56bea5e790080433b565b6f23bb0cf428d0472ea`
- 结果：Godot 安装尚未完成，隔离导入/门禁尚未运行，PaperRoute 未执行，不能记为通过。

云执行器的继承代理对已放行域名及包管理器站点均返回连接阶段 `HTTP CONNECT 403`，下载未到达源站；因此没有安装 Godot，也没有运行测试。该任务中未提供 `/etc/codex/network-policy.json`，当前工具目录也没有运行时环境状态接口。这些现象证明本次出口不可用，但不足以确定究竟是哪一层策略拒绝；不通过绕代理或扩大至不受限联网来规避。

2026-10-01 查阅官方排障说明：环境域名设置与 Enterprise Agent Security 策略可能同时生效；特定 `allow_local_binding=false` 策略还可能导致即使域名已放行，云任务仍无法连到上游代理。[Cloud 环境说明](https://learn.chatgpt.com/docs/environments/cloud-environments) · [Agent Security 网络策略](https://learn.chatgpt.com/docs/enterprise/agent-security)。目前没有证据确认此账号属于 Enterprise workspace，也没有有效策略快照能确认该字段；这只是一个待核实的可能原因，不是已诊断根因。若工作区有管理员，应核对 Cloud 环境的有效 Agent Security 网络策略；若没有，应携任务 ID 与 `HTTP CONNECT 403` 结果向 OpenAI 支持反馈。不要把环境切到“全部不受限制”，也不要绕过代理。

本机 `codex/cloud-main` 与 `origin/codex/cloud-main` 在复核时均为上述 SHA。工作区里原有未跟踪文件 `ambush_loop/scripts/r45_sweep_gate.gd.uid` 与 `error.log` 保留，未纳入本次文档变更。用户无需在手机端另建云任务；请在 Codex Cloud 任务列表查找标题，或使用上方正确链接。

同一精确提交的外部 GPT PLAN/REVIEW 尚未取得；专用只读评审连接尚未建立，当前连接选择待用户确认（固定域名 `hailinsu.top` 或临时地址）。连接完成前，不把旧本地工作区或旧提交上的历史反馈当作本次批准。下一步分别是：解决/定位该 Cloud 环境出口拒绝；取得精确 SHA 的实际外部评审；然后安装 Godot/Blender 并记录可复现的 headless 与 PaperRoute 证据。Android 与 vivo 门仍在本机完成。

PaperRoute 依赖核对补充：`.codex/cloud/install-look.sh` 从 `download.blender.org` 下载 Blender 5.2.2 归档及校验文件；该主机不在当前“包管理器 + 5 个域名”列表中。npm 的 `registry.npmjs.org` 属于包管理器预设，不需再加自定义域名。等已允许站点能正常连通后，如需云端 Look 安装，只为 Blender 源站和日志实际证实的重定向目标添加最小域名；先前任务对 `pypi.org` 等均遇到连接阶段 403，所以现在加此域名无法证明修复，也不应扩大权限。

2026-10-01 公共状态页核对：当前仅列出 ChatGPT Space Pages 的错误事件，未列 Codex Cloud/网络出口事件；这不能排除账户级策略或未公告的单独故障。[OpenAI 状态页](https://status.openai.com)。

2026-10-01 复核并更正云任务来源判断：任务页面元数据显示仓库为 `hailinsu-create/ambush-loop`、所选来源分支为 `codex/cloud-main`；任务内 HEAD `56bea5e790080433b565b6f23bb0cf428d0472ea` 与该分支当时的源码 SHA 相同。容器内部显示分支名 `work` 且没有 Git remote，是执行器布局，不足以判定取错仓库；撤回此前的“workspace mismatch”结论。仍然成立的失败是下载阶段 `HTTP CONNECT 403`，Godot、隔离门及 PaperRoute 没有完成。该旧任务不覆盖之后的新提交，也不为它们提供评审。

2026-10-01 本地安装安全修复已提交并推送到 Draft PR #7：`5f6cdff` 为官方 Godot 4.7.2 Linux 归档加入固定 SHA-512 校验，失败时在解压前终止；`8e8ba5d` 将云端 bootstrap 固定到含该校验的安装脚本。显式安装 `coreutils`/`curl`。本机 Git Bash `bash -n` 与 `git diff --check` 均通过，提交已推送且分支与 PR 同步核实。后续提交 `2ea4453` 更正云任务来源记录并更新索引。这不是 Linux 安装、Godot 导入、PaperRoute 渲染或运行测试通过；因云任务仍遇 403，未重复创建新的无效任务。未跟踪用户文件 `ambush_loop/scripts/r45_sweep_gate.gd.uid`、`error.log` 仍保留。

外部 GPT 精确 SHA 评审仍未完成。连接新云端工作区的地址偏好待用户选择（固定 `hailinsu.top` 或临时地址）；在获得选择前不修改原工作区连接。后续若出现实际安全连接授权页，再单独请求用户批准。
