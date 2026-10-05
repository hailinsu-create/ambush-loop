# PR15 拾取事件文字独立片

父端P2-DEPOT-LOOT-1原fixed3b只读4/1 actual1/E0/S0；作者先固定自身负向，保留原depot SHA ec232057b98e04262fd60f4e44933c7545f396ded83be68a05cdea26b4ebb3e0及mine事件f3bbcc8550a908a5e5740cfa16df238b:1:38。只修BattleLog中央formatter，从原payload.kind/amount输出物品与数量，不能改库存/拾取行为/原event/time/identity，不能混RESULT-1或a794gate。

原receive_item firearm amount是携弹量；工具/loose ammo/radio_part是事件数量。已支持十枪/六类枪族、刀、六typed ammo、ammo、mine/grenade/decoy/radio_part要按原kind称呼，radio_part仍称电台零件，不能借后端decoy转换改写事件。未知类型显示原标识的中性物品，旧记录缺kind/amount用明确未知占位，不能无证据声称弹药，也不max到1/填当前武器或当前run。

新的guard只读原depot/mine/ammo、全catalog与未知/缺量/零/负量边界；源hash/events/state不变。ALERT与REPLAY文字入口/历史绑定源且故意foreign live log污染，ItemList/状态定位/RichText fallback一致。使用原_record_time，保留本地与global双时间。R仅有界历史文字截图与original focus callback，不称新normal/3D全record/库存修复。先negative→最小修复→固定H/R/实际exit/PNG/hash/目检→普通push，原live片独立QA保持。完整samecandidate/FX-A3、艺术/耳听与APK/设备后置；资产制作归原作者/R5不变，Draft不merge/生产/height/G；网页GPT PLAN/REVIEW unavailable。
