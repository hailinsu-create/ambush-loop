# 可旋转院子资产源

本批是 A1 道具与建筑样板，不代表角色、整关美术或真机品质已经验收。几何和贴图均为本仓库原创程序生成，没有外部模型、AI 图片服务、账号或第三方素材依赖。

## 重建与检查

在仓库根目录运行，工具为 Blender **4.3.2**、Python 3、Godot **4.7.2**：

```bash
blender -b -t 2 --python ambush_loop/ArtSource/v2/build_yard_kit.py
python3 ambush_loop/ArtSource/v2/validate_exports.py
blender -b ambush_loop/ArtSource/v2/yard_kit.blend -t 2 --python ambush_loop/ArtSource/v2/render_source_review.py
bash ambush_loop/scripts/run_isolated_test.sh /path/to/godot editor_import
bash ambush_loop/scripts/run_isolated_test.sh /path/to/godot asset_review_capture.gd --render
```

`yard_kit.blend` 含九个资产集合及打包的 PBR 贴图，可直接编辑；本批以生成脚本为重建依据。手工修改 Blender 源时必须同步记录导出来源，不得让重建脚本覆盖唯一的手工成果。自动导出产生 `art/v2/manifest.json`、18 个 GLB 和三张共用 1024² 贴图。`.gdignore` 避免编辑源在运行工程中被重复导入；大图和转台帧写入忽略的 `build/asset_review/a1/`。

## 运行约定

- 1 单位 = 1 米；原点为地面中心。Blender +Z 向上、+Y 向前；glTF/Godot +Y 向上、-Z 向前。地面模块的上表面为 Y=0。
- GLB 保存 UV、法线、命名材质槽和用途元数据。通过 `scripts/presentation/asset_library.gd` 实例化，统一应用共享 Albedo、Normal、ORM 贴图；GLB 故意不嵌入重复图片，直接用通用 GLB 查看器看到的是占位材质。
- 普通道具一个材质 surface，灯具另一个发光 surface；仓库外墙四面、屋顶、门与细节分开，便于后续遮挡处理。所有模型均为 `visual_only`，不得直接生成战斗碰撞或导航。
- LOD0/LOD1 独立导出；本批 LOD1 用于远景评审，尚未接入战场距离切换。灯具挂点在清单中给出，光源由场景持有。
- `validate_exports.py` 检查哈希、有效索引/UV/单位法线、尺寸与原点、三角面/surface 计数及简化预算。相同脚本重建得到相同的运行文件哈希。
- 使用 `scenes/presentation/asset_review.tscn` 检查中性光/暮色、8 方位、近景和可拆屋顶。中键旋转、滚轮缩放，L 切光照，R 切屋顶。样板场景不包含战斗逻辑。

仍需逐件美术复核、抗锯齿/纹理远景检查和目标机验证；人物与动作样板属于后续 A1.2。
