# PR15 title200 全入口独立切片

完整记录作者正式关已在fixed15c完成29次exit0/ERROR0，证据交付a2188f988e525263dbdf3968e9edd8153326c52f。父端独立QA以fixed15c进行，本片不修改历史验证范围、不重跑有效项。后续git ls-remote认证失败，未换凭据/helper/remote；本地实现和隔离测试继续。

父端实际67f反例11/2exit1/ERROR0：1600×720、200%、logical640×360，Help y369–417、Quit y427–475完全offscreen，100%正常。a218 title blob未改。本片先在同原生产title代码上验证所有入口/子流程，不止补两个按钮。

范围：主菜单Start/Continue/Journal/Help/Quit；新档Continue禁用、合法保存进度Continue实际入SCOUT；六关任务选择/简报和返回/实际接受；帮助完整正文滚动及关闭/Back；档案完整六夜滚动/关闭；退出确认取消/设置/实际退出；Tab/Enter/Escape/M键、resize与后台focus恢复。窗口1280/1600×720、100/200%、desktop/force-touch形成8组；原生XTest限独占:112与strictisolated XDG。进度解锁为隔离档原GameSettings API fixture，不称实际通关。

实现方向：可滚动主菜单flow、响应viewport的modal限高，正文滚动且标题/返回固定，保持原文案/信号/入口；检验任务页/档案/设置全journey与键盘focus。只改title/UI、共享测试及native测试键helper，制作源/GLB/atlas/manifest不动，SCOUT→ALERT→SWEEP不变。

固定负向源和实际log/exit先保留，再修UI；正向固定源码后只跑本片对应测试，不重跑15c formal29。每图留存hash与窗口/比例/scroll/focus/入口结果，实际看关键100/200帧。提交源/证据独立于a218；parent独立title QA待。设备/模拟器仍全计划后，不merge/生产/height/G。网页GPT PLAN/REVIEW unavailable。


2026-10-03 实现/作者正式验证完成：[完整报告](AMBUSH_PR15_TITLE_20261003.md)，固定226505fb7cc424fb8ff955e94f98f086835b2423正式8组2391/0+keyboard7/0，2次实际exit0/SCRIPT ERROR0/ERROR0、72物理PNG hash核对、1119+4原生输入。负向195/44及开发372/0独立留存，全部队列已结束。父端fixed15c limitedQA结果单列不加计数，新title独立QA待。源码/证据本地提交尚未同步，Git认证未恢复不重试/绕过；恢复原Git后push/只读核对。资产制作输出未动。后续FX/autoREPLAY2×尚未实现/A3/最终同候选与APK继续，设备后置。
