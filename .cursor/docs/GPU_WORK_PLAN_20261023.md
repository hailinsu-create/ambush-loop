# GPU 工作方案 2026-10-23

来源：用户要释放 AutoDL 两台显卡机（791：359a49a1c3-4cda10df，RTX 5090；592：683045898b-caaa5b8f），以后不再保留自有 GPU 实例。本文定下以后哪些活要用 GPU、在哪做、花多少钱。状态：**规划，未执行**。本次没有开机、没有花钱、没有注册任何平台。

## 1. 现状和释放影响

**已完成**（两轮 GPU 合计约 ¥8.9，¥2.88/h，每个模型约 1 分钟、约 ¥0.05）：
- 72 个 Hunyuan3D-2.1 形状模型（6 人物 + 60 武器/配件 + 6 个人物随身武器，最后这 6 个没用）；本机 `glb/` 61 个、`round2/shape_new/` 14 个，清理版存在 store 的 `ambush3d_glb_clean`。
- 66 个 Paint 贴图模型：58 个好，8 个可用（`round2/out/ROUND2_REVIEW.md`）。
- 6 个人物：UniRig 关节 → Blender 重建 52/40 骨 → 自动权重 → 手 K 9 个动作 → 8 方向 128px 精灵和 WebP atlas（`cast/CAST_REPORT.md`、`hero/HERO_REPORT.md`）。
- 渲染在本机 CPU：EEVEE 约 2.44 s/帧，一个人物 864 帧约 35 分钟。**渲染不需要 GPU。**

**791 释放后会丢**（本机和 store 都没有）：

| 数据 | 数量 | 影响 |
|---|---|---|
| Paint 生成的 metallic/roughness 贴图（`*_metallic.jpg`、`*_roughness.jpg`） | 65 个模型 × 2 | 本机只有 mg_gunner 的 MR，其余只有 albedo |
| 去背景参考图 `nobg/*_v0.png` | 66 | 本机有原图（store `ambush3d_weapons/` 60 张、概念图 7 张），可以在 CPU 上重新抠图，影响小 |
| Paint 原始输出 `.obj` 和 sidecar | 66 套 | 本机有 GLB，影响小 |
| Hunyuan3D-2.1 环境和权重（shape、paint、DINOv2-giant、RealESRGAN） | 1 套 | 以后要重建 |
| UniRig 环境和权重（articulation-xl）、791 上的 Blender 4.2 | 1 套 | 以后要重建 |
| 791 上的批处理驱动脚本（manifest、逐个生成、FBX 导出） | 未计数 | 本机没找到副本，重建时要重写 |

592 上有什么：本机记录里查不到，**未核实**。

**建议**：释放前开 791 大约 15 分钟（约 ¥1），把 `/root/autodl-tmp/ambush3d/` 整个目录（不只 `*.glb`）和脚本拉回 store。这件事需要用户授权（见 §7）。不拉回也可以：MR 改在 CPU 上补（见 §3.3），不另花 GPU 钱。

## 2. 待做 GPU 工作清单

数量里标「预估」的，设计里还没定（第三关以后的新单位还没出设计）。积分按腾讯混元生3D 价目：每次 Normal 20 + PBR 10 = 30 积分，LowPoly+PBR 35 积分，纹理生成 30 积分，绑骨蒙皮 10 积分；预付 ¥0.1/积分，后付 ¥0.12/积分。

| 优先级 | 工作 | 数量 | 路线 | 预计积分（含重试） | 费用 |
|---|---|---:|---|---:|---:|
| P0 | 释放前把 791 的 MR、nobg、脚本拉回 store | 1 次 | 791 开机约 15 分钟 | — | ≈¥1 |
| P1 | 重出质量差的 3 件：eihandgranate_39（顶盖和拉环糊在一起）、pps43（背带缠成圈）、luger_p08（握把底部像融化） | 3 | 混元 API，Model 3.1 + PBR，每件 2 次 | 180 | ≈¥18（前 100 积分免费） |
| P1 | 8 件偏色：colt_m1911a1、panzerschreck、tt33、sten_mk2、mk2_grenade 用 CPU 调色；bar_m1918a2（枪托发蓝）、mg_ammo_box_34（冬季白漆）两件用纹理重生成 | 6 + 2 | CPU / 混元纹理生成 | 60 | ≈¥6 |
| P1 | 敌方重火机枪手 enemy_mg：设计 v2 §7.3 要三种敌人职责，现在 `enemy_mg` 贴图加载了但从没画出来，也没有 3D 模型 | 1 | 混元 API + 绑骨 | 80 | ≈¥8 |
| P2 | 第三关以后的新人物/敌人 | 预估 3 | 同上 | 240 | ≈¥24 |
| P2 | 新武器/配件 | 预估 10 | 混元 API | 450 | ≈¥45 |
| P2 | 第 3–6 关地标道具（泵体、水池管线、桅杆、油罐、检修梯、天线阵列、信号灯等） | 预估 16 | 混元 API LowPoly + PBR | 840 | ≈¥84 |
| P3 | 65 个模型的 MR | 65 | CPU 规则生成，**不用 GPU** | 0 | ¥0 |
| — | 院子、仓道等关卡建筑 | 6 关 | 本机 Blender 程序化建模，**不用 GPU** | 0 | ¥0 |
| — | 新动作：蹲、拿取、部署（设计 v2 §7.4 要九个状态，现有 9 个动作里没有这三个） | 3 × 7 人 | 本机 Blender 手 K，**不用 GPU** | 0 | ¥0 |
| — | 概念图、参考图、地面贴图 | 按需 | 自带的生图工具（60 张武器参考图就是这样生成的），**不用 GPU** | 0 | ¥0 |

**合计 ≈ 1,850 积分 − 100 免费 ≈ ¥175，上限按 ¥200（两个 1000 积分包）算。** 积分包有效期 1 年。

## 3. 每类工作的推荐路线

### 3.1 图生3D（新人物、敌人、武器、重出、道具）→ 腾讯混元生3D 官方 API（专业版，Model 3.1，开 PBR）
- 理由：
  1. 和现在的 Hunyuan 是同一系列，风格接得上。
  2. 一次就出带 metallic/roughness/法线的 PBR，补上现在缺 MR 的问题。
  3. 失败的任务不扣积分。
  4. 国内直接付款，生成内容归用户。
  5. 不用重建环境。剩下的活是按关卡零散来的，每次重开 AutoDL 都要付开机、拉权重、bpy 排错的时间。
- 社区意见：
  - Reddit 上 200 次生成的对比里，自部署 Hunyuan 只有 61% 能直接用（Meshy 78%、Tripo 72%、Rodin 81%），原话是 “free isn't free if it costs you time”。
  - 中文评测说混元重拓扑最干净，Tripo 贴图细节最好。
- 先试点：用开通时送的 100 积分重出 P1 的 3 件，过了 §5 的质量门槛再买积分包。
- 备选：AutoDL 按需开 5090，用 §6 的脚本重建 Hunyuan3D-2.1。只在两种情况下用：一批 ≥50 个，或者 API 试点没过门槛。
- 不推荐：
  - Meshy：免费版不能用 API，付款不支持支付宝。
  - Rodin：API 要 Business 套餐，模型面数很密。
  - fal.ai 的 Hunyuan3D 2.1 端点已经弃用。
  - SPAR3D：几何粗，PBR 估计不准。
  - HF ZeroGPU：要 PRO，失败了也扣额度。
  - RunPod、Vast、Modal 要开新账号、用外币付款，Vast 的机器会中途重启，比 AutoDL 没有优势。
- Tripo（$0.30–0.40/个，付费用户可商用，支持支付宝）只在混元 API 停服或涨价时才换过去。

### 3.2 重出和偏色
- 先在 CPU 上修：Blender 里对 albedo 调色相/饱和度/亮度，pps43 的背带直接删几何。
- 只有颜色改不对的（bar 枪托要换成胡桃木、弹药箱要去掉冬季白漆）才用混元「纹理生成」，输入现在的网格和参考图，30 积分一件。

### 3.3 MR/PBR 补全 → CPU 规则生成（释放前拉回的话就直接用原图）
- 理由：精灵只有 128px，又是夜间月光轮廓光。MR 只影响枪管和钢盔的反光，值不得为 65 个模型再开 GPU。
- 做法：
  - 按 albedo 的明度和饱和度分出金属和木/布两类。
  - 金属 metallic 0.8、roughness 0.45，其余 metallic 0、roughness 0.8。
  - 渲染前后对比 mg_gunner 的真 MR，差别看不出来就接受。
- 以后新出的模型由 API 直接带 MR。

### 3.4 场景和建筑 → 本机 Blender 程序化建模（CPU）
- 理由：
  - 关卡建筑要和格子、遮挡、高点规则对齐，AI 生成的网格对不准。
  - 社区说 Meshy 和 Tripo 做建筑效果很差，面数压不下来。
  - 仓库里已有 `art/environment_v2/` 80 个程序化 GLB 可以当起点。
- 单个地标道具（泵体、油罐、天线）走 3.1 的 LowPoly + PBR。

### 3.5 绑骨 → 关节位置用 Mixamo 自动绑骨（免费），骨架照旧在 Blender 用 `round2/skin.py` 重建
- 理由：
  - UniRig 本来就只有关节位置能用，换成 Mixamo 拿关节，效果一样，而且不用 GPU。
  - Mixamo 可以免费商用、用在游戏里，只是不能单独再分发原始文件。
- 备选：混元「绑骨蒙皮」10 积分一个，同样只取关节。社区口碑**未查到**。

### 3.6 动作 → 继续在本机 Blender 手 K（CPU），新增蹲、拿取、部署
- 理由：
  - 现有 9 个动作靠双手 IK 抓枪，握持误差 ≤0.05 m，这是剪影可读、不穿帮的关键。
  - 社区反馈 Mixamo 的步枪动作重定向以后手对不上枪，左手还有扭曲的已知问题，每个武器都要手修。
  - 文生动作 HY-Motion 要 24–26GB 显存，不带道具，许可也有地域限制。
  - 视频动捕（Rokoko Vision 每月免费 30 秒、DeepMotion）都要清理。
  - Cascadeur 免费版不能商用。
- Mixamo 只拿来当走、跑节奏的参考，不直接用。

## 4. 成本对比（同一批约 60 次生成）

| 路线 | 单价 | 60 个合计 | 固定开销 | 风险 | 来源 |
|---|---|---:|---|---|---|
| **混元生3D API 3.1 + PBR（推荐）** | 30 积分 ≈ ¥3–3.6 | ≈¥180 | 0 | 2026-07 起新购要迁到 TokenHub，TokenHub 上的 3D 价格**未查到**；默认 3 个并发 | [腾讯云计费](https://cloud.tencent.com/document/product/1804/123461) |
| AutoDL 按需 5090 自部署 2.1（备选） | ≈¥0.05/个 + paint | ≈¥5 | 每次重建约 1–2 h ≈ ¥3–6；关机后 GPU 不预留 | 开机可能没卡；bpy 坑；实例连续关机 15 天被释放 | [AutoDL 计费](https://www.autodl.com/docs/price/)、[数据保留](https://www.autodl.com/docs/instance_data/) |
| Tripo API | 30–40 积分 = $0.30–0.40 | ≈$18–24 | 0 | 外币/支付宝付款；积分不退 | [Tripo 价格](https://developers.tripo3d.ai/en/pricing) |
| Meshy API | 30 积分，要 Pro 及以上 | Pro $20/月起 | 月费 | 免费版没有 API | [Meshy 价格](https://docs.meshy.ai/api/pricing.md) |
| Rodin Gen-2 API | 0.5 积分 ≈ $0.75 | ≈$45 | 要 Business 套餐 | 面数密 | [Hyper3D](https://hyper3d.ai/pricing) |
| Replicate 2.1 | ≈$0.19/次 | ≈$11 | 0 | 社区维护的模型 | [Replicate](https://replicate.com/ndreca/hunyuan3d-2.1) |
| RunPod 4090 | $0.34–0.74/h | ≈$2 + 重建 | 网络盘另计 | 5090 难抢，社区 Pod 会被驱逐 | [r/mlops 22 次实测](https://www.reddit.com/r/mlops/comments/1wln9m7/notes_from_22_paid_runs_on_four_gpu_rental/) |
| Modal L40S | $1.95/h，每月 $30 免费额度 | 额度内 | 冷启动慢 | 比 RunPod 贵约 50% | [Modal](https://modal.com/pricing) |

自部署钱少，但时间多、出事概率高（第一轮就因为没有 bpy，paint 崩了只出了形状，还在 90 秒关机窗口里丢了 14 个文件）。剩下的活是零散的小批量，所以总价 ¥175 走 API。

## 5. 质量门槛（沿用现在的标准）
- 不接受粗糙的模型：对照参考图，评为「好」才进管线；「可用」的要先修好；「差」的重出，最多 2 次，还不行就换参考图。
- 人物不能是剪影：48px 手机截图里，8 个方向至少 7 个能认出持枪方向；服装细节要和参考图一致。
- 要有全套动作：9 个状态（idle/walk/aim/fire/hit/death/climb/prone/crawl），加上新增的蹲、拿取、部署；握持误差 ≤0.06 m，穿地 ≤0.05 m，拉伸 p99.9 ≤4.6。
- 武器只保留一份、只有 1 个连通块、开放边为 0；减面到 ≤3.5 万面，UV 不撕裂。

## 6. 以后重新开 GPU 的步骤（备选路线）
1. 机器选 5090 32GB。Hunyuan3D-2.1 形状要 10GB、贴图要 21GB，一起跑 29GB（[README](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1)）。24GB 的卡要分两步跑，或者开 `--low_vram_mode`。5090 要 CUDA 12.8 以上的 PyTorch 镜像。
2. 克隆 Hunyuan3D-2.1，`pip install -r requirements.txt`，编译 `custom_rasterizer` 和 `DifferentiableRenderer`。权重用 `HF_ENDPOINT` 镜像下载，放到 `/root/autodl-fs`（同地区共享，20GB 免费），不放数据盘，下次就不用重下。
3. **bpy 坑**：paint 的 `convert_obj_to_glb` 会 `import bpy`。装 `bpy==4.0.0` 会报 `undefined symbol: rtcIsSYCLDeviceSupported`（[issue #194](https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/issues/194)，同样是 5090 + cu128）。社区的解法是 `pip install pymeshlab==2022.2.post3`；我们第二轮用的是 trimesh 兜底。不管哪种，**MR 都要当 sidecar jpg 拉回来，再在本机 Blender 里打进 GLB**。正式跑批前先拿 1 件试，确认 GLB 里有 baseColor，旁边有 MR 文件。
4. **UniRig 坑**：输出的骨骼只有关节位置可信，骨骼方向全朝 +Y，坐标还是 Y-up 原始坐标，也不带蒙皮。处理方式：
   - 只取关节，用 `skin.py` 重建 Armature：子关节定骨尾，重算 roll。
   - 用包围盒把骨架和贴图网格对齐。
   - 导入时先合并顶点，再做自动权重，否则 bone heat 会全部失败。
   - FBX 导出要用 Blender 4.2（bpy）。
5. 跑批由 manifest 驱动：每完成一件就写结果和 sha256，**马上 rsync 到 store**（见 §8）。
6. 用完之后，系统盘保存镜像（30GB 内免费），权重留在 autodl-fs，然后释放实例。

## 7. 需要用户授权的事项
1. **释放前**：开 791 大约 15 分钟（约 ¥1），把 MR、nobg、脚本拉回 store。不授权就按 §3.3 在 CPU 上补，不影响后面的工作。
2. 开通腾讯云「混元生3D」（实名），领 100 免费积分，先拿 3 件试点。
3. 试点通过后：买 1000 积分包 ¥100，必要时再买一包，**总上限 ¥200**。
4. 用 Adobe ID 登录 Mixamo（免费），只用来拿新人物的关节位置。
5. 备选路线触发时：每次开 AutoDL 5090 不超过 ¥15。

不需要开的账号：Tripo、Meshy、Rodin、RunPod、Vast、Modal、Replicate、fal、HF PRO、Cascadeur。

## 8. 下次怎样避免盘上数据丢失
- 每件产物生成完立即拉回 store（`/cursor/stores/store-fbe0948f-.../ambush3d_*`），不要等整批跑完。
- 拉的是整个输出目录（GLB、obj、MR/albedo sidecar、nobg、日志、manifest），不能只拉 `*.glb`。第二轮丢 MR 就是因为只拉了 GLB。
- 关机由本机触发：本机核对数量和 sha256 都一致后，才发 `shutdown`。远端定时关机不可靠，第一轮就因此丢了 14 个文件。
- 跑批脚本在开机前先提交到仓库或 store，远端只放副本。
- 释放实例前，先对一遍远端和 store 的清单差异，差异为 0 才释放。

## 来源
- r/aigamedev，四家 200 次生成对比：https://www.reddit.com/r/aigamedev/comments/1tjfsry/ai_3d_generator_comparison_for_indie_games_meshy/
- r/aigamedev，生产数据和建筑问题：https://www.reddit.com/r/aigamedev/comments/1ucirid/meshy_vs_tripo_vs_rodin_vs_hunyuan_for_game/ ，https://www.reddit.com/r/aigamedev/comments/1wfyepq/tripo_3d_vs_meshy_for_asset_gen/
- r/aigamedev，绑骨和动作：https://www.reddit.com/r/aigamedev/comments/1v0ygjc/which_ai_3d_tool_actually_gives_engine_ready/
- r/StableDiffusion，AI 模型都要重拓扑：https://www.reddit.com/r/StableDiffusion/comments/1jk6nn3/3d_models_need_remeshing/
- r/StableDiffusion，GPU 云对比：https://www.reddit.com/r/StableDiffusion/comments/1vyze6r/best_budget_gpu_cloud_comparing_runpod_vastai/
- r/mlops，22 次付费实测：https://www.reddit.com/r/mlops/comments/1wln9m7/notes_from_22_paid_runs_on_four_gpu_rental/
- 中文重拓扑对比：https://www.top3d.ai/zh/learn/retopology-comparison-2025 ；三家评测：https://www.aitntnews.com/newDetail.html?newId=10814
- 混元生3D 计费：https://cloud.tencent.com/document/product/1804/123461 ；API Model 3.1：https://cloud.tencent.com/document/product/1804/123447 ；生成内容归属：https://www.tencentcloud.com/zh/document/product/301/78149
- Hunyuan3D-2.1 许可（排除欧盟、英国、韩国，月活超 100 万要另行申请）：https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE
- AutoDL 计费、数据保留、镜像、省钱：https://www.autodl.com/docs/price/ ，https://www.autodl.com/docs/instance_data/ ，https://www.autodl.com/docs/image/ ，https://www.autodl.com/docs/save_money/ ，https://www.autodl.com/docs/env/
- Tripo 价格和条款：https://developers.tripo3d.ai/en/pricing ，https://developers.tripo3d.ai/en/terms ，https://www.tripo3d.ai/zh/help/billing/what-payment-methods-does-tripo-ai-support
- Meshy：https://docs.meshy.ai/api/pricing.md ；Rodin：https://hyper3d.ai/pricing ；SPAR3D：https://stability.ai/news-updates/stable-point-aware-3d
- fal 和 Replicate 上的 Hunyuan3D 2.1：https://fal.ai/models/fal-ai/hunyuan3d-v21/llms.txt ，https://replicate.com/ndreca/hunyuan3d-2.1
- HF ZeroGPU：https://huggingface.co/docs/hub/spaces-zerogpu ；Modal：https://modal.com/pricing
- Mixamo 许可：https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400 ；步枪动作左手扭曲：https://community.adobe.com/t5/mixamo-discussions/mixamo-rifle-animation-left-hand-twisted/m-p/14145826
- Cascadeur 价格：https://cascadeur.com/payment/tariffs/ ；HY-Motion：https://huggingface.co/tencent/HY-Motion-1.0 ；Rokoko Vision：https://www.rokoko.com/products/vision
- UniRig：https://github.com/VAST-AI-Research/UniRig
- 混元 3D 网页版每天 20 次免费：https://www.wenweipo.com/a/202511/26/AP6926c912e4b051b3aa89e2db.html （网页版的商用条款未查到，所以不作为生产路线）
- AccuRig 的商用条款未查到，所以不采用。
