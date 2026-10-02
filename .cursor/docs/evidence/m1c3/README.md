# C3 实际桌面截图

源码 `1de462aeb18665111849159945efc0f91d5144b5`；Godot 4.7.2 isolated rendered run `1aed218964934d3881cbbdd8ae839c3c`，wrapper exit 0，玩家数据不变。以下为引擎实际生成的 1280×720 原图，未裁剪、重绘或改色。

这是 main.tscn 的受控 yard 测试夹具：唯一可见队员灰狼为选中枪械射手，坐标 (14,8)，路线样本 (18,8) 到 (20,8)。青色菱形只来自选中队员逐点 `in_fire_geometry`；橙色带是既有 aggregate killzone、黄色扇形是既有非权威方向参考。不证明 authored yard 战术方案、成品美术或 Android 验收。标签仍保留原角色描述，不能据此推断夹具武器。

- [LOW](c3-low.png)：平台射手与近端平台目标，中间 (16,8) LOW；显示独立目标点。
- [Mixed near high](c3-mixed-near-high.png)：平台射手→地面目标，LOW (15,8) 靠近高端，插值高度允许；有点。
- [Mixed near low](c3-mixed-near-low.png)：同高→低端点，LOW (17,8) 靠近低端，拒绝；无点。
- [FULL](c3-full.png)：(16,8) FULL；无点。
- [Move/pan](c3-move-pan.png)：恢复 LOW，真实 command tick 向同高邻格移动后刷新，再 pan (48,-24)/zoom 1.15；仍有正确世界目标点。

Codex 已逐张目视，最终 portrait 和侧栏均选中灰狼。外部 GPT 已读结构/执行记录与文件存在性，但当前连接工具未暴露图片读取；像素评审暂不可用，未 DONE。不能把文件生成、结构门或本地目视当作外部像素评审。
