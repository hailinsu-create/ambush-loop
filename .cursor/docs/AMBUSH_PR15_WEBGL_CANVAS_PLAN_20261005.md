# PR15 WebGL 旧画布绘制门最小切片

2026-10-05，继承 [首次正式发布结果](AMBUSH_PR15_WEB_INITIAL_RESULTS_20261005.md)。正式 Site 仍是游戏843f/运输fa188版本，不能用诊断样本更新验收状态。

固定官方4.7.2的 `Polygon2D` 同拓扑 redraw 进入 index-region更新，GLES错误ARRAY目标写入；原Web历史实际错误已保留。只读审计说明RS隐藏World不停止Node redraw。DRAW marker实验找到靠近Cover ProtectArc/Arrow与ReplayLayer的重绘，但官方Object notification顺序是native→script，不能把末次script marker当作精确当次native caller。首观察器还曾放错autoload路径；通知内白采样纹理实验仍24错误，均保留、未入生产。

隔离Main canvas gate实验：仅在Web且实际3D presenter.bind时设置Main Node2D自身visible=false；World及实体自身visible值不改，Node的process/input模式不改；HUD与3D控件是独立CanvasLayer，3D节点独立可见性。初始yard历史ALERT观察8坏绑定→0、fresh warning0/JS0/GodotE0/S0，实际3D/HUD保留，World.visible=true。原静态截图仅4个RGB像素有差异（提示文本范围），没有宣称像素严格相等或全矩阵通过。

实施限定为presenter.bind中Web条件的Main画布门；无引擎/JS GL patch，不隐藏/重写单个角色cone或World节点，不改记录/装备/模拟/资产。Native分支保持RS-only。这个门会使旧World子项的effective visibility为false（self-visible保持），旧2D ink检查将反映隐藏状态；它们不是实际3D UI验收。生产source无Core simulation调用effective World visibility的路径，后仍必须实测。

验证顺序：固定候选source、原生隔离presentation合同（native逻辑可见性/HUD/处理模式）、完整同源Web debug/release导出；实际browser六关历史阶段/波次前后seek与事件聚焦、yard whole1x/2x/只读身份、freshGL console，并实际SCOUT鼠标/背包/Back/ALERT暂停锁/触控cancel。关键门失败先保留再修；新Web正常13、其余五完整whole/oldschema/正式origin仍另列待。

资源与权限：只消费验收资产、不调用生成器/Blender、不改共享atlas/GLB/作者manifest。当前只读工作者已结束；根独占引擎/浏览器，诊断不当性能样本。当前稳定私有Site仅首次发布、rollback=null，不创建preview/冗余部署，不改网络/分享；正式域名proxy CONNECT403仍阻塞。

## 实施前置实际结果

工作候选在31273a基线两文件overlay的隔离stage执行原生storage guard包装器：presentation_contract_test.gd实际84048/0、exit0/E0/S0，01:11:55.927546→01:12:45.382198Z。presenter文件SHA256622843339c393cef53f397b3e76471bd8f96f3fe6c0ef0df3fd4b83a68aad69a、shared test SHA2562de44b20ffaea7cb2a0932f501b672ac5ab6c20a032addea04136b7e5c64e25a；root全部tracked前后不变。它仅证明native分支保持，不代Web门。

## 2026-10-05实际进展

候选已固定1d17；完整Title debug/release0 E0/S0，实际六关原native消费25951/0 actual0、76前后seek/6fire聚焦/44原PNG全看、freshGL/JS/Godot0。whole/输入仍待，正式Site仍v1未更新。父端要求本轮有界封存，owned窗口END01:37:59Z已释放；[实际结果、tar差异复现及下一包](AMBUSH_PR15_WEB_CANVAS_RESULTS_20261005.md)替代本计划的候选待导出/历史待验状态，不替代完整Web/FINAL门。
