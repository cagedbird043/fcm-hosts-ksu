#!/system/bin/sh
# 此模块的调度已由 MiceTimer 接管
# 配置文件位于 /data/adb/timers.d/fcm-hosts.toml
MODDIR=${0%/*}
echo "[$(date)] FCM Hosts (Skeleton Mode) is ready." > /data/adb/fcm-hosts/service.log