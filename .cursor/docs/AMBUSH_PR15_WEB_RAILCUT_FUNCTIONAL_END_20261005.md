# PR15 railcut 有界功能 END（2026-10-05）

原profile railcut 两波自然WON、同条原录制完整1×/2×、depot交接/首次教学/解锁/保存/刷新续关通过。本报告替代 [producer检查点](AMBUSH_PR15_WEB_RAILCUT_PRODUCER_CHECKPOINT_20261005.md) 的 RUNNING 当前状态；该检查点保留为历史原件。仅本切片功能通过，不是全六关、性能、完整计划或设备验收。

固定生产source **8532c4c3084d1a5672bbe28dc96e1c02522a8f05**，game tree **45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85**；14策略size/blob/SHA在执行前及全部END后实核保持。计划 eb50a736da09038bda49d96a3e15c33389a83317、原producer检查点 **7c661957276ca7445f7e2cf66896dccda3c53155** 已normal push/远端readback。本片只增加控制脚本、实际证据和文档，production/runtime manifest/loader/制作源没有修改；Draft PR15，不merge，不涉及高度PR4–6/13/16。

## 实际来源、预算与阶段结果

唯一原profile `/workspace/.ambush-loop-env/web-fresh-native-dab-20261005`，原origin `http://127.0.0.1:12815/index.html`，viewport1280×720/DPR1/default desktop。Title装载先核对上片完整cfg/settings/public checkpoint，actual0；原Continue新刀具SCOUT，fixture=false，无fixture query。复用已核QA-v2完整Title PCK **64,662,184bytes/SHA f02f9042f42d5fd08f286bbecfc386295bfb20fd677413d86c1bc33ae5a99e21**，已声明只读桥/warehouse bin/注册缓存差异保持，未执行冷fixture，不称production bit-identical。

| 阶段 | 实际动作与命令入口 | 实际结果 |
| --- | --- | --- |
| 原profile入口 | controller stdin `initialize-railcut-original-profile` / `initialize.py` | actual0；两cfg全文SHA、公开checkpoint、任务行/seen一致，one-page |
| railcut producer | `produce-railcut-natural` / `produce_railcut.py` | actual0；463.15195600601146s / 总cap900s；两波自然SWEEP→原撤离WON |
| 原录制whole1× | `railcut-whole-natural-1x` / `whole_railcut_1x.py` | actual0；自然0→7610；callback wall469.5659s / cap791s |
| 原录制whole2× | `railcut-whole-natural-2x` / `whole_railcut_2x.py` | actual0；自然0→7610；callback wall235.7332s / cap410.5s |
| depot保存边界 | `railcut-save-unlock-depot-reload` / `railcut_boundary.py` | 原实际stdout actual0；首次两页教学、精确reload、Continue新刀具SCOUT无重复教学、安全Title；原回执结束时间后来误写，损失见下 |
| 修正后最终proof | `railcut-browser-final-proof-corrected` / `finish_railcut.py` | actual0；150 trusted browser / 150 engine输入；原下一关存档与安全Title保持 |
| browser/controller END | stdin `{"label":"close-railcut","close":true}`，unified session17172 | 最终PTY actual0；11:46:52.935165 UTC END |
| 原bin纯reader审计 | `python3 /tmp/pr15-web-controls/railcut-native-8532-20261005/run_railcut_offline_audit.py` | wrapper/native actual0，16,350 checks/0 failures，ERROR0/SCRIPT_ERROR0，实际StorageGuard通过 |
| END封存/源码核对 | `python3 /tmp/pr15-web-controls/railcut-native-8532-20261005/seal_railcut_end.py` | actual0；14pins、原bin、旧28证据size/SHA保持，ports12815/12816 closed、live engines0、profile lock absent |

whole1× controller total wall **474.90480178498547s**；whole2× **241.06612218200462s**。真实输入到自然terminal callback比例 **1.9919379196481446**；原录制模拟时长126.83333333333333s。软件WebGL仍明显慢于模拟时长，只计完整自然功能流程，不作帧预算或设备性能通过。962/486观察行分别完整单调0→7610、view_tick逐行等于replay tick、attempt/rate固定；实际终点3D frame各 **17checks/0failures**。原record/domain前后相等，原ArrowLeft/ArrowRight只读暂停、Space返回WON分列，不用直接set_tick补whole终点。

## 原producer与身份

原attempt **da8ada7d495e14f0a7e1cd3b71058fa6**，producer START11:16:52.461076 UTC、END11:24:42.108792 UTC，原三刀具SCOUT无重复教学。原取Kar98k/MG42/98K瞄准镜/手雷；cover1/4/5、原键朝向270/270/180，灰狼原ammo pack和SCOUT I/auto按钮关闭auto-grenade。原MG42盒实际装备50发，不能把generic authored mg amount12写成实际枪械弹量。原alarm/pause/unpause；第一波自然SWEEP11:20:11.565136/local195，原铁砧authored ammo/夜枭搜刮/再部署；第二波自然SWEEP11:23:14.229706/local1149，原搜刮/撤离WON。未teleport/写phase/tick/policy、没有扩预算或重跑producer。

八原字段var_to_bytes bin先封于7c661检查点：**15,373,004bytes/SHA b50e1f115538933e2e1bdc86402817f1988e6bdbd77525308615c3a96e2bbd3f**，schema2、1017frames、45events、global terminal7610、local terminal1345、reasonwin。pure reader实际核出事件wave0/1为23/22、local tick reset1；全帧保存的level/wave/phase、支持pose、ViewState只读actor原值和事件cutoff、attempt/wave/seq/globaltime均0failures，原bytes未变。纯reader逐帧set_tick只用于离线原件契约，独立于真实whole/3D终点证据，不升级为全逐帧renderer验收。

## 保存、刷新与窗口生命周期

原WON Continue→depot handoff→原CTA→首次教学0/1两页→原Esc/Title任务行：yard/warehouse/pump/railcut cleared，depot unlocked，radio locked，complete=false。未生产的教学preview attempt **7ef12386ae31ad67ba5f085164347c72**；刷新后原Continue新刀具SCOUT **a4346f38912213d99197e7da1a176d6c**，无重复教学，随即原Esc/Title。两个preview独立，不拼入railcut原记录。

最终 `ambush_loop.cfg` SHA **050864ec68d3819eb4275bce4e106ba64299f6635b648cf736f0e68903d57b7c**，next depot/index4/loop1/四关各1loop perfect；settings SHA **5610ba32c76ec210bb5e3baf24ad8d17ad53702c14e9b05dd45cf0b3fd55042e**，仅原教学新增seen_depot=true，音量1/mutedfalse/force_touch_hudfalse/qualitystandard保持。公开checkpoint SHA **38792659f3d94dcf8f24ee838783c9445a0d255ebbba1fc3963f50835d38e162**。实际reload前后两cfg全文/SHA及公开checkpoint exact；刷新前140/刷新后10 trusted输入，engine各140/10。console error0/pageerror0/GL invalid0，原GPU ReadPixels warnings4保留。

v2 WINDOW_START **11:14:42.060022** / ENGINE_START **11:14:43.531035 UTC**，唯一controller PID159645/session17172/port12815、context one-page。全部自然回放/边界完成并安全Title后，browser END **11:46:52.935165 UTC**，PTY0。之后才单独native纯reader START **11:47:14.843879** / END **11:47:17.315568 UTC**、actual0；unique private user://实际guard，无配置删除，不直接运行smoke。最终live engine0/端口closed/原profile锁已释放；引擎窗口可归还，未启动其他关或并发引擎。

## 原失败、损失和证据

首controller actual1，恢复出的自有 `chrome-error://chromewebdata/` 页不在URL断言列表；server尚未启动，未进入Title/profile比较/producer。原脚本与receipt封于producer `negative-restored-error-page/`。v2仅允许自有恢复错误页并在server前关闭自有surplus→blank，one-page/原storage保持；不是游戏失败或900s重试。

首finish脚本使用exec全局 `label`/`receipt` 循环变量，与controller同名，断言本身完成却覆写了已有 `railcut-save-unlock-depot-reload.json` 的end为11:45:40.468739；该原回执已不再是精确endpoint原件。实际边界stdout在11:45:26.957743发出PASS并返回actual0、原输入/PNG/profile/reload文件仍在；不重构丢失回执。错误loaded script、误写原件、首有效proof和说明原样保存在本包 `negative-final-proof-global-label/`。随后只改为 `proof_label`/`proof_receipt`，修正请求独立actual0；不把误写回执当原endpoint精确证据或隐藏损失。

原producer包 [manifest](evidence/20261005-pr15-web-railcut-producer/manifest.json)：**28数据文件/20,199,029bytes**，7原PNG已看，原bin/失败原件保持7c661 SHA。最终END包 [manifest](evidence/20261005-pr15-web-railcut-functional-end/manifest.json)：**48数据文件/8,080,845bytes**，含全部此前活动driver-actions/HTTP日志、whole/fingerprints/input、原边界/配置、最终9PNG、loaded controls、native结果/日志、实际END回执与方法损失。两包逐文件size/SHA实核；共16原PNG实际逐张已看，原图无同名覆盖。manifest本身不计数据文件数；最终包引用旧bin，不重复制造record。

## 当前边界与下一步

私有Site **v3保持**，本片没有重复部署；生产代码8532/game tree45b/QA-PCKf02原样。资产工作者仍独占角色源/生成器/atlas/GLB/Blender输出；本片不编辑或重跑 `ArtSource/v2/build_yard_kit.py`，不接未验收WIP。版本化manifest/clip/socket/LOD接口保持，只接验收固定提交；没有新资产接口要求。

下一独立有界包从本片真实depot存档/Title继续depot两波，先原producer归档、再该原bin完整whole1×/2×与radio交接保存边界；root保留代码单写者与串行引擎QA，非引擎的源码/证据/策略只读包可独立并行分配。余depot/radio共5波、yard当前whole、全候选正常13波/六关全1×2×/A3/fullsmoke/FINAL、真实触控世界锁门、正式origin、独立PCK/+128B、耳听/设备/APK仍待。原父QA143/1/+128B/一PNG损失、预算None/旧多页污染/旧PTY未知及rawJS whitespace2保留，不能用此片覆盖。GPT PLAN/REVIEW unavailable。无本片产品阻碍；非全部计划完成。
