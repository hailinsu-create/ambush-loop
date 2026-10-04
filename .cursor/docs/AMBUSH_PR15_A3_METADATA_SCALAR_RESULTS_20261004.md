# PR15 窄元数据查询：固定候选与配对实测

2026-10-04。本片功能门通过，**未证实稳定性能收益，A3预算仍未通过**。八轮正式 ABBA/BAAB 已在 **20:54:51 UTC START / 21:04:27 UTC 自然 END**；全部实际退出0、anchored ERROR0/SCRIPT ERROR0，逐轮与跨轮 strict 离线检查均 actual0。1278原始行、672有效行，正式16原PNG全部核SHA并逐张查看。所有Godot句柄已收取实际退出；自有Xorg126/PID123583核uid/精确argv后关闭actual0，常驻99/PID1764未动。性能窗口已释放。

依父端最新限定，本turn止于此固定候选/量测端点，封存并交独立QA；不叠加另一优化、不启动FINAL/APK。旧六关A3正式结果23559/0及失败轮完整保留，不能用本次yard有界比较替代六关集成或设备验收。网页GPT PLAN/REVIEW unavailable。

## 固定来源与生产范围

| 角色 | 固定commit / game tree |
| --- | --- |
| baseline A | `41ff06cf8d01ce01b0d6ca1e33247daac9210bc1` / `ec73ed78833b5608919ae98e39ba7a58c4e03f41` |
| 窄生产实现 | `cd352bfb3ad1f7b7c7863a115c5dec29fc02042a` |
| 实际功能/比较consumer B | `a42ea2d7b50e79ee4a954ec9859a7281c577c174` / `ff0de72e42f636e201983cf47aa24aa142a652bd` |
| 输入record producer / 已封交付 | `a90eb0798914c023f5c8902303c72f2619abd7c2` / `41ff06cf8d01ce01b0d6ca1e33247daac9210bc1` |

生产仅两处文件：asset_library新增返回bool的`is_character_asset`；`model_path`在原revision拒绝门后直接只读已验证内部catalog。presenter替换原public deepcopy类别查询，保持animation_supported→has_asset→category的短路次序。公开`asset_record`继续递归复制；无内部可变容器返回、额外cache或新失效路径。原revision/legacy/LOD/material/socket/释放、ActorVisual、pose/ViewState/FX/record/sim均保持。cd352与a42两个生产blob逐字节同：asset_library SHA256 `6e307f84b2d9fa07ef0d7d92827e09017d95085f43683178b4d7518e2741381f`，presenter `0372d5d0db691600e6c3758212b29e54cab9e9eb57c8eb14bacf09e2335ac925`。a42仅修新增测试的显式bool类型。

## 六个分别运行的功能门

实际命令入口为`bash /tmp/pr15-metadata-scalar/run-entry.sh <entry> <mode> <label>`，内部原`run_isolated_test.sh` Guard与独立UUID数据目录。官方Godot4.7.2 SHA256 `8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e`。渲染轮`DISPLAY=:126 LIBGL_ALWAYS_SOFTWARE=1 AMBUSH_METADATA_ENGINE=/tmp/pr15-metadata-scalar/godot-dummy`；shim只给同官方engine显式`--audio-driver Dummy`，未改Guard仓库脚本。

| entry / mode | 实际label / UUID | checks/failures | actual / E / S |
| --- | --- | --- | --- |
| asset_library_test.gd / --headless | asset-library-H-fix1 / 5e05c873b13e43a38e9912c62fde1ad1 | 4069/0 | 0/0/0 |
| actor_visual_test.gd / --headless | actor-visual-H-a42 / 6af08a5de1d34485a546902e0215bc09 | 21818/0 | 0/0/0 |
| environment_assets_test.gd / --headless | environment-assets-H-a42 / 451ee3b285074aff8222c9118dee0865 | 610/0 | 0/0/0 |
| firearm_runtime_test.gd / --render | firearm-runtime-R-dummy-a42 / 898303836dfa4172aafd9f37925feffc | 7681/0、90configs | 0/0/0 |
| actor_battle_test.gd / --render | actor-battle-R-a42 / f99903c1b0544047982a943000cb1279 | 233/0 | 0/0/0 |
| presentation_lifecycle_test.gd / --render | presentation-lifecycle-R-a42 / 6dfdf7c01490479e9ec06baa2a4e1aa6 | 32/0 | 0/0/0 |

扩展asset门从原manifest建立独立oracle：71 accepted IDs、当前和兼容revision、实际R3 legacy原path/GLB SHA、unknown/negative/count/999LOD/crossrevision/category、公开nestedLOD/socket/clip修改隔离及release/reload。既有资源门另验实际20骨骼/3LOD/socket、环境40项/80LOD、武器接触/保存pose/旧资源/unsupported fallback、Back先关背包/触控cancel/事件聚焦等已有生命周期行为。13个唯一正向PNG全核并查看；actor_battle实际10capture调用产生8个最终唯一文件（原测试两次同名覆盖），不虚称10原图。这些含API/手动clock/历史fixtures；不代fresh native normal13、全十枪每动作每LOD艺术、fullsmoke或性能结果。详细实际argv、环境、source与原日志在[功能包](evidence/20261004-pr15-metadata-scalar/functional-a42/commands-and-results.json)。

## 比较契约与预检

两独立clean tracked game tree工作树`/workspace/pr15-metadata-baseline-41ff`、`/workspace/pr15-metadata-candidate-a42`，复制既有warm缓存和原`.import` sidecars，不生成资产/不跑editor import。各988 tracked source、986同字节warm imported文件与官方engine before/after验证；另493个ignored/tracked loader sidecars的相对path/bytes/SHA清单before/after一致，清单SHA256 `513aba6cd0bd41c141fd5c53603fd0d541ea63bf4032634848c21d3b867f552d`。初次漏掉ignored sidecars的失败保留，说明仅warm二进制清单不能证明新stage的loader元数据齐全。baseline proof SHA256 `afe135c7e0ea78addfa710d71395e1fc17aaab6a795e659a0b322a7572ba32bb`，candidate `7ec4126e7963218ac62e27de333d9ec35c756cf66d4e2152df50eb2c6f95441d`。

相同外置fixture`metadata_pair_external.gd` SHA256 `2bb636085075ae34e4d40a2caf4417ee23d61bc3f2ae46175ab65e0199e56b52`，只通过shim替换原Guard allowlisted A3 test entry，完整保留原collector59列/回调/计时/首次转换帧排除/溢出拒绝。原record5589224bytes SHA256 `426cf659c9fd10a47e53cd6ef28363e9e38ced0a6cb30c65cc844885104c4598`，attempt`ebb3b40c430e9939e054455f03a54e6f`、PBtick253/frame43/wave0/recordedALERT1/localtick204、实际saved shot2。冷terminal明确fixture进入原REPLAY，main与presenter原自动回调开启、tree未pause；不接受新胜利或progress。

跨进程画面含三个opaque source-instance cache token，不能拿正式A3进程raw frame SHA直接对新进程断言。新fixture在引擎内要求三个原值均TYPE_INT、非零且等于bound BattleLog实例；规范化只在deep comparison副本把这三项置0。原payload不改，并保存raw frame、canonical frame、实际rig签名bin；进程内原raw frame/实例保持及恢复仍严格检查。规范化画面SHA256 `c4cbba4f6fe5621f36af4b67930363daf38ab7654937b6a20ec77eb801ef4d05`、实际20骨/挂点/装备/资源路径/姿态签名 `0937d3202f1796dfc57bfda88e18af4852d2540aa0f0a3a49b5c79217e07a663`，共同cold backend `289c587be0ff1b767df035d75d35e972d69fec5905d75ee006273b4d0f62d340`；两预检与正式八轮严格相同。原正式raw hash只作进程相关参考标签，未声称其跨进程字节同。

共同配置1280×720、scale1、standard、maxfps0、实际vsync0、yaw0/pitch35/extent12/focus`(-6.5,0,-.155217)`。focus显式同值但来自原JSON显示精度，不声称复原正式进程未舍入float bits。静态：固定253、5墙秒warmup、至少5墙秒与60有效phase4行，30墙秒上限；原body/item实例及骨骼/socket/后台/source/frame保持。推进：同起点253、5秒paused warmup、原`play(false)`/1x自然回调、至少5墙秒与24有效phase4行、30秒上限；后台/source不变，结束pause并恢复253原raw frame和rig。实际终点452或453，尚未1397；主机delta/采样轨迹不同，非逐帧exact配对、非whole replay。

冻结common4预检 A UUIDfcbefa0d14f149528e9bc557444ad805 **457/0**、B UUID0dd787ae8aaf48b593f9b41d55c62d2c **459/0**，各actual0 E0/S0；共同strict0、324raw/168accepted、4PNG全核/查看。更早common3 baseline423/0另封，所有预检与正式数据分开。

## 正式八轮与原始分布

实际入口`bash /tmp/pr15-metadata-scalar/run-formal-pair.sh`；按A B B A B A A B串行调用`run-pair-entry.sh <A|B> <unique-label>`，每轮自然退出和strict检查后才启动下一轮。START/END、original actual exit、fixture/shim/runner/analysis源码与完整控制checksum均保留。最终`analyze_metadata_pair.py --formal`消费同八轮raw actual0；仅路径重定位的`analyze_sealed_metadata_pair.py`对封存副本再actual0，输出JSON与原分析**逐字节同**。独立反例检查拒绝两预检冒充完整八轮和原common2失败轮，各离线actual1、无acceptedJSON。

| label | 版 | 原UUID | checks/failures | raw/accepted | 静态/推进墙秒 | 推进end tick |
| --- | --- | --- | --- | --- | --- | --- |
| formal-01-A-common4 | A | 29ed04bd70b442e38bcb4a422432f03f | 456/0 | 160/84 | 8.503/18.665 | 453 |
| formal-02-B-common4 | B | 0e196ffcbd614c4c80d77255ad84240b | 456/0 | 160/84 | 8.672/18.698 | 452 |
| formal-03-B-common4 | B | acfc3f2c3c124e868a7a4cb8595d6f15 | 456/0 | 160/84 | 8.460/18.996 | 452 |
| formal-04-A-common4 | A | 9d5c41a5f6864f52842cff2cd086cb8a | 456/0 | 160/84 | 8.460/18.279 | 453 |
| formal-05-B-common4 | B | 4065b623d34047159701df458dedaa8d | 458/0 | 162/84 | 8.587/18.675 | 452 |
| formal-06-A-common4 | A | 1e3e8d928f0c420d943679d6d56ded80 | 455/0 | 159/84 | 8.860/19.334 | 453 |
| formal-07-A-common4 | A | 5a136c1eb3c54ec5a318658e41ffe62d | 455/0 | 159/84 | 8.657/19.426 | 452 |
| formal-08-B-common4 | B | 65e62f18d1094ac08318098892199789 | 454/0 | 158/84 | 9.272/18.937 | 453 |

| 窗口/版 | 有效行 | interval中位/p95/p99/max（ms） | >33.333 / >16.667ms |
| --- | --- | --- | --- |
| static A | 240 | 139.493 / 154.427 / 170.774 / 199.475 | 100% / 100% |
| static B | 240 | 139.950 / 164.791 / 198.741 / 239.921 | 100% / 100% |
| advancing A | 96 | 729.650 / 833.696 / 893.837 / 947.028 | 100% / 100% |
| advancing B | 96 | 722.412 / 798.622 / 907.439 / 909.598 | 100% / 100% |

相邻A/B配对中位变化B/A−1：静态`+0.893%、−0.022%、−0.887%、+4.642%`；推进`+0.090%、+2.775%、−3.895%、−3.165%`。汇总静态约+0.328%、推进约−0.992%，但方向不稳定且不是因果估计。版内max/min单轮中位漂移：static A3.10%/B6.12%，advancing A6.72%/B1.47%；last/first变化分别A0.33%/B4.06%、A4.88%/B1.47%。四pair及有限独立run的尾部分布仅描述性，不报告统计显著性、零开销或提升手机FPS。

collector写入计时中位static A235.5/B235.0µs，advancing A241.0/B249.5µs；计时终点之后final timestamp store/return仍不包含。TIME_PROCESS等monitor更新可能滞后，static process median A146.593/B150.159ms，advancing A722.817/B715.291ms，不能从wall减它或collector推出独立CPU/GPU成本。Linux13/EPYC7763、可见5CPU/cpuset0–4/quota4CPU、非exclusivehost证明；Mesa25.0.7 llvmpipe LLVM19.1.7/Compatibility/X11/Dummy，GPUtime不可得、pipeline支持unknown。预算未降低、collector未删除、玩法未改。

static对象5437/node1366/resource473/draw342两版相同，shot2/tool1/dust0；advancing对象max5459/node1383/resource476、draw329..345、shot0..2/tool0..1/dust0..1两版范围同，orphan0。static MEMORY_STATIC A305868190/B305869763bytes，不把这1573bytes差归因收益。八轮RSS ready266.6..267.1MB，static mark914.9..921.6MB，advance mark923.97..935.42MB，save957.6..969.9MB；包含collector15.47MB、解析原archive/序列化断言临时分配、缓存与驱动allocator驻留，不相减成游戏内存、未证长时泄漏或稳态移动端占用。

## 失败、图与封存

| 原尝试 | 实际结果与范围 |
| --- | --- |
| cd352新增asset测试parse | UUID003c759a0a6c4900a4548dc235fc6ad9 actual1 E1/S1；无checks/场景/资源执行。先封原source/log再test-only显式bool，生产未改。 |
| a42 firearm错headless模式 | UUID958cfda550374004abc9aa63e2d88c2b actual2 E1/S0，entry明确需renderer；无checks。 |
| a42 firearm首render音频初始化 | UUID054036c21fc245ea8aaef26f0bb398f9 7681/0 actual0但E1/S0；原三PNG保留/查看，不计E0门。之后显式Dummy另fresh成功。 |
| baseline common1 stage不完整 | UUIDab97661d0e2e4984a449b08a1deaa18a 438/8 actual1 E11879/S32，ignored PNG/GLB.import遗漏；原log/report/CSV/一张缺模型图先封。无有效性能接受或生产回归推断。 |
| baseline common2 raw frame断言错误 | UUIDbe6330ed7d454a77bbd15daf2d3a5da3 69/2 actual1 E0/S0，跨进程raw hash含instance token，timedwindows0；保留后只修比较证据。 |
| 离线检查器开发错误 | 两个actual1副本误要求signed RefCounted ID为正；改为整数/非零/绑定且在signed64范围。先前JSON小数归因不准确，实为合法非零负整数。原件完整保留，不计生产负例。 |

source-only review曾在任何engine之前发现`play(true)`会重置tick0，已修`play(false)`；未称实际复现。原失败不取消、不拆段拼绿。完整新切片39物理PNG：functional13/formal16/preflight6/invalid4，全部SHA核验并逐张看，[图账本](evidence/20261004-pr15-metadata-scalar/image-ledger.json)。static相同实际火线/枪口flare/演员/yard/HUD，advancing原死亡姿态及后续clock另列；固定近景裁切/flare表现不构成全艺术验收。common1图实际缺GLB/environment，明确invalid。

[完整清单](evidence/20261004-pr15-metadata-scalar/complete-evidence-manifest.json) **412listedfiles/54980644bytes**，manifest SHA256 `a236350b97408fae09c3125643bb5a4e8f4bfb46d37e697d04e3e0e6b792c4d5`。功能包61、冻结预检53、正式197、offline negatives13；其他原失败与common3各自独立manifest保持。正式manifest SHA256 `f0352aa385dbc6ef03615a7f36f37dafec3fb3361d17b4d37c55d3175036016e`。[正式封存strict JSON](evidence/20261004-pr15-metadata-scalar/formal-41ff-a42-pair/sealed-strict.json)、[实际退出/命令](evidence/20261004-pr15-metadata-scalar/formal-41ff-a42-pair/sealed-strict-command.json)、[自有显示关闭](evidence/20261004-pr15-metadata-scalar/formal-41ff-a42-pair/owned-display-closure.json)。所有内容均在证据封存前完成实际读取；未提交Godot缓存、APK、玩家档、签名或制作输出。 原Xorg日志四处trailing whitespace按原bytes保留；staged diff-check排除仅Xorg-126.log/stdout两原文件后actual0，未改日志。封存布局含ambush_loop/build路径，会命中仓库ignore；仅按412清单逐项force-add原report/CSV/bin/PNG证据，逐项hash/bytes/tracking复核，无build缓存或制作文件。

## 独立QA与接续接口

本固定a42可独立审public recursive-copy/历史R3/currentrevision/LOD/release与实际20骨/挂点/原record/三opaque token规范化/共同配置及全八raw；作者计数不代QA。下一优化应先取得真实调用热点量测并核仪器成本，再提出一个可复现对比的候选；目前源阅读无法指定唯一瓶颈。本turn无该profiling或新代码。

FINAL同最终source全相关门、完整fullsmoke、fresh原Title/main六关13波与六新records、每件whole1x+whole2x、真实旧schema1加载/消费、全动作/全LOD/五theme艺术/长驻、可追溯fullgameAPK均待验。旧schema1此前只核原bytes，不把hash称兼容通过；旧fullsmoke54/62实际失败保持。耳听/模拟器/真机遵用户顺序最后。

资产接口和所有权保持：R5 source`29749157c5db064bfea626c3ed9d75d9a1791ece`/交付`ebedb829e3263abbeb6dd266905f24a3869fa281`，7角色×3LOD、10枪×2LOD、5工具×2LOD、3atlases共54文件SHA，20骨/64clip/hand.R hand.L head与grip/muzzle；hash不是艺术接受。资产作者独占ArtSource、build_yard_kit/生成器、GLB、Blender、atlas及生产asset manifest；主集成仍负责main/presenter/ViewState/replay/runtime-loader/shared tests。未编辑或重跑这些制作文件、未whole merge WIP f7c30。独立资产包还需可编辑source/export provenance、10枪动作/LOD与5theme艺术接受后再接收。

匹配官方4.7.2模板/SDK仍缺；Java21存在且官方允许更高JDK，缺17单项非已证硬阻碍。APK后续应保持原Title/main_scene并验mobile+a0_preview/fullgame内容与可追溯source/engine/template/import/boot/cert/hash，未安装/导出/签名/adb。Draft PR15保持open/unmerged，SCOUT→ALERT→SWEEP与ALERT冻结不变，无生产发布或height/G混入。
