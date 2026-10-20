# VS T6 还击软顶显式难度（2026-10-20）

| 字段 | 值 |
|------|-----|
| 状态 | **已实现，本机隔离 headless 测试已验证**；草稿 PR（**堆叠**：base `vs/t5-climb`，即 PR #67）；不合并、不发布 |
| 分支 | `vs/p1-softcap`（基于 `vs/t5-climb` @ `4a75b56`） |
| 需求来源 | `NEXT_PLAN_20261018.md` T6；第 5 节授权项 1，按推荐项 A 由我们代定 |
| 编码方式 | 本机 OpenCode CLI，模型 **`opencode-go/deepseek-v4.1-flash --variant max`**，1 轮（约 20 分钟）；人工审查 diff |

## 我们代定的默认值（盲测后可调）

| 常量 / 字段 | 默认值 | 依据 | 位置 | 怎么调 |
|---|---|---|---|---|
| `RETURN_FIRE_ASSIST_DEFAULT` | `false`（硬核：没有每敌命中上限） | 规划第 5 节第 1 项推荐 A | `sim/constants.gd` | 改常量；改了要重生成金标 |
| `RETURN_FIRE_ASSIST_MAX_HITS_PER_ENEMY` | `1` | 沿用 PLAY-6 原软顶 | `sim/constants.gd` | 只在辅助档生效 |
| `plan.return_fire_assist` | 不写时取上面的常量 | 每局显式档位 | NightSim `setup()` | 布阵按钮、`AMBUSH_RETURN_ASSIST=1`（非试玩模式） |

## 改动

- **NightSim：** 软顶默认值读常量；`setup()` 读可选 plan 键 `return_fire_assist`，非 bool 时回落到常量；setup 之后改 `enemy_return_soft_cap` 仍然有效；事件 schema 没改。
- **控制器：**
  - 布阵按钮「还击辅助：关」/「还击辅助：开（每名敌人最多命中一次）」，试玩模式下也能用，因为它是玩家选项，不是开发入口。
  - 开局时写入 `plan.return_fire_assist`；简报和结算卡各显示一行当前档位。
  - 对局日志（match log）的 plan 段追加 `return_fire_assist`。
- **文档：** `ambush_vs/docs/COUNTEREX_P0_1_RESULTS_20261017.md` 新增 T6 节：两档全矩阵，并更正旧结论「OFF 时 B 全灭」。

## 两档矩阵要点（全表见 COUNTEREX 结果页）

- D.3 门：原来 14 个都成立的反例在关档（新默认）下逐个实测仍都成立，PENDING 仍为空；四档开局警报在关档下都是 wins=2。
- BASE-B：关档仍然赢，但 injury_n 从 1 变成 2（1 人阵亡），所以 **W6 里方案 B 评级从 A|B 降到 C**（有人阵亡就判 C）。
- F-A60、W-A-MG→Kar 在两档下都还是 win（关档伤亡更重），T-A+2、T-A+4 也还是 win。这 4 个是 T7 要处理的严判组。
- W2 瞄准容差：已发布格本身 ±5° 全胜。有 8 个“±1 格手指滑动”格在关档下变成 lose（有逃脱），记在 `HARD_TIER_EXCEPTIONS`，按实测的输赢和逃脱者写成精确值。T7 按 G.1 要把这些格改成「可胜或明确禁止落位」：
  - A op0 (5,10)：±5° 三格，F2、F1 逃脱；
  - B op0 (9,6)：±5° 三格，E2 逃脱；
  - B op1 (15,8)：−5°、0° 两格，E4 逃脱。

## 金标差异（`hashes.json`）

| plan | 旧 hash | 新 hash | outcome | t0 | standard | 负伤/阵亡 | 清场 |
|---|---|---|---|---|---|---|---|
| A | `a89a0e5a…` | **不变** | win | 520 | true | 1/0 | 0.55s |
| B | `2e61083f…` | `d3f35826…` | win | 560（不变） | true | 1/1（原 1/0） | 3.25s |

原因：关档下 B 有一名敌人打出第二次致伤，击倒 1 名队员，事件流多了伤亡和后续事件。A 没有出现第二次命中，所以不变。

## 变更的断言（旧 → 新）

- counterex：
  - 默认值：`== true` 改为 `== RETURN_FIRE_ASSIST_DEFAULT`，并写死常量 `== false`；cap 常量 `== 1`；
  - D.3 门和四档警报在两档下都断言；BASE-B 关档受伤 2 > 开档 1。
- W6：方案 A 评级从 A|S 改为 **A**；方案 B 从 A|B 改为 **C**；场景 A 从 A|S 改为 **A**。
- W7：默认档改为关，开档对 B 更宽松，plan 键生效。
- aim：上面 8 格按实测改成精确的 lose + 逃脱者。
- T5 的严格断言全部保留：W3/W5 t0 520 + 标准伏击；W5b 北梯结论没变（可见性和还击无关）。

## 验证（`run_isolated_test.sh`，先 `--import`）

| 套件 | 结果 | 套件 | 结果 |
|---|---|---|---|
| empty | exit 0 | W5b | 39/0 |
| W2 | 107/0（金标 plan_b 已更新） | W6 | 25/0 |
| counterex | **38/0**（27→38） | W7 | **30/0**（26→30） |
| aim | 111/0 | W8 | **428/0**（405→428） |
| W3 | 85/0 | blacklist | **35/0**（33→35） |
| W4 / W4 carry | 27/0、39/0 | W9 | **80/0**（70→80） |
| W5 | 22/0 | | |

反向对照：
- 常量临时改回 `true`：W2 106/1、counterex 36/2、W6 24/1，都是 exit 1；
- 去掉 setup 读 plan 键的那一行：W7 29/1、W8 427/1，都是 exit 1。

## 合并顺序（含与 #68 T8 的冲突）

1. #64、#65：互相独立，先合。
2. #66（T4）→ `vs/g3`。
3. #67（T5）：base 改成 `vs/g3` 后合。
4. 本 PR（T6）：base 改成 `vs/g3` 后合。
5. T7（堆在本 PR 上）：base 改成 `vs/g3` 后合。
6. #68（T8）：最后 rebase 到 `vs/g3`。会冲突的地方：
   - `run_isolated_test.sh/.ps1` 的白名单：取并集，加上 `w3_level_contract_test.gd`；
   - `greybox_controller.gd` 第 270 行附近的关卡加载：保留 T8 的 `SimLevels.path_for(...)`；
   - `sim/runner.gd`：T4–T7 没改，不冲突。
   - 金标：T8 的契约测试读 `hashes.json`。T6/T7 改过金标后，契约测试会读到新值，它的 `T0_A/T0_B` 常量要和 T7 定稿后的 t0 一致；rebase 后先跑一遍契约测试。

## 遗留

- 硬核默认的可见代价：示例方案 B 评级 C；8 个 ±1 格手指滑动格会输。如果盲测觉得太严，把常量切回 `true` 就行，不用改 schema。
- 截图/真机看按钮位置：待验证。
- 新断言都不在 CI 的 W9 步骤里（归 T3）；CI 里有 W2/W6/W7/W8，会跑到。
