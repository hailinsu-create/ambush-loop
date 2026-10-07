# Library a05/PCK 上传阻塞：独立只读评估

2026-10-05。本包只读原 receipt/stderr 和指定当前 helper，读取当前 Library skill 与 companion source。未上传、prepare、finalize、修改 helper、运行 browser/engine 或调整网络/ACL。报告及脱敏证据只写本包目录；未输出任何认证值、请求头值、端点或 transfer URL。

## 准确结论

**当前执行环境里，unchanged helper 到托管应用发现入口的标准网络路径被现有代理拒绝。** 对同一 helper 的一次只读 `tools/list` 请求，在约 0.019 秒内失败；链为 HostedAppsError → URLError → OSError，底层 HTTPS 代理 CONNECT 返回 **403**。沿用运行时既有代理与 TLS 配置，未绕过或修改。运行时没有提供 endpoint override，因此 helper 选择其当前官方内置 fallback；这里不记录其地址。

对照：平台暴露的 Library `list(limit=1)` harmless connector read 成功（isError=false，返回一个 item）。因此不能说“Library 账号断连”“Library 服务整体不可用”或“文件太大”。成功只读也不代表上传权限或 helper 路径已恢复。

原上传记录仅保留概括的 `network`，没有原始异常链；**403 是本次同路径只读诊断的具体证据，不虚构原上传日志已经记载 403**。原失败与当前诊断吻合，支持 helper 网络路径阻塞；原运行的确切底层原因没有被原 receipt 单独记录。

## 原始执行证据与调用边界

- `/tmp/pr15-web-controls/library-a05-pck/receipt.json`：8 个源文件（父端给定原候选 PCK、六关 bin、producer manifest），总计 109,037,876 bytes；actual_exit=1，results=[]；记录区间约 0.115324 秒。
- `/tmp/pr15-web-controls/library-a05-pck/stderr.log:1`：失败发生在 hosted apps `tools/list` discovery，分类 `network`。
- `/workspace/.ambush-loop-env/library-pr15-transfer-20261005/library_upload.py:525–528`：parse 后进入 _prepare；`:634–650` 的 call_tool 在 discovery 错误时直接抛出，尚未得到 prepared uploads。
- 同目录 `library_hosted_apps.py:72–86,106–141`：call_tool 首先找/加载工具，加载走 tools/list；只有找到工具以后才发 tools/call。因此本次记录的 discovery 失败发生在首个上传 app mutation 发出之前。
- 同文件 `:27–36,198–205`：URLError 的 reason 不属于 timeout/DNS/TLS/ConnectionError 时归类为 network。代理 tunnel 的 OSError 正好落入 network，故原短日志不能进一步区分代理、路由或其他 OSError。
- 同文件 `:62–66,180–195`：从运行时配置选 endpoint，否则用官方 fallback；使用标准 urllib 默认代理处理和当前 TLS context。

本次 current skill source 与指定目录三个 helper 逐字符比较，全部相等：library_upload.py 44,876 chars；library_hosted_apps.py 12,576 chars；library_file_transfer.py 11,084 chars。不是本地 helper 被改写或旧 helper 与当前 skill 不同的证据。

只读运行的脱敏字段保存在：[library-readonly-network-evidence.json](/tmp/pr15-web-storage-source-readonly/library-readonly-network-evidence.json)。该文件只含配置存在与否、布尔状态、异常类型、状态码、数量和时长；不含端点、认证或 Library 文件内容。

## 遵守 skill 的恢复路径

已读 [Library SKILL.md](skill://plugin_connector_1p_1b8ff8edfc1481918b252c8277e23125/library/SKILL.md) 与 [prepared-uploads.md](skill://plugin_connector_1p_1b8ff8edfc1481918b252c8277e23125/library/references/prepared-uploads.md)。相关明确规则：

> “Reuse the downloaded helpers for every call and retry within this request or run.”

> “Do not call prepare_uploads or finalize_uploads separately or transfer a returned URL yourself.”

> “Never switch a started helper write to a direct action.”

这批为多文件任务，平台当前暴露 prepared 工具；网络 discovery 失败不能视为“prepared 工具不可用”的能力声明，不能以此切 direct create、拆批、手工 prepare/finalize、手传 URL 或改 helper。平台 connector read 成功也不是允许跨执行路径重放认证或绕过 helper 的依据。

可执行恢复顺序：

1. 由平台/执行环境维护方恢复该执行环境**正式提供的**托管应用网络入口及现有代理通路。当前任务不授权设置任意 endpoint、禁用代理、放宽 ACL/TLS 或迁移认证；本包没有这些动作。因 runtime 没有 override 而 helper fallback 被代理拒绝，需维护方核对当前环境是否应注入正式 endpoint，或正式代理策略是否错误拒绝该官方路径；不能猜地址填 env。
2. 恢复后，先用同一个未修改 helper 执行一次 harmless tools/list/read-only 连接验证。成功后才可由主作者按原授权继续原有一次性完整 JSON 批处理、保留 8 项顺序；同一 request/run 复用当前已读且匹配的三 companion helper。若实际进入新的 request/run，则按 skill 重新取当前全套到新私有目录，不能搬旧版本冒称 current。
3. 原记录在 discovery 阶段失败，结果没有创建；源码支持本次未发出上传 mutation。因此恢复后继续这批不属于对“finalize 结果未知”的盲重试。若后续 prepare/transfer/finalize 已开始而结果超时未知，则改按 skill 的不自动重试规则处理，避免重复创建。
4. 完成后仍需逐项核对 helper ordered results；本包没有写成功、Library ID 或已持久化结论。待保存对象必须继续引用原 candidate 的字节/哈希，不能无声明地换成主作者同期新代码导出。

当前 blocker 尚未恢复。主作者可继续无关代码修复；此报告没有请求新增权限，也没有执行任何上传或网络变更。
