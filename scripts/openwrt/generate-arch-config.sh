#!/bin/bash

# 从架构字符串中提取target和subtarget
IFS='_' read -r target subtarget <<< "$ARCH"

# 生成基本的架构配置
echo "CONFIG_TARGET_${target}=y" > "$OPENWRT_PATH/.config"
echo "CONFIG_TARGET_${target}_${subtarget}=y" >> "$OPENWRT_PATH/.config"

# 禁用所有设备特定的配置（toolchain不需要设备配置）
echo "# CONFIG_TARGET_${target}_${subtarget}_DEVICE_* is not set" >> "$OPENWRT_PATH/.config"

# 添加toolchain构建所需的通用配置
echo "CONFIG_ALL=y" >> "$OPENWRT_PATH/.config"
echo "CONFIG_ALL_NONSHARED=y" >> "$OPENWRT_PATH/.config"

# 添加其他必要的toolchain配置
echo "CONFIG_DEVEL=y" >> "$OPENWRT_PATH/.config"
echo "CONFIG_CCACHE=y" >> "$OPENWRT_PATH/.config"

# 如果指定了额外的应用配置，追加它
if [ -n "$APP_CONFIG" ] && [ -f "$GITHUB_WORKSPACE/$APP_CONFIG" ]; then
    cat "$GITHUB_WORKSPACE/$APP_CONFIG" >> "$OPENWRT_PATH/.config"
fi