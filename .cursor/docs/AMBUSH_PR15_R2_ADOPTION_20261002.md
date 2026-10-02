# PR15 R2 角色候选采用切片

日期2026-10-02。状态：实施计划；已只读检查候选，尚未迁入。当前优先关闭独立QA四项P2，随后历史HUD与本方案。遵循完整执行顺序v2和单写者边界，不整体合并WIP。

## 来源和边界

资产提交 `dc83a730542d6848b8860056e921e9156b7140c6`，证据提交 `812261a0d7c29446ab631108feec5389cec2950b`；继承R1 `0242c983e8ae972b58b4f7afe9d08084b8f421c6` 和冻结WIP f7c30f9。读取R2 [README](https://github.com/hailinsu-create/ambush-loop/blob/812261a0d7c29446ab631108feec5389cec2950b/ambush_loop/ArtSource/v2/actor_acceptance/README.md)、catalog_candidate、contract和二次导出报告。

只读复核：对 git archive 固定副本运行 validator，实际22/51、零违规、退出0。其余51/51 raw+semantic二次独立生成一致为资产作者证据，本作者未重跑生成器，不把只读二进制检查写成独立再生成。共享 actors_manifest 仍R1；不能用该旧台账校验R2。当前已迁入的R1静态装备证据保留，采用R2必须另有新来源和验证。

资产作者独占 build_actors、actors.blend、角色/武器/工具生成和atlas字节。本作者只将候选已交付文件按清单原字节迁入、维护运行台账/loader、角色呈现/历史记录和共享测试。yard_kit源/旧atlas/旧18GLB不碰。未知或未验收身份拒绝或明确中性回退，不新增敌人规则。

## 接口与顺序

1. 按R2候选台账逐项校验51GLB/3PNG；分离候选技术可用、战场验证、最终美术批准的状态。登记7角色三LOD与15装备双LOD，保留角色枚举0/1/2和patrol/flank/sneak/echo→radio映射；装备旧别名只由WeaponCatalog既有定义映射。
2. 外部材质槽 v2_actor_atlas 沿用独立lazy material，normal0.4，ORM G/B；yard和灯槽保留。导出PCK在空目录检查全部资源与manifest，人物实际骨架/skins/12clip按导入对象验证。
3. 只读模型实例在同一逻辑脚底/朝向下替换代理；禁止添加碰撞、导航、LOS或模拟写入。live与replay共用平面快照接口。
4. 动作使用记录时间取样，不能让AnimationPlayer自动前进写模拟。idle/walk/run/aim/crouch/crouch_walk/haul由台账设循环；fire/pickup/death/deploy/hit单次clamp。起始时间/稳定attempt-wave-actor身份和fire/hit/death等事件接缝需测试前后seek、暂停、2×、换波和重试；缺字段不能借活体补写。
5. hand.R/hand.L局部 `(0,.035,0)` 与X+90°；枪口读实际marker global transform。工具用grip校正，carry读support_hand。pickup/deploy/haul收枪，death隐藏/掉落行为独立记录验证。haul是包carry样本，不能冒充尸体拖拽；其他枪族overlay未通过，不扩大M1样本结论。
6. 角色LOD切换保持历史身份/姿态、挂点和事件取样，不更换逻辑对象。实际场景旋转/近远/遮挡/夜色/HUD与完整多波渲染后才写战场接入通过。

## 验收门槛与未验项

固定源码、隔离run ID、真实退出码/完成标记、日志/截图/导出包哈希分别记录。候选20骨、原地12动作、单surface、预算8000/4000/1800（角色）、3000/1500（枪）、2000/1000（工具）。作者6300蒙皮样本和462捕获只代表技术采样；本作者已看优先步枪侧面和工具fit，仍有脸部卡通感/肩肘接缝、自然步态/死亡和其他枪专用握持未验收，不称A1.2最终美术完成。

先完成历史HUD反活体污染，然后接角色/动作；完整院子、声音45cue、全3D回放、A3云端优化、五关主题和完整APK继续按v2。中端30FPS/可选60FPS是真实设备目标，当前云端软件渲染不证明；全部计划制作与云端验证后再安排设备。网页GPT PLAN/REVIEW：unavailable。
