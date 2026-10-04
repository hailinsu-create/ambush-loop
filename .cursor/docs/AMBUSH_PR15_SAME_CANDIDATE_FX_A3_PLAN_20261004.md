# PR15 同候选六关、3D FX与A3接续计划

2026-10-04，继承资产执行v2全部范围与单写者约束。结果事实fixed a794、当前波fixed480为两个独立切片，各专项结果只归自己的source。旧d7/b27/030/3b正常13波是分段进度链，旧formal29/reference矩阵、样本场景与短相机probe不能替代最终同candidate完整验收。该文是执行计划，不是已运行结果；第二片正式报告记录其实际H/R与剩余边界。

## 固定候选与证据规则

当前波chip片的截图复核已发现另一个运行时展示问题：观战路线条caption为“观战”、elapsed绑定当前local clock，却仍用关卡总表dots（radio末波仍3.6/5.2s），并可能把前波payoff局部tick放到当前条。chip专项不把该条算green。**先独立live timeline slice**：负向绑定原当前队列/入场event与SCOUT预览，修dots为对应原wave定义、payoff只使用原attempt/current wave事件的local time，不改旧event身份；原失败/固定H/R及实际更新HUD的截图保全。该片完成前不把当前波全部展示关闭或开始最终candidate验收。debrief全attempt条/静态教学/IntelStore建议另审，不因live条修复自动计入。

首次基线先固定两片整合候选的源码SHA/game tree，使用官方4.7.2单次import/export及PCK/hash/实际exit作为云运行入口。fresh隔离UUID/XDG中的原fresh→原标题开始→六关13波→WON/原CTA/自然progress/credits，一路原生输入；默认刀/原匣拾枪/原SCOUT铺设/原SWEEP走近loot，不授seen/unlock/枪/ammo/位置，不用reference/vacuum/自造敌/快进。每关封存自然progress与原record，出错原失败、发生source和正常assert覆盖边界独立保留；不能因为总数green而隐藏未断言的文案、时钟或回放错误。

六份新record必须用同candidate实际3D绑定/auto/seek/事件聚焦，检查attempt/wave/seq/event_id/原local与global/playback时间、装备/动作/世界/尸体来自绑定source，后波/live同seq不能污染。耗尽、mine/trip或路线事件未发生就标未覆盖；分别补明确实际后端reference正反例，禁止把授枪/直tick/参考布阵改称正常输入。旧schema1原bytes/hash不升级，用原件读兼容；旧fallback与新版本轨分开报告。分清metadata、渲染、normal/reference与独立QA，不相加宣称通过。

除首轮基线外，FX/A3源发生变化后必须锁定新最终source重跑需要的同候选组合，不能拼接旧source数字形成最终验收。baseline记录行为与事件，在展示优化后比较同输入域结果；完整新native旅程仍须对最终candidate运行一次。

## FX-A1：真实枪声事件的3D表现

主集成作者单写presenter/ViewState/replay/事件契约/共享测试。先审实际成功射击与命中来源：当前fire日志在try_fire之前追加，不能未经核对就把任意fire都当成功射击/命中。从原成功callback建立表现descriptor，记录绑定attempt/wave/seq、版本、实际来源/目标/位置与时钟；保留原模拟/R统计。新增表现版本显式声明兼容，旧原件缺字段时不借当前actor/枪/目标或伪造命中，不把旧bytes现场升级。

三类首片：muzzle、tracer、实际hit impact。利用R5现存ActorVisual.item_socket("muzzle")/bone_socket及武器marker接口，先验证缺socket/weapon/actor、LOD切换、pose/seek边界；不改骨/GLB/源脚本/atlas。3D影子关闭、有限池与明确上限，标准/省电策略明确。真实射击帧、暂停ALERT、1x/2x、跨波、负向seek、重复seek、source切换/迟到callback/REPLAY离开/reset/abort/focus均验证，所有视觉不改state/record/ammo/HP。成功枪火与空fire/失效源有正反例。

## FX-A2：工具、爆炸与移动

再独立做grenade/mine爆炸、smoke、foot dust；由原工具动作/实际爆炸/移动pose时钟生成，仅表现池，不重写弹道或伤害。mine事件当前actor字段为受害敌id，须核对语义，不能误绑队员持枪socket；未知/缺字段降级行为明确。暂停/REPLAY完全由绑定记录时间控制，不能用壁钟继续冒烟/爆炸或后波数据补旧烟。池生命周期/内存增长与满池降级测试，对艺术人员提供真实战斗帧序列和成功/失败事件依据，样本展示不计全战场集成。

## A3：预算、优化与回归

先量测最终FX候选六关真实SCOUT/ALERT/SWEEP/WON/FAILED/REPLAY、各方向与实际战斗峰值，记录分辨率/scale、渲染后端/GPU/CPU/引擎、raw frame intervals、draw calls/primitives、纹理/内存、shader warm-up和池峰值。已有device_probe只是30s相机tour/2s warm-up，不是持续性能验收；llvmpipe云测是环境内比较，不宣称安卓30/60FPS达标。预算以实际基线及执行v2约束建立，不编造当前数字。

按证据单片优化：MultiMesh/批次、材质与纹理驻留、LOD/可见性/cutaway、FX池上限与省电成本；每片保留同输入域结果、实际图与必要原回放。不能缩角色/视距掩盖穿墙/握持或改战斗规则达标。A3回归覆盖装备ALERT/paused ALERT/REPLAY锁与SCOUT/SWEEP合法，Back先关包、touch cancel/focus/重试/换关、当前波clock、六关完整13波不变量及旧2D有界/全相关回归。测试失败归具体触发和source，新增修复后重新锁最终候选。

## APK与并行包

最终同candidate绿色只在对应已验范围内成立，再生成可追溯APK：源码SHA/game tree、R5/环境revision、导出工具模板、实际命令/exit、package/version/ABI、APK/PCK/hash与签名验证归build provenance。现有Android APK preset为arm64/com.ambushloop.game/version77/0.6.28，源码检查不等于工具链或APK已成功；安装工具/导出/签名验证仍待实际执行。私密签名材料不入库、不发布生产。设备全部计划后，本计划不提前安排设备测试。

可交父端的独立并行包（优先6.1-sol，不自行派astra；独立副本/display/XDG，禁止写主集成）：

| 包 | 输入/交付 | 不能冒认 |
| --- | --- | --- |
| 结果＋当前波独立QA | 固定修复source，旧原失败、正常depot/radio结果/paused末波及新record3D；返回自己的SHA、命令、actual exits、图hash和未覆盖 | 旧3b QA不代新candidate；reference不代normal |
| R5/六关真实战斗艺术评审 | 主集成给真实枪火/动作/尸体/环境方向帧；指出具体帧/socket/LOD问题；资产作者只改独立制作分支，提交验收后的source/GLB/manifest | 不全并WIP、不覆盖主manifest/测试；turnaround不代战场 |
| A3独立量测 | 固定FX候选与原正常input/record，只读收集同环境raw metrics/峰值/泄漏；输出环境与样本范围 | 短probe或云GPU不代设备持续性能 |
| 原45cue/六声景耳听 | 原音频与真实事件/关卡定位，输出实际听过条目/判断/遗漏 | Dummy路由或文件存在不计耳听；当前无耳听通过 |

所有包返回固定提交/接口后由唯一主集成验收有界接入。当前两项展示切片无需新增制作件；R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/3LOD/52语义保持，ArtSource/v2/build_yard_kit.py/共享atlas/角色GLB/Blender输出不编辑或重跑。runtime loader与build provenance归主作者；制作revision清单先只读接收验收提交。网页GPT PLAN/REVIEW unavailable，不臆造approval；普通push Draft PR15，不merge/生产/height/G。

其他已识别展示审查边界保留：总表route_spawn_marks→route timeline、IntelStore.delay_for_actor/first_route_delay、SCOUT echo callout与静态教学/fix_one/chatter的旧秒数；当前波chip修复不自动验收它们。先判其声明语义和实际波事件，发现运行时当前波/事实矛盾则独立negative→fix，保留教学目标但不把目标时间等同当前波入场。正式完整smoke不能对这些未验内容隐藏在green中。
