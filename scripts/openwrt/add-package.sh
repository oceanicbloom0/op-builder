#!/bin/bash

cd package

## Passwall Tools
git clone --depth 1 https://github.com/vernesong/OpenClash && mv -n OpenClash/luci-app-openclash ./ && rm -rf OpenClash
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki && mv -n OpenWrt-nikki/luci-app-nikki OpenWrt-nikki/nikki ./ && rm -rf OpenWrt-nikki

## Amlogic
git clone --depth 1 https://github.com/ophub/luci-app-amlogic.git op-amlogic && mv -n op-amlogic/luci-app-amlogic ./ && rm -rf op-amlogic

## Themes
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git
exit 0
