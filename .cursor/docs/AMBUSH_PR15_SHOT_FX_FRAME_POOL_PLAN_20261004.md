# PR15 FX-A1b 保存枪口与有限表现池

2026-10-04，承接A1a正式183/source e0的成功descriptor及P2固定f0e/证据e379。A1a只增加payload.fx schema1，不冒称既有3D枪火已实现。主集成唯一写者负责下列新presentation模块、ViewState/presenter和共享Guard测试；制作源/GLB/atlas/生产manifest不改、不重跑。

首个有界包A1b.1：纯ShotFxFrame读取明确frame接口及原成功descriptor。新frame opt-in schema1 / 独立fx playback schema2 / 原log实例source token只用于缓存失效，不改事实event_id。只认原event schema2/continuous2、frame保存attempt/wave/level、descriptor schema1/confirmed、原source-target groups/id/finite保存位置、原R5 revision/animation3/gun/pose、actual HP差。未知/缺失/旧schema1/旧a05无fx都中性，不借当前actor/gun/target补旧记录。生命周期仅frame.playback_tick减原event.playback_tick：flash3tick、tracer6tick、impact9tick，录制phase只在ALERT显示，SCOUT/SWEEP/终局立即清；暂停保持同tick，不用wall tween或pose clock。先Guard接口负例→实现→真实后端来源/严格坏版本/边界/只读H。

第二包A1b.2：ShotFxPool固定12个slots，每slot三个低面几何，省电既有GameSettings tier限定4slots且禁tracer。一个独立hidden ActorVisual读原saved model/gun/pose采样R5 item_socket("muzzle")，不从post-repack/pistol/current body取枪口；LOD0/1/2实际socket比较后再定缓存。最多48个最近原event枪口采样缓存，键包含原log实例source token、原事件身份及完整descriptor hash；同identity新source也不能复用旧枪口。source/phase/attempt/wave/旧neutral/seek重建可见列表，重复seek不得重复spawn，池不长大；所有mesh关闭shadow，资源驻留与shader/池峰值留A3。

tracer到descriptor保存二维target位置映射的展示躯干高度；impact仅actual damage>0，是原后端命中cue，不伪称3D几何碰撞/弹道玩法。刀不显示枪火。满池保留最新已知事件，省电按既有设置降级，未知/失效socket关闭该事件，不能随便从当前Actor替代。

共享隔离测试明确实际后端fixtures（授枪/位置/HP/直接API）与consumer/history复制：末弹pack/pistol仍取旧枪、敌人return实际伤害、false/no-context拒绝、ALERT暂停、原REPLAY1x/2x/pause/负向/重复seek、跨wave/source（含同身份不同source/descriptor）、缺unknown/原schema1真实原bytes/old a05新原件缺fx中性、reset/leave/abort/focus、标准/省电满池/稳态资源、三LOD muzzle。保存source/live/sim/ammo/HP/原bytes不变，真实3D原Window PNG/数值采样，覆盖shot实际帧而非只样本。新FX六关source/reference与最终native新13波/newrecord另阶段；单包结果不能拼FINAL。

P2独立QA可先只读f0ed44311775fa87ee63ebb911c7b11e12e65ab1；APK工具链只读包已交6.1-sol独立盘点，报告仅/tmp，未装SDK/导出/设备测试。A1b完成后A2工具/爆炸/烟/脚尘→A3实际指标/优化→FINAL同source全门/fullsmoke/正常13波/新六record→可追溯APK。网页GPT PLAN/REVIEW unavailable，Draft不merge/发布/height/G，设备耳听按原用户顺序后置。

可选pose布尔字段接续：固定56207c5保留实际负向H100/7、actual1、E0/S0；已知FX1/R5 pose缺字段默认true及合法true/false原20骨骼采样通过。原reader接受字符串、整数、null、字典、数组共7错误类型。最小修复只在ShotFxFrame._valid_pose有字段时要求TYPE_BOOL，不改ActorVisual、原事件、旧schema或缺字段默认值；固定修复源码后同命令正式复验。c9c开发静态bool(String)解析失败actual1/E1/S1亦保留，不称生产复现。资产所有权不变。

A1b.2实施切片：Guard固定544接口负向H1/1 actual1 E0/S0，仅planned module未存在；随后固定12槽/36mesh、三shared低面mesh/material、48纯值cache、隐藏单R5 sampler与presenter接入。固定采样LOD0以原记录资产/pose定义枪口，LOD012实际测量另列，不随观察镜头LOD改变事实枪口。hash只预筛且完整descriptor相等才复用；所有原set_asset/mount_item/sample_layers成功且身份/muzzle finite才显示。phase/source/unsupported清cache及采样model，纯到期隐藏并可seek原样恢复；pool随原场景释放。共享测试明确原后端授枪/HP/位置/API和synthetic容量/时钟/缺marker，不称正常战场或A3。正式渲染前冻结fixed source；原schema1与a05六raw精确hash只读，不改写。

只读c517审计后真实cd6负向H224/3 actual1 E1/S0：finite Vector2(1e38,-1e38)派生长度inf，旧pool写非finite tracer触发RenderingServer错误，现最小finite派生geometry门关闭整条坏事件。另两失败为测试foreign fixture未先detach已完成BattleLog，原_reset会清同一对象导致原saved被fixture改写；修fixture先给current新BattleLog，不改生产reset/回放逻辑。原所有失败保存，正式fixed H/R下一轮。实际c517 H218/0 actual0 E0/S0与LOD012差0是先前开发receipt，未代后续fixed R/FINAL。
