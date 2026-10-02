# Ambush Loop 工作说明

- 2026-10-02 本轮已按用户要求交接并暂停，后续由 dot 统一安排。先读 `.cursor/docs/AMBUSH_HANDOFF_TO_DOT_20261002.md`；WIP 人物源含未处理网格告警，不能视为已验收或自动继续施工。

- Godot 工程在 `ambush_loop/`，版本固定为 4.7.2；先读根 README、`ambush_loop/README.md`、`.cursor/docs/PLANNING_INDEX.md` 与其中的当前有效规划。
- 当前产品设计与阶段优先级以 `.cursor/docs/AMBUSH_DESIGN_V2_20260928.md` 为准；旧总计划保留工程/发行质量门槛。设计提案不代表代码已实现；高度等新规则必须独立切片声明契约变化并验证。
- 当前实施顺序以 `.cursor/docs/AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md` 为准：用户要求先完成全部资产、六关接入及云端验证，之后再安排模拟器/真机；替代 PR #14 中设备检查阻塞生产的顺序。中端安卓 30 FPS/高配可选 60 FPS、暮色工业院落和 360° 镜头为目标。表现与回放不得改写模拟状态，未测真机不得称通过。
- 每次规划必须保存为 `.cursor/docs/` 下带日期的文档，更新 `PLANNING_INDEX.md` 的有效入口、替代关系、当前状态和下一步，并通过本游戏仓库的分支/PR 流程同步 GitHub。区分提案、已确认、已实现和已验证；保留历史规划，不混入未验收代码。只有核对远端提交后才能报告已同步；失败时明确标注仅本地保存。具体内容要求见规划索引。
- 修改玩法遵守 `SCOUT → ALERT → SWEEP` 与冻结计划契约。不要顺手加入第七夜、FOW、联网或大规模战斗重写。
- 运行会清理测试档的脚本时必须走 `ambush_loop/scripts/run_isolated_test.ps1` 或 `.sh` 包装器，先确认隔离守卫通过。不能直接调用 `smoke_test.gd`。
- 每次只做一个可验证切片。记录源码提交、实际测试退出码、截图或真机证据；尚未验证的事项明确标为待验证。
- 网页 GPT PLAN/REVIEW 可用时记录实际反馈；不可用时标注 unavailable，不臆造 approve。密钥和签名文件不得入库。
- 旧 `.cursor/docs/AMBUSH_HANDOVER_20260927.md` 含历史环境与分支状态；当前执行状态以 M0 报告及最新提交为准。
