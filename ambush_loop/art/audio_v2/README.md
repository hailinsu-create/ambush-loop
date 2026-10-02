# Audio v2 候选成品

45 个新原创合成 WAV，逻辑 ID 与固定 `4dea88b264d57f21da589ab5ad7a6ceb18662d43` 的 `SfxBus.CUES` 逐项一致。六关环境和 `stealth_bed` 提供 16 秒完整循环。仅此目录为可采用音频成品；制作、许可、试听、验证和采用合同见 [源包说明](../../ArtSource/audio_v2/README.md)。

`catalog_candidate.json` 与 `cue_map_candidate.csv` 是独立采用候选表。尚未接入 runtime，实际听验待完成，不能作为完整战场音效已验收的证明。

45 个 `.wav.import` 是显式制作输入，必须与 WAV 一起采用：PCM 16-bit、禁止 trim/normalize、非循环禁用 loop、循环 forward 且 end 为 exclusive frame count。它们不包含导入缓存或机器私有路径。原仓库忽略 `.import`，此包有意单独跟踪这些新路径。
