#!/bin/bash

# 设备解析脚本
# 根据模式解析要构建的设备列表

# 参数说明：
# $1 - 设备模式 (all/config/specific)
# $2 - 设备配置名 (模式为config时使用)
# $3 - 特定设备列表 (模式为specific时使用，逗号分隔)
# $4 - 设备配置文件路径 (可选，默认为configs/devices.config)

DEVICE_MODE="$1"
DEVICE_CONFIG="$2"
SPECIFIC_DEVICES="$3"
DEVICE_CONFIG_FILE="${4:-configs/devices.config}"

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

# 验证设备是否存在
validate_device() {
    local device=$1
    if [ -d "configs/$device" ] || [ -d "configs/STANDALONE_CONF/$device" ]; then
        return 0
    else
        return 1
    fi
}

# 根据模式解析设备列表
case "$DEVICE_MODE" in
    "all")
        # 所有设备模式 - 扫描configs目录
        devices_json="["
        first=true

        # 扫描主设备目录
        for d in $(find configs -maxdepth 1 -type d ! -name "configs" ! -name "STANDALONE_CONF" ! -name "." -exec basename {} \;); do
            if [ "$first" = true ]; then
                devices_json="${devices_json}{\"name\":\"$d\",\"description\":\"Auto-detected\",\"source\":\"\"}"
                first=false
            else
                devices_json="${devices_json},{\"name\":\"$d\",\"description\":\"Auto-detected\",\"source\":\"\"}"
            fi
        done

        # 扫描独立配置目录
        if [ -d "configs/STANDALONE_CONF" ]; then
            for d in $(find configs/STANDALONE_CONF -maxdepth 1 -type d ! -name "STANDALONE_CONF" ! -name "." -exec basename {} \;); do
                if [ "$first" = true ]; then
                    devices_json="${devices_json}{\"name\":\"$d\",\"description\":\"Auto-detected\",\"source\":\"\"}"
                    first=false
                else
                    devices_json="${devices_json},{\"name\":\"$d\",\"description\":\"Auto-detected\",\"source\":\"\"}"
                fi
            done
        fi

        devices_json="${devices_json}]"
        echo "$devices_json"
        ;;
    "config")
        if [ -z "$DEVICE_CONFIG" ] || [ "$DEVICE_CONFIG" = "all" ]; then
            # 使用所有设备配置
            parse_device_config_file "$DEVICE_CONFIG_FILE"
        else
            # 使用特定设备配置
            devices_json=$(parse_device_config_file "$DEVICE_CONFIG_FILE")
            # 使用grep和sed来过滤特定配置
            if echo "$devices_json" | grep -q "\"name\":\"$DEVICE_CONFIG\""; then
                # 提取特定配置
                echo "$devices_json" | sed 's/},{/}\n{/g' | grep "\"name\":\"$DEVICE_CONFIG\""
            else
                echo "Error: Device config '$DEVICE_CONFIG' not found in $DEVICE_CONFIG_FILE" >&2
                echo "Available device configs:" >&2
                echo "$devices_json" | sed 's/},{/}\n{/g' | grep '"name":' | sed 's/.*"name":"\([^"]*\)".*/  - \1/' >&2
                exit 1
            fi
        fi
        ;;
    "specific")
        if [ -z "$SPECIFIC_DEVICES" ]; then
            echo "Error: devices parameter is required when device_mode=specific" >&2
            exit 1
        fi
        # 特定设备模式
        devices_json="["
        first=true
        IFS=',' read -ra DEVICE_ARRAY <<< "$SPECIFIC_DEVICES"
        for device in "${DEVICE_ARRAY[@]}"; do
            device=$(echo "$device" | xargs) # Trim whitespace
            if validate_device "$device"; then
                if [ "$first" = true ]; then
                    devices_json="${devices_json}{\"name\":\"$device\",\"description\":\"Manual selection\",\"source\":\"\"}"
                    first=false
                else
                    devices_json="${devices_json},{\"name\":\"$device\",\"description\":\"Manual selection\",\"source\":\"\"}"
                fi
            else
                echo "Warning: Device $device not found, skipping" >&2
            fi
        done
        devices_json="${devices_json}]"
        echo "$devices_json"
        ;;
    *)
        echo "Error: Invalid device_mode '$DEVICE_MODE'. Must be one of: all, config, specific" >&2
        exit 1
        ;;
esac