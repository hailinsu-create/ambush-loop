# PR15 P2 抓放内部边界连续性

日期：2026-10-03。作者运行修复固定 `f7fcfdbab1adac3ff545ecadbe9b8d74ec9306d3`。全部18正式运行实际exit0/ERROR0，独立P2复验仍待。仅本地提交：最近只读远端为a575d9ec9b7eed1b934218a727c41c2a6d0ff226；Git写凭证失败后按父端要求停止push/auth重试，未换token、未merge、未发布。先前0.559m中段断握及97.637mm正浮空的限定修复结论保留，本P2为后来发现的独立内部边界问题。

## 证实与版本契约

正式负向 `b6487b7b756c186fbdd0a9575d3a4606c8e90b11` 的尸体运行逻辑与a575相同，HUD已有6a切片。原生MG真实两波来源、原H输入及鼠标97步路径，调用普通main._process(dt)，不手写command clock；release .5→.5001、grab .1999→.2的双掌约0.387376m、皮肤最高0.393138m跳变，body根及body皮肤不跳。3角色×3LOD×2stance×2mode=36明确fixture仍保留实际carrier/body位置/朝向和原墙bounds。渲染241检查/110失败/实际exit1/ERROR0，UUID0941f106f9984ff995bb748178d7c5cf。[原日志与报告](evidence/20261003-pr15-corpse-boundary/negative-b6487b7/corpse-boundary-report.json)；此前ec9初诊断标签重复且reference泄漏，排除正式负向。父端另述a575原QA116/76，是独立父端结果，未冒称本作者运行该文本。

新记录显式corpse_pairing_schema=2。手臂从普通姿态连续混合骨骼旋转，只有原lift/lower接触区作双掌握持承诺；超出可达范围的中间目标投影到原骨段长度构成的可达壳，不拉长骨段。端点伸直腿的浮点放大通过新版本权重收敛，蹲姿held端点按记录pose clock采样，避免旧零时刻缓存与实际持握端点差异。body原floor、wall contact、世界锚点、源wave/bodyID、14px逻辑follow、共享haul及取消规则保持。仅改运行Pairing/CorpseVisual/VisualSnapshot与专项测试；未触制作源或导出资产。

schema1保留旧显示策略，包括其原边界行为；36用例×2时刻的72组根/40骨姿态SHA256逐字节匹配修复前，不升级/回写旧源。missing/unknown0/99保留原前版本fallback。新策略只读取历史记录，不从当前活体借姿态；schema2不是资产版本变化。

## 固定候选实际验证

引擎Godot4.7.2 official ed1daf0bf，隔离wrapper随机UUID/XDG+StorageGuard。正式边界命令：

```
AMBUSH_BOUNDARY_REFERENCE=/workspace/ambush-pr15/.cursor/docs/evidence/20261003-pr15-corpse-boundary/negative-b6487b7/corpse-boundary-report.json bash ambush_loop/scripts/run_isolated_test.sh /tmp/pr15-hud-godot corpse_pairing_boundary_test.gd --render
```

私有Xorg:110、llvmpipe，UUID5883c712545f443db44015fc8a30bc9d。2,978检查/0失败，实际exit0/ERROR0；36关键边界、1,350整段probe及72旧版姿态摘要。关键边界仍1mm门限，fixture最大双掌0.000603mm、皮肤0.021374mm、40骨位移0.016199mm；body根/skin不跳。原生H与普通_process100µs边界、暂停/后台冻结、记录历史seek/源保留也通过。

完整过渡另测25ms网格及所有端点周围100µs，再检查前后两半50µs的位移均收敛，保留5µm数值余量及20m/s外界。中段有限运动不能用“100µs小于1mm”当数学连续定义；实际最大皮肤1.493676mm/100µs、双掌1.387027mm、骨角0.005567rad，两个半步均收敛。开发2/3/4真实失败288/252/9均单列保留；开发5较旧单边收敛2970/0不充作固定源正式证据。这些是命名fixture取样，不证明任意墙/任意时刻美术自然度。

同固定候选corpse_pose_quality_test --render：2,695/0；72hold+864相位、17原生测点。gripped fixture双掌最高0.000307mm，bodyfloor约6mm；原生搬运者floor−0.173至+0.024mm，864矩阵搬运者floor−1.705至+0.142mm，仍满足既有±15mm门限。原生body/carrier墙内skin顶点均0；原骨段、端点/暂停/后台/复制历史/旧unknown回退通过。矩阵是明确fixture，不能称完整战场/设备验收。

其余同候选实际检查：角色21818、尸体1203、表现只读契约84042、六关13波10332、装备冻结66、时间轴66、commandclock27、工具1041、旧HUD snapshot渲染164、生命周期headless30/render32、camera23、交互headless38/render38、C2历史29、depot/radio渲染106，均exit0/ERROR0。所有实际命令、UUID、entry/hash、原日志、durable exit在[18运行receipt](evidence/20261003-pr15-corpse-boundary/validation.json)。不同模式计数明确区分，不套用旧候选32/30等数字。

六关原终局保持：yard1283/34、warehouse1191/67、pump907/34、railcut719/38、depot957/35、radio1413/51（tick/events）；波数2/2/2/2/2/3。测试使用原reference装备/路线/vacuum fixture，非普通玩家完整旅程。最新fullsmoke仍旧7d34867，旧PCK91不属于本候选。

## 视觉、归档边界与后续

四张关键边界图已看，且图像摘要匹配；另看新候选品质图的桌面grab前侧、release后侧及只读history。实际camera size12、viewport1280×720，不把请求8或父端QA camera4写成实际。品质9图全部保存/摘要匹配，depot/radio4图保存但未称逐图验收。边界原捕7图中的qa_exact/两张history通用名在后续运行覆盖，3张辅助原图未保留，receipt列明缺口；四张关键图和后续品质history完整，绝不称原7图全齐。

观察到两张focus切换邻近边界图右镜头文字裁切，列为待复现UI问题；普通桌面minimap/checklist文字叠层亦待评审。既有HUD6a原生窗口5081/0结论限定成立，不称整个HUD关闭。FAILED/WON200、独立P2/HUD复验、完整3DFX及版本化连续command历史、A3预算/六关完整13波视觉和普通旅程、同最终候选smoke/QA/APK继续；耳听0/45和0/6、设备统一后置，GPT PLAN/REVIEW unavailable。

唯一主作者所有权：main/HUD/presenter/ViewState/replay/运行manifest注册和loader/共享测试/运行派生mesh。独立资产作者所有权：ArtSource与Blender、build_yard_kit.py/角色生成器、共享atlas、角色GLB/制作输出和制作manifest；本片对ArtSource与ambush_loop/art diff为空，未重跑制作器。资产接口仍R5源29749157c5db064bfea626c3ed9d75d9a1791ece/交付ebedb829e3263abbeb6dd266905f24a3869fa281、20骨/socket/三LOD/旧52动作语义。未来候选只收固定SHA、原字节和LOD/挂点/接触floor/端点证据，不全并wip资产分支。

可并行独立包：固定f7fcfdb只读IK边界/全段/历史品质QA、固定6a519b3真实窗口/200%HUD QA、独立资产源动作评审。共享运行文件不得并发写，不自行派遣astra。Notion由父端指定作者维护。

转运阻塞独立于代码：811旧证据bundle已官方Library创建libfile_b28ecbb4edb8819199df33da8dcceea0，但本端/父端官方materialize均失败；不走rawcurl/缓存/token等替代，不称下载内容SHA已复验。本新候选仍本地；需官方GitHub写连接与Library下载恢复后才同步/交付远端。
