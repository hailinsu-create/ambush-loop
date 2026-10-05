# PR15 HUD内部子诊断执行声明

2026-10-05。父端读44a034后明确授权继续独占引擎，按[已交条件方案](AMBUSH_PR15_REPLAY_HUD_CAPTURE_CANDIDATE_PLAN_20261005.md)先定位具体成本，只有实证支持才实施一个最小优化。archive下载失败路线停止，server身份unknown；同Sitev4不部署，规则/资产不变。

本子诊断production source1ec3198/tree1e8，旧dab yard原bin e850/6339/wave0/frame792/SCOUT不变；原P0 cap135.99秒actual1和混合开销不改。外部stage在既有HUD QA上只加HUD getter capture count/elapsed、insideHUD及insideTouch子count/elapsed、touch refresh/style count/elapsed；原root/presenter/固定缓冲/postdraw保留。嵌套列不能相加为全帧。OFF保留共同lookup/branch/depth/counter/sampler，ON加stamp，时钟GCD100µs限制另报。

全部脚本先封存并自动连续native Guard→一次export→pack核→P0→OFF ON ON OFF→END，不用人工stdin空等。**本diagnostic总cap600秒**，含自首engine起native/export/启动/P0/idle/收尾；P0≤120，RUN≤90，各static+advance warm2/collect20、≥12实际样本/窗、2048 fixed rows，overflow无效。P0真实positive advance与paused negative、ON→OFF reset、原record/domain/fullcfg/checkpoint及canonical/20骨/socket中性先过；失败停止并END，不再扩窗。

若capture或style贡献不明确/净采样扰动不能与漂移分辨，报告限制，先改方法；不靠source或旧native热点选优化。若定位稳定实证，再冻结唯一候选及完整diff/固定SHA，另一个预声明有界A/B包（总≤600秒、4串行ABBA、同fixture/实际同source基线、共同OFF sampler、warm2/collect20/同预算/不利pair保留）核收益，和对应合同原生测试（每门≤60秒、实际Guard、安全END）分别计预算，不将多个包冒称一个600秒窗口。

candidate前后要核完整source/frame/状态cfg/checkpoint/来源切换/seek/暂停、静态像素和实际输入/回放，以及受影响的历史/旧schema/生命周期/装备合同；合同/pixel/稳定收益失败保留并不接受优化。仅局部sample不能代表最终同候选13波、听感、30/60FPS、设备或整帧唯一瓶颈。全自有engine/browser/HTTP关闭后交父端独立QA，实质候选未经独立合格不更新Site。

启动前状态：仪器源/控制已准备，未运行诊断、未实施生产优化。actual START/END/pack增量/方法失败/结果将在独立END记录，网页GPT PLAN/REVIEW unavailable。
