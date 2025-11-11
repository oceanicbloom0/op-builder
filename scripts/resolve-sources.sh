#!/bin/bash

# 源码解析脚本
# 根据模式解析要构建的源码列表

# 参数说明：
# $1 - 模式 (single/config/all)
# $2 - 源码地址 (模式为single时使用)
# $3 - 配置名称 (模式为config时使用)
# $4 - 配置文件路径 (可选，默认为configs/sources.config)

MODE="$1"
SOURCE_URL="$2"
CONFIG_NAME="$3"
CONFIG_FILE="${4:-configs/sources.config}"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found" >&2
    exit 1
fi

# 解析配置文件函数
parse_config_file() {
    ./scripts/parse-sources-config.sh "$CONFIG_FILE"
}

# 根据模式解析源码列表
case "$MODE" in
    "single")
        if [ -z "$SOURCE_URL" ]; then
            echo "Error: source_url is required when mode=single" >&2
            exit 1
        fi
        # 单个源码模式 - 创建一个临时的源码配置
        echo "["
        echo "  {"
        echo "    \"name\": \"custom\","
        echo "    \"source\": \"$SOURCE_URL\","
        echo "    \"branch\": \"master\","
        echo "    \"description\": \"Custom source URL\""
        echo "  }"
        echo "]"
        ;;
    "config")
        if [ -z "$CONFIG_NAME" ] || [ "$CONFIG_NAME" = "all" ]; then
            # 使用所有配置
            parse_config_file
        else
            # 使用特定配置
            sources_json=$(parse_config_file)
            # 使用grep和sed来过滤特定配置（不使用jq）
            if echo "$sources_json" | grep -q "\"name\": \"$CONFIG_NAME\""; then
                # 提取特定配置
                echo "$sources_json" | sed -n '/{/,/}/p' | grep -A 100 "\"name\": \"$CONFIG_NAME\"" | sed -n '/{/,/}/p' | head -n 5
            else
                echo "Error: Config '$CONFIG_NAME' not found in $CONFIG_FILE" >&2
                echo "Available configs:" >&2
                echo "$sources_json" | grep '"name":' | sed 's/.*"name": "\([^"]*\)".*/  - \1/' >&2
                exit 1
            fi
        fi
        ;;
    "all")
        # 使用所有配置
        parse_config_file
        ;;
    *)
        echo "Error: Invalid mode '$MODE'. Must be one of: single, config, all" >&2
        exit 1
        ;;
esac