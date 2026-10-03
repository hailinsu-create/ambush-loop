# PR15 同候选完整记录正式关

父端要求67f521 credits交独立QA后，只完成47+credits同候选正式六关、完整SCOUT→ALERT→SWEEP连续recordreplay、图形、失败/abort、identityseek/cancel与旧schema兼容，随后交固定片再续FX/A3；不扩UI、不动制作资产。

审计发现67f521只采SWEEP，首次ALERT begin_attempt清掉SCOUT。先固定原候选现有command及六关基线，新增实际SCOUT移动/暂停后台/首次报警身份与未采样边界反例，再补生产。新playback schema2记录SCOUT初帧、约0.1秒真实采样、报警前最后状态，并以一个明确presentation边界tick区分SCOUT末帧和ALERT首帧；原BattleLog schema2/battle tick/event seq/terminal统计不变。attempt在SCOUT开始后保存，报警只重置原battle域，不清新连续流/身份。schema1连续SWEEP、schema0旧battle及unknown/malformed保持保守兼容，不升级旧记录。

正式验证必须固定实际源SHA；完整六关13波的原reference、30/60 FPS、2x/camera对照及正常WON/FAILED/abort统计，SCOUT/SWEEP移动历史同点骨/root/copy、跨波identity、事件seek、取消生命周期和旧schema/fallback。图形用隔离私有X11与实际云GPU软件渲染；保存所有命令/UUID/exit/引擎错误/源与PNG摘要，实际看关键图。reference/vacuum辅助与合成Input.parse事件不称正常玩家全旅程/实体触控，Mesa不证明安卓性能。

主集成独占runtime/main/presenter/ViewState/replay/loader/共享测试；制作脚本/GLB/atlas/Blender/manifest仍资产作者，源asset不修改不重跑。SCOUT→ALERT→SWEEP及数值/Nav/LOS/拾取/14px follow/瞬时抓放/sharedhaul保持，Draft不merge/生产、高度/G隔离。耳听0/45cue、0/6声景及设备后置。GPT PLAN/REVIEW unavailable。
