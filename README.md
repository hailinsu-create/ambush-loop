# Ambush Loop

《Ambush Loop》是 Godot 4.7.2 制作的安卓横屏、离线六夜夜袭战术游戏。本次规划发布沿用已入库游戏基线 0.6.28（Android versionCode 77）；R45 的在制版本 0.6.29 / 78 不包含在本次文档发布中。游戏仍处于开发与试玩阶段，不是 1.0 成品。

Godot 工程位于 [`ambush_loop/`](ambush_loop/)，运行、操作和导出说明见 [游戏 README](ambush_loop/README.md)。在仓库根目录可用 `godot --path ambush_loop` 启动。会清理测试存档的冒烟测试必须通过 `ambush_loop/scripts/run_isolated_test.ps1`（Windows）或 `run_isolated_test.sh`（Linux）启动；不要直接执行 `smoke_test.gd`。

当前独立协作仓库来自 [`hailinsu-create/new` 的 PR #64](https://github.com/hailinsu-create/new/pull/64) 的固定代码树 `ab2076f9c2d1da63e7aba835ee0b0d23c5192654`。为让源码仓库适合协作，未复制历史 APK 和 Godot 生成的 `.import` 文件；原始提交历史与旧试玩包仍在来源仓库。详见 [来源说明](SOURCE_PROVENANCE.md)。

开发入口：

- [规划与续开发索引](.cursor/docs/PLANNING_INDEX.md)：当前有效规划、历史替代关系、接手顺序，以及每次规划保存并同步 GitHub 的规则。
- [游戏设计规划 v2](.cursor/docs/AMBUSH_DESIGN_V2_20260928.md)：当前主设计，包含玩法、高点规则、六关职责、视觉、手机操作与重新排序的 M0–M5。
- [资产升级与旋转场景讨论稿](.cursor/docs/AMBUSH_ASSET_UPGRADE_20261002.md)：源资产盘点与全面升级提案；写实厚重、水平 360° 旋转、俯角受限和缩放已确认，替代 v2 固定镜头约束；实时 3D 路线与新资产尚待样板验证。
- [资产升级执行计划](.cursor/docs/AMBUSH_ASSET_EXECUTION_PLAN_20261002.md)：当前实施入口，按 A0–A4 定义工具/基线、逻辑表现适配、可旋转院子、写实资产与六关推广；目标为中端安卓 30 FPS、高配可选 60 FPS，规划完成、制作尚未开始。
- [产品方向：短关卡小队伏击](.cursor/docs/AMBUSH_PRODUCT_DIRECTION_20260928.md)：用户确认的“搜集弹药 → 占领高点 → 埋伏 → 歼灭”主循环及待验证方案。
- [M0 状态报告](.cursor/docs/AMBUSH_M0_REPORT.md)：已完成的隔离、构建与待复验的手机项目。
- [旧成品总计划](.cursor/docs/AMBUSH_TO_FINISHED_PRODUCT_PLAN_20260927.md)：保留工程与发行验收；阶段顺序以 v2 为准。
- [R44–R53 历史切片表](.cursor/docs/AMBUSH_10_ROUNDS_R44.md)：在制与未验收项按 v2 归并，不再作为独立完整主线。
- [协作说明](CONTRIBUTING.md)：分支、测试和证据要求。
- [网页版 GPT 独立检查](.cursor/docs/WEB_GPT_REVIEW_20260927.md)：M0 退出门和后续阶段风险建议。

后续开发先保留并核实 R45 在制工作，闭环 M0 真机缺项，再按 v2 验证院子战术样板与视觉样板。此仓库没有发行签名密钥；密钥不得提交。
