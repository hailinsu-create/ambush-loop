# V0/V1：院子工业夜袭画面首切片

依据：用户确认按《AMBUSH_3D_VISUAL_UPGRADE_PLAN_20261007.md》提升画面。基线 f2d329d（游戏生产同 ec83205/1d27c42）；实施分支 codex/3d-v1-yard-look-20261007，依赖规划 PR #36。

目标：形成实际可玩的工业院子样板，改善构图、地面与墙体层次、冷暖灯光和 HUD 占用；消除静止人物重复姿态写入，修正导出构建目录污染。仅表现切片，保留权威网格、LOS、路径、模拟、拾取与中性复盘语义。

范围：新增共享静态视觉制作模块/轻量材质，presentation 相机约束及战术卡收纳，人物姿态变化检测，导出排除 build；必要测试夹具适配及专项门。完整人物骨架动画、六关推广、LightmapGI/渲染器迁移留在后续 V2/V3，手机长稳待设备可用。

外审：原聊天新任务 c2c_visual_v1 iteration0 已实际读到完整 PLAN（回答已完成），采用静态模块与共享材质、有限无阴影暖灯、仅 presenter 转换相机、可展开战术卡、pose signature、资源平台和打包排除。明确止于可玩院子首样板，不提前推进骨架动画、GI、战斗特效或 M3。旧 c2c_a619/dirty B1 不改。实施源码仍需独立 REVIEW，PLAN 不是验收。

执行顺序：基线导入/渲染→静态样板→构图/卡片→姿态复用/导出卫生→冻结源码→Forward+与Compatibility实际截图/两尺寸/拾取与资源平台→受影响接缝/触控/两案/复盘→精确包 GPT REVIEW→同步并核对远端。

验收：实际截图前后同镜头；装饰不增加可走格阻挡/可选身份；镜头不改队员位置，边界不出现大片空白；摘要/展开/质量/左右手至少48逻辑px，实际手机dp另验；静态节点/材质/模型身份在600次同步后稳定；静止 pose 写入平台且运动/搜索/命中恢复正确；资源打包不含生成 build 截图。测试均使用隔离包装器，记录实际 engine/wrapper退出与 runtime_errors、PLAYER_DATA_UNCHANGED，保留旧红灯。

当前：V1首样板已实现并完成下面列出的本地受影响门；外审后读不可用，持续卡顿尚未定因；桌面成本/资源平台不替代手机30分钟热态门。本轮不是 V0–V5 全部完成或 M3正式准入。

## 首轮验证记录

表现源码提交 465e993。后续只补充导出排除及 ZIP 资源检查脚本，表现/权威脚本未变化。基线 f2d329d 的 seam run b61c965a8ca9469091e165893d142876 完整 engine/wrapper0、runtime_errors0、PLAYER_DATA_UNCHANGED1；旧首轮 848ea26fa04744ada35182d012997bd4 因新模块 along_x 类型推断报错，engine/wrapper1，保留红灯；显式 bool 修正后重新验证。

| 隔离门 | run | 实际终态 |
| --- | --- | --- |
| V1 Forward+ 两尺寸/四截图/600同步 | 9d3a1b70b7cb46e68cc76312da5a8ed3 | engine0、wrapper0、runtime_errors0、PLAYER_DATA_UNCHANGED1、YARD_V1_VISUAL_OK |
| V1 Compatibility 两尺寸/四截图/600同步 | 38625014649542d2a9df424d98d17a02 | 同上，实际 OpenGL Compatibility 渲染 |
| 新构图 seam：真实补给搜索、拾取、平台、朝向预览/取消、镜头 | 95312da61ee249be870d05f4cf38edf2 | engine0、wrapper0、runtime_errors0、PLAYER_DATA_UNCHANGED1、M2_I0_SEAM_OK；退出有4 ObjectDB警告，未当作零警告通过 |
| 收尾：实际 A/B 两方案通关、终态定位、960布局/摘要/候选 | c409de168cf54e08b463477aa4121f30 | engine0、wrapper0、runtime_errors0、PLAYER_DATA_UNCHANGED1、M25_PRE_M3_CLOSEOUT_OK |

静止600同步后所有节点/模型/材质ID不变、style只构建一次、静止pose写入平台；运动姿态推进与命中闪色恢复断言通过。Forward+ 同步CPU p50=705us、p95=1189us、max=1720us；Compatibility p50=554us、p95=1211us、max=1843us。仅桌面同步CPU样本，不是FPS、手机热态或卡顿根因证明。

实际导出 `Windows Desktop` ZIP，EXPORT_EXIT=0；check_visual_export.ps1 退出0，232资源、banned=0、9项运行必需资源齐备。SHA256=12AB12FD0DA6EEA7213E8205125B5E84BA5B2B21E09D8125374CE09C2890CD61。排除docs/build/ArtSource以及开发门/截图/probe；原证据不删除。此处是资源包检查，不是Windows安装/Android APK验收。

补充门：最终08d9fb3源码触控 run f6f58e77739e44159747ebef6894f833（M2_TOUCH_INTENT_OK/M2_TOUCH_CANCEL_OK；顺序包装器的非零退出guard后继续进入P1B，确认触控wrapper0）；P1B run ff8a477268d8410291e8d2549e2d014e，M25_P1B_DECISION_DISPLAY_OK、engine0/wrapper0/runtime_errors0/PLAYER_DATA_UNCHANGED1。两项均完整结束。

原 GPT 聊天 c2c_visual_v1 iteration1：精确08d9fb3包已git archive并记录执行摘要/隔离测试输出。包 `.cursor/review_packets/visual-v1-executed-08d9fb3` 位于原只读B1，SHA256=3E6413D4B57D274EF368DBC269181E11CAD3FF54B1A8D4B2AE18E4A43240C7A3。EXECUTED填写和Enter返回成功；随后两次60秒上限的DOM后读均超时，因此送达/回复未验证，REVIEW=unavailable/pending，不能声明DONE/approve；不重复发送、不改旧会话/连接。恢复后先只读原聊天核对本精确包。

实际前后截图已保留到 `evidence/yard-v1-20261007/`（before-seam/after-seam是同一隔离接缝夹具，默认镜头因本次设计不同；并非同镜头性能对比）；compact-1280为新V1门实际截图。未使用概念图代替实际游戏。ADB devices本次为空。

下一步：先恢复读取本次外审，再实施V2静态环境细化与V3人物剪影/动画独立切片；手机长稳、真人操作、完整人物模型/动画、环境铺陈和V2–V5仍待完成；发行默认3D门未放开。GitHub同步只登记远端核对过的源码，不把本地受影响门扩大为六关新全回归或手机验收。
