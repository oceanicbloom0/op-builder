#!/bin/bash
#!/bin/bash

DATE=$(date +[%Y-%m-%d])
REPO=$(echo "$SOURCE_URL" | sed -E 's#https://github.com/([^/]+/[^/.]+)(\.git)?$#\1#')
REPO_CLEANED=$(echo "$REPO" | tr '/' '-')  # 替换掉 /

# 重命名
# 重命名
for file in *; do
    # 跳过目录
    [ -d "$file" ] && continue
    # 跳过特定文件
    case "$file" in
        "sha256sums"|"config.buildinfo"|"profiles.json"|"rename-bins.sh") continue ;;
    esac

    # 动态获取后缀（去除第一个 - 之前的内容）
    # 如果文件名中没有 -，则保留原文件名（或者根据需求处理，这里假设固件文件名都有 -）
    if [[ "$file" == *-* ]]; then
        suffix="-${file#*-}"
    else
        suffix="$file"
    fi
    
    newname="[${REPO_CLEANED}] ${DATE} ${FIRMWARE_NAME}${suffix}"
    mv -- "$file" "$newname"
done