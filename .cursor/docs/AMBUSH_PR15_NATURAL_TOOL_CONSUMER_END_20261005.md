# PR15 旧真实mine中性兼容 / repack历史动作消费者 END

2026-10-05，依[启动前计划与admission收敛](AMBUSH_PR15_NATURAL_TOOL_CONSUMER_PLAN_20261005.md)。固定产品 **b74f1fc2f190f574cd0c31aba04e495829337214** / game tree **1e8af45ee23098f763acc139b56f8f7e0f41665a**，与既有1ec产品树精确same，消费runtime为已核纯1ec stage。仅文档/外部观察脚本，无产品、玩法、reader/loader/manifest、资产/音频变更，无性能profiling、导出或部署。

**旧自然repack的当前历史动作已在有界原生消费者验证；旧自然mine只能验证受害者事实与中性兼容，不能验收新版已确认爆烟cue。** 没有重打producer/授物/传送/强制sim_check、修改旧记录或假造tool_fx。

## admission 与保留的阻碍/方法失败

原两个gzip本地无损解压actual0，raw warehouse15,311,216B/SHA63fccaa28ed9ff9f90729f458ebf695f05bac57cac9be0d58ec28c54ef17a08c，railcut13,717,064B/SHA154c69778d82b3d7a35b32d7d5ebd8782cd792cb9edad82544495a125af86e53；原gzip/raw SHA及完整源路径在decompression.json，未在新证据重复raw bin。

`python3 /tmp/pr15-natural-tool-originals-20261005/admission.py` actual0/E0/S0/Guard，START19:58:23.519845→19:58:24.787806 UTC。真实原mine event `2a53f1c40c480b06c4b12c24c9416bbb:1:39`，wave1/local356/global696/**playback6633**，actor2是受害敌，payload为空；紧前kill为同tick seq38。爆点前snapshot6631/后6637**无tool_fx相关keys**，附近原数组中性，因此不能得到新版确认descriptor/owner/tool identity/受害者payload。旧事实保留，不以当前live字段补历史。

真实repack event `93d07e8fdaa687f28d8e05c9432f4724:1:28`，wave1/local58/global254/**playback4749**，op1，same_weapon/kar98k/reload_s1.15，紧前真实fire seq27同三种时间。旧原自然输入中ammo0/usedfalse→ammo5/usedtrue的临界观察见原railcut journey；此原record最近存帧ammo1→5，不补造记录中未采到的瞬时ammo0或used字段。

原“两个工具新版positive”240秒包在admission后停止：**END20:02:21.551379/237.967823s（全部准备idle计入）/cap240/live0，renderer NOT_RUN_REQUIRED_MINE_FIELDS_ABSENT**。metadata actual0不等于positive mine presentation门通过；未重置预算补绿。之后启动前另声明不同范围的“旧mine中性兼容+repack动作”消费者包，原positive mine门保持未满足。

两个外部脚本编译失败保留：v1缺WebConfigStore preload，actual1/E1/S4/Guard未到；v2 snapshot实际返回String而误声明Dictionary，actual1/E1/S2/Guard未到；两个native窗口各约12.6秒已END，未进入consumer断言。v3先check-only actual0/E4/S0，是漏带XDG导致默认home写入被拒，未称方法通过；private XDG修正后**同一脚本**check-only actual0/E0/S0（20:09:32.643775→20:09:33.213787，cap15）。只修外部preload/类型/环境，产品与原断言未改，不映射exit或删错误。

## 实际原生消费结果

`python3 /tmp/pr15-natural-tool-render-v3-20261005/render.py` **actual0**，官方4.7.2/Compatibility/OpenGL/Mesa llvmpipe/Dummy/1280×720；fixed-fps60仅受控功能调度，不是帧性能。每侧独立UUID/actual Guard、cap75，窗口总cap180，超时只kill自有process group；START20:09:43.290761→**END20:10:44.474956 UTC，61.184626/180秒、live Godot/Chromium0**。

| 实际consumer | actual结果 | 有界结论 |
| --- | --- | --- |
| 原warehouse mine | **53检查/0失败/5采样/actual0/E0/S0/Guard**，20:09:43.290761→20:10:13.760849 | 原事件前/时/后、原3D聚焦、向后seek；原victim2在采样frame6632/6639的HP100→−20、alive true→false（120差），tool_fx_schema0/reader0/pool0正确中性。event_tick6633读最近前存帧，HP仍100；不声称同tick后果全部保存或新版爆烟cue出现。原inventory自然1→0事实沿用旧producer，不冒称本consumer重新消费雷 |
| 原railcut same-weapon repack | **55检查/0失败/6采样/actual0/E0/S0/Guard**，20:10:13.761454→20:10:44.474773 | 原事件前/时、reload时窗、后事件、3D聚焦、向后seek；tick4749原fire event27→tick4776 **reload_contact/event28/同kar98k**→tick4821后续新fire event33，20骨/weapon_hand/socket全封。后段实际是新fire，**不是aim**；reload_contact按保存事件时钟结束 |

明确consumer fixture：复用各原ending-player-progress完整cfg并加载当前level，通过原Replay handler绑定旧自然记录，暂停main与presenter自动处理，仅读选帧后当前renderer刷新；相机180°/35°/view7定位事件。seek/相机/场景初始配对是受控消费者设置，不是普通fresh胜利、可信OS/DOM输入、whole自动播放或设备接受。退出走合成engine原Space输入，未宣称真实Web/普通来源切换可达。

每样本实际断言**完整live domain（非只hash）/两cfg全文/public checkpoint String/原record containers不变**；20骨/socket及完整frame/UI/池状态均保存。原Space返回WON/record保持/旧tool pool中性，离线`analyze.py` actual0再次逐全文核：REPLAY期间全部domain-cfg-checkpoint一致，退出domain唯一差**phase4→3**，其余字段完全相同；退出cfg/checkpoint/record仍same。没有把允许phase转换说整个snapshot不变。

**11张原PNG逐张目检**：mine事件环位于历史雷点、前/后存帧受害者状态改变且无伪造爆烟；railcut HUD弹1→5、原重装动作/后续射击与事件聚焦可见，近景未挡住中心操作员。此角度/尺寸不能充分判细部握持接触与全部LOD/动作/全战场艺术接受。两原件分别在独立context消费，没有同context换源、live污染、跨波整段/自然暂停持续测试；那些仍待，不以旧shared source-text/FX fixtures代本自然case覆盖。

## 封存、下一步与边界

[manifest](evidence/20261005-pr15-natural-tool-consumers/manifest.json)封**73 artifact/9,781,080B**（manifest另计）、72原件映射，原metadata/解压receipt、v1/v2失败、v3两parse回执、两consumer实际argv/Guard/START/END/log、全文before/after/11frame-UI-body-pool/11PNG、原脚本与逐字段分析全保。大的原JSON仅gzip无损，roundtrip原bytes/SHA exact；两个raw bin沿原gzip引用，没有重写/复制进新包。

窗口已归还，下一父端可独立检查固定b74/1ec树与本11采样、允许退出phase转换、旧schema缺字段的中性行为、repack事件身份与动作。父QA b3be完整原件位置仍未收到，原E6/E3和95daa raw29差未关闭；候选已经撤回，不部署Site仍v4。

下一授权工作优先只读筹划最终同source fresh13的合法mine/repack触发；新版natural mine cue需要**当前writer原生保存tool_fx/confirmed/owner/victim/clock字段**的真实记录，优先在最终fresh旅程合法触发并直接封存消费，避免再重打旧producer。若最终策略没有触发，再有界独立自然case，不能改装备赠予/玩法/敌人或制造确认字段。throw/MG、完整samecandidate13/六新whole/fullsmoke/all-art/听感/最终A3/APK与设备、正式origin身份均保持待验；不继续同类性能小优化。

R5既有接口20骨/weapon_hand/socket/3LOD/52语义保持，无新增资产包请求；制作作者独占生成器/atlas/GLB/Blender与音频，本片未编辑或重跑。PR15保持Draft，不merge、不生产发布、不混高度射击。网页GPT PLAN/REVIEW unavailable。
