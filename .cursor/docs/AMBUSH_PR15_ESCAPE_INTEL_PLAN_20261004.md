# PR15 真实逃逸情报独立修复计划

2026-10-04，接静态教学语境片之后执行。实际2da原radio第三波reference已证实：echo敌5 spawn local30/global744，escape local957/global1671，同attempt/wave2的seq43→47；当前FAILED错误写5.2s出发，hint错误写主路巡卫南闸，重开建议把local15.95减总表5.2得到10.8秒并承诺“改一处就能赢”。原文件7737780 bytes/SHA37edd8a4cd40e992b0ba48d7a57bd4e9ca2f4f2ed00cdfc38c24ffbc857d29c3已封存dev-2da；fixture是原授枪/cover snaps/directticks/vacuum/合法SWEEP收回部署，非normal输入。收回保留枪械是原规则；2da一条卸枪断言是测试错误保留，不改库存规则。

本片只修真实情报显示来源，保留原BattleLog事件/时刻/路径/伤害/库存/phase/wave规则。原escape回调记录后，从当次BattleLog已有spawn与escape，严格匹配attempt/wave/actor与事件seq/id，给新Intel记忆追加显式schema元数据，保存level/原attempt/wave/入场与逃逸local/global/playback时刻和event身份。IntelStore.add_path新增可选末参数，旧调用仍可读，旧record bytes不升级，不以current run补旧身份。hint/FAILED行/SCOUT记忆只读保存身份；真实echo/alt/flank/sneak/main路线中性陈述，不保留Payoff的硬coded5.2/3.8在事实行。

严格context校验是显示契约：未知版本、缺字段/非Dictionary、负时间、逃逸早于入场、错actor/attempt/wave、错id/seq、未识别route、外关level只给中性旧情报回退，不猜currentwave/currentleveldelay。合法context必须来自原两个事件复制；重开begin_attempt清日志后仍显示旧wave/0.5s/15.9s，不重绑新attempt或同actor/seq。建议仅检查对应路线射界，陈述历史时刻，不造获胜保证或减总表的“应在N秒前”期限。

固定负向H/R先复用可达原第三波逃逸→原FAILED/卷宗/重开SCOUT，保存原事件和reference bytes/hash、实际源/退出/隔离guard/PNG核看；覆盖IntelStore旧8参数、合法context、坏context/同actor外源、稀疏旧record、max5与path复制边界，text refresh/state/ammo/HP/record不变。修后同测试固定新SHA H/R，逐项报告旧fallback、原legacy2D有界显示覆盖（未跑不称通过）、PNG/真实事件与旧bytes只读；不是正常13波/同candidate/newrecord完整3D/FX/A3/设备验收。

必要时更新现存smoke关于旧record推测总表时间的断言，旧数据可读不等于保留已证实的错误推算；不为green扩大战斗规则。新增回放事件聚焦/装备冻结等已有约束保持；完整相关smoke属于随后[统一候选清单](AMBUSH_PR15_UNIFIED_CANDIDATE_EVIDENCE_PLAN_20261004.md)，先准确列本片实跑与待跑。

R5资产/源/GLB/atlas/Blender/制作脚本/生产asset manifest所有权保持；唯一主集成代码作者写main/IntelStore/共享测试，父端固定QA可独立只读并行。Draft普通push授权，不merge/生产/height/G、不自行astra。网页GPT PLAN/REVIEW unavailable。耳听/设备及可追溯APK按完整计划后置。
