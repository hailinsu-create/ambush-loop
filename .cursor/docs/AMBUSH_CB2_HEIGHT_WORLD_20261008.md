# CB2 连续坡道与真实高点表现

源码冻结：`3f50735`，父规划与来源见 `AMBUSH_CB2_HEIGHT_20261008.md`。本切片不代表整体迁移、云端或真机通过。

## 实现

- 逻辑、人物/尸体/特效锚点、射击视线和镜头拾取共用连续坡道插值；快照高度版本2，版本1保持阶梯映射，缺失版本保持旧平地。
- 院子新增一格低货箱；高台不是伤害倍率。实际模拟产生友方开火与敌方反击，3D人物、枪口和目标高度一致。
- 环境装配版本2显示低货箱；原版本1仍可读取并保留自身装配身份，未知版本拒绝，不以当前地图重解释历史录像。
- 修正 PowerShell 单个参数数组被展开为字符的问题。修正前所谓 headless 测试实际使用 Forward+，已有成功结果仍有效但不能称为无渲染测试；此后 headless 与 Compatibility 渲染明确分开。

## 红灯保留

- `dd8f032` 输入测试遇 presenter 缩进解析错误，没有完成；精确核对该测试进程后结束该子进程，wrapper=-1，玩家数据未变。不算通过。e72aba5修复后输入80/0。
- `afaadeaa54c1498bbce8c65d86748321` 高点表现测试 wrapper=1：夹具清空 BattleLog 后未初始化现代回放身份，真实伤害存在但reader拒绝无身份事件。新增测试钩子使用正式 begin_attempt/continuous_playback=2；未制造特效或放宽两条弹道断言。
- `cc09e33f81114b5f8caf3962304ef5bc` 夹具修正后逻辑通过、wrapper0、玩家数据未变，但受限环境出现系统证书错误；不记 runtime_errors=0，后续非受限隔离复验替代。

## 终态证据

3f50735冻结源，顺序隔离矩阵实际退出0，各引擎/包装器0、PLAYER_DATA_UNCHANGED=1；逐日志未出现ERROR/SCRIPT ERROR：

| run | 范围 | 结果 |
| --- | --- | --- |
| 3ff3efe39ed24eafa929e4f8f0af8359 | 真模拟高点人物/枪口/反击、30次只读池复用 | failures0，active_shots2，HEIGHT_FIRE_GATE_OK |
| 0986b869def4446aaa40ee742afba01d | 真实取箱/历史装配身份/未知版本拒绝（crate_only） | 13/0 |
| 639dc7c2ebc54bbbb65639d924defd4a | 快照、历史与HUD | 130/0 |

另当前地形产品e72aba5：高度117/0 run7c8bae4d1ad04066a740ac28031d5d23；真实射击fc65b8b9cc304de792be7ad8d68218e3；输入80/0 run783035a7c8c94ce4965c354c9fbc8669；3D守恒83976/0 run46879a14dedc40949d85b26b1cd9d665。均wrapper/engine0、玩家数据未变。

实际Compatibility渲染 run4cb7fb6ec7364dca91b601a6b6455058：wrapper/engine0、玩家数据未变；`captures/high-shot-and-return.png`已目检双方抬升人物与两条弹道。该图是追加环境版本前同高点产品，不代表全关或手机目检。

## 下一步

补轻量射界含义/弹药/许可/冷却说明，继续CB3院子明确弹药与双部署、CB4完整世界检查点和教学，最终冻结六关与构建。外部GPT本迁移仍unavailable；真机/真人/云端门待实证，发行默认不切换。
