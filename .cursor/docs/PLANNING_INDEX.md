# Ambush Loop 规划与续开发入口

更新日期：2026-10-20。仅用于本游戏；设计文件不是实现或验收证明。

## 当前有效规划

| 文档 | 定位与状态 |
| --- | --- |
| [VS T5 高点攀爬代价 2026-10-20](VS_T5_CLIMB_20261020.md) | **当前 VS 执行切片**（规划 T5）：上下高点 +2s、禁射、出发格暴露；`CLIMB_COST_S` 生效；W2 107 / W3 67 / W8 366。堆叠在 T4 上（base `vs/t4-scout-carry`）。⚠ 谷仓出发格在西巡逻锥内，示例方案 A 场景掉到 C，待拍板。**不合并**。 |
| [VS T4 侦察警报带入埋伏 2026-10-20](VS_T4_SCOUT_CARRY_20261020.md) | 已被 T5 接续（规划 `NEXT_PLAN_20261018` T4）：`plan.start_alert` 携带侦察警报；area/global 失去标准伏击、A/B 仍可胜；新增 W4 carry 39；起疑轻代价（发现距离 ×1.3）。替代 W4a「埋伏从安静开始」。分支 `vs/t4-scout-carry` → draft PR 合入 `vs/g3`。**不合并**；起疑力度已拍板。 |
| [VS P0-4 试玩构建开关 + 对局日志 2026-10-18](VS_P0_4_PLAYTEST_20261018.md) | **当前 VS 执行切片**：`?playtest=1` / `AMBUSH_PLAYTEST` / feature `playtest` 隐藏开发入口；每局 JSON 日志 + 「导出日志」；W9 新增。分支 `vs/p0-4-playtest` → draft PR 合入 `vs/g3`。**不合并**。 |
| [VS P0-3 简报与最小教学 2026-10-17](VS_P0_3_BRIEF_20261017.md) | 开局简报 + 阶段提示 + 教学文案黑名单。分支 `vs/p0-3-brief` → draft PR 合入 `vs/p0-2-aim`。**不合并**。试玩 Pages 部署被环境分支策略阻塞（见文档）。 |
| [VS P0-2 朝向吸附与放大镜 2026-10-17](VS_P0_2_AIM_SNAP_20261017.md) | 放大镜 + AimSnap + G.1 容差门；结果表 [`ambush_vs/docs/AIM_TOLERANCE_P0_2_RESULTS_20261017.md`](../../ambush_vs/docs/AIM_TOLERANCE_P0_2_RESULTS_20261017.md)。分支 `vs/p0-2-aim` → draft PR 合入 `vs/p0-1-counterex`。**不合并**；已被 P0-3 接续。 |
| [VS P0-1 D.3 反例门 2026-10-17](VS_P0_1_COUNTEREX_20261017.md) | 切片 0–4 已验证（D.3 门全绿）；结果表 [`ambush_vs/docs/COUNTEREX_P0_1_RESULTS_20261017.md`](../../ambush_vs/docs/COUNTEREX_P0_1_RESULTS_20261017.md)；院子纸面 **v1.6**。分支 `vs/p0-1-counterex` → draft PR 合入 `vs/g3`。**不合并**；已被 P0-2 接续。 |
| [VS UX 布局修复 2026-10-17](VS_UX_LAYOUT_20261017.md) | 手机紧凑头像条 + 取景排除 HUD；W8 **273**。PR #57 → `vs/g2`。**不合并**；已被 P0-1 反例门接续。 |
| [VS UX 操作修复 2026-10-17](VS_UX_CONTROLS_20261017.md) | 审计 PR-1…10 手势/选人/重瞄/工具栏/HUD/快捷键；已被布局修复接续。PR #57 → `vs/g2`。**不合并**。 |
| [VS-PLAY6 敌人反应 2026-10-17](VS_PLAY6_ENEMY_REACT_20261017.md) | PLAY-6 敌人反应；已被 UX 操作切片接续。PR #57 → `vs/g2`。**不合并**。 |
| [W2 断言数与金标 2026-10-17](VS_W2_COUNT_AND_GOLDEN_20261017.md) | W2 61→73（PLAY-4 wait-turn）说明；PLAY-4/PLAY-6 金标变更 DECISIONS。 |
| [VS-PLAY5 中文复盘卡 2026-10-17](VS_PLAY5_REVIEW_CARD_20261017.md) | PLAY-5：复盘卡 + 搜尸 stub。已被 PLAY-6 接续。PR #57 → `vs/g2`。**不合并**。 |
| [VS-PLAY4 等待重瞄与节奏 2026-10-17](VS_PLAY4_WAIT_UX_20261017.md) | PLAY-4：WAIT 重瞄、脚步/环境/tension、院子节奏 t0 520/560。PR #57 → `vs/g2`。**不合并**。 |
| [VS-FX1 起爆战斗表现 2026-10-17](VS_FX1_COMBAT_FEEDBACK_20261017.md) | PLAY-3：视图消费 fire/hit/kill；枪口火/曳光/命中/地雷震/尸体。PLAY-4 起曳光加粗加亮、枪口放大。PR #57 → `vs/g2`。**不合并**。 |
| [VS-W4a 侦察搜集 2026-10-17](VS_W4A_SCOUT_GATHER_20261017.md) | PLAY-2 侦察搜集（ScoutSim）。PR #57 → `vs/g2`。**不合并**。 |
| [VS-UX1 空白布阵起手 2026-10-17](VS_UX1_BLANK_SETUP_20261017.md) | PLAY-1 空白板布阵（已被 PLAY-2 接在侦察之后）。G3 美术 Round 8 后暂停。PR #57 → `vs/g2`。**不合并**。 |
| [VS G3 高细节美术 2026-10-17](VS_G3_ART_20261017.md) | VS 美术切片（**已暂停**）：`vs/g3` Round 8 — 连续沙袋墙 + 去格背板。PR #57 → `vs/g2`。**不合并**；不再做 G3 打磨直至所有者要求。 |
| [VS G2 资产批 2026-10-17](VS_G2_ASSETS_20261017.md) | G2 程序生成院子/五武器/SFX；已被 G3 批作为可切换回退保留。PR #56 → `vs/web`。 |
| [VS Web greybox Pages 2026-10-17](VS_WEB_GREYBOX_PAGES_20261017.md) | **Web 试玩切片**：分支 `vs/web`（自 `vs/core` @ fa6bd08）导出灰盒到 GitHub Pages `/greybox/`。本地导出+Chromium smoke 已过；Pages API 启用被拒，待所有者打开 Actions Pages + `vs/web` 环境分支。**不合并 main / 不动 PR #54**。 |
| [VS W2 模拟核心 v0 2026-10-17](VS_W2_SIM_V0_20261017.md) | **当前 VS 执行入口**：`ambush_vs/sim/` headless 一夜模拟；院子纸面 **v1.2**；A/B 金标；隔离测试。在 `vs/core` / PR #54，**未合入 main**。 |
| [VS ADR v1 同步 2026-10-17](VS_ADR_V1_SYNC_20261017.md) | VS 规则文档：TERMS + 三 ADR 已采纳 v1 + 院子纸面 v1.1 + 资产生成门禁。已被 W2 实现消费。 |
| [开发规划 2026-10-16](DEV_PLAN_20261016.md) | VS 竖切开发规划（Notion 同源）；A1 仓库策略。执行骨架见 [VS A1 记录](VS_A1_SKELETON_20261016.md)；代码在分支 `vs/core`，**未合入 main**。ADR 正文以 `ambush_vs/docs/adr/` 为准（已采纳 v1 覆盖 PR #53 草案）。 |
| [代码审计与优化记录](AMBUSH_CODE_AUDIT_20261002.md) | 寻路优化、504 条路径等价/311 个最短代价检查、完整六夜冒烟及实际截图已完成；代码 [PR #11](https://github.com/hailinsu-create/ambush-loop/pull/11) 与审计 [PR #12](https://github.com/hailinsu-create/ambush-loop/pull/12) 已创建，均未合并。记录其余优化建议；不替代设计 v2 或 M0 验收。 |
| [游戏设计规划 v2](AMBUSH_DESIGN_V2_20260928.md) | 当前开发设计基线：玩法、高点规则、六关、视觉、手机操作、M0–M5。用户已同意以此推进；具体设计仍须逐切片实现、验证。 |
| [产品方向](AMBUSH_PRODUCT_DIRECTION_20260928.md) | 保留用户需求来源：“搜集弹药 → 占领高点 → 埋伏 → 歼灭”。细化方案以 v2 为准。 |
| [M0 状态报告](AMBUSH_M0_REPORT.md) | 工程基线与验收缺口。最终修复包真机复验、陌生人首局等未完成项目不得写成通过。 |
| [旧成品总计划](AMBUSH_TO_FINISHED_PRODUCT_PLAN_20260927.md) | 工程、数据安全和发行质量门槛仍有效；产品定位、阶段顺序、美术目标被 v2 替代。 |
| [R44–R53 历史切片表](AMBUSH_10_ROUNDS_R44.md) | 历史执行与复核记录；按 v2 重新归并，不视为新版设计已获验收。 |

## 接手时按这个顺序读

1. 根目录 `README.md`、`AGENTS.md`、`CONTRIBUTING.md`，确认范围、分支及测试规则。
2. 本索引与当前设计 v2，理解目标体验和阶段优先级。
3. M0 报告、最新 Git 提交和相关 PR，核对真实代码与测试证据；旧交接里的本机路径、连接状态、提交状态可能已过时。
4. 先核实 R45 在制提示切片与 M0 真机缺项，再开展 M1 院子战术样板；M2 做视觉、手机操作、引导与存档闭环。具体退出门见 v2。

2026-09-28 本次仅发布规划和协作规则；不包含 R45 的在制游戏代码，不代表 M1/M2 已完成。后续状态以新的执行报告、提交和验证证据更新。

## 以后每次规划的入库规则

- 每次阶段规划、需求重排或设计调整，都新增 `.cursor/docs/` 下带日期的 Markdown 文档；同日多版使用版本后缀。常规开发计划也要写入文件，不能只留聊天记录。
- 至少记录：目标与需求来源、范围及非目标、依赖与决策、执行切片、验收门槛、已知风险、当前状态和下一步。外部评审仅记录真实反馈。
- 明确区分“用户已确认方向”“待验证设计”“已实现”“已测试通过”；不得把规划中的功能当作已有能力。
- 更新本索引的有效入口与替代关系。旧规划保留历史，不直接删除；接手者应能看清什么仍有效、什么已被替代。
- 有用于决策的图、样板或评审结果时，保存可复用的文件并链接；没有保存到仓库的本机预览不得当作协作入口。
- 规划文档与相关入口、协作规则一起提交到本游戏 GitHub。按 `CONTRIBUTING.md` 的分支/PR 流程发布，核对远端提交，不混入尚未验收的代码、密钥、配对码或本机敏感配置。
- GitHub 同步失败时明确说明“仅本地保存/尚未同步”，保留未完成事项；不能把准备提交、已推送分支、已合并主线混为一谈。

新规划完成后，应更新此索引和下一步，不要求后续开发者重新翻查聊天。
