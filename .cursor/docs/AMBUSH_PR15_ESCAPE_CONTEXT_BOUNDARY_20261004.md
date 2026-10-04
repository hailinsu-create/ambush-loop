# PR15 P2-ESCAPE-CONTEXT-1 作者有界修复

2026-10-04。正式候选 **f0ed44311775fa87ee63ebb911c7b11e12e65ab1**；生产验证器修复 **3d30b1309ebcf09a01d17e344b4d900942b67bca**。仅 IntelStore 保存来源校验增加10行；main、BattleLog、ReplayPlayer、原事件生成与 FX-A1a、R5/资产文件不改。独立QA可先检查此固定候选，无须等待全FX或APK。

## 已复现与修复

877原radio参考记录只读解压复制：gzip SHA256 `bf3f914f8828d639a327f498be7bd32ce1b557634361a0339110e9b65c808610`，原raw **7739088 bytes / cf77a08654aff89561723944176e38dcb7aa8b1b8d0a897cf77f39685b7a6c09**。context schema1 / event schema2 / playback schema2各自独立。实际敌5第三波 spawn seq43/local30/global744/playback747 → escape seq47/local957/global1671/playback1675，Δlocal927、Δglobal927、**Δplayback928**。

原验证器实际允许 radio context/spawn/escape 都改wave3并同步原形式event_id后确认“历史第4波”；仅escape.playback_tick改747也确认历史第三波。负向source23c H **3/2 actual1 E0/S0**，有效3D source572 **18/4 actual1 E0/S0**（两validator+两原HUD/result失败）；原valid第三波与新retry身份检查通过。两坏context的实际窗口图已看。

修复从**context保存level的 LevelDef.wave_count()**取得零基波上界，不从当前live level/wave/run取值。只有明确event schema2、playback schema2才确认保存来源；相同attempt/wave原global-local offset检查保持，并要求 **Δplayback ≥ Δlocal**。额外phase ticks合法，不要求双钟相等、不固定+1/928/绝对offset。旧8参、缺context、旧event1、缺/未知三个版本中性“波次/入场未确认”，不升级旧bytes，不补live信息。

## 实际结果与边界

同正式source f0ed443：

| 隔离入口 | checks/failures | actual exit / E / S | Guard UUID |
| --- | --- | --- | --- |
| escape_context_boundary_test.gd H | 57/0 | 0 / 0 / 0 | c8c0b53afaf04af4b5e9fe9e134ec596 |
| 同入口真实3D R | 82/0 | 0 / 0 / 0 | 95e4888663c14756b7f13b7a246cdcdb |
| escape_intel_source_test.gd H | 70/0 | 0 / 0 / 0 | 61d06376e296488883cd0a63188ba3d2 |
| 同原reference真实3D R | 73/0 | 0 / 0 / 0 | 196161a8239a4522a01fe9a93bb8544a |

57项含原第三波/虚构第4波/停滞、合法minimum927/原928/额外phase tick/平移绝对playback offset、短926/反向、六保存level的0/last/count/负波边界、外关拒绝、旧8args/无context、缺未知context/event/playback schema以及内存与原raw保持。这里的六关波矩阵是显式保存context fixture，**不是六场新战斗**。

真实3D额外25项：原retry回调填实际历史HUD，cold SCOUT live新attempt/wave0与保存wave2独立，原advice/result分别确认或中性；foreign yard后回radio恢复原来源，世界/R5、live snapshot、sim tuple、保存memory保持，5张实际DisplayServer Window crop全部核hash并看。cold消费者只在隔离设置内标radio/yard教学seen；FAILED与绑定记忆为明确fixture，不冒称正常input/replay通关。

原escape reference另跑原实际radio三波→原第三波逃逸→retry，授枪/snap/directtick/vacuum/合法SWEEP clear方法沿用既有测试，**不是native normal**。观察的原local/global/playback仍30/744/747→957/1671/1675，escape_context保存原attempt/wave2/敌5/原spawn-escape完整副本，新SCOUT仍“历史第3波 · 0.5→15.9s”，foreign collision/复制/MAX5/25旧边界保持。3张reference实际窗口图核hash并看。两参考新raw单独压缩封存、SHA/bytes见收据，已有payload.fx属A1a，不能冒称与877旧保存bytes相同。

初次3d30 H57/0、R82/0和reference H70/0也保留，均actual0/E0/S0；该R foreign两图被首次教学遮层盖住，复核发现后只修cold consumer seen夹具并重跑正式f0e，不将被遮图当可见HUD证明。其他开发失败原件完整保留：23c冷SCOUT未执行retry导致原advice label为空，R15/5 actual1 **E1/S0**（ALSA fallback）；349把wave_index方法当属性，R3/2 actual1 **E0/S1**。修的是夹具与两指定入口Dummy audio，不归生产失败，不称耳听。

## 命令、环境、证据

实际从 `/workspace/ambush-pr15` 运行，每次都先由共享wrapper生成独立XDG/Guard；日志完整包含隔离路径与UUID。边界源环境为 `AMBUSH_ESCAPE_CONTEXT_RECORD=/tmp/pr15-escape-context/producer-877-radio.bin`，正式4次 `AMBUSH_TEST_SOURCE_SHA=f0ed44311775fa87ee63ebb911c7b11e12e65ab1`：

```bash
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 escape_context_boundary_test.gd --headless
DISPLAY=:117 LIBGL_ALWAYS_SOFTWARE=1 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 escape_context_boundary_test.gd --render
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 escape_intel_source_test.gd --headless
DISPLAY=:117 LIBGL_ALWAYS_SOFTWARE=1 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 escape_intel_source_test.gd --render
```

官方Godot4.7.2，gl_compatibility、Mesa25.0.7 llvmpipe LLVM19.1.7/256bit、1280×720/scale1、Dummy audio。两个H与首个R曾独立并行，仅功能检查，不报性能。R序列独占自有Xorg:117；所有engine自然退出后才精确关闭PID101876/原argv，session37986 **actual0**。没有碰其他display/process/save。

原日志/实际退出文件/JSON/19保留窗口图/新reference原bytes gzip/正式测试源码与wrapper/环境/生产原validator负例在 [证据目录](evidence/20261004-pr15-escape-context-boundary/)；manifest与收据逐项列hash和范围。正式8图核hash并看，负向有效两图已看；保留的开发图不计正式验收。父端fixed877独立min3/2、R49/2各actual1 E0/S0单列保留，不与作者计数相加。

## 待验与下一步

P2独立QA待；此片不证明native input、新正常13波、完整录制/旧schema1实际播放器、FX-A1b/A2/A3、最终同candidate全门/fullsmoke/APK/设备或耳听。原smoke54/62与bounded8906actual0继续保留，INITIAL29976/0只归producer_a05/consumer_d9c，不能拼当前FINAL。

父端fcf静态教学限定QA：原29/22→29/0、实际3D40/0 actual0、四图看/两包封存；未提供额外包hash不补造、不重开已闭cdb/392等scope。

下一主集成片 FX-A1b：只读保存R5 pose/枪与muzzle socket采样、有限muzzle/tracer/actualhit池、绑定playback时间，补pause/seek/source/旧missing-neutral与真实R。随后A2工具FX→A3实际指标/优化→最终固定source全门/正常13波/新六record/fullsmoke→可追溯APK。独立并行包：父端现在可只读QA f0e此P2，不需等待全FX/APK；后实际FX帧供资产工作者艺术评审、固定FX候选供独立A3量测。

资产接口保持 R5 source29749157c5db064bfea626c3ed9d75d9a1791ece / deliveryebedb829e3263abbeb6dd266905f24a3869fa281，20骨/socket/3LOD/52语义。主作者main/input/HUD/presenter/ViewState/replay/runtime-loader/shared tests唯一写者；ArtSource/v2/build_yard_kit.py、atlas、GLB/Blender、生产asset manifest由独立资产作者拥有，未编辑/重跑/全并WIP。Draft普通push，不merge/发布/height/G；网页GPT PLAN/REVIEW unavailable。
