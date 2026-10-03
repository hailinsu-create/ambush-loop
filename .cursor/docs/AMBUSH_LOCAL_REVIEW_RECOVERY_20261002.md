# 本地浏览器恢复、preflight 补审与下一设备切片

日期：2026-10-02。用户选择本地主开发、云端辅助，并授权独立本地浏览器修复任务；随后要求继续开发。本记录更新此前“浏览器超时、preflight 待外部评审”的状态，不替代设计 v2 或 B2 真机退出门。

## 范围与恢复证据

保留原游戏仓库、原 ChatGPT Project/评审对话及连接授权；修复任务没有迁移或复制游戏。原开发任务通过官方内置浏览器接口，实际读取原评审页面、隐藏侧边栏、验证隐藏后的按钮状态、还原布局并验证还原结果。仅能列出标签页或返回导航成功不算通过；本次取得了内容及操作结果证据。

该 Windows 环境的成功页面请求约需 21–27 秒，原先 15–20 秒执行上限可能在请求完成前终止它。已将本地使用规则改为每次一个页面操作，执行上限 60 秒、支持该参数的定位器上限 45 秒，读取/操作/验证分开；不无限延长，也不因超时重发消息或重建正常连接。此前发现的其他会话路由警告不能单独证明当前页面不可控；底层请求为何较慢仍未定因，不宣称修改了桌面应用源码。

Codex with ChatGPT 程序快进到上游 `535a07dbb7aee887924c53767d985c09d405319d`，构建 exit 0。首次默认并行测试为 192 passed / 7 failed（六项超时、一项连接重置），失败记录保留；随后以单 worker、关闭文件并行、测试/钩子上限 60 秒重新完整运行，18 个文件、199 tests 全部通过、exit 0。这是复查结果，不抹去首次失败，也不等同于游戏测试。安装的 skill 保留本次实际验证过的浏览器超时规则，更新前已备份。

仅重启原评审工作区以加载新版；随后检查全部通过，原固定地址未变，不需要重新配对。原游戏评审聊天已实际收到补审请求并生成完整反馈，不能再将本地浏览器或本轮补审标为 unavailable。未据此宣称云工作区的新提交已评审。

## 精确送审对象与实际测试

代码在 Draft PR #10、分支 `codex/local-device-preflight`，源码提交 `8e31d88e9e2ddd4a2b3484ea4266863d783d3e35`。只向原评审镜像新增以下两文件，核对 Git blob 与该提交逐一相同：

- `ambush_loop/scripts/android_preflight.py`：`07864ea88f8b6cc2f38c5cc58a9ba6f7e3c27e0a`。
- `ambush_loop/scripts/test_android_preflight.py`：`b536ab45f5491b4d4035c8ca4cb4d2b1c8ca261d`。

镜像仍是 detached `340b819` 加原有诊断差异，未覆盖这些差异；本次评审限于两份新文件，不是对镜像全部在制代码或整个候选提交的批准。实施时没有取得外部 PLAN，这一历史事实不变；本次是恢复后的补审及后续规划，不追溯伪称先审后写。

在精确源码提交上执行 `python -m unittest discover -s ambush_loop/scripts -p test_android_preflight.py -v`，10 tests 全部通过、exit 0。实际官方 ADB 设备列表为空；真实 preflight 输出 `ready=false`、`reason=select_one_device`、`device_count=0`、exit 2。正确拒绝表示程序门禁工作正常，不表示手机已连接、已安装或游戏验收通过。

## 实际外部 GPT REVIEW（c2c_audio_device，iteration 11）

原项目对话通过已授权 `Codex with ChatGPT · ambush-loop-collab` 读取送审文件及本轮执行记录后，给出实质性 REVIEW 和下一 bounded PLAN：

随后独立身份核对请求实际调用 `workspace_info`，GPT 返回 workspace name `ambush-loop-collab`、ID `363712641ef7`、commit `340b819`，并明确列出以上两条实际读取路径。该 commit 是未覆盖的镜像基线，不能误写成镜像已切到 `8e31d88`；精确送审文件由上述 blob 匹配证明。

- 未发现未知状态被误判 ready 的阻断问题。唯一目标、授权状态、型号、包存在、code80/name 都匹配才放行；零/多设备、指定 serial 不存在、错机、缺包、缺失/错误版本、ADB 超时或非零退出均不放行。
- 操作范围为设备枚举、型号属性、包路径、包信息查询；无安装/卸载、启动/停止、清档、授权修改、日志清理或设备文件写入。子进程有 15 秒上限。
- 默认 JSON 不含 serial，不输出完整包转储。`identity_verified` 只解释为型号与包版本预检查通过，不证明 APK 证书/哈希或原生库 Build ID；更强身份由独立安装包/签名证据承担。
- 不再扩展 preflight，不开启 M1-C/M1-D；下一切片仅获取 Vivo 设备证据。

这次只可记录为“只读包版本预检查已获补审，离线门禁测试通过”。外部评审不替代自动测试或真机验收，且没有 AudioTrack 修复的新证据。

## 下一 bounded PLAN、依赖与退出门

依赖：原 Vivo X Fold2 恢复可用；不得以另一型号 Android 代验，不为使门禁通过而降低 expected 参数。

1. **设备和包身份门。** 先运行 preflight；只在 exit 0 / identity_verified 时进入后续玩法验收。缺包、错版本、未授权或离线时只处理相应状态，预检查程序本身不安装/启动/修复手机。安装仍用来源、版本及受控签名已核对的包，若出现新的系统授权，由用户确认。
2. **B2 真机/视觉门。** 在同一已确认包的 session 记录 Title → briefing → Accept → Yard；取得横屏平台/唯一坡道可辨、双向上下坡、SMG 可达/拾取、follow-up 与 follow-down 的实际截图/观察和时间点。桌面回归不能代替此门。
3. **音频和生命周期样本。** 保持生产音频行为不变，目标至少 30 分钟连续、60 分钟累计，覆盖有声运行、任务转场、background/resume 和 Back。保存开始/结束 PID、包版本、时间范围、同期内存、ExitInfo 及限定到游戏的崩溃证据；没有复现只报告该样本时长与转场，不写 AudioTrack fixed。
4. **原生诊断边界。** 历史 code78 Build ID `379cc52e…8986` 仍 unresolved；拒绝用不匹配的 `f4a54bf1…1526` symbols 解旧 PCs。只在取得精确匹配 symbols，或来源/符号齐备的新 binary 产生 fresh crash 后继续定因。

当前停止点：桌面回归已有既往通过证据；本轮设备数量为零。code80 安装、B2 设备/视觉、Android 长时稳定性仍 pending。保存这份交接，不增加新的玩法范围、不合并或发布游戏、不改变云端网络策略。后续恢复原 iteration 11 checkpoint 和同一评审聊天，不重复 INIT。

规划/交接沿用独立文档 Draft PR #9；代码仍在 Draft PR #10。推送并核对远端后才算 GitHub 同步，均不代表已合并主线。
