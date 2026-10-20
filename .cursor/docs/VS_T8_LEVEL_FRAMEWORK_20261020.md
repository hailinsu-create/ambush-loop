# VS T8 多关卡框架（2026-10-20）

| 字段 | 值 |
|------|-----|
| 状态 | **已实现，本机隔离 headless 测试已验证**；草稿 PR；不合并、不发布 |
| 分支 | `vs/p1-level-framework`（基于 `vs/g3` @ `0de03bc`；按规划 T8 直接对 `vs/g3`，不堆在 T4/T5 上：两者互不依赖） |
| 需求来源 | `NEXT_PLAN_20261018.md` T8 |
| 编码方式 | 本机 OpenCode CLI，模型 **`opencode-go/deepseek-v4.1-flash --variant max`**，1 轮（约 9 分钟）；人工审查 diff |

## 改动

- 新增 `ambush_vs/sim/levels.gd`（`SimLevels`），关卡用显式注册表登记（导出包里扫目录不可靠）：
  - 目前只有 `yard`，登记了 path、golden（`hashes.json`）和 fixtures（plan_a、plan_b）。
  - 约定：以后的新关金标放在 `hashes_<id>.json`。
  - 接口：`ids / has / resolve_id / path_for / golden_path_for / fixtures_for`。
  - `selected_id()` / `selection_source()` 的取值顺序：环境变量 `AMBUSH_LEVEL` → Web 的 `?level=` → 默认 yard。id 未知时回落到 yard，来源记为 `env_unknown` / `url_unknown`。
- `sim/runner.gd`：
  - `run_plan` / `run_plan_dict` 的 `level_path` 默认值改为 `""`，空值时解析成注册表里的 yard，原有调用的行为不变。
  - 新增 `run_level_plan(level_id, plan, tweaks)`。
- `greybox_controller.gd`：
  - 关卡改为通过 `SimLevels.path_for(SimLevels.selected_id())` 加载。
  - 新增 `level_id` / `level_source` 两个成员。
  - 对局日志输出没改。
- `run_isolated_test.sh/.ps1` 的白名单加入 `w3_level_contract_test.gd`。
- 没改 yard.json、金标、fixture、sim 行为，也没动 `.github/`。

## 新测试 `w3_level_contract_test.gd`：40/0

对注册表里的每一关断言：
- 注册表和路径有效；关卡能加载，`level.id` 等于注册 id；
- 两套 fixture 都赢；
- 命名反例 F-A30、T-B+4 都输（构造方式与 `w2_counterex_test` 相同）；
- 同一方案跑两次哈希一致，且与金标一致，t0 也与金标一致；
- `resolve_id` 的回落、`AMBUSH_LEVEL` 选择及来源标记都正确；
- runner 不传关卡、显式传 yard 路径、`run_level_plan` 三种调用的哈希相同。

## 验证（`ambush_vs/scripts/run_isolated_test.sh <godot> <entry>`）

先 `--headless --path ambush_vs --import`。

| 套件 | 结果 | 基线 |
|---|---|---|
| empty | exit 0 | — |
| W2 sim | 74/0 | 74（金标不变） |
| counterex | 27/0 | 27 |
| aim | 111/0 | 111 |
| W3 greybox | 57/0 | 57 |
| **W3 level contract** | **40/0** | 新 |
| W4 scout | 27/0 | 27 |
| W5 FX | 19/0 | 19 |
| W6 review | 25/0 | 25 |
| W7 | 26/0 | 26 |
| W8 controls | 357/0 | 357 |
| blacklist | 33/0 | 33 |
| W9 | 69/0 | 69 |

反向对照：
- `runner.gd` 恢复成基底版本 → 契约测试解析失败，exit 1；
- 注册表里 yard 的金标路径改成 `hashes_yard.json` → 30/2，exit 1。

## 运行时代码里的 yard 硬编码清单（这次只登记，没改）

- `greybox_controller.gd:80-81`：节奏常量 520/560；`:941` 预设写死 `plan_a.json` / `plan_b.json`；`:4369,4383` headless 自动流程写死侦察坐标 (15,4)、(21,5)；`:2663,2920` `frame_yard()` 与 `ambient_yard` 音效。
- `sim/review_builder.gd:10-11,183`：yard 理想起爆 tick 520/560。
- `sim/aim_snap.gd:27-30`：地标坐标（`east_alley` (18,8)）。
- `sim/night_sim.gd:810`：road_tail 的回退坐标 (11,15)；`:1332` 撤退走廊固定 x=11。
- `sim/scout_sim.gd:54`：缺 level id 时回退为 `"yard"`。
- `view/greybox_map.gd:536`：侦察目标回退 (11,14)；`:1596-1598, 1639-1641, 1875`：yard 房屋/道具装饰坐标（只影响显示）。

> 上面这些要在 T9（第二关）之前改成按关卡数据读取，否则新关会继承 yard 的数值。

## 遗留

- Web 的 `?level=` 本机没实跑（headless 不是 Web 构建），写法照搬 `playtest_mode.gd`。
- 试玩锁定（playtest lockdown）还没屏蔽 `AMBUSH_LEVEL` / `?level=`，按规划留到 T11 加断言。
- 控制器的 `level_id` / `level_source` 还没有场景级断言（目前只有 yard，等新关接入时补）。
- W3 level contract 不在 CI 里（要改 workflow，归 T3）。
- 和 T4/T5 都改了 `greybox_controller.gd` 和 `run_isolated_test.sh` 白名单，合并时白名单那一行会有文本冲突，需要手工合并。
