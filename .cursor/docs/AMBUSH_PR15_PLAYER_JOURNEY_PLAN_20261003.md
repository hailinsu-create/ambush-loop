# PR15 正常玩家旅程与首个阻碍

接续父端要求：保持唯一主集成作者，先补六关13波正常玩家旅程，结合FX/A3待办识别实际运行缺口并修复首个阻碍；独立QA若返回当前源可复现缺陷优先处理。起点为已推送a5ba7c7，title/auto独立QA仍待。

继承资产执行v2；详单与inventory从PR14固定d69251be42d5f96c99da48a24a3923b62863f28f只读核对。已有fixed15c六关39reference波/mode和formal29，不无理由重跑。其raid_prepare_ref授予枪/雷/矿并部署，raid_vacuum_loot消费掉落；它们属于模拟fixture，不是正常搜刮、补给及进度旅程。此前title验证mark_tutorial_seen跳过首次教学，不能证明新档首局可进入。

首个源码疑点：TutorialOverlay固定600×410、正文minimum500×128，200%真实可用viewport640×360，下一步/开始布置可能离屏。先从隔离fresh title通过原Start→yard brief→出击进行原生XTest复现，保留原source、命令、退出、界面和输入证据；不能只凭读码判缺陷。若证实，以教学层响应式布局/正文滚动/自然焦点做独立修复，保留全部文案、页数、第一页不能点击dimmer跳过和原教学seen写入契约。

后续正常战役必须走原输入路径：开局插入点与刀；实际走路/开匣0.4秒、背包/补给/射界/绊索，真实引擎_process与原SimClock；SWEEP实际移动拾取，再原下一波/撤离/下一关CTA和最后credits。不得直接给武器、改actor位置/HP/ammo、强制胜负、调用reference/vacuum辅助或record_win解锁。原作者reference部署点可作玩家策略提示，输入通过原pointer/key，不把策略来自read-only源码叫陌生人首局。程序生成XTest为云端native输入，不称人类试玩/手机触控；若使用Input.parse或关卡装载fixture，分别明示。

每个bounded checkpoint固定源提交，再运行新增云端行为/视觉；保存完整命令、隔离UUID、actual exit、SCRIPT/engine ERROR、窗口尺寸、记录identity、截图hash与实际看过的图。只报告实际到达关卡/波/终局，新档首次教学与其他关教学的装载fixture不得冒称完成完整六关13波。失败不以已过样本覆盖。

FX/A3待办核对：原FX生命周期30/36只检清实时2D色罩/旧Tween，非完整版本化3D枪口/烟/弹道/命中/爆炸/扬尘；目前presenter源码只有角色姿态、物件和事件定位环，3D事件效果还须实际战斗确认。历史云软件draw172–424、primitives53826–168748及radio部件55/42是A3输入，未测当前source预算、纹理驻留/加载/内存或手机FPS。完整耳听0/45 cue、0/6声景仍待，不改为已完成。

所有权保持：主集成runtime/main/presenter/ViewState/replay/loader/HUD/共享测试；R5源29749157/交付ebedb829的20骨/socket/3LOD/52语义不变。ArtSource/v2/build_yard_kit.py、角色制作、GLB/atlas/Blender与生产manifest不编辑不重跑。无merge/生产、高度/G混入；设备在全计划后。GPT PLAN/REVIEW unavailable。
