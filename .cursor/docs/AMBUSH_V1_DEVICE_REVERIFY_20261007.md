# V1 真机复验：连接中断，未验收

## 用户重插后的实际续测

### 再试长时间卡顿测试

用户要求再次进行长期采样。devices起初仍显示authorized transport7，但只读pidof在10秒限时内未响应，取消的是本轮电脑端查询客户端。无安装/测试进程待结束后重启ADB server，设备变为 `(no serial number) offline transport1`；再次devices仍offline，mdns services无已发现无线调试端点。没有执行新游戏输入、重装、卸载、清档或修改手机设置。由于无法读进程/帧时间/内存/温度，长稳采样尚未开始，不能登记通过或据通信离线认定游戏卡顿/崩溃。需用户重新建立USB授权或无线调试连接后继续代表性标准/低档运行采样。

重插后authorized transport6恢复，pm path退出0；设备base.apk SHA256=796579006b192860f4e1cdb170a243d5bc5f35c69dbb3e8b4256c513cde09f3f，确认上次仍为旧f8ad51c包，才开始单次原位更新。新版 `install -r --no-streaming` 实际Success、INSTALL_EXIT0（31,305,849字节）。没有卸载、清档。

初次直接启动非exported GodotApp被系统拒绝，随后通过cmd package resolve-activity取得正确GodotAppLauncher，实际启动成功，PID29188。普通游戏UI：标题→开始行动→选择院子→接受任务→2D准备→查看3D院子→展开战术，截图逐步确认。新版冷色地面/砖墙、仓库卷帘/檐口、补给暖灯及compact卡片均实际可见；接受任务此次未退出。不注入关卡、资源或胜利状态。

发现手机布局红灯：展开卡片延伸至屏幕底部，覆盖主按钮/转向区；与桌面960/1280门的布局不同，不关闭手机UI尺寸/误触门。后续修复应让卡片按内容收敛高度并留出底部HUD，而不能把桌面48逻辑px当48Android dp。

3D展开态一次meminfo：TOTAL PSS466739KB、RSS623972KB；单点不证明内存稳定或泄漏。截图2800×1272。点击标准画质尝试切低档及随后收起的顺序命令卡在第一条ADB input；设备重新枚举为transport7，取消本轮电脑端序列，未确认两次操作送达。新PID只读查询同样设10秒限时，若超时取消客户端，不触及手机应用。

实际截图仅本地 `ambush_loop/build/android/v1-phone-title.png`、`v1-phone-mission.png`、`v1-phone-brief.png`、`v1-phone-yard.png`、`v1-phone-3d.png`、`v1-phone-expanded.png`。有限Godot-tag日志未返回可用运行正文，不以空日志登记无崩溃。未完成：收起/标准低档切换、补给/交战/复盘新包闭环、代表性长时间帧时/热态/内存趋势、真人手指误触。安装/启动/进入3D与展开具备证据；整轮真机复验仍不通过。

下文为重插前历史，安装状态未知已由本节Success替代。

用户连接手机并要求复验。设备初始ADB authorized：HONOR AAP-AN00；安装包 com.ambushloop.game，0.6.29/code78。版本号不用于判断精确源码。

源7a6250fcfe3fb3676aa73bc4da438123da9d1808（生产表现465e993、导出08d9fb3）。Godot4.7.2 Android debug export退出0，新APK本地 `ambush_loop/build/android/AmbushLoop-v1-7a6250f.apk`，SHA256=9520EAA370BECDDAFBAA75B268E45DD0A8900BE5862828054B1BAC6AD06816F8。apksigner verify退出0，证书SHA256=50365cc4281a221a673f9b4656bee84d325e3ae89d46aa0b624efad644bfa58d，与此前设备包证书一致。APK仍为0.6.29/code78，精确包通过文件哈希区分。

普通pm path查询持续无响应；安装 `install -r --no-streaming` 在45秒有界等待后仍未返回，stdout/stderr为空，未取得Success或安装完成退出码。仅取消自己发起的两个挂起ADB客户端，不卸载、不清档、不启动重复安装。执行adb reconnect后设备列表为空，实际新版安装状态未知。已提示用户保持解锁并确认手机安装/USB调试提示。

后续必须先恢复通信，读取设备包路径并拉取APK核对哈希，不能盲目重装；如仍为旧包再原位安装新包。之后冷启、实际2D→3D、新材质/仓库/灯光、收展卡片/触控/搜索/交战/复盘与标准低档长稳分别留证。本轮尚未运行新版启动或3D流程，任何桌面绿灯都不能替代真机通过。
