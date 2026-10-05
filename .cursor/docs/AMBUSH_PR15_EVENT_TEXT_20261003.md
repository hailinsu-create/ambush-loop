# PR15 历史事件文字绑定记录

生产修复 `fcfdb9be8fe2f862beb7bfa91bdb93faabd290cb`，正式测试固定 `ddec86eacc051e0955164ee3f26d288a25aaade8`，工程树 `0bee6f321686c1d7703140a1c942df98fec5b586`。事件列表、RichTextLabel fallback、定位状态和类型定位入口在REPLAY读取replay.log；现场阶段仍使用battle_log。原first-shot语义和记录格式保持，空历史不借现场事件。正式headless373/0、渲染387/0，二者actual exit0/SCRIPT0/ERROR0；每轮64自然回调、两源各无fire/碰撞seq×1×/2×八组；相关timeline67/0、actual exit0/ERROR0；equipment66/0、actual exit0/ERROR0。最终同步状态以实际push退出与GitHub PR15 HEAD核对为准，独立新P2关闭待父端。

原问题只限定文字：真实旧schema1记录第一枪 `5238b2984c35e9db437210547b996879:0:13`，wave0/seq13/playback227。受控API仅替换main.battle_log为无fire源，replay.log和保存事件保持；状态及列表由 `3.8s  ★ 第一枪是灰狼 → 敌1` 错变 `3.8s  灰狼 开火 → 敌1`。父端原H6/2/R8/2和作者test-only1629380的H6/2/R8/2分别actual exit1/SCRIPT0/ERROR0。普通用户UI换源可达性没有证明，不称模拟、装备或时间身份回归。

真实旧记录来源 `874d3501fdd2b34b0966472e22a9e43a28a1b3dd`，5418800字节，SHA256 `1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12`，末端1415；未升级。现代source为原yard reference部署、合法命令移动和两波战斗实产，wave1056/227、原terminal1283/events34、现代播放1430。reference授枪/消费loot属于隔离fixture，不是正常玩家赢关。

扩展测试在两个实际源分别以无fire和后来枪seq碰撞的live记录换源，检查全部列表文案与保存前缀、第一枪/后来枪定位、类型定位、正反seek、fallback、现场formatter、空绑定及源互换。1×/2×运行真实main引擎_process，用同帧delta独立累计检查游标和每帧文本/实际3D帧/装备；seek与换源是API操作，不称这些操作来自原生点击。自动播放前后记录、SimClock和恢复原source后的现场snapshot保持，原字节hash不变；根/20骨一致性是重复定位验证，不是独立动画数学证明。

开发记录保留：fcf最小H6/0；de86测试Array推断解析错误actual exit1/SCRIPT1/ERROR1，没有业务断言。d6扩展371/2、exit1/ERROR0，64自然回调通过，两个失败是测试误认同tick最后事件等于第一枪；ddec改完整前缀，不改生产源。所有失败、日志和JSON单列，不复用旧report。原反例两张native Window PNG已实际查看。正式14张native Window crop PNG全部核hash，实际查看旧no-fire第一枪、旧碰撞seq的2×后定位、现代no-fire第一枪及现代碰撞seq的2×后定位四张；不称全图目检。所有截图在固定聚焦状态拍摄，auto1/2图是自动播放后API再次聚焦第一枪，不能将静图说成连续播放录像。实际过程由每轮64回调/保存游标列证明，软件等待预算不作设备FPS。

父端title原两P2已限定关闭：固定4ba反例24/0、12/0，自然keyboard740/0、八组反向Tab/slider1003/0，全部exit0/ERROR0；auto29/167、life30/32、Quit7亦通过。父端计数与作者4476分开。本轮不为这些已限定关闭项目重复旧formal29/title整矩阵。

正常旅程暂保留[计划](AMBUSH_PR15_PLAYER_JOURNEY_PLAN_20261003.md)和[证据manifest](evidence/20261003-pr15-player-journey/file-manifest.json)：c7 fresh title1600/200三教学页32/0/exit0/ERROR0，初始教学阻碍未复现。528自然原3D拾取三枪/手雷，但75/1/exit1/engineERROR8为已释放stash测试lambda错误；相邻cover5未部署尚未用clean测试确认。117仅WeakRef类型解析失败，未拿528旧report冒称执行。制作器/PCK staging只加已有a0_preview feature，保留原title/main/进度，不为APK或设备。正常六关13波、SWEEP真实拾取仍待，之后继续首个实际阻碍。

继承父端3ba六原记录自动回放专项：fixed3ba消费此前fixed15c实产哈希已核对的六源，真实3D节点/headless普通过程8786/0、435回调，exit0/ERROR0；214边界正反seek4528/0另列。warehouse极短最终SWEEP自然帧跨过由边界补证。这不是本轮重跑或最新候选六关原生画面/玩家流程通过，live Yard与历史各源分离的限定证据仍保留。

下一步：此固定源独立文字QA，继续正常旅程清洁复现cover优先级，然后全3DFX/A3/余下正常六关与同候选可追溯APK。完整耳听0/45 cue、0/6声景、自然OS切换、艺术、设备/持续性能未验；模拟器/真机在全计划后。网页GPT PLAN/REVIEW unavailable。禁止merge/生产/高度/G混入，Notion归指定管理者。

资产接口固定R5源 `29749157c5db064bfea626c3ed9d75d9a1791ece` / 交付 `ebedb829e3263abbeb6dd266905f24a3869fa281`，20骨/socket/3LOD/52语义保持；所有ArtSource/Blender/GLB/atlas/制作manifest不编辑不重跑。主集成main/presenter/ViewState/replay/HUD/loader/共享测试仍单写，独立资产工作者拥有制作源与输出，不全并WIP。可并行包为固定ddec来源文字独立read-only QA；本轮无需新资产生产包。

证据文档完整diff --check实际exit2，仅原始Xorg日志三处尾空白；原字节保留。排除该单一raw日志后实际exit0，详见validation.json；所有源码切片check0。四正式验证全部结束后无该worktree Godot残留，自有Xorg112实际退出0。

父端后续独立fixed ddec86实际复验已限定关闭历史文字P2-R1，无新P1/P2。原H6/0、实际3D R8/0；独立扩展H7552/0、R7560/0，每轮128自然callback，全部actual exit0/ERROR0。无fire/同seq碰撞live换源、1×/2×、正反seek/list/status/fallback/真实旧schema1与生产WON退出恢复live文案均通过。来源为父端线程01a0efe8-604e-7249-8093-d7921d952020回传，未在本工作区重跑/读取独立artifact；与作者373/387、64callback分开。普通UI混源可达性仍UNPROVEN，正常全玩家/设备/耳听未验，已关title/auto不重开。
