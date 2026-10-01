# 云端核验自动化计划

日期：2026-10-01。用户明确要求自动化完成核验。基线 cloud-main 为 e3faeb5808b5d1b0a62ad9b479aa3f576ec0c3bc；当前修复分支为 3995503f9c5f86e2087ea416f4b65b45b1f5d93f。外部 PLAN unavailable。

## 范围与执行

新增单一机器核验入口和 GitHub Actions：相关分支推送/PR 更新时在干净 runner 安装固定工具，核对提交与安装 launcher，执行真实生命周期 suite、yard_crate 生成、glTF inspect 和隔离 Accept gate。输出源码 SHA、逐步退出码、日志、产物和明确分离的技术/评审状态；Actions 上传产物并生成摘要。已有游戏源码、美术与网络配置保持不变。

原外部评审方案中“不实施 Actions”被本轮用户要求替代；原 Project 与精确 SHA 来源规则仍有效。当前没有已认证的 Project 调用接口或可用 Cloud API，不以另一 Codex、自审、历史答复代替外部批准，也不新增 API 收费调用或域名权限。配置发布由产品拥有，当前无发布工具。

## 验收与风险

先在当前机器运行新入口，必须观察真实工具执行、输出标记和产物；再次验证失败传播。提交后核对远端，并查询 Actions 是否真实执行。Actions 管理权限查询实测 403，不能预先声称 CI 已启用；推送或运行失败均保存实际结果。CI 冷安装不等同于产品快照验收。PR 保持 Draft，不合并。

下一步：实现入口与工作流、真实运行、GitHub 留档；外部评审保持 unavailable 直到原 Project 提供可调用授权接入。
