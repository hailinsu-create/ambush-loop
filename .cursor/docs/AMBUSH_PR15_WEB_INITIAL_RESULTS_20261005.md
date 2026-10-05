# PR15 完整 HTML 首次正式发布与实际浏览器结果

2026-10-05。继承 [Web 执行计划](AMBUSH_PR15_WEB_GAME_EXECUTION_PLAN_20261004.md)；用户最新顺序为完整游戏 HTML 先行，APK 后置。此次交付建立了真实的完整 Title 游戏包及独立、默认私有的稳定正式站点，**Web 完整验收仍未完成**。没有 merge PR15、改变分享范围、修改旧 dot 站点或部署到 Vercel。

## 正式站点及固定身份

稳定正式地址：[Ambush Loop](https://ambush-loop-game.lning791548.chatgpt.site)。Sites 原生发布返回 `type=publish / status=succeeded`，时间 `2026-10-05T00:05:26.128419Z`。这是 owner-private 的新游戏站点；用户最终使用此正式地址。内部 localhost 仅用于验证。

| 对象 | 固定值 |
| --- | --- |
| Site | `appgprj_6ac2e89b4db08191b308c175371ee7c6` |
| 正式 deployment | `appgdep_6ac2e9a317d08191b57f795017f0b25a` |
| Site version | `appgprj_6ac2e89b4db08191b308c175371ee7c6~appgver_75b942a27f1c8191b533de7ebd4a5175` |
| 已推送并 ls-remote 核对的 Site source commit | `63642faff970fc8b01e4d54e624fa6ec129c929f`（新 Site 自身 main，非游戏 main） |
| 实际游戏导出 source / game tree | `843f55c3bc618706d1ddc7aa18d01223927233fc` / `bee4c866d12216538105f4815eedc6d904de8ae3` |
| 运输包装器 source / 文件 SHA256 | `fa18869bf105a7ccbb65f165438ce2a95169f2e6` / `00fb0d067e52a879dcca27d04b5f85e7ba11ed584af3aabf5bc90c7b6b1b7118` |
| 发布 tar bytes / SHA256 | 48,486,400 / `23dbec7329e31a2aa6f22805c6563d1868253eeea69acc61efb4668b0393c563` |
| dist 运行文件数 / 总 bytes | 12 / 48,465,105（约46.2 MiB） |
| 完整 PCK bytes / SHA256 | 38,074,116 / `71bc01e3e79a1bb0b2614fa0cdbb1adb43939fc9ef778e6c70e86b0ace68ee18` |
| 原 WASM bytes / SHA256 | 39,514,754 / `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |

发布 tar 在 `/workspace/pr15-web-artifacts/843f55c3bc618706d1ddc7aa18d01223927233fc/ambush-loop-site.tar`；内容是上述 Site commit 的 `.openai/hosting.json` 与 `dist`，13 个原文件逐一与 `git show` 字节相等。原件、包及模板保留工作区，不把大包和 TPZ 再复制进 PR 证据目录。Site Git 文件夹 `/workspace/sites/ambush-loop-html-game`。

统一 Sites 技能的 source helper 实际不可读/未找到；使用明确等价的 Git 初始化、push、ls-remote、固定 commit archive 流程。11 个实际 Git 命令均 exit0，完整 argv/开始结束时间封存于 `site-source-result.json`；认证只从隐藏 stdin 进入内存与子进程环境，无 token 参数、文件、日志或 Git config 留存。随后原生 save-version-and-deploy-private 成功；没有重复部署、删除历史或清理证据。

## 实际模板、导出与运输

固定官方 Godot `4.7.2.stable.official.ed1daf0bf`。官方 TPZ 实际整包 1,281,349,702 bytes / SHA256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`；只提取匹配 `version.txt=4.7.2.stable`、`web_nothreads_debug.zip` 与 release zip。模板 receipt 与各条目 hash 封存。没有使用 4.6.x 模板或下载 Android 工具链。

新增独立 `Web Game` preset；main_scene 保持 Title，完整六关资源与运行时 JSON，Compatibility/WebGL2、单线程、无 GDExtension/PWA。既有 `a0_preview` feature 只是现有 3D gate；不是 `preview_boot`，不绕过 Title/教学/解锁流程。原 Android preset 字节不变。

三个固定 source 分别完成真实 debug 与 release 导出，共六条实际 engine argv 均 exit0 / ERROR0 / SCRIPT_ERROR0：543d 原完整入口；9038 完整中文字体；843f 中文与符号最终候选。最后 debug `23:52:27.894669→23:52:35.307023Z`、release `23:52:35.397041→23:52:39.106372Z`。共同命令形态：

```text
Godot_v4.7.2-stable_linux.x86_64 --audio-driver Dummy --headless --path <isolated-stage> --export-debug|--export-release "Web Game" <fixed-source-artifact>/index.html
```

stage 从固定 `git archive HEAD:ambush_loop` 建立，导出只读消费既有验收资产，warm cache 与493个同字节既有 loader sidecars 明确列账；排除 `.blend` 制作源，未调用 Blender、生成器或资产生产导出。每轮 tracked hash 前后保持。

初始实际浏览器 Title/关卡入口中文缺字；加入完整 Noto Sans CJK SC face（44810 cmap / 65535 glyph，全字体 WOFF2 11,429,212 bytes；OFL1.1），并补完整 DejaVu Sans 2.37 处理 ↺↻☷♙✕。字体及许可证、原系统 TTC / 完整 face 与 WOFF2 同 cmap 验证均有来源/hash；未用当前文案裁剪字体。原生字体路径保持，Web fallback 由 UI 作者所有权实施。

静态宿主单文件25 MiB限制：PCK分为24 MiB与12,908,292 bytes两片，浏览器重新拼接并核完整原 PCK SHA256 后调用官方 `preloadFile`；WASM确定性 gzip 到10,054,758 bytes，浏览器解压并核原 WASM SHA256，再交官方引擎。HTML 保留官方 `startGame` 和进度/错误 UI。所有文件≤25 MiB；不依赖 Content-Encoding 重写。需求是现代浏览器 `DecompressionStream` 与安全 origin 下的 WebCrypto；[MDN API](https://developer.mozilla.org/en-US/docs/Web/API/DecompressionStream) 仅解释 API，实际能力以以下浏览器收据为准。

## 实际浏览器范围

本地主作者独占 Chromium151 / agent-browser0.38.2 /1280×720；嵌套容器运行可信自身 localhost 包使用 `--no-sandbox`，未关闭 Web 安全策略或调整网络权限。运行环境是云端软件 WebGL，不能代设备、独占 GPU 或中端30 FPS验收。

| source / 入口 | 实际已验 | 范围限制 |
| --- | --- | --- |
| 9038 release，原玩家 Title UI | Title→六关列表→yard 简报→首次三页教学→实际3D SCOUT；I背包、Esc先关闭；未装备警告后强制ALERT、P暂停、暂停ALERT拒绝I；原失败结果→原回放入口、2×/P暂停/REPLAY拒绝I；刷新Continue可用；SCOUT音频RMS0.009937/peak0.035247、M静音RMS0 | 初始手势已有历史activation，未证全新 autoplay；J明确跳到原终端结果，不是正常战斗通关；没有完成解锁存档验证；此源码比正式包少符号fallback，单独列源 |
| 843f游戏+fa188运输，与实际正式包字节相同的localhost12786 | 完整 Title 实际启动、中文/符号可见；DecompressionStream=function；secure=true、crossOriginIsolated=false、SAB=undefined；JS错误查询为空；PCK单字节破坏正确显示 integrity failure | localhost不是正式站点 origin；负向 transport 由只读server响应翻转原片最后一字节，未改原包 |
| 843f外部 debug stage /真实3D renderer | 原 native producer 六关 bin 按原hash传入浏览器 WASM FS，经原回放入口；阶段/波次前后 seek、原事件聚焦、actual roots/20骨/字段/事件cutoff断言 | 仅消费已归档 native 记录，不是新 Web 战斗、玩家自然通关或完整Web campaign |

所选原截图经过查看，动作后等待两次 presentation frame；早先未等输入落实的截图保留，不能据此判状态。agent-browser console 跨导航累积，不能把旧日志算新 epoch；外部 Playwright 附着的 fresh console 单独保存。

### 院子完整历史回放及实际缺陷

原 producer source `a05fa959093ef5b6733466091a04fbb46647f97b`；yard原记录 7,400,892 bytes / SHA256 `4e27b9af88ad72199489ee11e987e1ab0e8200c47bc963e831f4c9eb1883c164`，原 attempt / terminal tick4126保持。debug bridge 仅在隔离 stage，生产包不含它、bin、QA证据或制作源。

实际命令 `python3 run-web-records.py --levels yard --whole --output .../diagnostic-yard-843f`：**4043 checks /0 functional failures / actual exit0**；fresh epoch JS errors0、Godot ERROR0/SCRIPT_ERROR0。12次前后seek、首波SCOUT/两波ALERT/SWEEP/终态、原 fire 聚焦，9原截图全看。1×原自然callback516行、2×258行均到原终点，source原件/场景liveSim未改写，实际view tick与回放clock相等。

**这不代表 WebGL 或播放实时性通过**：fresh console记录257条WebGL warnings，包括 `bindBuffer` 的 index buffer→ARRAY_BUFFER非法目标、随后 `bufferSubData: no buffer`及错误报告上限。外部仅观察 hook 捕获8次相同非法绑定与 WASM调用栈，未屏蔽或修正任何GL错误。官方固定 [mesh_storage.cpp](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/drivers/gles3/storage/mesh_storage.cpp) 的 index-region路径存在相同目标写法，但当前应用无此显式调用，只读官方 source 审计已找到 `Polygon2D` 同拓扑 redraw 自动调用 index-region 的内置可达路径；3D gate 只做 RenderingServer 隐藏，不能证明停止其 Node redraw。具体场景节点与匿名WASM栈对应仍待主作者实际定位；不能直接认定某模型/素材或全局加静默shim。原画面可辨不消除该渲染缺陷。

自然到终端的 observed wall 为1×211.5147s、2×105.9437s，记录原时长68.77s。engine callback delta积分通过；云端低帧导致相对 wall约3×缓慢。没有以含轮询尾部的 `whole_result.wall_s` 充当终点时长，也不称实时速率/帧预算绿。

其余五关独立实际命令 `python3 run-web-records.py --levels warehouse pump railcut depot radio --output .../diagnostic-five-seeks-843f`，START `00:26:27.324028Z` / natural END `00:33:08.981328Z`，**22042 checks /0 functional failures / actual exit0**，JS errors0/Godot ERROR0/SCRIPT_ERROR0。warehouse/pump/railcut/depot各12次前后seek，radio三波16次，共64次；五个原fire聚焦均true。37原PNG全核hash并逐张看，环境与角色/装备/尸体/事件镜头可辨。fresh epoch仍209条WebGL warning，不以功能断言掩盖。与yard合计仅此历史消费范围26085 checks；全部六关新 Web 正常13波、其余五关完整1×/2×、旧schema1及最终候选全矩阵尚待。

## 失败保留、宿主阻塞与存储

正式域名只读 HEAD 实际 exit1：执行环境代理在 CONNECT 阶段返回 `Tunnel connection failed: 403 Forbidden`，发生于达到站点 origin 之前。**不是站点 origin403，也未证明是登录门**。未请求登录绕过token、导入用户cookie、更改代理/网络/安全策略。原生Sites发布成功独立成立；正式origin的认证浏览器载入、MIME、CSP、音频及输入仍未验证，因此不称正式站点已完整可玩/用户已验收。

四次隔离stage准备错误、FontTools初始缺brotli、跨盘rename、缺音频hook/错误页面 helper、首QA check-only未解析autoload，全保留原log或明确标为简要receipt的失败，不补绿色。修正后导出与v2QA check-only/export分别实际0/E0/S0。外部QA bridge SHA256 `d3ae6ed4a906a9ce437ce10264753b661404bd8ed2d40ef4e33649cadf571189`；只在隔离debug stage，不进入生产。

Vercel team `lninghahas-projects` 的75%/10GB提醒不归因到本游戏：此次provider=`cloudflare_artifact`，没有新增Vercel部署。当前必要候选仅一份Site正式版本，rollback版本=null（首次发布）；12运行文件没有raw source art、Blender、Git、记录或证据。原始HTML/WASM/PCK与原模板留工作区，不冗余部署。后续只在功能/浏览器验证后的必要candidate更新同一Site；历史部署、证据与作者原件本轮均不删。存储清理仅建议先只读列旧版本/大小/保留关系，审批另行。

## 下一步与接口

1. 先定位WebGL非法绑定实际caller，在主作者runtime/展示/运输所有权内做最小有证据的兼容修复，负向原件保持；不直接重做模型、换引擎或隐藏错误。
2. 固定修复候选完成完整六关正常13波/六新记录、完整1×/2×、旧schema1、触控cancel/blur-resume、设置及通关解锁刷新；云端视觉/行为及实际wall预算分别报告。
3. 当前执行环境无法抵达正式域名；父线程若有既有授权浏览器通道，可用稳定正式URL验origin。没有这样的通道则保留阻塞，不能通过扩大权限/分享自解。验证完成后同Site必要正式更新，不新增临时preview部署。
4. 继续全艺术/FINAL完整smoke/A3回归清单；HTML完成后才安排可追溯APK。没有模拟器/真机验收声明。网页GPT PLAN/REVIEW本轮 unavailable，未臆造approve。

资产接口保持：主作者仅消费验收过的现有GLB/atlas/runtime JSON及对应sidecars；UI字体/Web导出/loader/回放/共享测试属主作者。未编辑或重跑 `ArtSource/v2/build_yard_kit.py`、共享atlas、角色GLB、Blender输出或资产作者manifest，未全并未验角色分支，SCOUT→ALERT→SWEEP及高度PR边界保持。

## 本切片证据封存

[证据目录](evidence/20261005-pr15-web-initial/README.md) 的 SHA256-MANIFEST.json 列395文件 /49,374,308bytes（manifest自身另计），manifest SHA256 `f244c0dfba2ae87d3bb7e6cf26dbb28c0723c39814ea5697295f9bda045e8810`。391复制原件逐字节与COPY-MAP来源一致；49列明原PNG全看（六关历史46、transport2、绑定诊断1）。当前历史runner已自然结束，root自有浏览器/localhost服务仍保留给下一最小定位窗口；此封存不是全部QA窗口释放。只读caller包已结束，未运行引擎/浏览器。
