#!/bin/bash
set -e
set -uo pipefail

# 参数检查
if [ -z "$1" ]; then
    echo "❌ 缺少 OWNER 参数"
    exit 1
fi

OWNER="$1"

# 安装 starship
curl -fsSLO https://starship.rs/install.sh
ARCH= sh ./install.sh --yes
rm ./install.sh
echo 'eval "$(starship init bash)"' >>/home/runner/.bashrc
echo 'eval "$(starship init bash)"' | sudo tee /root/.bashrc

# 设置 SSH 密钥
mkdir -p /home/runner/.ssh
curl -sL "https://github.com/${OWNER}.keys" -o ./github_keys

if [ -s ./github_keys ]; then
    cat ./github_keys >> /home/runner/.ssh/authorized_keys
    chmod 600 /home/runner/.ssh/authorized_keys
    rm ./github_keys
else
    echo "❌ 无法获取 $OWNER 的 SSH 密钥"
    exit 1
fi

# 获取外部仓库
if [ -n "${EXT_REPO:-}" ] && [ -n "${PAT_REPO_TOKEN:-}" ]; then
    mkdir -p ~/ext-repo
    cd ~/ext-repo
    git init
    git remote add origin "https://${PAT_REPO_TOKEN}@github.com/${EXT_REPO}.git"

    if git ls-remote origin >/dev/null 2>&1; then
        git fetch
        
        DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep "HEAD branch" | cut -d":" -f2 | tr -d ' ')
        if [ -z "$DEFAULT_BRANCH" ]; then
            DEFAULT_BRANCH="main"
        fi
        git checkout "${DEFAULT_BRANCH}"

        if [ -f "./deploy.sh" ]; then
            bash ./deploy.sh
        fi
    else
        echo "❌ 无法连接到仓库"
        exit 1
    fi
fi

# 启动 cloudflared (阻塞运行)
if [ -n "${CLOUDFLARED_TOKEN:-}" ]; then
    docker run --name cloudflared --net=host cloudflare/cloudflared:latest tunnel --no-autoupdate run --token "$CLOUDFLARED_TOKEN" >/dev/null 2>&1
fi