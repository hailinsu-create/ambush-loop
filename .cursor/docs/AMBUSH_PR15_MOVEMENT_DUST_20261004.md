# PR15 A2 保存移动姿态尘 cue

2026-10-04。生产链00c6新增接口/池、3aa补raw envelope门、f9补malformed moving默认值门；生产最终 `f9cf844e327f53fc0e1a06daa55d90a5efbb6bbf`，正式测试候选 `71cfc20a877c9cbbfc272d15aa05c82f6f7090f7`。实际完整SHA以manifest/blob equality为准，五个生产文件在f9与71字节一致。本片完成作者有界移动cue验证；不是完整正常战场、A3或设备接受。

VisualSnapshot新增独立movement_fx_schema1；原moving/alive/active/position/facing/stance/sprinting/action/pose clock是唯一事实。ViewState复制defaults强转前的九个原actor字段与group，保存绑定source token、typed原版本/phase/wave/attempt/clock/domain门；旧/未知格式不借current actors、不升级原bytes。严格reader只支持ops/enemies实际walking action；sentries缺原moving字段则不猜。死亡/隐藏/停止/haul/search/fire、终局、坏typed字段及重复identity中性，原列表上限64。

24actor槽、每槽2个有限低面数puff，省电6actor每槽1；固定48节点/1共享mesh/24透明材质、关闭阴影。保存clock+actor ID驱动确定性近脚位置/大小，步行/冲刺/蹲行对应保存事实；派生几何及length_squared有限门在写节点前执行。cue位于当前保存actor位置附近，不是原脚掌落地事件、持久历史尾迹或新音频/碰撞/伤害。没有TIME、wall-delta、随机粒子或增长缓存；暂停/seek重建同样几何。

| 固定source / suite | checks/failures | actual exit | ERROR/SCRIPT ERROR | 范围 |
| --- | --- | --- | --- | --- |
| 582 planned interface H | 7/2 | 1 | 0/0 | 原SCOUT真实移动/HP/库存/events通过，两缺接口原负 |
| 00 initial production H | 8/0 | 0 | 0/0 | 首次原移动控制，不代完整验收 |
| 7cdf saved raw phase H | 3/1 | 1 | 0/0 | 合法one-frame control通过；坏phase0.0被强转接收 |
| 3aa same raw phase H | 3/0 | 0 | 0/0 | 同源最小反例修复 |
| 3aa original movement H | 8/0 | 0 | 0/0 | 原合法控制仍通过 |
| 111 expanded raw source H | 35/0 | 0 | 0/1 | 不算green：raw moving字符串触发旧bool(String)错误 |
| 111 expanded pool H | 132/2 | 1 | 0/0 | 错误fixture假定原setup会创建独立log；保全 |
| 71 complete raw source H | 35/0 | 0 | 0/0 | 原envelope/actor控制完整通过 |
| 71 complete reader/pool H | 132/0 | 0 | 0/0 | 原实际phase/API与明确corrupt/capacity/旧raw夹具 |
| 71 shared visual seam H | 130/0 | 0 | 0/0 | 原历史画面/合法bool与旧默认行为回归 |
| 71 actual Window R | 184/0 | 0 | 0/0 | 同完整专项及21原Window off/on/off PNG |

35项含合法历史正向控制及raw data.phase/wave_count/level/animation/revision/domain/clock、snapshot schema/playback/wave/attempt/frame_seq、actor moving异常字段；复制与原backend均byte-identical。只读00审计提出raw phase缺口后作者实际复现3/1并修复；正常writer/UI产生这些坏字段未证明。扩矩阵中的moving字符串先引出旧_actor_defaults bool(String) SCRIPT ERROR，f9仅将原moving按TYPE_BOOL保留、其他类型false；合法boolean和缺字段默认false不变。11135/0带S1不被接受，没有将E0/exit0当套件通过。

111 pool失败来自测试：_start_setup()原本复用并清空BattleLog，保留同对象跨load不能称冻结旧历史。71测试在原load warehouse前显式分配独立foreign log，再用原新关卡command实际移动；绑定先前真实record只读。该修正不改变main，不宣称正常UI会保留重置前对象。本片只改表现/保存格式，原main路径/伤害/库存/事件统计没有改写。

原SCOUT command接受路径，从真实初始位置经20个原_process步保存walk；随后原set_sprint/toggle_crouch到run/crouch_walk。132项含typed raw reader矩阵、版本/clock/-1/NaN/type坏值、停/死/隐藏/动作互斥、重复身份、无关tick/default clock不替代专属保存clock；100次同源更新仍48节点。64个明确复制enemy样本选稳定1..24，逆序不改，省电6×1；65项列表中性。finite原位置1e38与clock1e308的派生overflow在节点写入前拒绝。不是自然最大单位数量或吞吐测量。

原reference布阵/kit后实际_sim_tick获得ALERT活敌walking，原pause及后台30次更新保持clock/几何/log/HP/库存；原第一wave自然进入SWEEP，合法scout移动24步保持battle tick冻结。原REPLAY入口绑定真实playback2记录，在保存SWEEP moving tick暂停30次、seek0/restore/0/restore可复现。显式独立foreign source与真实warehouse活体移动不能污染绑定旧source。七authentic旧raw首末中性、内存及文件hash不升级。原abort中性，原标题API释放pool及48节点。这里是reference/API行为证据，没有完整1×/2×autoplay或新正常13波。

Window为1280×720/scale1，官方Godot4.7.2、gl_compatibility/Mesa25.0.7/llvmpipe LLVM19.1.7、DummyAudio、独立Xorg121。原SCOUT实际walk在yaw0/35/125/215/305，sprint/crouch在yaw0；pitch55/view12，原tween等待30帧、HUD更新，源clock因显式关闭main自动_process固定。21个Window原crop全hash、全部实际逐图查看；近脚小棕色cue可见，非新增脚步动画。ROI半径20/颜色阈值0.025，on变化walk56/121/140/209/177、sprint194/crouch196，七个off/off全0。原position/path/HP/inventory/sim/record保持。不涵盖全部pitch/zoom/LOD/地表、长驻留、所有actor艺术品质；未进行native输入。

实际正式命令（wrapper提供fresh UUID/XDG/Guard，使用如下共同env；不是另一次重复运行）：

```bash
export AMBUSH_TEST_SOURCE_SHA=71cfc20a877c9cbbfc272d15aa05c82f6f7090f7
export AMBUSH_INITIAL_RECORD_ROOT=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75
export AMBUSH_LEGACY_RECORD_FIXTURE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 movement_dust_source_boundary_test.gd --headless
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 movement_dust_test.gd --headless
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 visual_snapshot_test.gd --headless
DISPLAY=:121 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 movement_dust_test.gd --render
```

正式UUID依次540c874b0f8f4c309d2dc09cd4bd9c5d/172a4040d9a443acb251c8f2696d28f9/ca8f4983e97043a0a36702b6d28853f1/476922bf43da4c5b8e1db4af2c4d8433。[manifest](evidence/20261004-pr15-movement-dust/manifest.json)保存所有原负/带S1/错误fixture与正式log/actual exits/JSON/fixed scripts/production blob proof/21 PNG/view receipts。所有本作者engine已收尾；核对exact argv/UID后只关闭本作者Xorg121 PID112634，session68509实际退出0，receipt保存。

父端新blast source独立限定通过单列：fixed ac/d75/640四生产blob一致，source119、toolidentity19、old/new stats各7 actual0 E0/S0；独立105/0 E3/S1夹具与作者249 S1/261缺control旧轮不计green，不相加。没有独立PNG/render，未借此接受本尘或blast reader池。b563/53/9f此前独立限定关闭继续有效，不重开已通过范围。

下一步：[A3采集计划](AMBUSH_PR15_A3_COLLECTION_PLAN_20261004.md)按固定当前FX source进行云同环境raw量测和必要单片优化，再FINAL同source fullsmoke/new正常六关13波/六新原件完整1×/2×3D→可追溯fullgame APK。完整所有枪/姿态/LOD艺术复核、长驻留/所有波峰、耳听/设备尚未验。R5源29749157/交付ebed、20骨/socket/3LOD/52语义保持，ArtSource/GLB/Blender/atlas/production manifest不编辑或重跑；runtime/test主作者单写，无merge/生产/height/G。可并行固定71纯reader/source/资源生命周期只读独立QA，A3实际量测必须与其他engine串行控制CPU争用。
