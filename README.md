# Ambush Loop

《Ambush Loop》是 Godot 4.7.2 制作的安卓横屏、离线六夜夜袭战术游戏。当前代码版本为 0.6.28（Android versionCode 77），仍处于开发与试玩阶段，不是 1.0 成品。

Godot 工程位于 [`ambush_loop/`](ambush_loop/)，运行、操作和导出说明见 [游戏 README](ambush_loop/README.md)。在仓库根目录可用 `godot --path ambush_loop` 启动。会清理测试存档的冒烟测试必须通过 `ambush_loop/scripts/run_isolated_test.ps1`（Windows）或 `run_isolated_test.sh`（Linux）启动；不要直接执行 `smoke_test.gd`。

当前独立协作仓库来自 [`hailinsu-create/new` 的 PR #64](https://github.com/hailinsu-create/new/pull/64) 的固定代码树 `ab2076f9c2d1da63e7aba835ee0b0d23c5192654`。为让源码仓库适合协作，未复制历史 APK 和 Godot 生成的 `.import` 文件；原始提交历史与旧试玩包仍在来源仓库。详见 [来源说明](SOURCE_PROVENANCE.md)。

开发入口：

- [M0 状态报告](.cursor/docs/AMBUSH_M0_REPORT.md)：已完成的隔离、构建与待复验的手机项目。
- [直到 1.0 的开发规划](.cursor/docs/AMBUSH_TO_FINISHED_PRODUCT_PLAN_20260927.md)：M0–M5 阶段与成品验收。
- [R44–R53 切片表](.cursor/docs/AMBUSH_10_ROUNDS_R44.md)：R45–R53 仍待实施。
- [协作说明](CONTRIBUTING.md)：分支、测试和证据要求。
- [网页版 GPT 独立检查](.cursor/docs/WEB_GPT_REVIEW_20260927.md)：M0 退出门和后续阶段风险建议。

首次开发优先完成 M0 的最终 APK 真机复验、后台恢复和无引导首局观察，再按计划推进 R45。此仓库没有发行签名密钥；密钥不得提交。
