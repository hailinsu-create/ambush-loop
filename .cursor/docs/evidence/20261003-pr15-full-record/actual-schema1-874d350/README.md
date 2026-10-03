# 实际旧 schema1 fixture 来源与跨 executor 重建

该二进制由历史生产源 **874d3501fdd2b34b0966472e22a9e43a28a1b3dd** 的 `command_record_replay_test.gd` 实际运行导出，没有从 schema2 记录降级，也没有升级旧记录。导出代码位于该固定提交脚本末尾：实际 yard 两波 WON 的 `BattleLog` 经 `var_to_bytes()` 保存；后续 FAILED/abort 的日志没有替换这份 WON 来源。

| 项目 | 实际值 |
| --- | --- |
| 文件 | `command-record-source-v1.bin` |
| SHA256 | `1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12` |
| 字节数 | 5418800 |
| 生成源 | `874d3501fdd2b34b0966472e22a9e43a28a1b3dd` |
| 引擎 | Godot 4.7.2 stable official ed1daf0bf，Linux headless |
| 生成脚本 | `ambush_loop/scripts/command_record_replay_test.gd` |
| 隔离 UUID | `0bcf92c368614cd386bd0be02ee9ad2b` |
| 实际结果 | 98/0，exit0，ERROR0；同目录 `run.log` / `run.exit` |
| 原统计 | battle terminal1283、34events、playback terminal1415、playback_schema1 |
| 官方 LibraryID | 无。此前官方 materialize 失败；未重试、未绕过 Library。 |

本文件随游戏仓库的证据提交；提交后的 Git 固定路径可用于精确 hash 复验。它不是 Library 文件，不能填写或猜测 LibraryID。父端安排的独立 QA 不依赖作者 executor 的本地文件复制。

若优先从历史 Git 固定源生成新的实际旧记录，使用独立 worktree 和 Godot4.7.2；不编辑制作源、不运行 Blender/资产制作脚本：

```bash
git worktree add --detach /workspace/ambush-schema1-874d350 874d3501fdd2b34b0966472e22a9e43a28a1b3dd
cd /workspace/ambush-schema1-874d350
AMBUSH_SCHEMA1_GODOT=/absolute/path/to/Godot_v4.7.2-stable_linux.x86_64
bash ambush_loop/scripts/run_isolated_test.sh "$AMBUSH_SCHEMA1_GODOT" editor_import
bash ambush_loop/scripts/run_isolated_test.sh "$AMBUSH_SCHEMA1_GODOT" command_record_replay_test.gd --headless
sha256sum ambush_loop/build/asset_review/pr15-runtime/command-record-source-v1.bin
```

必须检查两条命令的实际退出码，生成测试应为98/0、ERROR0；保留新的隔离 UUID、log、exit、report 与新二进制 hash。`command-record-report.json` 的 WON 行应为1283/34/1415，`source_binary.sha256` 应与新文件匹配。当前 `full_command_record_replay_test.gd` 可通过 `AMBUSH_LEGACY_RECORD_FIXTURE` 指向这份重建文件，检验旧 schema1 源的身份、前后 seek、20骨/root 和源不变。

**重建可重复验证格式和行为统计，不能声称每次重建具有上表的同一二进制 hash。** 历史 `BattleLog.begin_attempt()` 使用 Crypto 随机 UUID，场景启动产生真实 command clock；因此新的实际记录会带新的身份/启动时间。上表精确 hash 只属于保留的原始二进制。不得为匹配旧 hash 伪造 UUID、重绑旧事件到当前 run_id 或把新 schema2 记录转换成旧 fixture。

本轮只核对固定历史源的生成代码与已保存的实际生成收据，没有重新运行这项历史生成测试，也没有重跑已通过的15c正式项。独立 executor 的上述重建仍需该 executor 报告实际结果。
