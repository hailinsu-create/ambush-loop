# Ambush Loop 工作说明

- Godot 工程在 `ambush_loop/`，版本固定为 4.7.2；先读根 README、`ambush_loop/README.md`、`.cursor/docs/AMBUSH_TO_FINISHED_PRODUCT_PLAN_20260927.md`。
- 修改玩法遵守 `SCOUT → ALERT → SWEEP` 与冻结计划契约。不要顺手加入第七夜、FOW、联网或大规模战斗重写。
- 运行会清理测试档的脚本时必须走 `ambush_loop/scripts/run_isolated_test.ps1` 或 `.sh` 包装器，先确认隔离守卫通过。不能直接调用 `smoke_test.gd`。
- 每次只做一个可验证切片。记录源码提交、实际测试退出码、截图或真机证据；尚未验证的事项明确标为待验证。
- 网页 GPT PLAN/REVIEW 可用时记录实际反馈；不可用时标注 unavailable，不臆造 approve。密钥和签名文件不得入库。
- 旧 `.cursor/docs/AMBUSH_HANDOVER_20260927.md` 含历史环境与分支状态；当前执行状态以 M0 报告及最新提交为准。
