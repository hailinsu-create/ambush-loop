# PR15 回放存档边界分类与静音续关修复 END（2026-10-05）

冷WON首次Space写胜利档属于夹具跳过首次结算的副作用；普通已结算WON重复两次回放返回保持配置原文。但另一个普通路径已实证：warehouse WON→Replay→M→作战设置返回标题→Continue实际退回warehouse，本应进入pump。最小修复保护已结算WON回放的续关指针，主动音频设置仍保存。fixed真实浏览器对照实际进入pump并安全Title/END。本片限定分类/修复通过，不是fresh胜利、whole、完整历史档隔离、全六关、性能或设备接受。

固定代码 **1ec3198e9c0db367af96fc264604c5a286003b5e**，game tree **1e8af45ee23098f763acc139b56f8f7e0f41665a**；计划bd022d194f2371a1f2a8cf4b34c73f5992019249。14策略pins仅main.gd因明确修复改变，其余13保持；新增paired回归及两平台隔离入口。资产payload/制作源/generator/atlas/GLB/Blender/manifest-loader接口未变，原活动profile未打开；私有Site v3未部署，Draft PR15，不merge/高度/APK。

## QA原负例的实际边界

父端报告独立QA END13:12:49.504635，原pump/railcut原bin语义12595/0、16350/0和railcut自然whole1×/2×当轮完整指纹通过，归父端计数，不合入作者。证据摘要SHA **4a4b1af6ddb22a154f59cece2f6dd5b7bb1b60a5eb6c0ac6d64519ffe8f33397**；其完整报告/文件尚未在本执行环境找到，不称逐文件读取或重新封存成功。父端确切补充：桥直接装原bin、设WON、显示Replay而未配对producer胜利存档；原全1×终点后←→Space使railcut/index3→depot/index4+cleared/stats，cfg和持久localStorage变，settings/原bin/模拟域/捕获IndexedDB镜像保持。不能称冷consumer全过程档不变。

普通UI顺序为自然最终SWEEP撤离→`_extract_win`→pending_result→`_flush_pending_result`→`_show_win_result`写胜利档，然后原Replay→Space返回WON再次显示结果。现有生产Replay仅绑定当前battle_log；未找到普通UI外部历史bin加载并跳过首次结算入口。作者guard隔离分类28/0、actual0/E0/S0证实未结算冷WON首返回会结算、已结算重复两次原checkpoint精确相同。显式植入未来完成档并配旧WON的对抗夹具会回退，但不证明普通玩家UI可达，不据此扩大修复。

## 实际命令与对照

所有引擎串行，fixed Godot4.7.2。Native均unique user://并实际StorageGuard；browser为Chromium/Playwright（Browser plugin not available）、1280×720/DPR1、唯一新隔离profile，origin12817。只读桥冷warehouse声明夹具起点，第一Space结算单列；其后原Replay/M/Esc/设置Title/TitleContinue均可信原键鼠，不写phase/tick/policy或seed存档。URL、Title、非空canvas/真实截图、console/JS与实际动作均核。

| 原命令/入口 | 实际结果与范围 |
| --- | --- |
| `python3 /tmp/pr15-web-controls/replay-save-classification-20261005/v2/run_classification.py` | fixed8532，28/0，actual0/E0/S0，13:37:43.712247→13:38:01.844855；cold/settled/injected与原M handler分类，不是普通输入/whole |
| `python3 …/browser_negative_v2.py` | fixed8532实际复现WON回放M续关回退，16trusted；actual0，13:42:51.796511→13:44:06.095120，browser/HTTP闭合 |
| `python3 …/regression-negative/run_regression.py` | fixed8532同一新增测试 **15/2 actual1 E0/S0**；失败仅WON回放M保存progress和Title续关两个断言，Guard通过 |
| `AMBUSH_TEST_SOURCE_SHA=1ec3198… AMBUSH_REPLAY_SAVE_RECORD=…/railcut-record.bin AMBUSH_REPLAY_SAVE_OUTPUT=…/fixed-native-result.json bash /workspace/pr15-replay-save-stage-1ec-20261005/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 replay_progress_save_test.gd --headless` | fixed1ec **15/0 actual0**，原Guard/run UUID b21344c611b9452a9d62e9474fc52dac；统一exec session34941实际exit0/TEST_LOG保留。只有实际工具退出观测，未冒造原请求START/END回执 |
| `python3 …/run_store_regression.py` | fixed1ec配置存储 **22/0 actual0 E0/S0/Guard**，13:55:03.010545→13:55:03.629347 |
| `python3 …/export_fixed.py` | 生产debug及QA-v2完整Title官方导出各actual0/E0/S0，13:50:51.068147→13:51:00.710152串行；复制既有cache资源，没有运行制作管线 |
| `python3 …/browser_fixed.py` | fixed1ec **PASS/actual0**，20trusted；13:52:14.736872→13:53:54.634577，M后nextpump/cleared与complete保持，真实Continue入pump、原两页教学、knife-only SCOUT、安全Title、browser/HTTP闭合 |

Native测试保留已结算WON重复返回幂等、原record字节、M改变音频且全部progress/stats保持；SETUP/SWEEP/FAILED返回来源的回放仍保存当前任务。Windows隔离runner仅登记入口，本环境未运行Windows。Browser控制器结束回执/vault原字节SHA一致，console error0/pageerror0/GL非法0，各ReadPixels warnings4保留，不计性能。

## 来源、原件与方法负例

953纯Git源文件字节实核；45既有规范化音频.import含uid/格式差异，与Git侧车分列并保留原缓存字节，.blend/.blend.import排除。全部PCK payload MD5实核：新QA对旧QA仅main.gdc、登记/53类缓存排序变化及新增测试remap/gdc；资产payload全部保持。新QA对同源生产只增加只读桥/原warehouse bin并改变project.binary/登记缓存及排序，53个完整class块相同；不称production bit-identical。原railcut bin b50e1f…和warehouse bin28c909…未改写。

[证据manifest](evidence/20261005-pr15-replay-save-boundary/manifest.json)：**100文件/13,904,237bytes**，逐文件size/SHA实核，接受范围14原PNG全部逐张已看。收尾失败首browser的6张方法负图原样保留、未列已看。profiles/私有缓存/凭证/制作资产不入包；原bin引用已封前片，不重复制造记录。

方法负例均保留：首预检把Z僵尸误计active而在引擎启动前拒绝；reader误用不存在的continue_level_id产生SCRIPT_ERROR并45秒timeout，wrapper1，native最终退出码和精确END原回执缺失不回填；首browser交互完成到safeTitle，with停止后finally重复close导致wrapper1，原END receipt未写，不能改称actual0；首stage准备误将规范化.import按Git字节拒绝，未启动导出/资产制作，另只读路径诊断使用非-z遇中文quoted路径失败。改正后新命名/新UUID/profile，不覆盖原脚本/request/log/PNG/result，也不重构精确时间。

## 当前边界与下一步

上述引擎及browser/HTTP均END；封存实际核live0/ports12815、12816、12817 closed。原活动profile保持depot END的真实radio续关存档，不与冷夹具profile合并。Site v3、R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281及制作独占接口保持，无新资产请求。

继续原profile radio3波：明确新的fixed1ec/sourcepins与QA-PCK，先精确旧cfg/checkpoint核对；原producer900/UI120/波300预算、原八字段先封，再1×/2×完整前后指纹与原回执；短波pause只按真实phase判定；credits开启/滚动/六关完成保存/reload/reopen、安全Title END。不得把前五关旧源已验拼成同最终候选full13。radio/yard whole、完整同源13/六关全回放/3D全事件/所有武器工具自然专项/A3/fullsmoke/FINAL/正式origin/PCK+128B/耳听/设备/APK仍待；冷历史全过程档隔离未通过。GPT PLAN/REVIEW unavailable。

## 原Title刷新持久边界补验（14:21 END）

父端要求补实测刷新后的回退。新隔离profile负轮 `python3 /tmp/pr15-web-controls/replay-save-classification-20261005/browser_refresh_negative_v2.py` source8532：已结算WON→原Replay→M→原设置Title→无fixture参数原URL重新载入→原Continue，错误warehouse指针仍持久、Continue确实warehouse；actual0，14:18:15.212148→14:19:38.297508，10+6trusted，成功复現负例而非product pass。正轮 `python3 …/browser_refresh_fixed.py` source1ec同一路实际pump，静音仍true并持久、两cfg全文/公开checkpoint刷新精确保持、清关/stats/complete保持；实际Continue pump及原两页教学→安全Title，actual0，14:20:07.458535→14:21:53.337877，10+10trusted，console errors0/pageerrors0，各4ReadPixels警告。所有自有引擎/browser/HTTP END/live0/portsclosed；原活动profile未打开。不是浏览器关闭重开、fresh胜利或whole接受。

首刷新方法仍带cold query，刷新再次触发原冷夹具而非Title，120秒等待超时 actual1，14:14:54.513893→14:18:02.352292，原loaded-script/request/log/receipt/vault与5未审方法PNG保留。新轮 canonical URL重新载入，不写storage/phase/tick。负轮部分PNG沿用模板文件名含correct/pump，实际画面/状态为warehouse，不能根据命名称pass。新增[独立补充manifest](evidence/20261005-pr15-replay-save-refresh/manifest.json)，16接受PNG全部逐张已看，前片100文件重新逐size/SHA核仍保持；profiles/缓存/凭证排除。最小生产代码仍1ec，配置偏好可写与campaign进度保护分别证实；radio仍未开始。
