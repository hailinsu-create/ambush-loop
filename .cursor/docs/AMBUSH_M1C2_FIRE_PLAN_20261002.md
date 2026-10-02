# M1-C2 枪械高度视线接入计划

日期：2026-10-02。状态：已实现、五项定向门通过且 GPT scoped REVIEW clean；**完整回归仍未完成，NOT DONE**。下方初稿和实施前修订均保留，实际进展见末节。原对话任务 `c2c_c2a4` iteration 0，已核对原工作区 `363712641ef7`，读取 grid/operator/enemy 与设计。继承已验收 C1 `e2550b7`，不代表完整 M1 通过。用户继续开发并明确暂缓真机。

## 目标与范围

让敌我枪械 eligibility、准备期覆盖预览和黄色枪械射界共用 `has_height_los`。高点只越过矮遮挡，不改伤害、射程、命中、弹药、冻结计划、音频或关卡资源。拾取、观察、岗哨视锥、手雷工具仍使用旧 LOS。近战需明确保持旧遮挡，不能因共用 eligibility 顺手获得隔矮箱刀杀。

GPT 实际审计指出：operator 的 `in_fire_geometry`、`engage_block_reason` 与 `_los_clip_distance` 是枪械入口；enemy 的 `_try_return_fire` 是反击入口。回放读取记录的 snapshots/events，不重新模拟 LOS；保持这一边界，验证允许/拒绝的射击事件，不另造回放计算。

## 实施与依赖

1. 此计划与索引在独立文档 PR #9 提交并核对远端，然后从 C1 分支建立 C2 代码分支。
2. operator 增加单一枪械 LOS helper，三处入口共享；enemy 仅改反击遮挡。保留所有非枪械调用。黄色扇形的离散采样遇到不可站障碍不能直接把其作为目标判定后停止，否则高处仍无法越过 LOW；需要结合真实目标高度与测试澄清采样语义，不能假称扇形精准覆盖任意高低目标。
3. 新增 `m1_height_fire_gate.gd` 并登记两种隔离包装器。记录信号/事件、弹药与 HP，合成地面 LOW 拒绝、高处 LOW 开火、FULL 拒绝、反击相同规则、预览一致、正常伤害/射程/朝向/hold/ammo 约束、非枪械 LOS 不变。任何发现的可视采样契约冲突应补请 GPT 决策，不自行扩大产品规则。
4. 经包装器执行新门、C1、height、ramp、B2；本次改战斗，必须 fresh full smoke 完成 `SMOKE_SLICE_COMPLETE`、exit 0、`PLAYER_DATA_UNCHANGED=1` 才能宣称 C2 验收。
5. 精确镜像本轮差异，保留旧诊断修改；外部 GPT 独立读取源码与实际执行输出评审。独立 Draft PR，不自动合并。

## 成功门与风险

成功仅为 C2 枪械接入的自动化与实际 GPT review，不包括完整 M1、视觉样板、两案玩法、Android 或 AudioTrack 修复。回放是既有事件消费，事件测试不等于新回放画面验收。cell-center Bresenham 非 supercover；黄色单一扇形对不同高度目标可能不能表达全空间视线，必须记录边界。真机与长时音频门仍 pending，手机插入后补验。

下一步：保存计划后实现单一切片，完整回归与外部评审完成前保持未验收。

## 实施前实际 GPT 修订

Codex 指出径向采样会在 blocked LOW 端点先停止，单一连续扇形无法表示不同目标高度或不连续可见区；GPT 随后明确修订范围：**只迁移目标特定的枪械资格与覆盖查询，保留黄色扇形的旧裁剪作为有限方向参考，不声称 cone parity**。近战明确使用 legacy LOS。替代以上第 2 项“三入口共享”和第 3 项连续扇形一致性的初稿；目标点 `in_fire_geometry` 与资格必须一致。准确的高度射界可视化留待下一 UI 切片，因此完整 M1 的“预览与模拟一致”退出门仍未闭环。回放仍消费既有事件；此次验证必须区分真实 BattleLog 与单纯信号，不能把信号伪称回放实证。fresh full smoke 要求不取消。

## 在制实现与实际评审（完整回归未完成）

代码 [Draft PR #16](https://github.com/hailinsu-create/ambush-loop/pull/16)，分支 `codex/m1-c2-fire-height`，源码 `e55a5216b2512a10d3bf6713081a66c4586cfcf1`，依赖未合并 PR #13。只有 operator/enemy、一个新 gate、两份包装器五文件。没有 main/audio/资源/回放源码变更。原镜像 operator/enemy/gate blobs 分别 `479fbc3ccc69c75ffaad9900621d12a7dac101d5`、`bd89d1c5004497e713d7e117daf5500e9dd4c74e`、`5c06a31c0259420574ac4f3697ef0fa8871782c6` 与源码一致；其他诊断差异保留。

Godot 4.7.2 规定隔离包装器五项均实际 exit 0 / `PLAYER_DATA_UNCHANGED=1`：新 firearm `5fcc13b82ec048ea9ca16f97c8254159`；C1 `f16a4fc2976d499fabae534de0d9f049`；height `8422fa9bad664ad294748b945fc8befd`；ramp `c57c411100a04a9e86a30740fd14b157`；B2 `d61277f15cac453cbedea35bc749c4f4`。新门调用真实 main `_sim_tick` 与 BattleLog，再绑定 ReplayPlayer、改变遮挡后证明仍只读取记录；地面 LOW/平台 LOW/FULL、敌我正常 HP/弹药、射程/方向/hold/ammo、近战 legacy 非空洞反例、无 grid 拒绝均通过。

最初 gate 两次 `92dba38b5329408cb9ed415490f0b548` / `496ab97523a64992be6c6abda5200b9c` wrapper exit 1：空 route 的剩余路程为 INF，不被既有优先级选择。保留失败日志与 C2 执行记录，改为有限单点 route 夹具后最终通过；没有改生产目标优先级来凑测试。

原 GPT 实际 iteration 1 REVIEW：范围内代码 clean，五项输出已读，无需代码修正；**NOT DONE**，等待 fresh full smoke。确认为 amended scope：枪械/近战分流，enemy 无 grid 拒绝，cone 不声称精准，真实 BattleLog/ReplayPlayer 而非假事件。完整 smoke run `4a70428c37ab43699b9d9ec4d330d41a` 正在运行，尚无完成退出证据，不能记 PASS。不得切换或修改正在运行的代码工作区。接手需续取原进程 session `4903` 的结果，不重复启动；若会话不可用则核查日志和进程，不能靠历史通过替代。

待完整退出 0、`SMOKE_SLICE_COMPLETE`、六关典型循环、玩家数据不变都齐备，再送原 GPT 完成判定；若失败，只处理首个具体失败，保留高度规则门。准确射界 UI、M1 整体玩法/Android/音频均未验收。
