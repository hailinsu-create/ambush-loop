# PR15 P2-ESCAPE-CONTEXT-1 波上界与双时钟

2026-10-04。父端独立QA fixed877：min3/2actual1、真实3D49/2actual1 E0/S0，两个坏context被确认历史事实。radio零基0/1/2只有三波，context/spawn/escape都改wave3并event_id同步仍被确认第4波；同原attempt/wave spawn local30/global744/playback747→escape local957/global1671/playback1675，实际Δlocal927/Δglobal927/**Δplayback928**，仅escape playback改747仍通过。不能硬等双时钟、固定+1或固定offset。原schema1 context、schema2 event、continuous playback2三个版本不同；旧BattleLog1/旧8args/缺未知context继续中性，不升级或套用当前live信息。

优先在当前代码（IntelStore仍877 validator）以封存877实际radio原件只读复制复现H/R，再只改validator。wave上界从context保存level的原LevelDef.wave_count取得，不从当前main.level/run/wave借值，不猜定义时间。明确continuous schema2同attempt/wave至少Δplayback>=Δlocal；原global-local同offset检查保持，额外phase boundary可让playback多于simulation。缺/未知playback schema不能证明新连续域，neutral fallback；原builder/reader不升级历史bytes，不改spawn/escape/模拟/身份/retry。

共享Guard新test：原valid第三波0.5/15.9、上述两bad/source bytes不变；合法minimum927/原928/更宽phase ticks，短926/plateau/backwards，六保存level上界/foreignlive、旧8args/旧event1/missingunknownschema；实际3D原advice label/result API中性/原world/actor/live/sim不变、原物理PNG。修后固定H/R及原escape reference测试保留真正第三波/retry/identity/foreign collision；旧scope/fcf静态教学limited pass不重开。

父端fcf静态教学limited QA：旧29/22→29/0、实际3D40/0actual0，四图看/两包封存；未提供额外包SHA不补造。只归fcf范围，不涉及INITIAL箭头/FX/FINAL。

原长轮已自然结束29976/0actual0 E0/S0 consumer_d9c/producer_a05，证据a323c3ae19dea041d69d65f197777502c170e934，未kill/重跑；自有116实际关闭0。FX-A1a正式183 H5607/0+boundary45/0actual0已交f012，生产源模块/原R/资产不改。此P2完成后A1b/A2/A3/FINAL全门/newnormal13/new6record/fullsmoke/APK继续；smoke54/62与bounded8906actual0保留。Draft普通push、不merge/生产/height/G，耳听设备后置，网页GPT PLAN/REVIEW unavailable。

已实现并作者有界验证：生产3d30b1309ebcf09a01d17e344b4d900942b67bca、正式f0ed44311775fa87ee63ebb911c7b11e12e65ab1，负3/2与有效R18/4→H57/R82及原reference70/73各0actual0 E0/S0，实际原Δ927/928/第三波/retry保持；正式8图看/核hash、原bytes只读、开发失败/遮层保留，自有117最终实际关闭0。详[报告](AMBUSH_PR15_ESCAPE_CONTEXT_BOUNDARY_20261004.md)，独立QA待，不拼FINAL。
