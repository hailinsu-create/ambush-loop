# PR15 历史事件文字来源绑定

父端 fixed4ba 独立QA关闭原title两项P2后返回新P2：真实schema1旧记录第一枪事件仍绑定旧源，替换live BattleLog为无fire记录后列表/定位文字丢失★第一枪。独立原探针H6/2、R8/2、actual exit1/ERROR0。本轮仅优先修复来源绑定，正常玩家旅程保留并暂停，不改变R规则、记录格式或资产文件。

旧记录来源874d3501fdd2b34b0966472e22a9e43a28a1b3dd，5418800字节，SHA256 1de456c1fc6677815ea3397c8e318ab83fc55ebf71f6a3e20001317d4904dd12。受控API替换main.battle_log，不重绑replay；普通玩家UI换源可达性未证明，不称模拟/装备/时间身份回归。

先固定最小六业务断言并实际H/R负向。然后事件列表两条渲染路径、定位文字及类型定位入口统一读取phase对应的记录；REPLAY必须用replay.log，其他阶段使用live。测试真实旧记录、现代原reference记录、1x/2x普通引擎过程、正反seek、无fire与碰撞seq的live来源、source重绑、旧fallback；记录/现场/SimClock/旧字节均保持。固定源正式H/R、云端截图、实际退出与错误数入库，再普通push并只读核对Draft PR15 HEAD，不merge。

验收范围只含此文字P2；普通六关13波玩家流程、全3DFX、A3预算、艺术、耳听45cue/六soundscape、同候选APK仍待。资产工作者继续独立源与导出单写；不编辑或运行ArtSource生成器/GLB/Blender/共享atlas。外部网页GPT review不可用，不冒称approve。初始立项：最小探针已编写、尚未执行；当时仅本地保存。

进度：test-only1629380原生产源实际H6/2、R8/2、exit1/SCRIPT0/ERROR0，完全复现父端原最小反例。生产修复fcfdb9b让列表、fallback、定位与类型定位使用绑定源；最小H6/0实际exit0。扩展de86因测试类型推断解析错误实际exit1/SCRIPT1/ERROR1；d6扩展371/2实际exit1/ERROR0，两个失败是测试误把同tick最后事件当第一枪，64自然callback全部时间/文字检查通过，非生产新P2。ddec改为完整prefix比较与live全行检查，固定正式运行中。原正常旅程c7/528/117的各自日志保留，不用其失败或引擎错误证明战场通过。

正式fixed ddec已完成H373/0、R387/0，actual exit0/SCRIPT0/ERROR0；各64自然callback，14 native Window PNG核hash/看4。相关timeline67/0、actual exit0/ERROR0，equipment headless66/0、actual exit0/ERROR0。报告和完整收据归档后普通同步；最终同步状态以PR15实际HEAD和push退出收据为准。
