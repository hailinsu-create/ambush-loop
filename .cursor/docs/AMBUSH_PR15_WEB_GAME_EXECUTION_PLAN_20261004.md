# PR15 完整游戏 HTML 交付执行计划

2026-10-04，继承用户明确“优先实现 HTML 站点版本，完成后再考虑 APK”。当前固定 HUD/历史切片证据HEAD `4619a0b62030ad1aa1a4e42290f4aa0a1426f545`，game tree `53ffc88566b1ce7bd40daa1ce847c838f04fbd85`；[切片结果](AMBUSH_PR15_HUD_BATCH_RESULTS_20261004.md)。Web是交付顺序变化，六关13波、SCOUT→ALERT→SWEEP、完整入口/资产/回放范围不缩减。APK/JDK/AndroidSDK不是本轮门槛。

主作者独占集成与引擎/浏览器窗口。两个既有6.1只读包已结束，仅查Web模板/入口/兼容，不下载/导出/运行/编辑。制作源、生成器、共享atlas、GLB、Blender输出和资产作者生产manifest保持其所有权；Godot导出只读消费现有验收资产，导入cache放隔离stage。PR15持续Draft，不merge/混高度PR/更改旧dot状态站点。

## 固定前置与出口

- 实际project main_scene是Title；Title正常进main，全部yard/warehouse/pump/railcut/depot/radio。禁止使用export_a0_preview的preview_boot（固定yard、跳教学）作为游戏交付。
- 官方4.7.2原引擎固定；Web仅支持Compatibility/WebGL2。选单线程、无GDExtension、初始不启PWA，不额外要求SharedArrayBuffer/COOP/COEP或修改网络安全权限。
- 官方release API已重新实际返回非Mono TPZ 1,281,349,702bytes/SHA256 f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011；匹配模板仍待下载/整包hash/准确version.txt及web_nothreads_debug/release提取核验。当前/workspace和用户模板root无模板；/opt只有4.6.3引擎，不混用。
- 新独立Web preset保留全部resources及非Resource运行时JSON include；完整Title入口、既有3D feature gate不改成preview_boot。renderer.web显式Compatibility。固定源码、stage变换、sidecars/模板/PCK/HTML/JS/WASM完整清单可追溯。
- 浏览器工具现有Chromium/PythonPlaywright；agent-browser CLI缺失，按技能安装到workspace局部目录并复用Chromium。首次npm默认cache在只读home失败，改明确workspace cache，不扩大权限。Sites当前可读统一sites技能与native发布工具；旧名sites-building/hosting未列出，统一技能已读。技能source helper目前查找/资源读取未找到，不能宣称已具备该helper。先产可验证静态包，发布路径依据实际宿主与可用source准备能力确定。

官方依据：[Web导出](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)、[固定4.7.2 exporter](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/web/export/export_plugin.cpp)。技术文档说明的是能力要求，不能代实际导出/浏览器结果。

## 验证顺序与声明边界

1. 模板真实hash与版本，固定完整入口/运行时JSON/资源加载；隔离stage/debug导出，actual exit与全部ERROR/SCRIPT ERROR/导出异常保留，随后release包同源证明。
2. 仅serve完整导出目录，核index、JS/WASM/PCK正确MIME/字节/无404或HTMLfallback/安全origin；实际Chromium启动、截图/console/network、canvas焦点/resize/首访Title教学/SCOUT→ALERT→SWEEP。单线程须在非crossOriginIsolated且无SAB条件可用，不凭导出配置断言。
3. 实际Start用户手势后音频上下文/信号、键鼠操作和浏览器触控协议输入；暂停/Back/背包ALERT锁/触控cancel/blur后用户resume。留实际浏览器版本/软件WebGL限制，不转成手机或独占GPU/FPS验收。
4. 正常存档checkpoint：设置与已通关后同origin刷新/重开Continue与unlocks；现有存档是campaign checkpoint，不能承诺当前战斗或内存回放跨刷新恢复。拒绝存储/错误返回如实记录，不擅加战斗存档功能。
5. 完整六关13波与每新record完整1x/2x、pause/seek/eventfocus、旧schema1按真实fixture另验证；测试fixture/内部接口与正常玩家UI证据分开，不拼接成正常全程验收。测量Web wall及环境/collector影响，预算不达照报。
6. 可用宿主上独立新游戏Site，creation_intent=user_requested，默认private不扩分享；与已删dot状态站点无关。先核真实host MIME/资源限制与部署支持，再保存准确推送source对应包并发布。工具/helper或宿主未具备时交完整可验证静态导出包、路径/hash/传递方式与真实阻塞，由父线程接发布；不称未验收站点可玩。

每有意义切片固定SHA、实际命令/结果/未验与资产接口。完整导出、browser launch、有限交互、全六关回放、已发布URL各自计证，不能把样本或native通过冒称完整Web验收。用户最终站点交付由父线程统一；本作者持续实施并报真实阻塞。全计划/全艺术/FINAL仍按既有清单，Web优先不消除旧失败。
