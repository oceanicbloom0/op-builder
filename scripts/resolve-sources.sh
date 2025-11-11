#!/bin/bash

# 源码和设备解析脚本
# 根据模式解析要构建的源码和设备列表

# 参数说明：
# $1 - 模式 (debug/config/all)
# $2 - 源码地址 (模式为debug时使用)
# $3 - 源码分支 (模式为debug时使用)
# $4 - 配置名称 (模式为config时使用)
# $5 - 设备配置名 (可为 'all' 表示全部，或用逗号分隔多个设备名)
# $6 - 调试模式设备名 (模式为debug时使用)
# $7 - 源码配置文件路径 (可选，默认为configs/sources.config)
# $8 - 设备配置文件路径 (可选，默认为configs/devices.config)

MODE="$1"
SOURCE_URL="$2"
SOURCE_BRANCH="$3"
CONFIG_NAME="$4"
DEVICE_CONFIG="$5"
DEBUG_DEVICE="$6"
CONFIG_FILE="${7:-configs/sources.config}"
DEVICE_CONFIG_FILE="${8:-configs/devices.config}"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found" >&2
    exit 1
fi

# 解析设备配置文件函数
parse_device_config_file() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        echo "Error: Device config file $config_file not found" >&2
        exit 1
    fi

    # 使用临时文件存储设备对象
    TEMP_FILE=$(mktemp)

    current_section=""

    while IFS= read -r line || [ -n "$line" ]; do
        # 跳过注释行和空行
        line_trimmed="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        if [[ "$line_trimmed" =~ ^# ]] || [[ -z "$line_trimmed" ]]; then
            continue
        fi

        # 检测章节头
        if [[ "$line_trimmed" =~ ^\[.*\]$ ]]; then
            # 如果之前有章节，写入临时文件
            if [ "$current_section" != "" ]; then
                echo "{\"name\":\"$current_section\",\"description\":\"$current_description\",\"sources\":\"$current_sources\"}" >> "$TEMP_FILE"
            fi

            current_section="$(echo "$line_trimmed" | sed 's/\[//; s/\]//')"
            current_description=""
            current_sources=""
            continue
        fi

        # 解析键值对
        if [[ "$line_trimmed" =~ = ]] && [ "$current_section" != "" ]; then
            key="$(echo "$line_trimmed" | cut -d'=' -f1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
            value="$(echo "$line_trimmed" | cut -d'=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

            case "$key" in
                "description")
                    current_description="$value"
                    ;;
                "source"|"sources")
                    current_sources="$value"
                    ;;
            esac
        fi
    done < "$config_file"

    # 写入最后一个章节
    if [ "$current_section" != "" ]; then
        echo "{\"name\":\"$current_section\",\"description\":\"$current_description\",\"sources\":\"$current_sources\"}" >> "$TEMP_FILE"
    fi

    # 构建 JSON 数组
    output="["
    first=true
    while IFS= read -r line; do
        if [ "$first" = true ]; then
            output="${output}${line}"
            first=false
        else
            output="${output},${line}"
        fi
    done < "$TEMP_FILE"
    output="${output}]"

    # 清理临时文件
    rm -f "$TEMP_FILE"

    # 使用 jq 格式化输出（如果可用）
    if command -v jq >/dev/null 2>&1; then
        echo "$output" | jq -c '.'
    else
        echo "$output"
    fi
}

# 解析配置文件函数
parse_config_file() {
    ./scripts/parse-sources-config.sh "$CONFIG_FILE"
}

# 解析设备配置
resolve_devices() {
    if [ -z "$DEVICE_CONFIG" ]; then
        echo "Error: device_config is required" >&2
        echo "Please specify device config name(s) separated by commas or 'all' for all devices" >&2
        exit 1
    fi

    if [ "$DEVICE_CONFIG" = "all" ]; then
        # 所有设备模式 - 扫描configs目录
        devices_json="["
        first=true

        # 扫描主设备目录
        for d in $(find configs -maxdepth 1 -type d ! -name "configs" ! -name "STANDALONE_CONF" ! -name "." -exec basename {} \;); do
            if [ "$first" = true ]; then
                devices_json="${devices_json}{\"name\":\"$d\",\"description\":\"Auto-detected\",\"sources\":\"\"}"
                first=false
            else
                devices_json="${devices_json},{\"name\":\"$d\",\"description\":\"Auto-detected\",\"sources\":\"\"}"
            fi
        done

        # 扫描独立配置目录
        if [ -d "configs/STANDALONE_CONF" ]; then
            for d in $(find configs/STANDALONE_CONF -maxdepth 1 -type d ! -name "STANDALONE_CONF" ! -name "." -exec basename {} \;); do
                if [ "$first" = true ]; then
                    devices_json="${devices_json}{\"name\":\"$d\",\"description\":\"Auto-detected\",\"sources\":\"\"}"
                    first=false
                else
                    devices_json="${devices_json},{\"name\":\"$d\",\"description\":\"Auto-detected\",\"sources\":\"\"}"
                fi
            done
        fi

        devices_json="${devices_json}]"
        echo "$devices_json"
    else
        # 使用逗号分隔的特定设备配置
        devices_json=$(parse_device_config_file "$DEVICE_CONFIG_FILE")

        # 将逗号分隔的设备列表转换为数组
        IFS=',' read -ra device_list <<< "$DEVICE_CONFIG"

        # 构建结果数组
        result_json="["
        first=true
        found_devices=0

        # 遍历每个请求的设备
        for device in "${device_list[@]}"; do
            device=$(echo "$device" | xargs) # 去除空格
            device_found=false

            # 在设备配置中查找匹配的设备
            while IFS= read -r device_obj; do
                if echo "$device_obj" | grep -q "\"name\":\"$device\""; then
                    if [ "$first" = true ]; then
                        result_json="${result_json}${device_obj}"
                        first=false
                    else
                        result_json="${result_json},${device_obj}"
                    fi
                    device_found=true
                    found_devices=$((found_devices + 1))
                    break
                fi
            done < <(echo "$devices_json" | sed 's/},{/}\n{/g')

            if [ "$device_found" = false ]; then
                echo "Warning: Device config '$device' not found in $DEVICE_CONFIG_FILE" >&2
            fi
        done

        result_json="${result_json}]"

        # 检查是否至少找到一个设备
        if [ "$found_devices" -eq 0 ]; then
            echo "Error: None of the specified device configs were found in $DEVICE_CONFIG_FILE" >&2
            echo "Available device configs:" >&2
            echo "$devices_json" | sed 's/},{/}\n{/g' | grep '\"name\":' | sed 's/.*\"name\":\"\([^\"]*\)\".*/  - \1/' >&2
            exit 1
        fi

        echo "$result_json"
    fi
}

# 根据模式解析源码和设备配置
case "$MODE" in
    "debug")
        if [ -z "$SOURCE_URL" ]; then
            echo "Error: source_url is required when mode=debug" >&2
            exit 1
        fi
        # 如果没有指定分支，使用默认值
        if [ -z "$SOURCE_BRANCH" ]; then
            SOURCE_BRANCH="master"
        fi
        # 调试模式 - 创建一个临时的源码配置
        sources_json="[{\"name\":\"custom\",\"source\":\"$SOURCE_URL\",\"branch\":\"$SOURCE_BRANCH\",\"description\":\"Debug source URL\"}]"

        # 如果是debug模式，使用debug_device
        if [ -z "$DEBUG_DEVICE" ]; then
            echo "Error: debug_device is required when mode=debug" >&2
            exit 1
        fi
        # 验证设备是否存在
        if [ ! -d "configs/$DEBUG_DEVICE" ] && [ ! -d "configs/STANDALONE_CONF/$DEBUG_DEVICE" ]; then
            echo "Error: Device '$DEBUG_DEVICE' not found in configs/ or configs/STANDALONE_CONF/" >&2
            exit 1
        fi
        devices_json="[{\"name\":\"$DEBUG_DEVICE\",\"description\":\"Debug device\",\"sources\":\"\"}]"
        ;;
    "config")
        if [ -z "$CONFIG_NAME" ] || [ "$CONFIG_NAME" = "all" ]; then
            # 使用所有配置
            sources_json=$(parse_config_file)
        else
            # 使用特定配置
            sources_json=$(parse_config_file)
            # 使用grep和sed来过滤特定配置
            if echo "$sources_json" | grep -q "\"name\":\"$CONFIG_NAME\""; then
                # 提取特定配置 - 使用更精确的匹配
                # 将整个JSON数组拆分为单独的对象，然后过滤
                sources_json=$(echo "$sources_json" | sed 's/},{/}\n{/g' | grep "\"name\":\"$CONFIG_NAME\"")
            else
                echo "Error: Config '$CONFIG_NAME' not found in $CONFIG_FILE" >&2
                echo "Available configs:" >&2
                echo "$sources_json" | sed 's/},{/}\n{/g' | grep '\"name\":' | sed 's/.*\"name\":\"\([^\"]*\)\".*/  - \1/' >&2
                exit 1
            fi
        fi
        devices_json=$(resolve_devices)
        ;;
    "all")
        # 使用所有配置
        sources_json=$(parse_config_file)
        devices_json=$(resolve_devices)
        ;;
    *)
        echo "Error: Invalid mode '$MODE'. Must be one of: debug, config, all" >&2
        exit 1
        ;;
esac

# 输出源码和设备配置
output="{\"sources\":$sources_json,\"devices\":$devices_json}"

# 使用 jq 格式化输出（如果可用）
if command -v jq >/dev/null 2>&1; then
    echo "$output" | jq -c '.'
else
    echo "$output"
fi