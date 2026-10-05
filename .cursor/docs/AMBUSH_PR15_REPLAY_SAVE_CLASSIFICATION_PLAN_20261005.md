# PR15 历史回放返回 WON 存档边界分类（2026-10-05）

父端报告独立 QA 已于13:12:49.504635 END并归还唯一引擎窗口；其原pump/railcut语义12595/0、16350/0及railcut自然whole1×/2×完整指纹结果归父端，不合并作者计数。父端证据摘要SHA `4a4b1af6ddb22a154f59cece2f6dd5b7bb1b60a5eb6c0ac6d64519ffe8f33397`；当前执行环境尚未找到其原报告/首次Space负例，已请求确切路径，原件待核，不臆造读取成功。

固定生产8532c4c3084d1a5672bbe28dc96e1c02522a8f05/game tree45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85；接续HEAD f0d97457faa81b94a51cae12c40e07987267c738。原活动profile不打开、不覆写；私有Site v3/资产制作接口保持。先分类/必要修复，再radio；单引擎串行，无设备/APK/merge/生产发布。

源码事实：普通自然胜利由 `_extract_win`→pending_result→`_flush_pending_result`→`_show_win_result` 完成写档，然后原Replay按钮进入历史，Space→`_exit_replay_to_setup`→`_show_win_result` 再次调用record_win。现有冷consumer桥直接赋phase=WON并装原bin，跳过首次胜利结算；第一次Space返回会首次执行胜利写档。生产Replay按钮只绑定当前battle_log；当前未找到普通UI加载外部历史bin并跳过结算的入口。以上为源码分析，不代运行复现。

隔离分类采用已核同源native stage和实际StorageGuard/unique user://，每轮45秒上限，外部脚本/独占原receipt/原文件SHA先封。使用原railcut八字段bin，不制造新战斗。分别记录：(1)未结算冷WON夹具在REPLAY中及首次Space前后两cfg全文/公开checkpoint/存档字段；(2)已结算WON重复Replay/Space前后同字段；(3)显式植入未来完成档与旧WON的对抗夹具，单列不可据此声称普通玩家UI可达。控制回调/输入事件专项不得称自然whole或正常producer。核原bin、固定来源、完整实际日志、退出码与错误，保留所有失败。

分类门：如普通UI可达历史返回错误回写进度，先最小生产修复，原失败/固定回归和真实渲染边界另封；如只属冷夹具缺失首次WON结算，说明原UI时序与已结算重复返回实际边界，不能把冷fixture全过程存档隔离写为通过。任何分类结论须引用实际复现和原QA证据范围；没有证据时保持待核。

完成此片normal push/readback与Draft PR15同步后，继续原depot存档radio3波：原producer900s、UI120s、每波300s；原八字段先封，再自然whole1×2×分别完整before/terminal-after指纹、原回执/各层wall分列；credits开启/滚动/六关完成存档/同profile精确reload重开/安全Title END。短波pause按输入后的真实phase分类，不伪造暂停检查点。radio完成后才隔离消费原yard bin whole；mine/repack自然专项仍独立，不造状态触发。GPT PLAN/REVIEW unavailable。

父端后续明确补充原QA：桥载原bin、设WON而未配对producer胜利存档；原全1×终点后←→Space首次写railcut→depot，cfg与localStorage变，settings/原bin/模拟域/捕获IndexedDB镜像相同。该补充是父端所述原件事实；完整文件尚未在本环境找到，不称已逐文件读取QA包。不能称冷consumer全过程档不变。

作者隔离分类fixed8532 actual0/28checks/0failures/E0/S0/实际Guard：冷WON首Space写下一关，已结算WON重复两次checkpoint原文保持；显式未来完成档配旧WON会回退，但属于人为注入、不证明普通UI可达。另发现普通已结算WON→Replay→M→设置返回标题→Continue会退回刚完成的关卡：仓道胜利本应续pump，真实browser却进warehouse。修正收尾后的独立新profile负例actual0、原可信键鼠/原UI均封，browser/HTTP END13:44:06.095120；shared回归fixed8532真实15/2、actual1/E0/S0/Guard，精确失败是WON回放M进度和Title续关两个断言。

最小实现只让 `_save_progress` 将return_phase=WON的REPLAY视为已结算胜利，保留record_win已写下一关；主动M音频设置照常保存，SCOUT/SWEEP/FAILED回放仍保持当前任务。不改变冷WON首次返回原结算行为，不引入外部历史加载UI、不扩大不可达夹具修复。新增paired结果回归与两平台隔离runner入口。固定候选回归/官方Web导出/真实browser对照尚UNRUN；完成后再radio。

方法负例保留：首预检误把Z僵尸认作活动进程，未启动引擎；reader误调用不存在函数导致45秒timeout，原script/request/log保留、native退出码及精确END回执未留存；首browser交互结果到safeTitle但with结束后重复ctx.close导致wrapper1，原END receipt缺失不回填。新轮独立命名，不覆盖旧原件。

当前：IMPLEMENTED_FIX_PENDING_VERIFICATION；radio仍UNRUN。
