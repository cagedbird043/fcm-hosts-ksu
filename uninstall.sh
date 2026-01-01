#!/system/bin/sh
# 清理 MiceTimer 中的任务注册
rm -f /data/adb/timers.d/fcm-hosts.toml

# 清理脚本，但保留 hosts 数据
rm -rf /data/adb/fcm-hosts/bin
