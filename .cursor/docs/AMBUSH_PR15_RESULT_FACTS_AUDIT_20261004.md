# PR15 六关结果高光事实依据审查

基线de59987568ffe0fb263c1db5077b807de7a0db4f，运行代码/正常后三关固定3b4976d1f4348d828a95bb627b2fb57c8501934d。仅结果统计、WON正文、FAILED卷宗；原教学hook/简报/实时事件摘要/战斗规则保留。当前波倒计时另片。

| 关卡 | 静态教学hook/原判定 | 已有证据与限制 |
| --- | --- | --- |
| yard | “交叉封锁第一枪”；hook_hit只要求任意fire | 没绑定交叉站位/多角色。此为源码审计，尚未将该句单列为正常旅程复现缺陷；空/单角色事件反例只作明确formatter fixture。 |
| warehouse | “入伏再打，弹包续上”；只要求ambush_armed或repack任一个 | b27正常原记录包未used/repack0，仍静态宣称“弹包续上”；F武装许可不等于实际耗尽补弹。既有正常记录可只读作为实际反例，不重跑warehouse。 |
| pump | “锁门后紫线改道被你罩住”；旧route_choice存在曾被当成功 | 生产7a3/fixed b892两处已中性化，父端相关P2限定关闭，030旧失败保留。本片保持原“泵站封锁完成/尚未封锁”，只验证共享formatter必要边界，不重开整片QA。 |
| railcut | “3.8s东廊迟到，铁砧等住”；_delayed_flank_shot只看任意fire.local tick≥228 | 没检查角色/目标路线/原spawn身份。源码不足以证明整句；当前正常3b49不在此冒认新实际文案缺陷，补晚发生的主路灰狼fire反例只作明确fixture。 |
| depot | “2.2s西暗道绊索抽中”；hook_hit只看trip，WON fallback仍显示整句 | 实际3b49正常205/0原mine/trip0，WON统计/正文却称抽中，原截图/record已封存；原SCOUT铺雷不等于trigger。 |
| radio | “5.2s灯塔回波，绊索抽中”；trip AND任意晚fire，WON fallback仍显示整句 | 实际3b49正常210/0 mine/trip0，末波echo在tick30入场、三fire角色1、MG未开火，2.15s清场；原两处假高光已复现。 |

共同原因：main统计除pump无条件读静态highlight_hook；Payoff无命中时WON仍把教学hook写成“本关高光”，部分命中判定也不能证明原整句。采用统一六关**真实中性封锁结果**（已封锁/尚未封锁），main两处使用同一formatter；事件事实继续由原terminal_summary/summary_lines/first_fire分别显示，不重写事件或把教学目标当完成。未知level采用中性通用描述、null level保留空；旧字段缺失/无log不编动作，不升级记录。

先commit新guard negative测试：只读五份原native record逐hash核验、六关empty/partial/action与WON/FAILED/legacy formatter反例、原domain depot/radio无触雷/实际后端触雷对照、原两处UI/FAILED卷宗与旧2D有界结果，state/log/clock不变。人工event/授枪/cover snap/direct tick/vacuum明确reference，不能替代自然触雷或正常新回放。失败先封存实际exit与E/S，再最小修复并固定H/R验证；失败句若未真正滚到图不称可见。旧2D结果片不代全旧2D装备/触控回归。普通push固定切片供并行QA，R5制作所有权及未验FX/A3/艺术/耳听/同candidate smoke/APK/device保持。
