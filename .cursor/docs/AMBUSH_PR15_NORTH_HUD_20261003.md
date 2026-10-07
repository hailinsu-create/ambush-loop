# PR15 北侧 HUD 收尾

2026-10-03。固定运行源码816c31946b7e32966efc9bb7890d0ef9a7253efb；minimap/checklist重叠已证实修复，原两张focus邻近镜头裁切未能稳定复现，仍待独立QA，不称关闭。

6046a5f真实两窗口/两比例/两偏好SCOUT焦点往返：1702检查/48失败/实际exit1，48为故意UI断言push_error；失败均为桌面100%checklist文字与minimap重叠。33e63b1另沿原生MG两波/97步/H/普通_process/暂停焦点/历史截图顺序测133/0exit0，六次实际面板x1076/宽188/右1264，四张新图未复现旧裁切。此非负向或独立关闭证据。

运行改动只有C2/presenter：minimap置76–180，桌面镜头控制置196起，checkbox原文字/规则保持；相应镜头最小宽度向左扩展，位置仅在布局模式变化时重设，避免每刷新重排水平边界。原生touch偏好及紧凑菜单语义不变，未改main域/历史/资产。

固定816正式focus1702/0exit0/64时刻，完整viewport5081/0exit0/42样本/51物理窗口图/46XTest事件，均ERROR0。具体命令/UUID/报告/所有图摘要：[证据](evidence/20261003-pr15-north-hud/validation.json)。正式已看桌面SCOUT、radio长header与200%ALERT设置；未称全部图逐图审美验收。独立focus问题与FAILED/WON200仍待，后者另切片。

交付状态更新：此前only-local/auth-blocked是当时历史事实。用户只授权一次原remote/配置正常push重试，本次成功a575→cf77f4db63605ff1e9846e1149f27ca6d461f458，git ls-remote及父端只读确认；未改凭据/helper/remote/身份。不能据一次成功推断永久凭据健康。Library旧官方materialize仍失败，未重试/绕过。本文816尚未计为已同步，以后续远端核对为准。资产单写/R5接口与主集成所有权保持，独立QA已由父端安排cf77，不自行派遣。


2026-10-03 本轮限定HUD收尾：[终局与北侧叠层报告](AMBUSH_PR15_RESULT_HUD_20261003.md)。f2结果滚动首修后，80ce379补镜头层级745/24exit1与时间条1718/16exit1→固定7edd0db93243e1079d6af3e55da37bf2d5a97df1正式结果449/0、focus1718/0、viewport5081/0、合同84042/0、历史画面164/0、渲染生命周期32/0，全实际exit0/ERROR0，119最终PNG全部留存并核hash，三张最终图已看。原两张focus邻近裁切未复现/独立QA仍待，cf77 IK/HUD独立QA由父端安排；未称全部HUD/完整战场/设备通过。此前onlylocal/authblocked为历史失败，原配置重试成功后，本片普通push及git/connector只读核对7edd成功；Library未恢复不重试。资产接口/单写者/SCOUT→ALERT→SWEEP规则保持；未展开FX/A3，后续仍按父端分配推进。
