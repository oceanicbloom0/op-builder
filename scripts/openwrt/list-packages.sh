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

# Plugins
append_section "Plugins" "CONFIG_PACKAGE_luci-app"

# Themes
append_section "Themes" "CONFIG_PACKAGE_luci-theme"
