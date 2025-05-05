#!/bin/bash

DATE=$(date +[%Y-%m-%d])
REPO=$(echo "$SOURCE_URL" | sed -E 's#https://github.com/([^/]+/[^/.]+)(\.git)?$#\1#')
REPO_CLEANED=$(echo "$REPO" | tr '/' '-')  # 替换掉 /

# 重命名
for file in openwrt*; do
    newname="[${REPO_CLEANED}] ${DATE} ${FIRMWARE_NAME}${file#openwrt}"
    mv -- "$file" "$newname"
done

# 查看结果
ls