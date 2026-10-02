# PR15 音频持续层实测报告

日期2026-10-02。固定运行源码 `4a00a91fe4004e65ce925f845ac5c48930ba32e4`。制作源 `86df6d0b4af9f30f3f1e670207cc54b22e2f043b`，交付 `355ea89243451d2c9f1b69ca5b44e8c437fa4555`。只原字节迁入45 WAV／45显式import，共5,732,600 bytes；无生产源／audition／样本工程整体合并，没有编辑或重跑资产生成器。

38短声只占 gun4／foley2／signal1／UI1；七loop由唯一当前ambient与可选bed拥有，总上限10路。推荐player gain与Music−6dB总线各应用一次。最近枪声／UI替换旧声，高紧急signal优先、终局互斥；同关两个旧入口不会叠放或重启。换关先停止旧层，用单owner 80ms淡入新层；ALERT duck5dB，省电关bed保留环境与危险声。暂停、菜单、静音、后台、换关、重试、REPLAY和标题停止相应层，恢复不补播旧枪声。历史seek保持安静，不把过往prefix重放。主流程在SCOUT建立后开启当前层，退出释放关卡所有权。

完整命令、固定SHA、run_id、退出码和日志／原始混音哈希见 [机器证据](evidence/20261002-pr15-audio-runtime/validation.json)。4.7.2 Compatibility、云端Mesa软件渲染，实际结果：

| 检查 | 结果与范围 |
| --- | --- |
| audio_runtime_test --render | 405项，退出0；45条实际play调用、playing owner与真实AudioServer采样，全非静音／有限；全部PCM、gain、七loop [0,352800)、并发、独立音量、省电、实际六关切换／ALERT／暂停／后台／REPLAY／重试／标题 |
| R3 actual actor_battle --render | 231项，退出0；真实yard完整两波、历史装备／骨姿／LOD、暂停与2×回归；建筑仍灰盒 |
| HUD／生命周期 --render | 164／32项，各退出0 |
| 六关完整多波 | 10,296项，退出0；static60／rotate30／rotate60@2×，原终局tick和事件数保持；不是六关美术验收 |
| 装备冻结／时间轴 | 66／66项，各退出0 |
| Linux PCK export | 退出0；18,436,084 bytes，SHA256 `98a3f51b7350c29f1c93685dce04693d57c517f4f57dd74347af60d2e04d1f3a`；技术包，不是APK |
| 空物理工程PCK加载 | 510项，退出0；45条原PCM hash／帧数／loop与R3角色库真实加载 |

45 cue总采样278,528帧，每条至少4,096帧；密集10路捕获4,096帧，绝对峰值0.21602863。保存 [真实混音WAV](evidence/20261002-pr15-audio-runtime/audio_v2_actual_mix_stress.wav) 和 [逐cue数据](evidence/20261002-pr15-audio-runtime/audio_v2_runtime_mix.json)。Dummy驱动运行实际混音线程；这些是工程采样，**实际耳听仍0/45、0/6**，不写听感、美术或设备性能通过。

实际战场重新捕获SCOUT／ALERT；本作者看了ALERT，角色／脚底和战斗层仍在真实yard，建筑与旧HUD布局仍待成品切片。另一张已捕获但不写逐图品质通过。

首轮实际退出1：alarm播放调用／playing均成功，但新AudioEffectCapture的首次异步安装还没有返回帧；其余44条通过。保留失败日志及原计数。修正fixture先证明采集器已收到帧，再清buffer测cue，45条均通过。有限性检查改为逐buffer汇总全部样本，405项不伪装成几十万独立场景。导出时Godot自动补import UID，随后恢复候选45原输入，WAV、导入参数和PCM全部不变。

下一片R4 optional枪族姿态：只读核对194d9c4／c4c2170的21人物几何／20骨／inverse bind和252旧clip完全兼容，76原socket不动；六枪新后握把几何不同，需要保留原R3回放资源。之后environment 9c06／50ef最小85文件＋11冻结依赖、完整yard／HUD／FX、A3云端预算、余五关成品、可追溯APK持续实施。刀／投雷／诱饵／拖尸源动作仍由独立资产作者完成，reload contact只表现既有事件，无新装填机制。

最新完整smoke仍为7d34867固定副本；不归到本SHA。Windows包装器未运行。完整制作和云端验证后才设备阶段；GPT PLAN/REVIEW unavailable，无虚构approve。
