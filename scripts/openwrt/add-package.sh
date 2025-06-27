#!/bin/bash

# 定义辅助函数
function git_clone() {
    local repo="$1"
    local target="${2:-$(basename "$repo" .git)}"
    echo "🔽 正在克隆：$repo → $target"
    git clone --depth 1 "$repo" "$target" || {
        echo "❌ 克隆失败：$repo" >&2
        exit 1
    }
}

function git_sparse_clone() {
    branch="$1" rurl="$2" localdir="$3" && shift 3
    git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$rurl" "$localdir"
    cd "$localdir"
    git sparse-checkout init --cone
    git sparse-checkout set "$@"
    mv -n "$@" ../
    cd ..
    rm -rf "$localdir"
}
function mvdir() {
    if [ -z "$1" ]; then
        echo "❌ mvdir: 缺少目录参数" >&2
        exit 1
    fi

    local subdirs
    subdirs=$(find "$1"/* -maxdepth 0 -type d 2>/dev/null)

    if [ -z "$subdirs" ]; then
        echo "ℹ️ mvdir: 无子目录，跳过 $1"
        return 0
    fi

    mv -n $subdirs ./ || {
        echo "❌ mvdir: 移动失败，目录 $1" >&2
        exit 1
    }

    rm -rf "$1"
}

cd package

## Passwall Tools
git clone --depth 1 https://github.com/vernesong/OpenClash && mv -n OpenClash/luci-app-openclash ./ && rm -rf OpenClash
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki && mv -n OpenWrt-nikki/luci-app-nikki OpenWrt-nikki/nikki ./ && rm -rf OpenWrt-nikki

## Amlogic
git clone --depth 1 https://github.com/ophub/luci-app-amlogic.git op-amlogic && mv -n op-amlogic/luci-app-amlogic ./ && rm -rf op-amlogic

## Themes
git clone --depth 1 https://github.com/derisamedia/luci-theme-alpha.git
git clone --depth 1 https://github.com/sirpdboy/luci-theme-kucat.git

## 其他软件包集合
# DNS 与网络相关
git_clone https://github.com/kiddin9/luci-app-dnsfilter
git_clone https://github.com/peter-tank/luci-app-dnscrypt-proxy2
git_clone https://github.com/peter-tank/luci-app-autorepeater

# 下载工具
git_clone https://github.com/kiddin9/aria2

# 百度网盘 Web 管理
git_clone https://github.com/kiddin9/luci-app-baidupcs-web

# 文件同步与分享
git_clone https://github.com/kiddin9/autoshare && mvdir autoshare || exit 1

# OpenVPN
git_clone https://github.com/kiddin9/openwrt-openvpn && mvdir openwrt-openvpn || exit 1

# Xray
git_clone https://github.com/yichya/luci-app-xray

git_clone https://github.com/Lienol/openwrt-package

git_clone https://github.com/ysc3839/openwrt-minieap

git_clone https://github.com/ysc3839/luci-proto-minieap

git_clone https://github.com/BoringCat/luci-app-mentohust

git_clone https://github.com/BoringCat/luci-app-minieap

# 用户在线统计
git_clone https://github.com/ElvenP/luci-app-onliner

# USB3 禁用
git_clone https://github.com/rufengsuixing/luci-app-usb3disable

# IPTV 辅助
git_clone https://github.com/riverscn/openwrt-iptvhelper && mvdir openwrt-iptvhelper || exit 1

# MentoHUST
git_clone https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk

# 其他应用
git_clone https://github.com/NateLol/luci-app-beardropper

# 代理与加速
git_clone https://github.com/yaof2/luci-app-ikoolproxy
git_clone https://github.com/project-lede/luci-app-godproxy

# 微信推送 (18.06)
git_clone -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush

git_clone https://github.com/4IceG/luci-app-sms-tool smstool && mvdir smstool || exit 1

# 迅雷下载
git_clone https://github.com/silime/luci-app-xunlei

git_clone https://github.com/BCYDTZ/luci-app-UUGameAcc

git_clone https://github.com/ntlf9t/luci-app-easymesh

git_clone https://github.com/zzsj0928/luci-app-pushbot

git_clone https://github.com/shanglanxin/luci-app-homebridge

git_clone https://github.com/esirplayground/luci-app-poweroff

git_clone https://github.com/esirplayground/LingTiGameAcc

git_clone https://github.com/esirplayground/luci-app-LingTiGameAcc

git_clone https://github.com/brvphoenix/luci-app-wrtbwmon wrtbwmon1 && mvdir wrtbwmon1 || exit 1

git_clone https://github.com/brvphoenix/wrtbwmon wrtbwmon2 && mvdir wrtbwmon2 || exit 1

# 主题与界面配置
git_clone https://github.com/jerrykuku/luci-theme-argon
git_clone https://github.com/jerrykuku/luci-app-argon-config

git_clone https://github.com/jerrykuku/luci-app-ttnode

git_clone https://github.com/jerrykuku/luci-app-go-aliyundrive-webdav

git_clone https://github.com/jerrykuku/lua-maxminddb

# ChatGPT Web 接口
git_clone https://github.com/sirpdboy/luci-app-chatgpt-web

# DDNS 与测速
git_clone https://github.com/sirpdboy/luci-app-ddns-go ddnsgo && mv -n ddnsgo/luci-app-ddns-go ./ && rm -rf ddnsgo

# Speedtest & 网络监测
git_clone https://github.com/sirpdboy/netspeedtest speedtest && mv -f speedtest/*/ ./ && rm -rf speedtest

# 其他工具
git_clone https://github.com/KFERMercer/luci-app-tcpdump
git_clone https://github.com/jefferymvp/luci-app-koolproxyR
git_clone https://github.com/wolandmaster/luci-app-rtorrent
git_clone https://github.com/NateLol/luci-app-oled
git_clone https://github.com/hubbylei/luci-app-clash
git_clone https://github.com/destan19/OpenAppFilter && mvdir OpenAppFilter || exit 1
git_clone https://github.com/lvqier/luci-app-dnsmasq-ipset
git_clone https://github.com/walkingsky/luci-wifidog luci-app-wifidog
git_clone https://github.com/CCnut/feed-netkeeper && mvdir feed-netkeeper || exit 1
git_clone https://github.com/sensec/luci-app-udp2raw
git_clone https://github.com/LGA1150/openwrt-sysuh3c && mvdir openwrt-sysuh3c || exit 1

# 自动构建集成
git_clone https://github.com/Hyy2001X/AutoBuild-Packages && rm -rf AutoBuild-Packages/luci-app-adguardhome && mvdir AutoBuild-Packages || exit 1

# Dockerman & Cupsd
git_clone https://github.com/lisaac/luci-app-dockerman dockerman && mv -n dockerman/applications/* ./ && rm -rf dockerman
git_clone https://github.com/gdck/luci-app-cupsd cupsd1 && mv -n cupsd1/luci-app-cupsd cupsd1/cups/cups ./ && rm -rf cupsd1

# 墙纸 & 工具
git_clone https://github.com/kenzok8/wall && mv -n wall/* ./ && rm -rf wall
git_clone https://github.com/peter-tank/luci-app-fullconenat

# 更多集成包
git_clone https://github.com/sirpdboy/sirpdboy-package && mv -n sirpdboy-package/luci-app-dockerman ./ && rm -rf sirpdboy-package
git_clone https://github.com/sundaqiang/openwrt-packages && mv -n openwrt-packages/luci-* ./ && rm -rf openwrt-packages

# V2raya & 主题
git_clone https://github.com/zxlhhyccc/luci-app-v2raya
git_clone https://github.com/kenzok8/luci-theme-ifit ifit && mv -n ifit/luci-theme-ifit ./ && rm -rf ifit

# 支持工具 & 子包
git_clone https://github.com/kenzok78/openwrt-minisign
git_clone https://github.com/kenzok78/luci-theme-argone
git_clone https://github.com/kenzok78/luci-app-argone-config
git_clone https://github.com/kenzok78/luci-app-adguardhome
git_clone https://github.com/kenzok78/luci-theme-design
git_clone https://github.com/kenzok78/luci-app-design-config

exit 0
