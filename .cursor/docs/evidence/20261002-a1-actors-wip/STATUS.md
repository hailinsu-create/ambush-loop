# 角色与武器草稿：暂停时快照

2026-10-02：用户要求写入 Notion 交接并暂停，后续由 dot 统一安排。本目录只保存暂停前已经产生的初次导出记录，不是验收报告。

- `build_actors.py` 初次 Blender 4.3.2 执行退出 0，输出 `ACTOR_KIT_EXPORTED 22`。
- 清单包含 3 名队员、4 类敌人、10 枪和 5 工具/补给，合计 22 个资产、51 个 LOD 导出；声明 20 骨共同骨架、12 动作，导入后实际动画/蒙皮尚未核实。
- 英雄 LOD0 为 9,900–10,420 面，每模型 1 surface；敌人 LOD0 为 9,908–10,376 面，超过原计划 4k–8k 预算，需后续调整。
- 日志有 18 条 `Mesh ... is not valid, and may be exported wrongly` 警告，以及 Draco 可选库缺失信息。没有启用 Draco。未排查这些告警，不能称源校验或引擎评审通过。
- 未进行 Godot 导入、360° 画面检查、动作/手枪口/足底/LOD/回放验证。材质加载器仍只绑定旧 yard 图集，角色图集未接入。不得直接替换正式资产。
- 清单引用的 `character_review_capture.gd` 是预定入口，尚不存在；台账里的 `status` 仍为 `exported; engine review pending`。
- 停止时没有持续中的 Blender/Godot/模拟器进程；没有开始本批游戏接入或修改玩法代码。
