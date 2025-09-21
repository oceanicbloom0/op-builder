#!/bin/bash
set -e
set -uo pipefail

OWNER="$1"

curl -fsSLO https://starship.rs/install.sh && ARCH= sh ./install.sh --yes
rm ./install.sh
echo 'eval "$(starship init bash)"' >>/home/runner/.bashrc
echo 'eval "$(starship init bash)"' | sudo tee /root/.bashrc

mkdir -p /home/runner/.ssh

# Downloading Your Public Keys from the Repository
curl -sL "https://github.com/${OWNER}.keys" -o ./github_keys

if [ -s ./github_keys ]; then
    cat ./github_keys >> /home/runner/.ssh/authorized_keys
    chmod 600 /home/runner/.ssh/authorized_keys
else
    echo "❌ Failed to fetch SSH keys for $OWNER or keys are empty."
    exit 1
fi

# 启动SSH隧道并后台运行
echo "[SSH Script] Starting Cloudflared tunnel..."
docker run --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARED_TOKEN > /dev/null 2>&1 &
TUNNEL_PID=$!

# 等待隧道启动
sleep 3

# 检查隧道是否成功启动
if ! kill -0 $TUNNEL_PID 2>/dev/null; then
    echo "❌ Cloudflared tunnel failed to start"
    exit 1
fi

# 输出PID供外部脚本使用
echo "TUNNEL_PID=$TUNNEL_PID"
echo "SSH_TUNNEL_PID=$TUNNEL_PID" >> $GITHUB_ENV 2>/dev/null || true

# 心跳监控函数
heartbeat_monitor() {
    local pid=$1
    local count=0
    while kill -0 $pid 2>/dev/null; do
        count=$((count + 1))
        echo "[SSH Heartbeat] Tunnel active - $(date '+%Y-%m-%d %H:%M:%S') - Check #$count"
        sleep 300  # 5分钟
    done
    echo "[SSH Heartbeat] Tunnel disconnected - $(date '+%Y-%m-%d %H:%M:%S')"
}

# 启动心跳监控（后台）
heartbeat_monitor $TUNNEL_PID &
HEARTBEAT_PID=$!
echo "HEARTBEAT_PID=$HEARTBEAT_PID" >> $GITHUB_ENV 2>/dev/null || true

echo "[SSH Script] Tunnel established with heartbeat monitoring (PID: $TUNNEL_PID)"
echo "[SSH Script] Heartbeat monitor started (PID: $HEARTBEAT_PID)"
echo "[SSH Script] Setup complete. Tunnel will remain active until process is terminated."