#!/bin/bash

# 工具函数：格式化输出函数
append_section() {
    local title="$1"
    local pattern="$2"

    echo "### $title"

    grep -i "$pattern" .config | grep -v '^#' |
        sed '/INCLUDE/d; s/CONFIG_PACKAGE_/、/g; s/=y//g' |
        awk '{ print NR $0 }'

    echo ""
}

# 插件部分
append_section "插件" "CONFIG_PACKAGE_luci-app"

# 主题部分
append_section "主题" "CONFIG_PACKAGE_luci-theme"

# 原始配置（插件 + 主题）
echo "### 配置（luci）"
grep -i CONFIG_PACKAGE_luci-app .config | grep -v '^#' || true
grep -i CONFIG_PACKAGE_luci-theme .config | grep -v '^#' || true
