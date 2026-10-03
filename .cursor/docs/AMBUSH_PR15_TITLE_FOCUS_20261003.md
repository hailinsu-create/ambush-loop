# PR15 title 自然键盘焦点与brief返回生命周期

固定测试源码 `4ba2bfd26a17ebbb1500f04c8fb267d852461f65`，生产title/pause/helper修复 `83067064d6add31bd4f15c2d9ea6da2237c4398b`，二者差异只有新title_focus_keyboard_test.gd的唯一截图路径与失败早停。六次作者正式命令全部实际结束，exit0、SCRIPT ERROR0、engine ERROR0。工程树 `41daf9c05162538d6d39e5a3d9dcbd66856d4314`；后续证据交付仅改文档。独立title/autoREPLAY QA仍待，作者通过不等于独立关闭。同步结果以实际push收据和GitHub只读HEAD核对为准。

父端d7b独立QA限定关闭Help/Quit原200尺寸P2；title整体仍两P2待。T1 exact fresh1600×720、scale2、logical640×360，原生Escape→Tab→Return→Tab×5→Return→Escape，Settings无focus、Tab到后台主menu、Return打开被遮Mission、Back关错层。父端24/7exit1；T2原native mouse Start→yard→Escape，12/0exit0但ERROR1；完整自然keyboard715/24exit1ERROR6。父端计数不与作者相加。

作者固定test-only129a170保留原226生产title源，actual negative34/4exit1/SCRIPTERROR0/engineERROR1，UUID7dd2e1f2a56a4292b5b0abe35475dab7，四图/log/exit留存。缺metadata引擎错误真实触发title.gd604。开发patch+新helper最小两路径36/0exit0/ERROR0，UUIDc791c150ee334e44ac15d49c76bc4e23，不当正式八组通过。

修复：共享focus helper遍历实际可见可focus的Control，跳过disabled Button，Tab/ShiftTab与方向neighbor限制在该层；Settings用原Close初始focus，scroll随focus，previous focus存weakref并安全恢复。Title Back按实际最高CanvasLayer关闭；后台新modal/Continue在已有top层时拒绝。每个title层previous_focus用has_meta安全读取和WeakRef，每次清理，失效/隐藏/缺引用恢复有效root-menu焦点；brief Esc仍回title，未改成missions。原文字/按钮信号/玩法保持。

正式scope为四surface profiles（1280/100 desktop、1280/200 touch、1600/100 touch、1600/200 desktop）×fresh/Continue两状态，共8组；不冒称旧8组所有physical×scale×touch全笛卡尔geometry矩阵重复。天然XTest Tab/ShiftTab/Return/Escape，主menu、Settings/mission/六brief/Help/Journal/Quit；mouse-yard-Escape每组再测缺previous_focus路径。Settings循环包括真实HSlider与所有enabled按钮，无硬编码Continue状态Tab数。Clear progress、depot win/全部unlock是guard隔离fixture，非玩家胜利路径。原生mouse/go信号沿用；Quit实际退出另跑原keyboard7专项。共享Pause改动需自动回放H/R与生命周期H/R相关回归。原formal29/title2391不重复。

过程边界：首轮830因新driver鼠标/键盘yard PNG同名而打算停止，但作者未验证进程退出，错误启动同112第二native任务；两轮实际均已终止exit143，7脚本error及所有该段nativefail不可用于production判断/正式验收。只有混合部分triage图留存，两张被覆盖旧版本不称保留；旧minimal JSON没有复用。新4ba仅修test命名/早停，已清场确认同屏唯一native后重跑。830两批各H29/Hlife30单列。首次outside-project check-only未设XDG导致4条默认目录ERROR，实际exit0但非正式；改专用临时XDG后parse0/ERROR0，无清档运行。均在证据中明确，不掩盖失败。

| fixed4ba作者正式运行 | checks/failures | 隔离UUID |
| --- | --- | --- |
| title_focus_keyboard_test.gd --render | 4476/0 | e5e3777eea77480da3916c431419a024 |
| title_menu_viewport_test.gd --render，原keyboard实际Quit | 7/0 | 330ce29c4ae54e3aae8e908184bdab5a |
| replay_autoplay_test.gd --headless | 29/0 | 9baf0e228f244f1282a71e72c9d967a6 |
| replay_autoplay_test.gd --render | 167/0 | c005122c15f84e8b9c9dfae8a3d45c71 |
| presentation_lifecycle_test.gd --headless | 30/0 | 9dfb3f8379184505b7e2b760b20211ea |
| presentation_lifecycle_test.gd --render | 32/0 | 76a27b63c5494d83bb5903d978209d7c |

实际命令均为 `bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-full-godot <entry> <mode>`；六次都设置原真实schema1 fixture的 `AMBUSH_LEGACY_RECORD_FIXTURE`，Quit另设 `AMBUSH_TITLE_EXIT_ONLY=keyboard`。完整逐条命令、固定源码、UUID、log与实际exit见 [validation.json](evidence/20261003-pr15-title-focus/formal-4ba2bfd/validation.json)。Godot固定4.7.2、独立Xorg112/evdev/us/llvmpipe，native同屏串行；包装器/XKB/配置留存在autoREPLAY的environment证据。软件render等待预算不当设备FPS门槛。全部六次结束后确认无该worktree Godot残留。

83张最终PNG逐一核对hash：title76、autoREPLAY6 native Window crop与生命周期1 root Viewport。76 title为唯一命名；两类来源分开，82 native +1 root，不把root图说成真实窗口。1392条title原生输入、原Quit4条、autoREPLAY32条，helper全部exit0；输入数量不当独立用例数。作者实际视觉查看15张，清单见validation；设置初始Close焦点、200%滚动控件、回主菜单/六关radio简报返回，以及2×播放/末端与事件定位图已看，不冒称全83张目检。全部留存含负向、开发patch、parse失败和无效并发轮次的 [file-manifest.json](evidence/20261003-pr15-title-focus/file-manifest.json) 可逐一核对。

AutoREPLAY回归沿用原yard两波1056/227、终局1283/34事件与现代历史末端1430，真实schema1字节/旧端点1415保持。fixed4ba的main/BattleLog/ReplayPlayer/presenter/ViewState与fixed770相同；没有重跑原正式29项或旧title2391，历史证据仍限定各自固定源码。

下一步由父端安排固定4ba的独立title焦点/生命周期和autoREPLAY QA。本checkpoint不展开FX/A3。自然OS app切换/设备键盘、全部正常玩家旅程、真实schema1原生自动播放、完整3DFX/耳听/A3/最终smoke/APK仍未验；设备/模拟器在全计划完成后。资产接口继续固定R5源 `29749157c5db064bfea626c3ed9d75d9a1791ece` / 交付 `ebedb829e3263abbeb6dd266905f24a3869fa281`，20骨/socket/3LOD/52语义不变；GLB/atlas/制作源/Blender/生产manifest全部未改/未重跑。主集成继续独占runtime/presenter/replay/HUD/loader/共享测试，资产制作归独立作者，未整体合并WIP。高度/G、merge/生产仍排除，网页GPT PLAN/REVIEW unavailable。
