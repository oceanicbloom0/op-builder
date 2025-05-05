#!/bin/bash

DATE=$(date +[%Y-%m-%d])
REPO=$(echo "$SOURCE_URL" | sed -E 's#.*/([^/]+/[^/.]+)(\.git)?$#\1#')

for file in openwrt*; do
    newname=$(echo "$file" | sed "s/^openwrt/[$REPO] ${DATE} ${FIRMWARE_NAME}/")
    mv "$file" "$newname"
done
