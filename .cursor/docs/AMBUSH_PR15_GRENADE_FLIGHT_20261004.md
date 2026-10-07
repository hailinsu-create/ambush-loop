# PR15 A2 原手雷飞行单位切片

2026-10-04。继承[工具/烟/尘计划](AMBUSH_PR15_TOOL_FX_PLAN_20261004.md)，先作者实证原投掷/实际sim_step/保存snapshot/真实3D节点位置。固定负测试source `102df5b83e5a45c31bcb8d60389fd6f60eacb26f`，生产presenter未改；9c初稿未执行，102仅修test同tick最后snapshot预期，未改生产时间轴。

原RaidGrenade._flight为0–1进度，.18s/.10s存于独立flight_duration；旧3D把progress再除duration并clamp1，使真实mid-flight0.5的1.25m弧高变成约0。原2D位置已含自己的18px lift，本片保持原逻辑/映射，3D y是presentation弧高，不变成新抛物规则。实证负H119/15 actual1 E0/S0（UUID4170f908c4284e4c832a331a4d220cf0），失败全为旧height公式：真实quarter/mid/bounce、REPLAY原seek、missing/different-duration明确兼容fixtures、四个authentic INITIAL原飞行帧。原投掷成功、库存2→1、BattleLog事件数、原progress/duration/position、bounce8,6/0.1s、settled等待fuse、历史pause/原bytes等其他断言无失败。

固定修复source **53e2eeb937b48b1a593991af921329d0a7f65c6d**、Godot工程tree **5a7968e90223498fc1504fb4b347ecb00578af94**：仅presenter一行移除重复duration除法，clamp0–1及原1.25m幅度保持，其他生产代码不改。同原测试字节的固定H119/0（UUID48b14613bb9645be83e2da90f1734a94）、R128/0（UUID00962a3e1bfb4caebce380b2680b065b）均actual0 E0/S0、Guard通过；真实midpoint y=1.25m。旧102 R128/15 actual1 E0/S0、UUID6be4718460c14e20913418f5d3def37c亦保全。

9正式实际Window PNG全核hash/目检，9旧负PNG全核hash/实际看2；midpoint/quarter的小原grenade模型已可见于正确弧高，落地/部分bounce保留屋顶深度遮挡，未修改剔除规则或放大资产。REPLAY图展示保存的midpoint高度；直接调用transport后HUD文本未逐帧刷新，不将该图当完整HUD/普通玩家transport验收。所有图未后处理。自有Xorg119 PID107496 exact argv核对后SIGTERM，自有四轮引擎均自然结束，Xorg session5661 actual0；没有停止其他worker。

测试明确使用参考授枪/库存、原_throw_grenade_from、原_tick_raid_grenades到sim_step的显式dt，以及独立advance_command_playback fixture录原snapshot；不是普通玩家输入或自然连续战斗。REPLAY用原入口、同tick末帧选择、前后seek、暂停30实际draw frames，missing/different duration只是复制的字段fixture；四个INITIAL原件来自a05 native producer，六原件hash/memory只读不升级，railcut/depot没有该次检查的midflight帧，不能补称已验。

实际复验命令（固定source、fresh隔离UUID；R需executor自己的display）：

```bash
export AMBUSH_TEST_SOURCE_SHA=53e2eeb937b48b1a593991af921329d0a7f65c6d
export AMBUSH_INITIAL_RECORD_ROOT=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime/baseline-a05fa959093e-7b50d8a62bfd48dc9f741796d2ce9e75
bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 grenade_flight_height_test.gd --headless
DISPLAY=:119 bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 grenade_flight_height_test.gd --render
```

独立executor可从INITIAL evidence/native-all六个native-player原gzip解压同bytes到独立/tmp并设INITIAL_RECORD_ROOT，不重建。实际官方Godot4.7.2 SHA8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e、OpenGL4.5 Mesa25.0.7-2+deb13u1 llvmpipe LLVM19.1.7、1280×720/scale1、Dummy，0 XTest/无耳听；日志、actual exits、JSON、18原PNG、fixed sources/wrappers、环境及Xorg退出见[证据manifest](evidence/20261004-pr15-grenade-flight/manifest.json)。未新增制作资源。

本片只修飞行presentation单位；未实现或验收blast/smoke/dust来源/池，不以消失、投掷或spent猜真实爆炸。下一独立确认callback到终局snapshot接口，保存实际位置/半径/每victim HP差与稳定tool/effect identity，保持原伤害归因、BattleLog原统计与事件身份；再有界烟尘/爆炸及实际云端图。A3预算/优化、FINAL同source全门/正常13波/六新record/full1×/最新fullsmoke/APK、独立运行QA及设备耳听待。R5制作源/GLB/Blender/atlas/manifest未编辑重跑，主集成唯一代码作者，Draft不merge/生产/height/G，网页GPT PLAN/REVIEW unavailable。
