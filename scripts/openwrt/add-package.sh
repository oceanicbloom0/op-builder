#!/bin/bash

cd package/feeds/luci

git_clone_clean() {
    local repo="$1"
    local dir
    
    dir="$(basename "$repo" .git)"
    
    if ! git clone --depth 1 "$repo" "$dir"; then
        echo "Clone failed. Removing existing directory: $dir"
        rm -rf -- "$dir"
        git clone --depth 1 "$repo" "$dir"
    fi
}


## Passwall Tools
git_clone_clean  https://github.com/vernesong/OpenClash && mv -n OpenClash/luci-app-openclash ./ && rm -rf OpenClash
git_clone_clean https://github.com/nikkinikki-org/OpenWrt-nikki && mv -n OpenWrt-nikki/luci-app-nikki OpenWrt-nikki/nikki ./ && rm -rf OpenWrt-nikki

## Amlogic
git_clone_clean https://github.com/ophub/luci-app-amlogic.git op-amlogic && mv -n op-amlogic/luci-app-amlogic ./ && rm -rf op-amlogic

## Themes
git_clone_clean https://github.com/jerrykuku/luci-theme-argon.git
git_clone_clean https://github.com/jerrykuku/luci-app-argon-config.git
git_clone_clean https://github.com/AngelaCooljx/luci-theme-material3.git

# 更改 material3 主题 makefile
sed -i 's#^include \.\./\.\./luci.mk#include $(TOPDIR)/feeds/luci/luci.mk#' luci-theme-material3/Makefile
exit 0
