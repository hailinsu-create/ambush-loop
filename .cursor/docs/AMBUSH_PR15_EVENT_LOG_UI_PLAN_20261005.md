# PR15 日志/相机真实输入最小切片（2026-10-05）

用户确认范围：父端已接收 5dba 仓库 bounded END。本轮只修复原事件日志被相机控件遮挡，并验证同 Web 布局、命中、键盘/鼠标/触控焦点；完成封存并归还独占引擎窗口，独立 bounded QA 后才继续 pump。生产树基线 dab8705/4f49；PR15 不 merge，不动资产制作，不做 APK。

## 已复现与实现

原仓库记录 SHA256 `28c90902016e3a0323081c756ddde215ea2ec228223147231eed7ef66af33266`，仅作历史消费者。本轮不新增自然 producer/WON、不替代已封存 warehouse 整段记录。原中心点击被 camera 消费的旧失败保留；首次 geometry receipt 同名覆盖丢失仍按原报告披露，不重构成原始证据。

实现仅 presenter 的日志布局：宽屏放在相机左侧，紧凑布局放在右侧，底部留出原触控栏；日志和相机都保留原可用输入。旧源 headless 六组合 36 checks/6 failures actual1；候选几何 36/0 actual0，只证明几何，不证明真实点击。

## 顺序与验收

1. 隔离 Guard、真实 Window/XTest 六尺寸/缩放/触控 HUD，原事件行左中右 seek/focus、相机角度不变、真实滚动、记录/模拟不变；保存实际退出和原图。
2. 固定源码 SHA 后官方 4.7.2 完整 Title Web debug/release 导出，不运行 Blender。另立 cold historical QA 包，记录注册/fixture 与生产 PCK payload 差异，不能称包相同。
3. 单引擎实际 Chromium：鼠标与 CDP 原生触控左中右、两波历史事件、相机仍可操作、键盘回放及焦点/取消生命周期；窄屏与 200% 布局保留可用日志滚动。所有阳性操作必须来自浏览器真实输入。截图逐张看，console/GL 指标分开，不作真实手机或性能通过。
4. 固定导出/包 hashes、封存负例/原始日志、报告/索引/Git push/readback、PR Draft 保持；自然关闭所有自有 engine/browser/server，交给独立 QA。线上同 private Site 更新仅本地验证后按已有授权执行，FINAL/APK/全计划仍待。

## 方法负例与当前状态

headless 初始 fixture 缺 3D presenter 后修正；synthetic push_input 路由方法不计真实输入。首轮 Window launcher 缺 `AMBUSH_TEST_X11_DISPLAY`，原助手在 XTest 前拒绝，actual1/99 checks/42 failures，保留原日志。已补启动参数，并用原生 wheel 露出 compact 历史行，六组合 Window 后续触及180s cap，actual124、不计通过，保留四原图；改为三组合有界 Window（1280/1×touch、1280/2×touch、960/1×touch）103/0 actual0，原生XTest、真实wheel、三原图全看。最终同测试 headless六组合36/0 actual0。自有 Xorg136准确argv关闭actual0，首次stop因wrapper路径不匹配未发信号。完整Web/浏览器门仍待。不得把方法失败隐藏或算产品验收。

资产接口保持既有所有权：ArtSource、build_yard_kit.py、角色 GLB/Blender、共享 atlas/manifest 由资产作者负责，本切片 diff 不含这些路径。网页 GPT PLAN/REVIEW unavailable；独立 QA 尚待本轮 END。
