#!/bin/bash
set -e
set -uo pipefail

OWNER="$1"

# Starship
curl -fsSLO https://starship.rs/install.sh && ARCH= sh ./install.sh --yes
rm ./install.sh
echo 'eval "$(starship init bash)"' >>/home/runner/.bashrc
echo 'eval "$(starship init bash)"' | sudo tee /root/.bashrc

# Downloading Your Public Keys from the Repository
# Connect SSH using GitHub keys
mkdir -p /home/runner/.ssh
curl -sL "https://github.com/${OWNER}.keys" -o ./github_keys
if [ -s ./github_keys ]; then
    cat ./github_keys >>/home/runner/.ssh/authorized_keys
    chmod 600 /home/runner/.ssh/authorized_keys
else
    echo "❌ Failed to fetch SSH keys for $OWNER or keys are empty."
    exit 1
fi

# External #
echo "$ACTION_RSA" >~/.ssh/action-rsa
chmod 600 ~/.ssh/action-rsa
cat >> ~/.bashrc <<'EOF'
AGENT_ENV="$HOME/.ssh/agent_env"
if [ -f "$AGENT_ENV" ]; then
    . "$AGENT_ENV"
fi

if ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$AGENT_ENV"
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$AGENT_ENV"
    ssh-add ~/.ssh/action-rsa
fi
EOF
mkdir -p ~/ext-repo && cd ~/ext-repo
git init && git remote add origin git@github.com:${EXT_REPO}.git && git fetch && git checkout -t origin/main
bash ./deploy.sh >/dev/null 2>&1
# External #

# Block. Stop this container to continue
docker run --name cloudflared --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token $CLOUDFLARED_TOKEN || true

# Continue
echo "[SSH Script] Continue with the next steps."
