# Ambush Loop 云开发交接 · 2026-10-08

本文件交接当前迁移候选，不是成品验收。用户要求完成当前本地切片后转云开发；不要另起项目或回到旧简化3D基座。

## 1. 直接接手位置

- 仓库：<https://github.com/hailinsu-create/ambush-loop>
- 分支：`codex/cb5-migration-closeout-20261008`。必须从该分支最新提交接手，不从当前旧 `main` 开始。
- PR：[#50](https://github.com/hailinsu-create/ambush-loop/pull/50)，Draft，base 为 `codex/cb4-teaching-20261008`。这是 PR39→50 的叠加迁移链；未合并主分支，也未合并或改写协作者 PR15。
- 代码冻结：`81d46f3ab54fe0ec9a31010a99c52704155dd179`。随后交接/证据文档提交不修改游戏代码；云端另行记录自己实际的 `git rev-parse HEAD`。
- 协作者固定源：`891f967eda36f3be326d3243cd676a83d5568f52`；本地旧实现仅作为规则供体。
- 工程：`ambush_loop/`，Godot **4.7.2**；候选完整3D场景 `res://scenes/presentation/yard_3d.tscn`。正式发行默认3D仍未强制切换。
- 先完整读 `AGENTS.md`、本文件、`PLANNING_INDEX.md`、`AMBUSH_COLLABORATOR_BASE_PLAN_20261007.md` 和 `AMBUSH_CB5_MIGRATION_CLOSEOUT_20261008.md`。

## 2. 已落实的内容

CB0保留协作者六关场景、骨骼角色、岗哨、枪火/死亡/尸体、镜头和回放主体。CB1接入触屏预览/就近确认/取消、双指相机所有权和方向柄，收敛HUD。CB2接入权威高度/坡道/LOS、历史地形、完整对象锚点和轻量状态说明。CB3院子开局少量枪弹，实际开箱到7/50/6；高点与地面两解，一次接敌，独立侧翼延迟4秒。CB4完整准备世界失败恢复、奖励回滚与四步短提示；复盘不借现局补齐历史。

当前本地收口修复的是迁移后不适用的测试前提，没有把错误夹具的规则改回游戏：

1. 跨FPS比较前先校验实际嵌套枪火/姿态的来源身份，再仅规范化随机尝试前缀；保留波次、序号、时间、命中、坐标及其余事件字段。
2. 尸体跨波次夹具从新单波院子移到真实多波仓库，保留跨波来源/取消/真实敌人死亡断言，增加非空下一波守卫。
3. 外来历史枪火夹具明确给3发手枪弹。装备枪本身不能生成弹药，不能修改生产规则来让测试开火。

## 3. 本地实际证据和源码边界

以下通过均有实际 engine/wrapper退出0、日志错误0、PLAYER_DATA_UNCHANGED=1。新包装器把后检写入独立 `wrapper-result.json`；`run.log` 本身不包含这些包装器后检。

| 内容 | run / 源码 | 实际结果 |
| --- | --- | --- |
| 六关完整模拟/回放矩阵 | `dd2f017252e54a988bf1d95767fa4a19` / `10da118` | 12948/0；每关3次，共18场、36波；六关记录均完整 |
| 高度真实射击/3D锚点 | `b1ce68654d01495083a0cc2fce01b139` / `0309661` | HEIGHT_FIRE_GATE_OK，真实枪火2条 |
| 触控/鼠标交互 | `84afc20e94e549028981610aa646a2c7` / `0309661` | 80/0 |
| 完整准备重试 | `3cac5384b4124b35bc46f8e8d9a9ccb2` / `0309661` | 85/0 |
| 四步教学 | `105d0afe482b4664bd29e164bca0107e` / `0309661` | 12/0，headless；真实截图另见CB4文档 |
| 尸体原流程/跨波次 | `edd943c1694a45ba8e635953339e1438` / `d8bc6da` | 1205/0 |
| 枪火表现池/旧历史 | `a6b48098bc304b8ebcc8a542c2549b4a` / `81d46f3` | 225/0 |
| 工具表现池/旧历史 | `b02573c42a074ebf8449a5daf1fbc002` / `81d46f3` | 255/0 |
| 素材库 | `05bbba33134348fb99c8d21b2c9cbf70` / `81d46f3` | 4069/0 |
| 六关环境资产 | `254adb5c41f24dbb9fc2b6b392084748` / `81d46f3` | 610/0，40种资产/80个LOD |
| 3D拾取/表现合同 | `ed7dcdc445654460b9f7acb5749acc03` / `81d46f3` | 83976项；拾取矩阵48416个样本/72个姿态 |
| 画质/布局合同 | `dd7e031ca3de4aff91f90b6477bdb418` / `81d46f3` | 102/0，headless不包含截图验收 |
| 历史逃逸归因 | `7fb23b3517e542b0b1fa67ac62134cc1` / `81d46f3` | 70/0，包含真实电台第三波逃逸 |
| 真实QA PCK空工程资源门 | `40d2ded57718406e913775b815e89f0e` / `81d46f3` | 1766/0；角色/动画/原PCM音频/纹理/六关环境实际从包加载 |

六关终态 tick/events：yard258/33；warehouse1191/67；pump907/34；railcut719/38；depot957/35；radio1413/51。院子合同已改，其余五关原基线未放宽。FPS/倍速是模拟步长与表现刷新频率夹具，不是手机实际帧率测量。直接站位/准备工具也不是自然触屏或陌生玩家证明。

`10da118`→`81d46f3` 生产main/operator/level/presentation/世界检查点未变；变化是测试、包装器、CI和入口说明。以上不同提交的证据明确分列，不拼成一个最终SHA的完整验收。云端必须在自己的最终冻结源码上再完成整批门。

原红灯必须保留：`350860e0c1d04056bf16b9081eda4e74` 六关12330/6、engine/wrapper1，随机嵌套ID比较失败；`42330219989740509351e8244a0927f0` 尸体1200/1并有空队列SCRIPT ERROR；`16a0182c698a4e8a9db192a71039dc58` 枪火224/1，夹具没有手枪弹。这些不是现修复通过。

本地QA PCK实际导出退出0、导出日志错误0；大小38,198,184 bytes，SHA256 `6E8FA7DDA73982B0030FFD57C50E34ED22220C978513163253B9B6E1916D1DA2`。物理包留在忽略的 `ambush_loop/build/cb5_pack_7b76cf3b4325427594b8a9c8833c71d6/AmbushLoop-QA.pck`，不放Git。原导出日志和测试/包装器回执归档在 `evidence/20261008-cb5-closeout/`；云端须自己重建，不假定可以读本机build。QA包不是Android APK或最终发行卫生验收。

## 4. 云端下一步，按顺序执行

1. `git fetch` 后核对分支/实际SHA；不要覆盖云端已有未提交修改。若任务默认落在旧main，切到本交接分支再工作。
2. 先查现有Actions状态和精确headSha，不要把旧0309661的结果当81d46f3结果。最新81d46f3工作流run `37740423330`，另一个PR事件run `37740428339`可由条件跳过；必须看实际job/step和日志，跳过不是通过。
3. 旧run `37738503260` / `37738621259` 在交接准备时仍运行，源码0309661含已修尸体夹具缺陷。保留其实际终态，不当新修复验收，不手动重复启动或终止健康运行。新run可能因并发组等待旧run。
4. `.github/workflows/cb5-migration.yml` 已配置官方4.7.2二进制与模板固定SHA256、隔离导入、完整六关、必要专项、真实QA PCK导出和空物理工程资源门；执行配置不是通过。下载Actions证据，核对完成标记、每关结果、engine/wrapper0、错误0、玩家档不变，并保存源码和PCK哈希。
5. 云端完整新基座回归用 `cb5_campaign_test.gd`。旧 `smoke_test.gd` 有“首关只有刀/两波/旧箱子”的旧合同，不允许把不适用夹具绿灯当新验收，也不要粗暴删除其余安全断言。
6. 资源/回放旧夹具必须用仓库原件与哈希；不伪造替代录像。枪火/工具旧历史门在本地使用 `AMBUSH_LEGACY_RECORD_FIXTURE` 和 `AMBUSH_INITIAL_RECORD_ROOT`（具体见CB2证据文档），新云环境先按原件清单准备。
7. 整体门通过后再做独立候选导出/包卫生与必要设备后置门。当前QA PCK不是最终发行包，不能以QA脚本仍在包内为发行卫生通过。未完成手机30分钟/真人可读性前，不开启M3正式入口或强制旧发行默认3D。
8. 每个后续切片更新规划索引和证据、走原游戏分支/PR流程、push后核对远端SHA；不改协作者PR15历史。

Linux运行示例（Godot绝对路径按云环境实际调整）：

```bash
bash ambush_loop/scripts/run_isolated_test.sh /absolute/path/to/godot editor_import
bash ambush_loop/scripts/run_isolated_test.sh /absolute/path/to/godot cb5_campaign_test.gd
bash ambush_loop/scripts/run_isolated_test.sh /absolute/path/to/godot corpse_runtime_test.gd
```

## 5. 尚未验收和环境注意事项

- **CB5整体尚未通过**：云端最终源完整结果、候选发行卫生、手机30分钟热/帧时间/内存与真实触屏、陌生玩家可读性仍待。以上本地矩阵不是手机性能修复证明。
- GPT原聊天 `https://chatgpt.com/c/6ac120c9-7a84-83ec-8f5a-b01fd6ba5442` 可以读取，但仅有旧V1局部DONE，没有本轮迁移新PLAN/REVIEW。标注unavailable，不能复用旧批准；用户已允许外审不可用回退。
- 保留原 `c2c_a619`、B1 dirty工作区、原聊天/连接。不要重复送达未知的INIT/EXECUTED，不把本机桥接、登录、配对码或密钥搬进仓库/云端。
- 真机和本机浏览器不能假定在云端可访问；涉及新登录/授权时才找用户。手机个人数据不随本次源码交接复制。
- 本机旧 `ambush-p0` heartbeat已PAUSED，目标是旧M2.5工作树，不恢复它来开发本分支。
- 本机Godot生成的45个音频 `.import` 改动及许多 `.gd.uid` 未混入本切片提交。不要全量stage或reset；云端冷导入生成文件不是新玩法工作。

## 6. 可直接发给云端的接手指令

> 接手 `hailinsu-create/ambush-loop` 的 `codex/cb5-migration-closeout-20261008` 最新分支。完整读取 AGENTS.md、.cursor/docs/AMBUSH_CB5_CLOUD_HANDOVER_20261008.md、PLANNING_INDEX.md及当前有效规划。继续完成CB5云端完整回归、真实打包与后置质量门，不重建项目、不回旧main或第二套3D基座。先核对已有CI精确SHA/终态，不重复启动活动回归；保留旧红灯与玩家数据隔离，未验收门如实记录。每片证据同步GitHub并核对远端SHA，只在确需授权时找我。
