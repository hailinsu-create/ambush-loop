# V1 真机复验：连接中断，未验收

用户连接手机并要求复验。设备初始ADB authorized：HONOR AAP-AN00；安装包 com.ambushloop.game，0.6.29/code78。版本号不用于判断精确源码。

源7a6250fcfe3fb3676aa73bc4da438123da9d1808（生产表现465e993、导出08d9fb3）。Godot4.7.2 Android debug export退出0，新APK本地 `ambush_loop/build/android/AmbushLoop-v1-7a6250f.apk`，SHA256=9520EAA370BECDDAFBAA75B268E45DD0A8900BE5862828054B1BAC6AD06816F8。apksigner verify退出0，证书SHA256=50365cc4281a221a673f9b4656bee84d325e3ae89d46aa0b624efad644bfa58d，与此前设备包证书一致。APK仍为0.6.29/code78，精确包通过文件哈希区分。

普通pm path查询持续无响应；安装 `install -r --no-streaming` 在45秒有界等待后仍未返回，stdout/stderr为空，未取得Success或安装完成退出码。仅取消自己发起的两个挂起ADB客户端，不卸载、不清档、不启动重复安装。执行adb reconnect后设备列表为空，实际新版安装状态未知。已提示用户保持解锁并确认手机安装/USB调试提示。

后续必须先恢复通信，读取设备包路径并拉取APK核对哈希，不能盲目重装；如仍为旧包再原位安装新包。之后冷启、实际2D→3D、新材质/仓库/灯光、收展卡片/触控/搜索/交战/复盘与标准低档长稳分别留证。本轮尚未运行新版启动或3D流程，任何桌面绿灯都不能替代真机通过。
