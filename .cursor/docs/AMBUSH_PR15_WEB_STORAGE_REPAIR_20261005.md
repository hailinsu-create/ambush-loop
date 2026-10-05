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

上述初始待验入口已完成本切片的有界浏览器与同站更新；实际结果如下。fresh Web 六关 13 波仍按 `83a7` 计划下一独立包执行，独立 PCK 多 32B 仍待双方原包逐项比对。

Library 原 1d17 PCK + 原 a05 六 bin + 原 producer manifest 已逐文件验证 SHA/长度，无更改。当前 skill 的原样批量 helper 在 tools/list 即被环境代理 CONNECT403 拒绝，尚未 prepare/transfer/finalize，**没有 confirmed IDs**；平台 Library 只读成功，不能称账号断连。保留失败，不能绕过代理或把本地路径当跨环境交接。原 manifest SHA `9b57cc16086151eeaba3c23861157c220cd69f6a5b35ea2c93fe1b246835b587`；原 PCK `38074644B / 07a1a14411a45ecff3ed5afd898f40382f7ede7462c44306396ec4c4859a8a3c`。该 blocker 不影响本代码修复与后续授权私有 Site 更新。

## 有界结果与固定来源

核心实现 `bd9218a83047f1452cf8af910eed0f4784ec1335`；后续两次仅 Web 提示布局，中心顶部 `b0a6f66e8207f94a094e0f0a613f7c64beb757cc` 没部署（ALERT 阶段栏仍占顶部），最终提示在战场控制底边以下。最终源 **`dab870595175eed37a6d2a012bc69a76062d48b0`** / 游戏树 **`4f49a7c9cb5a789fbb570bceb947eab7df2eb54a`**，正常 push / ls-remote 精确一致；没有 merge，PR15 仍 Draft/open/unmerged。

最终完整 Title 导出命令，隔离 stage/warm loader，作者 Blender 源排除，493 个既有导入 sidecar 同字节消费，全部 tracked game source 前后相等：

```sh
Godot_v4.7.2-stable_linux.x86_64 --audio-driver Dummy --headless --path /workspace/pr15-web-stage-dab8705 --export-debug 'Web Game' /workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/debug/index.html
Godot_v4.7.2-stable_linux.x86_64 --audio-driver Dummy --headless --path /workspace/pr15-web-stage-dab8705 --export-release 'Web Game' /workspace/pr15-web-artifacts/dab870595175eed37a6d2a012bc69a76062d48b0/release/index.html
```

debug 03:34:05.103684→03:34:14.004274Z，release 03:34:14.106857→03:34:19.186257Z，各**实际 exit0 E0/S0**。最终 PCK **38,082,080B / `2d8eac7f8be1d7931762f5c31364c5695eef912d23fd193a7389eb967af4c0b6`**；raw WASM **39,514,754B / `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`**；官方 JS 仍 `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba`。中间两个源码各有完整导出，均成功，不能替代最终来源。

实际浏览器控制器：`python3 /tmp/pr15-web-controls/storage-browser-controller-fixed.py`（Playwright 系统 Chromium，独占 profile + localhost 12793）。具体逐条真实 UI 操作、monotonic 秒、实际 start/end/exception/console 与脚本均封入 evidence。

| 实际病例 | 来源与结果 |
| --- | --- |
| 原 1d17 窄 Title 负例 | observer 诊断 runner exit0，产品 `preserved=false`；914ms 刷新时原 sync 未完成。不是 independent 800ms exit1 的替代 |
| 原 IDBFS 配置迁移→Title M→804ms 刷新 | bd9218a unmodified release，实际 exit0；下一原 M 值反转证明真正载入保存值，不只是读原快照 |
| 完成即刷新，无额外等待 | bd9218a，实际 exit0；原 M 反转核对成功 |
| 浏览器拒绝存储 | 外部 QA 的公开 Storage.setItem 暂时抛 QuotaExceededError，生产捕获；原快照未变，屏上明确“保存未完成”，恢复原方法再刷新实际读前次状态，exit0 |
| 原完整教学→SCOUT→刀强 ALERT→自然逃逸 FAILED→原 replay→Space SCOUT→M→802ms 刷新 | bd9218a 原流；刷新消费最终 dab，store/progress/main 函数同字节，仅提示布局变化；两份配置 muted=false、yard/loop 保存，Title 后下一原 M 证明实际载入，Continue 到 SCOUT；exit0 |
| 精确最终 dab 原 Continue SCOUT 双配置 M→806ms 刷新 | **dab 全程**；原 Continue / 原 M 证明两份配置实际恢复；exit0。前次插入截图的 2.421s 病例另留，不能称 800ms |

最终浏览器 console 31 项：JS page error0、console error0、Godot ERROR/SCRIPT ERROR0、GL_INVALID/INVALID_OPERATION0；4 条 GPU ReadPixels 性能警告保留，不是性能 green。原 UI/教学/SCOUT/自然 FAILED/原 replay 的实际 PNG 有逐张查看；本轮未作声音耳验、触控/DOM blur、whole 或陌生人体验声明。方法负例保留：早期 path/固定 true 等待错误、Playwright 返回函数触发 Illegal invocation、教学按钮不同页坐标导致未完成；修正后才计对应病例。

## 同一个 private Site 更新已终结

稳定 URL：<https://ambush-loop-game.lning791548.chatgpt.site>；项目 `appgprj_6ac2e89b4db08191b308c175371ee7c6`。新 **Site Git `aa19d5b03c014c3483a2b98320018ea3e4e02042`** 已普通 push/ls-remote 精确一致，站点工作树 clean；archive 由同 SHA 生成，13 个 regular payload 逐项 `git show` 精确相等。运行目录仍 **12 文件 / 48,473,069B**；分片完整 PCK、gzip 恢复原 WASM hash 已验证；每运行文件 ≤25MiB。仅运行包，排除外部 QA bridge、记录 bin、evidence、截图、浏览器 profile、凭证与制作源；沿用 all_resources 的游戏工程脚本集合。运输源仍 `fa18869bf105a7ccbb65f165438ce2a95169f2e6`，包装脚本文件 hash `00fb0d067e52a879dcca27d04b5f85e7ba11ed584af3aabf5bc90c7b6b1b7118`，无改引擎/COOP/SAB/PWA/权限。

作者 Git tar **48,486,400B / `71358bfdba3916a9beaacb9a54c5f4e4267296fb27bac68b8d0715da46651d26`**；保存后的 server tar **48,486,400B / `b3a1eaa5a9a9a6a5ebb5da932e8838a0552184310570824ee585cc28c17c46b6`**。同 13 payload Python 默认 TarInfo/PAX 序列化完整重现 server 整 hash，actual0，证明仅 tar metadata；**与独立原 PCK +32B 无关，后者未解**。

03:37:42→03:38:40Z 一次原生 save-and-deploy-private，**succeeded**，无需重试、无 publish-on-push、非 Vercel：

- version **`appgprj_6ac2e89b4db08191b308c175371ee7c6~appgver_0011120092a88191bf67cace12146522`**，version number 2；get_version.source.commit_sha 精确 Site Git SHA。
- deployment **`appgdep_6ac31badd5248191af80e81054118b60`**，publish succeeded；get_site 读回 version2。
- owner/custom，access revision1、owner1、editors0、groups0、外客0，原权限不变。未使用 bypass、未改变代理/ACL；正式 origin 仍没有本执行环境浏览器验收，先前 CONNECT403 不当 origin403。旧 v1/version/archive/source/负例保留作回滚，不再把旧警告 v1 当最终站点。

## 本切片封存与下一包

[证据 manifest](evidence/20261005-pr15-web-storage/manifest.json)：94 个数据文件 **10,072,453B**（manifest 本体另计），SHA **`939632f7142976135d1ea8b47e081844e3744e1ef25bc8661361dee385ac2f8b`**；全逐文件 hash、原字节拷贝断言、原负例、测试 recipe、原生 Site 读回与 tar hash 复现。自有 browser/controller/HTTP close actual0；所有自有 engine/browser/controller 已查 `/proc` 无残留。网页 GPT PLAN/REVIEW unavailable，无臆造 approve。

Library 替代流程的明确授权问题已发出，仍待答复，不把等待当授权；skill 要求多文件 prepared helper，而本环境该路径阻塞。父端可协调恢复通路，或明确授权平台原生逐文件保存。原八文件验证完好可交接，尚无 confirmed IDs；不能消费猜测的跨环境路径。

下一独立有界包按 fresh plan，以**最终 dab / version2**、新 profile 原 Title 玩家输入开始：六关13波原 WON/解锁/同 origin reload、新 Web 原件、全 1×/2×自然终局，分关封存并记录失败；源资产仍只消费验收提交。原 a05 六原件跨环境消费另算，PCK32B 另审。整体 A3/FINAL/full smoke/完整FX/追溯APK/设备验收仍未完成；本切片不新增模拟器/真机或性能通过声明。
