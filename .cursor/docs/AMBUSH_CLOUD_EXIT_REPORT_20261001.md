# PaperRoute Cloud 退出修复验证报告

日期：2026-10-01。起点 `e3faeb5808b5d1b0a62ad9b479aa3f576ec0c3bc`；实现提交 `75209831bbf86e9deb53e52137bff65c1025c908`；分支 `codex/paperroute-cloud-exit-20261001`，Draft [PR #8](https://github.com/hailinsu-create/ambush-loop/pull/8)，base `codex/cloud-main`。没有合并任何 PR，也未更新 `codex/cloud-main`。

## 结果与结论边界

新增独立 Xvfb + 显式 OpenGL + factory-startup 的云端 Blender 包装器，默认两线程，保留 `--python-exit-code 1`。既有生成器、网格、材质、游戏资产和玩法未改变。bootstrap 系统依赖明确加入 xauth；环境网络配置没有修改。

当轮使用官方 SHA-256 校验后的 Blender 5.2.2 LTS（`d13f752e3b9c`）、glTF CLI 4.5.1、Godot 4.7.2。原 `--background` 路径重现了 `EGL_BAD_MATCH`，但本实例完整生成后 **正常退出 0**，没有复现历史退出挂起。因此，历史 143 的具体根因仍未定论；不能写成已复现并彻底根治。新 Xvfb 对照及实际安装器 heredoc 包装器各完成一次完整生成，均正常退出 0、输出 `Blender quit`，没有 EGL 错误。新路径提供了当轮干净退出证据。

## 实际验证

| 检查 | 实际退出码 / 结果 |
| --- | --- |
| 原包装器等价命令，fresh baseline 输出 | 0；含 EGL_BAD_MATCH，未挂起 |
| Xvfb/OpenGL 对照，fresh xvfb 输出 | 0；四个产物完整，无 EGL 错误 |
| 从实现安装器提取的实际包装器，fresh wrapper 输出 | 0；四个产物完整，无 EGL 错误 |
| `--python-expr 'raise RuntimeError("EXPECTED_LOOK_FAILURE")'` | 1（预期失败）；未伪装成功 |
| PATH 不含 Xvfb 时实际包装器 | 1（预期失败），明确缺依赖 |
| `gltf-transform inspect yard_crate.glb` | 0；glTF 2.0，GLB 62680 字节 |
| PNG 完整解码、尺寸、非空内容及 GLB header/length 检查 | 0；turnaround 960×480、iso 256×256、top 256×192 |
| 三次 PNG 解码像素比较 | 全部相同；文件字节 hash 不同，不能以 PNG 文件 hash 宣称像素改变 |
| Godot 4.7.2 headless editor import | 0 |
| 隔离 Accept→Yard gate | 0；TEST_STORAGE_ISOLATED，ACCEPT_CTA_FLOW_OK level=yard frames=1 |
| `bash -n` 两个修改安装脚本、`git diff --check` | 0 |

生成命令均以 `timeout --kill-after=10s` 为外部失败守卫（baseline 180s，新路径 240s）；它们在期限内自行退出，未触发 timeout/强杀。不会因产物存在而忽略非零退出码。

新生成 turnaround、iso/top 均已目视检查：三视 clay/shaded 布局完整，木板接缝与铁条可见，AMMO 文字保留；iso/top 透明背景与预期视角完整。该切片仅验证 art-study 管线，未改变游戏内资产，因此没有声称取得新的游戏内截图或完成 Look/Android 验收。

Xvfb 已无运行中的 helper；当前容器 PID 1 未回收三个已退出的 Xvfb zombie 记录。它们不占用显示服务，记录该运行时限制，不伪称完全无进程记录。

## 可复现步骤与证据

仓库根目录，安装器更新后由环境 setup 安装/刷新工具；确认 `blender --version` 是 5.2.2、`gltf-transform --version` 是 4.5.1，PATH 含 xvfb-run/xauth。

```bash
study_dir="$(mktemp -d)"
cp ambush_loop/ArtSource/build_yard_crate.py "$study_dir/"
timeout --kill-after=10s 240s blender-headless --python "$study_dir/build_yard_crate.py"
gltf-transform inspect "$study_dir/yard_crate.glb"
bash ambush_loop/scripts/run_isolated_test.sh /absolute/path/to/godot accept_cta_flow_gate.gd
```

本实例为尊重文件系统权限，将官方 Blender、通过 apt 签名元数据下载并解包的 Xvfb/xauth 与 npm 工具放在 `/workspace/ambush-environment`，没有改 HOME、系统目录或代理。包装器从提交的安装器 heredoc 原样提取，旁边链接固定 Blender；安装器全流程（默认 HOME 路径）未在此实例重新执行，不将该检查冒充新实例部署成功。npm 首次因默认 HOME cache 不可写失败，改为 workspace cache 后安装成功。

日志、实际图像、GLB 与 checksum 摘要保存在 [当轮证据目录](../../ambush_loop/docs/cloud_exit_20261001/)。`checks.json` 记录实际退出码；`artifact-check.json` 记录图像及 GLB 校验。Accept gate run ID 为 `ea69370b148040e5a42608cc9e2c08a7`。导入产生的本轮未跟踪 `.uid` 已清理；没有纳入游戏源码改动。

## 部署、外部评审与剩余事项

环境历史 bootstrap 固定 `5f6cdff`，不会自动获得修复。**本轮仅 GitHub 分支上的实现和当前实例验证通过；未修改已发布环境配置或网络权限，未发布新快照，也未验证新任务安装。** 后续环境维护需采用评审后的精确修复提交并刷新包装器，不能把旧 bootstrap 的健康状态当作新部署完成。当前读取的配置域名列表未包含 download.blender.org；复用现有快照工具或由环境维护核对既有授权来源，本轮不增域名、不申请扩网。

外部 PLAN/REVIEW：`unavailable`，待按 [GitHub 精确来源评审方案](AMBUSH_CLOUD_GPT_REVIEW_PLAN_20261001.md) 补齐。该方案第三个提交为 `2e3cd841839c363fb3144064fb3301af14ce987d`；本报告作为后续独立证据提交，不冒充已评审源码。历史评审、原本机 C2C doctor 和网页服务正常均不批准本轮。

后续：取得当前精确实现/证据 SHA 的外部 GPT 反馈；再在用户选定的发布环境维护中部署并复验。Android/vivo、触控/音频/内存门及旧 AudioTrack 根因继续待本机设备证据，不在云端标记通过。
