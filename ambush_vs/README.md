# Ambush VS（竖切）

Godot **4.7.2** 竖切工程，目录与 `ambush_loop/` 并存。Android `package/unique_name` 保持 **`com.ambushloop.game`**。

W2：`sim/` 纯 RefCounted 一夜模拟（无渲染）。规则见 `docs/TERMS_AND_TICK_ORDER.md` 与 ADR；纸面/数据冲突见 `docs/W2_DISCREPANCIES.md`。

## 隔离测试

```bash
# 空测试 / W2 金标+契约（退出码 0）
./scripts/run_isolated_test.sh /absolute/path/to/Godot_v4.7.2 empty_test.gd
./scripts/run_isolated_test.sh /absolute/path/to/Godot_v4.7.2 w2_sim_test.gd

# CLI：跑方案 A 或 B
AMBUSH_PLAN=A ./scripts/run_isolated_test.sh /absolute/path/to/Godot_v4.7.2 w2_sim_cli.gd
AMBUSH_PLAN=B ./scripts/run_isolated_test.sh /absolute/path/to/Godot_v4.7.2 w2_sim_cli.gd

# 直接入口应被拒：退出码 91
godot --headless --path . -s res://scripts/empty_test.gd
```

Windows：`scripts/run_isolated_test.ps1 -GodotBin <path> [-Entry w2_sim_test.gd]`。

## 布局

| 路径 | 说明 |
|------|------|
| `sim/` | 模拟核心（grid / alert / trigger / fire / event hash） |
| `data/levels/yard.json` | 院子关卡 |
| `data/fixtures/plan_{a,b}.json` | 方案 A/B |
| `data/golden/hashes.json` | 金标日志哈希 |
| `schema/` | level / events JSON Schema |
