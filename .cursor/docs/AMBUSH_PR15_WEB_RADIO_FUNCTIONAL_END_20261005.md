# PR15 原radio功能END与独立save QA交接（2026-10-05）

**PASS_BOUNDED_RADIO_FUNCTIONAL_END**。radio原producer、同原bin自然完整1×/2×、原credits实际滚动、六关完成档精确reload/有限同profile重开、安全Title及实际END、隔离原bin只读语义均已完成。仅radio3波属于新source；旧五关不能拼同最终候选full13，仍不是艺术/设备性能/fullplan/FINAL/APK通过。

生产 **1ec3198e9c0db367af96fc264604c5a286003b5e**，game tree **1e8af45ee23098f763acc139b56f8f7e0f41665a**；producer交付 **74ef1535a4bb9078dff5faec2dbf9e7c5c9d1077**。[producer原检查点](AMBUSH_PR15_WEB_RADIO_PRODUCER_CHECKPOINT_20261005.md)给完整父链与原档/策略/预算。相对f0d97457faa81b94a51cae12c40e07987267c738，唯一产品变更是1ec main.gd `_save_progress` 保护已结算WON回放next/complete；新增paired回归及Linux/Windows隔离入口单列。**037ac927a120485ce462028a6bb7d19ba4521794** 及0a160a46055d4beb01084da32b56d3525a927c3b、1eddea3e131e45ffc5a05c02aff81c6d8c7693cd、74ef均只文档/计划/证据，无额外产品变更；14pins仅main明确变，其余13保持，原chain机器证据封存。

## 实际命令与结果

唯一持续controller：`python3 /tmp/pr15-web-controls/radio-native-1ec-20261005/browser_controller.py`，PTY session75687/pid165979。原独占JSON请求按下面实际入口串行，无额外并行引擎。

| 请求 → 原脚本 | 实际结果 |
| --- | --- |
| initialize-radio-original-profile → initialize.py | actual0；原profile两cfg全文/SHA及公开checkpoint14052356…精确depot END，next radio/seen六关/单页/no fixture/no seed |
| produce-radio-natural → produce_radio.py | actual0；原Continue刀具新attempt **1b581d1574f29d83f44f04032601b7f6**，三波自然ALERT→SWEEP **591/123/129**→原撤离WON，**552.739915s/cap900**；三波pausedALERT各原图已留/已看，无失败/重试/强制事件 |
| radio-whole-natural-1x / -2x → whole_radio_1x.py / _2x.py | 两请求各actual0，下面分列完整实际请求/helper/输入到终点callbackwall；均从零自然终点7390并原←→Space返回WON |
| radio-credits-complete-reload-reopen → radio_boundary.py | actual0，14:59:23.349893→15:00:22.681470；原WON CTA/原wheel **vertical0→84/max402/page318**，原Back Title；六关cleared/unlocked、complete=true/Continue disabled；全文两cfg/公开checkpoint精确reload及有限同profile重开 |
| radio-browser-final-proof → finish_radio.py；close-radio | 各actual0，safeTitle、ownedpages1，原预finish5回执副本；browser/HTTP **END15:01:26.442554**，工具实际PTYexit0；ports12815/12816/12817closed、liveGodot/Chromium0、profile lockabsent |
| `python3 …/run_radio_offline_audit.py` | unique user:// UUID3a2550b95ef64b059dfa218d5b1264a0及实际Guard，native4.7.2原bin只读 **15707/0 actual0/E0/S0**，15:01:48.124828→15:01:50.495699；不称离线逐选择是whole/3D渲染 |

| 原whole | actual | 完整请求wall | helperwall | callbackwall | cap | 对齐观测行 | 终点3D checks |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1× | 0 | 551.876284s | 507.536693s | 501.312300s | 769.000000s | 935 | 15/0 |
| 2× | 0 | 295.779271s | 257.061855s | 250.603400s | 399.500000s | 473 | 15/0 |

两轮都分别保存完整before-natural/after-terminal/post-WON指纹（包含原只读state/configs）、原pinned且exclusive-copy helper、可信原输入及request/receipt/vault原件。record/domain/两cfg保持，行tick全局单调、source attempt/rate和3D view_tick对应。callback比值 **2.000420984** 仅软件功能观察，不称实际设备速率/帧预算接受。冷夹具首次Space结算边界不由本自然已结算WON结果替代。

## 原件与范围

原八字段 **14,263,460bytes/SHA fd78f1f500455777b3c97e7d4a3ab466d162538782387b4df9b11d1ab7225196**，schema2/972frames/57events/global terminal7390；legacy battle terminal845、末波local129。原事件waves0/1/2计数38/9/10，原两次本地tick回退而全局单调、event identity/seq与纯ViewState边界全核。fire14（Grey12/Scout2）、kill5/spawn5/return_fire6/loot5/no_engage20/door1/terminal1；mine/repack/throw仍0，MG未射击，续包unused/场内原mine1。原loot包括第一波ammo2/5/2、第二波decoy1、末波radio_part1，未因表现改库存。最终HP100/ammo4/50/4；第一波实际伤害及原拾取恢复仍在原记录，不能写全程无伤或全部武器工具通过。

完成档progress SHA **bd858eed12b54c69ef40eb3b6e4d97a5ed9fb2fe74b72bdf79f39199f92a3d55**，settings SHA **9301c4e5a6be0d02e8d4274e92cad786790dce801903f7cbb330686757fefa0e**，公开checkpoint **a6cdd8951fc2928bdc6d71113c642c8562b253ce0a647f82f48b6a987bc9a77b**。原next字段仍radio/index5，complete=true导致has_progress=false/Continue禁用；不声称next字段为空。有限重开先停HTTP，owned恢复页chrome-error+blank，关1 surplus后唯一blank才重启HTTP，配置未seed，未构成两个活跃游戏页。

浏览器trusted **155+4+4=163** 与原引擎输入 **156+4+4=164** 分列，差1实核来自一个DOM wheel对应原Godot MouseButton5 pressed/released；45原click/32key pairs相同，无合成输入。console errors0/pageerrors0/GL_invalid0、ReadPixels warning8保留。17原PNG全部逐张看，仅云端软件图，不代设备或全面艺术接受。

[producer manifest](evidence/20261005-pr15-web-radio-producer/manifest.json) **57files/23,087,925bytes**；[END manifest](evidence/20261005-pr15-web-radio-functional-end/manifest.json) **78files/8,116,932bytes**。逐文件size/SHA实核、前57原件再次保持；7原controller receipts/vault完整，5外部prefinish副本exact，原START/END不补造。profiles/cache/凭证/制作资产/PCK不入包。只读scroll QA官方exportactual0/E0/S0、PCK817fadb9/64,667,788bytes，对fixed QA仅observer.gdc变，53完整class块/全部payload MD5/资产保持；QA不是production bit-identical。外层pure audit误用res://前缀KeyError wrapper1和更正pure0仍原样保留，未重导/重跑制作。

## 下一步与接口

当前作者所有engine/browser/HTTP均END、没有活动会话，**窗口交回父端独立QA**；不再启动yard/其他引擎。优先固定1ec普通已结算WON→Replay→M→原设置Title→Continue，真实原URL刷新及关闭重开是否保持campaign next/complete/stats和合法音频偏好。作者[原对照](AMBUSH_PR15_REPLAY_SAVE_BOUNDARY_END_20261005.md)已paired负15/2→正15/0、store22/0、真实刷新旧warehouse负/新pump正各0；原关闭重开此M场景仍独立QA待，不用本radio complete重开代替。保旧reader错误/timeout/缺END、首browser重复close1、cold-query刷新1原件；父端QA4a4b完整包未本地取得，不臆造全文读取。

之后按原计划继续原yard whole、所有武器/矿/repack合法自然专项、同最终候选fresh13/六新record全3D事件、FX/A3/fullsmoke/FINAL/正式origin与PCK+128B差异/耳听及可追溯APK；设备按全计划后统一。私有Site **v3不变**、R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281与manifest/clip/socket/LOD接口保持，无新资产请求；不改/重跑generator/atlas/GLB/Blender，无merge/生产/height/G混入。GPT PLAN/REVIEW unavailable。
