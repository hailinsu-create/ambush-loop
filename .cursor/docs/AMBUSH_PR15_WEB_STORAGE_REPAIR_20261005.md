# PR15 Web 小配置刷新保存修复

日期 2026-10-05；基础源码 `83a7a725ad1647d1360930c2cd596f3a4b709d20`，游戏树与 `1d17a16156d2afae0cbdd77cf73030a57f953ada` 相同。仅主集成代码/UI/共享测试；不制作资产，不 merge，不调整站点权限。

## 证据与实现

独立 QA 的失败保留：原真实 UI Title→yard 教学→欠装备强 ALERT→自然 FAILED→原 replay→Space 回 SCOUT→可信 M，确认 muted=true 后等 800ms 再读取/刷新，回到 muted=false，实际 exit1。8s 后的另次 exit0/32 checks 不能覆盖它；原 QA 没记录 ConfigFile.save/FS.syncfs 提交完成，所以不能据此判定唯一原因。独立 whole yard 是 a90 reference（1397 tick / 23.2833s），不是 a05 原六份记录；软件浏览器 whole 约三倍墙钟，性能仍未通过。

本地窄复现使用 **原 1d17 release PCK**、完整 Title、真实 M 键，外部 JS 仅观察原 FS.syncfs（保留参数/回调、无主动同步或数据写入）。确认内存 cfg muted=true 后 **914ms** 刷新，恢复 false；同步开始 40176.7ms，刷新前 41292.3ms 尚无 completion。前次相同小文件同步 2460.9→6351.6ms，约 3891ms。用户目录仅一个 175B 设置 cfg；不把耗时归因大存档或固定 8s 周期。前两次观察方法错误（未递归用户目录、重复 M 等待固定 true）保留，不能计为产品复现。

官方 4.7.2 FileAccess.close 自动置 dirty；force_fs_sync 返回 void、没有公开完成通知。GodotFS.sync 内部 Promise resolve(error)，忙时可能立即 resolve；不得当作已保存信号。没有改引擎 JS、模板、FS、GodotFS 或同步循环。

本切片增加 `web_config_store.gd`，只通过公开 JavaScriptBridge + Web Storage 对两个小 ConfigFile 进行 schema1 单键原子快照：`ambush_loop_settings.cfg` 与 `ambush_loop.cfg`。保存原 ConfigFile 成功后读取两份实际文本、验证后同步 setItem，完整读回一致才显示“已保存到此浏览器”；异常/配额/拒绝/读回不符显示未完成，旧 checkpoint 保留。上限 64KiB；不保存模拟、战斗、回放或资产。主 `save_progress` 与 GameSettings 的设置/统计/胜利统一经过同一入口，不能把音乐成功当进度成功。

首次无 checkpoint 继续消费原 IDBFS 配置；已有合法 checkpoint 在 GameSettings.load_settings 前恢复原文本，显式 null 表示原文件不存在，防止旧 IDBFS 进度复活。两个配置先全部验证再写入。未知版本/损坏 checkpoint 不覆盖，显示失败并阻止快照写回；原 IDBFS 异步同步保留。恢复仅同 origin/profile，不承诺其他浏览器、清站点数据、战场/回放刷新恢复或设备性能。

公开接口依据：[Storage.setItem](https://developer.mozilla.org/en-US/docs/Web/API/Storage/setItem)、[localStorage](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)、[固定 4.7.2 官方同步源码](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/platform/web/js/libs/library_godot_os.js)。

## 实际检查与下一门槛

`bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 web_config_store_test.gd --headless`：guard 通过，run `bd7d39a893834cbabc22ffb91b8f4f67`，**22/0，实际 exit0，E0/S0**。覆盖原配置精确恢复、音频/教学/下一关与解锁一致、非法/未知/越界 checkpoint 拒绝且不写文件、缺失进度 tombstone。首次编译存在两处 Variant 循环变量推断错误，已明确声明 String 修复；原失败日志保留，停掉该独占挂起进程实际 exit143，不计为 pass。

待：固定源码完整 Title debug/release 导出，真实浏览器同条件 800ms/完成即刷新、连续设置+进度、错误/旧配置迁移、WebGL/原 UI 基线。通过后按 `83a7` 计划更新**同一个** private Site，再执行 fresh Web 六关 13 波；不把窄设置测试当 fresh13。独立 PCK 多 32B 仍待原包逐项比对。

Library 原 1d17 PCK + 原 a05 六 bin + 原 producer manifest 已逐文件验证 SHA/长度，无更改。当前 skill 的原样批量 helper 在 tools/list 即被环境代理 CONNECT403 拒绝，尚未 prepare/transfer/finalize，**没有 confirmed IDs**；平台 Library 只读成功，不能称账号断连。保留失败，不能绕过代理或把本地路径当跨环境交接。原 manifest SHA `9b57cc16086151eeaba3c23861157c220cd69f6a5b35ea2c93fe1b246835b587`；原 PCK `38074644B / 07a1a14411a45ecff3ed5afd898f40382f7ede7462c44306396ec4c4859a8a3c`。该 blocker 不影响本代码修复与后续授权私有 Site 更新。
