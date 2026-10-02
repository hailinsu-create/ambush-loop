# PR15 尸体来源、肩掌配对和回放切片

2026-10-02。运行修复固定 `30482940a3b873ec146b68e9a907c2869ccb2b3e`；最终测试／导出 `91b9bdc038afea5b8edd73f9cacc40ead7c74c5b`。后者只比运行源新增两项测试覆盖，生产运行树 diff 退出0。PR15保持 Draft/Open、未merge/生产，不混高度玩法。主作者只修改main／C2真实事件挂点、presentation/replay和共享测试；art／ArtSource相对41eff0f diff退出0，未编辑或重跑制作源／GLB／atlas。

## 真实事件与显示边界

成功C2绕背和EnemyRunner真实死亡产生的原LootPickup绑定独立scope、body ID、原source group/actor/attempt/wave、模型、朝向及位置。节点弱引用只在实时记录器，历史全为复制值。原BattleLog schema2保持，Actor schema3下增加可选corpse_schema1；旧/未来尸体版本、旧R4/R3记录和没有新字段的R5记录沿用原演员死亡／背负表现，不用当前活体补数据。跨波保留原body/source wave，原演员实例决定替代关系，后波复用数字label不会绑定旧尸体。

H键成功时才记grab，放下时记release。仍即时调用原haul/drop和负重规则，loot逻辑坐标仍为原屏幕轴`op.pos + Vector2(0,14)`；普通无来源掉落继续可背负，绝不推断新corpse。松散ammo即使背包满也照常自动拾取，这一行为没有被动画阻挡。演示配对段明确为手动推进command clock而暂不tick原自动拾取的夹具，自动拾取取消另有真实handler验证。

每帧先重置模型显示transform，根节点保持复制的逻辑loot位置。body corpse_dragged固定phase0与当前操作员实际左右palms配对；肩点取旧upper_arm.L/R骨原点。grab/release使用 held endpoint anchor 采样corpse_lift/lower，ground的0.20m后移已内嵌在制作骨姿，运行未额外加20cm。手动满刷新／前后seek不积累位移。蹲姿保留原八根下身骨，枪／工具隐藏只属显示；ALERT取消command配对，原haul引用保留。

换枪、原后续动作、移动、换实际carrier、死亡、collection、phase/wave/attempt变化和重启都取消瞬态；选中别的队员本身不改变原物理carrier。原共享haul引用继续允许，原follow loop最后有效操作员赢得显示配对，没有新所有权／拾取／碰撞锁。

## 固定结果与反例

| 固定源码 | 实际结果 |
| --- | --- |
| ce932cc | 尸体render770/0、合同84042/0、工具headless1028/0、装备锁66/0、command clock headless27/0 |
| ce932cc | 完整六关10332/3fail，railcut/depot/radio跨FPS记录年龄浮点累加不一致，原终局/事件不变 |
| bf1261c（仅增加差异诊断） | railcut专项1249/1fail，差异只在death_age_s/transition_age_s，默认打印精度显示相同 |
| 3048294 | 时钟改按原domain anchor计算，只在domain切换结算；尸体770/0、合同84042/0、六关13波10332/0 |
| 91b9bdc（仅扩测试） | 实际移动取消／即时follow、三角色×四敌人×三LOD×两姿态72配置、四hold循环采样及抓／放三phase，render1207/0；空物理工程包1766/0 |

所有通过run有独立XDG/StorageGuard、无SCRIPT ERROR、原set -euo pipefail包装器完整TEST_LOG标记；具体命令/日志/hash/固定source见[证据](evidence/20261002-pr15-corpse-runtime/validation.json)。执行环境重连接丢失旧统一会话ID：304组三个成功run由包装器完成标记证实engine/tee退出0；ce与bf两个失败run保存FAILED完成结果，无法再读取其旧tool exit，不把退出1称为已观测。其余成功退出0由统一exec观察。未固定开发parse/fixture错误另存development，排除验收。

四张当前91实际framebuffer抓取／持有／释放／落地已看，保留原战场、HUD及其遮挡缺陷，没有做视觉裁剪。静态72配对最小skinned vertex y范围−0.001234874–0.101031780m，全部接触<15mm，midpoint<0.1mm；所有测试pose最小y门限为−15mm。正向离地高度上限、自然抓握／尸体与墙面穿插不作为此门限通过结论，完整艺术质量仍需复验。

六关原终局tick/事件：yard1283/34、warehouse1191/67、pump907/34、railcut719/38、depot957/35、radio1413/51。13波／30–60FPS／2×实际运行保持。这使用原reference装备和原loot-vacuum夹具，不能称全玩家路径／逐波视觉／设备通过；实际拖尸交互来自SCOUT，完整SWEEP拖尸玩家路径待后续回归。

技术PCK `91b9bdc038afea5b8edd73f9cacc40ead7c74c5b`，25,618,864 bytes，SHA256 `52e14b6b4189af54cb28086b0f36ec08f7201ba24a6be8fa2e823da376562378`，`/tmp/pr15-corpse-runtime.pck`。导出实际0，45原audio import恢复，空物理工程1766/0包含实际尸体sampler与prone根坐标检查。技术包不是最终APK。

## 下一步与独立包接口

主作者继续先修父端明确复现的desktop HUD中下方肖像覆盖目标／历史事件与radio yaw345整天线隐藏；然后完整3D FX／连续command历史与FAILED/abort终局回归、A3 LOD/batch/动画内存、六关13波逐波视觉矩阵、最新完整smoke和可追溯APK。最新完整smoke仍7d34867；耳听0/45、0/6，模拟器／真机依用户顺序后置。

父端可并行安排91固定树的只读来源/取消/历史/接触QA及制作作者尸体自然抓握／离地／墙体接触评审；共享运行代码仍唯一主作者，不自行派遣astra。资产接口仍R5源2974915／交付ebedb82的21原GLB，旧20bones/socket/atlas不变，optional肩点是现有骨原点；不回写制作源或整体并资产分支。独立作者如需改clip，仅交付候选SHA、旧52语义兼容、三LOD contact/skin-floor/端点证据，主作者择验收提交接入。

数值订正：正文此前沿用较早夹具的0.003765m最低值。518b5d已提交validation.json与runtime-report.json原始receipt均为−0.00123487412929535m（operator_rifle/enemy_flank/LOD2/stand）；最高值0.10103178024292m（operator_rifle/enemy_patrol/LOD0/crouch）。本次仅正文订正，不改原始receipt；−15mm最低门限仅检查穿地，不能推导自然接地、离地上限或墙体接触已验。
