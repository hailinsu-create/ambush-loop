首预检 wrapper actual exit1：ps仅按comm识别，将既有 <defunct> Godot/Chromium误计为活动引擎，因此assert拒绝启动。尚未创建user://、尚未启动引擎、未读取/覆写活动profile。原loaded runner保留；stdout由原工具调用保留，此文件不重构原endpoint/完整stderr。改为读取stat并排除Z后再运行。
