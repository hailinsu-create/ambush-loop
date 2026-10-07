# PR15 A2 保存爆炸 reader / 有界烟池

2026-10-04，来源片生产d75、正式源/参考640、边界测试继续校正正向control。本计划尚未实现或验收，不把 source描述/节点存在当实际 render。

纯 ToolFxFrame 只读取 ViewState 的 tool_fx_schema1/playback2 与 opaque bound-source token。严格 TYPE_INT/BOOL/String、已知level与saved wave_count、attempt-wave-effect/tool canonical identity、created wave/clock不晚于confirmation、实际phase0/1/5、finite radius/position/local_tick、victim group+真实typed ID/HP前后/实际非负差，以及 mine 的 explicit canonical原事件引用与 saved events exact identity。grenade original_event空；不把 mine victim actor当owner、不读取 live actors/tools/selected、不伪造旧来源。descriptor列表最多48、受害最多有限上限；每项坏值中性，重复身份不重复呈现，派生world transform/basis/size还须finite。

blast/smoke pool拟8工具槽、省电2，固定低面数shared meshes、关闭阴影、纯 deterministic seq种子。每槽有限flash/ground pressure cue/烟团，不生成sim collision或新玩法。确认前中性；实际失败wipe终端仍可从已完成源展示，abort立即取消；终局/暂停冻结按保存时钟而非wall-delta。跨wave/source/attempt/replay/重置/Title明确撤场；seek back重建同一可见几何，不增长节点、资源或缓存。

火光/压力环仅短时。烟由确认爆炸位置/半径/seq/age派生，显式非烟雾工具、非原particle轨迹。取消遵守source跨wave契约；不宣称跨波烟延续。透明材质固定有限资源，颜色/opacity以saved age驱动，无时间随机种子，云渲染成本进入A3而非提前宣称设备性能。

先planned pool缺口实际负向，再严格reader坏字段/control H，原实际 grenade/mine +空爆/cover/wipe/saved REPLAY/真实foreign log/旧七raw只读及派生finite/满池/省电/释放回归。固定source H/R/actual exits E/S，真实原Window像素ROI和目检，camera多yaw/pitch/zoom/遮挡中有代表性样本。样本通过仍不是最新13波normal/艺术总接受或全部设备FPS。

移动尘独立后一片：保存moving/stance/sprint与pose时钟确定性采样，标注表现型脚步cue，非原落脚事件。不借当前活体冒称历史足迹。持久尾迹需额外真实脉冲来源，当前不虚构。完成后A3同环境实际raw指标→必要优化→FINAL同source全门/newnormal13/六新records完整1×2×/fullsmoke→fullgame可追溯APK。R5制作源/ArtSource/GLB/atlas/Blender/production manifest所有权不变，无merge/生产/height/G/设备启动。独立b563/53 QA与本片分开。

2026-10-04执行状态：严格reader/8槽省电2的blast/smoke已实现固定a9；H255/3、Window268/f2像素75各0 actual0 E0/S0，43原图全hash/实际看。半径及同mine原event重复引用实际负向后修复，测试parser/Title错误和三次异常退出保全。细节与scope见[实际报告](AMBUSH_PR15_TOOL_FX_POOL_20261004.md)，不把该专项称正常13波、全pitch/zoom、全回放或A3。移动尘未实现，随后独立纯保存pose片→A3→FINAL同source/完整smoke/new13/full1×2×→APK；制作资产接口不变。
