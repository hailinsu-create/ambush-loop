# PR15 自有浏览器多标签发现与单页控制修正

2026-10-05，**RUNNING / 原warehouse单页回归**。当前生产仍dab870595175eed37a6d2a012bc69a76062d48b0/game tree4f49a7c9cb5a789fbb570bceb947eab7df2eb54a；私有Site v2不变，未改生产/制作资产/paid/merge/APK。

## 已完成原输入事实与环境更正

上一固定观察器回归 attempt `d8ba862ce497eb87f8d3fde463a5d35b` 原SCOUT/原三枪手雷与掩体/原两波自然SWEEP339与863/补弹与cell(24,5)地雷/原走近三项SWEEP掉落/原撤离WON，producer894.4934469409927s，actual0、无retry，原900门内。这是实际原玩家输入和自然终局事实，没有grant/force win/tick赋值。原八字段record **11,738,920bytes / SHA256 cd9ed64e7653770e5dcc24724be7bf862f09c907a043ac23503570cdc364f49f**，schema2/win/62events/713frames/playbackterminal5228，validation[]；244 browser trusted与244 engine输入，同attempt，原件未改。

06:46:38原whole1×开始前打印真实context.pages：**5页，3个localhost游戏URL、2个about:blank**。此前恢复profile后的“单引擎”假设错误；首deferred包未实际采page_count，标UNKNOWN，不能推广为controlled single engine。d8的自然WON/原记录事实保留，但其wall结果 **ENVIRONMENT_CONFOUNDED**，不称单引擎性能；不同Title 9–29ms/403–514ms和后续0.4s样本也不能当稳定仓道开销/paired性能归因。

原因是Chromium persistent context恢复自有旧标签，controller仅使用pages[0]却未关其余。全部属于独立QA profile，不是用户浏览器。没有把发现说成游戏产品失败。whole环境不合格，已主动停止，**INTERRUPTED_NOT_PASS，未到自然terminal，不称完成1×**。PTY Ctrl-C只结束shell wrapper，Python变孤儿且12815仍alive，这一方法负例保留；随后从原receipt核精确controllerPID150598/命令，显式对该自有PID SIGINT，Playwright关闭上下文，06:51:19端口connect111。未对其他项目进程发信号，未删除任何profile/bin/cfg。内核proc尚存不能等同live，后续按state/command核，不冒写Python exit0；本次wrapper实际1、显式中断与端口结束分别列。

[25件完成数据manifest](evidence/20261005-pr15-web-warehouse-multitab-result/manifest.json)包含d8原record、输入/PNG/actual0 receipts、部分whole操作、页数与中断/关端口原件。旧失败和late38MB原record仍独立；不将本包合并成旧900 PASS。progressive driver在之后另改RPC，同目录后续版与重构的实际interrupted-whole加载版明确分列，未改历史JSON。

## 修正与当前实际单页回归

外controller在首次goto/玩家输入前核所有旧URL仅本QA localhost/about:blank，保留pages[0]、关闭自有surplus并assert len(context.pages)==1。首次单页启动实际关闭5个surplus（启动有6页），写before/after原件；同profile reopen helper也执行相同规则。只关闭自有标签，不清profile/存档/缓存，不修改游戏。

原单页Title加载后从已记录第一条state与d8原WON state进行离线exact比较：**两cfg文本/SHA全同、yard/warehouse cleared、next=pump**。不是只读当前localStorage自比；未导入/seed/cfg写入。原Start→warehouse行→简报→新knife-only SCOUT、已读教学不重复，attempt `1289c65c34af63cf62707bf18ddc4cca`，入口actual0。

仅控制器进一步在同evaluate取已存在匹配ID的同步reply，未就绪才用25ms只读poll（不RAF/manual tick）；实际10查询仍357–488ms，**未宣称改后稳定9ms**。现阶段renderer/浏览器消息调度仍有成本，逐阶段按原wall cap。桥/PCK实际 **bridge433d191181b311d09d011f8ba319b91aaee11833b2416a1c7124f924554d5b18 / PCK17711fe6f3677316cb8bddf4368a6c66063ca3d7d1c4e2a8c65f2f906fd707bd**，没有新export或生产变化。

单页producer START07:00:43.408Z，原900门有效；第一波原ALERT START07:04:04.401→自然SWEEP07:04:27.646，tick339。实际原携带地雷/再部署正在进行，后续WON/原record/原1×2×/pump handoff与reload在达到后再填；无预造通过。原初次warehouse教学是三页，之前已纠正。原SCOUT包含实际控制器准备空闲，录制时长不等battle时长/吞吐。

接下来完成本单页warehouse，趁原WON record仍在做whole/seek-focus，然后原Continue→pump handoff与首教学preview→Title/reload→新的pump刀装attempt；后四关按既有矩阵/120-300-900和whole预算逐关。APK/资产制作/paid/merge/public仍后置；生产origin、音试听/手感/设备与FINAL/A3不称通过。用户已明确恢复，不回退成暂停状态。
