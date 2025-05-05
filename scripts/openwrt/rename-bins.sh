#!/bin/bash

DATE=$(date +[%Y-%m-%d])
REPO=$(echo "$SOURCE_URL" | sed -E 's#https://github.com/([^/]+/[^/.]+)(\.git)?$#\1#')

# 重命名
for file in openwrt*; do
    newname="[${REPO}] ${DATE} ${FIRMWARE_NAME}${file#openwrt}"
    mv -- "$file" "$newname"
done