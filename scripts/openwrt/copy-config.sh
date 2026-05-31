#!/bin/bash

CONFIG_PATH="$GITHUB_WORKSPACE/configs/$DEVICE/.config"
STANDALONE_CONF_PATH="$GITHUB_WORKSPACE/configs/STANDALONE_CONF/$DEVICE/.config"

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

echo "=== copy-config.sh Debug Info ==="
echo "DEVICE: $DEVICE"
echo "APP_CONFIG: $APP_CONFIG"
echo "SOURCE_URL: ${SOURCE_URL:-}"
echo "SOURCE_BRANCH: ${SOURCE_BRANCH:-}"
echo "CONFIG_PATH: $CONFIG_PATH"
echo "STANDALONE_CONF_PATH: $STANDALONE_CONF_PATH"
echo "OPENWRT_PATH: $OPENWRT_PATH"

# Debug: Check if OPENWRT_PATH exists and is writable
echo "=== File System Debug ==="
echo "Current directory: $(pwd)"
echo "OPENWRT_PATH exists: $([ -d "$OPENWRT_PATH" ] && echo "YES" || echo "NO")"
echo "OPENWRT_PATH permissions: $(ls -ld "$OPENWRT_PATH" 2>/dev/null || echo "NOT FOUND")"
echo "GITHUB_WORKSPACE: $GITHUB_WORKSPACE"

if [ -f "$CONFIG_PATH" ]; then
    echo "Found device config at: $CONFIG_PATH"
    echo "Copying config to: $OPENWRT_PATH/.config"
    cp "$CONFIG_PATH" "$OPENWRT_PATH/.config"
    echo "Copy result: $?"
    echo "Target file exists: $([ -f "$OPENWRT_PATH/.config" ] && echo "YES" || echo "NO")"
    append_app_configs
    # Append theme configuration
    if [ -f "$GITHUB_WORKSPACE/configs/theme.config" ]; then
        cat "$GITHUB_WORKSPACE/configs/theme.config" >>"$OPENWRT_PATH/.config"
    fi
    # Append ccache configuration
    if [ -f "$GITHUB_WORKSPACE/configs/ccache.config" ]; then
        cat "$GITHUB_WORKSPACE/configs/ccache.config" >>"$OPENWRT_PATH/.config"
    fi
elif [ -f "$STANDALONE_CONF_PATH" ]; then
    echo "Found standalone config at: $STANDALONE_CONF_PATH"
    echo "Copying config to: $OPENWRT_PATH/.config"
    cp "$STANDALONE_CONF_PATH" "$OPENWRT_PATH/.config"
    echo "Copy result: $?"
    echo "Target file exists: $([ -f "$OPENWRT_PATH/.config" ] && echo "YES" || echo "NO")"
    echo "Standalone configuration: Skipping merge with app.config, theme.config, and ccache.config"

else
    echo "Error: .config file not found for DEVICE=$DEVICE"
    exit 1
fi
