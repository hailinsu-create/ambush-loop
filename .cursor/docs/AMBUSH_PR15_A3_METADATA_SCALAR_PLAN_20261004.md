# PR15 A3 窄元数据访问切片

当前端点（2026-10-04）：功能六门4069/21818/610/7681/233/32各0 actual0 E0/S0；固定A41ff/Ba42 common4预检各0并strict同输入。正式ABBA/BAAB START20:54:51/naturalEND21:04:27UTC，8轮actual0 E0S0、strict0，1278raw/672accepted/16原图全核并看；未证稳定收益，预算仍未过。自有Godot全收/Xorg126实际0关闭，99未动，性能窗口释放。父端最新要求本turn止于固定候选/实测，封存交QA，不叠加优化/FINAL/APK。[实际结果、全命令/失败/接口](AMBUSH_PR15_A3_METADATA_SCALAR_RESULTS_20261004.md)。下文保留实施前计划与当时状态；当前完成/未验以新报告为准。

实际状态更新：实现consumer `cd352bfb3ad1f7b7c7863a115c5dec29fc02042a` 首次Guard headless asset_library_test UUID003c759a0a6c4900a4548dc235fc6ad9自然actual1、anchoredSCRIPT ERROR1/ERROR1；新增测试line124从untyped path推断environment失败，尚无checks/场景/资源/parity执行，不称生产回归或绿。已在修复前封[原source/log/exit](evidence/20261004-pr15-metadata-scalar/negative-cd352-test-parse/manifest.json)，下一独立test-only一行显式bool，生产两blob不变；修正后fresh运行，性能仍待。

2026-10-04，接六关实际来源报告/证据交付 `41ff06cf8d01ce01b0d6ca1e33247daac9210bc1`。正式原轮 consumer a90、23559/0 actual0 E0/S0、strict0/13波/576代表性历史窗口/60原PNG全核并查看已封并正常push/readback。预算未达；本切片不以先前结果代优化验证。

唯一生产改动：`asset_library.model_path` 在原 revision拒绝门之后直接只读已验证内部catalog，新增返回bool的 `is_character_asset` 保留原类别严格比较；presenter只替换原公开deep copy类别查询，保animation_supported→has_asset→category短路与次序。公开 `asset_record`继续recursive duplicate，ActorVisual metadata与socket/clips、asset validation、revision/legacy/LOD行为、resource/material/释放、ViewState、pose/FX/record/sim与全部资产文件不改。内部可变Dictionary/Array不通过新接口返回，无额外cache或失效路径。

只读接口审查 `/tmp/pr15-a3-window-controls/readonly-metadata-scalar-interface.md` 已完成，无engine或测试。当前代码及测试尚未Godot运行。新增既有asset_library_test的manifest独立oracle：全部71 accepted IDs/当前与兼容revision、R3 legacy实际原path/GLB SHA、negative/count/large LOD、跨namespace/unknown、category、公用返回值nested LOD/socket/clip污染隔离，以及release后重新加载。保留既有真实instantiate/mesh/material/socket门；不是只比较另一个accessor。

接下来的有界实际门：官方4.7.2与Guard，串行headless扩展asset_library、actor_visual（真实20骨骼/LOD/socket）、firearm_runtime（R3原资源/接触/pose）、environment_assets（当前环境GLB/材料/socket）；shared lifecycle/history seam与实际3D actor_battle的saved-clock/unsupported fallback/LOD/同body/item身份。每项固定源码、actual exit与anchored ERROR/SCRIPT ERROR、原图完整保留。初次新测试错误或任何生产反例先保存原日志/source/exit，再独立修，不改资产制作解决。

性能另外成片：冻结本baseline与candidate，使用完全相同原A3record bytes/attempt/selected frame、camera/config/clock/backend/presenter payload、官方engine与完整warmimport证据，在唯一Godot串行进行重复交错A/B或ABBA及足量samples，另列advancing pose。比较postdraw分布/monitor更新语义/RSS/resources/FX占用，collector不改、不减开销。功能结果与元数据查询microbenchmark均不等于整个游戏FPS提升；无实际comparison之前不宣称成本归因或收益。

完成本片后继续FINAL同最终source/fullsmoke/freshnative六关13波/六新records完整1x2x/旧compat和全资产、APK；设备/耳听依用户顺序最后。本切片仅A3授权范围，无merge/prod/height-G，ArtSource/GLB/Blender/atlas/asset-author manifest所有权仍归独立资产作者。
