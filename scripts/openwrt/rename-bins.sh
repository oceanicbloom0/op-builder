#!/bin/bash

TIMESTAMP=$(date +%Y%m%d%H%M)
SOURCE_REPO=$(basename "$SOURCE_URL" .git)
SOURCE_REPO_CLEANED=$(echo "$SOURCE_REPO" | sed 's#[^A-Za-z0-9._-]#-#g')
SOURCE_BRANCH_CLEANED=$(echo "$SOURCE_BRANCH" | sed 's#[^A-Za-z0-9._-]#-#g')
BUILD_TAG="[${TIMESTAMP}][${ARCH}][${SOURCE_REPO_CLEANED}-${SOURCE_BRANCH_CLEANED}]"

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

    newname="${BUILD_TAG}-${FIRMWARE_NAME}${suffix}"
    mv -- "$file" "$newname"
done
