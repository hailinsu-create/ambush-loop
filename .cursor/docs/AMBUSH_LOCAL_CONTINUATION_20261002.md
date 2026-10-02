# 本地主开发与设备验收续做

日期：2026-10-02。用户要求本地主开发、云端辅助；本计划补充当前 B2 交接，不替代设计 v2，不提前开始 M1-C/M1-D。

## 范围与切片

从已有迁移候选源码 `e3faeb5808b5d1b0a62ad9b479aa3f576ec0c3bc` 建独立本地分支 `codex/local-device-preflight`，不覆盖原评审镜像和 Android worktree 的在制改动。代码依赖候选分支已有 B2/诊断实现，不代表这些 PR 已合并主线。

本切片增加只读 Android preflight：用官方 ADB 选择唯一已授权目标，核对 vivo V2266A、包名及已登记 code80 的 versionName/versionCode；不安装、不启动、不清档、不修改手机设置。多设备时必须明确选择 serial；离线、未授权、无包、错机、错版本、命令失败或超时一律拒绝 ready。

默认 JSON 不包含手机 serial 或完整包信息转储。只读身份通过仅表示可以开始该包的真机验收，不证明签名、源码、B2 玩法、稳定性或 AudioTrack 根因通过。若改用新包，应先登记来源、签名和版本，再显式传入新的 expected 参数，不能为了通过门而改期望。

## 验收与后续

- 标准库离线单元测试覆盖正例、无设备、多设备、未授权/offline、错机、无包、错误/缺失版本、指定目标不存在、非零退出和超时。
- 实际 preflight 通过要求 exit 0 和 `ready=true`；无设备 exit 2 是正确拒绝，不是手机验收通过。
- 设备恢复后沿用 B2 交接：包来源/签名确认、Title→briefing→Accept→Yard、双向上下坡/随队/拾取、声音与生命周期稳定性。历史桌面门不重记为本轮结果。
- 原本地 C2C `workspace_info` 返回 internal error，doctor 报 `workspace_mismatch` 且拒绝自动修复。未借用 cloud 连接、重配/覆盖原连接；本切片外部 PLAN/REVIEW unavailable，待恢复后在原项目对话针对精确差异补审。此处规划由 Codex 给出，不冒充 GPT 规划。

规划与代码分开提交；保留原未跟踪文件。不合并或发布游戏、不扩大云网络、不把只读设备门当作玩法交付。

## 本轮实际结果

`python -m unittest -v test_android_preflight.py`：10 tests、exit 0，全部通过。官方 ADB `devices -l` 列表为空；运行新 preflight 得到 `ready=false`、`reason=select_one_device`、`device_count=0`、exit 2，正确拒绝。没有连接手机、安装包或进行真机玩法/稳定性验收。测试仅覆盖预检查程序，不替代 Godot 回归。下一步恢复原评审服务的精确工作区身份，并在目标设备可用后续做既有验收。

## 原本地评审连接修复（2026-10-02）

已确认原工作区服务不再运行，但仍留下过期运行记录；旧地址的健康响应实际属于 cloud 工作区，故 doctor 正确拒绝启动/停机。核对进程身份后仅把原工作区的过期记录备份到本机私有状态目录，没有停止云端服务，也没有删除原授权、Project、对话或诊断差异。再次 doctor 自动启动原服务并恢复原固定地址，全项通过，地址未变，不需要重新授权。

通过原已授权连接器实际调用 `workspace_info` 和 `read_file(README.md)` 成功，返回原本地 `ambush-loop-collab`（ID `363712641ef7`）及游戏 README；云工作区 status 同时仍为运行状态。身份冲突已修复，文件读取能力已验证。旧运行记录可从备份恢复；备份和凭据不入仓库。

限制：原评审镜像仍是 detached `340b819` 加已有诊断差异，本轮没有覆盖/更新镜像，不能把文件读取成功当作对新 preflight 提交 `8e31d88` 的代码评审。内置浏览器初始化仍超时，未向原 GPT 对话发送新的 PLAN/REVIEW，也没有取得本轮反馈；最新代码评审仍待补。服务恢复与浏览器控制、镜像同步、实际评审是不同验收门。
