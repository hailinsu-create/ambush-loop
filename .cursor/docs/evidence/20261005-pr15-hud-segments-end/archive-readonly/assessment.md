# Site v4 archive：独立只读来源与成员核查

2026-10-05。范围只限父端给定 Site/version、sediment 文件引用和既有本地 tar。不运行浏览器、引擎、导出、部署；不访问 Site origin/PCK/截图 URL；不修改网络、ACL、产品、资产或共享文档。没有产品提交。仅本目录报告/脱敏证据产生写入。

## 结果与关键限制

**服务器 v4 元数据已通过授权连接器确认；服务器归档字节未取得，因此服务器成员内容仍未知。** 不能据相同 size/file_count 或本地检查成功声称服务器成员一致，也不能解释两个 SHA 的差异来自 padding、tar 重打包或任何未观察原因。

实际工具及结果：

1. `skills.read` 读取当前 Sites skill；仅适用只读来源核查，未进入凭据/源码写入/发布流程。
2. `sites_get_site_version` 对给定 opaque project/version 成功，确认 version_number=4，source.commit_sha=`da59df8415b8f70690ea815bed8917948abd3160`，archive_format=tar，size_bytes=48,506,880，file_count=13，服务器声明 content_hash=`sha256:2502ad6f6acf036cd20bc97ff7306d2b0deaf9323410706fcc7a814502b57327`，存储引用为父端提供的同一文件。
3. `download_file` 仅对给定 sediment file ID 发出一次授权下载请求，实际返回 `file could not be authorized or resolved`。这次没有报 32MiB 超限，不能把错误改写为超限。该工具已知最大 32MiB，小于本归档 48,506,880B，这是另一项能力限制；没有原服务器文件落地。
4. `exec_command` 内标准 Python tarfile/hashlib/json/gzip 只读本地既有 tar；不解包到产品、不执行任何成员脚本。完成下述 32 项静态内容/清单核对，32 passed / 0 failed。此数字不是浏览器或游戏运行测试。

没有获取新 URL、源凭据、token，也没有把响应中可能附带的截图地址等字段写出。没有修改既有代理配置、重试 Site origin 或尝试其他下载绕行。

## 本地给定 tar 的实际证据

文件：`/workspace/pr15-web-artifacts/1ec3198e9c0db367af96fc264604c5a286003b5e/ambush-loop-site-v4.tar`。

- 实际 size=48,506,880 bytes，SHA256=`e62ee8b3ea3a3e54c0d04e712565e59286ba897f856639c9a8bebfceec1736e1`，与父端给定本地值一致。
- tarfile 枚举 15 个成员：13 个普通文件，2 个目录（`.openai`、`dist`）。13 与服务器 file_count 数值吻合，但只有本地成员名称、内容和类型被实际读取。
- 无绝对/父级路径、符号链接或硬链接。所有普通成员小于 25MiB；最大 PCK part00 为 24MiB。
- `.openai/hosting.json` 确认相同 project_id，static.directory=`dist`。
- `dist/game-build.json` 声明 source_sha=`1ec3198e9c0db367af96fc264604c5a286003b5e`、game_tree=`1e8af45ee23098f763acc139b56f8f7e0f41665a`、full_Title_entry=true。这些是归档内字段；服务器 source.commit_sha 按服务器字段单列。未使用这两个不同字段证明同一仓库/同一源码，也没有虚构远端 commit 树的逐文件比较。
- 归档普通文件精确等于 build manifest 的 11 个 dist 文件，再加 `.openai/hosting.json`、`dist/game-build.json` 两个元数据文件。11 项 manifest size/hash 全部与实际成员匹配。
- 两个 PCK 分片按 manifest 顺序**仅在内存流中**拼接计算：38,096,256 bytes，SHA256=`0eabd893591bc97c6e7ad897e370759ba58b6e36419d47e80a0aefce638c6523`，匹配 pck 总记录；前四字节十六进制 `47445043`（GDPC）。没有启动/运行 PCK，也没有声称验证内部游戏行为。
- WASM gzip 按流解压仅计算摘要：39,514,754 bytes，SHA256=`fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`，匹配 manifest raw hash；未实例化 WASM。
- HTML 静态内容包含两个分片路径、DecompressionStream 与 engine.startGame 调用。只读存在性检查不证明页面加载/运行成功。

本地普通成员内容摘要：

| 本地 tar 成员 | bytes | 实际 SHA256 |
|---|---:|---|
| `.openai/hosting.json` | 106 | `f354c402dcc3c4b2534e85cb9666e32cd6e1fb68ecd75261ea6acbdc65ef63ee` |
| `dist/_headers` | 144 | `7d6031e4e2fecd4548ee10dc76893e23d9b52d2c7064c9ba2a4dfa235a35f2ac` |
| `dist/game-build.json` | 2440 | `4761fffc1a681a40396ec2bb9ed92b1a1a5edf783b44856220cbbfa612fe8910` |
| `dist/index.apple-touch-icon.png` | 10015 | `8d7beb9a029424558ffa8f9cc76b6aad2e96aa91060153e4421b52a14c3239b5` |
| `dist/index.audio.position.worklet.js` | 2973 | `be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8` |
| `dist/index.audio.worklet.js` | 7298 | `5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3` |
| `dist/index.html` | 8087 | `b2c1e84cc5c52e8652f9d949ff06d51cf889dd0fef389cd8739554d0eb838c03` |
| `dist/index.icon.png` | 4016 | `f5b83b2e20897a943ef34368a3bbe2fdbc85af0b67616d234d5850842086979d` |
| `dist/index.js` | 279815 | `33c94cb3175f3333b82e2a3be5e8e86f77986f0aa2042b1631f6367a4e5bb6ba` |
| `dist/index.pck.part00` | 25165824 | `ae9bcfa8230188f5789b16ad1324a3cfc133cec8445b3cd0f7cc2beda16448a4` |
| `dist/index.pck.part01` | 12930432 | `bafd4cca2b1e25dbf55748a72e7849a1a464c00ebc2925a154577672dcb4be1a` |
| `dist/index.png` | 21443 | `3cb4495c0b98dfbe4b663cbf2b6836473572339beb66d902367893162a70be0e` |
| `dist/index.wasm.gz` | 10054758 | `8032306d52d52497129dce5b767baacb660d504bdde28668b1c1337b717eacd8` |

## 可成立与不可成立的结论

可成立：连接器记录 v4 来源为指定 pushed commit，保存了 13 文件/48,506,880B 的 tar 元数据；给定本地 tar 自身摘要核实，且其清单、PCK 和 WASM 内容内部一致。

不可成立：服务器 tar 原始字节 SHA 独立复算、服务器成员名称/类型/逐文件 hash 与本地相同、当前生产页面实际提供这些成员、已运行游戏或已通过浏览器 QA。服务器声明的内容哈希与本地整 tar 哈希不同；当前只记录这个观察，不诊断其原因。

取得可比较证据的合法下一步仅是平台提供对此确切归档的正式授权且适合大小的文件读取入口，或由授权存储方提供该确切对象的成员清单/逐成员摘要。不能猜 ID、手工取签名 URL、绕 origin 403、改变网络策略，或重新部署制造替代对象。本包没有要求/执行这些动作。

## 留存

- [server-metadata-sanitized.json](/tmp/pr15-site-v4-archive-readonly-20261005/server-metadata-sanitized.json)：白名单服务器 provenance/archive 元数据、实际下载失败及能力上限。
- [local-member-audit.json](/tmp/pr15-site-v4-archive-readonly-20261005/local-member-audit.json)：全部本地成员 offsets/types/sizes/hashes，32 项核对结果，PCK/WASM 汇总。
- 本报告只保存只读结论，无私密响应字段或产品变更。
