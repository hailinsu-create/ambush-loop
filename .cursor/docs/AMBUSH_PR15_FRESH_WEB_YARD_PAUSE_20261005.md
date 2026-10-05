# PR15 fresh Web yard 有界结果与暂停

2026-10-05。**PAUSED_USER_REQUEST。** 用户在已开始的 yard 包中要求“完成手头工作即可暂停”；仅收尾自然双波、原记录、Title 解锁 reload/reopen。没有启动 warehouse、其余四关、whole、新优化/资产/QA/APK。自有 browser/controller/server 全 actual0 END，shutdown 只读确认无自有 engine/browser live、12815 连接拒绝111；未删除 profile/原件。恢复开发须新的续工指令，本报告不安排自动继续。

PR15 仍 Draft/Open/未合并。运行固定生产源 **`dab870595175eed37a6d2a012bc69a76062d48b0`**、game tree **`4f49a7c9cb5a789fbb570bceb947eab7df2eb54a`**；本片只增仓库根 `.cursor/docs` 的 QA 代码/证据和新记录，`ambush_loop` tree 不变。资产/generator/GLB/atlas/Blender/作者 manifest 不写不重跑。旧 a05 及原1d17八件 Library 转移仍独立 blocked，无IDs，不把本次新 record 替换为旧原件。

## 实际环境与身份

完整原 Title 工程，官方 Godot `4.7.2.stable.official.ed1daf0bf`；Browser 插件未提供，使用已有 Playwright1.62/headless Chromium，CSS1280×720/DPR1，独立新 profile 与 `http://127.0.0.1:12815/index.html`。Compatibility/WebGL2 实际 console banner；具体 GPU driver 本包未读取，性能/手机预算不称通过。source-informed 原匣/掩体策略不称陌生人 playtest。

996 个生产 source 文件核原 Git 字节、493既有同字节 sidecars；排除作者 `.blend`，复制既有 `.godot`，只追加 external readonly autoload。桥只读 state/controls/project_targets/record bytes/fingerprints，唯一写入是自身回复、序列化缓冲和观察 trace；全部玩家动作经真实 CDP 键鼠/原UI。78 个 browser 输入均 isTrusted，78 个 engine 输入记录仅单一 yard attempt；阶段−1(Title)/0(SCOUT)/1(ALERT)/5(SWEEP)/3(WON)，无REPLAY及下一关 attempt。

最终 aligned fixture PCK **38,094,932 bytes / SHA256 `4a455916bbfb5183e086d461984add423398341ee0ac1698630ffce014bd99d0`**；桥 SHA `7297eb7b89cd8a2ec118ac3544a2e666d3049171d0841bf34b02ac3c5cc264ba`。原965/fixture967目录 entry 的每一 payload MD5实际核对；只增两个桥条目，原 payload 仅 `project.binary` 与 `.godot/uid_cache.bin` 为注册差异，其他全字节相同。因此 fixture PCK另列，不冒称发布的原 PCK2d8字节等同。

## 实际 START/END 与原输入

实际运行命令是 `python3 /tmp/pr15-web-controls/fresh-native-dab-20261005/browser_controller.py`；其 stdin 顺序接收以下请求，controller 在同一真实 browser context 执行脚本并封各自 actual_exit。不是独立重启每个 producer：

```json
{"label":"initialize-aligned-yard","script":"/tmp/pr15-web-controls/fresh-native-dab-20261005/initialize_aligned_yard.py"}
{"label":"produce-yard","script":"/tmp/pr15-web-controls/fresh-native-dab-20261005/produce_yard.py"}
{"label":"finish-yard-and-pause","script":"/tmp/pr15-web-controls/fresh-native-dab-20261005/finish_yard_and_pause.py"}
```

三请求均 actual0；结束发 controller `close` 请求，原进程 exit0/FRESH_BROWSER_END。aligned export 的完整官方 argv 与 E0/S0 在 `controls/aligned-export.json`；后续只做 `git diff --check`、62文件大小/SHA校验和正常 Git 推送/远端读回，无新增 runtime QA。这些为历史调用证据，当前暂停期间不重跑。

| 范围 | UTC | 实际结果 |
| --- | --- | --- |
| 原 Title fresh→yard 简报→全部三页教学 | START04:42:21.106；END04:44:09.218 | actual0；初始只有yard解锁、Continue禁用，教学后仍三刀/未获额外资源 |
| yard producer | START04:47:46.300；原记录 END04:55:31.455 | actual0，424.705s至自然WON（记录复制/截图收尾另计）；无retry，900s cap内 |
| wave0 | START04:51:15.361；END04:51:56.505 | 原alarm/pause/resume，自然SWEEP，localtick450；后原走近拾取与再部署 |
| wave1 | START04:53:32.105；END04:54:00.758 | 原SWEEP alarm→ALERT，自然SWEEP，localtick225；原最后拾取/撤离→WON |
| reload | 04:56:56.157→04:57:08.448 | 两 cfg、公用checkpoint、yard cleared/warehouse unlocked/下一关字段原字节/值保留 |
| 同 profile close/reopen | 04:57:08.953→04:57:24.852 | 同上；实际 Title 原六行locked/disabled与Continue启用检查 |
| yard packet END/用户暂停 | 04:57:28.367 | PASS_PRODUCER_UNLOCK_RELOAD；没有点击 Continue/进入warehouse，也未启动whole |
| owned收尾 | close实际exit0；04:58:58.358只读确认 | controllerPID147611已消失、无自有engine/browser、HTTP12815关闭；原profile/证据保留 |

真实拾 rifle→队员0、mg→1、scout→2、grenade→0，原步行/0.4s搜索；原1/2/5掩体、90/180/180朝向由数字键/3D点击/A-D量子达到。两波暂停/继续均原按钮，不赋tick/phase/HP/ammo/装备，不调用raid_force_alarm/record_win，不点“跳到终局”。所有SWEEP拾取和最终撤离走原过程。

自然WON的进度 `level_id=warehouse, cleared=[yard], complete=false, yard_loops=1, yard_perfect=true`；只yard和warehouse解锁，其余四关仍锁。返回Title用原Esc暂停菜单“返回标题”，避开会实际加载warehouse的WON Continue。reload/reopen只核已保存解锁及默认设置/seen，未测试新的设置取值变化、当前战斗resume或真正后台退出。

## 新原记录及已核范围

[原 `var_to_bytes` record](evidence/20261005-pr15-fresh-web-yard-pause/run/yard-record.bin)：**19,025,696 bytes / SHA256 `e850bb81212393478617a06700e8a26ea293b7d46672c06c0d9c780c405815d5`**，attempt `93a9671c444c749f102a04a728c963a5`，schema2，terminal_reason=win、playback_terminal_tick12678，30 events/1622 playback frames。原八字段完整保存，保留 Godot Variant/Vector类型；分块传出后的长度/SHA与原桥缓冲一致。桥只读检查 event attempt/wave/seq/event_id、event timeline及playback time/frame_seq，failures=[]。producer结果、原输入与public配置均有原件。

记录包含真实教学、SCOUT/控制器准备空闲、取物部署及SWEEP的命令时间；211.3s playback长度不等于胜利统计battle11.3s，更不是FPS/吞吐通过。new Web 当前只是**1关/2获胜波/1新record**，未拼入旧 a05 或失败attempt。whole1×/2×、seek/event focus、20骨/复制历史不可变等新回放门均 UNRUN_USER_STOP；未用 seek/manualtick装成完整播放。

| 渲染/行为门 | 当前证据 |
| --- | --- |
| 页面身份、非空、无框架overlay | 原debug标题、Title/三页教学、实际3D SCOUT/两ALERT/两SWEEP/WON/Title解锁截图 |
| 真实交互 | 78 browser trusted/78 engine输入，同yard attempt，双波自然WON |
| aligned实际console健康 | 13 entries，console error0/page error0；GPU ReadPixels warnings4保留，不能写全warning0/性能通过 |
| 持久化读回 | 两cfg text/SHA、公共checkpoint exact及实际GameSettings/Title rows，reload与reopen均actual0 |
| 视觉 | 18原PNG已封；本报告选择的Title/教学/刀装/两波ALERT-SWEEP/WON/解锁原图已实际查看。未做完整美术验收 |

## 方法负例、独立存储QA与交付

第一fixture导出engine actual0 E0/S0，但recipe strict payload审计actual1拒绝47 UID remap差异；UID审计首次期望48的计数错误actual1，改为45音频+2字体=47后actual0。第一browser入口actual1因期望标题遗漏(DEBUG)，且console有字体UID fallback；没有任何游戏输入/存档。保留原件后先 about:blank 停WASM，复制**已有生产export stage**的47 import元数据及uid_cache再串行官方导出：actual0 E0/S0，最终payload差异门0、实际aligned字体warning0。不是资产重生成，也不解释独立旧PCK+32或新+96。

独立存储QA精确口径按父端报告另封[澄清](evidence/20261005-pr15-fresh-web-yard-pause/controls/parent-storage-qa-clarification.json)：fast边界是FS.close后受控reload microtask，非人手F5自然样本/非直接ConfigFile.save-return；old/new800ms这轮都过，CDP确认到reload为992.5/960ms，不能覆盖原失败或宣称800ms永远足够。独立新PCK+96/旧+32仍pending，不把归档tar差异归因于它们；正式origin/后台/性能未验，独立计数不冒充本作者复跑。

[完整证据manifest](evidence/20261005-pr15-fresh-web-yard-pause/manifest.json)封62数据文件/28,353,600bytes，含新原record、原PNG、JSONL/receipts、export与PCK payload审计、只读桥和driver代码、方法负例及shutdown。生产二进制、browser profile、制作源和凭证不进此包；原record按授权PR证据保留，不冒称Library上传成功。未执行的whole/campaign prototype仍不具备验收资格；其中未调用的battlefield fingerprints reader引用enemy_id而源字段是label_id，续工须修正再使用。本包Title fingerprints未走该路径。

已只读核线上同私有Site **active/version2**、source `aa19d5b03c014c3483a2b98320018ea3e4e02042`、deployment `appgdep_6ac31badd5248191af80e81054118b60`；custom access rev1/owner1/外客0/群组0不变。稳定URL `https://ambush-loop-game.lning791548.chatgpt.site`，没有重部署/改ACL；native active状态不折算origin浏览器验收。

**暂停未完成：** 后五关自然11波/五新记录、六新whole1×2×、handoff/next Continue实际链、旧schema独立兼容、正式origin/触控生命周期/后台/耳听、FINAL/fullsmoke/all-art、A3帧预算、可追溯APK及最终设备阶段。Library原八件helper tools/list路径blocked无IDs；两prepared工具当前实际存在，不适用native fallback，不绕代理/猜URL。当前不再启动这些工作，不merge、不做APK、保留所有唯一证据。
