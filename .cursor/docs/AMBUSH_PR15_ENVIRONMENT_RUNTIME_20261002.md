# PR15 环境运行实施计划

2026-10-02，需求来源为用户完整资产 v2 的 A2/A4 与 dot 交付。角色 R4 正式运行证据已推 PR15；本片接原字节环境，所有权继续由主作者负责运行代码/台账/测试，独立环境作者负责制作源/导出。资源接口与实际六关组装已完成下述固定源云端验证，完整HUD/FX/艺术验收和设备仍待做。

候选源 `50ef7883285c4419dbd8339b935433dc6bb5e3f8`、证据 `9c06f04cf7795faf69d9d69d0f853f30ccf80838`，最小 85 运行文件（40 件/80 GLB、3 PNG、2 TRES）及 11 旧 yard 冻结依赖只读哈希已核对。只采用这 85 文件，生成主作者 manifest；制作源、展场 sample 与资产作者测试不整体并入。

1. 扩展 loader 严格目录/ID/schema，绑定新独立 atlas/emission，并显式处理旧灯空槽 surface1。实际导入 80 LOD、挂点/活动父节点/材质/面数/哈希/无碰撞，空项目 PCK 验导出完整。此门只证明运行资源接口。
2. 真实六关 40×22 逻辑地图的 blocked 副本驱动组装，地表批量化，墙/屋顶/地标/道具映射原用途；不采用作者 12×12 展场替代地图，不从 AABB 生成逻辑占格。切屋顶/墙只影响显示，360° 与低/高俯角另看。
3. 版本化环境字段记录布局/门/箱盖/空箱；旧记录保持灰盒，未知版中性，不借当前关卡。箱/门使用已存在模拟状态或实际事件，打开空箱不保留交互命令，活动 socket 随真实父节点动。
4. SCOUT/ALERT/SWEEP/REPLAY、暂停/2×/任意 seek、重试/换关、六关多波与逻辑不变量回归；实际云画面和预算另报。完整 HUD/FX、R5 交互、A3 优化与可追溯 APK 后续，不把样本或软件渲染称设备验收。

已观察候选限制：35° 门框/屋顶可能挡地标，旧油桶/电台 atlas 斑纹与新包不一致；共享 atlas 不改，主作者处理遮挡/显示绑定。耳听/设备后置，GPT PLAN/REVIEW unavailable；无需阻塞可逆集成。

## 环境资源接口固定源验收

固定源码 `a54d538d10658440ac1bd8336d91a68d1da305ad`，85 原运行文件采用，11旧依赖原字节不变；新独立材质槽及旧lamp空surface1发光显式绑定。正式 `environment_assets_test.gd --render` 618（40件/80LOD），`actor_battle_test.gd --render`231，`asset_library_test.gd --render`333，以及空物理工程 `asset_pack_test.gd`1476，全部实际退出0。完整命令/run_id/哈希/失败开发日志见 [资源接口证据](evidence/20261002-pr15-environment-library/validation.json)。云端资源库 framebuffer 已保存8张、实际看1张；小物与材质在远库画面较暗，完整实战光照/缩放另调，不称最终品质通过。

技术PCK 24478880 bytes，SHA256 `7796693420562ae102031b21ffce3523fb79dee7c0e3cad96d28a88f8de00ff2`，不是APK；45原音频import恢复。此门不代表六关实战环境接入。下一片按真实blocked副本搭建地表/建筑/地标，接门/开箱和旧历史兼容，再跑实际关卡与六关不变量。

## 六关战场切片实施范围（已固定源验证）

40×22原网格副本组装220块2m地表，静态地表/轨道/货箱合批；院落仓房、仓道雨棚货堆、泵站设备、铁路信号杆、油库罐组、电台天线沿原阻挡区布置。新导入物不生成碰撞、导航、通行或高度规则。门叶直接读取原锁闭状态；真实开箱0.4秒进度驱动活动箱盖，take成功后保存纯数据空箱，不再参与拾取。

新记录添加独立environment_schema/revision及门/空箱字段，旧完整记录沿原灰盒/道具显示，未知环境版保留源记录且不用当前环境。35°–65°切遮挡同时保护队员、敌人、哨兵、尸体及掉落物；LOD0/1在缩放22/26之间保留迟滞。正式切片证据见下节；未声称A2/A4整体、HUD/FX或设备通过。

## 实际六关环境固定源结果

源码 **ffb95a670b4b58cbe420571bd9f884fed3a1a41b**，Godot4.7.2 ed1daf0bf。实际六关40×22组装与13原波已运行，不再只是资源展场；部署/装备采用既有reference fixture，波后消费原掉落采用与smoke同样的loot-vacuum fixture，不能称完整玩家寻路/实机触控旅程。50张1280×720实际framebuffer，包括六关SCOUT/ALERT、35°四方位SWEEP、65°SWEEP和历史；箱半开/已搜空另捕获。已看六关SCOUT、低角及历史三张接触表、两张原低角图和开箱原图。

| 固定源入口 | 实际退出0结果 |
| --- | --- |
| `environment_battle_test.gd --render` | 283/0，六关13波、50捕获；真实箱0.4秒搜索/空箱生命周期、门叶、两档LOD、低角遮挡、历史活体关卡/网格/门污染、旧/未知资源及布局版本、源record不改写 |
| `campaign_replay_test.gd` | 10296/0，13波×30/60FPS及2×保持原终局tick/事件：yard1283/34，warehouse1191/67，pump907/34，railcut719/38，depot957/35，radio1413/51 |
| `presentation_contract_test.gd` | 84039/0，坐标/拾取/原始grid与只读状态合同 |
| `visual_snapshot_test.gd --render` | 164/0，历史HUD及原生触控seek |
| `presentation_lifecycle_test.gd --render` / `command_pose_clock_test.gd --render` | 32/0、29/0 |

完整命令、run_id、源树、真实退出码、日志哈希、50张路径/哈希/视角/波次/viewport计数见 [固定证据](evidence/20261002-pr15-environment-battle/validation.json)。原运行85文件＋旧11依赖SHA再次核对零差异；生成器/atlas/GLB制作源未修改或重跑。首次开发277项/1fail为测试误把正确ground id=-1当成可交互箱，源码与失败日志保留；修正后开发headless233/0，正式源283/0。

环境资源rev为50ef788，布局另固定`six_level_grid_assembly_1`，未知两类版本均回落到原记录grid灰盒，不从当前关卡拼历史。货箱按4m区域合批并参与切遮挡；活动门叶实时更新显示AABB。AABB只影响遮挡，无占格/导航/LOS写入。manifest的pending状态是固定源测试前快照，本报告与日志记录测试后的实际门状态。

软件渲染50张中的viewport visible draw calls172–424、primitives53826–168748，作为A3优化输入，不是设备FPS/热稳定性通过。HUD仍挤占战場，资源小件/旧atlas及切遮挡整体隐藏局限继续评审。历史接触表发现未清的live胜负/警报色罩，另行[独立复现与补片](AMBUSH_PR15_REPLAY_FX_20261002.md)，不隐去ffb的原失败视觉。R5工具/尸体、完整HUD/3D事件FX、连续SWEEP时间轴和FAILED/abort终局、最新完整smoke、完整APK仍待完成；耳听0/45、0/6及设备后置。

运行补片2ce6c602e31fb29556c85961704778185ca5a776只加进入历史的实时FX清理，环境/manifest/组装/loader/原六关测试/pack测试与ffb源完全相同，`git diff --exit-code ffb95a670b4b58cbe420571bd9f884fed3a1a41b 2ce6c602e31fb29556c85961704778185ca5a776 -- ambush_loop/scripts/presentation ambush_loop/scripts/replay/visual_snapshot.gd ambush_loop/art/environment_v2 ambush_loop/scripts/environment_battle_test.gd ambush_loop/scripts/asset_pack_test.gd`退出0。36/18fail→36/0、HUD164/0、生命周期32/0，六张清色罩历史另保存/看验。开箱远图目标被旧HUD挡，测试738534274fb54bade2e6201c859b2b406907956a只改焦点/12m近景并提供crate_only入口，不改运行；不能把原远图当清晰接触评审。

技术PCK固定2ce源24521472 bytes，SHA256`f78aa89b1d2bd2cde659b0d4fc26181dbea997d3462f9b6b5a6af1e9ce7f2da0`，空物理工程1512/0（原R4/R3/40环境80LOD/45PCM＋六真实网格×两档组装36项）。不是APK，导出后45原import恢复且运行树差异检查退出0。

近景随后发现旧实心selected/event圆盘仍挡住脚下箱子，独立显示源码 **05a90268086dde694cc2f8313e808b5b23b629ba** 改为空心轮廓，不改位置/拾取/事件身份。focused crate11/0、定位/触控生命周期32/0，半开/空箱原图再捕获并实际看验；盒盖可见，人物同格脚/箱接触仍需R5/完整HUD阶段评审。原50帧仍归ffb，新的两张轮廓近图另按05a固定归档；技术PCK2ce早于这个纯显示补片，未冒称最新整包/最终APK。
