#!/bin/bash

# 定义辅助函数

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
git clone --depth 1 https://github.com/kiddin9/luci-app-dnsfilter
git clone --depth 1 https://github.com/peter-tank/luci-app-dnscrypt-proxy2
git clone --depth 1 https://github.com/peter-tank/luci-app-autorepeater

# 下载工具
git clone --depth 1 https://github.com/kiddin9/aria2

# 百度网盘 Web 管理
git clone --depth 1 https://github.com/kiddin9/luci-app-baidupcs-web

# 文件同步与分享
git clone --depth 1 https://github.com/kiddin9/autoshare && mvdir autoshare || exit 1

# OpenVPN
git clone --depth 1 https://github.com/kiddin9/openwrt-openvpn && mvdir openwrt-openvpn || exit 1

# Xray
git clone --depth 1 https://github.com/yichya/luci-app-xray

git clone --depth 1 https://github.com/Lienol/openwrt-package

git clone --depth 1 https://github.com/ysc3839/openwrt-minieap

git clone --depth 1 https://github.com/ysc3839/luci-proto-minieap

git clone --depth 1 https://github.com/BoringCat/luci-app-mentohust

git clone --depth 1 https://github.com/BoringCat/luci-app-minieap

# 用户在线统计
git clone --depth 1 https://github.com/ElvenP/luci-app-onliner

# USB3 禁用
git clone --depth 1 https://github.com/rufengsuixing/luci-app-usb3disable

# IPTV 辅助
git clone --depth 1 https://github.com/riverscn/openwrt-iptvhelper && mvdir openwrt-iptvhelper || exit 1

# MentoHUST
git clone --depth 1 https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk

# 其他应用
git clone --depth 1 https://github.com/NateLol/luci-app-beardropper

# 代理与加速
git clone --depth 1 https://github.com/yaof2/luci-app-ikoolproxy
git clone --depth 1 https://github.com/project-lede/luci-app-godproxy

# 微信推送 (18.06)
git clone --depth 1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush

git clone --depth 1 https://github.com/4IceG/luci-app-sms-tool smstool && mvdir smstool || exit 1

# 迅雷下载
git clone --depth 1 https://github.com/silime/luci-app-xunlei

git clone --depth 1 https://github.com/BCYDTZ/luci-app-UUGameAcc

git clone --depth 1 https://github.com/ntlf9t/luci-app-easymesh

git clone --depth 1 https://github.com/zzsj0928/luci-app-pushbot

git clone --depth 1 https://github.com/shanglanxin/luci-app-homebridge

git clone --depth 1 https://github.com/esirplayground/luci-app-poweroff

git clone --depth 1 https://github.com/esirplayground/LingTiGameAcc

git clone --depth 1 https://github.com/esirplayground/luci-app-LingTiGameAcc

git clone --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon wrtbwmon1 && mvdir wrtbwmon1 || exit 1

git clone --depth 1 https://github.com/brvphoenix/wrtbwmon wrtbwmon2 && mvdir wrtbwmon2 || exit 1

# 主题与界面配置
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config

git clone --depth 1 https://github.com/jerrykuku/luci-app-ttnode

git clone --depth 1 https://github.com/jerrykuku/luci-app-go-aliyundrive-webdav

git clone --depth 1 https://github.com/jerrykuku/lua-maxminddb

# ChatGPT Web 接口
git clone --depth 1 https://github.com/sirpdboy/luci-app-chatgpt-web

# DDNS 与测速
git clone --depth 1 https://github.com/sirpdboy/luci-app-ddns-go ddnsgo && mv -n ddnsgo/luci-app-ddns-go ./ && rm -rf ddnsgo

# Speedtest & 网络监测
git clone --depth 1 https://github.com/sirpdboy/netspeedtest speedtest && mv -f speedtest/*/ ./ && rm -rf speedtest

# 其他工具
git clone --depth 1 https://github.com/KFERMercer/luci-app-tcpdump
git clone --depth 1 https://github.com/jefferymvp/luci-app-koolproxyR
git clone --depth 1 https://github.com/wolandmaster/luci-app-rtorrent
git clone --depth 1 https://github.com/NateLol/luci-app-oled
git clone --depth 1 https://github.com/hubbylei/luci-app-clash
git clone --depth 1 https://github.com/destan19/OpenAppFilter && mvdir OpenAppFilter || exit 1
git clone --depth 1 https://github.com/lvqier/luci-app-dnsmasq-ipset
git clone --depth 1 https://github.com/walkingsky/luci-wifidog luci-app-wifidog
git clone --depth 1 https://github.com/CCnut/feed-netkeeper && mvdir feed-netkeeper || exit 1
git clone --depth 1 https://github.com/sensec/luci-app-udp2raw
git clone --depth 1 https://github.com/LGA1150/openwrt-sysuh3c && mvdir openwrt-sysuh3c || exit 1

# 自动构建集成
git clone --depth 1 https://github.com/Hyy2001X/AutoBuild-Packages && rm -rf AutoBuild-Packages/luci-app-adguardhome && mvdir AutoBuild-Packages || exit 1

# Dockerman & Cupsd
git clone --depth 1 https://github.com/lisaac/luci-app-dockerman dockerman && mv -n dockerman/applications/* ./ && rm -rf dockerman
git clone --depth 1 https://github.com/gdck/luci-app-cupsd cupsd1 && mv -n cupsd1/luci-app-cupsd cupsd1/cups/cups ./ && rm -rf cupsd1

# 墙纸 & 工具
git clone --depth 1 https://github.com/kenzok8/wall && mv -n wall/* ./ && rm -rf wall
git clone --depth 1 https://github.com/peter-tank/luci-app-fullconenat

# 更多集成包
git clone --depth 1 https://github.com/sirpdboy/sirpdboy-package && mv -n sirpdboy-package/luci-app-dockerman ./ && rm -rf sirpdboy-package
git clone --depth 1 https://github.com/sundaqiang/openwrt-packages && mv -n openwrt-packages/luci-* ./ && rm -rf openwrt-packages

# V2raya & 主题
git clone --depth 1 https://github.com/zxlhhyccc/luci-app-v2raya
git clone --depth 1 https://github.com/kenzok8/luci-theme-ifit ifit && mv -n ifit/luci-theme-ifit ./ && rm -rf ifit

# 支持工具 & 子包
git clone --depth 1 https://github.com/kenzok78/openwrt-minisign
git clone --depth 1 https://github.com/kenzok78/luci-theme-argone
git clone --depth 1 https://github.com/kenzok78/luci-app-argone-config
git clone --depth 1 https://github.com/kenzok78/luci-app-adguardhome
git clone --depth 1 https://github.com/kenzok78/luci-theme-design
git clone --depth 1 https://github.com/kenzok78/luci-app-design-config

exit 0
