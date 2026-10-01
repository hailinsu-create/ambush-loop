# 当前 Cloud 修复的精确提交评审请求

日期：2026-10-01。状态：请求已准备，**尚未发送到已登录 GPT Project，也没有外部批准**。原 Project 地址保留在 `.codex/cloud/WEB_REVIEW.md`。

请在已有登录身份的原 Ambush Loop Project / 对话中发送下列控制消息。原 Project 是授权边界；本云会话只能打开登录页，不能代替用户登录。消息不包含源码摘要替代品或任何密钥，GPT 必须通过自己的授权 GitHub 来源读取文件。

> REVIEW — 请评审 hailinsu-create/ambush-loop 的 Draft PR #8，分支 codex/paperroute-cloud-exit-20261001。评审目标与证据提交均为 **629e3efccb253cea4937eb96002201207650e8e2**，基线为 **e3faeb5808b5d1b0a62ad9b479aa3f576ec0c3bc**；实际安装的固定工具包为 **99e6b70e831e28d672a14ab61029a71d1f9f982e**。请通过授权 GitHub 自行读取目标提交的 .codex/cloud/blender-headless.py、test-look-runtime.py、install.sh、install-look.sh、environment-setup.sh、environment-bootstrap.sh、START.md、WEB_REVIEW.md，以及 .cursor/docs/AMBUSH_CLOUD_COMPLETION_REPORT_20261001.md 和 ambush_loop/docs/cloud_completion_20261001/。重点核查子进程拥有权/回收、认证显示隔离、失败/超时/取消码、信号竞态、安装源/缓存校验、bootstrap 同版本及云配置的发布边界。先回报实际读到的 SHA、关键文件 blob 与来源，再给出阻断项、非阻断项和结论；无法确认来源时返回 unavailable。正常/失败/超时/信号/并发回归与完整渲染已有当轮证据，但历史 Blender 上游挂起根因未复现、新快照和真机验收未完成。历史评审不批准此提交，禁止合并 PR 或扩大网络权限。

关键文件的 source SHA、blob SHA 和不可变 GitHub 链接在 [review-request-20261001.json](../../.codex/cloud/review-request-20261001.json)。该 manifest 在干净工作树上生成，随后仅新增此请求及索引入口；它不声称这些后续文档也已得到批准。

收到真实反馈后：保留原文、来源/时间、实际读取证据、阻断项及采用决策，另提交回本 PR。若修改实现，生成新的评审目标 SHA；不将对旧 SHA 的响应扩展到后续代码。反馈不能替代 Android/vivo 或新环境发布后的实际验证。
