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

待验证：云端环境创建/发布、Linux 实际 Godot 门、Blender 渲染及 glTF 检查、同提交的首次网页 PLAN/REVIEW、APK 和 vivo 真机门。浏览器读取恢复后，云端入口导航仍发生超时；没有环境发布证明，不标记已迁移运行成功。

## 下一步与验收门

1. 云环境绑定本仓库、`codex/cloud-main`，运行 `.codex/cloud/install.sh` 和 `.codex/cloud/install-look.sh`。需要 GitHub/账户授权时才找用户；不索取 token。
2. 保存 Linux 安装和隔离门的实际退出码。若缺图形依赖，在环境安装官方 Linux 系统依赖；不要以历史素材代替新渲染。
3. Look 独立切片重生成一件道具，检查 GLB、turnaround、iso/top、引擎截图；提交来源脚本与可复现证据。Engine 独立回归，不改变冻结契约。
4. 网页审核必须读取精确云端 SHA；按 `.codex/cloud/WEB_REVIEW.md` 验证来源，反馈入库并更新本索引。不通则 unavailable，不能虚构批准。
5. 发布环境后从该分支启动单个切片，Android 验收保持本机待办，旧 AudioTrack 根因不标记修复。

此文件补充迁移与工作流，不替代设计 v2 或当前 B2/Android 质量门。
