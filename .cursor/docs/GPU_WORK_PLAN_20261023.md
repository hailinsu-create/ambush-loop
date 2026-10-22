# GPU 工作方案 2026-10-23（v2：主路线改为按需租卡）

来源：用户要释放 AutoDL 两台显卡机（791：359a49a1c3-4cda10df，RTX 5090；592：683045898b-caaa5b8f），以后不再保留自有 GPU 实例。v1 的主路线是混元 API。用户看了以后指出「混元看上去比租卡要贵」，所以 v2 改为：**按需新开 AutoDL 5090，自己跑开源模型（Hunyuan3D-2.1 shape+paint、UniRig 关节）；只有自己跑出来过不了质量门的单件，才走混元 API 补救**。状态：**规划，未执行**。没有开机、没有花钱、没有注册。

## 1. 现状和释放影响

**已完成**（AutoDL 5090，¥2.88/h，两轮合计约 ¥8.9）：
- 72 个 Hunyuan3D-2.1 形状模型：72/72 生成成功，单个约 1 分钟、约 ¥0.05。
- 66 个 Paint 贴图模型：单个约 46 秒（66 个共 3026 GPU 秒，约 ¥2.42）。
- 6 个人物：UniRig 关节（6 个共约 17 分钟）→ Blender 重建骨架 → 自动权重 → 手 K 9 个动作 → 8 方向 128px 精灵。
- 渲染在本机 CPU：一个人物 864 帧约 35 分钟。**渲染不需要 GPU。**

**791 释放后会丢**（本机和 store 都没有）：

| 数据 | 数量 | 影响 |
|---|---|---|
| Paint 输出的 metallic/roughness sidecar | 65 个模型 × 2 | 本机只有 mg_gunner 的 MR |
| 去背景参考图 `nobg/*_v0.png` | 66 | 本机有原图，CPU 能重抠，影响小 |
| Paint 原始 `.obj` | 66 套 | 本机有 GLB，影响小 |
| Hunyuan3D-2.1、UniRig 的 conda 环境和权重，791 上的 Blender 4.2 | 1 套 | 以后要重建 |
| 791 上的批处理驱动脚本 | 未计数 | 本机没找到副本 |

592 上有什么：**未核实**。

## 2. 待做 GPU 工作清单

| 优先级 | 工作 | 数量 | 生成次数（含重试） |
|---|---|---:|---:|
| P1 | 重出 eihandgranate_39、pps43、luger_p08 | 3 | 6 |
| P1 | 偏色 8 件：bar_m1918a2、mg_ammo_box_34 用 paint 重出贴图；colt、panzerschreck、tt33、sten、mk2、pps43 背带在 CPU 上修 | 2 + 6 | 2（只跑 paint） |
| P1 | 敌方重火机枪手 enemy_mg（设计 v2 §7.3 要三种敌人职责，现在没有 3D 模型） | 1 | 2 + UniRig |
| P2 | 第三关以后的新人物/敌人（预估） | 3 | 6 + UniRig |
| P2 | 新武器/配件（预估） | 10 | 15 |
| P2 | 第 3–6 关地标道具（泵体、油罐、桅杆、天线等，预估） | 16 | 24 |
| — | 关卡建筑、MR 补全、新动作（蹲/拿取/部署）、概念图、渲染 | — | 本机 CPU，**0 GPU** |

合计约 **55 次 shape+paint、2 次只跑 paint、4 个人物跑 UniRig**，按关卡分 **3 次开机**：P1 一次，第 3–4 关一次，第 5–6 关一次。

## 3. 成本对比（同一份清单）

单价依据：
- 自己跑：shape 约 1 分钟、约 ¥0.05/个；paint 约 46 秒、约 ¥0.04/个；UniRig 约 3 分钟、约 ¥0.14/个（前两轮实测，¥2.88/h）。
- 重建环境：首次按 1–2 小时 GPU 算，即 ¥2.9–5.8，包括 bpy/pymeshlab 排坑。有镜像以后，每次开机和自检按约 15 分钟、约 ¥0.7 算。
- API：混元生3D 专业版 3.1 + PBR，30 积分，约 ¥3/个；纹理生成约 ¥3/个；绑骨约 ¥1/个（[腾讯云计费](https://cloud.tencent.com/document/product/1804/123461)）。

| 项 | 租卡自己跑（推荐） | 全走混元 API |
|---|---:|---:|
| 55 次 shape+paint | 55 × ¥0.09 ≈ ¥5.0 | 55 × ¥3 ≈ ¥165 |
| 2 次只跑 paint | ≈ ¥0.1 | 2 × ¥3 = ¥6 |
| 4 个人物绑骨关节 | 4 × ¥0.14 ≈ ¥0.6 | 4 × ¥1 = ¥4 |
| 环境 | 首次重建 ¥2.9–5.8，再加 2 次开机 × ¥0.7 | 0 |
| 存储 | 镜像 ≤30GB 免费；autodl-fs 放权重约 22GB，约 ¥0.02/天 ≈ ¥7/年 | 0 |
| 补救（预留约 10%，5 件过不了门，各走 API 一次） | ¥15 | — |
| **合计** | **≈ ¥32–35（GPU ¥10–13 + 存储 ¥7/年 + 补救预留 ¥15；补救没用上就是 ¥17–20）** | **≈ ¥175（扣掉 100 免费积分）** |

结论：租卡便宜约 5–7 倍。开机等待、bpy 排坑这类风险，用镜像加脚本来压低（见 §6）。

## 4. 租卡平台

**主平台：AutoDL 按需新开 RTX 5090 32GB**。已有账号，实测 ¥2.88/h，镜像和网盘生态最好。

选卡依据：
- 官方 README 写明 shape 要 10GB、paint 要 21GB，一起跑 29GB（[README](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1)）。
- 社区 issue 反映 24GB 卡跑不了 paint（[#85](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/85)）。mmgp 把模型卸到 CPU 后能跑，但有人反映还是 OOM，或者更慢（[#15](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/15)、[ComfyUI #9](https://github.com/visualbruno/ComfyUI-Hunyuan3d-2-1/issues/9)）。
- 所以 **4090 24GB 不用**，选 32GB 的 5090；没卡时退到同区 48GB 卡（A6000/L40S/4090 48G）。

社区对各平台的价格和口碑：

| 平台 | 价格（社区/官网） | 口碑 | 来源 |
|---|---|---|---|
| AutoDL | 4090 约 ¥1.98/h，5090 实测 ¥2.88/h | 生态和镜像最好；晚高峰热门卡难抢；关机后 GPU 不预留 | [rentgpu 对比](https://rentgpu.link/posts/autodl-vs-gpushare-vs-matpool)、[fwidc 实测](https://www.fwidc.com/news/44_231003.html)、[AutoDL 计费](https://www.autodl.com/docs/price/) |
| Featurize | 5090 ¥3/h，4090 ¥1.87/h | linux.do 用户推荐，便宜 | [Featurize](https://featurize.cn/vm/available)、[linux.do](https://linux.do/t/topic/2596442) |
| 恒源云 | 4090 ¥1.88/h | 稳定，送 50GB 存储；竞价实例会被抢占 | [rentgpu](https://rentgpu.link/tw/vs) |
| 矩池云 | 4090 ¥2.20/h | 价格有竞争力，文档一般 | 同上 |
| 优云智算 | 4090 ¥1.92/h | 驱动偏旧，环境简陋 | 同上、[fwidc](https://www.fwidc.com/news/44_231003.html) |
| 魔搭免费 GPU | 36 小时免费，24GB | 24GB 不够跑 paint | [linux.do](https://linux.do/t/topic/2596442) |
| RunPod / Vast / Modal | 4090 $0.34–0.74/h；Modal 每月 $30 免费额度 | 5090 难抢、Pod 会被驱逐、Vast 中途重启；要外币付款 | [r/mlops](https://www.reddit.com/r/mlops/comments/1wln9m7/notes_from_22_paid_runs_on_four_gpu_rental/)、[r/StableDiffusion](https://www.reddit.com/r/StableDiffusion/comments/1vyze6r/best_budget_gpu_cloud_comparing_runpod_vastai/) |

不换平台。AutoDL 没有 5090 时，先换地区（私有镜像可以跨地区加载），或者错开高峰再开。

**保存环境，减少下次重建**：
- **保存镜像**：只保存系统盘（30GB），conda 环境、代码、Blender 4.2 放系统盘。镜像按所有镜像总容量计费，**30GB 以内免费，超出部分 ¥0.01/GB/天**，最多 20 个（[AutoDL 计费 · 镜像计费](https://www.autodl.com/docs/price/)、[镜像文档](https://www.autodl.com/docs/image/)）。可以跨地区加载，首次加载要从公网传、比较慢，但「创建中」不计费（[迁移文档](https://autodl.com/docs/migrate_instance/)）。
- **权重放 `/root/autodl-fs` 文件存储**：数据盘的内容不进镜像。权重约 22GB：Hunyuan3D-2.1 仓库 14.9GB、DINOv2-giant 单份约 4.5GB、UniRig 约 2GB、RealESRGAN。文件存储 20GB 免费，超出 ¥0.01/GB/天，只能在同地区共享（[env 文档](https://www.autodl.com/docs/env/)、[price](https://www.autodl.com/docs/price/)）。换地区就重新下载。
- **store** 只放脚本、锁版本的 `requirements.lock`、manifest 和全部产物，不放权重，因为太大。

## 5. 质量（如实写）

- 社区数据：开源 Hunyuan 在 Reddit 的 200 次对比里，生成成功 82%，30 分钟内能清理到可用的只有 61%。Meshy 78%、Tripo 72%、Rodin 81%（[r/aigamedev](https://www.reddit.com/r/aigamedev/comments/1tjfsry/ai_3d_generator_comparison_for_indie_games_meshy/)）。
- 我们自己前两轮：
  - 形状：72/72 生成成功，3 件偏差（eihandgranate_39、pps43、luger_p08）。
  - 贴图：**66 件里 58 好、8 可用、0 差**。
  - 比社区数字好，原因是我们有本机清理这一步：选块、减面、合并顶点。
- 混元 API 3.1 和开源 2.1 的直接对比**未查到**。所以 API 只用来补救单件，不批量用。
- 质量门槛（不变）：
  - 不接受粗糙的模型：对照参考图评「好」才进管线，「可用」的先修。
  - 人物不能是剪影：48px 下 8 个方向至少 7 个能认出来。
  - 全套动作：9 个状态，加上蹲、拿取、部署；握持误差 ≤0.06 m，穿地 ≤0.05 m。
  - 武器只有 1 个连通块、开放边为 0、≤3.5 万面。
- **补救规则**：同一件在租卡上最多跑 2 次（换 seed 或换参考图裁切）。还过不了门槛的，才用混元 API 单件重出，补救总额上限 ¥30。

## 6. 每类工作的推荐路线

- **图生3D**（新人物、敌人、武器、重出、道具）：租卡跑 Hunyuan3D-2.1 shape+paint，按 manifest 跑批；不过门的单件走混元 API。
- **偏色**：本机 Blender 调色、删几何；只有颜色改不对的 2 件跑 paint 重出。
- **MR**：
  - 新模型直接用 paint 输出的 MR。
  - 旧的 65 件**按 CPU 规则补**：金属 metallic 0.8 / roughness 0.45，其余 0 / 0.8，再和 mg_gunner 的真 MR 对比渲染。
  - 不随批重跑 paint。原因：重跑 paint 会重新生成网格、UV 和 albedo，已经评为「好」的 58 件要重新评审，可能变差；而 128px 夜景下 MR 的差别看不出来。
  - 如果授权 791 拉回（§8 第 2 项），就直接用原 MR。
- **场景建筑**：本机 Blender 程序化建模（社区说 Meshy/Tripo 做建筑很差，见[r/aigamedev](https://www.reddit.com/r/aigamedev/comments/1wfyepq/tripo_3d_vs_meshy_for_asset_gen/)）。地标道具随批跑 shape+paint。
- **绑骨**：在租卡上随批跑 UniRig，只取关节，本机用 `skin.py` 重建骨架。UniRig 失败的人物用 Mixamo 自动绑骨拿关节（免费，可以商用于游戏，见[FAQ](https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400)）。
- **动作**：本机 Blender 手 K。社区说 Mixamo 步枪动作重定向后手对不上枪（[Adobe 社区](https://community.adobe.com/t5/mixamo-discussions/mixamo-rifle-animation-left-hand-twisted/m-p/14145826)）；HY-Motion 要 24–26GB 显存，不带道具（[HF](https://huggingface.co/tencent/HY-Motion-1.0)）。
- **概念图和贴图**：自带生图工具，不用 GPU。

## 7. 重新开 GPU 的步骤（每次开机都照做）

1. 机器：AutoDL 5090 32GB，镜像用 PyTorch + CUDA 12.8 以上。有私有镜像就直接加载，跳到第 5 步。
2. 首次重建：
   - 克隆 Hunyuan3D-2.1，`pip install -r requirements.txt`，编译 `custom_rasterizer` 和 `DifferentiableRenderer`。
   - 设 `HF_ENDPOINT` 走镜像，把权重下载到 `/root/autodl-fs/weights`，然后软链到代码目录。
3. **bpy 坑**：paint 的 `convert_obj_to_glb` 会 `import bpy`。装 `bpy==4.0.0` 会报 `undefined symbol: rtcIsSYCLDeviceSupported`，报这个错的是同样的 5090 + cu128 环境（[#194](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/194)）。
   - 先 `pip install pymeshlab==2022.2.post3`（issue 里的解法）。
   - 还不行，就用我们第二轮的 trimesh 兜底。
   - 不管用哪种，MR 都当 sidecar jpg 拉回本机，再在 Blender 里打进 GLB。
4. **UniRig 坑**：输出的骨骼只有关节位置可信。骨骼方向全朝 +Y，坐标是 Y-up 原始坐标，也不带蒙皮。
   - 只取关节，在本机用 `skin.py` 重建骨架：子关节定骨尾，重算 roll，用包围盒对齐。
   - 先合并顶点，再做自动权重。
   - FBX 导出要用 Blender 4.2（bpy）。
5. 自检：跑 1 件 shape+paint 和 1 个 UniRig。确认 GLB 里有 baseColor，旁边有 MR，sha256 写进 manifest。通过了再跑全批。
6. 跑批：每完成一件，**马上 rsync 整个输出目录到 store**，并且本机核对。
7. 收尾：本机核对数量和 sha256 一致后才关机。首次重建的那次，关机后保存镜像。然后释放或者关机；连续关机 15 天实例会被自动释放，但镜像和 autodl-fs 都还在。

## 8. 需要用户授权的事项

1. **新开 AutoDL 按需实例**：RTX 5090，没卡时用同区 48GB 卡。**单次费用上限 ¥15**，全年预计 3 次，GPU 合计约 ¥10–13。同时授权保存 1 个私有镜像（≤30GB 免费），以及用 autodl-fs 存放约 22GB 权重（约 ¥7/年）。
2. （可选）**791 释放前开机约 15 分钟（约 ¥1）**：
   - 把 `/root/autodl-tmp/ambush3d/` 整个目录和脚本拉回 store；
   - 把权重拷到 autodl-fs；
   - 关机后对 791 保存镜像。这样下次就省掉首次重建的 1–2 小时。
3. （可选，降级）**混元 API 补救**：开通腾讯云混元生3D，补救总额上限 ¥30，只在 §5 规则触发时使用。
4. **Mixamo**：用 Adobe ID 登录（免费），只在 UniRig 失败时拿关节。

不需要开的账号：Featurize、恒源云、矩池云、RunPod、Vast、Modal、Tripo、Meshy、Rodin 等。

## 9. 下次怎样避免盘上数据丢失

- 每件产物生成完立即拉回 store（`ambush3d_*`），拉整个输出目录（GLB、obj、MR sidecar、nobg、日志、manifest）。第二轮只拉了 GLB，所以丢了 MR。
- 关机由本机核对后触发，远端不设定时关机。第一轮在 90 秒关机窗口里丢了 14 个文件。
- 跑批脚本先进仓库或 store，再上机。
- 释放实例前，远端和 store 的清单差异必须为 0。

## 来源（v1 的来源继续有效）
- Hunyuan3D-2.1 README（显存）：https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1 ；显存 issue：https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/85 ，https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/15 ，https://github.com/visualbruno/ComfyUI-Hunyuan3d-2-1/issues/9 ；bpy：https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/194
- 许可：https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE （排除欧盟、英国、韩国，月活超 100 万要另行申请）
- AutoDL：计费（含镜像计费）https://www.autodl.com/docs/price/ ，镜像 https://www.autodl.com/docs/image/ ，目录和文件存储 https://www.autodl.com/docs/env/ ，迁移 https://autodl.com/docs/migrate_instance/ ，数据保留 https://www.autodl.com/docs/instance_data/
- 国内平台对比：https://rentgpu.link/posts/autodl-vs-gpushare-vs-matpool ，https://rentgpu.link/tw/vs ，https://www.fwidc.com/news/44_231003.html ，https://linux.do/t/topic/2596442 ，https://featurize.cn/vm/available
- 海外：https://www.reddit.com/r/mlops/comments/1wln9m7/notes_from_22_paid_runs_on_four_gpu_rental/ ，https://www.reddit.com/r/StableDiffusion/comments/1vyze6r/best_budget_gpu_cloud_comparing_runpod_vastai/ ，https://modal.com/pricing
- 质量：https://www.reddit.com/r/aigamedev/comments/1tjfsry/ai_3d_generator_comparison_for_indie_games_meshy/ ，https://www.reddit.com/r/StableDiffusion/comments/1jk6nn3/3d_models_need_remeshing/ ；我们自己的结果：`/workspace/ambush/aline/round2/out/ROUND2_REVIEW.md`、`glb_clean/CLEAN_REPORT.md`
- 混元 API：https://cloud.tencent.com/document/product/1804/123461 ，https://cloud.tencent.com/document/product/1804/123447
- 权重大小：用 HF API 查的，tencent/Hunyuan3D-2.1 14.91GB，facebook/dinov2-giant 9.09GB（含两份格式），VAST-AI/UniRig 11.48GB（全仓库，只需其中的 articulation-xl）
- Mixamo、Cascadeur、HY-Motion、Tripo、Meshy、Rodin：见 v1 版本的提交 a39848f
