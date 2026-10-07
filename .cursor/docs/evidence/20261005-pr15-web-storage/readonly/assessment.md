# Godot 4.7.2 Web 持久化只读源码评估

日期：2026-10-05。游戏只读 HEAD：`83a7a725ad1647d1360930c2cd596f3a4b709d20`。引擎固定：`4.7.2.stable.official.ed1daf0bf`（完整 SHA `ed1daf0bf001b61586d9930840f2f1394092c079`）。本包没有运行 engine、browser、tests、installer、Blender、资产工具；没有编辑仓库或更改网络安全。只把既有官方源归档的相关文件复制到本包 source/ 供引用。

## 结论

`ConfigFile.save()` 返回与 IndexedDB 保存完成是两个边界。FileAccess 写后关闭会自动请求 Web 同步，所以当前代码未显式 `force_fs_sync()` **本身不能证明漏同步**。自动同步在下一次可执行主循环启动，是异步流程，源码没有“8 秒周期”。`force_fs_sync()` 只置待同步标记，返回 void，无公开完成回调、完成信号或错误结果。加它再 sleep 8 秒不能建立保存完成契约。

`JavaScriptBridge.create_callback()` 是公开、受支持的 JS→GDScript 回调接口；Emscripten `FS.syncfs(false, callback)` 也有明确的完成/错误回调。因此可以做事件驱动保存反馈。但是 **stock Godot 4.7.2 没有只用 Godot 公共持久化 API 就可等待 ConfigFile→IndexedDB 完成的接口**。固定模板适配层或独立页面存储层才可把真实同步完成送回游戏。不能把内部 `GodotOS._fs_sync_promise` / `GodotFS.sync` 当作公开稳定 API。

父端转述的独立 QA：真实 UI 静音后 800ms 刷新丢设置；等 8 秒 reload 32/0。这里未复现，也没有检查该浏览器运行证据。后者不能覆盖前者。静态链路解释存在异步刷新窗口，不能据此判定 800ms 失败的唯一根因或声称加 force 已修好。

## 文件与行证据

本包源根：`/tmp/pr15-web-storage-source-readonly/source/godot-ed1daf0bf001b61586d9930840f2f1394092c079/`。以下行号来自本地原始文件；网页文本提取的行号可能压缩空行。

| 路径与行 | 事实与含义 |
|---|---|
| `core/io/config_file.cpp:145–154,191–210` | save 打开 WRITE，写入字符串，返回 OK；函数中无 IndexedDB 等待。打开失败返回 err，写入后 `_internal_save` 返回 OK，也不检查异步存储错误。|
| `drivers/unix/file_access_unix.cpp:198–208,619–627` | close / 析构均 `_close()`；`fclose` 后调用 close_notification_func。ConfigFile 的局部 Ref 释放走此链。|
| `platform/web/os_web.cpp:227–239,311–318` | 安装 close 回调；已启用持久化、WRITE、`/userfs` 文件关闭后置 `idb_needs_sync=true`。|
| `platform/web/os_web.cpp:74–89` | 下一 main_loop_iterate 在 persistent、needs_sync、!is_syncing 时先置 syncing 并清 dirty，再调用 godot_js_os_fs_sync；完成只清 syncing。写入发生在旧同步期间仍会重新置 dirty，让后续循环再同步。|
| `platform/web/os_web.cpp:263–275`；`platform/web/javascript_bridge_singleton.cpp:412–414` | force_fs_sync 仅置 dirty；桥接函数仅转调，无 callback / promise / Error 返回。|
| `platform/web/web_main.cpp:80–109` | 同步检查随主循环执行，受帧调度/限帧影响；没有固定秒数周期。正常游戏退出进入 finish_async。|
| `platform/web/js/libs/library_godot_os.js:155–169` | `FS.mount(IDBFS, {}, path)`，无 autoPersist；启动 `FS.syncfs(true, cb)` 从存储恢复。|
| 同文件 `191–205` | GodotFS.sync 使用 `FS.syncfs(false, cb)`；错误写日志并 **resolve(error)**，不 reject。`_syncing` 时打印 Already syncing 并立刻 `Promise.resolve()`，既不等待现有提交，也没有提交新快照。|
| 同文件 `292–299` | GodotOS._fs_sync_promise 保存本次 Promise；then(err) 调用 C++ func()，**丢弃 err**。自动失败不会把 dirty 重置为 true；若此后没有写入/显式请求，源码未安排重试。|
| 同文件 `255–269` | 正常退出先等待现有 Promise，再最终同步；同样忽略错误。浏览器 reload/关标签没有保证走这个路径。|
| `doc/classes/JavaScriptBridge.xml:14–20,41–62,94–100` | create_callback 要保留 JavaScriptObject 强引用直到回调；Callable 接收一个 Array 参数；eval 默认 engine runtime context，get_interface 只能取 window 上的属性；唯一声明信号是 PWA update。|
| `platform/web/js/libs/library_godot_javascript_singleton.js:217–239,346–395` | create_callback 转 arguments 为数组；eval(false) 为直接 eval，可在该固定构建访问运行时词法环境；eval(true) 是 global eval；eval 返回 Promise / 普通 JS object 不会自动成为可等待 GDScript 结果。|

公共来源：[固定提交 OS_Web](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/platform/web/os_web.cpp)、[固定提交 Web JS 文件系统](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/platform/web/js/libs/library_godot_os.js)、[固定提交桥接 API 文档](https://github.com/godotengine/godot/blob/ed1daf0bf001b61586d9930840f2f1394092c079/doc/classes/JavaScriptBridge.xml)、[Emscripten FS.syncfs 公共契约](https://emscripten.org/docs/api_reference/Filesystem-API.html#FS.syncfs)。Emscripten 在线文档为当前版，具体构建行为以下述既有导出 JS 为准。Godot 4.7 文档站本次读取不可用，固定源 API XML 已读取。

官方 raw URL 逐字节只读比较：os_web.cpp、library_godot_os.js、library_godot_javascript_singleton.js、JavaScriptBridge.xml、version.py 均与既有归档提取件相等；version.py 为 4.7.2 stable。

## 既有实际导出 JS 核对

`/workspace/pr15-web-artifacts/1d17a16156d2afae0cbdd77cf73030a57f953ada/release/index.js` 为单行压缩 JS。以下为 0-based 字符偏移（本次 ASCII 前缀也对应字节偏移）：

- GodotFS 对象从 131157；确认 mount(IDBFS,{})、_syncing 分支、resolve(error)。
- GodotOS 从 132847；确认 finish_async 等待再最终同步。
- _godot_js_eval 从 185479；确认 eval 默认运行时作用域。
- _godot_js_os_fs_sync 从 195818；确认 err 被丢弃。
- _godot_js_wrapper_interface_get 从 216619；只访问 window[name]。
- IDBFS transaction.oncomplete 从 25946；提交无 error 时 callback(null)。FS.syncfs 从 34563；逐 mount 同步，完成时 callback(null)，错误走 callback(err)。并发次数 >1 时只警告，**它自身不串行化**。
- 未发现 `Module["FS"]` 导出。因此不能假设页面全局 FS、window.GodotFS 或 engine.rtenv.FS 存在。默认 eval 可以进入固定运行时，但对内部对象的依赖仍是版本绑定适配，而不是新增的公共持久化 API。

SHA256：index.js `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba`；既有 source.tar.gz `e607e9985e1c201bc9cdc1aec8a120f0c3f53b9603f1f828e2b748534a2471ef`。

## 当前调用方与最低建议（无实现）

游戏 `ambush_loop/scripts/game_settings.gd:151–163` 保存设置；`:389,411` 保存统计/通关并在 record_win 后再写一次统计。`ambush_loop/scripts/main.gd:1471–1481` 保存进度。均忽略 cfg.save 返回 Error。设置和进度必须共用一个反馈协调点，否则设置声称保存时仍可能有进度待写。

1. 先收集 cfg.save 的 Error。失败进入明确失败状态；成功只进入“正在保存”。不要把本地 save OK 等同于“已持久化”。
2. 保留引擎已有 close→dirty→主循环同步，不另开不受协调的 GodotFS.sync / FS.syncfs。最小固定版本方案是只观察真实引擎 `FS.syncfs(false, callback)` 的完成，保留原回调语义与调用次数；把开始时的保存 generation 和完成 error 通过游戏自己的 window 接口及 `create_callback` 送回 GDScript。观察层接入运行时需要固定模板/默认-context eval，并显式声明这是版本绑定接缝，主作者集成时核对可达性。
3. 观察层应在首次游戏写入前初始化。每次本地成功保存增加 generation；同步开始捕获该 generation。只有该次 sync 真正开始、完成且 error 为 null/undefined，才能确认其覆盖的 generation。更新设置发生于同步期间时，旧完成只确认旧 generation；新 generation 保持 pending，等已有 dirty 机制启动下一次同步。回调强引用留在长期存活的协调对象；传回原始错误的 name/message 字符串与 generation，不能只传 boolean。
4. 错误后保留失败/pending 状态，由明确重试再次请求 dirty（force_fs_sync 可用于这个目的）。超时只能显示“尚未确认”，不能转成功。bridge 缺失、IDBFS 不可用、适配安装失败均不能显示“已保存到浏览器”。可读 OS.is_userfs_persistent，但它只是初始化时可用，不等于每次同步成功。
5. 应用内主动 reload/退出跳转可等 latest generation 成功后再进行；设置 UI 若允许继续交互，就保持 pending 标记且不承诺立即刷新安全。浏览器外部刷新/关标签可中止异步工作，不能靠 sleep、beforeunload 异步保存或一次 force_fs_sync 建立完成保证。正常成功回调的边界是此次 IndexedDB 同步完成；不承诺浏览器清除数据、存储驱逐、跨 origin/profile 或其他标签覆写后的保留。

此观察方案复用受支持的 callback 通路，但 hook 运行时是固定版本适配；**不是声称 Godot 自带公开 fs_sync_completed**。如果要求完全禁止内部 hook，则须引擎/自定义模板公开一个串行化且有错误返回的同步完成 API，或改用页面拥有的存储服务（将 schema/迁移纳入独立切片）；现有 ConfigFile 公共 API 单独不能实现这一反馈。

必须避开的误判：force_fs_sync 后立刻读 _fs_sync_promise 可能读到旧已完成 Promise；随便等一帧也不是保存批次契约；GodotFS.sync().then 无条件成功会误报 _syncing 立即resolve或 resolve(error)；只加 catch 无法捕获 resolve(error)；等待旧批次完成不能代表同步期间的新设置已提交。

## 尚待主作者/独立 QA 验证

没有实现、浏览器复验或已修复结论。集成后需以真实 UI 的最新 generation 成功反馈作为刷新触发条件，覆盖设置连续写入、同步中再次写进度/设置、显式错误反馈；刷新后核对实际文件/静音值。800ms 原失败与 8s 后 32/0 必须保留为分开的证据，不用后者擦除前者。浏览器实际 IndexedDB 错误、目标回调可达性、该失败的具体原因仍未由本包验证。
