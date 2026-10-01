# Cloud 生命周期与安装闭环报告

日期：2026-10-01。用户追加要求“把这些问题都修好”。当前实现 `99e6b70e831e28d672a14ab61029a71d1f9f982e`，承接 `3b45da8`；工作仍在 Draft PR #8，未合并、未更新 `codex/cloud-main`、未扩大网络权限。

## 已修复并验证

1. **Xvfb 子进程未回收。** 读取系统 xvfb-run 确认其退出 trap 只 kill Xvfb，没有 wait；容器 PID 1 不回收时留下 zombie。新增 Python launcher 直接持有 Xvfb/Blender 子进程：认证文件位于权限受限的临时目录，Xvfb 通过 displayfd 自动分配显示号，禁用 TCP；退出时先停止并等待 Blender，再停止并等待 Xvfb，最后删除认证文件。没有强制成功退出逻辑。
2. **挂起、取消与失败无可靠生命周期边界。** 默认 Blender deadline 900 秒，可通过 AMBUSH_BLENDER_TIMEOUT 设置；超时退出 124，SIGINT/SIGTERM 退出 130/143，Python 失败保留 1。子进程收到 TERM 后最多等待 5 秒，再 KILL 并 wait；此处只操作 launcher 自己创建的进程组。正常生成不经过强杀。历史 143 的上游 EGL 挂起根因本轮仍未复现；不将生命周期修复写成已证明 Blender 上游根因。
3. **实际安装与仓库实现脱节。** Godot/Look 安装器支持 AMBUSH_TOOLS_DIR 与 AMBUSH_DOWNLOAD_CACHE，不改 HOME；Blender 归档固定官方 SHA-256，Godot 固定 SHA-512，缓存文件也校验。安装时刷新真实 launcher；glTF 4.5.1 已安装且版本正确时不重复访问 npm。
4. **旧 bootstrap pin。** environment-setup.sh 执行同一源包中的安装器，不再内嵌抓取 5f6cdff。新增 environment-bootstrap.sh 从精确实现 SHA 提取整个 .codex/cloud 包；缺对象时使用明确 GitHub URL fetch，不依赖 origin，也不切换任务工作树。

## 当轮实际验证

使用 /workspace/ambush-environment/tools 全新目录运行完整 environment-setup.sh，退出 0；重复安装退出 0。安装了固定 Godot 4.7.2、Blender 5.2.2 LTS、glTF CLI 4.5.1。Xvfb/xauth 使用上轮经 apt 签名元数据验证后提取的依赖，不重新安装系统包。完整安装中实际运行了 Godot editor import。

随后运行与保存草稿完全相同的 pinned bootstrap，退出 0；安装出的 launcher 与提交文件 cmp 相同。另在全新无 origin 的临时 bare Git 仓库中 fetch 精确 SHA、提取并比对源包，退出 0，输出 BOOTSTRAP_NO_ORIGIN_FETCH_OK。该检查验证引导逻辑，不冒充新云机器或新快照验收。

| 验证 | 实际结果 |
| --- | --- |
| 实际安装的 launcher 完整 yard_crate 生成 | 退出 0，Blender quit，无 EGL 错误 |
| Python 正常/故意异常 | 0 / 1（符合预期） |
| 真实 Blender 超时 | 124（符合预期） |
| 只向 launcher 发送 SIGINT / SIGTERM | 130 / 143（符合预期），子进程已回收 |
| 无效 deadline（NaN） | 1（符合预期） |
| 两个真实 Blender 并发 | 均退出 0，使用 :0 / :1 不同显示 |
| 最终进程归属检查 | new_runtime_pids=[]；没有新增运行/僵尸子进程 |
| gltf-transform inspect | 0，GLB 2.0，四件产物完整 |
| 三张新 PNG 解码与像素比较 | 与上一轮三个视图像素一致；turnaround 已再次目视 |
| 隔离 Accept→Yard | 0，TEST_STORAGE_ISOLATED，ACCEPT_CTA_FLOW_OK level=yard frames=1 |
| Python AST、bash -n、git diff --check | 通过 |

首版进程回归按全局 PID 差集检查，误把并行运行的完整渲染计为遗留，测试退出 1；已改为 Linux child-subreaper + 本测试进程树归属判断，重跑整个 suite 退出 0。保留初版结果为 runtime-initial-interference.json，不把这次测试失败隐藏为应用通过。此前 PID 1 下的三个旧 zombie 无法由新 launcher wait，仍保留历史记录；新实现没有继续产生它们。

实际生成器/launcher 源内容在提交前运行，提交后和安装源逐字节核对一致；之后按精确 99e6b70 执行 bootstrap 再确认部署一致。未修改生成器、游戏源码或游戏内美术。安装引起的本轮未跟踪 .uid 已清理。未运行完整游戏 smoke（本轮不改玩法）；Accept gate 只代表本切片的启动门，不替代完整游戏/Android 验收。

证据在 [cloud_completion_20261001](../../ambush_loop/docs/cloud_completion_20261001/)，包含原始安装/生成/门禁日志、runtime 回归日志、JSON 结果、当轮 GLB 和三张图。测试入口为 `.codex/cloud/test-look-runtime.py`，操作说明已更新 `.codex/cloud/START.md`。

## 云配置实际保存状态

已调用 update_environment_config_draft 保存 **install_script 与 start_skill**；结果 status=saved，draft_id `83164f0e-db83-4461-b78a-16ebb6b0f54f~cecfgdraft_6abe4765865081918bd2c49d17c17e06`。随后读回核对两字段与提交内容一致，network_policy 与保存前一致，未添加凭据/域名。install_script 的仓库副本为 environment-bootstrap.sh，固定实现 SHA 99e6b70；start_skill 明确工具目录、隔离入口、失败码、进程重启与未验收项。

当前机器已实际部署并验证；**草稿保存不是发布**。新快照只能由产品发布流程建立，本会话没有发布工具，因此未声称新快照或新任务验证通过。下载缓存与安装目录可以保留到快照，不依赖活进程；若冷启动缺缓存且官方源被策略拒绝，保留拒绝并报告，不扩大域名权限。

## 外部 GPT 仍存在的授权边界

本轮已做真实访问诊断：现有 c2c-ambush-loop-cloud.hailinsu.top/mcp 返回 401；对原 ChatGPT Project 的 TLS 验证请求返回 Get started | ChatGPT，页面含登录入口，没有项目内容。本环境未配置外部 GPT API 凭据，也无可调用的已认证 ChatGPT 会话工具。前一轮“没有浏览器工具”不代表系统没有 Chromium，现已区分这两项。

系统 Chromium + Playwright 首次遇到 ERR_CERT_AUTHORITY_INVALID。核对实际公开证书链、系统 CA 与 NSS 库，确认同一代理根证书已存在，SHA-256 指纹为 `C71B4D1E9D7775C538C688AB10CEA9CE417D7312E89838F9D15FF73256CD7FC3`；重复导入没有解决错误。随后仅授予 `/home/agent/.pki/nssdb` 目录写权限，使 NSS 能创建验证所需锁文件；浏览器在 **未关闭 TLS 校验** 的情况下返回 HTTP 200，并跳转原 Project 对应登录页。该文件系统授权仅本轮有效，未改变网络权限。未读取/复制账号凭据、cookies 或证书私钥；仅保存不含凭据的访问结果。后续浏览器运行需要同样的证书库写权限，操作说明已保存 WEB_REVIEW.md 与云 start_skill。

因此实际外部 PLAN/REVIEW 仍是 **unavailable**。代码与环境修复无法自动获得用户的 ChatGPT 登录身份。下一步必须由已有授权会话在原 Project 通过 GitHub 读取本轮精确实现及证据 SHA；本轮将提供可直接发送的评审请求。不能用服务 401、历史反馈、Codex 自审或本报告替代外部批准。

用户需要的剩余动作：在环境设置中发布已保存草稿；在原已登录 Project 发出本轮精确 SHA 的评审请求并取得实际反馈。没有请求扩大网络、合并 PR 或新 API 计费。Android/vivo、旧音频根因及真机质量门保留原独立任务，不宣称云端修复了设备问题。
