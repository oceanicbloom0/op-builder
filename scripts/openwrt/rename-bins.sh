#!/bin/bash

DATE=$(date +[%Y-%m-%d])

REPO_SANITIZED=$(echo "$SOURCE_URL" \
  | sed -E 's#https://github.com/([^/]+/[^/.]+)(\.git)?$#\1#' \
  | tr '/' '_')

# 执行重命名循环
for file in openwrt*; do
  mv -- "$file" \
    "[${REPO_SANITIZED}] ${DATE} ${FIRMWARE_NAME}${file#openwrt}"
done

# 查看最终结果
ls