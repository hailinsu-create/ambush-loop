# PR15 P2-SOURCE-SHOOTER 独立源修复

2026-10-04。父端source183实际反例提示已由作者复现；负测试固定 `50b2c1a6c4ced217fe31a489f31c5a02efbd6eeb`，生产writer与183/e0相同。修复固定 `9f6f83ead818993114b8519266e1a7131acc5f05`：仅ShotFxRecording._valid_source增加真实shooter仍有效、按ops/op_id或enemies/label_id读取真实ID、双方严格TYPE_INT且相等的6行门。confirm及finish共同执行该门。原攻击、ammo、HP、回调、事件统计及保存schema没有修改。

明确fixture：真实A/id1、Kar98k、ammo3、pos(80,80)/90°，target(80,112)/HP100；B/id2、MP40、pos(104,80)，传入valid current-log B event，调用原 `_try_fire_with_recorded_fx(A,target,event)`。50b负H3/1 actual1 E0/S0、UUID a04c6fe5cdd54f2289dea96e08ad0eb4：A成功/唯一callback、ammo3→2、target100→52、B ammo32保持均通过，旧writer却写B/MP40/fire_smg且fx实际damage48。不是已证明普通玩家UI路径。

同原测试字节、固定9f最小H3/0 actual0 E0/S0、UUID f9bb84010c0849aaba20b2bc6dd9723f：A原攻击保持，B原event字节完全不改且无fx。固定9f原合法boundary H45/0 actual0 E0/S0、UUID 15b27cf0f9fc48d1a55f10ceee300b50 已自然结束：ordinary/末弹pack/自动pistol/致死/刀、false/stray callback、old-wave/foreign-log、enemy cooldown/MG/cover实际HP差全部保持。固定9f六关source H5607/0 actual0 E0/S0、UUID 407429d68543456abd98787248a78df7 已自然结束，103原实际reference shots全部通过。原terminal/count yard1283/34、warehouse1191/67、pump907/34、railcut719/38、depot957/35、radio1413/51 保持。这些是此次9f的独立作者运行，不沿用183旧结果。

完整原负日志、实际退出、JSON、固定writer/tests/wrappers及审计归因见 [证据 manifest](evidence/20261004-pr15-shot-fx-shooter/manifest.json)。

实际命令全部走官方4.7.2与fresh UUID/XDG、Guard先于autoload：

```bash
AMBUSH_TEST_SOURCE_SHA=50b2c1a6c4ced217fe31a489f31c5a02efbd6eeb bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_shooter_binding_test.gd --headless
AMBUSH_TEST_SOURCE_SHA=9f6f83ead818993114b8519266e1a7131acc5f05 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_shooter_binding_test.gd --headless
AMBUSH_TEST_SOURCE_SHA=9f6f83ead818993114b8519266e1a7131acc5f05 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_boundary_test.gd --headless
AMBUSH_TEST_SOURCE_SHA=9f6f83ead818993114b8519266e1a7131acc5f05 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_source_test.gd --headless
```

6.1-sol只读复审确认两个真实ID字段原类型均int；正常return_fired同from.label_id建event与confirm；pack/自动pistol不改op_id、保存gun仍在原伤害/换枪前。审计没有运行引擎，不作为独立运行验收。另提示同射手旧事件/错误clock与重复descriptor覆盖为未运行复现接口风险，普通main紧接新prelog；本片不扩大到其他source规则。

父端独立QA归因：可选bool866同原测试148/0、38/0 actual0、missing/true/false及原20骨等价限定关闭，旧577的148/7、38/8保留；escape f0ed限定关闭不重开。以上是父端运行计数，不混入作者100/45/5607。b563池224/236/可见47原结果只属b563，不覆盖本P2或代最终全FX接受。

未验：新source的3D FX独立运行QA、普通玩家错配可达性、同射手旧event/错误clock/重复覆盖、全部武器/自然长驻留、A2/A3/FINAL13波/六新record/full1×/最新fullsmoke/APK。源H不代窗口或设备表现。后续A2先实证flight单位，再独立确认blast保存接口及烟尘池；6.1-sol可并行固定源只读QA、主作者独占代码和引擎。R5制作源/GLB/atlas/manifest未改、未重跑；Draft不merge/生产/height/G；耳听/设备后置，网页GPT PLAN/REVIEW unavailable。

2026-10-04 后续父端独立限定关闭收据：同字节原183最小3/1→9f3/0，另副作用10/0 actual0 E0/S0；实际A成功ammo3→2、HP100→52、原callback唯一且先于伤害，B ammo与错误PREevent bytes不变，仅拒badFX且合法A metadata正确。正常玩家错配可达仍未证；作者45/5607只核证据，不计独立运行。父端963files/旧20packs一致。b563 pool与53 flight仍待独立render，不能借此源关闭算通过；本scope不重开。
