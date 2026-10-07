# PR15 Web 画布门实际结果与有界交付

2026-10-05。固定修复 source **`1d17a16156d2afae0cbdd77cf73030a57f953ada`**，game tree **`b5ebb0b2f7ddc1901e02a9843d1791164aee98ec`**。继承 [最小计划](AMBUSH_PR15_WEBGL_CANVAS_PLAN_20261005.md) 与 [首次正式发布结果](AMBUSH_PR15_WEB_INITIAL_RESULTS_20261005.md)。父端要求本轮封存交付、停止无界优化；本切片完成 source/native/Web 历史消费门，**全游戏 Web 与 FINAL 尚未验收**，候选尚未更新正式 Site。

## 当前给用户的正式地址

唯一稳定正式地址：[Ambush Loop](https://ambush-loop-game.lning791548.chatgpt.site)。新 owner-private 游戏 Site `appgprj_6ac2e89b4db08191b308c175371ee7c6` 保持首次版本1 / deployment `appgdep_6ac2e9a317d08191b57f795017f0b25a`，原生 `publish/succeeded`。没有新建 preview、重复部署、改旧站点/ACL或 merge 游戏 main。

**正式 v1 映射仍是游戏 `843f55c3bc618706d1ddc7aa18d01223927233fc` + 运输 `fa18869bf105a7ccbb65f165438ce2a95169f2e6` → Site Git `63642faff970fc8b01e4d54e624fa6ec129c929f`。** 01:41:53→01:41:55 UTC 原生只读回读仍 version1/commit63642，不能把本轮1d17的零警告结果挂到已发布包。

同字节正式包在 localhost 已能启动完整 Title、显示中文与符号，12运行文件48,465,105 bytes，完整六关资源保留。早先9038的原玩家UI实际到首关简报、三页教学、3D SCOUT，并有限验证背包/Back、ALERT暂停锁、失败回放和checkpoint；六关列表正常仅首关初始解锁。它不是当前正式origin验证，也未证明通关解锁与完整玩家六关流程。当前可交付的是**已发布候选网址**，不称正式游戏完整可玩验收。

正式 v1 的实际历史消费仍有257/209 WebGL警告；原yard完整1×/2× observed terminal wall211.5147/105.9437s，而原记录时长68.77s，云端约3×缓慢。callback clock积分通过不等于wall实时性或30/60FPS通过。本轮没有候选whole/performance数据，旧速率不能直接当候选测量。

正式域名HEAD在执行环境代理CONNECT阶段被403挡住，未到origin；**不是origin403或已证明登录门**。没有绕过拒绝、导入cookie、改代理/网络/分享。父端可另安排既有授权浏览器对同一正式URL做独立origin QA；无需把用户电脑当唯一验证渠道。MIME/CSP、授权加载/存档/音频/输入均仍待该通道。

## 修复与实际命令

唯一生产改动是 presenter.bind 的 Web 条件：隐藏旧 Main Node2D 画布，保留 World/实体自身visible和处理模式，HUD与3D位于独立CanvasLayer。固定4.7.2的Polygon2D同拓扑redraw可进入错误index更新；RS-only隐藏仍会redraw。门阻止旧画布native绘制，不加GL shim、不改单个cone、模拟/记录/装备/玩法或资产。旧画布effective visibility变false是明确行为；native分支保持原路径。共享presentation合同增加3条断言。

| 实际命令/固定字节 | START→END UTC | 实际结果与范围 |
| --- | --- | --- |
| `bash /workspace/pr15-web-canvas-contract-stage/scripts/run_isolated_test.sh <official4.7.2> presentation_contract_test.gd --headless`；31273两文件overlay逐字节等1d17 | 01:11:55.927546→01:12:45.382198 | **84048/0，exit0/E0/S0**；隔离guard通过，native pass-through，不执行Web条件 |
| `<official4.7.2> --audio-driver Dummy --headless --path /workspace/pr15-web-stage-1d17 --export-debug "Web Game" .../1d17.../debug/index.html` | 01:14:40.655103→01:14:48.239856 | exit0/E0/S0；完整Title、六关资源，493既有同字节sidecars，只读验收资产 |
| 同一stage `--export-release "Web Game" .../1d17.../release/index.html` | 01:14:48.324490→01:14:52.038026 | exit0/E0/S0；PCK38,074,644 bytes / SHA256 `07a1a14411a45ecff3ed5afd898f40382f7ede7462c44306396ec4c4859a8a3c` |
| 外部debug bridge隔离stage `--export-debug "Web Game" .../1d17.../qa-debug/index.html` | 01:19:25.035278→01:19:31.379230 | exit0/E0/S0；桥SHA256 `11dde6e92fa3c47ce9336a858d5aa6235a14edad47644938e688a7f9fb9dbc87`，无Polygon/GL观察脚本，生产包无桥 |
| `python3 /tmp/pr15-web-controls/main-canvas-gate-candidate-qa/run-web-records.py --levels yard warehouse pump railcut depot radio --output /tmp/pr15-web-controls/candidate-1d17-six-seeks` | 01:22:03.552280→01:29:34.391846 | **25951/0，actual exit0；fresh console空、JS/Godot E/S0、WebGL warning0** |

官方引擎仍4.7.2.stable.official.ed1daf0bf，匹配TPZ全hash/单线程debug和release模板沿用首发证明。根tracked导出前后保持，source两blob与固定1d17核对；没有调用Blender或生成器。候选debug/release在 `/workspace/pr15-web-artifacts/1d17a16156d2afae0cbdd77cf73030a57f953ada/`，尚未制作新的Site运输/上传候选。

### 六关实际范围

原 producer仍 `a05fa959093ef5b6733466091a04fbb46647f97b` 六个原native bin及其hash/attempt/terminal，不升级、不改写记录。浏览器桥经原回放入口，由实际renderer检查字段/事件cutoff/3D roots/20骨与阶段波次身份。

| 关卡 | 前后seek | 原fire聚焦 | 原截图 | 完整1×/2× |
| --- | ---: | --- | ---: | --- |
| yard | 12 | true | 7 | 本候选未跑 |
| warehouse | 12 | true | 7 | 未跑 |
| pump | 12 | true | 7 | 未跑 |
| railcut | 12 | true | 7 | 未跑 |
| depot | 12 | true | 7 | 未跑 |
| radio（三波） | 16 | true | 9 | 未跑 |

合76前后seek，13原记录波次的代表阶段消费，**44张候选原PNG逐张view_image查看**；动作后等2 presentation frames。场景/HUD、角色/装备/尸体与聚焦镜头可辨，canvas gate实际Main=false、World自身=true、HUD有效=true。报告所有whole数组为空；五关明确仅seek/focus，yard本候选也只seek/focus。这不是新Web正常13波、自然玩家胜利、全部动作/LOD美术验收或设备性能。

## 方法负向与归档差异

原GL错误/匿名WASM栈保持首发证据。首caller观察器放错autoload位置，label=null，其runner/export0不能使方法有效；正确路径后24坏绑定仍在。官方Object通知先native再script，因此末次DRAW script marker只能说明附近前次绘制，不是当次native精确节点，原node-attribution-summary较强措辞由本计划/结果限定。白采样纹理通知实验仍24错，未进入生产。隔离Main门样本8坏→0、warning0，单图4个RGB像素差而非严格像素相等；后来由本轮六关实际矩阵补证，不以样本替代战场集成。以上原件/退出/方法失败均封存。

作者Git tar **48,486,400 bytes / SHA256 `23dbec7329e31a2aa6f22805c6563d1868253eeea69acc61efb4668b0393c563`**；Sites归档 **48,476,160 / `9b789a57b14fa36e794a9fcf1f34c000588f706d9a5f6b211bfe3ba8f26051a4`**，13files。同文件名/顺序/原payload，每个逐字节等`git show63642`；只去两目录条目、Git全局PAX comment，使用默认Python TarInfo/PAX重新串行化，**实际exit0，完整复现Sites大小及SHA256**。差异来自tar头/元数据/填充，不是错游戏文件。只读Library下载请求ownership404未绕过；不必读取其字节也已重现完整hash。实际脚本、13文件hash和两个原archive身份均在证据中。

## END、下一包与资产接口

引擎与runner自然结束；自有browser `agent-browser --namespace ambush-pr15-web-held --session pr15game543d ... close` actual0。9个自有HTTP服务逐一核PID/argv/UID后有意SIGTERM（各服务收尾143，非测试失败），`/proc`已不存在。**END2026-10-05T01:37:59.044565Z，自有浏览器/QA引擎剩余0**，预有Xorg99与原工作树不碰；不保留活窗口占独立QA。网页GPT PLAN/REVIEW unavailable，未臆造approve。

下一有界主作者包固定同1d17：原Title→教学→SCOUT真实键鼠/背包/Back、ALERT/暂停ALERT/REPLAY拒绝；实际触控cancel与focus/恢复；yard原whole1×/2×到原terminal、只读身份与fresh console，单列observed wall，不改预算或优化。关键门过后才准备同Site必要更新。可独立并行的是父端正式origin授权browser QA与固定source只读评审；性能窗口仍互斥，资产作者修源/产物另分支，不跑本作者共享测试。

后续另外列清：全部六关新Web正常13波/六新记录、六关完整1×/2×、真旧schema1、设置和通关解锁刷新、正式host全矩阵、FINAL/fullsmoke/all-art/A3预算；HTML后才可追溯APK，再按用户顺序讨论模拟器/真机。没有完成声明。

主作者仍仅消费验收GLB/atlas/runtime JSON/493loader sidecars，拥有main/presenter/ViewState/replay/runtime loader/共享测试/UI字体/Web运输。未编辑重跑ArtSource/v2/build_yard_kit.py、atlas/角色GLB/Blender/资产作者manifest，未全并WIP角色分支；SCOUT→ALERT→SWEEP与高度PR隔离保持。仅现有一次cloudflare_artifact Site部署，不将Vercel75%/10GB警告归因此游戏；无删除历史/证据/原件、升级套餐或冗余部署。v1作为当前版本保留，可供将来必要更新回滚。

[本轮证据](evidence/20261005-pr15-web-canvas/README.md) 封存原log/argv/start/end/actualexit/方法负向/实际截图/源身份与tar复现；首发证据31273保持。SHA256-MANIFEST列121文件/45,819,254bytes（manifest自身另计），SHA256 `2bf69b6ca6c5197d198624cc9d514547f6bcabc5183b158c7f9f65cdae8dd4d4`；116复制原件与COPY-MAP来源逐字节一致。45列明原PNG已看（候选44+隔离prototype1）；另外3方法失败原图只保留，不声称本次逐图视觉验收。
