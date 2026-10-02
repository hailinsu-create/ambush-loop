# M1-C2 枪械高度视线接入计划

日期：2026-10-02。状态：实际外部 GPT PLAN 已收到，尚未实现或验收。原对话任务 `c2c_c2a4` iteration 0，已核对原工作区 `363712641ef7`，读取 grid/operator/enemy 与设计。继承已验收 C1 `e2550b7`，不代表完整 M1 通过。用户继续开发并明确暂缓真机。

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
