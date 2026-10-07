# PR15 正常玩家旅程与首个阻碍

接续父端要求：保持唯一主集成作者，先补六关13波正常玩家旅程，结合FX/A3待办识别实际运行缺口并修复首个阻碍；独立QA若返回当前源可复现缺陷优先处理。起点为已推送a5ba7c7，title/auto独立QA仍待。

继承资产执行v2；详单与inventory从PR14固定d69251be42d5f96c99da48a24a3923b62863f28f只读核对。已有fixed15c六关39reference波/mode和formal29，不无理由重跑。其raid_prepare_ref授予枪/雷/矿并部署，raid_vacuum_loot消费掉落；它们属于模拟fixture，不是正常搜刮、补给及进度旅程。此前title验证mark_tutorial_seen跳过首次教学，不能证明新档首局可进入。

首个源码疑点：TutorialOverlay固定600×410、正文minimum500×128，200%真实可用viewport640×360，下一步/开始布置可能离屏。先从隔离fresh title通过原Start→yard brief→出击进行原生XTest复现，保留原source、命令、退出、界面和输入证据；不能只凭读码判缺陷。若证实，以教学层响应式布局/正文滚动/自然焦点做独立修复，保留全部文案、页数、第一页不能点击dimmer跳过和原教学seen写入契约。

后续正常战役必须走原输入路径：开局插入点与刀；实际走路/开匣0.4秒、背包/补给/射界/绊索，真实引擎_process与原SimClock；SWEEP实际移动拾取，再原下一波/撤离/下一关CTA和最后credits。不得直接给武器、改actor位置/HP/ammo、强制胜负、调用reference/vacuum辅助或record_win解锁。原作者reference部署点可作玩家策略提示，输入通过原pointer/key，不把策略来自read-only源码叫陌生人首局。程序生成XTest为云端native输入，不称人类试玩/手机触控；若使用Input.parse或关卡装载fixture，分别明示。

每个bounded checkpoint固定源提交，再运行新增云端行为/视觉；保存完整命令、隔离UUID、actual exit、SCRIPT/engine ERROR、窗口尺寸、记录identity、截图hash与实际看过的图。只报告实际到达关卡/波/终局，新档首次教学与其他关教学的装载fixture不得冒称完成完整六关13波。失败不以已过样本覆盖。

FX/A3待办核对：原FX生命周期30/36只检清实时2D色罩/旧Tween，非完整版本化3D枪口/烟/弹道/命中/爆炸/扬尘；目前presenter源码只有角色姿态、物件和事件定位环，3D事件效果还须实际战斗确认。历史云软件draw172–424、primitives53826–168748及radio部件55/42是A3输入，未测当前source预算、纹理驻留/加载/内存或手机FPS。完整耳听0/45 cue、0/6声景仍待，不改为已完成。

所有权保持：主集成runtime/main/presenter/ViewState/replay/loader/HUD/共享测试；R5源29749157/交付ebedb829的20骨/socket/3LOD/52语义不变。ArtSource/v2/build_yard_kit.py、角色制作、GLB/atlas/Blender与生产manifest不编辑不重跑。无merge/生产、高度/G混入；设备在全计划后。GPT PLAN/REVIEW unavailable。

首次疑点实际未复现：固定test-only c7d01111b24392217cc1e3c5e043dfb72195a5a1，fresh title1600×720/200%→原Main→院子三教学页32/0、actual exit0/ERROR0，6次XTest、3物理PNG、实际看page0。下一步/开始布置均可达，不为源码假设改教学布局。根屏幕额外采样发生在进程退出后是黑图，不当证据。原Main开发入口没有a0_preview时保留2D；之前3D测试直接加载yard_3d。因此后续另建固定源码的隔离PCK，只加已有custom_features=a0_preview，保留原title/main/进度流程，验证自然创建3D presenter，不改原配置/资产输出。

新native旅程driver先限yard，原数字键选人、点击真实匣并等真实引擎走路/开匣、原cover点击与15°朝向、真实警报/暂停/清波/撤离/下一关。策略引用原reference站位但不调用reference授枪或vacuum；全部行为记录实际状态，不能硬套其terminal/event计数。确认yard实际通过后再续其余五关；失败先复现修第一个实际阻碍，当前不能称六关13波已过。

当前正常旅程保全并暂缓：528测试包自然取得kar98k/MG42/kar98k_zf及手雷，但75/1、exit1、engineERROR8；测试lambda直接捕获已释放stash的错误单列，不当生产缺陷证据。原拾取器命中cover5而站在相邻1格的队员未部署，疑似old32px body选择优先于明确3D cover；需修测试后重新独立确认。117只有typed weakref parser失败、exit1/SCRIPT1/ERROR1，旧528 report没有复用。包导入/导出0并不证明其未使用测试脚本可解析。WeakRef已改显式类型。父端新报“历史事件文本读取live log”P2，按要求优先复现修复；此前title两P2父端固定4ba独立限定关闭，独立计数不与作者相加。正常六关13波尚未完成，未新增设备/耳听/FX/A3通过。

2026-10-04正常旅程检查点：fixed361干净77/1、exit1/ERROR0确认cover5明确picker命中仍被旧32px body选择覆盖；124修仅3D显式cover路由。正式d7通过原新档title/教学/实际四匣搜刮/三cover/原ALERT两波450/225/SWEEP撤离/WON675/27/下一夜CTA/warehouse三教学页，135/0、exit0/ERROR0；专项H25/合成输入render38亦exit0/ERROR0。32 XTest、14 native Window图核hash/看6；完整scope见[cover报告](AMBUSH_PR15_COVER_INPUT_20261003.md)。124开发113/1是漏点原handoff CTA，非产品新P2；dev整轮不列正式。原文字P2父端fixed ddec独立限定关闭，计数另列不重跑。后续继续余五关11波、SWEEP实际搜刮/补給、depot/radio工具和走近埋雷；当前无环境阻塞，不称六关13波/FX/A3/艺术/耳听/设备/APK完成。
