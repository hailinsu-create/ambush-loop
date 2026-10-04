# PR15 A2 保存移动姿态尘 cue

2026-10-04，接blast/smoke固定a9/f2已验有界切片。新片尚未实现；先实际原移动正向与缺接口负向，再生产/固定源H/R。

增加独立movement_fx_schema1，VisualSnapshot只声明本次捕获支持移动cue；现存原ops/enemies moving/alive/active/position/facing/stance/sprinting/action及pose_clock仍是唯一事实。ViewState另外复制未经actor defaults强转的原字段、绑定source token、保存pose clock/domain与playback2结构门；缺schema/未知/旧raw中性，不拿当前角色位置补历史。仅ops/enemies，原sentries未存moving则不猜测。

纯reader严格版本/typed身份/已知level/attempt/wave/finite非负clock/合法command与simulation domain，actor typed moving/alive/active、实际walking action、ops stance/sprint/ID和enemy ID、finite位置/朝向；重复actor identity中性，有限原列表。cue由保存clock与actor ID确定性周期、当前保存ground position派生，明示非原脚掌落地事件、非持久旧位置尾迹，不新增BattleLog event或footstep音频，不改变路径/HP/库存/原统计。

固定24actor槽、每槽2低面数共享mesh、省电最多6actor每槽1，关闭阴影，有限材质/节点，finite派生先于RenderServer写入；步行/冲刺/蹲行尺寸与opacity由保存事实决定。保存姿态停止/死亡/隐藏、未知格式、source/wave/phase切换/abort/Title撤场；pause/seek完全由保存clock重建，无wall clock/粒子模拟/缓存增长。不给没有原moving字段的旧record回填尘。

先正向原SCOUT command_move/_process及原位置/path实际变化，planned schema/presenter两缺口负向保原HP/库存/log。再原SCOUT与reference自然清波SWEEP合法移动、ALERT敌人原sim_step、原ALERT pause/background/REPLAY pause/seek/foreign source、不 moving/haul/search/death中性、typed/corrupt/version/overflow/重复/cap/省电/资源释放。真实Window off/on/off原cue ROI与多yaw代表性样本，保存hash/全部目检，记录actual exits/E/S。显式摆位/授reference/直tick/clock复制与正常13波分开，后者只在FINAL同source接受。

制作接口沿用R5的20骨/socket/3LOD/52语义；本cue不需要改骨/GLB/atlas/Blender/ArtSource/production manifest。主作者拥有VisualSnapshot/ViewState/presenter/纯reader/pool/共享测试。只读A3并行包只返回现存指标接口与采集提案，不启动engine或冒称实际性能；本片后A3 raw量测→必要单片优化→FINAL/fullsmoke/newnormal13/六新原件full1×2×→APK，耳听与设备最后。

2026-10-04执行状态：生产00→3aa raw门→f9 malformed moving门，正式71 H35/132/130与Window184各0 actual0 E0/S0，21图全部hash/实际查看；原planned7/2、rawphase3/1、11135带S1和132/2错误foreignlog假设保全。详情见[实际报告](AMBUSH_PR15_MOVEMENT_DUST_20261004.md)。本片非normal13/全autoplay/A3；下一[A3实际采集](AMBUSH_PR15_A3_COLLECTION_PLAN_20261004.md)，制作与设备后置边界保持。
