# VS P0-1 D.3 反例门量测（2026-10-17）

| 字段 | 值 |
|------|-----|
| 状态 | **已实现 / 已隔离验证**；draft PR → `vs/g3`（不合并） |
| 分支 | `vs/p0-1-counterex` |
| 基线 | `vs/g3` @ `5f31b75` |
| chatgpt | unavailable（Cloud Agent；未冒充网页额度） |

## 目标

PLAY-6 之后证明开发规划 D.3 反例门是否仍「错了就会输」；记录还击软顶开/关对照；不成立者按原则应改几何或收软顶——本切片量测后判定改动量超过单 PR，**只交结果表与建议**。

## 范围

- **做**：`NightSim.enemy_return_soft_cap` 测量开关（默认 true）；`w2_counterex_test.gd` 命名用例；W7 soft-cap 对照；`ambush_vs/docs/COUNTEREX_P0_1_RESULTS_20261017.md`；CI 挂接。
- **不做**：改院子几何、改默认软顶、改金标 hash、截图、合并 PR。

## 验收

| 项 | 结果 |
|----|------|
| `w2_counterex_test.gd` | exit **0** |
| `w7_combat_test.gd` | exit **0**（含 soft-cap 对照） |
| `w2_sim_test.gd` | exit **0**（73；金标未动） |
| 结果表 | 已入库 |

## 结论摘要

- **成立**：F-A30/60、T-A−4、T-A+4、T-B+2/+4、W-A-MG→Kar；警报 quiet/suspicious/area。
- **不成立**：F-B30/60、T-A±2、T-B−4/−2、未侦察东巷、ALERT-global。
- **软顶**：OFF → BASE-B 不可胜，警报可胜门塌 → **保留默认软顶**；对照仅测量。
- **下一步**：见结果表 §4（几何收窄 / 侧翼脱出 / global 残局案），另开切片。

## 替代关系

接续 [W2 断言数与金标](VS_W2_COUNT_AND_GOLDEN_20261017.md) / [PLAY-6](VS_PLAY6_ENEMY_REACT_20261017.md)；不替代设计 v2。
