# PR15 fresh Web六关13波与同Site更新计划

2026-10-05 当前 source-only driver 入口：[原输入契约](AMBUSH_PR15_WEB_NATIVE_INPUT_DRIVER_20261005.md) / [机器 spec](AMBUSH_PR15_WEB_NATIVE_INPUT_DRIVER_20261005.json)。固定 dab8705/game tree4f49/同Site version2；明确 Continue 先加载 next 再 handoff、原 replay 默认2×、六新 record 无旧 a05 依赖、教学 preview attempt 与获胜 attempt 不拼接。当前独立 QA 持有存储复验重活窗口，root只做本包轻检，driver/bridge/export/fresh13/六新whole全UNRUN；主 QA 工作树冻结b46。正文旧1d17/未部署段落保留为历史，不作为当前执行身份。原八件 Library helper发现入口阻塞与支持但不适用本批的单文件 schema见[精确阻塞报告](AMBUSH_PR15_LIBRARY_TRANSFER_BLOCKER_20261005.md)。

2026-10-05 后续状态：独立 QA 已 END 释放窗口；800ms 保存失败已按 [storage repair](AMBUSH_PR15_WEB_STORAGE_REPAIR_20261005.md) 封存修复/有界实际浏览器结果。**最终 dab8705 / 游戏树4f49a7c / 同 Site version2 已发布**，取代本计划最初的固定1d17候选/未部署状态。以下 fresh13 自然玩家流程与预算仍有效、尚未执行；Library 原件交接与独立 PCK32B 尚有 blocker，不将本地路径当交接。

2026-10-05，状态：**source只读计划/发布准备，fresh campaign、候选运输打包及部署均UNRUN**。父端已把重活窗口转交独立QA01a108c9，验固定WebGL原bad/new、浏览器输入/触控/音频gesture/存档刷新与yard全1×/2×。本作者不并发引擎/浏览器/性能工作、不继续原生优化。本计划存于独立稀疏规划工作树，不移动主QA工作树HEAD40b7007。

固定修复source `1d17a16156d2afae0cbdd77cf73030a57f953ada` /game tree `b5ebb0b2f7ddc1901e02a9843d1791164aee98ec`；已封存交付40b7007仅native合同/导出/原native六关历史seek/focus，不能折算新Web胜利。独立结果未收到，网页GPT PLAN/REVIEW unavailable。本计划不预写accepted/green。

## 执行入口、所有权与边界

独立有界QA实际END并确认结果后，先据其source/范围处理必要阻碍；通过即可按授权更新**同一私有Site**修正版，不必等待此fresh13计划才修复已知v1。发布不等于fullWeb/FINAL验收。若其发现代码问题，另开最小固定修复切片，重验对应门，不能直接把计划目标换成通过状态。

后续fresh13使用新的root自有持久浏览器profile、唯一origin/URL路径与固定完整Title包；不触碰独立QA/用户正式站点已有浏览器存档、不清其IndexedDB。首次无seen/unlock/progress，原Start→yard简报→全部教学→SCOUT。使用实际CDP键鼠/触控协议事件，source-informed策略标明不是陌生人playtest。只读坐标/状态观察桥若需要，只在新的隔离debug stage，生产所有字节等1d17，桥哈希和observer成本单列；生产release入口另核。禁止用已有web_qa_bridge的load_record/restart_scout动作作为fresh13。

禁止在fresh13赋phase/tick/HP/ammo/inventory、直接load_level/record_win/mark_tutorial_seen、reference/vacuum helper或手调process/sim_step来通关。campaign_replay_test是原生模拟fixture，不能直接移为Web正常战。first_visit_journey_test的实际取枪/走路/掩体/朝向/补给/点击策略可只读参考，Web不调用其XTest/OS.execute；全部指令经真实原UI，main原process/callback自然推进。

Root仍拥有main/runtime loader/presenter/ViewState/replay/UI/Web运输/共享测试；资产作者仍拥有源/generator/GLB/atlas/Blender/作者manifest。只消费验收资源及sidecars，不重新导出制作资产；不merge/混入高度PR。运行原生清档测试仍须isolated wrapper，当前不运行。

## 六关13波矩阵及自然流程

每关开始均原SCOUT；后续波通过原SWEEP按钮进入ALERT，实际代码没有每波重回SCOUT，不造额外SCOUT边界。正常失败保留结果/日志/源record，原UI可重试；只统计实际自然赢过的波，不能把前次失败与后次成功拼成同一次13波。每关独立attempt，单关各波稳定attempt/global时间，frame_seq与event seq连续。

| 关卡 | 原波数 | 参考掩体/朝向（仅玩家输入策略） | 胜利后应保存的下一关 |
| --- | ---: | --- | --- |
| yard | 2 | 1/2/5；90/180/180 | warehouse |
| warehouse | 2 | 1/3/5；180/0/180；原埋伏/首波SWEEP补给 | pump |
| pump | 2 | 1/4/5；90/0/180；原门/补给UI | railcut |
| railcut | 2 | 1/4/5；270/270/180；原背包策略及弹药包 | depot |
| depot | 2 | 1/4/5；270/270/180；原取雷/近距离放置 | radio |
| radio | 3 | 1/4/5；270/90/270；原取雷/近距离放置 | complete=true；Continue禁用，全关可重玩 |

实际取枪三家族、手雷/雷/弹药包依关卡原库存。观测取物/行走/装备实际事件、武器ID、弹药池和HP，不直接写变量。A/D按原MG8度/其他15度量子，达到合法最近方向而非赋精确角度。ALERT/P暂停锁与SCOUT/SWEEP合法动作沿用冻结契约。每波原自然ALERT→SWEEP，原走近掉落补给、再部署和下一波/撤离；最终WON才能读取原record_win结果。

冻结初始有界期限：每次单项UI/走路最多120 wall秒，每波自然ALERT最多300 wall秒，单关玩家流程最多900 wall秒（含至多两次原UI重试）；以浏览器controller单调wall计时，不能用可能慢于wall的GodotTimer作唯一截止。超时保存原状态/console/record并FAIL或BLOCKED，不强制终局、不静默延长或提高速度补绿。六关按关封存、保留同一campaign存档链，不并行性能引擎。

每关至少保存Title/简报/教学首访证据、armed SCOUT、每波ALERT/SWEEP/真实WON、phase/attempt/wave/local tick/global tick/seq/record hash、原console/network/浏览器与viewport/DPR/输入动作时间。截图在实际状态确认及两次引擎present后；phase取样与原图有明确身份，不把滞后帧算正确。

## 解锁、设置与reload矩阵

代码依据：GameSettings.record_win保存cleared+下一level_id，末关complete=true；main._save_progress在WON不覆写next；Title按cleared/complete禁用锁定项，has_progress在complete时false。settings包含mute/music/sfx/force_touch_hud/quality与逐关seen。main._return_to_title仅换Title；WON回放退出返回原WON。以上是source契约，不是新Web持久化通过。

1. 首访核六行、仅yard可选、Continue禁用、教学未读；先用原设置UI改静音/音量/触控开关/standard或power_saving，记录值与只读配置hash。原UI恢复standard后跑固定视觉，另记录settings持久化，不混作A3比较。
2. 每关真实WON后只读复制原 `user://ambush_loop.cfg` / `user://ambush_loop_settings.cfg`，记录内容/hash/自然写入时刻；返回Title核本关cleared、下一关unlocked、之后关仍locked，Continue目标为下一关。
3. 同origin真实reload后重新启动engine，核相同cleared/next/settings；close/reopen同自有profile再读回至少yard后与最终radio两个检查点。对每关reload留实际WASM初始化/网络cache与存储错误；FS内存读取不等于IndexedDB持久化。
4. 用原Continue进入下一关；新关未读教学仍应呈现，已读关重玩不重复教学。下一关SCOUT仍原knife-only，不能把前关战斗库存当checkpoint恢复要求。
5. radio原WON/credits后返回Title并reload，complete=true、六关解锁、Continue禁用；任一clear/best stats不能凭调用record_clear_stats来人工解锁。重玩已清关只核UI合法，不额外计作13波胜利。
6. 刷新当前SCOUT/ALERT/REPLAY的对照只承诺现有campaign checkpoint和settings；新attempt/教学状态按原行为记录，不要求内存battle/replay恢复。断写/拒绝存储若未实际可控测试，明确UNRUN，不用helper主动force_fs_sync补绿。

固定release index.js只读可见GodotFS/IDBFS、初始化load与sync/错误路径；mount没有autoPersist配置，不能凭库含autoPersist符号断言持续自动落盘。验收以原保存后的真实reload/reopen读回为准，留实际等待时间与错误。拒绝/消失不强行替用户开浏览器权限。

## 六个fresh Web记录及完整回放

每关自然WON后，只读保存原BattleLog全部字段的var_to_bytes副本与SHA256：attempt_id/events/snapshots/terminal_tick/terminal_reason/playback_schema/playback_snapshots/playback_terminal_tick；标producer为新Web source1d17、profile/origin/真实输入链/阶段时间。随机attempt与输入时间不同，不能要求逐tick/事件数量等旧a05 native参考。

每个新记录在原回放按钮/UI完整播1×、2×，从真实0到原terminal自然停止；实测P暂停/继续、正反scrub与事件focus。observer只读，不manual tick/scrub/refresh推动播放。检查全局单调时间、唯一attempt/wave/seq/event_id、latest同tick帧、未来事件cutoff、实际3D roots/20bones/武器/工具与现场身份，原record和live simulation前后不改；原WON返回的合法progress写入另计，不能误作模拟改写。

完整回放wall期限 `max(180s, 6×record_duration/rate+30s)`；其作用是有界收尾，不是放宽实时速率/33.333或16.667ms预算。observed terminal wall取真正最后callback，分离轮询尾部、加载/observer耗时与softwareWebGL环境，不能宣称手机FPS。超时保全原rows，不把partial算whole。真旧schema1的三选择/完整播放另用原hash-pinned旧记录消费fixture，不计入fresh13。

## 同一Site正式更新准备

[更新spec](AMBUSH_PR15_WEB_SITE_UPDATE_SPEC_20261005.json)固定当前v1/game843f+transportfa188/SiteGit63642与新game1d17/既有release及PCK hash。Site原生02:00:55→02:00:56 UTC只读回读active/owner/custom revision1，仅owner1、外客0、群组0；默认private不改。旧一次cloudflare_artifact部署和原tar/唯一证据均保留，不归因Vercel容量警告、不删历史。

**以下均UNRUN，待独立有界结果确认及窗口释放：**

1. 用现有fa188同字节packager，只打包既有1d17 release一次到新 `.../1d17.../site-candidate/dist`；不重起engine/Blender。命令：`python3 /workspace/ambush-pr15/ambush_loop/tools/package_web_site.py <1d17-release> <new-dist> --source-sha 1d17a16156d2afae0cbdd77cf73030a57f953ada --game-tree b5ebb0b2f7ddc1901e02a9843d1791164aee98ec`。核PCK38,074,644/SHA07a1、两片整拼接、WASM原fc746、12allowlist文件≤25MiB、完整Title与安全hash运输；精确新总大小在实际生成后填，不能预造SiteSHA/version/archivehash。
2. 新运输包必要localhost启动检查仅在QA窗口释放后，源码/console/输入证据沿用正确固定映射；不额外创建preview站点。正式origin验证由已有授权独立browser通道补，不绕过代理CONNECT拒绝。
3. 当前SiteGit已存在main/63642。原首次helper的`assert not .git.exists()`不适用；更新必须检查现有branch/remote/head/clean与同project hosting.json，不能重新init/force/改remote或覆盖未经核对的远端变化。新token仅准备好后调用原生create_source_repository_write_credential(project_id)，省略publish_on_push，短期token隐藏stdin/内存/子进程http.extraHeader，不复用已过期旧凭证、不持久化/打印。
4. 更换12个dist运行输出及仓库BUNDLE-IDENTITY（metadata不进runtime archive），记录旧v1为rollback候选；不引入证据/录像/记录/profile/cache/TPZ/制作源。正常commit/push现有Site main、ls-remote精确核新commit；与游戏main/PRmerge无关。用该新commit的`.openai/hosting.json`与dist制作固定tar，13regular files逐字节等git show，不把工作目录未经提交字节上传。
5. 已知owner-private时仅一次原生save_version_and_deploy_private(same project_id, actual new commit_sha, archive absolute path)。如凭证意外返回accepted publish-on-push，遵循其已接受窗口观察匹配version/deployment，不能再显式save/deploy重复发布；出错含saved_version_id则保留并用同version重试deploy，不盲目重新save。只对非终态查status，准确保留工具返回不透明ID。
6. publish成功后保留当前新version及旧v1回滚关系，parent统一发送同一稳定URL与[精简玩家说明草稿](AMBUSH_PR15_WEB_PLAYER_GUIDE_DRAFT_20261005.md)，附source/实际已验/软件WebGL速率范围。不把旧v1当最终发给用户，不改ACL、不清唯一证据。若origin仍阻塞，明确限制，不能用发布成功替代host验证。

本次实际只读规划与轻量Git/语法/metadata检查另留receipt；候选包、token、Site source push、版本/部署尚无新实际记录。下一重活须以父端QA END与结果为起点；此doc提交不更改ambush_loop tree。完整Web/FINAL/fullsmoke/all-art/A3预算与APK仍按既有清单分开推进，APK之后再谈模拟器/真机。
