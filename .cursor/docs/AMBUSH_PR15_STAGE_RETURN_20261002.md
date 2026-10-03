# PR15 已推送角色／音频阶段返回

父端于2026-10-02要求先返回实际角色战场固定SHA和运行状态。没有活动Godot验证或挂起等待；原两项Godot僵尸不运行。PR15仍Draft/Open/未合并，无生产发布／高度玩法／设备测试。

已推送：

- R3运行源码 `e7b8cfa44bc306c31286e98bff2c2c8957471beb`；测试类引用补片 `f47f3213331c3ffec88e708f1a0782e4f2ad1435`；完整证据 `90389780c0d6f5f9c0465d26ac520faff1485619`。角色替代实际main/presenter中的灰盒，格式1记录时钟／角色／枪／骨姿，真实yard两波及前后seek／暂停／2×／近远LOD通过。角色和枪接入，建筑仍灰盒；没有把fixture称完整战场成品。
- 音频源码 `4a00a91fe4004e65ce925f845ac5c48930ba32e4`；正式证据 `0a87fda8bf5d26279a13c822026c377e480f2283`。45条实际play／混音、七loop唯一持续层、10路总限额、六关切换、静音／后台／菜单／暂停／重试／REPLAY／标题已验，耳听0/45、0/6。
- 角色详证：[R3战场报告](AMBUSH_PR15_R3_BATTLE_20261002.md)、[固定命令／日志](evidence/20261002-pr15-r3-battle/validation.json)。音频及其后角色回归：[音频报告](AMBUSH_PR15_AUDIO_RUNTIME_20261002.md)、[固定命令／日志](evidence/20261002-pr15-audio-runtime/validation.json)。所有run有独立XDG／StorageGuard。

最近固定4a00a91正式结果，全部实际退出0：audio_runtime --render 405；actor_battle --render 231；HUD --render164；lifecycle --render32；campaign_replay10296；equipment_freeze66；replay_timeline66；空物理工程asset_pack510。原R3的presentation_contract84039／actor_visual4362另有e7/f47固定源日志。六关原终局tick和事件数不变；本轮角色／音频回归不是完整六关主题美术或设备FPS验收。最新完整smoke仍7d34867固定副本，不归到新SHA。

音频PCK `/tmp/pr15-audio-4a00a91.pck`，18,436,084 bytes，SHA256 `98a3f51b7350c29f1c93685dce04693d57c517f4f57dd74347af60d2e04d1f3a`；技术资源包，不是最终APK。原文件45WAV／45 import从355ea89／86df6d0逐字节采用；没有重跑生产源。Godot导出生成的import UID已恢复原候选输入，PCM哈希另在空目录包检验。

## 保存中的下一片

R4主作者运行WIP独立**只本地**保存：分支 `wip/runtime-r4-main-20261002`，固定保存提交 `5ecefe0e3f2c1da119257edcfbfc796783ebfa09`，基于规划 `1514a79148a9e5e8561de04f9ebb797135019eb9`。未推PR15；当前工作树已回到PR15已验生产代码，制作源所有权不变。WIP含候选194d9c4／c4c2170的51GLB原字节、三个枪六旧R3文件保留、格式2枪族／上身分层与腰胯姿态补偿、真实fire/repack元数据和射速脉冲／换枪取消。

R4仅工作树开发验证：52clip真实采样17802；修正蹲姿后真实battle231；十枪×三角色×三LOD 90配置＋实际MG42连发／原空弹切手枪／历史seek 7681，退出0；最新run `6e0a9bed9d914042a5ab860ab9d21a35`，日志 `/tmp/pr15-r4-firearm-dev-final.log`。这些不宣称固定源正式验收；正式battery／PCK／图像看验还未开始。首次蹲姿5个失败、fixture枚举拼写和MG42在原generic MG点超射程的真实反例全部保留在WIP证据，未用改枪射程或数值修fixture。继续时可读取 `git show 5ecefe0:.cursor/docs/evidence/20261002-pr15-r4-runtime/development-only.json`；不能整体合并资产作者分支。

后续优先把WIP切片固定源正式验证后接到PR15；独立作者继续刀／投雷／诱饵／拖尸和艺术修复。环境包9c06f04（制作50ef788）已读交接，最小85新运行文件＋11冻结依赖尚未迁入；主作者负责loader／材质／真实六关场景与历史，环境作者不编辑共享运行代码。A2完整yard／HUD／FX、A3云端预算、五关完整主题及可追溯APK仍待完成。制作和全部云端验证后才讨论模拟器／真机；无阻碍安全回归的权限问题，GPT PLAN/REVIEW unavailable。

## R4 正式继续与推广

父端授权继续 R4 固定源正式验证后推 PR15。全部正式回归现已退出0，固定生产源5ecefe0与测试/导出源448ecf0已完整保存；PR15接收源20cdc8ccfe887f6f64eda9fc64769294fa7de371整个ambush_loop树与448ecf0完全相同，差异检查退出0。十枪90配置7681／动作17802／真实战场231／合同84039／六关10296／音频405／HUD164／生命周期32／静态333／装备66／时间66和空目录PCK1380通过，已看四张实际/历史图；详证 [R4正式报告](AMBUSH_PR15_R4_RUNTIME_20261002.md) 与 [命令/日志/哈希](evidence/20261002-pr15-r4-runtime/validation.json)。先前本地保存说明为当时状态，现由本段替代。环境85原文件＋11依赖及R5交接已核对，实际接入继续；艺术、耳听、设备、完整HUD/FX和最终APK不称通过。

## 环境资源与新SWEEP clock P2返回

环境源码a54d538d10658440ac1bd8336d91a68d1da305ad、证据e0f50dda2f12f8ae7cb8335dd91b98ced8d421ae已推。85新文件/11冻结依赖，40件80LOD618、实战231、装备333、空目录PCK1476退出0；仅运行资源接口，六关尚未组装。dot新P2优先：源码3ba263c4edfc41dd4a498bec100b1ecc2d14b215，最终测试c381258f9a62cd2ac4046704a47eccf1e1413c57，除command_pose_clock_test外运行树一致。正确反例22/11fail，正式24/0＋正常双波撤离/真实终局记录回放29/0，六关10296/合同84039/枪族7681/实战231/HUD164/生命周期32/装备66/时间66/音频405/PCK1476均退出0，详证 [补片报告](AMBUSH_PR15_COMMAND_POSE_CLOCK_20261002.md)。无活动测试、无权限阻碍。完整command时长UI区段、实际环境/R5/HUD/FX/预算/APK继续，未启动设备/耳听，dot独立关闭待验。

## 六关实际环境及视觉发现返回

本轮固定环境源ffb95a670b4b58cbe420571bd9f884fed3a1a41b：真实六关40×22/13波283/0＋50framebuffer，六关10296、合同84039、HUD164、生命周期32、command clock29全部实际退出0；reference装备与原掉落vacuum fixture明确，不称全部玩家/触控路径。环境/布局独立版本、原grid、门叶/箱盖/空箱、两LOD、35°四方向/65°、历史活体污染与旧/未知版回退已验。旧85/11bytes未改。软件visible draw calls172–424、primitives53826–168748只是A3输入。

视觉评审额外证实实时色罩污染历史：ffb源36/18fail→2ce6c602e31fb29556c85961704778185ca5a776源36/0，HUD164/生命周期32退出0，六张清色罩历史已看。测试738534274fb54bade2e6201c859b2b406907956a只把箱近景焦点放到真实箱；随后05a90268086dde694cc2f8313e808b5b23b629ba将实心selected/event盘改空心轮廓，近景11/生命周期32退出0，盒盖可见而角色同格箱接触仍需R5评审。详证 [环境](AMBUSH_PR15_ENVIRONMENT_RUNTIME_20261002.md) / [FX](AMBUSH_PR15_REPLAY_FX_20261002.md)。固定2ce技术PCK24521472 bytes SHA256 f78aa89b1d2bd2cde659b0d4fc26181dbea997d3462f9b6b5a6af1e9ce7f2da0，空物理工程1512/0；早于轮廓补片，不是最终APK。

父端SWEEPclock独立68/0已闭合；断连通知后实际文件/导入/命令/GitHub正常，无恢复阻碍。完成本轮推送核对后可并行独立QA环境/FX与HUD只读视觉评审。主作者下一包R5（2974915/ebedb82），其余HUD/3DFX、连续SWEEP/FAILED/abort终局、A3、最终完整smoke/APK继续；最新完整smoke仍7d34867，耳听0/45、0/6与设备未启动，Draft不merge。


最新R5工具片：[实际刀/雷/诱饵报告](AMBUSH_PR15_R5_TOOLS_20261002.md)。只接2974915/ebedb82的21角色GLB原字节，1092旧键/rig/geometry及30装备/3atlas兼容复核0失败；c5ec8ff工具真实事件clock/target/mask/取消与格式3保留R4/R3历史，d53成功装备立即取消修真实同帧反例4/1→4/0，工具1034/0和冻结66/0。分固定源六关10332/合同84042/角色21818/枪7681/战场231/clock29/HUD164/生命周期32/audio405/static333均退出0，f687空工程PCK1764/0。每run固定源、混合等价范围与保留失败在validation；未称当前全smoke/逐波视觉/设备通过。未merge/生产，制作源/atlas仍独立作者所有，尸体body来源/肩掌配对与20cm局部offset一次为下一片；之后必修desktop HUD覆盖和radio yaw345天线整隐，再FX/A3预算和13波视觉矩阵/完整回归APK，耳听设备后置。


最新尸体片：[真实来源/肩掌/取消与纯回放报告](AMBUSH_PR15_CORPSE_RUNTIME_20261002.md)。ce932cc成功来源绑定/ground/held及真实H抓放先770/0；完整六关10332/3暴露age随capture浮点累加，bf1261c railcut1249/1明确只在两个年龄字段。3048294改domain原锚点后尸体770/合同84042/六关13波10332均0失败；91b9bdc仅扩实际移动/步态测试至1207/0和emptyPCK1766/0，运行树与304等价。复制bodyID/source wave不重绑，原任意loot haul/屏幕14px follow/自动ammo拾取和共享引用不变；内嵌20cm只采样一次。四张实际帧已看，72配对接触及−15mm最低floor门限通过，正向离地/自然艺术/墙碰撞/完整SWEEP玩家拖尸路径未称验收。当前技术PCK25618864 bytes SHA52e14b6b4189af54cb28086b0f36ec08f7201ba24a6be8fa2e823da376562378，非APK；环境重连旧exit句柄失效，304成功有pipefail后TEST_LOG证实0，两个FAILED退出码不冒称观测。HUD盖目标与radio整隐仍是下一必修，然后FX/continuous command/FAILED-A3/13波visual/最新fullsmoke/APK；生产源/GLB/atlas仍独立作者，最新fullsmoke7d34867、耳听设备后置。


最新独立P2：[成功丢弃取消报告](AMBUSH_PR15_DROP_CANCEL_20261002.md)。原518仍同帧投雷→drop rifle→普通更新拾回rifle导致旧throw复活，b082540真实headless6/1exit1；47f0634仅成功drop立即cancel一行修为6/0，6e9ed4c扩失败/同枪kit/ALERT拒绝13/0、完整render1047/0、装备66/0、尸体headless1203/0，3e09a82专项render7/0与恢复枪实际帧。所有实际exit/durable状态和原日志已存。尸体正文按518原receipt改最低−0.001234874m（原误0.003765）、最高0.101031780m，原receipt不改；自然接地/离地上限/墙contact/完整SWEEP玩家路径独立待验。制作资产无修改，既有PCK91早于此修复，最新fullsmoke7d34867；HUD/radio→FX/A3/13wavevisual/fullsmoke/APK继续，未merge/生产/设备。


2026-10-03 R02限定作者修复：[原生SWEEP墙接触报告](AMBUSH_PR15_CORPSE_CONTACT_20261003.md)。固定cd158166真实第二波H/原鼠标路径/朝+Y有363蒙皮顶点进砖墙17/1exit1，d7d291560a77ce112d3fe5f212e39e2d1143c132显式contact版本/共同显示转身修为render576/0，原尸体1203、合同84042、工具1041、冻结66、六关13波10332全部实际exit0；原终局/规则不变，5张真帧已看。独立墙QA、自然正向高度和全墙品质待验，R01由父端报告a325独立关闭；HUD/radio→FX/耳听/A3/13wave visual→单一候选smoke/QA/APK继续，设备后置。G另版、height PR13/16/17/18不合入；ArtSource/GLB/atlas/manifest未改未重跑。旧PCK91/完整smoke7d34867不归当前版本。

附加固定29898fd精确父端MG/force-touch/原生Space-H抓放再抓-鼠标路径复现25/0 exit0；真实flank#3原source(596.6511,207.7352)，97步后(592.2054,178.353)、逻辑90°，LOD0墙内skin顶点0。仅测试文件不同，生产代码等价d7；新MG帧已看，测试parse诊断22c单列保留不计通过。


2026-10-03 R03限定作者修复：[depot点击与radio整隐](AMBUSH_PR15_PRESENTATION_QUALITY_20261003.md)。负向c00ddef69/14实际exit1→4741c5f020965f9a4315fa8993da20474efc04f0正式106/0，桌面重复肖像不再盖depot原SWEEP566目标，radio18姿态保留几何、两LOD逐三角形位置/法线/UV/切线及材质完全保留；copied history/live污染/seek、旧缺失/未知version回退及历史卡片只读已验，四张正式图已看。HUD164/生命周期32/输入23/合同84042/六关13波10332/defaultcontact576/nativeMG25均实际exit0；开发属性重编码失败原日志另存排除验收。R03独立QA与SCOUT顶部文字拥挤仍待；missing/unknown cutaway保留旧整隐行为，55/42部件成本进入A3。父端报告68582原穿墙P2独立闭合但最高浮空97.64mm与中段约0.56m断握仍品质缺口，下一优先修断握，再剩余HUD/FX/A3/13wavevisual/同候选smoke-QA-APK。资产制作源/GLB/atlas/manifest未改未重跑，Notion由指定作者写；耳听0/45、0/6缺实际能力，设备后置。旧PCK91与完整smoke7d34867不能归当前版本，不merge/生产、不混G或height分支。
