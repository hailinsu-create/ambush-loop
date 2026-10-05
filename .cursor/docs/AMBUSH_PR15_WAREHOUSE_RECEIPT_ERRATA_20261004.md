# PR15 warehouse 原收据标签勘误

父端核对8149c5d6/b27发现两份原收据标签写错：`evidence/20261004-pr15-remaining-journey/run-b27/run.json.classification`与`validation.json.native_run.classification`的`pump3pages`应为`pump2pages`。实际玩家报告、原生PNG只有pump page0/page1两页；warehouse正式报告及规划索引此前已经正确列两页。只有两页计为已验。

保留两份原收据原字节及84文件历史hash manifest，不重跑warehouse，不改此前实际270/0、exit0或图/录像/进度证据。此文件是追加勘误；后续分类使用实际两页，父端独立QA与pump继续工作保持。不能由该标签推导第三页存在或通过。
