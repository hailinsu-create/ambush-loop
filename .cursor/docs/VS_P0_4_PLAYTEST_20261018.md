# VS P0-4 试玩构建开关 + 对局日志导出（2026-10-18）

| 字段 | 值 |
|------|-----|
| 状态 | **已实现 + 隔离 headless 测试已验证**；draft PR → `vs/g3`（不合并、不发布） |
| 分支 | `vs/p0-4-playtest`（自 `origin/vs/g3` @ `24b2954`） |
| 代码提交 | `3599b57` |
| 需求来源 | Opus 复盘 P0-4：给陌生人玩的构建须隐藏开发入口，并留下可回收的对局日志 |
| 编码方式 | 本机 OpenCode CLI + `opencode-go/deepseek-v4.1-flash`（2 轮），人工审查 diff |
| chatgpt | unavailable |

## 目标

1. 一个「试玩构建」开关，打开后陌生人看不到/触发不了任何开发调试入口。
2. 每局结束自动生成带时间戳的 JSON 日志；网页版可下载/复制，桌面版写 `user://`。

非目标：不改 sim 规则与金标；不改布局；不做远程上报；不改 Pages 部署流程。

## 开关（`ambush_vs/ui/playtest_mode.gd`）

优先级从高到低：

| 来源 | 开 | 关 |
|------|----|----|
| 环境变量 `AMBUSH_PLAYTEST` | `1`/`true` | `0`/`false`（显式覆盖） |
| 网页 URL 参数 | `?playtest=1` | `?playtest=0` |
| 导出 feature tag | 导出预设 `custom_features` 含 `playtest` | — |

**默认关闭**：线上 `/greybox/` 行为不变（开发组照常用开发菜单）；给陌生人发
`https://hailinsu-create.github.io/ambush-loop/greybox/?playtest=1`。Pages 根页加了试玩版链接。
桌面/安卓：导出时在预设 `custom_features` 填 `playtest`，或启动前设 `AMBUSH_PLAYTEST=1`。

试玩模式下：

- 「开发」按钮隐藏且 disabled；开发菜单不可打开（toggle 防御性 no-op）。
- 示例方案、方案 A/B、预览、美术切换、侦察预览：隐藏 + disabled；`_toggle_example_plans` / `_load_preset` no-op。
- `AMBUSH_GREYBOX_AUTO` / `CAPTURE` / `FORCE_LEAK` / `ART` / `SKIP_SCOUT` / `SKIP_BRIEF` 环境钩子全部忽略；`force_leak_allowed()` 恒 false。
- 结算面板出现「导出日志」按钮（非试玩模式不显示，保持现有布局与 W8 断言不变）。

## 对局日志（`ambush_vs/ui/match_log.gd`，schema `ambush_match_log/1`）

每次进入结算（两种模式都写）保存到 `user://match_logs/match_YYYYMMDD_HHMMSS[_n].json`。
「导出日志」：网页 → `JavaScriptBridge.download_buffer` 下载 + 剪贴板；桌面 → 显示绝对路径 + 剪贴板。

| 字段 | 含义 |
|------|------|
| `schema`, `game_version`, `level_id`, `platform` | 版本/关卡/平台 |
| `playtest`, `playtest_source` | 是否试玩构建、来源 env/url/feature |
| `started_at`, `ended_at`, `started_unix`, `ended_unix`, `duration_s` | 本局墙钟时间（重开/重新侦察重新计） |
| `beats_ms {scout, setup, wait, fire}` | 每拍停留毫秒：侦察（含搜集）/布阵/等待（起爆前）/开火（起爆后至结算） |
| `plan {operators[id,display_name,weapon_id,x,y,height,facing_deg], mines, grenades, trigger}` | 布阵 |
| `detonate_tick`, `detonate_t_s`, `trigger` | 起爆时刻与触发方式 |
| `fires[{tick,t_s,actor,weapon_id,target}]`, `fire_count` | 每一发开火时刻 |
| `outcome`, `reason`, `standard_ambush`, `alert` | 结局 |
| `kills`, `escapes`, `wounded`, `dead_ops` | 歼灭 / 逃脱 / 负伤 / 阵亡 |
| `sim_ticks`, `sim_time_s`, `log_hash` | 模拟长度与事件日志哈希（可对照复现） |

## 验证（本机 Godot 4.7.2 headless，全部经 `run_isolated_test.sh`）

| 入口 | exit | passed |
|------|------|--------|
| empty_test | 0 | — |
| w2_sim | 0 | 74 |
| w2_counterex | 0 | 27 |
| w2_aim_tolerance | 0 | 111 |
| w3_greybox | 0 | 57 |
| w4_scout | 0 | 27 |
| w5_combat_fx | 0 | 19 |
| w6_review | 0 | 25 |
| w7_combat | 0 | 26 |
| w8_controls | 0 | 357 |
| w8_briefing_blacklist | 0 | 33 |
| **w9_playtest（新增）** | 0 | **69** |
| 直接入口拒绝 | 91 | — |

W2–W8 与改动前基线（同机同版本）计数完全一致。W9 覆盖：开关来源解析；关模式开发按钮可见、导出按钮隐藏；开模式开发入口全不可见、按下开发按钮不出菜单、示例方案/预设加载无效、FORCE_LEAK 不可用、AUTO 环境不触发自动对局；脚本布阵跑完一局后日志字段齐全、类型正确、文件落地可重新解析、导出返回成功。

CI：本分支**未**改 `.github/workflows/ambush-vs-isolated-test.yml`——推送凭据缺 `workflow` scope，GitHub 拒绝修改工作流文件。CI 照常跑 W2–W8；W9 步骤补丁（在 W8 briefing 之后加 `Isolated W9 playtest tests (expect 0)`，调用 `run_isolated_test.sh … w9_playtest_test.gd`）需所有者用有 workflow 权限的账号补上。W9 目前只有本机证据。

待验证：网页端 `?playtest=1` 实机（需 PR 进 `vs/g3` 后自动部署；本切片未合并）；真机/陌生人首局。

## 替代关系

接续 [P0-3 简报](VS_P0_3_BRIEF_20261017.md)（已合入 `vs/g3`）。
