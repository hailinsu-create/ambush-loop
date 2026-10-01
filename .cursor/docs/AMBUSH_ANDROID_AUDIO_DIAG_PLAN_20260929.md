# Android 真机音频崩溃诊断计划

日期：2026-09-29。状态：无线连接与 APK 安装已验证；音频崩溃已捕获，原因未确认，未修复。此计划优先于 B2 最终验收，不扩展玩法。

## 已验证的设备结果

- vivo X Fold2 / V2266A、Android 16。USB 仍不稳定；用户开启无线调试后，ADB 发现并连接同一设备，复用现有授权，无需额外配对码。无线通路完成安装、shell、截图，不能写作 USB 已修好。
- 查询当前 Android 用户为 `0`。显式 `install --user 0 -r --no-incremental` 返回 `Success`、退出码 0。此前不指定用户的查询出现 user 666 权限错误，不能推广查询范围；没有切换用户、卸载或清档。
- 安装包来自 B2 `340b819`，0.6.29 / versionCode 78，SHA-256 `F8CBE0C68A9DE53D2A9504D1AD47D1EAD8668929BE6048ED61019D923F2B7238`。安装后系统查询核实版本和更新时间。
- 通过 manifest 暴露的 `com.godot.game.GodotAppLauncher` 冷启动成功。直接启动内部 `GodotApp` 被系统拒绝，改用公开启动入口后正常；不能绕过组件权限。
- 真机标题可见；ADB 注入系统 Back 打开退出确认，取消后点击开始行动显示六夜任务列表及院子简报。一次 Home → 公开 Launcher 恢复显示 `HOT`、同 PID，随后截图恢复标题。仅覆盖短时标题恢复，不代表战斗/长时间后台或系统返回手势全部通过。
- 采用真实设备截图和 ADB 输入，不冒充真人首局或手指触控录像。保留 [标题](evidence/android-20260929/01-title.png)、[Back 确认](evidence/android-20260929/02-back.png)、[任务选择](evidence/android-20260929/03-missions.png)、[后台恢复标题](evidence/android-20260929/07-resume.png)。

## 崩溃证据与边界

首次运行接近点击接受院子任务后进程退出，系统 crash buffer 明确记录本应用：

```text
2026-09-29 22:43:23 +0800
Process uptime: 295s
Cmdline: com.ambushloop.game
thread: AudioTrack
signal 11 (SIGSEGV), code 1 (SEGV_MAPERR)
libgodot_android.so BuildId: 379cc52e73d31af89517a529d3bbc6108b808986
#00 pc 0x2f8f814 libgodot_android.so
#01 pc 0x34c1db4 libgodot_android.so
#02 pc 0x349d77c libgodot_android.so
#03 pc 0x349b7e4 libgodot_android.so
#04 pc 0x12f7b1c libgodot_android.so
#05 android::AudioTrackCallback::onMoreData
#06 android::AudioTrack::processAudioBuffer
```

以上为系统输出的去路径摘要，不含设备网络地址、授权信息或其他应用日志。音频线程是确定事实；具体 PCM 越界、stream 生命周期或驱动错误均未证明。重启后的再次进程退出未取得第二份对应 tombstone，不能称为两次同栈稳定复现。仍不能宣布院子进入或 B2 真机玩法通过。

## 外部 GPT 诊断输入

原游戏项目对话已通过现有连接器读取精确 `340b819`，诊断回复 ID `721f0067-f355-444b-83b7-02bb0d3d42fd`。此前 B2 移动逻辑的“无新代码阻断项”仅适用于其评审范围，不覆盖这个新真机崩溃。

- 静态读取：两个 looping WAV 是 mono/16-bit/22050 Hz，`data.size=n*2`、`loop_begin=0`、`loop_end=n`，没有明显单位混淆；不能无证据改 loop_end。
- mood 实际 pitch 固定为 1.0，不能把未使用的 mission_mood_pitch() 当动态调速原因。
- 待验证假设：长期循环与 Android audio backend、任务切换的 mood stop/replace/play、前后台 stop/resume。SFX pool 同样需在证据支持时排除。

## 下一切片：先复现、后修复

1. 不改生产逻辑，记录单次冷启动的事件时间线与仅本应用的音频/崩溃日志；必要时符号化顶部 Godot native frames。
2. 分开验证标题静置 6–10 分钟、进入院子后静置、重复任务切换、重复后台恢复，记录各自触发点，不在一轮同时更改多个变量。
3. 根据复现才增加临时诊断记录：实际 PCM 格式/字节数/loop 范围、旧新 stream instance、stop/play 和 focus 时间。每次仅隔离 master bed、mood 或 stream replacement 中的一项；诊断构建与正式修复分开，不以全局静音冒充完成。
4. 根因有证据后提交最小修复，隔离自动门 + 同真机复现矩阵复验，外部 GPT 再读取精确修复提交评审。保留存档、不卸载、不修改授权安全设置。

退出门：原崩溃步骤不再复现，带音频的标题/院子长时运行及前后台恢复正常；再完成 B2 下坡随队和视觉证据。陌生人首局、真实触摸录像和完整 M0/M1 验收仍是独立待办。
