#!/bin/bash

# 解析 sources.config 配置文件
# 输出格式：JSON 数组，包含所有源码配置

CONFIG_FILE="${1:-configs/sources.config}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found" >&2
    exit 1
fi

# 使用纯 Bash 解析 INI 格式的配置文件
output="["

current_section=""
first_section=true

while IFS= read -r line || [ -n "$line" ]; do
    # 跳过注释行和空行
    line_trimmed="$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [[ "$line_trimmed" =~ ^# ]] || [[ -z "$line_trimmed" ]]; then
        continue
    fi

    # 检测章节头
    if [[ "$line_trimmed" =~ ^\[.*\]$ ]]; then
        if [ "$current_section" != "" ]; then
            if [ "$first_section" = false ]; then
                output="${output}, "
            fi
            output="${output} }"
        fi

        current_section="$(echo "$line_trimmed" | sed 's/\[//; s/\]//')"
        output="${output} { \"name\": \"$current_section\""

        first_section=false
        continue
    fi

    # 解析键值对
    if [[ "$line_trimmed" =~ = ]] && [ "$current_section" != "" ]; then
        key="$(echo "$line_trimmed" | cut -d'=' -f1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        value="$(echo "$line_trimmed" | cut -d'=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

        if [[ "$key" =~ ^(source|branch|description)$ ]]; then
            output="${output}, \"$key\": \"$value\""
        fi
    fi
done < "$CONFIG_FILE"

if [ "$current_section" != "" ]; then
    output="${output} }"
fi

output="${output} ]"

# 使用 jq 格式化输出（如果可用）
if command -v jq >/dev/null 2>&1; then
    echo "$output" | jq '.'
else
    echo "$output"
fi