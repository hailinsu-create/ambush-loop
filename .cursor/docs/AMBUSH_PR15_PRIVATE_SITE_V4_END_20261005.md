# PR15 同私有Site v4必要修复更新 END

2026-10-05，父端明确授权在原yard consumer包END后同站一次必要更新，现 **succeeded**。原yard END交付 **05469c5e74649eda10b174baf547a7ca4f35cfaa**，source1ec/tree1e8保持；本次不增加产品代码或资产、不新站/preview、不merge/公开。采用[Sites skill](skill://plugin_connector_1p_689987207de08191979cf68eca2941c6/sites/SKILL.md)同站source/publish流程，packaged helper资源在此环境不可读取，沿用此前已验的精确Git fallback，凭证只在隐藏stdin/进程内存，未写token/签名URL/owner联系方式。

| 实际交付字段 | 回执 |
| --- | --- |
| 原project / URL | `appgprj_6ac2e89b4db08191b308c175371ee7c6` / https://ambush-loop-game.lning791548.chatgpt.site |
| 生产source / game tree | `1ec3198e9c0db367af96fc264604c5a286003b5e` / `1e8af45ee23098f763acc139b56f8f7e0f41665a` |
| Site source commit | **da59df8415b8f70690ea815bed8917948abd3160**，正常push与ls-remote精确一致；原v3 commit87cccf2152ce112c36a704efa332f16e7692867b保作rollback |
| saved version | **4** / `appgprj_6ac2e89b4db08191b308c175371ee7c6~appgver_e9c4d837ee5081918417404a7bd96f83`，get_version source commit exact |
| deployment | `appgdep_6ac3d5fa40688191afcc315288780e61`，native **succeeded / 16:53:30.987805 UTC**；单次save_version_and_deploy_private，无重复发布 |
| ACL前后 | owner角色、custom owner单人allowlist、无group/external、revision1；实际IDs/roles/allowlists逐项比较exact，持久回执只存计数 |
| 原production PCK | 38,096,256bytes / **0eabd893591bc97c6e7ad897e370759ba58b6e36419d47e80a0aefce638c6523**，与已验debug production PCK SHA相同；QA observer/raw/paired cfg不在包 |
| runtime transport | 12files / **48,487,245bytes**，PCK两分片重组exact、WASM gzip解压exact、每file<25MiB；HTML/JS实际node语法检查0 |
| 本地发布tar | 13 payload / **48,506,880bytes**，SHA **e62ee8b3ea3a3e54c0d04e712565e59286ba897f856639c9a8bebfceec1736e1**，每payload与推送commit逐字节一致 |
| server archive元数据 | 同为13files/48,506,880bytes，content_hash **2502ad6f6acf036cd20bc97ff7306d2b0deaf9323410706fcc7a814502b57327**；与本地tar哈希不同，**没有独立下载/逐payload比较，不解释成已证序列化差异，也不称hosted PCK身份门通过** |

实际命令均在证据目录：`python3 …/export_release.py` 调官方4.7.2 `--headless --audio-driver Dummy --path /workspace/pr15-replay-save-stage-1ec-20261005 --export-release 'Web Game' …/release/index.html`，16:45:55.098412→16:46:00.528114 **actual0/E0/S0**、独立XDG、cached资源，无制作generator运行。`python3 …/package_site_candidate.py` **actual0**，16:47:10.818922→16:47:14.288049。两次 `python3 …/site_source_workflow.py` 以隐藏stdin接凭证分别open/package，均最终actual0，远端87cc→da59与13项tar内容actual核。随后native save/deploy terminal success、get_site v4/ACL exact、get_version v4/source exact；不另开浏览器或访问preview。

v3→v4纯PCK MD5/SHA核对：产品变化是 `scripts/main.gdc`；新增未调用的回归测试 `.gdc/.remap`，uid/class cache相应变化，53完整class块相同，其他生产payload/资产逐字节一致。最初纯audit过严地只允许main，**actual1**；原增量/原因保留，完整声明allowlist重核**actual0**，没有重导出。package receipt中scope文字复制残留source8532，而实际source/tree/文件全部1ec；原receipt保留，另存scope correction，未重新打包/改bytes。export wrapper旧“cached QA export”字样也是复用标签，实际pure stage/PCK及QA排除由独立payload证明，不将其解释为部署QA。

如需进一步闭合server archive/正式origin PCK，须以v4实际返回的file pointer/source为输入另做独立比对；当前通用download_file上限32MiB，不能拉48.5MB包，因此本轮未尝试注定超限的下载、不绕过host/private访问。native成功仅认部署/source/ACL，既有origin与其他FINAL门不借此补绿。凭证/签名截图URL不入库；本回执不是人工听感/设备或最终fresh13通过。

19份[实际证据manifest](evidence/20261005-pr15-site-v4-update/manifest.json)封150,284bytes，各file size/SHA精确复核；不含实际token或签名截图URL。引擎仅一次release export且已END，没有browser/Godot/HTTP待收。接下来是[有限REPLAY HUD分段计划](AMBUSH_PR15_REPLAY_HUD_SEGMENT_PLAN_20261005.md)，**未实现/未运行**，不先下唯一瓶颈结论。R5 source/52语义/20骨/socket/3LOD及制作单写接口保持，无新增资产请求，网页GPT PLAN/REVIEW unavailable。
