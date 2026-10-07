# PR15 终局 HUD 与北侧叠层收尾

2026-10-03。用户将本轮限定在北侧镜头/minimap/checklist与FAILED/WON 200%弹窗，主集成继续单写；本轮未展开FX/A3。最终运行源码 **7edd0db93243e1079d6af3e55da37bf2d5a97df1**；结果滚动布局先修 **f2ef6f7b6f2119430ad9410f046d3067b22877b6**，北侧首修 **816c31946b7e32966efc9bb7890d0ef9a7253efb**。源码已通过原配置正常push，并由git ls-remote和GitHub只读核对7edd；本报告和证据的提交交付另核对。

FAILED/WON原文字与按钮绑定保留，原VBox正文迁入垂直ScrollContainer，原重试/档案/返回标题与下一关按钮迁入固定footer；200%变更时重新按实际可用viewport限宽限高，终局隐藏重复touch命令行。后续发现高CanvasLayer镜头控件仍盖正文，7edd在真实结果overlay显示期间隐藏面板/按钮/底板，离开结果页后恢复。北侧桌面时间条右界由−16改为−220，为minimap列留白，紧凑模式仍使用原全宽。规则、记录、tick、结果文本与场景资产未改变。

固定3a2ef9619cb71b0dabdff3c199836a14a2e562ef先用实际域终局证实bounds反例 **1248/93 exit1 / ERROR0 / 21图**。第一次开发结果665/17 exit1，其中一项要求短折叠正文也能滚动的错误断言已排除；其余16项为WON200真实resize越界，已修。第二次开发671/0 exit0仅日志留存，未保留的PNG不称验图；f2固定正式671/0另有26图，八次正式run全部exit0/ERROR0，但当时没有镜头层级oracle，不能称全部终局HUD关闭。

追加固定80ce3798bd5cffdd3e1c92f1c3ca6a39b20f4ece测试后，结果镜头层级 **745/24 exit1 / ERROR0 / 26图**，北侧时间条 **1718/16 exit1 / 16个故意断言push_error / 40图**；由7edd修复。隐藏控件后普通按钮重叠配对检查减少，最终449不与负向745冒称同一可见控件数量；16布局、24个结果bounds时刻、三个镜头可见性检查与40原生输入均保留。

| 固定7edd正式命令/参数 | 实际结果 |
| --- | --- |
| `bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot result_viewport_test.gd --render` | 449/0、exit0、26物理PNG、40XTest；147.465秒 |
| `AMBUSH_VIEWPORT_SCOPE=focus bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot viewport_hud_test.gd --render` | 1718/0、exit0、64时刻、40PNG；111.193秒 |
| `bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot viewport_hud_test.gd --render` | 5081/0、exit0、42样本、51物理PNG、46XTest；226.623秒 |
| `bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot visual_snapshot_test.gd --render` | 164/0、exit0；50.355秒 |
| `bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot presentation_lifecycle_test.gd --render` | 32/0、exit0；57.052秒 |
| `bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 presentation_contract_test.gd` | 84042/0、exit0 |

六次正式run均引擎ERROR0。隔离UUID、原日志、durable退出码、真实argv、原报告、全部留存图SHA256与源码树在[证据receipt](evidence/20261003-pr15-result-hud/validation.json)，私有Xorg配置和render wrapper文本随证据保存。所有结果图以DisplayServer实际窗口crop采集，1280×720/1600×720和100%/200%各两偏好，保留aspect keep的逻辑宽及留黑；原生输入是隔离Linux XTest鼠标，不称设备touch通过。f2的equipment66、headless lifecycle30/camera23、native UI133等通过是前一固定源码，未混写成最新7edd全面回归。

实际FAILED由yard不部署→原警报→原模拟escape到达，波内tick929、19事件、0清波；WON用原reference部署弹药、普通模拟、vacuum helper和两次原撤离到达，末波tick227、34事件、清2波。227不是全局终局tick，此路径不称正常玩家旅程。正式原生档案开/关保留完整snapshot/text，长正文wheel保持snapshot、固定footer关闭档案，原生retry使loop精确+1且仍yard、下一关进warehouse。radio最终credits入口未覆盖。

已实际看最终FAILED档案/WON的1600/200%滚动图与北侧1600/100%焦点图，镜头不再压正文、minimap与时间条分开；其余图留存不称逐图艺术验收。北侧原两张focus邻近镜头裁切在原生MG两波/97步/H/暂停焦点/历史序列133/0中未复现，仍待独立QA；本片稳定几何通过不替代原问题关闭。父端已安排cf77独立IK/HUD QA，尚未收到结果，schema2作者通过保持限定。

此前only-local/auth-blocked是历史失败状态，原配置授权重试a575→cf77成功，随后eb15314及本片7edd普通push/只读HEAD核对成功；未改凭据/helper/remote/身份，一次成功不证明永久凭据健康。Library官方materialize未恢复，不重试/绕过。

资产接口仍为R5 source29749157c5db064bfea626c3ed9d75d9a1791ece / deliveryebedb829e3263abbeb6dd266905f24a3869fa281，20骨骼/socket/3LOD/52旧语义。ArtSource/Blender/GLB/atlas/制作manifest独立作者所有，本片无修改/重跑；主作者只写runtime/presenter/HUD/loader/共享测试，WIP资产不整体并入，Notion指定维护者负责。

下一步是取得本HUD/IK独立复验和原两张裁切的独立关闭，再按父端分配恢复FX、continuous command、A3、六关13波视觉/正常旅程、同最终候选smoke/QA/APK。当前未导出新APK/PCK，旧smoke7d34867/PCK91不能归7edd；耳听0/45、0/6，模拟器/设备后置，云llvmpipe不证明安卓性能。保持Draft/Open/未合并，G与高度分支隔离。
