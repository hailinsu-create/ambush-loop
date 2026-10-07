# PR15 成功丢弃立即取消工具动作 P2

运行修复固定 `47f0634f5e1a5f1dfb94a996037b6ae71c954cfd`。测试/数值订正 `6e9ed4c7e26a16518ae4706515e353991859e2b6`；最终专项render测试 `3e09a82d3df2cb124049449450e80028c72bfd13`。生产代码相对518b5d仅main.gd成功drop多一行cancel_utility，测试后继运行树与47f0634等价。PR15仍Draft/Open、未merge/生产，无制作源/GLB/atlas修改或重跑。

SCOUT成功投雷后，真实_on_pack_drop丢当前rifle，原普通_process更新立即自动拾回rifle；两步之间无presentation capture，最终weapon相同，旧weapon stamp仍匹配并复活grenade_throw。b082540只加实际handler反例，源运行字节仍518，headless6/1失败、实际退出1。47f0634在rec.ok后、spawn_loot前立即cancel，阻断丢弃/拾回之间的旧动作；失败drop和phase拒绝都在该行之前返回，未改变装备/拾取/投射物/库存规则。既有cancel入口也取消尸体瞬态，原haul引用不改。

| 固定源 | 命令入口／实际结果 |
| --- | --- |
| b082540 | AMBUSH_UTILITY_TEST_SCOPE=drop_roundtrip，utility_runtime_test.gd headless6/1，exit1 |
| 47f0634 | 同一反例headless6/0，exit0 |
| 6e9ed4c | scope=drop_cases headless13/0：原枪drop/pickup、失败不取消、同枪手雷装备drop/pickup、ALERT拒绝不取消真实ALERT投雷 |
| 6e9ed4c | 完整工具--render1047/0、装备锁headless66/0、尸体headless1203/0，全exit0 |
| 3e09a82 | scope=drop_roundtrip --render7/0、实际恢复枪帧、exit0 |

完整实际命令、source、独立StorageGuard/XDG、durable shell exit、日志/hash和7张已看的原framebuffer见[证据](evidence/20261002-pr15-drop-cancel/validation.json)。完整render6帧来自6e9；专项恢复枪帧来自3e09。第一专项6c23e render7/0曾有4 ObjectDB退出警告，最终测试调用已有AudioDirector.pause_for_background再退出，最新无该警告；保留前日志，不把此测试收尾称A3内存/设备性能通过。

尸体正文数值已按518原receipt订正：范围−0.00123487412929535至0.10103178024292m；最低operator_rifle/enemy_flank/LOD2/stand，最高operator_rifle/enemy_patrol/LOD0/crouch。validation.json和runtime-report.json原字节不动。原正文误沿用较早夹具0.003765最低值；−15mm最低门限只验证穿地，不能推导自然接地、离地上限、墙体接触或完整SWEEP玩家拖尸已验。这些保留独立待验。

下一主作者包继续已复现desktop HUD覆盖目标/历史事件与radio yaw345整天线隐藏，再FX/A3/13波visual/完整smoke/APK。可并行只读QA此固定树的drop/pickup/equipment往返及尸体SWEEP/艺术接触；主作者独占共享运行代码，制作作者仍通过候选SHA/版本兼容/三LOD contact与端点证据交付，不直接覆当前资源。若后续改R5新clip，须审查旧R5 64clip/297历史兼容。

本小片不重新导出：最新技术PCK仍91b9bdc、早于此drop修复；六关10332/0归304源，不冒归此片。最新完整smoke7d34867；APK、耳听0/45及0/6、设备仍按全计划顺序继续，未关闭全部计划。
