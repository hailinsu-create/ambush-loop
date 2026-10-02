# 固定候选验证 · 2026-10-02

实际验证制作源码：`86df6d0b4af9f30f3f1e670207cc54b22e2f043b`。基线：`4dea88b264d57f21da589ab5ad7a6ceb18662d43`。后续交付提交只增加本证据目录，制作脚本与生产资产保持本源提交的字节。

| 检查 | 实际结果 | 证据 |
| --- | --- | --- |
| 当前 CUES / 委派列表 | 45/45，一致，无新增或遗漏 | technical_report.json |
| WAV / FFmpeg PCM | 45/45 可解码，两个解码器 PCM 完全一致 | technical_report.json |
| clipping / DC / 电平 | 每 cue clipped=0、DC 不超过 1 LSB、4× true peak 低于 -3 dBFS | technical_report.json |
| 六关 ambient + stealth loop | 7/7，16 秒，三次重复接缝步长 0–1 LSB；无边界 RMS dropout | technical_report.json |
| 损坏反例 | clipping、DC、静音、错误 rate、loop 阶跃、错误 hash 均被拒绝 | technical_report.json negative_controls |
| 候选生产体积 | 5,732,600 bytes；PCM 5,730,144 bytes；各低于自定 8 MiB 合同 | technical_report.json |
| 重建 | 两次独立空 /tmp 重建，98/98 生成文件字节/hash 一致，退出 0、0 | reproducibility_report.json、rebuild_1.log、rebuild_2.log |
| Godot 4.7.2 | import / resource probe 各退出 0；45/45 实际资源及 AudioStreamPlayer 绑定通过，7 loop end=352800 exclusive，PCM 与 WAV 原字节一致 | godot_report.json、godot_import.log、godot_probe.log |
| 推荐增益与并发上界 | 建议 10 voices 的完全同相 true peak 上界 -2.33 dBFS；当前 runtime 尚未执行这些 cap | technical_report.json |
| 试听文件 | 5 条本地 WAV 技术检查通过，有完整秒偏移与 hash；未外发 | ../audition/index.json |
| 实际听验 | **0/45 cue、0/6 关环境，未通过听验** | environment.json、technical_report.json hearing_capability |

`run_receipt.json` 保存实际命令、退出码、完成标记、源 SHA 和证据 hash。Godot 检查在无 autoload 的隔离最小工程进行，Dummy 下没有调用 play；不代表游戏整合、声音播放时序、延迟、CPU 或手机性能验收。

采用候选分支 `feat/audio-v2-candidate-20261002`，仅两个新 audio_v2 目录。`ownership.json` 记录开工基线及只读核对时 PR15 head 的范围均不存在；源提交范围检查无越界文件。未改变旧音、共享 manifest、Audio runtime 或角色资产。

剩余阻塞与主作者采用注意：当前环境无音频设备和听音工具，真实性/可辨识/疲劳/手机可懂度未评审；环境 loop 不能直接放入旧一次性 cue player，必须接持续层并处理 pause/background/mute/tier/换关/退出；按新文件电平采用候选 gain 与 cap，再做六关实战 mix、事件去重和回放验证。后置设备阶段由主作者安排。此包不作专业最终音效或完整战场验收声明。
