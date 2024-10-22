#!/usr/bin/env bash

IMAGE=$1
VERSION=$2
LIBRARY=$3

echo "[i] Clean dist folder"
rm -f -R ./dist
mkdir -p ./dist

echo "[i] Grab version information"
docker run --rm -a stdout -a stderr --entrypoint "/usr/sbin/nginx" "${IMAGE}:${VERSION}" -v 2&> ./dist/version.txt

for PLATFORM in linux/amd64 linux/arm64
do
    CONTAINER=$(docker create --platform ${PLATFORM} "${IMAGE}:${VERSION}")
    echo "[i] Created container ${CONTAINER:0:12}"

    echo "[i] Extract assets"
    docker cp "${CONTAINER}:/usr/sbin/nginx" ./dist/nginx

    echo "[i] Create distribution archive"
    XZ_OPT=-9 tar -C ./dist -Jcvf ./dist/nginx-http3-${LIBRARY}-${PLATFORM/\//-}.tar.xz nginx

    echo "[i] Removing container ${CONTAINER:0:12}"
    docker rm $CONTAINER
done
