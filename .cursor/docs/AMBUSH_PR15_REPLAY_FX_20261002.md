# PR15 回放实时色罩清理

2026-10-02，六关实际环境画面评审中发现历史视图带有活体胜负/警报色罩。独立小片修复该视觉污染；不将它当作环境资源或设备性能问题。

环境运行固定源ffb95a670b4b58cbe420571bd9f884fed3a1a41b的生产代码，复制新测试/隔离入口后：六关真实记录＋原alarm/result/signature/static生成器的显式视觉事件fixture，36项18fail、实际退出1。每关进入历史、下一帧及迟到seek仍被实时色罩污染。该fixture不声明真实FAILED/abort终局旅程已测。

修复在进入REPLAY时复用表现FX清理，并补齐失败static的Tween/可见性/alpha清理，避免旧Tween下一帧重新涂色。只影响展示，不改变模拟、事件、波次、存档或装备。保存反例与固定源正式结果后再报告完成；完整3D事件FX及历史FX仍为后续。

固定源码 **2ce6c602e31fb29556c85961704778185ca5a776**：`replay_fx_lifecycle_test.gd --render`36/0，六关进入回放/下一帧/迟到seek色罩透明，原record/events保持。源ffb反例与正例都是同一36项脚本，实际退出1→0。`visual_snapshot_test.gd --render`164/0、`presentation_lifecycle_test.gd --render`32/0；六张清理后的真实历史framebuffer接触表已看，原有HUD挤占依然存在。命令/run_id/退出码/哈希和图在 [独立证据](evidence/20261002-pr15-replay-fx/validation.json)。此片没有将实时视觉事件改成版本化历史FX，完整3D事件FX/真实FAILED和abort终局仍待最终回归。
