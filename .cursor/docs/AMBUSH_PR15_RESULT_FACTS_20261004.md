# PR15 六关结果事实切片

修复源码 **a7942a96415c844701cdaa1f2bd2654ef3a52b14**。main结果统计与Payoff正文统一显示关名＋封锁完成/尚未封锁；pump原中性措辞保持。教学hook/简报、实际第一枪/终局与事件摘要保留。战斗、装备、spawn、记录身份/时钟/R、存档及制作资产未改；完整3D FX不是本片。

[六关源码/实际证据审查](AMBUSH_PR15_RESULT_FACTS_AUDIT_20261004.md)区分：warehouse原b27未续包、depot/radio原3b49无mine/trip却显示完成教学动作，是既有正常反例；yard/railcut复合动作的判定没有角色/路线绑定，只列源码不足，人工晚灰狼主路fire不冒充新的正常旅程反例。pump相关P2已由父端限定关闭，本片仅保留共享formatter必要边界。

固定负向 **99186ec1a4e8f0a173c630fb5eddde41b4eff373** H **193/80**，实际exit1，SCRIPT ERROR/ERROR均0。六个reference终局均自然达到预期状态，80项失败是文案断言。修复source正式H **193/0**（UUID8d26f46a2b5f4792aceda06467239c84）与R **221/0**（UUID6a34b2d1b6e04735a13da43ae999d060），各actual exit0/E0/S0。两模式独立，不相加宣称测试量。

覆盖五份原native记录hash只读formatter；六关empty/unrelated/action/sparse-legacy/WON/FAILED/null-log边界，unknown/null level；原main统计、正文、失败卷宗一致且snapshot/fingerprint/clock不变。所有新的战斗使用明确授枪/cover snap/direct tick/vacuum reference，不能称正常旅程或自然触雷输入。3D depot无雷WON638、原后端雷trigger1/WON955、radio无雷WON843/FAILED902；旧2D仅depot无雷WON638及radioFAILED902有界结果。负向与固定终局相同。synthetic action_fixture不是实际事件验收，sparse-legacy不是重跑旧原件兼容QA；五份原bytes没有播放/重写。

R保存14张原始物理窗口PNG全部核hash，目检7张（准确列表在validation）：depot无雷/后端触雷、radioWON、旧2Ddepot，两模式原native按钮打开FAILED卷宗并真实滚到完整“电台尚未封锁”。8次XTest点击/滚轮均记录坐标、helper exit和目标path。失败入口初始/早滚动图有未完整露句的帧，保留；仅scroll2图作为看见完整句的证据。自用Xorg89786已SIGTERM/actual exit0，stdout/log无损gzip。无新导出/PCK或设备性能声明。

实际命令（完整source/env、UUID、outer exit/log在[36文件证据与validation](evidence/20261004-pr15-result-facts/validation.json)，[完整hash清单](evidence/20261004-pr15-result-facts/file-manifest.json)）：

```bash
AMBUSH_TEST_SOURCE_SHA=a7942a96415c844701cdaa1f2bd2654ef3a52b14 AMBUSH_NATIVE_RECORD_DIR=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime bash ambush_loop/scripts/run_isolated_test.sh /workspace/.ambush-loop-env/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 campaign_result_copy_test.gd --headless
DISPLAY=:112 AMBUSH_TEST_X11_DISPLAY=:112 LIBGL_ALWAYS_SOFTWARE=1 AMBUSH_TEST_SOURCE_SHA=a7942a96415c844701cdaa1f2bd2654ef3a52b14 AMBUSH_NATIVE_RECORD_DIR=/workspace/ambush-pr15/ambush_loop/build/asset_review/pr15-runtime bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-result-godot.sh campaign_result_copy_test.gd --render
```

首版56e7 H189/80内含三个弱布阵未到WON的测试问题，全部另存dev，不能把它的80称全生产缺陷；随后只改测试采用本关原匣枪械，9918正式负向不含终局失败。直接执行非executable的sh首次exit126属于引擎前启动错误，原日志/退出另存；实际运行均使用bash和隔离守卫，不掩盖开发失败。

**未验/下一步**：radio原3b49末波提示t1.4仍喊暗道2.2s的已复现错误待独立片；route timeline/level静态3.6s/5.2s教学与FAILED建议/intel delay读取总表是审查边界，未由本片修正或全验，R图保留原句。whole修复版装备/触控/旧2D、同候选fresh六关13波正常旅程＋新record3D、FX/艺术/A3/耳听/APK/device待。原正常流程green没有覆盖这两类展示断言，不能升级为全部HUD正常。R5资产29749157/ebedb829接口不变，无新增制作需求；可交独立副本fixed a794展示QA，不写main/共享测试。网页GPT PLAN/REVIEW unavailable。普通push授权PR15，不merge/生产/height/G。
