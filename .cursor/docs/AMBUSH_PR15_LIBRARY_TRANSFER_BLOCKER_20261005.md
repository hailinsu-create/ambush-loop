# PR15 原八件 Library 转移阻塞

2026-10-05。原游戏 QA 输入转移已有授权；当前是技术路径阻塞，不另要求用户授权任意 API 绕行。本包只读取已封 receipt、同路径只读诊断、当前 Library skill 和原生工具 metadata；**没有重试上传、prepare/finalize、改 endpoint/代理/权限，没有 Library IDs。**

## 精确入口、阶段与原文

当前 helper `library_hosted_apps.py:62–66` 从正式 runtime `CODEX_APPS_MCP_URL` 取入口；当前环境该项未提供，因此选择当前官方默认 **host `chatgpt.com` / path `/backend-api/wham/apps`**，完整入口 `https://chatgpt.com/backend-api/wham/apps`。这是 parent 要求核对的 helper 发现入口，不是猜测上传 URL，不暴露认证头、代理地址或 signed transfer URL。

原一次上传 helper receipt：2026-10-05T03:11:21.567218→03:11:21.682542Z，8件、109,037,876 bytes，actual exit1，results=[]。原 stderr **完整一行**：

```text
library upload failed: hosted apps tools/list request failed: network
```

失败处为 **tools/list discovery**，在第一个 tools/call 上传 mutation 前；尚无 prepare 回包、文件 transfer 或 finalize。原日志没有记录403。随后沿同未修改 helper/现有网络与 TLS 配置的 harmless tools/list 诊断约0.019秒失败，HostedAppsError→URLError→OSError，底层现有代理 **HTTPS CONNECT 403**。因此只能说后续诊断确认同路径代理拒绝；不冒称原 stderr 已含403，也不说 origin 返回403。

平台 Library `list(limit=1)` 成功，只证明平台 connector read 可用，不证明 helper 网络/upload 路径恢复。当前 prepare_uploads/finalize_uploads 都已 surfaced；发现入口报错不等于它们不存在。独立只读证据已封于 [library-assessment](evidence/20261005-pr15-web-storage/readonly/library-assessment.md)、[网络字段](evidence/20261005-pr15-web-storage/readonly/library-readonly-network-evidence.json)、[原 receipt](evidence/20261005-pr15-web-storage/library-original-transfer/receipt.json)和 [stderr](evidence/20261005-pr15-web-storage/library-original-transfer/stderr.log)。

## 当前技能允许的单文件原生 schema

当前 [Library SKILL.md](skill://plugin_connector_1p_1b8ff8edfc1481918b252c8277e23125/library/SKILL.md) 的单文件 fast path 适用 **one confirmed local file under about 50 MiB**。运行时实际暴露的 schema：

```ts
tools.mcp__codex_apps__library_create_library_file({
  file?: string,                  // 一个绝对本地路径
  files?: string[],               // 1..20；file/files 必须二选一
  directory_id?: string | null,
  library_artifact_type?: "other" | "image" | "image_gen"
    | "report" | "sheet" | "slides" | null
})
```

对符合条件的新单件，用 `file: "/absolute/path"`；这些用户导入的游戏 QA 输入分类 `other`。成功后必须**同一 functions.exec 调用内**运行当前 `library_file_transfer.py apply-xattrs PATH LIBRARY_FILE_ID`，完整返回 xattrs 数组或 `[]` 作为 stdin JSON，检查结果；不能臆造 ID、先返回模型再补 metadata。本包仅返回 schema，没有执行该调用。

## 为什么这批不能改成八次单件

当前 [SKILL.md](skill://plugin_connector_1p_1b8ff8edfc1481918b252c8277e23125/library/SKILL.md) 明确：

> “Treat every local file written by one user task as one ordered upload batch.”

> “Use the bundled prepared-upload helper below.”

当前 [prepared-uploads.md](skill://plugin_connector_1p_1b8ff8edfc1481918b252c8277e23125/library/references/prepared-uploads.md) 明确：

> “Do not call prepare_uploads or finalize_uploads separately or transfer a returned URL yourself.”

> “Never switch a started helper write to a direct action.”

本任务指定原 PCK + 六原 bin + 原 producer manifest 为同一八件任务，prepared 两工具存在，已走 helper；因此当前官方规则不允许拆成八个 fast path，亦不允许改用 `files=[...]` 的“prepared 不可用”fallback。这是本次停止传递的明确 skill 要求，**不请求新增授权，也不以已有游戏 QA 转移授权猜 endpoint/改代理/扩 network**。

原件固定：1d17 release PCK 38,074,644 bytes / SHA `07a1a14411a45ecff3ed5afd898f40382f7ede7462c44306396ec4c4859a8a3c`；六 bin producer a05fa959093ef5b6733466091a04fbb46647f97b / run7b50d8a62bfd48dc9f741796d2ce9e75，共70,943,176 bytes；manifest20,056 / SHA `9b57cc16086151eeaba3c23861157c220cd69f6a5b35ea2c93fe1b246835b587`。请求原顺序和各原 SHA 均在原 receipt；不能用新 dab PCK 或新 fresh Web 记录静默替换。

恢复需平台/执行环境维护方恢复**正式提供的** helper 入口及现有代理通路；不自行注入猜测 URL、迁移认证或降 TLS。先用原 unchanged helper harmless read 验证，再在同 request/run 复用当前匹配 helpers 重试原完整八件有序批次。原 discovery 失败发生在 mutation 前，可据此避免错误的“未知 finalize”判断；若将来 mutation 结果未知，则按技能禁止盲重试。本阻塞不影响新 fresh Web 六关原输入独立生产，后者仍等独立 QA 归还重活窗口。
