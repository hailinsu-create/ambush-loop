# Ambush Loop M0 交付与待办

日期：2026-09-27。源码基线：PR #64 的 `c87aee4`；M0 已进入 PR #64，远端提交 `ab2076f`（与本地提交 `0558947` 的源码树 SHA 完全相同）。项目保持 Godot 4.7.2、安卓横屏、六夜，游戏版本 v0.6.28 / Android versionCode 77。

## 已验证

- 建立了可重复的本机环境检查和独立 `user://` 测试入口。直接运行可能清档的旧冒烟脚本会被拒绝（退出码 91）；正常、预期断言失败、强制终止三个模拟玩家档哨兵场景都保持存档和设置字节不变。
- Godot 4.7.2 导入成功；完整隔离冒烟退出码 0，覆盖六夜参考循环和 `SMOKE_SLICE_COMPLETE`。对 Android Back 去重的复跑出现 `SMOKE_OK_ANDROID_BACK_DEBOUNCE` 并到达最终完成标记；这次终端会话的最终退出码未被保留。
- 官方 Godot 4.7.2 Android 模板校验通过；调试 APK 导出并完成签名验证。最终 APK 38,675,390 字节，SHA-256：`B4013A1B49E31D0B744602EE8CF467826C7941745DA3D48C4A06B127CD454F48`。
- AAP-AN00（Android 16、arm64）已安装首次调试包，验证冷启动、标题、六夜任务选择、院子进入、三页教学及触控警报反馈，并保留画面证据。
- 审计了旧 Codex 纵屏切片：触控、安全区、暂停、速度等以现有横屏六夜实现为主；旧原子存档方法有价值，但必须按现有进度格式在 M2 适配，不能整体恢复旧三关状态。

## 尚未闭环

1. 真机上首次包的系统 Back 无明显响应；定位到 Godot 4.7.2/targetSdk 36 双返回通知后，代码加入 200ms 去重并通过自动断言。但更新 APK 的 `adb install -r` 两次都导致 USB 调试命令卡住，没有手机确认弹窗，所以最终修复包尚未在设备上验证。后台恢复和实际触控录像也待复验。
2. 尚需一位没读过攻略的人做一次首局：只给 APK，让其从标题进入院子，记录第一次拿枪、第一次尝试警报、完成/放弃时点和每个求助点；不要口头引导。结果用于 M1 的 R45–R53 排序。
3. 本机 Android SDK 只有 build-tools 34.0.0/platform android-34；Godot 导出 targetSdk 36 时提示回退使用 34.0.0。调试包已导出成功，正式发布前需补齐目标 SDK 工具并复验。
4. 网页版 GPT 桥接的 `status` 返回 `EDGE_CDP_UNAVAILABLE`，未进入登录或授权阶段；PLAN/REVIEW 没有被假定通过。后续需修复专用 Edge CDP 再跑审核。

当前 APK 是调试签名包，不是 1.0 正式发行包。不要卸载设备上的游戏来解决更新问题，也不要运行未隔离的清档测试。

## 2026-09-29 复验补记

- 按用户授权安装并接受官方 Android SDK 许可；本机现有 Godot 4.7.2、JDK 17、ADB 37.0.1、Android platforms/build-tools 34 与 36，以及 Godot 4.7.2 Android 导出模板。环境检查无缺项。
- 从 M1-B1 当前代码导出调试包：`ambush_loop/build/android/AmbushLoop.apk`，35,761,650 字节，SHA-256 `1DBADCA5B063AEACF2A0E7295410FF238CF646435C15C30162F73B771F3DCAA9`；包名 `com.ambushloop.game`、versionName `0.6.29`、versionCode `78`、compile SDK 36；APK 签名验证通过。
- 目标设备为 vivo X Fold2（型号 V2266A / PD2266，Android 16，arm64）。用户已在手机确认 USB 调试授权；截至本补记，ADB transport 仍为 `offline`。一次保留数据更新安装未成功，禁用增量安装重试返回 `device offline`。未卸载应用、未清理应用数据，因此 Back 去重修复及 v0.6.29 尚未在该设备上验证。
- 结论：SDK/导出工具问题已解决；设备传输稳定性仍是 M0 真机复验的阻塞项。待 ADB 稳定显示 `device` 后，先核对已安装版本与签名，再以 `adb install -r --no-incremental` 更新并执行 Back、后台恢复和触控复验。若传输再次掉线即停止，不做卸载或清档。

### 2026-09-29 用户重新授权后的复查

- 用户确认已在 vivo X Fold2 允许 USB 调试；ADB 能列出设备 `10AD4L182J001DB`，但状态持续为 `authorizing`，未达到可安全安装状态。
- B2 分支另行导出 `AmbushLoop-m1-b2.apk`（0.6.29 / versionCode 78）；签名验证通过。尚未对手机安装该包，也未卸载应用或清理数据。
- 当前只需等设备握手成为 `device`；再执行保留数据更新和启动验证。如果手机还弹出 USB 调试确认，需在设备上确认一次；若无弹窗，不重复重启 ADB 或强装。

### 2026-09-29 连接修复补记

- Windows 同时识别 vivo X Fold2 和 ADB Interface，设备状态均为 OK；仅有一个官方 SDK ADB 服务进程。执行一次 reconnect 和一次服务重启后，手机恢复出现在列表但仍为 `authorizing`，因此未继续强装；已引导用户在手机重新开关 USB 调试以触发确认。安装、Back、后台恢复仍待验证，未卸载或清档。
- GPT 评审通路已恢复并实测完成 B2 代码评审：复用既有游戏连接，固定评审工作区切至精确提交 `340b819`，连接器身份和文件读取测试通过，原项目对话已返回实码复核结果。无需额外连接授权；不将此结果写作浏览器页面点击控制器已修复。旧报告中的 Edge 故障不是当前评审通路的阻塞项。详情见 B2 计划。

### 2026-09-29 再次允许后的 USB 实验与后续方案

- 用户再次确认允许后仍为 `authorizing`。ADB 37.0.1 的 server-status 显示 Windows 新 `LIBADBUSB` 后端；日志含重复的 USB read/write terminated。依据 [官方版本说明](https://developer.android.com/tools/releases/platform-tools)，仅在启动服务的进程环境设置 `ADB_USB_LEGACY=1`，切换后 server-status 为 `NATIVE`；未改机器级环境、未删除或替换授权密钥。
- 兼容模式稍后出现 `device`，`shell getprop ro.product.model` 成功返回 `V2266A`，说明不是始终未授权。但随后保留数据的 `install -r --no-incremental` 退出码 1（空错误详情），设备再次 `offline`。连接短暂恢复不等于稳定性修复，B2 安装未成功，启动/Back/后台测试未执行。
- 安装前包查询还出现 `Shell does not have permission to access user 666`；当前 Android 用户/应用安装状态尚未核实，不能据查询无结果推断未安装。后续连接稳定后先核实当前用户及对应应用状态，不切换用户、不绕过权限。
- 曾尝试仅重启 ADB Interface 的 PnP 设备，Windows 返回 Access denied，未实际重启；不反复提升权限或替换驱动。
- 下一步采用无线调试备选：用户在与电脑同一 Wi-Fi 下打开无线调试，再通过手机显示的配对页面授权。配对信息不入库；成功后先核实设备与用户，再执行保留数据更新、冷启动、Back/后台恢复并保存证据。若不可用，再检查数据线/直连 USB 口；不卸载游戏或清档。当前无线调试尚未开启/配对验证。
