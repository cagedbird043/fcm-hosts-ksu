#!/system/bin/sh
# 此模块的调度已由 MiceTimer 接管
# 配置文件位于 /data/adb/timers.d/fcm-hosts.toml
MODDIR=${0%/*}
# 1. 确保数据区 hosts 存在 (保底逻辑)
HOSTS_DATA="/data/adb/fcm-hosts/hosts"
if [ ! -f "$HOSTS_DATA" ]; then
    echo "127.0.0.1 localhost" > "$HOSTS_DATA"
    chmod 644 "$HOSTS_DATA"
fi

# 2. 挂载检查与保底
# v3.0 优先利用管理器的原生挂载。如果硬链接策略生效，系统 hosts 的 Inode 应与数据区一致。
TARGET_HOSTS="/system/etc/hosts"
DATA_INODE=$(ls -i "$HOSTS_DATA" | awk '{print $1}')
SYSTEM_INODE=$(ls -i "$TARGET_HOSTS" | awk '{print $1}')

if [ "$DATA_INODE" = "$SYSTEM_INODE" ]; then
    echo "[$(date)] FCM Hosts: Native Mount (Inodes match: $DATA_INODE). No action needed. / 原生挂载生效 (Inode 匹配)，无需操作。" > /data/adb/fcm-hosts/service.log
else
    # 只有当原生挂载失败（Inode 不匹配）时，才尝试手动挂载
    mount --bind "$HOSTS_DATA" "$TARGET_HOSTS"
    if [ $? -eq 0 ]; then
        echo "[$(date)] FCM Hosts: Manual Bind Mount active (Fallback). / 手动绑定挂载已激活 (保底方案)。" >> /data/adb/fcm-hosts/service.log
    else
        echo "[$(date)] FCM Hosts: ERROR - Failed to mount hosts. / 错误 - 挂载 hosts 失败。" >> /data/adb/fcm-hosts/service.log
    fi
fi