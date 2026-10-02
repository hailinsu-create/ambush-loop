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
