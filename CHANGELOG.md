## v2.1.0

- **修复**: 切换为 Bind Mount (挂载) 策略，解决非 Root 应用因 `/data/adb` 权限无法读取 hosts 的问题。
- **修复**: hosts 更新改为原地写入，防止挂载点失效。
- **文档**: README 全面中文化。

## v2.0.0

- 架构重大升级：迁移至 Skeleton 模式。
- 调度中心化：现在由 MiceTimer 统一托管定时任务（频率提升至 1h/次）。
- 依赖强制检查：安装时需确保 MiceTimer 已安装。
- 增强稳定性：引入 hosts 文件保底逻辑，确保 localhost 永不丢失。
- 优化路径：所有业务数据迁移至 /data/adb/fcm-hosts。