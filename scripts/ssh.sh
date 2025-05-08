#!/bin/bash
set -e
set -uo pipefail

OWNER="$1"
echo "Fetching public SSH keys for GitHub user: $OWNER"

curl -fsSLO https://starship.rs/install.sh && sh ./install.sh --yes
rm ./install.sh
echo 'eval "$(starship init bash)"' >>/home/runner/.bashrc
echo 'eval "$(starship init bash)"' | sudo tee /root/.bashrc

mkdir -p /home/runner/.ssh
sudo mkdir -p /root/.ssh

# Downloading Your Public Keys from the Repository
curl -sL "https://github.com/${OWNER}.keys" -o /tmp/github_keys

if [ -s /tmp/github_keys ]; then
    cat /tmp/github_keys >> /home/runner/.ssh/authorized_keys
    chmod 600 /home/runner/.ssh/authorized_keys
else
    echo "❌ Failed to fetch SSH keys for $OWNER or keys are empty."
    exit 1
fi

docker run --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARED_TOKEN

# 运行后续任务
echo "[SSH] 继续运行后续任务..."