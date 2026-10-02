# 45 cue 原创音效候选 R1 · 2026-10-02

本包是供唯一主集成作者 `01a0fcab-4daa-716b-8d26-e998edbb30bd` 采用的独立音频候选。它完成新资产制作及所记录的技术检查，**未实际听验、未战场接入、未完成专业音效品质验收**。不得将资产数量或导入成功表述为完整战场音效通过。

基线固定为 PR15 的 `4dea88b264d57f21da589ab5ad7a6ceb18662d43`。独立分支 `feat/audio-v2-candidate-20261002`，只增加 `ambush_loop/ArtSource/audio_v2/` 与 `ambush_loop/art/audio_v2/`。开工时两个路径不存在，无旧资产冲突。未修改 main、Audio runtime、共享 manifest、角色源/GLB、旧音频或测试包装器；不推 PR15，不 merge、部署、构建 APK 或运行模拟器/真机。

范围遵循 [执行顺序 v2](../../../.cursor/docs/AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md)、[仓库指引](../../../AGENTS.md) 和最新委派的单写者边界。规划索引由主作者维护；本候选说明留在授权的新资产范围。原交接与管理来源：[交接](https://app.notion.com/p/3edcc0775087818ea39edeb723e03671)、[管理](https://app.notion.com/p/3edcc077508781c9952bf48c66a77c11)。网页 GPT PLAN/REVIEW unavailable，没有外部 approve。

## 制作与来源

全部新 WAV 由 [build_audio.py](build_audio.py) 原创合成，不含任何录音、第三方样本、提取游戏音频、模型服务素材或付费输入；未安装工具、调用用户 secret 或外发试听。设计参数、每 cue 固定 SHA-256 派生 PCG64 seed、频段、压力包络、共振模态、机械动作、反射和电平都保留在源脚本。44100 Hz 内部合成，抗混叠降至 22050 Hz；短音先去低频 DC，再保留零值首尾。循环使用周期频谱、周期调制与环形叠加，选择平滑边界，不用首尾静音淡出掩盖接缝。

制作意图为暮色工业写实战术：枪族由不同压力体、频谱、机械时序和反射尾组成；UI 用短、柔和机械触点；危险/结果用克制的铃、无线电或低共振动机。六关声景覆盖 wind/vent/motor/water/rail/diesel/static 的不同结构。`fire_mg` 与 `fire_mg42` 保留旧资产已有的短 burst 声学形状；不是给每个逻辑射击新增行为或模拟真实枪械射速。`fire_garand` 没有每枪弹夹退出 ping；`fire_ping` 单独保留旧 cue。没有增删逻辑 ID、语音台词或新玩法触发。

这些合成结构只是候选设计意图。枪械真实性、压力感、六关辨识、循环疲劳、UI 干扰和手机扬声器可懂度均需听验，频谱差异不证明感知辨识通过。原素材许可和脚本许可在 [LICENSE.txt](LICENSE.txt)：生成 WAV 为 CC0-1.0，作者脚本/文档为 MIT；工具本身的许可不转写成素材来源。

## 采用合同

完整 45 项 ID、资源路径、时长、电平、voice class、loop 和状态见 [候选台账](../../art/audio_v2/catalog_candidate.json) 与 [候选 cue 表](../../art/audio_v2/cue_map_candidate.csv)。两表是独立资产数据，不是 runtime/shared manifest。

| 项目 | 候选合同 |
| --- | --- |
| 格式 | 22050 Hz、mono、PCM signed little-endian 16-bit WAV；与当前 `AudioStreamWAV` 返回型一致 |
| 压缩 | 成品无损 PCM；显式 `compress/mode=0`。本包无需压缩即可低于 8 MiB 候选预算。尚未验证 ADPCM/Vorbis 听感、解码成本或循环精度；可由主作者另做独立压缩切片 |
| 电平 | gun/alarm/barrel sample peak -6 dBFS，其他信号 -8/-10、foley -10、UI -14、ambient -12、bed -15；4×重建 true peak <= -3 dBFS；clipped sample = 0，DC <= 1 PCM LSB |
| 运行音量 | 按台账 `recommended_player_gain_db` 使用，SFX bus 0 dB，Music bus -6 dB 为固定基线。新文件电平不同，沿用 `_gain()` 不能代表本包混音合同；特别是旧 ambient 的 -24…-28 dB 会过度衰减 |
| loop | 六关 ambient 与 stealth bed 均 16 秒 / 352800 帧，forward，begin 0，end 352800（exclusive）；其余 38 项关闭 loop |
| 导入 | 45 个新 `.wav.import` 一起采用，禁止 trim/normalize、禁止 8-bit/downsample；`edit/loop_mode=2` 是 forward、`1` 是 disabled。Godot 4.7.2 AUTO 对 smpl 的 inclusive end 留下 352799，不能依赖 AUTO 获取完整周期 |
| 存储与内存 | WAV 共 5,732,600 bytes（5.47 MiB）；全库 PCM 5,730,144 bytes；每关只驻留一个 ambient+bed 为 1,411,200 PCM bytes，另加短音与资源/播放器开销。8 MiB 是本候选自定合同，未把它宣称为既有项目全量预算 |
| 并发建议 | 10 voices：gun 4、foley 2、signal 1、UI 1、ambient 1、bed 1；每 cue 最多 1。当前 runtime 没有总并发限制，建议需主作者实现并验证 |
| 仲裁建议 | signal 优先保留最近最高紧急度消息；互斥终局、禁止 alarm/stinger/barrel 三者无界叠加；先收低优先级 foley/UI；不增加事件、修改模拟或冻结规则 |
| 生命周期 | 背景/暂停/静音/返回标题/换关必须 stop；ambient 互斥，换关建议 60–120 ms 淡换，战斗 ambient/bed 再衰减 4–6 dB；省电层可关闭 bed，不能丢失危险提示 |

候选 10 voice 分类上限与各 cue 推荐增益一起成立时，按测得 4× true peak 做完全同相最坏叠加上界为 -2.33 dBFS。这是数学电平约束，不是手机音量安全、实际 runtime mixing 或性能通过的证明。试听 stress montage 也不替代主战场并发和触发去重测试。

现 runtime `SfxBus._pooled_stream()` 仍合成旧音；`play()` 为每 cue 一个 player 并重启；`play_mission_ambient()` 一次性播放当前 ambient，持续的 `_mood` 是 AudioDirector 另一生成层。**不能只替换文件路径就开启所有七个 loop**，否则旧 cue player 会无限播放且可与旧 mood 重叠。主作者应把 ambient/bed 明确接入持续层，保留 pause/background/mute/tier 生命周期，只读当前关卡身份；短 cue 的触发位置、历史事件身份、一次性去重与 ALERT 冻结保持原契约。

## 试听与听验状态

[audition/index.json](audition/index.json) 给出每个样本的秒偏移、循环接缝位置和 hash。5 个本地 WAV 分别为武器、foley/UI、危险/结果、六关及 stealth 完整周期+2 秒接缝、推荐增益 stress montage。前四轨保留源电平，最后一轨使用推荐 player/bus 增益、真实重叠尾，不做增益归一化或 limiter。未自动外发。

**实际听过：0/45 cue，0/6 关环境。** 环境没有 `/dev/snd`、播放/听音/转录工具；解码、波形和频谱仅属技术验。下一位有听音能力的评审应听全 cue，重点比较枪族、alarm vs terminal danger、hit vs kill、UI vs select；在第 04 轨每关第 16 秒处确认循环，并在重复完整循环、耳机与手机扬声器及战场 mix 中检查疲劳/遮蔽。听验不应由用户临时真机安装阻塞本阶段生产，主作者可先用有音频能力的评审环境。

## 可重复生成与技术验证

已装环境：Python 3.12.14、NumPy 2.3.5、SciPy 1.17.0、FFmpeg 7.1.5、Godot `4.7.2.stable.official.ed1daf0bf`。无需安装、API key、secret 或联网服务。重复 hash 的保证范围是固定本轮 toolchain，不声称不同 FFT/编译平台浮点字节必然一致。

在仓库根目录运行以下命令；`<source-sha>` 使用待验证源提交，`<godot-4.7.2>` 使用实际固定二进制绝对路径。生成器默认只写这两个新目录，`--output-project /tmp/...` 可生成独立副本。

```bash
python3 ambush_loop/ArtSource/audio_v2/build_audio.py
python3 ambush_loop/ArtSource/audio_v2/validate_audio.py --source-sha <source-sha>
python3 ambush_loop/ArtSource/audio_v2/reproduce.py --source-sha <source-sha>
python3 ambush_loop/ArtSource/audio_v2/run_engine_validation.py --godot <godot-4.7.2> --source-sha <source-sha>
```

`validate_audio.py` 从当前固定源解析 CUES 并核对 45 项；Python WAV + FFmpeg 独立解码逐字节比较；测首尾、DC、clipping、4× true peak、循环步长/斜率/边界 RMS 与三次重复，核对磁盘、PCM、混音上界与旧 smoke 的音频形状约束。包括 clipping/DC/静音/错误采样率/错误 hash/循环阶跃六个真实损坏反例，要求都被拒绝。没有运行 gameplay smoke，不能借旧音频断言的静态等价称全游戏测试通过。

`reproduce.py` 两次从独立空 `/tmp` 路径生成，逐字节比较所有 45 成品 WAV、45 导入输入、候选表、5 试听 WAV 及索引/校验收据。`generated.sha256` 是生成物清单。

`run_engine_validation.py` 在 `/tmp` 最小工程复制本包，只执行 Godot editor import 和只读资源检查。隔离 XDG，无游戏 autoload、玩家档或破坏性测试。45 个 AudioStreamWAV 全部核对 rate/channel/16-bit、帧数、loop 区间及原始 PCM 字节；实际绑定/释放 AudioStreamPlayer，未调用播放。没有修改共享测试白名单，也没有直接运行 smoke。

证据在 [evidence/](evidence/)：JSON 记录实际验证源 SHA、退出码、每 cue 测量、重复 hash、Godot 导入日志。构建与技术验证固定源码提交见各 report 的 `validated_source_sha`；最终交付提交只补证据，生产 WAV/生成脚本以报告 hash 核对。当前通过范围为资源技术条件，尚缺实际听验、集成战场混音、六关 loop 生命周期及后置 Android/性能验证。

主作者采用时只迁入这两个新目录（包括被上级 gitignore 忽略而已显式跟踪的 `.wav.import`），依据候选表做自己的 runtime 接线与共享 manifest 更新。无需整体合并候选分支的其他历史改动；本分支相对固定基线没有范围外改动。父任务负责转交，候选作者不联系其他作者、不推 PR15。
