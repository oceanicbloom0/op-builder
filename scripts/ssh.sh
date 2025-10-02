#!/bin/bash
set -e
set -uo pipefail

OWNER="$1"
SSH_FLAG="$2"

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

# Only run cloudflared in background if SSH is enabled
if [ "$SSH_FLAG" = "true" ]; then
    docker run -d --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARED_TOKEN || true
else
    docker run --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARED_TOKEN || true
fi

# Continue
echo "[SSH Script] Continue with the next steps."