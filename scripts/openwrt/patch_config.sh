#!/bin/bash

set -e

# 如果是独立配置，跳过此脚本
STANDALONE_CONF_PATH="$GITHUB_WORKSPACE/configs/STANDALONE_CONF/$DEVICE/.config"
if [ -f "$STANDALONE_CONF_PATH" ]; then
    echo "Standalone configuration: Skipping patch_config.sh"
    exit 0
fi


CONFIG_FILE="$OPENWRT_PATH/.config"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 未找到 .config，请先运行 make defconfig"
    exit 1
fi

# 删除 CONFIG_DEFAULT_luci 条目
sed -i '/CONFIG_DEFAULT_luci/'d "$CONFIG_FILE"

# 显式禁止 dnsmasq，启用 dnsmasq-full
echo "📦 清理旧配置条目..."
sed -i '/^CONFIG_PACKAGE_dnsmasq[ =]/d' "$CONFIG_FILE"
sed -i '/^CONFIG_PACKAGE_dnsmasq-full[ =]/d' "$CONFIG_FILE"
echo "CONFIG_PACKAGE_dnsmasq=n" >>"$CONFIG_FILE"
echo "CONFIG_PACKAGE_dnsmasq-full=y" >>"$CONFIG_FILE"
