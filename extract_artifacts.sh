#!/usr/bin/env bash

IMAGE=$1
VERSION=$2

echo "[i] Clean dist folder"
rm -f -R ./dist
mkdir -p ./dist

for PLATFORM in linux/amd64 linux/arm64
do
    CONTAINER=$(docker create --platform ${PLATFORM} "${IMAGE}:${VERSION}")
    echo "[i] Created container ${CONTAINER:0:12}"

    echo "[i] Extract assets"
    docker cp "${CONTAINER}:/usr/sbin/nginx" ./dist/nginx

    echo "[i] Create distribution archive"
    XZ_OPT=-9 tar -C ./dist -Jcvf ./dist/nginx-http3-${PLATFORM/\//-}.tar.xz nginx

    echo "[i] Removing container ${CONTAINER:0:12}"
    docker rm $CONTAINER
done
