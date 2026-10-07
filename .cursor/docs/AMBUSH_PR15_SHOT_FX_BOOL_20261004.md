# PR15 保存pose可选布尔边界

2026-10-04，固定修复源码 `866a63b01a113c0da4e0e7865666e060fa5988a1`。仅ShotFxFrame已知FX1/R5读取入口有字段时要求TYPE_BOOL；缺字段保持原默认true，合法true/false原值保持。ActorVisual、原事件、旧记录schema及制作资产未改。

实际来源：A1a正式183存档7个descriptor中6个Kar98k pose缺该字段，原刀pose明确false。现有corpse/utility producer也写字面false。原实际枪击fixture与隐藏R5 sampler的缺字段/true/false、全部20骨骼默认true等价、原bytes保持均通过；字符串false/true、整数0/1、null、字典、数组为明确损坏fixtures。

固定562负向H100/7、actual1、ERROR0/SCRIPT0、Guard通过；固定866同测试H100/0、actual0、ERROR0/SCRIPT0、Guard通过。命令：`AMBUSH_TEST_SOURCE_SHA=<fixedSHA> bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 shot_fx_frame_test.gd --headless`。负向UUID4d1ae37ecd114c8f9c496b8cedf49c86，正式UUID04841c0a21554129b65153b0c2f1cf1a。完整日志、actual退出、report、固定reader/test及13条hash manifest保存在[evidence](evidence/20261004-pr15-shot-fx-bool/manifest.json)。

c9c开发测试误用静态bool(String)被Godot解析拒绝actual1/E1/S1，未进入Guard且无实际check，原失败完整保留；562改测试移除无效静态构造，实际负向另列。未声称字符串强转得到true。

此片没有3D FX池、实际窗口FX、FINAL13波、A3性能、APK/设备验收；下一片有限12slots/48纯值cache、保存原R5枪口采样与真实render生命周期。主集成单写者及独立资产所有权保持，不重跑制作源、不动GLB/atlas/manifest。网页GPT PLAN/REVIEW unavailable。PR15保持Draft、不merge/发布。
