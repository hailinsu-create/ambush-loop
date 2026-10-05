# PR15 独立45 cue音频制作接口

日期2026-10-02；当前代码契约来源 `4dea88b264d57f21da589ab5ad7a6ceb18662d43` 的 SfxBus/AudioDirector/main 与 smoke。用户已授权dot分派独立音频制作；本文件是主集成作者的接收接口，不是声音品质通过报告。

## 所有权与格式

音频作者独占 `ambush_loop/ArtSource/audio_v2/` 与 `ambush_loop/art/audio_v2/`：可复现制作源、WAV、候选台账、README及独立证据。主作者不编辑或重跑其制作源、修改音频文件；主作者维护 runtime loader、AudioDirector/SfxBus、运行映射/总manifest、回放事件去重和共享测试。不要改共享runtime、既有audio目录或其他作者的角色/yard文件。

runtime首版采用22,050Hz、mono、signed PCM16 little-endian RIFF/WAV；当前 duration helper按该格式计算，先保持兼容。可保留高采样率/位深源，但不能将其直接冒充这个runtime格式。每个WAV干声峰值 ≤0.501187（−6dBFS），零削波，有限数据；记录实际sample peak、RMS、duration、frames、bytes和SHA-256。该上限是本切片留出混音余量的工程约定，不代表同时事件混音或最终听感已经批准。

不把现有运行gain或候选suggested_gain_db烘焙进文件，避免叠加两次衰减。枪/警报/关键stinger可用约−12到−6dBFS peak，UI明显较低；短促瞬态不用同一个RMS目标硬拉平。建议增益另列，主作者基于密集同时事件混音核定。来源/许可/第三方引用或原创制作方法必须逐件可追溯；确定seed和工具版本，二次生成hash及真实命令/退出码独立记录。

## 45个用途ID与候选台账

保持现有枚举，不重命名或遗漏；允许多个用途引用同一个已声明样本。候选台账放 `ArtSource/audio_v2/cue_candidate.json`，主作者审查后再生成运行台账。

```text
alarm alarm_stinger fire fire_mg fire_scout fire_smg fire_bolt fire_garand
fire_mg42 fire_pistol fire_shotgun fire_ping return_fire empty loot op_death
escape fail win win_stinger door trip barrel kill hit ui spawn echo_ping
handoff leak night_enter tension ambient_yard ambient_warehouse ambient_pump
ambient_railcut ambient_depot ambient_radio foot whistle knife crate_lid
body_drop select stealth_bed
```

每个cue至少：`cue_id, path, sha256, sample_rate, channels, bits_per_sample, frames, duration_sec, peak, rms, suggested_gain_db, loop, loop_begin_frame, loop_end_frame, source, provenance, license, status`。path为相对project的 `art/audio_v2/<stable_name>.wav`，不用机器绝对路径。`variants`可选：foot的metal/soil两种文件与同样的测量字段，保留foot默认映射；其他模型枪声可先共享sample，但不共享用途身份。状态必须区分制作完成、技术测量、实际听过、runtime接入及未验项。

## 循环、时长与现有检查

六个ambient和stealth_bed提供可循环样本：`loop=true`，帧边界 `[begin,end)`，0 ≤ begin < end ≤ frames；同时记录循环点振幅/斜率差、已听循环接缝与未验项。首版可用完整文件循环并做周期/交叉渐变，不能只把单次声勾成loop。主作者接入后通过唯一环境层切换；旧 `play_mission_ambient` 不另开启重复循环。

其余cue单次，`loop=false`；起止无明显click，保留枪声尾音，尽量避免长静音。UI/脚步等短声、枪声与尾音、警报/胜负stinger分别保留合适时长，标明尚未完成的真实型号准确性。

现有smoke实测对象是原始样本，必须兼容：fire peak ≥ ui peak×1.15；tension peak≥0.18，echo_ping peak≥0.10；fire_bolt比fire_smg至少长0.06s；fire_mg42和fire_mg时长差至少0.02s。这些是已有最低区分门槛，不能据此宣布逼真音色通过。

现有单次运行gain：alarm−12、alarm_stinger−10、fire/return_fire−13、fire_mg−12、fire_scout−15、fire_smg−14、fire_bolt−12、fire_garand−13、fire_mg42−11、fire_pistol−14、fire_shotgun−11、fire_ping−16、ui−20、tension−8dB；ambient约−24到−28、stealth−20。它们供兼容/推荐增益判断，候选实际混音由主作者调整，不能在制作文件里再套一遍。

## 接收验证与未验边界

交付固定候选提交、完整45项台账/脚步变体、来源/生成命令、二次生成比较、每文件PCM测量和试听样本（单次、循环、密集事件）。有实际听音能力时记录实际听过的对象/结论；没有则明确未听，不以波形代替耳听。

主作者随后做Godot4.7.2实际导入、PCK包内加载、mute/独立Music-SFX/后台恢复/场景切换、暂停2×/重试/回放去重与并发测试。回放靠attempt-wave-seq和记录时间驱动；seek不能重播整个前缀，后台不补播积压。制作音频不会改变战斗时序或伤害。云端Dummy/波形不证明设备听感或手机性能。完整计划云端制作/接入完成后再讨论设备阶段。
