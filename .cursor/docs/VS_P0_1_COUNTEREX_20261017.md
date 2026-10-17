# VS P0-1 D.3 反例门（2026-10-17）

| 字段 | 值 |
|------|-----|
| 状态 | **切片 3 已验证**；进行 ALERT-global |
| 分支 | `vs/p0-1-counterex` |
| 基线 | `vs/g3` @ `5f31b75` |
| chatgpt | unavailable |

## 目标

D.3 反例门「错了就会输」；软顶默认保留；逐片改几何使不成立门成立。

## 切片

| 片 | 内容 | 提交 |
|----|------|------|
| 0 | 量测门 + 软顶对照 | `b5a8a27` |
| 1 | 东巷脱出；纸面 v1.3；金标 hash | `997e9f9` |
| 2 | F-B30/60；纸面 v1.4；MP 150°；unwatched_break | `95028ef` |
| 3 | T-A−2；纸面 v1.5；`road_tail` 后尾 peel | （本切片） |
| 4 | ALERT-global | 待做 |

## 切片 3 后仍缺

ALERT-global（0 胜）。

## 替代关系

接续 [W2 金标](VS_W2_COUNT_AND_GOLDEN_20261017.md) / [PLAY-6](VS_PLAY6_ENEMY_REACT_20261017.md)。
