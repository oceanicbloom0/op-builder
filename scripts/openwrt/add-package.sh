#!/bin/bash

cd package

## Passwall Tools
svn co https://github.com/vernesong/trunk/OpenClash/luci-app-openclash luci-app-openclash
svn co https://github.com/nikkinikki-org/trunk/OpenWrt-nikki/luci-app-nikki luci-app-nikki

## Amlogic
svn co https://github.com/ophub/luci-app-amlogic/trunk/luci-app-amlogic luci-app-amlogic

## Themes
git clone --depth 1 https://github.com/derisamedia/luci-theme-alpha.git
git clone --depth 1 https://github.com/sirpdboy/luci-theme-kucat.git
