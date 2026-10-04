# PR15 pump结果高光事实修复

父端确认d8e1/030正常pump开门通关，却WON高光显示“锁门后紫线改道被你罩住”，要求先修文案、补开门/锁门反例，固定小片交独立QA，再接自然railcut存档继续三关7波。源证据保留，父端pump QA已接。

原统计_fill_result_stats直接读level.highlight_hook；正文PayoffCopy.highlight_result_line即使hook_hit=false也回退同一固定目标。最小片只改pump结果文案：完成显示“泵站封锁完成”、失败显示“泵站尚未封锁”。统一统计与正文，教学/brief的未来目标仍保留；不凭route_choice事件/covered标志或当前door字段虚构玩家已完成闭门紫线策略，不改模拟/冻结/R/其他关文案/资产。

先固定负向测试源，复用真实030 Native record的只读formatter反例；另用明确reference grants/cover snaps/direct tick/vacuum的窄域三例开门赢、锁门正确朝向赢、锁门错误朝向失败，确认原door/route_choice/真实终局，再核两处结果文案和记录/模拟未被formatter改写。H与1280×720/100%实际窗口各一次，三图核hash/目检；这不是新增正常输入旅程或闭门原生路线/全美术/设备通过。新入口两平台runner注册，先确认guard。负向实际exit/ERROR与正式分源保全；官方PCK仅隔离staging已有a0_preview，资产生成器不运行。当前待实现/运行，网页GPT PLAN/REVIEW unavailable。

主集成单写main/presenter/ViewState/replay/HUD/loader/共享测试；R5源29749157/交付ebedb829资产接口不变，制作源/GLB/atlas/Blender/生产manifest不改不重跑，WIP不全并。普通push Draft PR15，不merge/生产/height/G。小片后接自然railcut2波，再depot2/radio3；真正耗尽自动ammo pack未触发仍不计通过。FX/A3/耳听/最终APK/设备全计划后待验。可并行固定本片只读结果文案QA，不写主集成文件；当前无需新资产包。
