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

# [Critical] 强制清理模块内的 system/etc/hosts
# 防止覆盖安装时残留软链接，导致 service.sh 中的 bind mount 跟随链接失效
if [ -d "$MODPATH/system/etc" ]; then
    ui_print "- 清理旧版架构..."
    rm -rf "$MODPATH/system/etc"
fi

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

# 3. hosts 文件保底逻辑
HOSTS_FILE="$DATA_DIR/hosts"
if [ ! -f "$HOSTS_FILE" ]; then
    ui_print "- 正在创建保底 hosts 文件..."
    cat > "$HOSTS_FILE" <<EOF
127.0.0.1       localhost
::1             localhost
127.0.0.1       ip6-localhost
::1             ip6-localhost
EOF
    chmod 644 "$HOSTS_FILE"
fi

# 4. 设置安全上下文 (SELinux)
if [ -x "$(command -v chcon)" ]; then
    ui_print "- 设置安全上下文..."
    chcon --reference /system/etc/hosts "$BIN_DIR/fcm-update" 2>/dev/null || true
    chcon --reference /system/etc/hosts "$HOSTS_FILE" 2>/dev/null || true
fi

ui_print "✅ 安装完成！任务已移交给 MiceTimer 托管。"
