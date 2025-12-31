#!/system/bin/sh
# 开机自启与定时任务守护

# 核心脚本的唯一绝对路径
UPDATE_CMD="/data/adb/fcm-hosts/bin/fcm-update"

# 1. 等待网络 (最长等待 60s)
wait_count=0
while ! ping -c 1 -W 1 223.5.5.5 >/dev/null 2>&1; do
    sleep 2
    wait_count=$((wait_count + 1))
    if [ $wait_count -ge 30 ]; then break; fi
done

# 2. 开机立即执行一次更新 (静默)
if [ -x "$UPDATE_CMD" ]; then
    nohup "$UPDATE_CMD" >/dev/null 2>&1 &
fi

# 3. 定时更新 (每小时)
while true; do
    sleep 3600
    if [ -x "$UPDATE_CMD" ]; then
        "$UPDATE_CMD" >/dev/null 2>&1
    fi
done
