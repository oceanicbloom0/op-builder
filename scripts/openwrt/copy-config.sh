#!/bin/bash

CONFIG_PATH="$GITHUB_WORKSPACE/configs/$DEVICE/.config"
STANDALONE_CONF_PATH="$GITHUB_WORKSPACE/configs/STANDALONE_CONF/$DEVICE/.config"

if [ -f "$CONFIG_PATH" ]; then
    cp "$CONFIG_PATH" "$OPENWRT_PATH/.config"
    if [ -n "$APP_CONFIG" ] && [ -f "$GITHUB_WORKSPACE/$APP_CONFIG" ]; then
        # Append additional app configuration if specified
        cat "$GITHUB_WORKSPACE/$APP_CONFIG" >>"$OPENWRT_PATH/.config"
    fi
elif [ -f "$STANDALONE_CONF_PATH" ]; then
    cp "$STANDALONE_CONF_PATH" "$OPENWRT_PATH/.config"
else
    echo "Error: .config file not found for DEVICE=$DEVICE"
    exit 1
fi
