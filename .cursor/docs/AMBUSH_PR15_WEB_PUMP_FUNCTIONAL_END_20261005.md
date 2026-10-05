# PR15 pump 有界功能 / 同私有 Site v3 END（2026-10-05）

本片实际完成原 profile 的 pump 新自然双波/WON、先封原 bin、railcut 原交接首次教学/解锁存档/同源刷新，再对该原 bin 完整1×/2×自然回放，随后仅一次同 owner-private Site更新。游戏代码 `8532c4c3084d1a5672bbe28dc96e1c02522a8f05` / tree `45b88482e867ddc8e6b0bfdaad4db32e9dc1ca85` 保持；生产/资产未改，PR15仍Draft、不merge、无APK。producer与交接证据固定提交 `819893b86235524943035b3eee4955b33773586e`，完整前半片事实与方法负例见 `AMBUSH_PR15_WEB_PUMP_PRODUCER_END_20261005.md`。

## 原 producer 与进度

原 profile `/workspace/.ambush-loop-env/web-fresh-native-dab-20261005`、原 `http://127.0.0.1:12815/index.html` 无fixture query，QA-v2原Title读取cfg/settings/public checkpoint全文SHA均exact actual0；next pump/seen_pump=true，不清storage/教学。原Continue新刀具SCOUT attempt `f9bfc48ef5288e4bfb4305a942b73546`，原世界鼠标取枪/补弹/搜刮、1/2/3+A/D部署、原镜头按钮露出目标，两波SCOUT→ALERT→SWEEP及原撤离WON，**actual0 / 396.82748366097803s / cap900s**。无teleport/强推phase/tick/policy，无重复warehouse。

原八字段 bin **11,203,052bytes / SHA `a0e5b232a001671ead8156e97e29f902796f81cd7669d925d66045064d5709cf`**，schema2、terminal6178、820frames、34events、原win；先归档再换场景，122 browser原输入allTrusted/122 engine inputs。原WON下一关→railcut刀具preview/交接→原CTA/首次 **2页**教学→Esc暂停Title/任务解锁→same-origin reload→Title Continue新刀具SCOUT无重复教学→安全Title **actual0**。两个cfg全文/public checkpoint字符串刷新前后相等，next railcut、cleared=[yard,warehouse,pump]、railcut unlocked未通、depot/radio locked、complete=false。原两preview attempt单列放弃，未算railcut producer。

初次driver预算None在首个Continue之前 **actual1**，加载脚本与receipt原件保留；修初始化后沿用同一已选monotonic900总预算，没有重置延长。producer自然END且port closed/process absent，但close工具未给最终PTY退出码，仍明示unknown，不借consumer0补写。

## 同原记录完整回放

producer与存档交接结束后独立冷consumer；隔离新 profile `/workspace/.ambush-loop-env/web-pump-cold-consumer-20261005` / `http://127.0.0.1:12816/index.html?fixture=pump`，一次性装入刚封八原字段，设历史WON只展示原Replay入口，**不表示新胜利**。setup仅disposable profile标教学，不写原campaign profile；后续只有只读RPC。全程由原ReplayButton、pause/speed、实际可见滑条+Home、resume从0自然到terminal，未用set_tick补终点；终点后原Left/Right保持暂停、Space原返回WON。Space原返回代码可能只保存disposable consumer settings，未使用原campaign profile。

| 独立 whole | actual exit | 原resume→自然terminal callback wall | controller wall | cap | 观察帧 | 终点actual3D checks |
|---|---:|---:|---:|---:|---:|---:|
| 1× | 0 | 367.1996s | 372.3180356719822s | 647.8s | 783 | 15/0 |
| 2× | 0 | 183.8657s | 188.99394560500514s | 338.9s | 397 | 15/0 |

cap公式 `max(180,6*(6178/60)/rate+30)`，各tick0→6178、自然停止；所有观察帧tick单调、view_tick等于tick、source attempt与rate一致。各前后原record SHA、domain结构不变，events/frame校验无失败。两原终点PNG已实际看；34 engine/34 browser输入allTrusted，page/console error/GL非法0，原4条GPU ReadPixels warnings保留。终点3D checks含身份、level、wave、seq、recorded_phase、事件截止、保存位置和20bone骨架；**没有把终点15/0说成每一像素/每一骨架帧均已验**。

回调wall比1.997107671523291；原记录时长102.96666666666667s，实际1×367.2s，软件WebGL实速仍未达到记录时长，本片只认功能，不认30/60FPS/A3/设备性能。运行期间独立Git/包校验与5s生产transport打包是环境工作，wall不当纯性能指标。不是旧warehouse再播放，消费者来源明确属于新pump bin。

官方4.7.2独立冷consumer export **actual0 / ERROR0 / SCRIPT_ERROR0**，PCK **49,310,308bytes / `6aa57dcd246838580185e09c842b61e95c4adb3dbc4dbc3957320890a6446e5d`**。PCK全部payload MD5校验；production相较只新增桥compiled/remap+原pump bin，改project.binary/uid_cache/class cache排序，53完整raw class块相同；production其余payload逐字节一致。完整Title保留，无资产生成/Blender。该PCK是声明QA包，不是生产bit-identical包。

## 原 bin 只读契约补核

所有浏览器END后单独原生headless只读审计 **actual0 / 12,595checks / failures[] / ERROR0 / SCRIPT_ERROR0**。自定义非破坏脚本不删除测试档，仍以唯一私有user://和实际 `TEST_STORAGE_ISOLATED` guard保护；不是破坏性test entry或fullsmoke。

820保存frames逐项核schema/attempt/wave/seq/全局time与纯ReplayPlayer/ViewState来源、全部actor原值、只读frame及事件截止；34原events身份/顺序，两波events **16/18**。实际 **1次 local tick回退**、全局clock始终单调，源八字段load和全部offline selections后原 `var_to_bytes` 及文件SHA不变。phase counts：wave0 SCOUT360/ALERT43/SWEEP185；wave1 ALERT115/SWEEP116/WON1。这是真实新双波原bin的纯reader契约，offline set_tick只在本只读审计内，不算实际whole或3D renderer验收。

`source14-final.json`实际重新计算14原策略/数值源码size、SHA与Git blob，全部exact actual0；8532游戏树保持。没有借UI布局变更调整胜负或数值。

## 唯一一次同 owner-private Site更新

用户已授权稳定candidate后一次必要同Site更新。Sites技能/本机helper脚本和cloud scripts资源不可用，已按该技能troubleshooting保留既有Site，沿用前片同Git credential-stdin/commit/push/readback/archive流程；密钥仅内存+隐藏stdin，不写文件/argv/输出。官方Sites API可调用。没有新站、preview、public/ACL/付费更改。

选本作者先前已封的官方完整Title **release**（导出actual0/E0/S0），所有9文件先重hash；原production PCK **38,090,812bytes / `d3fa7380c74dd9bb49447fd56db45b5a37e20ae16c871b8a89d5b4153a07edfd`**。使用未改packager文件SHA `00fb0d067e52a879dcca27d04b5f85e7ba11ed584af3aabf5bc90c7b6b1b7118`，分片重组==原PCK、gzip解压==原WASM；inline/engine JS node --check全actual0、12 runtime files **48,481,801bytes** 且各≤25MiB。仅transport封装，QA桥/bin、ArtSource、证据、profile未入Site。

Site source commit **`87cccf2152ce112c36a704efa332f16e7692867b`**，normal push/remoteSHA exact actual0；archive **48,496,640bytes / `0577186ecdf9c3de56ddab4e017b35fa4ce99f9875c5a6588fb4cd1e89cd167e`**，13files=hosting manifest+12runtime，每payload==提交字节。rollback保留v2源aa19/dab及原version/deployment IDs。

一次 `save_version_and_deploy_private` 原生终态 **succeeded**：

- project `appgprj_6ac2e89b4db08191b308c175371ee7c6`
- version3 `appgprj_6ac2e89b4db08191b308c175371ee7c6~appgver_563625d651a08191bc60097376cd55f7`
- deployment `appgdep_6ac381f17588819196e95158ade5bb39`
- 原URL **https://ambush-loop-game.lning791548.chatgpt.site**

独立privacy readback仍active/owner/custom、ACL revision1、一owner、groups0/external0，未变audience。终态有URL，未额外status轮询/部署/线上浏览器尝试。**API部署成功不等于正式origin浏览器验收或onlineReady**；既存正式origin代理CONNECT403限制保持待办，不重试绕路。

## 证据、END、未验与下一包

前半片 `evidence/20261005-pr15-web-pump-producer/manifest.json` 47files/19,578,581bytes，固定819893b；后半片 `evidence/20261005-pr15-web-pump-consumer-site/manifest.json` 48files/3,899,677bytes，包含逐文件size/SHA、全部加载controller/桥/原命令receipts/whole观察输入、两终点PNG、原bin只读审计与Site隐私/deploy/精确archive收据，引用同原bin不重建。producer14与consumer2原图均实际逐张看；不包含旧独立QA丢失PNG。全部ownerGodot/Chromium/browser/HTTP已END，ports12815/12816closed、live engines0；consumer实际PTY0、native audit0；既存defunct非live。Git工作树应以本片正常push/readback的最终docs SHA为准。

最终辅助检查：`git diff --check HEAD^ HEAD` 在证据提交4b5449f实际 **2**，唯一报告是原HTML提取的 `site-inline-1.js:138` tab空行/EOF空白；该原始JS和SHA证据保持未normalize，`node --check`已actual0。以明确pathspec排除此一原始artifact的 `git diff --check 3a0e8ab... HEAD -- . ':(exclude).cursor/docs/evidence/20261005-pr15-web-pump-consumer-site/site-inline-1.js'` 实际 **0**；`git diff --name-only 3a0e8ab... HEAD -- ambush_loop` 实际0/空，生产源码未改。没有把整个raw证据提交的whitespace检查称全绿。

父端独立UI QA END10:02:32.356684 UTC及其包SHA `91a9c573d9cc21711a824a77adf5b28e3d5756f7243ec56ed049ae1fcae9e934`按父端交付单列：旧中心fail→candidate10482、no-touchdesktop72、PageUp18/0、native200+landscape68/0，没有新产品fail；**原143/1仍保留、普通PCK作者+128B未解、横屏wave0一PNG被覆盖仅hash**。本作者没有本机解包或复验该父包，不把各scope相加、没有猜padding、更不称所有像素完整。

未验：railcut/depot/radio新producer（后7波）、yard本新schema完整whole、六关共同最终candidate/正常13波、全6×1×/2×、完整fullsmoke/FINAL、实时速率/A3、完整世界触控取消与锁门分支、正式origin浏览器、普通PCK+128B、设备及可追溯APK。已验pump不等于全计划完成。网页GPT PLAN/REVIEW unavailable。

下一代码包：原profile保持next railcut/seen=true，先固定8532与14pin并实核两cfg/public checkpoint，单窗口原Continue刀具新attempt、原数值/原取枪部署两波自然WON，先bin再depot交接教学/保存reload与同新原bin有界whole。沿用900 producer与whole公式，不重做warehouse/pump，不将preview拼入新attempt。窗口现已空闲可交独立只读QA；需要引擎的QA与下一producer明确串行。

可安全并行的独立只读包：8532后3关 authored route/cover/装备/朝向数值与原driver策略核查、producer/consumer/production三身份与缺项文档审阅、两个manifest与原binSHA复核；禁止同时起游戏引擎，普通PCK差异只做源/目录条目比较，不预设padding原因。资产作者继续只在独立制作分支交付验收过的源/生成提交；接口仍是版本化manifest/loader、骨架/clip/socket/LOD与原记录asset revision，不重跑或改ArtSource/v2/build_yard_kit.py、shared atlas、GLB/Blender输出。主集成作者持main/presenter/view_state/replay、共享tests、runtime manifest/loader/PR15；此片没有更改资产接口或全并未验收handoff分支。
