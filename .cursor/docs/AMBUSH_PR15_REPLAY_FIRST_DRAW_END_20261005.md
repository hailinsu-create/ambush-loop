# PR15 首绘制反证 END / 撤回无稳定收益的 touch 候选

2026-10-05，接父端95daa独立QA END19:36:27与明确返窗，执行[首绘制反证计划](AMBUSH_PR15_REPLAY_FIRST_DRAW_PLAN_20261005.md)。本片产品决定为**撤回唯一main优化**，固定源码 **b74f1fc2f190f574cd0c31aba04e495829337214**，game tree **1e8af45ee23098f763acc139b56f8f7e0f41665a** 与既有1ec产品树精确相同；没有新修复、frame/style缓存、规则/资产改动或性能接受。95daa05及其全部测量/失败证据保留，不改写为已合格。

父端交接称严格同步layout actual1/E6/S0、首process-frame后隐藏容器rect actual1/E3/S0，普通入口首渲染尚未证；性能ABBA362.08/480、paired中位+21.92%/-1.26%、重复漂移10%、159全超16.667ms/158超33.333ms。QA包SHA `b3be7d6a15b47f56455bf6d8963744eb797d18483f22c6881283195212d219c5` 的原件路径/具体节点仍未收到，已请求；这些是明确父端交接，**不称本地独立阅读全文或关闭原失败**。

## 实际反证

工具命令 `python3 /tmp/pr15-replay-first-draw-20261005/prepare.py` actual0：原生纯A=1ec、纯B=95daa，998个tracked文件逐字节核唯一差main，唯一省略非runtime源blend；990个已有import文件A/B完全相同。首次只读盘点因git默认quoted中文文件名误报12missing，改`git ls-files -z`后精确仅1个非runtimeblend，原盘点不计有效runtime审计。

`python3 /tmp/pr15-replay-first-draw-20261005/run.py` **actual0**。官方4.7.2/Compatibility/OpenGL/Mesa llvmpipe/Dummy、1280×720、官方fixed-fps60仅对齐功能调度。两个独立UUID/实际Guard、各cap90、整个原生包cap240，超时runner只关自有process group。A actual0/E0/S0/214检查0失败，B actual0/E0/S0/214检查0失败；A START19:44:47.832437→19:45:39.107238，B START19:45:39.107864→19:46:27.243098 UTC。最终END19:46:27/live Godot与Chromium0，未占父端QA旧进程，既有Xorg99保持。

一次初始化复用原yard e850 bin和原已结算配对cfg，把其绑定原WON consumer；不是新胜利或fresh13。后续通过 **Input.parse_input_event鼠标/键盘GUI** 走原Replay按钮、原菜单触控按钮、关闭菜单、原暂停/倍速/返回，所有控件实际visible/enabled并响应。输入是合成引擎输入，**不是OS XTest/DOM isTrusted，也不是Web首绘制证明**。采样前没有_update_hud/_refresh_touch_hud/refresh、呈现clock freeze或额外settle补布局；正常回调和tween继续运行。

- 原Replay触控off入口、off→on菜单切换、关菜单露出触控底栏、触控on再次Replay：同步状态+首个RenderingServer.frame_post_draw+随后两帧；另原pause/speed/resume/返回首draw。
- **25份状态/每份455个Control节点，所有采集UI属性逐字段一致**：styles/font/text/rect/visible/in_tree/disabled/modulate/minimum/mouse_filter等，未排除隐藏字段。
- **17对PNG、每对921600像素，changed0**；全部两侧原PNG保留为明确digest映射的原字节。五张代表原PNG实际目检：off入口、on菜单、关菜单、on再次入口、返回WON；没有称34张逐张目检或全战场艺术验收。早进度误报16对已更正17。
- 绑定frame/20bones/socket的所有postdraw字段相同，原attempt/wave/seq/tick保留；三instance source token先实际核绑定再省入跨进程比较。同步帧/WON中utility_scope_id存在4处跨进程差，源码VisualSnapshot.reset生成随机scope，后续历史postdraw一致；仍保留原值，不删字段转绿。
- 完整raw A/B比较**未通过**：25行29处差异（25个domain hash、4个同步/live utility_scope_id）。domain只封了hash，没有封全文，不能独立定位全部差因或称本包完整domain/cfg/checkpoint合同已通过；原record containers/archives不变的实际断言通过，合法菜单touch偏好持久化两侧一致。`python3 .../strict_pair.py` **actual1**，未改成green；`analyze.py` actual0仅表示分析完成。

原生最小反证范围未复现可见布局、像素或后续运输控件交互差。它不覆盖父端原同步fixture的E6/E3、普通fresh胜利、真实Web首绘制或跨进程完整state。继续接受95daa仍需这些解释，而稳定帧收益并未建立；因此选择撤回该单一优化，**不把反证误称实际回归或独立QA合格**，也不继续改变诊断门以接受它。撤回后main SHA256 `b80cdd52e4e327ddf4ff361223fec7cae84b8bd9bfaeffd2921afc7e418d4c0f` 与1ec逐字节equal、整个game tree equal；纯A这轮已实际运行相同产品。未重新跑全部旧门。

## 证据与接续

[manifest](evidence/20261005-pr15-replay-first-draw/manifest.json) 封102份原件映射/86份实际artifact/17,504,258B（manifest自身另计）；大型原JSON仅gzip lossless且roundtrip原bytes/SHA exact，PNG只用原字节content-addressed去重，A/B各原路径/bytes/SHA与blob映射逐个核。prepare/run/oracle/analyze/strict脚本、原命令/Guard/两实际回执/全部25×2状态与17×2图/原差异都在其中。

下一恢复后的固定产品树消费真实旧warehouse mine/railcut repack原件：另有界计划、原bytes先封，事件身份/历史装备/伤害/库存/3D cue/握持socket及seek/focus/source/lifecycle检查。不是新producer自然专项接受，不补造事件；本片不继续同类小优化，不部署，Site仍v4，PR15仍Draft/不merge。

最终同candidate13波/自然工具/六新whole/完整smoke/all-art/人工听感/最终A3/APK及设备门保持；QA包原件位置与server-origin身份仍待。资产接口R5既有20骨/weapon_hand/socket/3LOD/52语义保持，无新增资产请求，不改/重跑生成器、atlas、GLB、Blender或音频。网页GPT PLAN/REVIEW unavailable。
