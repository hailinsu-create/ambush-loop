## 接管结论与暂停状态

Notion 交接页：https://app.notion.com/p/3edcc0775087818ea39edeb723e03671 。

交接日期：2026-10-02（Asia/Shanghai）。来源：本次 Codex 会话「查找 lning 分支和 PR」。用户最新指令：“不进行协调了，你这边直接在 notion 中写好工作交接，然后暂停当前工作，后续工作有 dot 统一安排”。

本会话完成交接后暂停，不继续制作、测试、合并或安排其他代理。原占用工作包为 **A1.2 角色、共同骨架、动作与武器草稿**；文件范围在下文列明，交接后释放，由 dot 统一重新安排。没有向 dot 或其他会话发送协作消息，也没有创建新的代理。

**整个资产计划尚未完成。** A0 灰盒及首批 A1 道具有云端证据；角色资产只有初次 Blender 导出，带告警，未通过源校验、Godot 评审或玩法接入。请勿把 WIP 导出数量当作成品数量。

## 已确认需求与执行约束

- 画风更写实，接近经典战术游戏的厚重细节；第一关为暮色工业院落，冷灰环境、局部暖灯。
- 360° 水平自由旋转，俯角 35°–65°，可缩放；比例为一格一米。
- 主流中端安卓稳定 30 FPS、高配可选 60 FPS是目标，尚未取得本轮真机达标证据。
- AI、Blender 或其他工具均可；缺少工具可按需在云端安装。当前源资产为原创程序几何和材质，无第三方付费服务。
- 用户设备为努比亚 Z60、Android 14，可安装 APK；尽量由开发端完成能自行完成的检查。
- **先完成全部计划制作、六关接入和云端验证，再处理模拟器/真机。** 用户最新顺序替代旧 A0.3/A3 设备门槛阻塞生产的安排；不提前要求用户装灰盒或进行设备测试。
- 保持 SCOUT → ALERT → SWEEP、ALERT 计划冻结、战斗数值/路线/胜负/可行走区域；不混入高度玩法、第七关、FOW 或联网。表现层只读，回放不可写活体状态或读取当前装备伪造历史。
- 新 PR 未获自动合并授权；旧 #11/#12 的合并已经完成。

## 远端源码与恢复入口

仓库：[hailinsu-create/ambush-loop](https://github.com/hailinsu-create/ambush-loop)。已实际核对远端 SHA。

- 主线：`c1aaf27c23f8f711f23305bf6f3223c38cb69098`，包含已合并 #11 寻路优化与 #12 审计。
- 实现分支：`feat/rotatable-yard-a0-20261002`，当前 `b766da1c06b3312aac4f7120556d8cbd5d32b8d0`；[Draft PR #15](https://github.com/hailinsu-create/ambush-loop/pull/15)，Open、未合并。此分支保留 A0、首批 A1 样板和最新执行顺序。
- **暂停草稿分支**：`wip/asset-actors-handoff-20261002`；角色/武器冻结源码提交 **`f7c30f9f7f0c2d53513191235f3a719a251e3a4c`**。该提交已推送并核对远端。它是 b766da1 的后继，仅保存未验收角色资产、制作脚本和导出日志；未混入 PR #15，没有另开 PR。
- [冻结草稿源码](https://github.com/hailinsu-create/ambush-loop/tree/f7c30f9f7f0c2d53513191235f3a719a251e3a4c) · [草稿与 PR 分支差异](https://github.com/hailinsu-create/ambush-loop/compare/b766da1c06b3312aac4f7120556d8cbd5d32b8d0...f7c30f9f7f0c2d53513191235f3a719a251e3a4c)
- 本机工作目录：`/workspace/ambush-3d`，Godot 工程子目录 `ambush_loop/`；暂停时已切到上述 WIP 分支，后续文档提交只补交接记录。
- 原完整资产计划在 [PR #14](https://github.com/hailinsu-create/ambush-loop/pull/14)，本机 `/workspace/asset-upgrade`，源提交 `d69251be42d5f96c99da48a24a3923b62863f28f`。

恢复时先获取远端分支并核对提交，再按 dot 的安排取用草稿；无需依赖本机未提交文件。不要重置其他工作目录或改动旧玩家档。

## 已实现并有证据的内容

**A0 表现接缝与灰盒**：二维逻辑继续模拟，3D 只读状态；世界坐标转换、正交镜头、360° 旋转、俯角/缩放、双指平移/扭转/捏合、鼠标中键、地面/角色拾取、UI 优先和触摸取消、简易建筑遮挡、原冻结方案和回放代理。正式默认入口仍为旧二维视图；新入口是独立 preview 场景/自定义导出 feature。

**首批 A1 道具/建筑**：木箱、沙袋、油桶、电台、灯具、仓库片段、混凝土/沥青/泥地共九资产、十八 LOD；共享 1024² Albedo/Normal/ORM；可重建 Blender 脚本和可编辑源；Godot 中性/暮色、八方位、拆顶、俯角边界与远近评审。它们仍在独立评审场景，未完成战场替换，也不是全游戏写实资产验收。

实际验证：

- 主线寻路：504 条等价路径、311 个最短代价 oracle 检查通过，指纹 `0b77fff7d2d836cb1eccb589891c1c5f3a6bf5c63b25ea3a8a369e2d6e3aad45`。
- A0 冻结源码 `1331d97876262c938a470c0795ac7d999debae97`：完整六关冒烟退出 0，run `72af153d0f5e4db7a6f7cbff7a150a6b`。
- 同一 A0 源：表现契约 84,039 检查退出 0，run `9ea6830c844546b288e92483922a6cd9`；原生输入 38 检查退出 0，run `f239dbdbbd724648893bf3be4fa55b65`；手势 20 检查退出 0，run `79ed81ac44a64aca9b502687cb5cd91b`。
- 静止镜头 60 FPS、旋转 30 FPS、旋转 60 FPS/2×参考战斗终局相同：tick 1056，22 事件，HP/弹药/敌人结果一致。
- 首批道具生成、重复生成哈希一致、源校验通过；Blender 转台 40 帧退出 0；Godot 23 张捕获最终退出 0，run `8e89af6e28e541ceb8696b1a0511b797`，捕获脚本源 `81ff89e`。
- 这些结果只证明各自固定源码；**没有为本轮角色 WIP 重新运行上述检查，不能把旧测试归给新草稿。**

证据与截图：[A0 记录](https://github.com/hailinsu-create/ambush-loop/blob/b766da1c06b3312aac4f7120556d8cbd5d32b8d0/.cursor/docs/AMBUSH_3D_A0_EXECUTION_20261002.md)、[A1 样件记录](https://github.com/hailinsu-create/ambush-loop/blob/b766da1c06b3312aac4f7120556d8cbd5d32b8d0/.cursor/docs/AMBUSH_ASSET_A1_SAMPLE_20261002.md)。原始精选日志在 `.cursor/docs/evidence/20261002-a0/`、`20261002-a1/`。

## 本轮 WIP：实际产物、文件范围与已知缺口

初次 Blender 构建退出 0，完成标记 `ACTOR_KIT_EXPORTED 22`。清单为 22 资产、51 个 LOD：三队员、四敌人、十枪、匕首/手榴弹/地雷/诱饵/弹药包。脚本声明 20 骨共用骨架和 12 动作：idle、walk、run、aim、fire、pickup、death、crouch、crouch_walk、deploy、hit、haul。实际导入后的骨架、动作轨道、蒙皮和挂点尚未核实。

本会话暂停前写入的文件均在下列范围，除此之外没有开始本轮游戏接入：

- `ambush_loop/ArtSource/v2/build_actors.py`：新制作脚本，调用已有 `build_yard_kit.py` 的材质/UV/合并辅助函数；没有修改该旧脚本。
- `ambush_loop/ArtSource/v2/actors.blend`：可编辑源，约 17 MiB，打包角色贴图。
- `ambush_loop/art/v2/actors_manifest.json`：独立台账，未改旧 `manifest.json`。
- `ambush_loop/art/v2/textures/actor_atlas_albedo.png`、`actor_atlas_normal.png`、`actor_atlas_orm.png`。
- `ambush_loop/art/v2/models/`：仅新增 `operator_rifle/operator_mg/operator_scout/enemy_patrol/enemy_flank/enemy_heavy/enemy_radio` 的 lod0/1/2；`m1911/luger/m1_garand/kar98k/thompson/mp40/bar/mg42/springfield/kar98k_zf/knife/grenade/mine/decoy/ammo_pack` 的 lod0/1。既有九道具文件未改。
- `.cursor/docs/evidence/20261002-a1-actors-wip/STATUS.md` 和 `blender-export.log`：未验收声明与原始导出记录。

**明确未完成的问题：**

- 导出日志包含 18 条 `Mesh ... is not valid, and may be exported wrongly`；需逐项定位并修复。另有可选 Draco 库缺失信息，当前没有启用 Draco 压缩。
- 敌人 LOD0 约 9.9k–10.4k 面，超过原 4k–8k 预算；英雄 LOD0 约 9.9k–10.4k 面。暂为每模型一个 surface，面数不是品质验收。
- 没有进行本批 Godot 导入、360° 画面、动作录屏、脚底接触、握持、枪口、暂停/2×、LOD 或回放检查。部分武器形体仍共用构型，需要逐枪核对识别特征。
- `asset_library.gd` 仍仅给所有普通材质绑定 yard 图集；尚不识别 `v2_actor_atlas`，不能直接用现状加载器宣布人物材质可用。
- `actors_manifest.json` 中的 `character_review_capture.gd` 是预定入口，**文件尚未创建**；角色 runtime、动画选择、骨挂点与战场替换也未创建。
- 已有 `validate_exports.py` 面向首批静态道具，不能直接当作角色骨架/权重/动画验证器。
- 全部草稿状态保持 `exported; engine review pending`；未对这批资产作视觉品质背书。

[WIP 状态和导出日志](https://github.com/hailinsu-create/ambush-loop/tree/f7c30f9f7f0c2d53513191235f3a719a251e3a4c/.cursor/docs/evidence/20261002-a1-actors-wip)

## 尚未占用但后续需要接续的代码边界

下面是接续定位信息，不是新分派或施工授权。由 dot 决定负责人和顺序。

- `scripts/presentation/asset_library.gd`、待建角色展示/验证文件：角色图集、动作、挂点、LOD。
- `scripts/presentation/view_state.gd`：目前缺完整装备、蹲伏/冲刺/搜索/拖拽、工具与事件；`events` 仍为空占位。历史兼容字段不可从活体补写。
- `scripts/presentation/presenter_3d.gd`：仍为灰盒，需完整场景、人物和道具接入；原逻辑 World 隐藏必须继续用 RenderingServer canvas 可见性，不能把 `op.visible` 或逻辑节点 processing 关掉。
- `scripts/main.gd`、`scripts/replay/`、`scripts/c2/`：公共模拟/回放接缝，应单写者集成。已有鼠标坐标 helper 和命令路由应复用，不另造坐标补偿。
- `scripts/input/`：已有手势取消、鼠标/触摸去重和 ALERT 拒绝规则，修改要保留定向测试。
- HUD、45 cue 音频替换表、事件去重特效、安全区、画质/镜头设置、标题至结算/重试/回放的正式 3D 入口：本轮尚未施工。
- 十四道具分类全覆盖、六关地标与声景仍未补齐，不能将首批九资产等同于完成这项。

## 接续清单，交由 dot 排序

1. 决定是否沿用角色 WIP；先修复 mesh 告警、检查蒙皮/骨架/动作并评审比例材质，再接入。当前生成数量足够做候选库，但无需保留质量不合格的草稿。
2. 完成 A1.1 品质闭合和 A1.2 角色动作基准，再做 A2.0 完整院子、A2.1 HUD/续玩、A2.2 3D 历史回放及事件去重。
3. A3 云端优化：现有灰盒含旧 HUD 为 267 draw calls / 10,038 primitives，超过暂定 200 draw 警戒；需减少 HUD/代理/surface 提交。道具评审的 95 draw / 11,294 primitives只代表另一场景，不能替代实战预算。
4. A4 仓道、泵站、信号楼、油库、电台：逐关主题资产、地表、灯光/声景与参考战斗回归。
5. 全部制作完成后构建完整 APK、精选录屏/截图、固定提交与证据；再安排模拟器、Z60 和代表性中端机的触控、后台/返回与持续性能。30/60 FPS、热稳定、陌生人首局仍待验收。

## 云端工具、运行与存档安全

本环境固定 Godot 4.7.2；系统默认 4.6.3 不可代替。Blender 4.3.2、FFmpeg 7.1.5、Python 3.12 已装。Blender 不含 OpenImageDenoise，源评审曾使用 Cycles CPU 24 samples、关闭 denoising。

- Godot：`/workspace/tools/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64`
- Android 模板：`/workspace/tools/godot/4.7.2/templates`
- JDK：`/workspace/tools/java/jdk-17.0.20.1+1`
- SDK：`/workspace/tools/android/sdk`，API 36、build-tools 36.0.0、adb 37.0.1。
- Xvfb 工具在 `/workspace/tools/x11`；曾使用 DISPLAY=:99 和其 lib 路径。暂停检查时没有 Xvfb/Godot/Blender/模拟器进程，后续不能假设显示服务还在运行。
- 软件 Android 模拟器无 KVM，先前出现系统 ANR，已停止；不算应用验证通过，按用户要求此阶段不继续排查。

所有会清理测试档的检查必须使用隔离包装器，禁止直接启动 smoke_test.gd；source_sha/实际退出码/完成标记必须一起记录。典型命令只供后续接手，不代表已在 WIP 执行：

```bash
cd /workspace/ambush-3d
bash ambush_loop/scripts/run_isolated_test.sh /workspace/tools/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 editor_import
bash ambush_loop/scripts/run_isolated_test.sh /workspace/tools/godot/4.7.2/Godot_v4.7.2-stable_linux.x86_64 presentation_contract_test.gd
```

渲染捕获需可用显示环境及 `--render`；新测试需加入 Linux/PowerShell 白名单和 StorageGuard。捕获退出前停止 AudioDirector 旧背景播放可避免 Dummy driver 的两个播放对象泄漏警告。完整 smoke 约十八至十九分钟，修改有必要时再运行，不能用片段成功标记当整套通过。

云环境状态实际核对为 revision 7、enforced、connected，无 secrets/identities；受限网络使用现有代理和证书。GitHub API、Git 推送可用；`uploads.github.com` 未获允许，先前 release 资产上传被拒，空 draft release 已删除。不要绕过网络限制。没有新 APK Release URL。

## 已有 APK 与附件边界

现有 APK **仅 A0.2 灰盒，不包含首批 A1 道具或本次人物草稿**：

- 文件：`/workspace/deliverables/ambush-loop-a0-20261002/AmbushLoop-A0.2-arm64.apk`；同目录有 `manifest.json` 和 `rotation.mp4`。
- 源码：`1e9863ba0e9c007b0fb612d8dd5f705fa7f374d7`。
- SHA-256：`d5a4d33743c6d1ee1b20f237be3ff1a94384695ca56bf0a28e22956f00b09b83`；29,624,703 bytes。
- 独立包名 `com.ambushloop.game.a0`，version `0.7.0-a0.2` / code `2026100202`，720p、30 FPS 上限；debug 测试签名。
- 签名留在忽略的 build 目录，不入库；源码和贴图已入远端 WIP，APK/本地大视频未上传 GitHub。

## 规划与证据入口

- [最新执行顺序 v2](https://github.com/hailinsu-create/ambush-loop/blob/b766da1c06b3312aac4f7120556d8cbd5d32b8d0/.cursor/docs/AMBUSH_ASSET_EXECUTION_PLAN_20261002_v2.md)
- [完整资产计划，PR #14 固定源](https://github.com/hailinsu-create/ambush-loop/blob/d69251be42d5f96c99da48a24a3923b62863f28f/.cursor/docs/AMBUSH_ASSET_EXECUTION_PLAN_20261002.md)
- [规划索引](https://github.com/hailinsu-create/ambush-loop/blob/b766da1c06b3312aac4f7120556d8cbd5d32b8d0/.cursor/docs/PLANNING_INDEX.md)
- 网页 GPT PLAN/REVIEW：unavailable，没有外部 approve。

本页记录的是交接时事实与剩余工作，不声称 dot 已接收、认领或完成；后续安排由 dot 统一决定。
