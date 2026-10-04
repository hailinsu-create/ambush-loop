# PR15 完整smoke模态fixture接续

2026-10-04。a05正常六关13波已封，完整smoke actual54/ERROR1/SCRIPT0原日志与source固定保留。源码确认smoke在原yard简报仍打开时直接open_journal，Title已有_top_modal锁，所以原fixture的成功预期与现有产品规则冲突。此片只修共享测试顺序：原open_journal必须拒绝（新增负向断言）→原_on_back关闭简报→确认无顶层模态→原open_journal允许并保留电台正文断言，随后跑完整smoke。不要为测试开放生产Title锁、不重开已闭TitleQA、不要称未运行的后段通过。

单片测试源码固定SHA后以官方4.7.2/run_isolated_test.sh/fresh Guard H运行；如后段仍失败，先封实际source/exit/error/log/触发，再判fixture或prod，独立修正/新SHA，不用阶段门green取消原失败。不重复a05正常13；a05记录与新消费者SHA分记。之后六新原件实际3D，再FX/A3与最终完整candidate。唯一主集成共享测试单写，资产/R5不动，Draft普通push授权、不merge/生产/height/G，网页GPT PLAN/REVIEW unavailable，耳听设备后置。

首test源码9f46 H actual54/E1/S0在SMOKE_BACK_DID_NOT_CLOSE_BRIEF_MODAL停止，拒绝journal断言已过但一个headless frame未等原0.15s dismiss tween完成。先封原失败，修为等待实际原tween.finished再判断，无生产锁/时间改动；重新固定source后跑完整smoke，后段仍未验。

b62固定完整H在SMOKE_RADIO_NO_ECHO_BREATH actual62/E1/S0停止；此前原journal/launch及touch与五关reference波通过，不称whole green。触发在radio刚进SCOUT，旧assert要求live watch echo pending=true；新scope cdb只让实际当前wave ALERT pending，SCOUT是明确全关教学预览，因此源码反例已证实旧fixture过期。保留原62整轮，只改共享assert：必须SCOUT+echo全关教学前缀+live pending=false；原关卡5.2总表与人数/routes/gun/pad保持。新增有界smoke_contract_test直接调用原launch-modal及radio-contract函数，Guard/官方H/固定新SHA，供精确修后验证；完整smoke末段仍未验，最终FX候选还须自己的完整smoke。生产title/timeline/main不改、不重开已闭cdb范围。
