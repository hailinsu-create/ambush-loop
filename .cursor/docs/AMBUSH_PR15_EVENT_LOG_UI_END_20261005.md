# PR15 日志/相机 UI 有界结果与 END（2026-10-05）

**已修复并完成作者限定验证，独占引擎窗口已归还；独立 bounded QA 待。** 固定生产代码 `8532c4c3084d1a5672bbe28dc96e1c02522a8f05`，game tree `45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85`，替代 dab/4f49 中日志/相机重叠布局。改动仅 presenter 34 行布局、专用历史消费者测试和两隔离 wrapper。main/replay/战斗/资产制作及 manifest 未改。日志与相机都可见、可操作，没有通过收起/禁用控件避开命中验证。代码已 push/readback 8532；本报告与证据提交另列，源码树相同。

宽屏日志在相机左侧；200% 紧凑逻辑 640×360 时日志在右侧、底部避开原132高触控栏，原短日志视窗保留滚动。镜头展开的既有抽屉行为保留，本片不称全HUD/全艺术完成。保留 SCOUT→ALERT→SWEEP、冻结计划，不混入高度分支，不 merge/APK/paid/public。

## 来源、包身份与实际范围

原 record 仍是 ec121 仓库正常 producer，26,554,792 bytes / SHA256 `28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266` / attempt1289 / 两波 / 62events / 2072frames / t16102。使用原8字段冷绑定历史消费 fixture，显式一次性 WON→Replay/暂停/初始10788，只用于设置消费者；不新增自然通关、解锁或 whole，后续验收聚焦/滚动/镜头/滑条/键盘均由原玩家输入完成，无直接 set_tick/focus mutation RPC。不要把这些消费者结果称正常战场生产、全六关或设备性能通过。

官方 Godot 4.7.2 matched debug/release 完整 Title 导出各 **actual0 / ERROR0 / SCRIPT ERROR0**，493个既存项目 sidecar 同字节复制，既存生产 UID import 元数据对齐；排除 Blender 源，未重跑作者生成器。导出前后所有 tracked game 文件 SHA 相同。生产 PCK（debug/release相同）38,090,812 bytes / **`d3fa7380c74dd9bb49447fd56db45b5a37e20ae16c871b8a89d5b4153a07edfd`**；release WASM39,514,754 bytes / `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`。

[生产9文件canonical bundle身份](evidence/20261005-pr15-event-log-ui/production-bundle.json)：77946880 bytes / **`f62190f97b8c763a876278fa6ac25e0b5148af08db89b10228b865a621a25b0f`**，按文件名排序、mtime/uid/gid0的PAX tar，逐成员重读 size/hash exact。包在 `/workspace/pr15-web-artifacts/8532c4c3084d1a5672bbe28dc96e1c02522a8f05/event-log-production-release-canonical.tar`，非线上 Sites 的分片运输包，未部署。

受控 QA v2 PCK64,662,184 bytes / **`f02f9042f42d5fd08f286bbecfc386295bfb20fd677413d86c1bc33ae5a99e21`**，桥SHA `f9a0484bfbb5ada4ce03a1174c7e0d7a7815d9952a770679b988aebfa87e77b6`；QA stage `/workspace/pr15-event-log-qa-stage-v2-20261005`，输出 `/workspace/pr15-web-artifacts/8532c4c3084d1a5672bbe28dc96e1c02522a8f05/event-log-cold-qa-v2-20261005`。所有 PCK payload MD5实际验证。相比生产只加桥gdc/remap和原record.bin，改project.binary/uid_cache及全局类缓存排序；53个完整原类block逐类字节相同。最初audit allowlist遗漏排序差异导致runner actual1，官方export本身0；两个v1/v2负例原件与独立结构验收actual0均保留，不称 bit-identical。生产相对旧 dab 只加测试gdc/remap、presenter.gdc与两个注册缓存；art/ArtSource payload没有变化。

## 实际门与原始退出码

| 门 | 实际结果 | 能证明什么 |
| --- | --- | --- |
| 旧源 headless 基线 | 36 checks/6 failures，actual1 | 六组合重叠/越界已复现；原旧Web中心遮挡失败仍另存 |
| 最终 headless 六组合 | 36/0，actual0，run002608 | 1280×720 1×/2×、1600×900 2×、960×540 与两种触控HUD的几何/原record/domain |
| 有界真实 Window | 103/0，actual0，runc118d | 三组合（1280/1×touch、1280/2×touch、960/1×touch），原 XTest 鼠标/滚轮、9个原行左中右 exact seek/ring、相机角不变、三实际PNG |
| Web v2整批 | **actual1 / 613 checks**；desktop与scale200各有完整END与before/after保存 | 桌面6、200%10个文字聚焦；两波、原相机旋转、原滑条、ItemList键盘/P播放暂停、200%touchCancel+DOM焦点后新触控。整批在手机滑条落点早于首fire时失败，未改写整体结果 |
| 手机横屏独立v3 | **actual0 / 284 checks / 118.532809s** | 915×412、scale2、实际640×360逻辑+92px横向留边；10个两波文字聚焦，鼠标/CDP touch、镜头、原滑条、键盘、取消/焦点恢复；原记录和模拟域不变 |
| 已完成case离线实核 | **198/0，actual0** | 两个v2完整case加独立v3手机，26原文字聚焦逐条 exact event/tick/actor/attempt/wave/ring/camera；before/after、可信输入、六原PNG hashes、原3D/source invariants。只核既存raw，不冒充一轮整批浏览器actual0 |

[已完成case精确审计](evidence/20261005-pr15-event-log-ui/completed-web-audit.json)中桌面 trusted22/engine22；200%trusted40/engine66、手机trusted42/engine70（触控同时产生原ScreenTouch与鼠标模拟，因此不同，不强凑1:1）。每段单页、case结束后关闭 context再启下一case，旧producer profile未动。记录hash始终28c909、live/domain exact、frame checks每case19/0。每段浏览器原输入 isTrusted=true，点的是字体实际glyph宽度的5%/50%/95%，并核原ItemList滚动后hit index。字体/滚动几何使用官方 [ItemList API](https://docs.godotengine.org/en/4.7/classes/class_itemlist.html)；全局屏幕变换来自真实Godot Window，未将915×412拉成错误双轴比例。

Browser plugin not available；使用既有 Python Playwright1.62.0 + `/usr/bin/chromium`，无依赖安装。原 localhost12826、完整3D/HUD中文不为空，无框架覆盖；console error/page error/Godot script/GL_INVALID/INVALID_OPERATION均0。v2整批与v3分别4条 GPU ReadPixels warnings保留，不称零warning或30/60FPS。九张接受范围原PNG（三Window、六Web两波）均实际查看，中文字、日志/镜头间距、3D环与两波身份可见；其他负例/partial图仅保全，不作为通过。

## 方法失败与证据损失

全部保留，不能略过：首fixture漏3D presenter SCRIPT ERROR，精确PID/UID/argv SIGINT收尾actual130；首次环境匹配因不可读environ失败未发signal，曾短暂同时两个headless probe，不作计时。旧 synthetic push_input108/39 actual1，仅方法负例。Window首launcher缺显式 `AMBUSH_TEST_X11_DISPLAY`，助手在XTest前拒绝，99/42 actual1；后续六组合180s cap actual124、没有完成report，不计PASS，保留四原PNG。最终三组合240s cap内自然actual0。

Window方法负例六张通用capture路径被后续运行覆盖：原code/log/report及六hash保留，仅1600那张仍与原SHA匹配并实际恢复，**另外五张原PNG不在，未重构**。四cap图先拷出后后续测试，保全。Xorg首次stop `/usr/bin` argv与wrapper exec `/usr/lib`不匹配，无signal；随后精确实际argv/UID停止actual0，未动常驻99。

Web首v1 driver误点隐藏旧BottomBar slider，actual1/92，之前的文字/镜头有限正例不等整批接受；原after-seek state未保存，不重构。v2 corrected只读桥选可见 TouchHud/ReplayScrub；手机 `.945`近似点实际落15023，wave1但早于原首fire15054而失败，所有before/after与实际落点保留。v3只重测手机，实际玩家滑条`.985`露出第二波开火；无生产修改、不加直接seek API、不重新跑自然仓库。旧5dba首geometry receipt同名覆盖损失照原报告保留，不在此伪造。

## 命令、封存、END与下一步

实际命令为 `env AMBUSH_TEST_RECORD=… timeout 45s bash ambush_loop/scripts/run_isolated_test.sh <fixedGodot> event_log_layout_test.gd`（0）；Window增加 `DISPLAY=:136 AMBUSH_TEST_X11_DISPLAY=:136 AMBUSH_TEST_LAYOUT_MATRIX=window-bounded`、`timeout240s`、`--render`（0）。包装器Guard实际通过。`python3 export_production.py`（0），`export_qa[_v2].py`（engine0但初始metadata audit runner1）、`accept_qa_audit[_v2].py`（0）；`browser_regression.py` v1/v2各1、`browser_phone_v3.py`（0）、`audit_completed_web.py`（0）。实际loaded-script/source/argv/log/receipt均在[封存manifest](evidence/20261005-pr15-event-log-ui/manifest.json)，manifest列118条数据/15,538,576bytes（不含manifest自身），每件SHA/size可核。PowerShell只做入口/音频flag源级对齐，未执行Windows。

[END receipt](evidence/20261005-pr15-event-log-ui/end-receipt.json)：08:59:06.505UTC，browser PID155658/156192/156600全部absent，Godot/Chromium进程空，Xorg136/PID153896/socket absent，port12826 connect111，全部自有engine/browser/server END。没有pump producer、其他新QA或后台运行。

下一步交给父端独立 bounded QA：固定8532源、完整官方release与明确QA-v2包，重点原日志文字左/中/右命中、可见原滑条、镜头继续可用、窄屏与触控/取消焦点，并对照旧负例。独立QA通过且归还窗口后，再在保持原fresh profile/cfg的原Title Continue继续pump→railcut→depot→radio。父端已授权必要时同private Site更新，但本轮优先归还独立QA窗口，线上仍v2/aa19/dab、owner-only ACL未变，候选不能冒充线上修复。

正式origin、实时速率/A3预算、全新六关/旧schema/fullsmoke/FINAL/耳听/设备与可追溯APK仍待；不自行前移。本片production/source+包/功能范围可审，不是全计划最终完成。资产接口保持 [所有权与接收契约](AMBUSH_PR15_INTEGRATION_20261002.md)：root所有main/presenter/view_state/replay/共享tests/loader；资产作者所有ArtSource/generator/GLB/Blender/atlas/制作manifest，接收验收过的独立提交，不整体合入WIP。网页 GPT PLAN/REVIEW unavailable，独立QA未预绿。
