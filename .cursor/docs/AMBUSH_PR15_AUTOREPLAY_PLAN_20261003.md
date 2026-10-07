# PR15 autoREPLAY2× 独立小片

父端本轮仅授权autoREPLAY2×与原clock/seek/pause/record绑定；FX/A3另片。title固定226、证据d7b已原remote/原credential唯一正常push重试成功，GitHub只读HEAD核对d7b；不是永久凭据健康声明。title作者2391/0+keyboard7/0，独立QA待。

现状已读实际源：ReplayPlayer.playing未驱动时间，bind保留旧terminal默认scrub位置，main._process(REPLAY)直接return；标题同步前的controlled2×fixture不是自动播放功能。

契约：生产复盘按钮进入时从记录起点自动2×播放；只增加独立历史播放时钟，不使用或推进SimClock、不重算战斗。保留直接bind的旧terminal选择语义；可暂停/继续、1×/2×，P键、+/-，空格原返回语义保持。slider/左右键/事件seek定位后暂停并清除旧fraction，防seek后旧时间债；抵达真实记录末端停止，保留末帧/REPLAY并支持重播，不自动新战斗/下一关。菜单冻结播放且关菜单恢复原播放状态；focus失去暂停，返回后由玩家继续，无后台累计。

桌面复用原pause/speed信号，compact HUD在现时间轴行加入两按钮并走原apply_touch_command，保持ALERT原pause/speed/abort与全部模拟数值。记录/旧schema1/缺失未知格式仍只读，replay绑定源独立于当前battle_log/live。

先提交本片test-only负向，在原生产源上实际验证缺口并保存log/exit；再改ReplayPlayer/main/必要touch HUD。单位/受控时钟覆盖30/60与低帧、1×/2×/fraction/暂停/seek/末端/重新bind及旧/歧义记录。正式native必须main自动process、普通按钮进入、真实帧delta驱动；实际SCOUT→两波ALERT/SWEEP→WON记录为原reference部署/合法move fixture，不称正常玩家旅程，原1283/34与波末1056/227保持。

本片正式验证仅新测试headless+render，以及相关timeline/装备锁/生命周期回归；不重跑有效formal29或完整title8组。1280/100 desktop和1600/200 compact实际native pause/speed/slider/左右键/事件/菜单/focus/末端/返回，留存identity/clock/PNGhash，实际看关键帧。固定源码后运行，完成实际退出收据才交付；原资产制作源/GLB/atlas/manifest不动。独立QA由父端固定可读SHA安排。最终smoke/APK/设备、FX/A3后续；网页GPT PLAN/REVIEW unavailable。

实施补充：固定12a native入口负向27/2、exit1/ERROR0，terminal Overlay隐藏原BottomBar，因此把同一个ReplayButton放原终局footer，进复盘/重新setup回原parent，信号不变；相关result viewport需要追加回归。两轮pointer诊断发现新测试遗漏Window.position=0，与已有原生helper约定不符；另旧private X11 base表arrow100/102不符Godot physical evdev映射，改仅自有:112为evdev、left113/right114。均保留失败收据，不能称生产缺口复现。生产GUI前置shortcut方案已撤回；native全局左右6tick/Space原路由以明确释放GUI焦点fixture验证，HSlider自身GUI键盘行为仍原样。软件渲染末端wait预算120s不作为FPS门槛，采集实际Node delta与对应历史tick。autoREPLAY安全边界后父端最新要求先修title两P2，参见TITLE_FOCUS_PLAN。
