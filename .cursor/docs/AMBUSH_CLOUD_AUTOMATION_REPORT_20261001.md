# 云端核验自动化报告

日期：2026-10-01。用户要求自动化。实现入口首次提交 ccbff7cb905c459e11410bb0b9906922b669d7a8；runner 配置修复 0069a88ce7a1605efa8bf0f4da9d742b61d2303f；增加精确源/blob manifest 的实现 09eeb584a15dbf259d15a7f0487560ba2cd561f5。PR #8 保持 Draft。

## 自动化能力

`.codex/cloud/verify.py` 要求干净 checkout、新输出目录、安装 launcher 与目标提交一致。它用 git archive HEAD 运行真实工具和隔离游戏门，不使用旧产物；保存逐步退出码、完整日志、渲染结果、source/blob 清单与三种独立状态。相关 codex 分支推送和 PR 更新自动触发 GitHub Actions，在 Ubuntu 24.04 冷安装固定 Godot/Blender/glTF。actions 固定源码 SHA；权限仅 contents:read，不调用 ChatGPT、写源码、合并或修改网络。

Actions 在成功/失败时上传证据（保留 30 天）并写摘要。上传证据不意味着外部评审通过。安装失败时仅安装日志；进入 runner 后保存 verification.json，包括失败状态。自动化没有修改玩法或已有资产。

## 当轮真实验证

当前云端对 ccbff7c 的完整入口退出 0：八个命令检查通过，包括真实生命周期、完整渲染、GLB inspect、Godot import 和隔离 Accept→Yard。三个新 PNG 尺寸为 960×480、256×256、256×192。生命周期 suite 无新增遗留进程。后续源 manifest 对 09eeb58 的九个文件 blob 与 git object 逐个一致；缺失工具反例退出 1，结果为 failed，不伪造通过。首次因本轮 py_compile 产生未跟踪 __pycache__ 被干净工作树守卫拒绝，清除仅该生成文件后才重跑通过。

证据：[cloud_automation_20261001](../../ambush_loop/docs/cloud_automation_20261001/)。本地全套结果针对 ccbff7c，不能冒称后续 CI 已通过。

首个 GitHub run 36908320668 在执行前因 job env 中 runner.temp 上下文无效而拒绝；已将目录初始化移入 step，后续冷 runner 实际启动。0069a88 PR run 36908481089 的下载命令退出 22；其产物下载被 Azure blob 出站拒绝，不扩大域名、保留失败。09eeb58 PR run 36908668243 已完成平台依赖与工具安装并实际运行 suite；最终结果见下文。push run 36908661351 并行执行，不能将开始执行当作完成。

## 配置和外部边界

环境 start_skill 已新增自动核验入口及版本/隔离规则，保存并读回一致，草稿 revision 6。install_script 未变，network_policy 与前值一致，未新增秘密绑定或域名。保存不发布；旧 pin99 的源包不含 verify.py，启动说明要求先核对当前任务提交是否有该入口。

原 Project 的自动调用仍无已认证接口；外部 PLAN/REVIEW unavailable。用户提出全自动后已发出接入选择：是否授权将原 Project 规则改为独立 GPT API（需要一次性 GitHub Secret，可能计费），或保留原 Project 等待认证接口。尚无选择或授权，未调用收费 API，也未以 Codex 自审/历史反馈代替外部批准。产品快照仍 unverified；技能 onboarding.md 明确由用户在产品发布，当前没有代理发布工具。

## GitHub 最终结果

[09eeb58 PR 自动运行](https://github.com/hailinsu-create/ambush-loop/actions/runs/36908668243) 实际 completed/success，verify job 耗时 4m30s：冷安装、完整真实核验和证据上传均 success。源码为 PR merge checkout，事件 head SHA 为 09eeb584a15dbf259d15a7f0487560ba2cd561f5；产物名记录实际 checkout SHA，不能将它误报为本地 ccbff7c 的运行。已保存 GitHub run/jobs/artifacts 元数据及实际 verify step 日志。CI 通过是技术门通过，external review 仍 unavailable。

GitHub 提示旧 actions 的 Node20 已强制运行在 Node24，本轮所有步骤成功；这是平台弃用提示，不写成当前失败。尚未声称 API 自动评审或产品发布完成。下一步只需要一次性确定外部评审接入与授权，不再让用户每轮手动发技术测试。
