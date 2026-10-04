# PR15 完整smoke模态fixture接续

2026-10-04。a05正常六关13波已封，完整smoke actual54/ERROR1/SCRIPT0原日志与source固定保留。源码确认smoke在原yard简报仍打开时直接open_journal，Title已有_top_modal锁，所以原fixture的成功预期与现有产品规则冲突。此片只修共享测试顺序：原open_journal必须拒绝（新增负向断言）→原_on_back关闭简报→确认无顶层模态→原open_journal允许并保留电台正文断言，随后跑完整smoke。不要为测试开放生产Title锁、不重开已闭TitleQA、不要称未运行的后段通过。

单片测试源码固定SHA后以官方4.7.2/run_isolated_test.sh/fresh Guard H运行；如后段仍失败，先封实际source/exit/error/log/触发，再判fixture或prod，独立修正/新SHA，不用阶段门green取消原失败。不重复a05正常13；a05记录与新消费者SHA分记。之后六新原件实际3D，再FX/A3与最终完整candidate。唯一主集成共享测试单写，资产/R5不动，Draft普通push授权、不merge/生产/height/G，网页GPT PLAN/REVIEW unavailable，耳听设备后置。
