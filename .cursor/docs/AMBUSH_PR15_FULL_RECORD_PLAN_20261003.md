# PR15 同候选完整记录正式关

父端要求67f521 credits交独立QA后，只完成47+credits同候选正式六关、完整SCOUT→ALERT→SWEEP连续recordreplay、图形、失败/abort、identityseek/cancel与旧schema兼容，随后交固定片再续FX/A3；不扩UI、不动制作资产。

审计发现67f521只采SWEEP，首次ALERT begin_attempt清掉SCOUT。先固定原候选现有command及六关基线，新增实际SCOUT移动/暂停后台/首次报警身份与未采样边界反例，再补生产。新playback schema2记录SCOUT初帧、约0.1秒真实采样、报警前最后状态，并以一个明确presentation边界tick区分SCOUT末帧和ALERT首帧；原BattleLog schema2/battle tick/event seq/terminal统计不变。attempt在SCOUT开始后保存，报警只重置原battle域，不清新连续流/身份。schema1连续SWEEP、schema0旧battle及unknown/malformed保持保守兼容，不升级旧记录。

正式验证必须固定实际源SHA；完整六关13波的原reference、30/60 FPS、2x/camera对照及正常WON/FAILED/abort统计，SCOUT/SWEEP移动历史同点骨/root/copy、跨波identity、事件seek、取消生命周期和旧schema/fallback。图形用隔离私有X11与实际云GPU软件渲染；保存所有命令/UUID/exit/引擎错误/源与PNG摘要，实际看关键图。reference/vacuum辅助与合成Input.parse事件不称正常玩家全旅程/实体触控，Mesa不证明安卓性能。

主集成独占runtime/main/presenter/ViewState/replay/loader/共享测试；制作脚本/GLB/atlas/Blender/manifest仍资产作者，源asset不修改不重跑。SCOUT→ALERT→SWEEP及数值/Nav/LOS/拾取/14px follow/瞬时抓放/sharedhaul保持，Draft不merge/生产、高度/G隔离。耳听0/45cue、0/6声景及设备后置。GPT PLAN/REVIEW unavailable。


2026-10-03 同候选正式关作者完成：[完整报告](AMBUSH_PR15_FULL_RECORD_20261003.md)。固定15c0783059bb7c2f9e9cd9b7252a9343e71f4168，runtime d860056f2107836c08dfb375a034ebbe694baff6；29次全部实际exit0/ERROR0、75图核hash。SCOUT身份/真实采样保至报警、schema2播放+原domain不变，旧schema1实际874 fixture兼容。六关39reference波/mode、原terminal/events与30/60/2x camera对照保持；不是正常完整玩家旅程/完整3DFX/设备性能。23项checkpoint后只收session5976既有6项，不重跑有效项。失败/旧候选保全，fixture精确hash与历史源重建已写，无LibraryID/不绕过。父端fixed15c独立QA待；继承title200全菜单/Help返回/退出确认/键盘下一独立片，然后FX/A3。R5制作所有权、SCOUT→ALERT→SWEEP、Draft不merge/生产、height/G隔离保持。
