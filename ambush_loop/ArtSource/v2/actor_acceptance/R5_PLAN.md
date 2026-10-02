# R5 动作与交互资产切片

用户授权继续刀刺、投雷、诱饵、拖尸与必要接触修整。基线 c4c21708a2e06d3a7eaefbb8ab6bfeee31f5073d，独立分支 fix/asset-actors-dot-20261002，源仅 dot 单写。

占用 build_actors.py、actors.blend、actor_acceptance/、台账51GLB；不写共享 manifest、loader、main、presenter、view_state、replay、共享测试、yard源/atlas。使用既读 paperroute-game-build 的确定性源/实际Godot像素检查流程。用户资产范围优先，规划只放独立资产目录。

先核对冻结实际事件：melee会发 fired_shot；岗哨技能直接 knock_out；手雷立即创建、0.18s初次飞行并之后弹跳；诱饵立即在指定点出现；haul跟随LootPickup且偏移是屏幕轴(0,14)。历史表现接口不含这些完整交互状态。主作者负责时钟、历史事件、取消、遮罩和集成。

本片增加可选工具就绪/刀刺/投雷/诱饵放置/拖拽抓取循环放下/俯卧尸体/死亡候选。保留旧52动作、20骨及所有旧挂点。尸体交互挂点用现有骨的BoneAttachment定义，不加骨/玩法。通用手雷不能宣称覆盖stiel/mills/mk2型号。

验收：独立二次生成raw/semantic一致；全LOD预算与蒙皮地面/接缝；旧52动作语义兼容；真实Godot实际播放、近远与四方位、手/工具/成对肩部接触、暂停/2x资产样本；可追溯报告与关键帧。只修实际缺陷；近脸、闭手、机械reload保持品质限制。不得把独立样本通过写成实战/A1.2全通过。完成后固定源SHA与证据SHA交付，不merge/deploy/device。
