# PR15 HUD子诊断与条件最小候选（提案，未实施/未运行）

2026-10-05 更新：本提案的诊断已由[HUD子诊断END](AMBUSH_PR15_HUD_SUBSEGMENTS_END_20261005.md)完成。实测8次capture/2次touch/50次style，选择仅REPLAY省相邻第二次touch refresh；历史frame复用未实施，候选以新END中的冻结合同为准。下文保留启动前提案，不代表候选实际结果。

2026-10-05，[有限测量END](AMBUSH_PR15_REPLAY_HUD_SEGMENTS_END_20261005.md)已知：两个ON的HUD占root累计90.12%/89.53%，而postdraw OFF/ON推进方向混合，净采样开销未稳定。**下一优先级是HUD内实际成本与方法修正；尚无具体子热点/稳定净性能收益，不直接提交优化。** 1ec source/tree1e8、原yard bin、paired consumer、资产/规则/同Sitev4保持。本文件不是已经实现的cache或性能提升。

## 下一有限诊断

自动连续驱动native Guard→一次QA export→P0→测量→END，避免原135.99秒P0含idle等待的调度失败；先明确P0起止/原120秒子cap与600秒总cap，原失败不能移出或改绿。唯一窗口确认归还后才另包启动，总cap从首engine算、实际所有idle亦计总量；不继承本轮剩余预算、不静默续跑。

仍同原6339/frame792/SCOUT，以及原40秒同phase区间。计时只加两条必要HUD子线：**replay_hud_frame/ViewState.capture实际调用count+inclusive sum**、**_refresh_touch_hud inclusive及其实际_apply_btn_style count/elapsed**；HUD root和presenter/wall保留以识别嵌套。源中main title/role cards、c2 minimap/portraits、touch HUD可能重复读取历史帧，是源码假设，不是本轮实测callcount或原因。禁止先展开全部HUD树，paint/list/资源/规则不变。

共同采样、原buffer、首样本/warm、固定clock粒度和OFF非零成本明确；尽量将采样区间选为同一source frame/固定自然回放区域，报告每轮实际tick范围和差异。四串行OFF→ON→ON→OFF，各static+advance warm2/collect20，≥12实际样本/窗口、2048行、run≤90、总≤600，没测足或仪器/ON OFF方向不能识别则UNMEASURED或方法受限。记录相邻pair与OFF/ON重复漂移；不得只挑有利配对或负值解释“采样加速”，不能wall减inclusive给GPU。采样窗禁止RPC/截图/output，后flush/END。P0 paused root0与presenter/capture正控制、ON→OFF reset、中性/实际Guard先过；无runtime正计数则不进行候选。

## 条件单候选：一次HUD刷新内复用历史frame

仅当子测量确认HUD里重复ViewState.capture次数和稳定区间贡献，才考虑**一个_update_hud调用内共享同一不可变历史frame**，不跨刷新/seek/attempt/来源/phase缓存；replay_hud_frame在该明确scope外仍原capture。所有格式/UI/触控/样式更新仍执行，调用次序/字体通知/信号/隐藏状态保持。scope必须处理重入、异常退出/未来早return、来源或scrub_tick变化，不能将旧source frame挂到新来源；不要做永久tick缓存或跳HUD。具体实现待诊断后冻结，当前没有该补丁，也没有预测提升百分比。

若capture不是主贡献，不实现这一候选；若touch/style有成本，单独提最小样式候选及外来override/独立StyleBox合同，而不同时优化两条线。历史20261004 native样式热点/合批收益另有原证据，不自动等于当前Web结果。

## 实施前冻结回归方案

候选A/B都来自同精确source、同official engine/import/QA fixture、只声明一个runtime diff；全部资源/manifest/GLB/Blender/atlas不变。先负向确认被省的重复capture及scope边界，再candidate。父端QA窗口和资产单写者所有权保持。

- A/B同6339 static RGBA逐像素、完整历史HUD字串/可见/disabled/style状态、完整immutable source frame与20骨/socket/装备相同；推进实际tick差异单列，选相同原tick的canonical只作像素合同，不能称whole。
- 同原record/domain/fullcfg/checkpoint在Replay/P/seek/事件聚焦/返回WON前后相同；attempt/source switch、同tick异来源、同source seek倒退/波切换、暂停/后台/Back/触控取消、旧schema1与缺字段中性/unsupported保留，确保scope结束后继续原getter与无历史泄漏。测试检查最终可见结果/真实帧与历史字节，不镜像实现。
- 同源核心历史合同/装备冻结/生命周期与实际旧记录读者做对应已有必要门，不把静态fixtures标成自然六关13波。像素或行为不同即停止候选，保留失败；不以cache值相同代替source immutable/装备/存储回归。
- 性能另有有限A/B ABBA、明确输入/callback/tick范围、共同无新增profiling模式、漂移/不利pair/tail/内存/原budget miss全保留；稳定多个pair才能说局部收益，仍不代表SwiftShader/设备或30/60FPS目标过。方向混合不扩无限反向块。

本轮引擎窗口已END且归还；以上全部未运行。若未来候选验收通过，再按实质修复授权决定同Site必要更新；当前不再deploy，server archive身份unknown、最终同候选13波与听感不随候选自动通过。
