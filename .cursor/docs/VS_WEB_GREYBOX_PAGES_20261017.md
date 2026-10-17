# VS Web greybox → GitHub Pages（2026-10-17）

chatgpt:unavailable（Cloud Agent；无网页 ChatGPT 桥）

## 目标与来源

仓库所有者要求：公开可玩的在线灰盒页。授权范围仅限启用 GitHub Pages + 发布本 Web 构建；不合并 `main`、不动 PR #54、不改 keystore、不花付费托管。

## 范围

- 分支：`vs/web`（从 `vs/core` @ `fa6bd08`）
- 主场景：`ambush_vs/scenes/greybox.tscn`
- Godot **4.7.2** Web preset：`Thread Support=OFF`（无需 COOP/COEP）
- 部署：`https://hailinsu-create.github.io/ambush-loop/greybox/` + 根索引链到 `/greybox/`
- CI：`.github/workflows/deploy-greybox-pages.yml`（configure-pages / upload-pages-artifact / deploy-pages）

## 非目标

- 不合并 PR #54 / `main`
- 不改 Android keystore
- 不提交 secrets / build 产物（`**/build/` 已忽略）
- 不引入付费主机或需登录主机

## 实现要点

| 项 | 状态 |
| --- | --- |
| Web preset（landscape、adaptive canvas、CJK `web_ui_font.tres`） | 已实现 |
| 排除 `art/**`（灰盒未用的 3D/音频） | 已实现 |
| `weapons.csv` 改为 `importer=keep`（导出后 `FileAccess` 可读） | 已实现；W2/W3 仍通过 |
| 本地 headless 导出 `build/web/greybox/` | 已验证（~50MB） |
| Chromium smoke（页面 200、canvas 渲染、无 fatal console） | 已验证（本地） |
| Pages API `build_type=workflow` | **被拒**（integration 403） |
| `github-pages` 环境允许 `vs/web` | **被拒**（integration 403） |

## 验收门槛

1. 本地/CI 导出成功；W2=61、W3=17 隔离测试 exit 0
2. Headless Chromium：`/greybox/` 加载、canvas 非空、无 fatal 错误
3. 线上 URL 200 且可启动（依赖下方 Pages 设置）

## 阻塞：所有者需手动打开的设置

当前 Cloud Agent 的 GitHub token **无** Pages/Environments 写权限（`Resource not accessible by integration`）。请仓库所有者（或 admin）执行：

1. **启用 Pages（Actions）**  
   - UI：Settings → Pages → Build and deployment → Source = **GitHub Actions**  
   - API（需 `pages:write` 或 admin）：  
     `POST /repos/hailinsu-create/ambush-loop/pages`  
     body: `{"build_type":"workflow"}`

2. **允许 `vs/web` 部署到 `github-pages` 环境**  
   - UI：Settings → Environments → `github-pages` → Deployment branches → 加入 `vs/web`（或选 All）  
   - API：创建/更新 environment 的 custom branch policy，添加 branch `vs/web`

完成后推送/重跑 `deploy-greybox-pages` workflow；预期 URL：  
`https://hailinsu-create.github.io/ambush-loop/greybox/`

## 已知限制

- 首次加载约 **50MB**（wasm ~38MB + pck ~12MB，CJK 字体占 pck 大头）；手机流量/弱网较慢
- 单线程 Web 导出，移动端性能有限；landscape 可用，未做触控专用布局精修
- 线上启动验证在 Pages 启用前 **待验证**

## 当前状态 / 下一步

- **已实现**：preset、workflow、CSV keep、本地导出与 Chromium smoke、W2/W3 绿
- **待所有者**：Pages + workshop 环境分支策略
- **下一步**：Pages 打开后核对线上 200 与 Chromium boot；再更新本页为「已验证」
