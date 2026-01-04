## v3.0.0 (Pre-release)

### 🚀 新特性 / New Features
- **自适应挂载架构 (Adaptive Mounting)**: 独创“硬链接 + 原生挂载”方案。完美适配 Magisk, APatch 与 KernelSU，彻底解决非 OverlayFS 环境下的挂载失效问题。
- **诊断工具 (Diagnostic Tool)**: 新增 `fcm-test` 指令，一键自测 9 个 FCM 核心节点的连通性与 IP 解析状态。
- **全量双语支持 (Bilingual)**: `service.sh`, `fcm-update` 及 `fcm-test` 全面支持中英双语日志和输出。

### 🛡️ 安全与权限 / Security & Permissions
- **SELinux 深度修复**: 重新设计了安全上下文对齐逻辑。通过参考系统核心组件并强制对齐 `system_file` 标签，确保非 Root 用户（普通 App）拥有持久的 hosts 读取权限。
- **自愈机制**: `service.sh` 现在会在开机时自动巡检并修正被元模块篡改的 Inode 或 SELinux 标签。

### 🔧 优化与修复 / Improvements & Fixes
- **CI 流程加固**: 修复了 GitHub Actions 的正则逻辑，解决了 `update.json` 中查询字符串堆叠（串串香）的严重错误。
- **极速同步**: 优化 MiceTimer 配置，开机延迟缩短至 1 分钟，显著提升首次激活速度。
- **打包精简**: 优化 ZIP 白名单，移除了冗余缓存并确保 `system/etc/hosts` 占位符正确打包。

### ⚠️ 迁移指南 / Migration Guide
1. **自动迁移**: 安装本版本时，脚本会自动尝试将旧版的挂载逻辑移除并重新建立硬链接。
2. **验证状态**: 建议安装后重启，并运行 `fcm-test` 验证状态。
3. **兼容性**: 本模块会由于“硬链接抢占”导致其他 Hosts 模块失效，请知悉。

## v2.1.2

- **修复**: 增加对 Meta OverlayFS 模块缓存 (`/data/adb/modules/meta-overlayfs/...`) 的自动清理逻辑，解决因旧版软链接残留导致模块更新不生效的问题。

## v2.1.1

- **修复**: 在安装脚本 (`customize.sh`) 中强制删除模块内的 `system/etc/hosts` 目录，防止覆盖安装时软链接残留导致 Bind Mount 依然被重定向的问题。

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