# PR15 pump 原输入 producer / 保存交接 END（2026-10-05）

游戏源码固定 `8532c4c3084d1a5672bbe28dc96e1c02522a8f05`，游戏树 `45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85`；开始时 docs HEAD `3a0e8abfa1958b964fdedfa2f76a10c2e161ff65`。既有14策略数值源码 pin 不变，未改运行时/资产、未重做 warehouse、未 merge/APK。执行计划见 `AMBUSH_PR15_WEB_PUMP_PLAN_20261005.md`。

本片 producer 与存档交接通过，完整1×/2×回放在本报告时仍待独立冷 consumer。不是完整六关、A3性能或设备验收。父端独立QA包 `91a9c573d9cc21711a824a77adf5b28e3d5756f7243ec56ed049ae1fcae9e934` 仅按交付保留：原143/1、普通 PCK 作者+128B差异、横屏一张PNG被覆盖仍未解决；本片没有重建 padding 或声称 onlineReady。

原 profile `/workspace/.ambush-loop-env/web-fresh-native-dab-20261005`、原 URL `http://127.0.0.1:12815/index.html`，无 fixture query。已封 QA-v2 PCK `f02f9042f42d5fd08f286bbecfc386295bfb20fd677413d86c1bc33ae5a99e21`（64,662,184bytes）原 Title 真实装载；warehouse cold setup 未执行、fixture_ready=false。QA桥/warehouse bin/注册及缓存顺序与 production 差异保持63da明示，不称 production bit-identical。Browser plugin unavailable，用已安装 Playwright1.62.0/Chromium，始终单自有page。没有清 storage、seed、teleport、直接推进 phase/tick/policy 的 RPC。

原装载核对 `initialize-pump-profile` actual0：progress cfg SHA `a1952169fd685883c5b87fb318fbcf2d0041acff36b2c904f2004f5f729da60e`，settings SHA `be93fd9c87c2900acdc56553780b9444e9a6a0bdd286e641f3d60dcfc304d7dd`，公开 checkpoint SHA `2d33cc93f05478c8b143bb98044df6bb42a2842eca5304866987eeab0f440700` 全文一致。原 next=pump、cleared=[yard,warehouse]、complete=false、seen_pump=true。新 Continue 从三刀具 SCOUT 开始，无重复教学。

`produce-pump-natural-v2` actual0，attempt `f9bfc48ef5288e4bfb4305a942b73546`，producer wall **396.82748366097803秒**／上限900秒。原取 rifle/mg/scout/grenade，cover1/4/5、朝向90/358/180（铁砧8°粒度容差），弹包给铁砧；原镜头按钮露出世界目标，世界鼠标拾取、1/2/3+A/D部署，第一 SWEEP补弹/搜刮再部署，原下一波警报，第二 SWEEP原撤离到WON。门保持原开门策略；锁门紫线不在本片验收。

| 原阶段 | UTC | 记录 |
|---|---|---|
| producer开始 | 10:23:43.064752 | 新独立attempt、wave_count=2 |
| wave0开始→SWEEP | 10:26:28.053234→10:26:47.449689 | wave0原自然战斗；local tick253 |
| wave1开始→SWEEP | 10:27:55.849733→10:28:36.775413 | 同attempt下一波；local tick681 |
| WON原记录归档 | 10:29:41.406726 | win；global terminal6178 |

八原字段 `var_to_bytes` 原 bin **11,203,052bytes / `a0e5b232a001671ead8156e97e29f902796f81cd7669d925d66045064d5709cf`**，schema2、820 playback frames、34 events，attempt/wave/seq、event_id、全局时间单调校验 failures=[]。先归档再换场景；没有拼前preview或旧warehouse事件。原 engine/browser输入与两波原图均封存。

`pump-save-unlock-railcut-reload` actual0：原WON“下一关”→railcut刀具SCOUT交接→原CTA→首次教学 **2页**→原Esc暂停返回Title，六任务行解锁/禁用实查；同源reload后两个cfg全文与公开 checkpoint 字符串不变，seen_railcut=true、音量/质量/触控设置不变；Title原Continue进另一新刀具SCOUT，无重复教学。教学preview `5f4e51b43585341db61740290efcf033`，刷新后刀具preview `23d6525107a2127140922862ad3f5860` 均单列放弃，未算railcut producer。最终原Esc返回Title安全保存。

保存后 progress cfg SHA `2346856cfef799b6b140bc52ae766df8d030729b95f6e6d728978d55da949b78`，settings `bb25bfab3df63381939c14b7515ae538cddada5a9e7801e26cb1a6af88da7940`，公开 checkpoint `86c8ee4a9734d6ad11a7f0980aa0238c5460b6fd0ebadea0666caad10a5cfb45`。cleared=[yard,warehouse,pump]、前三关loops1/perfect、next=railcut、railcut unlocked/未完成、depot/radio locked、complete=false。

保留方法负例：首次 `produce-pump-natural` actual1，在首个Continue输入之前 budget None 减法失败；修复 driver level_start 初始化后继续沿用同一已选 monotonic budget，不重置900秒、不计游戏失败。加载脚本与 actual1 receipt 在 `negative-budget-clock/`。关闭操作收到 `PUMP_SINGLE_BROWSER_END`；close工具未返回最终PTY退出码，后续poll为Unknown process id，此码不臆造。端口12815 closed、无live engine/browser；ps中三条既存Godot defunct单列，不是活动引擎。

证据 `evidence/20261005-pr15-web-pump-producer/manifest.json`：47个文件／19,578,581bytes，每文件SHA，含原bin、脚本、actual receipts、profile前后、engine/浏览器trusted输入、所有原图。Title/SCOUT/两ALERT/两SWEEP/WON/交接/两教学/刀具Continue/刷新任务行/最终Title已实际看图；原未刷新任务行另列原图。原软件WebGL运行不代表30/60FPS或设备性能。网页GPT PLAN/REVIEW unavailable。

下一步：隔离冷 consumer 明示一次性装入同原pump bin（不写原campaign profile、不制造新胜利），原Replay/pause/speed/slider Home/resume从0自然到6178，分别1×/2×，每次 wall cap `max(180,6*(6178/60)/rate+30)`；原记录与domain前后SHA/结构、3D frame/actor/event截止不变验证。稳定后同owner-private Site仅必要一次更新。资产接口/所有权不变，角色/atlas/GLB/Blender/generator由独立资产作者负责。
