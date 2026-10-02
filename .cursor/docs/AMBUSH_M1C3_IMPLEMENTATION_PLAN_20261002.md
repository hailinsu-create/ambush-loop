# M1-C3 选中枪械队员高度覆盖实施计划

2026-10-02。原 GPT `c2c_d38a` iteration 0 实际 STATE: PLAN，核对工作区 `363712641ef7`；继承 C2 `e55a521` 的完整回归及 DONE。此文替代 C3 预研的待确认状态，尚未实现/验收。用户继续暂缓真机。

## 范围与理由

SETUP-only 的独立世界坐标 Node2D 图层，对当前选中、存活、可见的枪械队员采样 `_active_routes`，逐点调用 `in_fire_geometry`。使用独立小标记，不连线、不填面、不做其他队员并集。旧 aggregate killzone 和黄色方向扇形不改；几何覆盖不保证弹药/hold/冷却已允许开火。无持久缓存，不修改战斗、音频、路径、资源、冻结或回放。

生产仅 main.gd；新 `m1_height_coverage_gate.gd` 与两种隔离包装器。选择/转向/换枪/门/重置沿既有 killzone 刷新点同步；普通 SETUP command tick 比较实际选中队员位置，仅在其移动后刷新。掩体吸附临时 selected 恢复后明确刷新原身份，避免留下临时队员覆盖。阶段非 SETUP 必须清空/隐藏。

## 验证与证据

新门检查 LOW/FULL、地面与平台、混合高→低近高端 LOW 可通/近低端 LOW 拒绝、射程/朝向、未选中队员不贡献、近战抑制、重复刷新不累积；真实 ordinary move 和另一队员 snap 路径不手工兜底刷新；HP/弹药/朝向/路线/日志/tick 不因纯刷新改变。世界坐标与镜头 pan/zoom 不改变覆盖成员，无交互 Control。

隔离执行 C3、C2、C1、B2、feel focused UI；记录实际退出码和玩家数据不变。截图显示 LOW、mixed-tier、FULL、普通移动/镜头后的标记，Codex 目视和 GPT 独立评审。C2 已完成 fresh full smoke；本轮只观察移动并增加派生视觉，GPT 不要求再次六关 smoke。若改变共享移动语义/既有 killzone 行为或定向门有回归，再扩大回归。截图与 headless 结构门分别记录，不互相替代。

代码独立 C3 分支/PR，依赖未合并 C2 PR #16；文档独立 PR #9。精确镜像 C3 差异而非覆盖 dirty main；释放实际成功/失败输出供原 GPT 评审。C3 完成不等于完整 M1/B2、Android 或 AudioTrack 修复。下一步实现、测试、截图、送审，再更新此文和索引。
