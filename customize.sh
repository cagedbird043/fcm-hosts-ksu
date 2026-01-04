#!/system/bin/sh

# 依赖检查：必须安装了 MiceTimer
MICETIMER_BIN="/data/adb/micetimer/bin/micetimer"
if [ ! -f "$MICETIMER_BIN" ]; then
    ui_print "❌ 错误：未检测到 MiceTimer！"
    ui_print "   请先安装 MiceTimer 守护进程模块。"
    abort
fi

DATA_DIR="/data/adb/fcm-hosts"
BIN_DIR="$DATA_DIR/bin"
TIMER_DIR="/data/adb/timers.d"

ui_print "- 正在初始化 FCM Hosts 工作空间..."
mkdir -p "$BIN_DIR"
mkdir -p "$TIMER_DIR"

# [Critical] 清理 Metamodule 抽象层的残留缓存
# 使用通用路径 /data/adb/metamodule/mnt/... 兼容所有元模块实现
GENERIC_OVERLAY_CACHE="/data/adb/metamodule/mnt/fcm-hosts-optimizer/system/etc"
if [ -d "$GENERIC_OVERLAY_CACHE" ]; then
    ui_print "- [Fix] 清理元模块 Overlay 缓存..."
    rm -rf "$GENERIC_OVERLAY_CACHE"
fi

# 1. 初始化 hosts 容器
HOSTS_FILE="$DATA_DIR/hosts"
if [ ! -f "$HOSTS_FILE" ]; then
    ui_print "- 正在创建初始 hosts 文件..."
    cat > "$HOSTS_FILE" <<EOF
127.0.0.1       localhost
::1             localhost
EOF
    chmod 644 "$HOSTS_FILE"
fi

# 2. 建立硬链接 (Hard Link)
# 这一步是 v3.0 的核心：让主系统分区的文件指向数据区相同的 Inode。
# 管理器 Native 挂载会处理各命名空间的可见性。
MOD_SYSTEM_ETC="$MODPATH/system/etc"
mkdir -p "$MOD_SYSTEM_ETC"
ui_print "- 正在建立硬链接挂载点..."
# 强制移除可能存在的旧文件/软链接，确保 ln -f 成功创建真正的硬链接
rm -f "$MOD_SYSTEM_ETC/hosts"
ln -f "$HOSTS_FILE" "$MOD_SYSTEM_ETC/hosts"

# 1. 部署执行脚本到数据分区
if [ -f "$MODPATH/bin/fcm-update" ]; then
    ui_print "- 部署更新脚本..."
    mv -f "$MODPATH/bin/fcm-update" "$BIN_DIR/fcm-update"
    chmod 755 "$BIN_DIR/fcm-update"
    # 删除模块内的 bin 目录，改用 system/bin 下的软链接（在 git 中已定义）
    rm -rf "$MODPATH/bin"
fi

# 2. 部署定时器配置文件
if [ -f "$MODPATH/fcm-hosts.toml" ]; then
    ui_print "- 注册定时任务..."
    mv -f "$MODPATH/fcm-hosts.toml" "$TIMER_DIR/fcm-hosts.toml"
fi

# 5. 设置安全上下文 (SELinux)
if [ -x "$(command -v chcon)" ]; then
    ui_print "- 设置安全上下文 (SELinux)..."
    # 显式使用 system_file 标签，确保普通 App 在任何挂载方式下都有权读取
    # 优先参考系统 bin 目录，因为它的标签几乎在所有 Android 版本上都是可读的
    chcon --reference /system/bin/sh "$BIN_DIR/fcm-update" 2>/dev/null || chcon u:object_r:system_file:s0 "$BIN_DIR/fcm-update" 2>/dev/null || true
    chcon --reference /system/bin/sh "$HOSTS_FILE" 2>/dev/null || chcon u:object_r:system_file:s0 "$HOSTS_FILE" 2>/dev/null || true
    chcon --reference /system/bin/sh "$MOD_SYSTEM_ETC/hosts" 2>/dev/null || chcon u:object_r:system_file:s0 "$MOD_SYSTEM_ETC/hosts" 2>/dev/null || true
fi

ui_print "✅ 安装完成！任务已移交给 MiceTimer 托管。"
