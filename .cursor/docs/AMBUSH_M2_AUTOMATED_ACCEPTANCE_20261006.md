# M2 固定源码桌面自动验收

生产/测试源码：`0f53512929fffd57059e9e240afff9e4ab27451f`，分支 `codex/m2-f-operable-guide`，Draft PR [#35](https://github.com/hailinsu-create/ambush-loop/pull/35)。后续验收文档提交不改变生产源码。总入口：[M2 整合收尾](AMBUSH_M2_CLOSEOUT_20261006.md)。

当前状态：17 项专项通过；完整 smoke 首轮退出 61，测试契约适配后待重跑，不能宣布 M2 全部验收完成。手机/真人按用户指示暂缓。以下“原生触摸”指 Windows 两个合成视口中的实际 InputEventScreenTouch/ScreenDrag 与 GUI 分派，不是 vivo 真机、设备 dp 或人体误触率证据。

## 专项矩阵

各项经 `run_isolated_test.ps1` 执行，engine/wrapper 均退出 0，stderr 文件 0 字节，PLAYER_DATA_UNCHANGED=1；源码固定后串行执行，原生时间轴门另行同源码真实 Vulkan 执行。E/F 同样使用真实 Vulkan 渲染，非截图替代代码验收。

| 门（scripts/ 下的入口） | run |
| --- | --- |
| m2_preparation_checkpoint_gate.gd | `1be979b0206148949ed10684e9e7af72` |
| m2_c_team_fire_gate.gd | `63d1aaaee219425aa77136e3fd1f7598` |
| m2_c_auto_baseline_gate.gd | `b4757ed7f25d466ebc0f1a086c02caef` |
| m2_single_contact_gate.gd | `2a9102f0c4014a848730c26ffbc8cd42` |
| m2_yard_supply_gate.gd | `ab7a554c42aa48529cffa5da15300bd8` |
| m2_supply_regression_gate.gd | `309db1bc422b47f1b9dc574ab3747105` |
| m2_touch_intent_gate.gd | `dfef8c57c20f49e18a8250cbba4713ae` |
| m2_touch_target_gate.gd | `e7e5b3fe5d9646d9a7e368e6b53a8c18` |
| m2_role_dock_gate.gd | `16ec9ecf61984c77b059337ab45d34fd` |
| m2_yard_hud_gate.gd | `e101daf6e99d4f2ba7add0603dc784a7` |
| m2_i0_3d_seam_gate.gd | `0d4b235e9663425e8578b4a9b28a2226` |
| m2_integrated_campaign_gate.gd | `9acee0df1934415d93f3c6a1caa73ae4` |
| m1_height_los_gate.gd | `841d82e2f0a542bab3a3d86043639508` |
| m1_height_fire_gate.gd | `4dc4e6f3ea5c47bc8f8cf216ecaf78c0` |
| m2_e_yard_presentation_gate.gd（Rendered） | `f9ec749884c54f62b4b80d00bdd14d67` |
| m2_f_yard_guide_gate.gd（Rendered） | `4b2f2a8ec60c41bebd9eeb1c7d326ec8` |
| m2_replay_lifecycle_gate.gd（Rendered） | `891e01b197ef4b049716071d4b6dd752` |

D1 二十次恢复无资源增益，额外十次严格计时 705–1268ms，仍要求 <5000ms。原生时间轴门真实搜集手雷、部署地面/雷点、实际失败；原生点击复盘、点按与拖动时间轴、返回 FAILED、原生准确恢复 MANUAL 补给/工具/雷点/箱子/方向，排空战斗许可队列；原生重新搜集回到基础 1/3/1 与四箱。两尺寸全部可见复盘 CTA 枚举恰好一个，至少 48px、在屏幕内、互不重叠；回放前后日志、血量、弹药、位置、可见性不变，其他关卡还原旧 slider 父节点和尺寸。真实截图已目视检查。

## 完整回归（首轮失败，待重跑）

`smoke_test.gd` run `a884100226bc4d3cb797fc6c0358b77e`，在以上矩阵全绿后串行启动，生产源码 `0f53512`，最终 engine/wrapper 退出 61、PLAYER_DATA_UNCHANGED=1，失败点 `SMOKE_NO_FIX_ONE_COPY yard`。旧断言要求院子也包含“改一处”，而已批准的 M2 新设计禁止保证胜利的文案；院子现检查射界/视线/弹药等真实建议且不含“就能赢”，其他五关原断言不变。同期保留旧模态教程实际流程在 warehouse，并给院子增加非阻塞、可见且不静默完成教学偏好的检查。只改测试契约，不改生产游戏。

新增后半段诊断 `m2_post_touch_regression_gate.gd` 调用完整 smoke 的同一批后续断言，先定位仍有不兼容项，再完整重跑；明确 `not_full_smoke=1`，不拼接首轮前半段与诊断后半段冒充通过。最终仍须正常完整结束标记、六关 loops、数据隔离和 engine/wrapper 退出 0。

所有本地日志与截图在 `ambush_loop/build/ambush_test_runs/<run>/`，未上传个人手机资料或 APK。复现：在仓库根使用隔离包装器及固定 Godot 4.7.2 执行对应入口，E/F/原生回放添加 `-Rendered`。禁止直接运行会删除测试档的 gate。

## 外部评审边界

GPT 实际独立读取 `8ed717c` 并提出四个具体缺陷；实际复审 `50cd77a` 与已释放输出确认四项修复正确。之后更强原生门暴露返回按钮和滑条可用性缺陷，修复至 `0f53512`。新增源码及红/绿输出均已在原安全连接释放，原会话 iteration-2 和 iteration-3 均实际出现 `Unknown error`，一次重试未恢复生成；连接本身健康。故最新增量外部 REVIEW 暂记 unavailable，绝不写 GPT DONE 或 M2 全部 DONE。既有聊天、连接、T3 检查点均保留。

待验清单：本次 full 正常退出、最新增量独立 GPT 复审、vivo 折叠屏/设备触控 dp/误触、安全区、内存与音频、真人首局盲测。手机/真人项暂缓不等于通过。下一阶段 M3 扩展原有五关，在本轮自动闭环后再规划/接入。
# 补充：旧全量回归契约修正与后半段复验

全量重跑已从头启动：`650935fc8ec94d088bf098b3f7641c25`，测试提交 `30d141f`，entry `smoke_test.gd`。启动时未取得终态，不能标为 PASS；继续工作应先读取该 run 的 stdout/stderr 并确认正常最终标记、engine/wrapper 0 和玩家数据不变。不要再并行启动第二个全量实例。

首轮全量 `a884100226bc4d3cb797fc6c0358b77e` 的 exit 61 和后半段诊断 `3bd198e1013d41108ecfd9e9379075ba` 的 engine 81 / wrapper 1 均保留。前者要求新版院子仍承诺“改一处”，后者使用旧覆盖槽布阵，未覆盖新版东侧入口。

仅修改测试：院子检查非保证获胜的射界/视线/弹药提示，首次教学检查非模态且不自动完成；其他五关继续验证原有模态教学。院子通关使用实际西侧箱子搜索领取弹药和既有 B2 高点交叉覆盖布阵，不虚构胜利、不直接加弹药。独立 B2 门禁已覆盖真实移动与坡道，后半段测试只设置战斗布阵 fixture。

后半段诊断 `c10adaa97cdf4465a70771a9956713a3`：engine/wrapper 0、stderr 空、PLAYER_DATA_UNCHANGED=1，六关真实获胜、正常推进、SMOKE_SLICE_COMPLETE、M2_POST_TOUCH_SUFFIX_OK not_full_smoke=1。它不替代从头执行的全量回归。生产实现仍为 `0f53512929fffd57059e9e240afff9e4ab27451f`；17 项独立门禁结果仍有效。最新 GPT 增量评审未取得有效回复，不计作通过；真机和人工体验仍暂缓。
