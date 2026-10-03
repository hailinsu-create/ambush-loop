# PR15 真实窗口与 200% HUD 切片

日期：2026-10-03。运行源码固定 `6a519b3b928c7d386cb19a7484279ab2bef01b82`，仅本地提交。最近只读远端核对为 `a575d9ec9b7eed1b934218a727c41c2a6d0ff226`。此前写凭证失败，父端要求暂停推送/认证重试；只读 git 与 GitHub connector 成功，无官方 reconnect 提示。未换 token、未合并、未发布。

## 实现与窗口契约

按实际可用 Viewport 而非 Window 物理尺寸选择紧凑底栏。紧凑桌面仍保留鼠标输入偏好，复用现有触控布局和菜单入口。桌面两排按钮按实际主题最小高度分开，标题/阶段/路线文字分配独立空间，长路线用省略和 tooltip。设置与背包使用滚动内容区和固定关闭按钮；镜头面板可展开/关闭。装备冻结仍调用原域守卫，存活队员选择与背包可编辑条件一致。没有战术数值、路径、阶段顺序或胜负规则变化。

真实 X11 Window 测试 1280×720 和 1600×720；200% 明确为 `Window.content_scale_factor=2.0`。原项目 aspect keep 未改，因此可用逻辑区在 100% 为 1280×720，200% 为 640×360；1600 物理窗口左右各有 160px 留黑。这不是“1600 逻辑宽度”。Window 截图采用 DisplayServer 原生屏幕 crop，root viewport 纹理尺寸不能替代窗口尺寸。原生 XTest 输入经过屏幕变换，包含留黑偏移；测试 helper 仅允许显式私有 DISPLAY 和隔离 UUID/XDG，不触及其他图形会话。

## 实际验证

正式命令：`bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot viewport_hud_test.gd --render`。Godot 4.7.2、私有 Xorg :110、llvmpipe，隔离 UUID `9c048262395e4dc9be9d67d7e33d5e4c`。实际退出 0、5,081 检查/0 失败、运行时 ERROR 0；42 样本、51 原生窗口 PNG、46 XTest 输入事件。完整原日志、退出码、报告、所有图与 wrapper/config/摘要在 [证据目录](evidence/20261003-pr15-viewport-hud/validation.json)。

覆盖 yard 四阶段 × 两窗口 × 两比例 × 两输入偏好，共32样本；原首波1056完成后进入SWEEP和正式REPLAY，另五关真实SCOUT标题共10样本。每样本检查可见按钮/滑条边界、按钮彼此不重叠及实际字体文字区域。原生鼠标打开/关闭 SCOUT 与 SWEEP 背包、设置滚动条滚动、ALERT 暂停/恢复、四阶段镜头入口、REPLAY只读肖像。滚动不得误改音量；resize/显示模式切换不得改完整战术快照。参考战斗路线与装备是明确 fixture，不称普通玩家完整旅程。

已人工查看正式七图：1600/200%桌面SCOUT镜头面板、ALERT设置、REPLAY触控返回、radio/depot SCOUT、SWEEP背包及1280/100%桌面SCOUT。其余44图已保存但不声称逐图审美验收；此前开发图单列。截图和自动边界测试不等价于触屏设备验证或 FPS/热性能通过。

负向来源保留：`66c62d2b7e8926aae6b3031d8074439798643353` 初诊断583/65，错误地用root纹理断言物理截图且参考装备有误，排除正式尺寸结论。修正的 `1b0bac132cc9495c7eb9c9f500d569e6e5524e70` 原生窗口627/57、实际退出1，含一个错误参考部署断言；该断言排除，56项真实UI失败保留。原参考最终恢复[1,2,5]/[90,180,180]，新增字体与按钮交叠断言后正式5081/0。开发失败原日志保留，不以开发通过替代正式候选。

## 范围与下一步

本片已验窗口/比例/四阶段入口和上述原生鼠标操作。后续f7fcfdb尸体边界正式图中两张focus切换邻近图可见右侧镜头文字裁切，须独立复现；普通桌面minimap/checklist叠层视觉亦仍待评审，按钮边界检查不覆盖这些文字层。不能称HUD整体验收关闭。FAILED/WON的200%结果弹窗、完整13波视觉与普通玩家旅程、最新同候选完整smoke/APK、独立HUD品质复验仍待。P2内部抓放IK边界独立处理；此前中段握持/正浮空修复的限定结论保留。

资产制作作者继续独占 ArtSource、Blender、共享 atlas、角色GLB及制作manifest，本片未编辑/重建这些文件。主作者拥有 main/HUD/presenter/ViewState/replay/运行loader/共享测试，只接验收固定SHA与原字节资产；当前接收接口R5源29749157c5db064bfea626c3ed9d75d9a1791ece、交付ebedb829e3263abbeb6dd266905f24a3869fa281、原20骨/socket/三LOD及旧动作语义不变。可并行独立包：本固定候选只读HUD复验、未来美术动作候选评审；不得并发修改本运行文件。不自行派遣astra或其他代码集成作者。

完整v2计划继续：内部IK连续→剩余HUD/完整3DFX/版本化连续command历史→A3预算和六关视觉旅程→同最终候选fullsmoke/QA/APK。耳听仍0/45、0/6，设备统一后置，网页GPT PLAN/REVIEW unavailable。旧smoke7d34867/PCK91不是本候选交付。


2026-10-03 最新交付状态：原配置唯一push重试成功并只读核对cf77f4db63605ff1e9846e1149f27ca6d461f458；先前onlylocal/authblocked均为历史状态，不推永久凭据健康。Library恢复未发生，不重试。HUD续片[北侧HUD报告](AMBUSH_PR15_NORTH_HUD_20261003.md)，运行816正式focus1702/0+viewport5081/0exit0，checkbox/minimap已分开，原两张镜头裁切原生133/0未复现仍待独立QA，FAILED/WON200另做。
