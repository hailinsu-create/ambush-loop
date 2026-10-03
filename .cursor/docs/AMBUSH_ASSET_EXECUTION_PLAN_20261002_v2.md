# 写实资产实施顺序 v2

日期：2026-10-02。需求来源：用户明确要求“先完成全部计划工作，之后再说模拟器/真机测试”。本文件替代 PR #14 执行计划中 A0.3、A3 设备检查阻塞资产生产及六关推广的顺序；原资产清单、玩法边界、质量与真实性要求继续有效。

## 目标与范围

完成三名队员、四类敌人、共同骨架与当前行为动作、十种枪械及工具、十四类道具、六关建筑地表与声景、3D 特效、HUD、回放和设置接入。360° 水平旋转、35°–65° 俯角及缩放保持；暮色冷灰环境与局部暖灯、主流中端安卓 30 FPS / 高配可选 60 FPS 仍为目标。

不改变战斗数值、路线、可行走区域或胜负规则，不增加高度玩法、第七关、FOW 或联网。Blender 源与导出物可重建，表现只读模拟状态，回放不得读取当前活体来伪造历史。

## 新执行顺序

1. **A1.2 角色与动作**：共同骨架、角色差异、装备挂点、原地动作、LOD；源校验与引擎动作评审。
2. **A2 完整院子**：场景/道具/角色/特效/声音接入；HUD、安全区、设置；新旧回放兼容及完整战术循环。
3. **A3 云端部分**：合批、LOD、纹理与渲染预算检查；隔离行为测试、画面和动画评审，处理发现的问题。
4. **A4 其余五关**：仓道、泵站、信号楼、油库、电台的完整主题资产、照明与声景；六关云端回归。
5. **交付完整构建**：可追溯 APK、精选截图/视频、源提交和测试记录，更新同一实现 PR。
6. **最后安排设备阶段**：全部制作及接入完成后，再处理模拟器、努比亚 Z60 / Android 14、代表性中端机及持续运行。当前不启动模拟器，不要求用户安装灰盒或协助云端可完成的检查。

## 验证与风险

每一制作切片完成后继续做资源导入、针对性云端功能和视觉检查；修改交互/回放后测试对应契约，最终运行完整六夜回归。云端图形计数用于优化，不能证明手机 30/60 FPS 或热稳定性。设备阶段的结果在执行前一律标为“待验证”。后置设备检查可能发现 GPU/触控适配问题，届时修复，不用未知性能阻塞当前全部生产。

设置与战役进度分离；默认入口切换后保留开发用旧视图，回退不清档。新 PR 不自动合并。本次只是顺序变更，不把未实现或未检验的资产标为完成。

## 当前状态

A0 云端坐标/镜头/输入/冻结与六关基线已通过，灰盒 APK 已构建；A1 首批九件道具/建筑及十八个 LOD 已完成源管线与渲染评审。现从 A1.2 继续。设备验证统一移至上述第六步。网页 GPT PLAN/REVIEW：unavailable。


最新尸体片：[真实来源/肩掌/取消与纯回放报告](AMBUSH_PR15_CORPSE_RUNTIME_20261002.md)。ce932cc成功来源绑定/ground/held及真实H抓放先770/0；完整六关10332/3暴露age随capture浮点累加，bf1261c railcut1249/1明确只在两个年龄字段。3048294改domain原锚点后尸体770/合同84042/六关13波10332均0失败；91b9bdc仅扩实际移动/步态测试至1207/0和emptyPCK1766/0，运行树与304等价。复制bodyID/source wave不重绑，原任意loot haul/屏幕14px follow/自动ammo拾取和共享引用不变；内嵌20cm只采样一次。四张实际帧已看，72配对接触及−15mm最低floor门限通过，正向离地/自然艺术/墙碰撞/完整SWEEP玩家拖尸路径未称验收。当前技术PCK25618864 bytes SHA52e14b6b4189af54cb28086b0f36ec08f7201ba24a6be8fa2e823da376562378，非APK；环境重连旧exit句柄失效，304成功有pipefail后TEST_LOG证实0，两个FAILED退出码不冒称观测。HUD盖目标与radio整隐仍是下一必修，然后FX/continuous command/FAILED-A3/13波visual/最新fullsmoke/APK；生产源/GLB/atlas仍独立作者，最新fullsmoke7d34867、耳听设备后置。


最新独立P2：[成功丢弃取消报告](AMBUSH_PR15_DROP_CANCEL_20261002.md)。原518仍同帧投雷→drop rifle→普通更新拾回rifle导致旧throw复活，b082540真实headless6/1exit1；47f0634仅成功drop立即cancel一行修为6/0，6e9ed4c扩失败/同枪kit/ALERT拒绝13/0、完整render1047/0、装备66/0、尸体headless1203/0，3e09a82专项render7/0与恢复枪实际帧。所有实际exit/durable状态和原日志已存。尸体正文按518原receipt改最低−0.001234874m（原误0.003765）、最高0.101031780m，原receipt不改；自然接地/离地上限/墙contact/完整SWEEP玩家路径独立待验。制作资产无修改，既有PCK91早于此修复，最新fullsmoke7d34867；HUD/radio→FX/A3/13wavevisual/fullsmoke/APK继续，未merge/生产/设备。


2026-10-03 R02限定作者修复：[原生SWEEP墙接触报告](AMBUSH_PR15_CORPSE_CONTACT_20261003.md)。固定cd158166真实第二波H/原鼠标路径/朝+Y有363蒙皮顶点进砖墙17/1exit1，d7d291560a77ce112d3fe5f212e39e2d1143c132显式contact版本/共同显示转身修为render576/0，原尸体1203、合同84042、工具1041、冻结66、六关13波10332全部实际exit0；原终局/规则不变，5张真帧已看。独立墙QA、自然正向高度和全墙品质待验，R01由父端报告a325独立关闭；HUD/radio→FX/耳听/A3/13wave visual→单一候选smoke/QA/APK继续，设备后置。G另版、height PR13/16/17/18不合入；ArtSource/GLB/atlas/manifest未改未重跑。旧PCK91/完整smoke7d34867不归当前版本。

附加固定29898fd精确父端MG/force-touch/原生Space-H抓放再抓-鼠标路径复现25/0 exit0；真实flank#3原source(596.6511,207.7352)，97步后(592.2054,178.353)、逻辑90°，LOD0墙内skin顶点0。仅测试文件不同，生产代码等价d7；新MG帧已看，测试parse诊断22c单列保留不计通过。


2026-10-03 R03限定作者修复：[depot点击与radio整隐](AMBUSH_PR15_PRESENTATION_QUALITY_20261003.md)。负向c00ddef69/14实际exit1→4741c5f020965f9a4315fa8993da20474efc04f0正式106/0，桌面重复肖像不再盖depot原SWEEP566目标，radio18姿态保留几何、两LOD逐三角形位置/法线/UV/切线及材质完全保留；copied history/live污染/seek、旧缺失/未知version回退及历史卡片只读已验，四张正式图已看。HUD164/生命周期32/输入23/合同84042/六关13波10332/defaultcontact576/nativeMG25均实际exit0；开发属性重编码失败原日志另存排除验收。R03独立QA与SCOUT顶部文字拥挤仍待；missing/unknown cutaway保留旧整隐行为，55/42部件成本进入A3。父端报告68582原穿墙P2独立闭合但最高浮空97.64mm与中段约0.56m断握仍品质缺口，下一优先修断握，再剩余HUD/FX/A3/13wavevisual/同候选smoke-QA-APK。资产制作源/GLB/atlas/manifest未改未重跑，Notion由指定作者写；耳听0/45、0/6缺实际能力，设备后置。旧PCK91与完整smoke7d34867不能归当前版本，不merge/生产、不混G或height分支。


2026-10-03 接触品质续片：[抓放/正浮空报告](AMBUSH_PR15_CORPSE_PAIRING_20261003.md)。原e9 native MG102/15exit1、86矩阵171/83exit1→89fb34be2498123651bb7685dc55eb5aff6436f2运行修复；a575d9ec9b7eed1b934218a727c41c2a6d0ff226仅改专项测试实际camera参数和正式REPLAY入口，生产等价89，代码已推送核对PR15 Draft/Open/未合并。最终render2695/0/103秒、72hold/864相位、17native测点、双掌<0.001mm、body约6mm/搬运者脚底<0.2mm、原墙skin0、原骨段/端点/暂停/后台/复制历史/旧版通过；18正式run全exit0/ERROR0，9最终图已看，六关13波10332/0/393秒及原终局保持。矩阵/年龄/复制时间轴为明确fixture，不称全墙自然艺术或连续command已完成；独立品质复验待。实际camera size12/viewport1280×720，不将请求4/8写成实际。父端b011 R03原遮挡/整隐已独立闭合，真1600和200%HUD裁切待。下一剩余HUD/完整3DFX/连续command→A3/13波视觉与正常旅程→同最终候选fullsmoke/QA/APK；旧smoke7d34867/PCK91不归本片。资产源/GLB/atlas/manifest和R规则未改，无需新增R取舍；Notion指定作者负责，耳听0/45、0/6与设备后置。


2026-10-03 本地HUD续片：[真实窗口/200% HUD报告](AMBUSH_PR15_VIEWPORT_HUD_20261003.md)。固定6a519b3运行5081/0、42样本/51物理PNG/46原生XTest事件，实际exit0/ERROR0；保留aspect keep的1280逻辑宽及1600留黑，200%可用640×360。三正式图已看，其余图保存不冒称逐图验收；FAILED/WON、独立复验/六关完整旅程/fullsmoke/APK待。Git只读与connector成功但写凭证未恢复，停止auth/push重试，仅本地保存；P2抓放内部边界仍独立处理中，资产制作文件未改。


2026-10-03 本地P2内部边界续片：[schema2连续抓放报告](AMBUSH_PR15_CORPSE_BOUNDARY_20261003.md)。固定f7fcfdbab1adac3ff545ecadbe9b8d74ec9306d3，正式边界2978/0、36关键边界/1350整段probe/72旧schema1精确摘要；旧0/99fallback及history不升级。18正式run均exit0/ERROR0，含品质2695、合同84042、六关13波10332，原终局保留。四关键图+三品质图已看；边界三辅助PNG被后续通用名覆盖未保留，receipt明示，品质9图完整。作者验证通过，独立P2仍待；focus邻近镜头文字裁切、minimap/checklist叠层及FAILED/WON200列待。6a HUD5081限定结论保留，未称全HUD关闭。仅本地保存，Git/Library阻塞不绕过；资产制作diff为空。继续FX/continuouscommand/A3/完整旅程/同候选smoke-QA-APK，耳听/设备后置。


2026-10-03 最新交付状态：原配置唯一push重试成功并只读核对cf77f4db63605ff1e9846e1149f27ca6d461f458；先前onlylocal/authblocked均为历史状态，不推永久凭据健康。Library恢复未发生，不重试。HUD续片[北侧HUD报告](AMBUSH_PR15_NORTH_HUD_20261003.md)，运行816正式focus1702/0+viewport5081/0exit0，checkbox/minimap已分开，原两张镜头裁切原生133/0未复现仍待独立QA，FAILED/WON200另做。
