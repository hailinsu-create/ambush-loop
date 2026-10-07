# PR15 A3 实际云指标采集计划

2026-10-04，接固定71的A2移动cue和固定a9的blast/smoke，枪池b563/flight53/writer9f保持。本计划尚未运行A3；只读并行包已核现存API/六INITIAL文件hash，没有engine、QA或性能结论。来源报告保存在[evidence只读提案](evidence/20261004-pr15-a3-readonly/report.md)，读取时source da1，不能把它冒称新固定FX量测。

继承same-candidate FX/A3计划：先实际六关SCOUT/ALERT/SWEEP/WON/FAILED/REPLAY、镜头与原FX峰值，区分native正常旅程、原reference/API正反例、旧producer/newconsumer兼容。原device_probe只是30秒镜头/2秒剔除，不是全部持续性能门，也不能据此宣称Android30/60FPS。旧六INITIAL不含新shot/tool/dust，只用于兼容与相同原record对照；最终FX峰值需要新真实记录或明确原source reference正向。

实现test-only轻量collector，订阅RenderingServer.frame_post_draw，读取已捕获presenter.frame，不再次capture或调用任何sim/record mutator。不在计时窗口截图、深拷贝diagnostics、print或写文件；仅scalar行缓冲，报告collector用时。原raw intervals保留，包括冷启动/首次scene/FX/LOD/cutaway spike；后续warm repeat另列。pipeline monitor不支持或release给0时标unsupported，不能当无编译或无成本证明。

raw每行：render frame/monotonic usec/interval、segment与exclusion、level/attempt/wave/phase/recorded_phase/frame_seq/local与playback tick、REPLAY speed/sim pause、yaw/pitch/zoom/viewport/policy；draw calls/primitives/rendered objects/texture-buffer-video bytes/static bytes/object-node-resource-orphan counts/process+physics秒/render setup毫秒；shot/tool/dust实际active/cap/cache及geometry/socket rejects、collector微秒。MEMORY_STATIC不是RSS，object count不是bytes；OpenGL无RD的GPU时间不能编造。元信息锁engine/hash/backend/adapter/driver/OS/CPU/cgroup/resolution/scale/fps limiter/vsync/cache/版本与asset revisions。

先固定FX source只进行原reference/API有界六关phase+actual成功枪火/爆炸/移动、8方向/35与65pitch/近远代表性分段，fixture转换与截图保留标记并剔除timing summaries。不会将明确授kit/原直tick的行为夹具叫正常旅程，也不把人为48源容量样本当自然峰值。旧原record的完整真实1×/2×consumer也单列，不拿旧无FX记录冒作最新全部战场。所有engine串行；独立display避免输入冲突，却不消除CPU争用，因此记录实际争用和资源限制。

每segment输出样本数/真实时长/median/p95/p99/max interval、超过33.33/16.67ms比例、draw/primitives/资源峰值、baseline/peak/post-reset对象与memory、池峰值/拒绝/满池；量化方法与raw rows保留。按实测建立环境内预算并选单片优化，比较同记录/输入/镜头/分辨率/策略，保持原terminal/events/HP/ammo/inventory及旧raw hash。不同source/policy/environment数字不能拼成最终green，llvmpipe数字不能推真机热稳或手机FPS。

全枪/姿态/LOD与真实战场艺术帧复核仍由具体source及实际图证明，需要制作修订时只接已验独立commit；R5/ArtSource/GLB/Blender/atlas/production manifest单写边界保持。收敛后锁最终candidate：相关全门/fullsmoke、新正常Title→六关13波→WON/CTA/自然progress/credits，封六新raw，再完整1×/2×3D pause/seek/eventfocus/跨wave/source/oldraw。所有同source通过范围明确后生成fullgame可追溯APK；工具链需实际安装/模板/导出/签名验证，但不运行模拟器/真机/adb，也不提前宣称设备或耳听验收。Draft PR15普通push，不merge/生产/height/G。
