#!/bin/bash

cd package

## Passwall Tools
git clone --depth 1 https://github.com/vernesong/OpenClash && mv -n OpenClash/luci-app-openclash ./
rm -rf OpenClash
git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki && mv -n OpenWrt-nikki/luci-app-nikki ./
rm -rf OpenWrt-nikki

## Amlogic
git clone --depth 1 https://github.com/ophub/luci-app-amlogic.git op-amlogic && mv -n op-amlogic/luci-app-amlogic ./
rm -rf op-amlogic

## Themes
git clone --depth 1 https://github.com/derisamedia/luci-theme-alpha.git
git clone --depth 1 https://github.com/sirpdboy/luci-theme-kucat.git
