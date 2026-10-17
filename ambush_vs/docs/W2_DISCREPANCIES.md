# W2 sim v0 — paper / rule discrepancies

| 字段 | 值 |
|------|-----|
| 日期 | 2026-10-17 |
| 范围 | 院子纸面 × TERMS/ADR × headless sim |
| 纸面 | **v1.2** 已吸收关卡向变更；见 [yard_paper_v1_2.md](yard_paper_v1_2.md) |

---

## Resolved in paper v1.2

| # | 原问题 | 处置 |
|---|--------|------|
| 1 | Plan A facing 18.3895° 贴锥缘过拟合 | **resolved-in-paper**：A 改 `cross_marker` @ y=7；Kar 朝向清洁 **15°**；±1° 稳定性测试 |
| 2 | 东巷起点 (23,6) vs 5 格/10 s | **resolved-in-paper**：航点 `(23,7)→(18,8)` |
| 3 | 雷「整格」vs 路径点 (11,6) | **resolved-in-paper**：触发 = 距路径点 ≤½ 步长 |
| 4 | `(12,9)/(12,10)` 的 `w` 打断 B | **resolved-in-paper**：清除矮掩，保证 MP→纵队 LOS |
| 5 | H-01 总挡格比达不到 50% | **resolved-in-paper**：西岛+北带矮掩；度量改为两锥**交集** |
| 6 | `(9,12)` ASCII 歧义 | **resolved-in-paper**：数据强制 `#` |
| 7 | 阶段名 `resolve` | **resolved**：`events.json` 枚举含 `resolve` 与 `sweep` |

---

## Open

| # | 项 | 说明 |
|---|----|------|
| O1 | A 首枪叙事 | 纸面 v1.1 强调 Kar「看到」侧翼；v1.2 起爆改为头兵越线。玩法上仍靠 Kar 扇覆盖 F1，但触发语义从 `see_first_enemy` 换成 `cross_marker`。若产品要坚持「首枪=看见」，需另做宽裕扇/站位切片（本轮不做）。 |
| O2 | 等待中 A 可能起疑 | CLI 可见 `alert=suspicious`（高点剪影等）；未升区域警戒，标准伏击仍成立。是否要在布阵上消掉起疑留给 W3 可读性。 |

---

## Math notes (kept for audit)

**A cross_marker：** E1 `y=14−0.5t`；`y≤7` ⇒ `t≥14` ⇒ tick 280.

**Kar 15°±1° vs F1：** 巷口方位 ≈10.9°；Δ ∈ [3.1°, 5.1°] ＜ 7.5°.

**Mine point：** step = 0.025 格/tick；阈 0.0125 格于 (11,6)。
