#!/bin/bash

resolve_auto_app_configs() {
    local source_url="${SOURCE_URL:-}"
    local source_branch="${SOURCE_BRANCH:-}"
    local repo_name
    local branch_name

    repo_name="${source_url##*/}"
    repo_name="${repo_name%.git}"
    repo_name="${repo_name//[^A-Za-z0-9._-]/-}"
    branch_name="${source_branch//\//-}"
    branch_name="${branch_name//[^A-Za-z0-9._-]/-}"

    local candidates=(
        "configs/apps/common.config"
    )

    if [ -n "$repo_name" ]; then
        candidates+=("configs/apps/$repo_name.config")
        if [ -n "$branch_name" ]; then
            candidates+=("configs/apps/$repo_name-$branch_name.config")
        fi
    fi

    local resolved=()
    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -f "$GITHUB_WORKSPACE/$candidate" ]; then
            resolved+=("$candidate")
        else
            echo "Auto app config not found, skipping: $candidate" >&2
        fi
    done

    local IFS=,
    echo "${resolved[*]}"
}

append_app_configs() {
    local app_config="${APP_CONFIG:-}"

    if [ -z "$app_config" ]; then
        echo "APP_CONFIG is empty, skipping app overlays"
        return
    fi

    if [ "$app_config" = "auto" ]; then
        app_config="$(resolve_auto_app_configs)"
        if [ -z "$app_config" ]; then
            echo "APP_CONFIG=auto resolved to no files, skipping app overlays"
            return
        fi
        echo "APP_CONFIG=auto resolved to: $app_config"
    fi

    IFS=',' read -ra APP_CONFIG_ARRAY <<< "$app_config"
    local entry
    for entry in "${APP_CONFIG_ARRAY[@]}"; do
        entry="$(echo "$entry" | xargs)"
        if [ -z "$entry" ]; then
            continue
        fi

        if [ ! -f "$GITHUB_WORKSPACE/$entry" ]; then
            echo "Error: app config file not found: $entry"
            exit 1
        fi

        echo "Appending app config: $entry"
        cat "$GITHUB_WORKSPACE/$entry" >>"$OPENWRT_PATH/.config"
    done
}

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
append_app_configs
