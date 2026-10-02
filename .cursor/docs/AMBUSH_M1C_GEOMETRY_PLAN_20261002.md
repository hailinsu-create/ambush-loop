# M1-C1 高度视线几何切片

日期：2026-10-02。用户明确要求先跳过真机，设备插入后再补验；由原游戏 GPT 对话修改 iteration 11 PLAN。本计划替代恢复报告中“设备未恢复时不进入 M1-C”的执行顺序，但不取消任何 B2、M0、Android 或音频验收门。

## 目标、范围与依赖

按设计 v2 与高度 ADR，先实现几何查询，让地面被矮箱遮挡、平台可以越过矮箱，完整墙始终挡线。仅修改 `grid.gd`，新增 `has_height_los`；原 `has_los` 完全不变，不接入 main、敌我射击、预览、伤害、回放或音频。此切片不改变当前实际战果。M1-C 的统一消费者接入留给下一独立切片。

代码从未合并候选 `codex/cloud-main` / `e3faeb5808b5d1b0a62ad9b479aa3f576ec0c3bc` 建独立分支/PR，不覆盖原评审镜像诊断差异。原 GPT 已确认工作区 `ambush-loop-collab` / `363712641ef7`，读取其 dirty `340b819` 的 grid 与高度门及设计 v2；它未找到本机命名的高度 ADR，不能声称已读取该文件。Codex 已另外核对本地 ADR；镜像与候选 grid 基线需比较后实施。

## 几何契约与决策

- 新查询采用单一高度元数据。地面/平台眼高为 terrain tier + 0.5；矮遮挡高 1。射线高度随端点线性插值，触及遮挡顶面也视为被挡。
- 首版明确采用端点所在格的中心和确定性 Bresenham 格列，不承诺像素级 supercover。按格序号规范化射手/目标顺序，保证几何反向一致；之后接入消费者时应另评估边缘擦线精度。
- 越界、非有限坐标、阻塞端点、非法端点高度/中间遮挡类别拒绝；合法同格查询无中间遮挡。FULL 或继承旧 blocked 的格始终挡线；NONE 保持透明但不改变可通行性。
- 不改走路、坡道、旧 LOS、关卡补给、掩体保护、射程、命中率、伤害、音频或存档。真机缺口不记 PASS。

## 执行与验收

1. 保存计划、更新索引，独立文档 PR #9 同步后实施。
2. 增加 `m1_height_los_gate.gd`，在 Windows/Linux 隔离包装器只登记这一个新入口；保留隔离守卫和旧入口。
3. 合成正反例：开阔地面可见；同一 LOW 地面阻挡/平台通线；FULL 与旧 blocked 阻挡高线；正反方向一致；混合高低端点按插值而非取较大高度；越界/NaN/INF/阻塞端点拒绝；旧查询仍拒绝 LOW blocked。
4. 经规定隔离包装器跑新 LOS 门、旧 height data、ramp pathfinder、B2 yard 门，记录退出码和玩家数据不变。完整 smoke 若未重跑，明确记录未重跑，不借用历史通过当本轮证据。
5. 镜像精确新增几何差异及新门，保留原诊断修改，通过原 GPT 对话对实际代码和执行结果补审，再保存结果和源码提交、发布独立 Draft PR。

成功仅表示 M1-C1 几何查询的桌面门与外部评审完成；不表示 combat/preview/replay 已统一或完整 M1/B2/Android 通过。风险：Bresenham 不是完整空间相交、眼高单位与视觉模型还需后续校准；未接入生产消费者之前不能宣称高点已改变火力。

状态：M1-C1 已实现并通过四项桌面定向隔离门、原 GPT iteration 12 实际 REVIEW / DONE；见下方精确结果。不等于完整 M1-C 或玩法验收。手机恢复后另按原安装身份 → B2 视觉/玩法 → 30 分钟连续/60 分钟累计生命周期取证链补验；历史 AudioTrack 崩溃仍未定因。

## 实际实现、测试与补审

代码 [Draft PR #13](https://github.com/hailinsu-create/ambush-loop/pull/13)，分支 `codex/m1-c-height-los`，提交 `e2550b73a29f0cdb19ddd51b963e6b4b5ed487c5`。独立四文件差异：grid 新 API、LOS gate、Windows/Linux 包装器的新入口。其他生产调用者未改；全文搜索新 API 仅找到定义与新门。实施前确认源/镜像 grid 基线相同；送审后 grid blob `584f7e8f813f2204d3e898e69221f12deb093f86`、gate blob `97fe54742679171ae1fe13120d1057e279d46ef0` 均相同，未覆盖原 main/audio/CTA 等诊断差异。

Godot 4.7.2 经规定包装器执行，四次均 exit 0 且 `PLAYER_DATA_UNCHANGED=1`：

| 入口 | Run ID | 实际完成标记 |
| --- | --- | --- |
| `m1_height_los_gate.gd` | `cac76026306447ec8104e39bc06a4c22` | `M1_HEIGHT_LOS_GATE_OK`，低/全遮挡、反向、插值、拒绝非法输入、旧查询不变均为 1 |
| `m1_height_data_gate.gd` | `80b9b9550c914b0ab26fbb8ed5f56e55` | `M1_HEIGHT_DATA_GATE_OK` |
| `m1_ramp_pathfinder_gate.gd` | `1642b4bb603f407fabf1bd031902323f` | `M1_RAMP_PATHFINDER_GATE_OK` |
| `m1_b2_yard_height_gate.gd` | `e386a47b7f5f42f5a91efc7d83b384c0` | `M1_B2_YARD_HEIGHT_GATE_OK`，上/下随队与上/下断坡反例均为 1 |

新 gate 首次 run `39cac0ebccdc4781b0ac7f04cb4df931` 也通过；随后加强非法遮挡反例，先清空其他遮挡并证明同一线通，再设置非法值证明拒绝、恢复后再次通线，以避免负例空洞。上表记录的是加强后的最终版本。

`git diff --check` 通过；full smoke 本轮未重跑，Linux 包装器未执行，不能引用历史结果作为本轮通过。未进行真机、APK 安装、音频长期测试或新视觉验收。

原 GPT 实际读取四份范围内代码/差异及 iteration 12 四项执行输出，返回 `STATE: DONE`：geometry-only slice accepted，无需修正。重点确认：规范化后方向一致、端点高度随之正确交换；LOW/FULL、移除碰撞但仍 FULL、混合高低近端插值等负例非空洞；非法输入拒绝与旧查询未变；认可包装器仅增加新入口，并明确原 CTA 注册不在本结论范围。

此 DONE 仅结束本轮几何目标，不代表旧原生崩溃定因、整阶段通过、GitHub 正式 review 或主线合并。已达到本协作任务第 12 轮且当前小目标完成，不继续扩展同一轮。下一独立切片应先请 GPT 规划敌我射击、预览与回放同源接入，再实现并重建受影响回归；手机插入后恢复待补真机链。
