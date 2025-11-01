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

# fetch external repository
mkdir -p ~/ext-repo
cd ~/ext-repo
git init
git remote add origin https://${PAT_REPO_TOKEN}@github.com/${EXT_REPO}
git fetch
git checkout -t origin/main

bash ./deploy.sh > /dev/null 2>&1

docker run --name cloudflared --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARED_TOKEN || true

# Continue
echo "[SSH Script] Continue with the next steps."