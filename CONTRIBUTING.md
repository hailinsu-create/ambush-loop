# 协作约定

1. 从本仓库 `main` 建功能分支，通过 Pull Request 提交游戏改动。一个 PR 聚焦一个可玩或可见的切片；描述目标行为、修改范围、验证结果和未解决问题。
2. Godot 版本固定为 4.7.2。核心循环为 `SCOUT → ALERT → SWEEP`，ALERT 阶段锁定计划。R45–R53 的具体范围见 [原切片表](.cursor/docs/AMBUSH_10_ROUNDS_R44.md)，当前成品路线见 [开发规划](.cursor/docs/AMBUSH_TO_FINISHED_PRODUCT_PLAN_20260927.md)。
3. 冒烟测试只能走 `ambush_loop/scripts/run_isolated_test.ps1` 或同目录的 `.sh` 包装器。直接运行 `smoke_test.gd` 会被隔离守卫拒绝。修改输入、存档或战斗规则时，附退出码、完成标记及对应反例；手机交互还应附实际设备记录。
4. 不提交 APK、构建缓存、玩家存档、密钥或本机路径配置。旧试玩包从来源仓库的 Release 获取；新安装包由可追溯源码与受控签名流程生成。
5. 当前 M0 尚未完成最终修复包真机复验和陌生人首局。任何文档、PR 或发布说明都不要把 0.6.28 称为已验收 1.0。

这个仓库仅用于 Ambush Loop。来源混合仓库 `hailinsu-create/new` 的其他项目不属于协作范围。
