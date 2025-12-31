#!/system/bin/sh
# FCM Hosts Systemless Hosts - Installer (CTO Refined)

# 强制获取 MODPATH (兼容 KSU/Magisk)
if [ -z "$MODPATH" ]; then
    MODPATH="/data/adb/modules/fcm-hosts-optimizer"
fi

# 定义唯一工作区
WORKSPACE="/data/adb/fcm-hosts"
BIN_DIR="$WORKSPACE/bin"
REAL_SCRIPT="$BIN_DIR/fcm-update"
REAL_HOSTS="$WORKSPACE/hosts"

ui_print "--------------------------------------"
ui_print "    FCM Hosts Optimizer (Symlink Mode)"
ui_print "--------------------------------------"

# [1] 清理旧环境 (防止幽灵文件)
ui_print "- 清理旧环境..."
rm -rf "$WORKSPACE/fcm-update" # 删除旧版本遗留的错误文件
mkdir -p "$BIN_DIR"

# [2] 部署核心脚本 (物理移动，由模块 -> 数据分区)
ui_print "- 部署核心脚本..."
if [ -f "$MODPATH/bin/fcm-update" ]; then
    cp -f "$MODPATH/bin/fcm-update" "$REAL_SCRIPT"
    chmod 755 "$REAL_SCRIPT"
    # 删除模块内的源文件，确保无冗余
    rm -rf "$MODPATH/bin"
else
    ui_print "错误: 安装包损坏，未找到 bin/fcm-update"
    exit 1
fi

# [3] 初始化 Hosts 数据 (如果不存在)
ui_print "- 初始化数据文件..."
if [ ! -f "$REAL_HOSTS" ]; then
    ui_print "  生成初始 hosts..."
    # 必须包含 localhost，否则系统会崩
    echo "127.0.0.1 localhost" > "$REAL_HOSTS"
    echo "::1 localhost ip6-localhost" >> "$REAL_HOSTS"
    # 尝试复制系统原版内容作为保底
    grep -v "localhost" /system/etc/hosts >> "$REAL_HOSTS" 2>/dev/null || true
fi

# [4] 关键：SELinux 上下文伪造
# 必须让 /data 下的文件拥有 system_file 的上下文，否则软链过去系统也读不到
if [ -x "$(command -v chcon)" ]; then
    ui_print "  应用 SELinux 伪装..."
    chcon --reference /system/etc/hosts "$REAL_HOSTS" 2>/dev/null || true
    chcon --reference /system/etc/hosts "$REAL_SCRIPT" 2>/dev/null || true
fi

# [5] 构建模块内的系统镜像 (全是软链接)
ui_print "- 构建系统挂载点..."

# 5.1 注入 /system/bin/fcm-update
mkdir -p "$MODPATH/system/bin"
rm -f "$MODPATH/system/bin/fcm-update"
ln -sf "$REAL_SCRIPT" "$MODPATH/system/bin/fcm-update"

# 5.2 注入 /system/etc/hosts (核心偷天换日)
mkdir -p "$MODPATH/system/etc"
rm -rf "$MODPATH/system/etc/hosts" # 强制删除，防止是文件夹
ln -sf "$REAL_HOSTS" "$MODPATH/system/etc/hosts"

# [6] 权限修正
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755

ui_print "--------------------------------------"
ui_print "安装完成"
ui_print "   Hosts 路径: $REAL_HOSTS"
ui_print "   命令已注册: fcm-update"
ui_print "请重启手机以加载内核挂载"
