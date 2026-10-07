# PR15 原生回放箭头缺物理码修复

2026-10-04。原a05 PCK/新正常yard原件只读渲染whole4404/1actual1保留，唯一Right断言失败；加trace短诊断4140/2actual1明确两个原生XTest arrow pressed/echo=false，physical=0、logicalRight4194321/Left4194319、GUI focus=null，scrub2971两键都不变。加强Left必须先前Right-6与原seek，不再让两键均无动作的弱反向断言过绿。原a05 PCK/source、记录SHA、时钟、root/bones/fields未变。不是修正last-frame-wins的四个开发fixture错误；这是实际输入触发的生产边界失败，不把whole2x258callback/原4126终端子段称整绿，不重开其他父端已闭scope。

[Godot InputEventKey官方文档](https://docs.godotengine.org/en/stable/classes/class_inputeventkey.html)区分logical keycode/physical位置码且通常均设置；本次实际日志证明并非每个已观测箭头事件都有physical，原因是否来自本Xorg映射不作引擎或设备结论。生产改动仅REPLAY pressed/not echo block：physical优先；physical=0时只对已知Left/Right用logical，沿原set_tick±6与pause/clamp/UI刷新。其他phase/GUI-modal/其他快捷键优先级/未知key保持现有规则。没有回放写回/借live源、无版本/事件/模拟/资产变化。

先新增Guard共享replay_arrow_input_test读取固定a05yard raw，明确synthetic InputEventKey/原_unhandled_input seam、缺physical/physical优先/未知/echo/release/菜单拒绝/0与terminal边界/record-live-sim-raw不变，固定negative actualH→最小main修复→固定正式H。随后官方4.7.2单次新source PCK/hash，外部同固定harness/原始a05 raw实际XTest Right+6/Left逆6/实际1x2x/暂停菜单/focus/全record2x及原图，生产source与producer/a05来源分记。此fix使初始a05候选有已确认遗留输入失败，不能用新source绿补a05最终统一接受；六原件read-only新consumer和最终FX候选分别声明。

旧a05正常13/元数据只归a05；完整smoke原54/62和fixed8906有界合同actual0状态保持，最终FX source仍要完整smoke/normal13/六newrecord3D/A3/APK。R5/制作源/GLB/atlas/Blender/生产manifest保持、主集成main/sharedtests单写；Draft普通push、不merge/生产/height/G，耳听设备后置，网页GPT PLAN/REVIEW unavailable。
