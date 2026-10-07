# PR15 formalcombined 安全边界 checkpoint

时间：2026-10-03T18:40:42.159897+00:00。源15c0783059bb7c2f9e9cd9b7252a9343e71f4168已普通push及remote/GitHub只读核对，Draft/Open/unmerged。生产源d860056f2107836c08dfb375a034ebbe694baff6；其后只改测试。**本片是部分正式结果，整体验收未完成。**

SCOUT缺失先1ab118/14 exit1实证，d860保存真实SCOUT初帧/约0.1s采样和报警前最后状态，attempt从SCOUT保留至跨波。仅presentation边界tick区分phase，原battle schema2/tick/event seq/terminal不变，schema1/旧域/未知回退保留，事件焦点使用保存身份和playback_time。15c只修共享夹具：SCOUT原attempt、播放轴seek、两次绘制后native抓屏及对应frame receipt。

| 同15c已完成实际命令入口 | checks/failures | exit | ERROR |
| --- | --- | --- | --- |
| camera_input-headless | 23/0 | 0 | 0 |
| campaign-depot-headless | 2068/0 | 0 | 0 |
| campaign-depot-render | 2080/0 | 0 | 0 |
| campaign-pump-headless | 1939/0 | 0 | 0 |
| campaign-pump-render | 1951/0 | 0 | 0 |
| campaign-radio-headless | 3163/0 | 0 | 0 |
| campaign-radio-render | 3179/0 | 0 | 0 |
| campaign-railcut-headless | 1684/0 | 0 | 0 |
| campaign-railcut-render | 1696/0 | 0 | 0 |
| campaign-warehouse-headless | 2659/0 | 0 | 0 |
| campaign-warehouse-render | 2671/0 | 0 | 0 |
| campaign-yard-headless | 2515/0 | 0 | 0 |
| campaign-yard-render | 2527/0 | 0 | 0 |
| command-headless | 217/0 | 0 | 0 |
| command-render | 224/0 | 0 | 0 |
| command_pose_clock-headless | 27/0 | 0 | 0 |
| equipment_freeze-headless | 66/0 | 0 | 0 |
| presentation_contract-headless | 84042/0 | 0 | 0 |
| presentation_lifecycle-headless | 30/0 | 0 | 0 |
| replay_fx_lifecycle-headless | 30/0 | 0 | 0 |
| replay_timeline-headless | 67/0 | 0 | 0 |
| utility_runtime-headless | 1041/0 | 0 | 0 |
| visual_snapshot-headless | 130/0 | 0 | 0 |

上述23次仅截至这个checkpoint。完整命令/环境/UUID/PNG摘要与实际log/exit见[evidence receipt](evidence/20261003-pr15-full-record/checkpoint-20261003.json)及各formal目录run.json。真实旧schema1来源874d3501fdd2b34b0966472e22a9e43a28a1b3dd，二进制SHA256 1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12；旧域1283/34、旧播放1415保持。其文件目前仅本地，QA必须取actual-schema1-874d350/command-record-source-v1.bin。

实际包装命令模板（每条完整参数见receipt）：
```bash
AMBUSH_CAMPAIGN_LEVEL=yard bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 campaign_replay_test.gd --headless
AMBUSH_LEGACY_RECORD_FIXTURE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-full-record/actual-schema1-874d350/command-record-source-v1.bin bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-full-godot full_command_record_replay_test.gd --render
```

六关原terminal/events分别1283/34、1191/67、907/34、719/38、957/35、1413/51；每种mode按原reference部署/vacuum跑60、30、60+2x和camera对照，不能称正常玩家全旅程或设备FPS。WON1283/34、FAILED escape928/19、abort0/3检查保留；旧HUD另一fixture的929不混入。command渲染7帧及当前六关38帧已留存，yard完整6帧contact已看并确认第二波header2/2；其余未称逐图艺术验收。

失败/开发/旧候选均保留在negative/development/preliminary/previous-*。7b3工具1041/1 exit1/ERROR1（空attempt夹具）与历史画面130/2 exit1/ERROR2（旧battle tick seek）均已由15c同生产blob的1041/0及130/0验证修正；firearm headless因明确要求render而exit2/ERROR1，未运行配置断言，不计为枪械通过。旧单draw native图存在一帧phase滞后，被新两draw/identity receipt替代。禁止重跑已有效测试只为补汇报。

现有batch仍在跑，源树不能改：renderer session5976，headless regressions session3098；入口/tmp/pr15_full_candidate15.sh，分支guard固定15c。六关headless与render及全部headless回归已完成，Godot renderer当前credits（随后lifecycle、utility、firearm、visual、FX）。日志/tmp/pr15-full-final-NAME.log及.exit，完成后自动归档formal-NAME。私有Xorg :112 PID53962，仅该显示属于本任务，不碰:99。控制脚本已复制到evidence/checkpoint-control-helpers。

代码可交独立QA；证据约136MB未提交、全部保全。证据正式整合/规划索引更新仍待，不能更改HEAD使现有固定源guard中止。完成现有测试后按实际结果收口，不重跑有效项。title200完整菜单/Help返回/退出确认/键盘留下一独立片；本片未改title。父端67f credits独立127/probe243/life30 ERROR0仅记录其报告，未冒充本15c复验。

资产接口仍R5源29749157c5db064bfea626c3ed9d75d9a1791ece、交付ebedb829e3263abbeb6dd266905f24a3869fa281，20骨/socket/3LOD/52语义。ArtSource/GLB/atlas/Blender/制作manifest未改未重跑，主集成独占runtime/presenter/replay/HUD/loader/共享测试；资产作者仍独立制作。

待验：上述剩余formal、title200、完整3DFX/A3合批LOD预算、正常六关玩家旅程、原两focus裁切、耳听0/45cue和0/6声景、同一最终候选smoke/QA/APK。当前LinuxMesa llvmpipe不证明设备性能；设备/模拟器仍在全计划之后，旧smoke7d34867/PCK91不归当前源码。GPT PLAN/REVIEW unavailable。不merge/生产，不混height/G，不写Notion/Library。


后续状态：同一固定源既有6项render已收齐，29次作者正式结果见[完整报告](AMBUSH_PR15_FULL_RECORD_20261003.md)。此checkpoint保留当时部分/排队状态，不改写历史计数。
