# PR15 音频持续层实施记录

日期2026-10-02。实施计划；本文件尚不是验证通过报告。按用户/dot指令完成R3实际战場固定e7/f47及9038978证据后，接独立355ea89音频候选。技术制作源86df6d0、交付355ea89，已完整审README并逐件只读核45WAV hash，共5,732,600bytes。只原字节迁入45WAV/45显式import；不整体合并、不复制audition/evidence、不编辑或重跑生成器。运行manifest和AudioDirector/SfxBus由本作者拥有。

实现顺序：只用新候选资源和推荐gain；38短声分类voice限额gun4/foley2/signal1/UI1，每cue1；六ambient与stealth进入唯一持续层ambient1/bed1，不与旧mood/once-cue叠放。优先最近高紧急signal/终局互斥；同一ambient重复入口不restart，换关短淡换；战斗duck5dB，省电关闭bed保留危险声。暂停/静音/后台/标题/换关/REPLAY停止，恢复不补播积压；历史seek不重放prefix。

验收门：固定source SHA、隔离guard；45真实导入PCM/loop[0,352800)；实际AudioStreamPlayer.play而非仅bind；Music/SFX独立音量、限额/仲裁/重启、六关切换、暂停/背景/菜单/重试/历史与退出；云端真实AudioServer混音buffer有限/非静音/peak、有样本hash，完整战场/六关原规则回归。PCK空目录检查包含45WAV及运行manifest。Dummy混音/工程波形不当作耳听或设备性能；目前实际听验0/45、0/6，待独立听音能力。

随后R4 optional动作runtime、environment9c06/50ef最小85+旧11、完整yard/HUD/FX/3D回放、A3云端优化、余五关成品、可追溯APK继续。原20骨12clip兼容必须实证后才接受旧R3asset revision；reload只是接触姿态无新装填机制。完成制作和全部云端验证后才设备阶段。GPT PLAN/REVIEW unavailable。
