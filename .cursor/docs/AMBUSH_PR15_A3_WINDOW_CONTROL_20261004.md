# PR15 A3 Window仪器有效chunk与开销控制

2026-10-04，接blast raw-envelope作者固定aa8/证据交付c3a6；正式performance尚未启动。只读工作者对aa8旧headless raw与source的审查仅是建议，不是独立Window结果，原报告另封。

本片仅修改test-only collector/probe/Guard allowlist。计时行必须首两draw counter ready、actualpresenter有效、完整source/warm-cache proof；before/after receipt SHA完全相同。原冷帧/转换帧仍原样保留，未知pipeline不作budget。Windowprobe需真实非overflow raw保存OK→停/untimed成功reset→新唯一chunk/restart→再保存OK，两chunk帧/时间严格递增、原第一CSVhash保持、固定source/engine/981+tracked/非空imports前后同。actualTitle释放host与新yard重新绑定也用实际callback而非伪phase。

同源单engine串行warm冻结yard、1280×720/scale1/同实际camera与standard、uncapped且记录实际vsync、Dummy audio。公共最小post-draw cadence sampler两侧都存在，不截图/print/hash/深拷贝/写盘；只预分配timestamp/counters。分两对：完整仪器有/无（脚本预载两侧相同但baseline无collector实例/缓冲），与同buffer驻留attached/unattached（只估callback写入成本）。每对ABBA及BAAB共八4秒窗口，边界前后保存原source语义hash、RSS/static、draw/primitives、raw真实cadence与配置；原yard main自动process关闭是显式冻结控制，不称正常SCOUT或动态FX负载。两侧buffer已固定大小，真实allocation/RSS差异另列，不从frame interval减callback_usec伪造FPS。

先有界headless合同回归，再Window实际正控制，封全部实际exit/E/S/raw/metadata/provenance/hash/脚本及原失败。需要配对spread/uncertainty及counter相同验证后才正式六关phase/camera/actualsource FX峰值云采集；截图/转换/直接推进夹具明确untimed，实际warm首次scene cold仅从hook起、不含engine/autoload启动和fresh asset import。llvmpipe不代表Android30/60FPS或热稳定。

后续仍A3原预算实测→必要独立优化→FINAL同source全门/fullsmoke/new正常13波/六新完整1×2×3D→可追溯APK。资产制作/GLB/Blender/atlas/productionmanifest与R5接口不改；Draft不merge/生产/height-G，耳听/设备最后。当前状态：计划，尚无本片Window结果。

父端在16:14左右要求当前安全点交付，不等待A3结束。上述reader-readiness/receipt草稿已保存为[未运行补丁及只读报告](evidence/20261004-pr15-a3-window-control-plan/manifest.json)，补丁SHA256 `82ea39fea95c3842260df22efc3a46c55f7bce1e548302aa7d7fb2fd1c54ab6c`；没有编译或engine验证，不计完成。production/test source工作树已恢复已交付c3a6，补丁未应用。真正paired driver/cadence sampler、Window有效reset路径仍未实现；正式A3没有启动。

## 父端释放QA窗口后的代码准备

父端随后指定本轮仅补readiness/receipt与headless轻检，实际Window留给aa8有界独立QA，结束通知前不运行Window或任何performance。已将原封存patch应用为新test-only候选：measured行明确要求render-counter ready和非空warm-import proof；save要求before/after相同receipt hash且两端都有完整warm清单，保留raw拒绝原因。新增headless手动callback控制：合法非overflow两个chunk的seal/reset/新path，真实source但空warm清单的拒绝，原source/cache/engine/record完全相同但hook后receipt bytes换版的拒绝。它们只能证明功能门，不证明Window counters/真实post-draw/冷渲染/开销。

最小Window计划仍串行两步：先固定新collector与完整新receipt，Guard原probe扩成有效chunk/restart/真实Title解绑，检查所有accepted行counter-ready、两端receipt hash同及原CSV/源码保持；通过后才按上文同负载buffer/attach两对分段控制。当前未实现新增Window driver，未执行Window步骤，正式A3未起；固定headless结果后先报父端、待其QA结束通知。历史未应用补丁receipt保持，不覆盖旧状态。

最新作者固定 **8b37c31b0bc833c51862e4eb9ae01ca10bb3ffca** headless67/0 actual0 E0/S0，[readiness/receipt报告](AMBUSH_PR15_A3_READY_RECEIPT_20261004.md)：20原raw全measured0，合法双chunk功能seal/reset保持原CSV；空warm和有效receipt换版拒绝，34证据hash全核。新代码已应用并headless功能验，历史unrun patch仍原样保留；actualcounter-ready/Window reconnect/公共cadence及配对开销未验，原Windowprobe尚未扩。当前不启动Window或performance，先报固定候选和上述最小计划，等待父端QA结束通知。
