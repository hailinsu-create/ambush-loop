# PR15 旧smoke合同fixture修正报告

2026-10-04。本片只改smoke共享测试顺序/预期与隔离入口，不改生产Title/main/timeline。固定修后源码 **8906ff5d595a08e614fb02c8d19277867b00e865**、game tree33c30ecabc6a75c24cd279adb75350ff6fff0524。有界原launch-modal+radio-SCOUT函数实际官方4.7.2 H/Guard/UUID **dfe6ae24b5854e129623d925f5ebbf24**，actual exit0、ERROR0/SCRIPT0。[命令/收据](evidence/20261004-pr15-smoke-fixtures/fixed-bounded-8906/boundary.json)、[原日志](evidence/20261004-pr15-smoke-fixtures/fixed-bounded-8906/run.log)、[hash清单](evidence/20261004-pr15-smoke-fixtures/file-manifest.json)。没有额外虚构checks总数，完整smoke仍未通过。

原a05完整smoke actual54/E1/S0提前SMOKE_JOURNAL_RADIO：简报打开时原open_journal已按现有锁拒绝。修测试先断言拒绝，然后原Back关闭简报、再原journal电台正文。首次9f46只等一个headless frame，原0.15s tween仍未完成，actual54/E1/S0在SMOKE_BACK_DID_NOT_CLOSE_BRIEF_MODAL失败；先封原失败再等待原tween.finished，没有改变产品模态/动画时间。

随后b62固定整轮H实际运行触控/队形/生命周期/表现与reference campaign，走过原yard/warehouse/pump/railcut/depot到radio SCOUT，在SMOKE_RADIO_NO_ECHO_BREATH **actual62/E1/S0**停止。[完整原失败日志](evidence/20261004-pr15-smoke-fixtures/full-smoke-b62-radio-stop/run.log)。旧assert把全关总表echo5.2当当前SCOUT已待入场；现有本波scope只让实际ALERT wave queue pending，SCOUT是全关教学预览。只修旧assert为SCOUT+原callout明确全关教学预览+live echo pending=false，原5.2总表/n=5/routes/kit/pad/人数保持；不重开父端已闭cdb范围、不为旧测试恢复错误生产展示。

smoke_contract_test直接调用同一原_assert_launch_bar与_assert_radio_contract函数，隔离wrapper两平台增加明确entry；不是复制实现的假测试，也不是跳过失败就称整轮green。正式完整smoke末段、最终FX候选自己的完整smoke仍待验；a05正常1193/0与新record实际3D也不取消上述54/62失败。下一继续[新原件3D计划](AMBUSH_PR15_NATIVE_RECORD3D_PLAN_20261004.md)，真实原a05 PCK yard第一渲染4404/1actual1保留，Right原生步长正在独立诊断，不把whole2x子段当整绿。

R5/制作源/GLB/atlas/Blender/生产manifest不改，主集成共享测试单写；Draft普通push、不merge/生产/height/G，耳听设备后置，网页GPT PLAN/REVIEW unavailable。
