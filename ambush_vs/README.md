# Ambush VS（竖切骨架）

Godot **4.7.2** 空项目骨架，目录与 `ambush_loop/` 并存。Android `package/unique_name` 保持 **`com.ambushloop.game`**，便于将来对 0.6.28 做覆盖升级测试。

本目录当前**不含**新玩法模拟核心（W2+）。素材来源与许可见 `PROVENANCE_VS.md`、`THIRD_PARTY_NOTICES.md`。

## 隔离空测试

```bash
# 通过护栏：退出码 0
./scripts/run_isolated_test.sh /absolute/path/to/Godot_v4.7.2

# 直接入口应被拒：退出码 91
godot --headless --path . -s res://scripts/empty_test.gd
# → TEST_STORAGE_ISOLATION_REQUIRED … quit(91)
```

Windows：`scripts/run_isolated_test.ps1 -GodotBin <path>`。
