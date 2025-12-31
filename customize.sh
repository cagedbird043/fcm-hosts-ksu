#!/system/bin/sh
set -e

# 使用 $MODPATH 环境变量（KSU 安装器传入），如果不存在则从脚本路径推导
if [ -z "$MODPATH" ]; then
    # 解析脚本真实路径（跟随软链接）
    SCRIPT_PATH="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")" && pwd)"
    MODPATH="${SCRIPT_PATH%/*}"
fi

WORKSPACE="/data/adb/fcm-hosts"

ui_print "========================================"
ui_print "FCM Hosts Optimizer - 安装程序 v1.0"
ui_print "========================================"
ui_print ""
ui_print "   MODPATH: $MODPATH"

# [1] 环境准备
ui_print "[1/5] 准备安装环境..."
mkdir -p "$WORKSPACE"
if [ $? -ne 0 ]; then
    ui_print "[错误] 无法创建工作目录: $WORKSPACE"
    exit 1
fi
ui_print "   OK: 工作目录 $WORKSPACE"
ui_print ""

# [2] 部署 fcm-update 脚本 (从模块目录)
ui_print "[2/5] 部署 fcm-update 脚本..."

if [ -f "$MODPATH/bin/fcm-update" ]; then
    cp "$MODPATH/bin/fcm-update" "$WORKSPACE/fcm-update"
    chmod 755 "$WORKSPACE/fcm-update"
    ui_print "   OK: 脚本已部署到 $WORKSPACE/fcm-update"
else
    ui_print "[错误] 未找到 $MODPATH/bin/fcm-update"
    exit 1
fi
ui_print ""

# [3] 基底初始化
ui_print "[3/5] 初始化 hosts 文件..."

if [ ! -f "$WORKSPACE/hosts" ]; then
    ui_print "   首次安装，复制系统 hosts..."
    if ! cat /system/etc/hosts > "$WORKSPACE/hosts" 2>/dev/null; then
        ui_print "[错误] 无法读取系统 hosts"
        exit 1
    fi
    ui_print "   OK: 已复制系统 hosts"

    # SELinux
    if [ -x "$(command -v chcon)" ]; then
        chcon --reference /system/etc/hosts "$WORKSPACE/hosts" 2>/dev/null || true
        ui_print "   OK: SELinux 上下文已设置"
    fi
else
    ui_print "   已有 hosts，跳过初始化"
fi
ui_print ""

# [4] 建立软链
ui_print "[4/5] 建立系统软链..."

mkdir -p "$MODPATH/system/etc" 2>/dev/null
if [ $? -ne 0 ]; then
    ui_print "[错误] 无法创建 $MODPATH/system/etc"
    exit 1
fi

# hosts 软链
rm -f "$MODPATH/system/etc/hosts" 2>/dev/null
ln -sf "$WORKSPACE/hosts" "$MODPATH/system/etc/hosts"
if [ $? -ne 0 ]; then
    ui_print "[错误] hosts 软链创建失败"
    exit 1
fi
ui_print "   OK: /system/etc/hosts -> $WORKSPACE/hosts"

# fcm-update 软链 (模块目录已经是软链接)
if [ -L "$MODPATH/system/bin/fcm-update" ]; then
    TARGET=$(readlink "$MODPATH/system/bin/fcm-update")
    ui_print "   OK: system/bin/fcm-update -> $TARGET"
else
    ui_print "[警告] fcm-update 不是符号链接"
fi
ui_print ""

# [5] 设置 service.sh 权限
ui_print "[5/5] 设置权限..."

if [ -f "$MODPATH/service.sh" ]; then
    chmod 755 "$MODPATH/service.sh"
    ui_print "   OK: service.sh 已设置可执行"
else
    ui_print "[警告] 未找到 service.sh"
fi

# 验证
ui_print ""
ui_print "[验证] 安装状态"
if [ -L "$MODPATH/system/etc/hosts" ]; then
    ui_print "   OK: hosts 软链正常"
else
    ui_print "[警告] hosts 软链可能异常"
fi

if [ -f "$WORKSPACE/fcm-update" ]; then
    ui_print "   OK: fcm-update 脚本存在"
else
    ui_print "[警告] fcm-update 脚本不存在"
fi

ui_print ""
ui_print "========================================"
ui_print "安装完成！请重启手机"
ui_print "========================================"
