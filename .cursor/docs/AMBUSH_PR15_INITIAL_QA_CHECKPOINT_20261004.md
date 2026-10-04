# PR15 INITIAL 独立QA checkpoint

2026-10-04，交父端游戏QA使用；QA可现在并行只读核INITIAL正常旅程/六新原件/静态教学/escape，不等待FINAL FX。主集成继续唯一写main/input/HUD/presenter/ViewState/replay/runtime-loader/shared tests；资产工作者继续拥有制作源/build_yard_kit/角色GLB/Blender/atlas/生产asset manifest，接口保持R5/20骨/socket/3LOD/52语义，不接未验WIP全量。

## 固定来源与证据

| 范围 | 固定source SHA | 已推送evidence SHA | 实际作者结果与限制 |
| --- | --- | --- | --- |
| INITIAL自然六关13波、credits | a05fa959093ef5b6733466091a04fbb46647f97b | 4d0f1b3de9f6e5f302a10e44c63d01df852210b7 | 官方4.7.2单PCK、fresh原Title一路native、1193/0 actual0 E0/S0；credits原生wheel0→81、返回Title，386inputs、92图hash/11图看；不是陌生玩家playtest或FINAL |
| INITIAL记录结构 | 同a05 | 同4d0f | metadata15807/0 actual0 E0/S0，仅builtin bytes_to_var，无autoload/replay/3D；初始15807/6 actual1保留 |
| 全关静态教学/预览/总表/静态建议/背景 | fcf40a97606c148ec6dcb87a2b20dfa39100458e | a3df5281768973156e033d3168b7552ab5d763e9 | 负H138/R141各80fail actual1→fixed H138/R141各0actual0 E0/S0；26 display fixtures不是实战 |
| 原实际逃逸Intel context1 | 877decb0ea14d6c3c0a833e4d6948c7ee549514f | 4b82fbf0acba15a0de9fed35bd60d7d8003b465a | 负H18/R21各8fail actual1→fixed H70/R73各0actual0 E0/S0；radio实际第三波0.5s入场/15.9s逃逸、retry历史第三波，旧/坏context中性回退 |
| smoke测试fixture有界修正 | 8906ff5d595a08e614fb02c8d19277867b00e865 | 2d4b90b4809554b430682029483b6ec3f2e43aff | 原launch-modal与radio-SCOUT函数Guard复跑actual0 E0/S0；**full smoke未通过** |

正式INITIAL PCK bytes23493668 / SHA256 **313cf1b607f15ce88909bc01674da509c600110d032b8dc450b40e3fffa3fb9b**。完整构建/命令/实际exit/Guard/source/tree/截图/自然cfg复制hash在[INITIAL报告](AMBUSH_PR15_UNIFIED_BASELINE_20261004.md)及[evidence manifest](evidence/20261004-pr15-unified-baseline/file-manifest.json)；166 manifest entries都已tracked/hash复核。核心a05 H装备66/0、生命周期30/0、timeline67/0、旧2D-FX lifecycle30/0、controlled reference campaign14028/0各actual0 E0/S0，分别属于自己的范围。参考授枪/直接tick/vacuum不是正常旅程，旧2D效果不代完整3D FX。

六份新原件是该fresh正常旅程自然保存的原始bytes，无升级/重写。gzip无损副本在`evidence/20261004-pr15-unified-baseline/native-all/native-player-{level}-record.bin.gz`，完整raw SHA/bytes/attempt/clock见[原producer manifest](evidence/20261004-pr15-unified-baseline/native-all/boundary.json)。在独立QA目录解压，先核raw SHA再运行；不得覆盖历史normal包，也不得把event挂到current run_id。producer原件：yard terminal4126、warehouse8317、pump5376、railcut6640、depot6313、radio6798；raw SHA表见INITIAL报告。各WON与radio-credits-return自然cfg/settings是复制件，不写回或seed。a05新warehouse实际mine1；depot/radio没有mine/trip实际触发。railcut实际K98末弹同枪repack事件原身份和clock保留。

## full smoke实际失败和testfix复跑

a05整轮actual54 E1/S0：简报仍打开而fixture直接开journal，现有产品顶层锁拒绝。9f46f8eed22d9a1dd41720c9fdbc1e2b3455472e只等一帧仍actual54 E1/S0，原Back动画未结束。b62df6cecddb9e3f69ae08a0ec718c88b69f3cb2等待原tween.finished后跑完整旧reference链到radio SCOUT，actual62 E1/S0停在SMOKE_RADIO_NO_ECHO_BREATH。原SCOUT显示全关教学预览，实际echo pending=false；8906只修原测试预期、生产Title/timeline未变。有界复跑不是整轮green，末段/FINAL source完整smoke仍待。[完整原失败/有界命令收据](AMBUSH_PR15_SMOKE_FIXTURES_20261004.md)。

## INITIAL新record真实3D当前边界

原a05 PCK+只读yard真实R **4404/1 actual1 E0/S0**；整份2x原0→4126、258实际callbacks、elapsed172897ms只是有效子段，唯一nativeRight失败使整场不通过。短诊断 **4140/2 actual1 E0/S0**，两箭头实际XTest logicalRight4194321/Left4194319、physical0、pressed非echo、GUI focus=null，scrub2971不变。重写Left断言要求先前Right-6并等于原seek，防两键均无动作的弱oracle过绿。原PCK/source/raw未变。开发parse1/停止143/重复clock误选早帧H5022/4均保留，last-frame-wins修测试oracle，不称生产故障。

共享synthetic seam负例source **83f29577af1026177ebb668808deabf717c0a25c** H26/4actual1→生产最小箭头fix **d9c67256545a227c78bf5c3264818b8ad86b2c78** H26/0actual0 E0/S0。physical优先，缺physical时仅Left/Right logical fallback；±6、pause/clamp、modal gate/其他shortcut规则保持。真实R复验正在独立新PCK执行；未完不称通过。新PCK bytes23497556/SHA256 **b133a1c8aac17fb46ba1455ba1585768c65bb82fbca5d5c0131f7d8004a731ab**，import/export各actual0；consumer_d9c与producer_a05分列，不拿新绿补a05最终接受。

因此六新原件可立即并行QA只读，六关实际3D整矩阵作者尚未通过。优先INITIAL原source/PCK/原件验证；箭头P2独立复验新d9c，不重开父端已闭cdb/392/旧railcut/其他历史scope。完整3D记录消费者、FX-A1/A2、A3优化、FINAL同source全门/新normal13/新六record、可追溯APK继续待完成；耳听/模拟器/真机按用户顺序后置。没有设备性能或全计划通过声明。Draft普通push，不merge/生产/height/G；网页GPT PLAN/REVIEW unavailable。
