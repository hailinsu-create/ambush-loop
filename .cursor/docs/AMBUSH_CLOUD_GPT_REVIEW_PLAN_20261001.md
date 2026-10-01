# 不依赖本机的外部 GPT 评审流程

日期：2026-10-01。状态：流程提案，尚未取得本轮外部 PLAN/REVIEW。用户要求完成云端迁移；本方案不新增网络权限、不运行本机服务、不覆盖已有连接器或对话。

## 选择与依赖

首选既有 Ambush Loop ChatGPT Project / 对话中的授权 GitHub 来源，由网页 GPT 直接读取本仓库的精确提交、PR 和证据。Codex 在云端实现、测试并通过 GitHub 存储资料；GPT 在 ChatGPT 侧访问 GitHub，不经过云容器出站调用、Windows C2C、Cloudflare 本机隧道或 localhost。保留 Project 与对话地址，见 `.codex/cloud/WEB_REVIEW.md`。

当前可验证的是 GitHub Git 读写与 PR API；当前会话没有 ChatGPT 浏览器、Project 控制或外部 GPT 调用工具，也没有可验证的 ChatGPT GitHub 连接状态。不能据此宣布该流程已连通或已批准。必要前提是该 Project 中的授权 GitHub 来源能读取 **指定 SHA**；若连接仅索引旧分支、不能读取提交或证据，标记 `unavailable`，保留 Draft。恢复访问时回到同一 Project，不新建重复连接器。用户无需运行本机服务。

## 每轮流程

1. PLAN：云端先提交 dated planning request，包含需求、约束、父 SHA、目标文件和验收门；推送后核对远端。给既有网页对话一条短控制消息，让评审器通过 GitHub 自行读该提交。保留真实答复原文、来源与采用/未采用理由。PLAN 无法获取时记录 unavailable；用户明确授权的独立修复仍可执行，保持未获外部批准。
2. 实现：单一切片提交；生成并保存当轮实际退出码、日志、图片和校验摘要。Engine 与 Look 分离，不提交签名、密钥、手机个人数据或无关产物。
3. REVIEW：推送代码与证据，记录实现 SHA 和证据 SHA，发出明确的 REVIEW 请求。评审器必须通过 GitHub 自行读实现提交的目标文件和证据提交；不能把聊天中的摘要作为源码读取证明。
4. 身份核对：要求回报实际读取的仓库、实现 SHA、证据 SHA、目标文件路径与 blob SHA / 实际读取的关键变更。云端用 GitHub API 或 Git tree 对照；仅复述消息中的 SHA 不构成读取证明。
5. 入库：保存原始答复、读取证据、阻断项、非阻断项、判断与时间。状态只能按事实记录 `unavailable`、`changes_requested`、`reviewed_no_blockers`；代码评审通过不代表运行、引擎画面或 Android 验收通过。
6. 变更后重新评审：修复引入新的实现 SHA 即撤销对旧 SHA 的适用性。仅记录评审的明确覆盖范围；不自动批准之后的文档/代码提交。PR 维持 Draft；本轮不合并。

## 可直接发送的控制消息

PLAN：

> PLAN — hailinsu-create/ambush-loop，分支 codex/paperroute-cloud-exit-20261001，计划提交 1ea3492b94c45670c98825a15ff8c2fbf3ee7938。请经授权 GitHub 自行读取 .cursor/docs/AMBUSH_CLOUD_EXIT_PLAN_20261001.md、迁移交接及目标安装脚本，给出单一退出修复切片、验收门与停止条件；先回报实际读取的 SHA 和文件来源。历史反馈不适用于此提交。

REVIEW 模板（填入最新、已核对的证据提交后使用）：

> REVIEW — hailinsu-create/ambush-loop，Draft PR #8，实现 SHA 75209831bbf86e9deb53e52137bff65c1025c908，证据 SHA <verified-evidence-sha>。请经授权 GitHub 自行读取 .codex/cloud/install-look.sh、environment-setup.sh、START.md 与 .cursor/docs/AMBUSH_CLOUD_EXIT_REPORT_20261001.md 及其证据目录。核对实际文件/blob 与提交身份后，评审退出状态传播、Xvfb 生命周期、固定工具版本和历史 bootstrap 的部署限制。明确区分已验证正常退出、尚未复现的历史挂起根因、未验证的新实例部署与实际引擎画面/Android 验收。访问不完整请返回 unavailable，不沿用历史批准。

## 停止条件与后续

源提交不可访问、无法证明读取身份、只返回摘要、没有真实答复时，不继续宣称批准，不以另一个 Codex 代理代替 GPT。API 自动化与 GitHub Actions 集成不在本轮实施；新增 API 密钥、收费调用或域名权限需单独需求与授权。本轮没有申请或修改这些配置。

下一步是在既有 Project 中验证 GitHub 精确 SHA 读取并补发上述请求，保存实际外部反馈。该操作当前缺少可调用网页工具；本轮仅交付可执行流程与待评审材料。
