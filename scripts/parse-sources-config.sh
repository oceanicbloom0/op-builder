#!/bin/bash

# 解析 sources.config 配置文件
# 输出格式：JSON 数组，包含所有源码配置

CONFIG_FILE="${1:-configs/sources.config}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file $CONFIG_FILE not found" >&2
    exit 1
fi

# 使用临时文件存储配置对象
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
            echo "{\"name\":\"$current_section\",\"source\":\"$current_source\",\"branch\":\"$current_branch\",\"description\":\"$current_description\"}" >> "$TEMP_FILE"
        fi

        current_section="$(echo "$line_trimmed" | sed 's/\[//; s/\]//')"
        current_source=""
        current_branch=""
        current_description=""
        continue
    fi

    # 解析键值对
    if [[ "$line_trimmed" =~ = ]] && [ "$current_section" != "" ]; then
        key="$(echo "$line_trimmed" | cut -d'=' -f1 | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
        value="$(echo "$line_trimmed" | cut -d'=' -f2- | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

        case "$key" in
            "source")
                current_source="$value"
                ;;
            "branch")
                current_branch="$value"
                ;;
            "description")
                current_description="$value"
                ;;
        esac
    fi
done < "$CONFIG_FILE"

# 写入最后一个章节
if [ "$current_section" != "" ]; then
    echo "{\"name\":\"$current_section\",\"source\":\"$current_source\",\"branch\":\"$current_branch\",\"description\":\"$current_description\"}" >> "$TEMP_FILE"
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