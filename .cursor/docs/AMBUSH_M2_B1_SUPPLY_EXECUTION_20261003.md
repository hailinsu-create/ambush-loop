# M2-B1 现场弹药与基础装备契约

日期：2026-10-03。用户要求继续按已采纳的 M2 玩法大改规划开发。来源：[M2 规划](AMBUSH_M2_PREPARATION_GAMEPLAY_REDESIGN_20261003.md)。

## 范围与状态

本轮为一个可验证子切片 B1：先改变资源契约，B2 再改变一次主接触与无高点战术。源码基于 M2-A `26528ddca855ae0f8c61ea9688feff3677a55817`，独立分支 `codex/m2-b1-explicit-supplies`，最终准确提交 `42ba583e2ce88203543678280b905acb2cda63dd` 已推送并核对远端。[Draft PR #25](https://github.com/hailinsu-create/ambush-loop/pull/25) 依赖 PR #24，尚未合并。B1 已实现并通过定向资源及共享资源检查，六关全量 smoke 待补；没有将整个 M2-B 或 M2 标为完成。规划与证据使用独立文档 PR #9。

外部 GPT PLAN/REVIEW：`unavailable`，尚无当前准确版本读取证据。遵守 `.agents/skills/ambush-web-gpt-review/SKILL.md` 与 `.codex/cloud/WEB_REVIEW.md`，不重置旧诊断 checkpoint 或把连接健康当成代码批准。手机与真人体验仍按用户决定暂缓。

## 已采用的契约

- 仅院子启用显式弹药；三人携带 Kar98k/MG42/精准枪，起始应急弹药 1/3/1 发。
- 西侧 `(6,12)`、`(8,13)`、`(11,16)` 三箱分别为步枪 6、机枪 47、精准枪 5 发；实收后预算仍为 7/50/6，暂不凭空宣称已完成平衡。
- 东侧 `(26,12)` 一枚手雷是可选绕路交互，不设为开战条件。交互点由 9 减至 4；不再教学其他型号、地雷、诱饵。
- 装备/切枪不提供 start_ammo，空枪仍为空枪。ammo_pool 为所持枪族携行弹药镜像，不是隐性补满弹匣；显式规则下多收弹药保留为同一携行预算，不在换枪时丢失或再生。
- 递枪、丢枪与回收需保留实际弹量，包括零弹；同枪族弹药随枪族预算交接，不克隆到两把同族枪。不同枪族弹药不可自动装入当前枪。
- 当前重试仍是资源回初始 1/3/1 并恢复四箱，不能滚存失败所得；快速检查点属于 M2-D。
- 两波、自动执行、冻结、寻路、视线、伤害保持不变。其他五关不启用显式弹药，保持刀开局和历史领枪补弹规则。

## 验收门

新增隔离 `m2_yard_supply_gate.gd`：实际走路与搜箱获得精确预算；高点标准方案无可选手雷实际通关；逐队员核对真实 fire 记录与余弹账；空枪反复装备/递交/丢弃回收不增弹；错族弹药与携行超额不丢失；可选手雷实际走路取得并只能消耗一次；真实 abort→continue 恢复基线，多次 setup 不增殖；五关旧装备路径复查。

图形保存开局补给与补给后高点两张 viewport 图，逐张检查。另跑无窗口同 gate 与受影响 M2-A 界面 gate。共享 smoke 的旧院子资源断言随契约更新；共享 smoke 若未实际完成必须明确说明，不以编译检查替代全量通过。所有执行清档入口必须走隔离包装器，记录 exit code 和玩家数据守卫。

## 风险与下一步

预算沿用旧成功方案，尚不证明弹药选择有趣；三箱步行路线和可选工具尚需首玩计时。B2 将用单次主接触验证高点交叉火力与地面爆破方案，至少一套不上高台，并补各自反例和误差容忍。同步发动只在 M2-C 改，快速重试只在 D 改。真机触控、音频根因、5 人试玩和外部 GPT 不因本切片关闭。

## 执行结果

| 验证 | 运行与实际结果 |
| --- | --- |
| 图形资源 gate | `315fcd38a6fe4dc7b103a3ccdd0d70f4`，wrapper exit 0，`M2_YARD_SUPPLY_OK`，`PLAYER_DATA_UNCHANGED=1`；[引擎日志](evidence/m2-b1/rendered-supply.log)。 |
| Windows headless 同 gate | `20c3192fc9dd464ea1418752916fd850`，wrapper exit 0，相同完成/隔离标记；[引擎日志](evidence/m2-b1/headless-supply.log)。不宣称 Linux/云端已运行。 |
| 受改动影响的共享资源组 | `72819412f08a4d0298d10a588e1861c0`，wrapper exit 0，`M2_SHARED_RESOURCE_CONTRACT_OK not_full_smoke=1`，玩家数据不变；[日志](evidence/m2-b1/shared-resource.log)。入口 `m2_supply_regression_gate.gd` 继承共享 smoke 的真实 `_assert_raid_contract`，覆盖背包、递物、工具、软开战门等，不替代六关完整运行。 |
| 最终提交 M2-A HUD 回归 | `45c36c68826a40dd99e3c2355c379d05`，wrapper exit 0，`M2_YARD_HUD_OK`，玩家数据不变；[日志](evidence/m2-b1/hud-regression.log)。鼠标/合成触控、冻结、胜利/真实侧翼逃逸与只读复盘通过；不是手机证据。 |

归档日志只包含引擎 stdout；包装器退出码和存档守卫结果按工具实际返回单独记录在上表，不伪称日志包含全部尾部标记。

最终实际游戏 viewport 图（均为 1280×720，逐张目视）：

- [插入点与四处补给](evidence/m2-b1/insertion-supplies.png)：基础枪已携带、选中灰狼 1 发；基础弹药在西侧，手雷在东侧。
- [实收弹药后的高点部署](evidence/m2-b1/supplied-highpoint.png)：夜枭实际沿坡道到台上、6 发，东侧手雷仍未领取。地图仍是旧暗色资产，不冒充 M2-E 最终视觉。

标准方案沿用 M1 精确枪械型号与真实路径，没有测试脚本置胜或注入成功方案弹药。实收 7/50/6 发；权威 fire 次数 3/6/2，余弹 4/44/4，三账相符。可选手雷不作通关前提；本切片只验证它的真实搜箱及单次消耗，不宣称地面爆破解已完成。

### 失败/未完成迭代

首次图形运行 `a3dbf9cf7af6421cae9e2727e211a7d0` exit 0，但自查发现用了泛型 scout 而不是旧精确型号 Kar98k ZF；已更正再跑。该早期运行不能作为最终数值证据。随后补充了有弹/空弹递交回收、零量弹药、携行溢出及教程文字核对，最终图形/headless 结果以上表为准。

共享六关 smoke 首次 `30fe548a4a9442e39b5d66d46e55bad5` wrapper exit 1（[日志](evidence/m2-b1/full-smoke-first-failure.log)）：此前测试展开了战术层，后续旧触控折叠断言未恢复前置状态，报 `SMOKE_NORTH_TIMELINE_ON_SCOUT`。已在该断言入口明确折叠，而非取消检查。

第二次 `26ac1c45a4ce440a98feb6da9793b597` 在旧触控随队系列连续运行超过十分钟，已通过上述折叠项、随队避锥和 margin 项，但尚未到六关终局。核对进程为本隔离工程的 `smoke_test.gd` 后主动有界停止，wrapper exit 1，`PLAYER_DATA_UNCHANGED=1`；[部分日志](evidence/m2-b1/full-smoke-bounded.log)。没有完整完成标记，因此全量回归明确待补。此运行还早于最终少量弹药/状态文案完善，不是最终提交的全量证据。

本轮没有修复旧随队性能瓶颈，也未绕过它写全量成功。下一步先保留待补门，再开始 B2 的独立规则提案；B1 的定向通过不关闭外部 GPT、Android/vivo、AudioTrack 与真人门。
