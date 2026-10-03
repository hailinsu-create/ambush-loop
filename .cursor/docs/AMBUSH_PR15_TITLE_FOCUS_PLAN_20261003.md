# PR15 title 焦点与子层生命周期补片

2026-10-03。父端在autoREPLAY执行中报告d7b独立QA；本片排在autoREPLAY固定源码验证与推送之后，FX/A3后置。title整体仍未关闭，原200% Help/Quit尺寸P2按限定范围关闭。此前作者2391/0与quit7/0不覆盖此次自然键盘缺口。

父端实测T1：fresh隔离档Continue禁用，physical1600×720/content scale2/logical640×360，intro后原生Escape→Tab→Return→Tab×5→Return→Escape。Quit初始Cancel焦点，Tab进入settings并Return后Quit隐藏、PauseOverlay开启但focus=null；五个Tab落后台Start/Archive/Help/Quit/Start，Return造成settings与mission同时可见，Escape关闭后台mission。UUID fd518b788f68429c842088e5743b40e4，24/7、实际exit1。该计数为父端独立证据，不混入作者验证。

父端实测T2：最短原生mouse Start→yard→Escape，回标题但ERROR1。mission先hide，其焦点不可见，因此brief未写previous_focus；dismiss使用get_meta(previous_focus,null)，Godot4.7.2缺metadata仍报error。UUID b30042e90c394a2cbce05d86dfacf750，12/0、exit0、ERROR1；不能视为green。完整自然keyboard独立715/24、exit1、ERROR6。

契约：settings打开后有有效初始焦点；所有可见启用Button/HSlider均在该层内循环Tab/反向Tab，滚动跟随焦点；Return只能激活最上层；Back先关闭最高层。fresh/Continue可用都不能依赖固定Tab次数。每个title子层的previous focus存取安全且有效，重复打开/关闭、已隐藏/无焦点/已失效引用使用有效fallback；brief Escape仍回title，不改成mission列表。

先保存test-only自然输入负向、实际exit与ERROR数，再修title.gd/必要共享PauseOverlay焦点边界。覆盖mission→六简报、Help、Journal、Quit→Settings，天然Tab/Return/Escape与鼠标打开简报后Esc；原按钮和路由、SCOUT→ALERT→SWEEP与资产保持。新的固定SHA正式复验，截图hash和实际关键帧检查；共享设置改动需跑相关生命周期/autoREPLAY菜单回归。原formal29不重复，旧title尺寸matrix按必要范围复验，不用程序调用替代naturalkeyboard。

父端独立QA与作者计数分别列示；本片完成前不能宣称title整体关闭。生产源/GLB/atlas/manifest、模拟数值、高度PR不变。网页GPT PLAN/REVIEW unavailable。

作者实施：固定test-only129a170原title源负向34/4、actualexit1/SCRIPTERROR0/引擎ERROR1，UUID7dd2e1f2a56a4292b5b0abe35475dab7，实际四图和log留存。开发最小两路径36/0、exit0/ERROR0，UUIDc791c150ee334e44ac15d49c76bc4e23，不代正式八组自然键盘。修复为共享modal focus遍历实际可见启用Button/HSlider，tab/反向tab/方向neighbor环及滚动跟焦点，settings初始Close焦点与弱引用恢复；title按CanvasLayer最高层Back且拒绝后台重开，previous_focus has_meta+WeakRef、每次安全清理fallback，brief Esc原回title。全覆盖计划为四个真实physical/scale/touch组合×fresh/Continue两状态，共8组，主菜单/Settings/mission/六brief/Help/Journal/Quit天然Tab/ShiftTab/Return/Escape；Unlock/clear progress是隔离guard内fixture，不称玩家获胜。共享Pause变更复验auto H/R、生命周期H/R与原native Quit键盘实际退出。原formal29/旧title2391不重复。
