#!/bin/bash

CONFIG_PATH="$GITHUB_WORKSPACE/configs/$DEVICE/.config"
STANDALONE_CONF_PATH="$GITHUB_WORKSPACE/configs/STANDALONE_CONF/$DEVICE/.config"

echo "=== copy-config.sh Debug Info ==="
echo "DEVICE: $DEVICE"
echo "APP_CONFIG: $APP_CONFIG"
echo "CONFIG_PATH: $CONFIG_PATH"
echo "STANDALONE_CONF_PATH: $STANDALONE_CONF_PATH"
echo "OPENWRT_PATH: $OPENWRT_PATH"

if [ -f "$CONFIG_PATH" ]; then
    echo "Found device config at: $CONFIG_PATH"
    cp "$CONFIG_PATH" "$OPENWRT_PATH/.config"
    if [ -n "$APP_CONFIG" ] && [ -f "$GITHUB_WORKSPACE/$APP_CONFIG" ]; then
        echo "APP_CONFIG is set and file exists: $GITHUB_WORKSPACE/$APP_CONFIG"
        echo "Appending app.config contents to .config..."
        # Append additional app configuration if specified
        cat "$GITHUB_WORKSPACE/$APP_CONFIG" >>"$OPENWRT_PATH/.config"
        echo "Successfully appended app.config to .config"
    else
        echo "APP_CONFIG not set or file not found: APP_CONFIG='$APP_CONFIG', file exists: $([ -f "$GITHUB_WORKSPACE/$APP_CONFIG" ] && echo "YES" || echo "NO")"
    fi
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
    cp "$STANDALONE_CONF_PATH" "$OPENWRT_PATH/.config"
    if [ -n "$APP_CONFIG" ] && [ -f "$GITHUB_WORKSPACE/$APP_CONFIG" ]; then
        echo "APP_CONFIG is set and file exists: $GITHUB_WORKSPACE/$APP_CONFIG"
        echo "Appending app.config contents to .config..."
        # Append additional app configuration if specified
        cat "$GITHUB_WORKSPACE/$APP_CONFIG" >>"$OPENWRT_PATH/.config"
        echo "Successfully appended app.config to .config"
    else
        echo "APP_CONFIG not set or file not found: APP_CONFIG='$APP_CONFIG', file exists: $([ -f "$GITHUB_WORKSPACE/$APP_CONFIG" ] && echo "YES" || echo "NO")"
    fi
    # Append theme configuration
    if [ -f "$GITHUB_WORKSPACE/configs/theme.config" ]; then
        cat "$GITHUB_WORKSPACE/configs/theme.config" >>"$OPENWRT_PATH/.config"
    fi
    # Append ccache configuration
    if [ -f "$GITHUB_WORKSPACE/configs/ccache.config" ]; then
        cat "$GITHUB_WORKSPACE/configs/ccache.config" >>"$OPENWRT_PATH/.config"
    fi
else
    echo "Error: .config file not found for DEVICE=$DEVICE"
    exit 1
fi
