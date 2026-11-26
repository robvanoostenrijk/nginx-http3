# syntax=docker/dockerfile:1
##################################################
# Nginx with HTTP/3, Brotli, Headers More
##################################################
FROM alpine:latest AS builder

ARG ARCH_MARCH=native
ARG SSL_LIBRARY=openssl

ARG UID=1000
ARG GID=1000

ARG	AWS_LC_TAG=v5.15.0 \
	LIBRESSL_TAG=v4.4.1 \
	OPENSSL_TAG=openssl-4.1.0 \
	WOLFSSL_TAG=v5.9.4 \
	MODULE_NGINX_DEVEL_KIT=v0.3.4 \
	MODULE_NGINX_ECHO=v0.66 \
	MODULE_NGINX_GEOIP2=3.4 \
	MODULE_NGINX_FLV=v1.2.15 \
	MODULE_NGINX_HEADERS_MORE=v0.42 \
	MODULE_NGINX_MISC=v0.34 \
	MODULE_NGINX_NJS=1.0.2 \
	MODULE_NGINX_VTS=v0.2.7 \
	MODULE_NGINX_ZSTD=0.1.1 \
	NGINX=1.31.10 \
	ZLIB_NG_TAG=2.3.3

#
# Base toolchain
#
RUN <<EOF
set -euox pipefail

sed -i -r 's/v\d+\.\d+/edge/g' /etc/apk/repositories
apk update
apk upgrade --no-interactive --latest
apk add --no-cache \
	build-base \
	ca-certificates \
	clang \
	cmake \
	curl \
	file \
	git \
	linux-headers \
	libmaxminddb-dev \
	libmaxminddb-static \
	libxml2-dev \
	libxml2-static \
	libxslt-dev \
	libxslt-static \
	openssl \
	patch \
	perl \
	pcre2-dev \
	pcre2-static \
	samurai \
	tar \
	xz \
	xz-static \
	zstd-dev \
	zstd-static
EOF

#
# zlib-ng (zlib-compat static build)
#
RUN <<EOF
set -euox pipefail
mkdir -p /usr/src
curl --silent --show-error --fail --location "https://github.com/zlib-ng/zlib-ng/archive/refs/tags/${ZLIB_NG_TAG}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=zlib-ng --strip-components=1
mkdir -p /usr/src/zlib-ng/build
cd /usr/src/zlib-ng/build
CC=clang cmake \
	-GNinja \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS=OFF \
	-DZLIB_COMPAT=ON \
	-DZLIB_ENABLE_TESTS=OFF \
	-DCMAKE_C_FLAGS="-O3 -march=${ARCH_MARCH}" \
	-DCMAKE_INSTALL_LIBDIR=lib \
	-DCMAKE_INSTALL_PREFIX=/usr/local/zlib-ng \
	..
cmake --build .
cmake --install .
EOF

#
# ngx_brotli
#
RUN <<EOF
set -euox pipefail
mkdir -p /usr/src
git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli /usr/src/ngx_brotli
mkdir -p /usr/src/ngx_brotli/deps/brotli/out
cd /usr/src/ngx_brotli/deps/brotli/out
CC=clang CXX=clang++ cmake \
	-GNinja \
	-DCMAKE_BUILD_TYPE=Release \
	-DBUILD_SHARED_LIBS=OFF \
	-DCMAKE_C_FLAGS="-O3 -march=${ARCH_MARCH} -funroll-loops -ffunction-sections -fdata-sections" \
	-DCMAKE_CXX_FLAGS="-O3 -march=${ARCH_MARCH} -funroll-loops -ffunction-sections -fdata-sections" \
	-DCMAKE_INSTALL_PREFIX=./installed \
	..
cmake --build . --config Release --target brotlienc
EOF

#
# SSL library (OpenSSL / LibreSSL / AWS-LC / wolfSSL)
#
RUN <<EOF
set -euox pipefail
echo "Compiling for SSL_LIBRARY: ${SSL_LIBRARY}"
mkdir -p /usr/src /usr/local/ssl

case "${SSL_LIBRARY}" in
	openssl)
		curl --silent --show-error --fail --location "https://github.com/openssl/openssl/archive/refs/tags/${OPENSSL_TAG}.tar.gz" \
			| tar xz -C /usr/src --one-top-level=openssl --strip-components=1
		cd /usr/src/openssl
		CC=clang ./config \
			no-shared \
			no-tests \
			no-apps \
			--prefix=/usr/local/ssl \
			--openssldir=/usr/local/ssl \
			--libdir=lib \
			-O3 -march=${ARCH_MARCH} -ffunction-sections -fdata-sections
		make -j"$(getconf _NPROCESSORS_ONLN)"
		make install_sw
		echo "${OPENSSL_TAG}" > /usr/local/ssl/commit.txt
		;;
	libressl)
		apk add --no-cache autoconf automake libtool m4
		curl --silent --show-error --fail --location "https://github.com/libressl-portable/portable/archive/refs/tags/${LIBRESSL_TAG}.tar.gz" \
			| tar xz -C /usr/src --one-top-level=libressl --strip-components=1
		cd /usr/src/libressl
		./autogen.sh
		CC=clang CXX=clang++ \
		CFLAGS="-O3 -march=${ARCH_MARCH} -ffunction-sections -fdata-sections" \
		CXXFLAGS="-O3 -march=${ARCH_MARCH} -ffunction-sections -fdata-sections" \
		./configure \
			--prefix=/usr/local/ssl \
			--disable-shared \
			--disable-tests \
			--enable-static
		make -j"$(getconf _NPROCESSORS_ONLN)" install
		echo "libressl-${LIBRESSL_TAG}" > /usr/local/ssl/commit.txt
		;;
	aws-lc)
		curl --silent --show-error --fail --location "https://github.com/aws/aws-lc/archive/refs/tags/${AWS_LC_TAG}.tar.gz" \
			| tar xz -C /usr/src --one-top-level=aws-lc --strip-components=1
		mkdir -p /usr/src/aws-lc/build
		cd /usr/src/aws-lc/build
		CC=clang CXX=clang++ cmake \
			-GNinja \
			-DCMAKE_BUILD_TYPE=Release \
			-DBUILD_SHARED_LIBS=OFF \
			-DBUILD_TESTING=OFF \
			-DBUILD_TOOL=OFF \
			-DDISABLE_GO=ON \
			-DCMAKE_C_FLAGS="-O3 -march=${ARCH_MARCH} -ffunction-sections -fdata-sections" \
			-DCMAKE_CXX_FLAGS="-O3 -march=${ARCH_MARCH} -ffunction-sections -fdata-sections" \
			-DCMAKE_INSTALL_LIBDIR=lib \
			-DCMAKE_INSTALL_PREFIX=/usr/local/ssl \
			..
		cmake --build .
		cmake --install .
		echo "AWS-LC-${AWS_LC_TAG}" > /usr/local/ssl/commit.txt
		;;
	wolfssl)
		apk add --no-cache autoconf automake libtool m4
		mkdir -p /usr/src/wolfssl
		curl --silent --show-error --fail --location "https://github.com/wolfSSL/wolfssl/archive/refs/tags/${WOLFSSL_TAG}-stable.tar.gz" \
			| tar xz -C /usr/src/wolfssl --strip-components=1
		cd /usr/src/wolfssl
		./autogen.sh
		CC=clang CXX=clang++ CFLAGS="-O2 -march=${ARCH_MARCH} -ffunction-sections -fdata-sections" ./configure \
			--prefix=/usr/local/ssl \
			--disable-examples \
			--disable-shared \
			--enable-static \
			--enable-nginx \
			--enable-opensslextra \
			--enable-opensslall \
			--enable-aesccm \
			--enable-alpn \
			--enable-earlydata \
			--enable-haproxy \
			--enable-quic \
			--enable-tlsv12 \
			--enable-tls13 \
			--enable-curve25519 \
			--enable-ed25519
		make -j"$(getconf _NPROCESSORS_ONLN)" install
		ln -sf /usr/local/ssl/include/wolfssl/openssl /usr/local/ssl/include/openssl
		ln -sf libwolfssl.a /usr/local/ssl/lib/libssl.a
		ln -sf libwolfssl.a /usr/local/ssl/lib/libcrypto.a
		echo "wolfssl-${WOLFSSL_TAG}" > /usr/local/ssl/commit.txt
		;;
	*)
		echo "Unsupported SSL_LIBRARY: ${SSL_LIBRARY}" >&2
		exit 1
		;;
esac
EOF

#
# Download nginx + modules
#
RUN <<EOF
set -euox pipefail
mkdir -p /usr/src

curl --silent --show-error --fail --location "https://github.com/vision5/ngx_devel_kit/archive/refs/tags/${MODULE_NGINX_DEVEL_KIT}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=ngx_devel_kit --strip-components=1
curl --silent --show-error --fail --location "https://github.com/openresty/echo-nginx-module/archive/refs/tags/${MODULE_NGINX_ECHO}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=echo-nginx-module --strip-components=1
curl --silent --show-error --fail --location "https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/${MODULE_NGINX_HEADERS_MORE}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=headers-more-nginx-module --strip-components=1
curl --silent --show-error --fail --location "https://github.com/openresty/set-misc-nginx-module/archive/refs/tags/${MODULE_NGINX_MISC}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=set-misc-nginx-module --strip-components=1
curl --silent --show-error --fail --location "https://github.com/vozlt/nginx-module-vts/archive/refs/tags/${MODULE_NGINX_VTS}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=nginx-module-vts --strip-components=1
curl --silent --show-error --fail --location "https://github.com/yaoweibin/ngx_http_substitutions_filter_module/tarball/master" \
	| tar xz -C /usr/src --one-top-level=ngx_http_substitutions_filter_module --strip-components=1
curl --silent --show-error --fail --location "https://github.com/winshining/nginx-http-flv-module/archive/refs/tags/${MODULE_NGINX_FLV}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=nginx-http-flv-module --strip-components=1
curl --silent --show-error --fail --location "https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${MODULE_NGINX_GEOIP2}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=ngx_http_geoip2_module --strip-components=1
curl --silent --show-error --fail --location "https://github.com/tokers/zstd-nginx-module/archive/refs/tags/${MODULE_NGINX_ZSTD}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=zstd-nginx-module --strip-components=1
curl --silent --show-error --fail --location "https://github.com/nginx/njs/archive/refs/tags/${MODULE_NGINX_NJS}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=njs --strip-components=1
curl --silent --show-error --fail --location "https://nginx.org/download/nginx-${NGINX}.tar.gz" \
	| tar xz -C /usr/src --one-top-level=nginx --strip-components=1
EOF

#
# Build nginx
#
COPY --link ["patches/nginx_dynamic_tls_records.patch", "/usr/src/nginx_dynamic_tls_records.patch"]
COPY --link ["patches/nginx_wolfssl.patch", "/usr/src/nginx_wolfssl.patch"]
COPY --link ["patches/njs_wolfssl.patch", "/usr/src/njs_wolfssl.patch"]

RUN <<EOF
set -euox pipefail

SSL_COMMIT="$(cat /usr/local/ssl/commit.txt)"
BROTLI_COMMIT="$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD)"
SSL_CC_OPT=""
if [ "${SSL_LIBRARY}" = "wolfssl" ]; then
	SSL_CC_OPT="-I/usr/local/ssl/include/wolfssl -include /usr/local/ssl/include/wolfssl/options.h"
fi

cd /usr/src/nginx
patch -p1 < /usr/src/nginx_dynamic_tls_records.patch
if [ "${SSL_LIBRARY}" = "wolfssl" ]; then
	patch -p1 < /usr/src/nginx_wolfssl.patch
	patch -d /usr/src/njs -p1 < /usr/src/njs_wolfssl.patch
fi
CC=/usr/bin/clang \
CXX=/usr/bin/clang++ \
./configure \
	--build="${SSL_COMMIT} ngx_brotli-${BROTLI_COMMIT} ngx-devel-kit-${MODULE_NGINX_DEVEL_KIT} headers-more-nginx-module-${MODULE_NGINX_HEADERS_MORE} echo-nginx-module-${MODULE_NGINX_ECHO} nginx-module-vts-${MODULE_NGINX_VTS} set-misc-nginx-module-${MODULE_NGINX_MISC} nginx-http-flv-module-${MODULE_NGINX_FLV} ngx_http_geoip2_module-${MODULE_NGINX_GEOIP2} ngx-http-substitutions-filter-module-latest zstd-nginx-module-${MODULE_NGINX_ZSTD} njs-${MODULE_NGINX_NJS}" \
	--prefix=/var/lib/nginx \
	--sbin-path=/usr/sbin/nginx \
	--modules-path=/usr/lib/nginx/modules \
	--conf-path=/etc/nginx/nginx.conf \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
	--pid-path=/run/nginx/nginx.pid \
	--lock-path=/run/nginx/nginx.lock \
	--http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
	--http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
	--http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
	--http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
	--http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
	--user=nginx \
	--group=nginx \
	--with-cc-opt="-I/usr/include/libxml2 -I/usr/local/ssl/include ${SSL_CC_OPT} -I/usr/local/zlib-ng/include -O3 -march=${ARCH_MARCH} -Wno-sign-compare -Wno-conditional-uninitialized -Wno-unused-but-set-variable -Wno-gnu-folding-constant" \
	--with-compat \
	--with-file-aio \
	--with-http_addition_module \
	--with-http_auth_request_module \
	--with-http_dav_module \
	--with-http_degradation_module \
	--with-http_gunzip_module \
	--with-http_gzip_static_module \
	--with-http_random_index_module \
	--with-http_realip_module \
	--with-http_secure_link_module \
	--with-http_slice_module \
	--with-http_ssl_module \
	--with-http_stub_status_module \
	--with-http_sub_module \
	--with-http_v2_module \
	--with-http_v3_module \
	--with-http_xslt_module \
	--with-ld-opt="-L/usr/local/ssl/lib -L/usr/local/zlib-ng/lib -w -s -static -Wl,--gc-sections -lexslt -lxslt -lxml2 -lz -llzma" \
	--with-pcre-jit \
	--with-pcre-opt="-O3 -march=${ARCH_MARCH}" \
	--with-poll_module \
	--with-select_module \
	--with-stream \
	--with-stream_ssl_preread_module \
	--with-threads \
	--add-module=/usr/src/ngx_devel_kit \
	--add-module=/usr/src/echo-nginx-module \
	--add-module=/usr/src/headers-more-nginx-module \
	--add-module=/usr/src/nginx-module-vts \
	--add-module=/usr/src/ngx_brotli \
	--add-module=/usr/src/nginx-http-flv-module \
	--add-module=/usr/src/ngx_http_geoip2_module \
	--add-module=/usr/src/ngx_http_substitutions_filter_module \
	--add-module=/usr/src/zstd-nginx-module \
	--add-module=/usr/src/njs/nginx \
	--add-module=/usr/src/set-misc-nginx-module \
	--without-http_browser_module \
	--without-http_grpc_module \
	--without-http_mirror_module \
	--without-http_scgi_module \
	--without-http_uwsgi_module || { cat objs/autoconf.err; exit 1; }

make -j"$(getconf _NPROCESSORS_ONLN)"
make -j"$(getconf _NPROCESSORS_ONLN)" install

ls -lh /usr/sbin/nginx
file /usr/sbin/nginx
/usr/sbin/nginx -v
EOF

#
# Assemble /scratchfs
#
COPY --link ["scratchfs", "/scratchfs"]

RUN <<EOF
set -euox pipefail

# Create self-signed certificate
mkdir -p /scratchfs/etc/ssl/private
openssl req -x509 -newkey rsa:4096 -nodes \
	-keyout /scratchfs/etc/ssl/private/localhost.key \
	-out /scratchfs/etc/ssl/private/localhost.pem \
	-days 365 -sha256 -subj "/CN=localhost"
chown "${UID}:${GID}" /scratchfs/etc/ssl/private/localhost.key

# Mozilla CA cert bundle
curl --silent --show-error --fail --location --retry 3 --compressed --output /scratchfs/etc/ssl/cacert.pem https://curl.se/ca/cacert.pem
curl --silent --show-error --fail --location --retry 3 --compressed --output /scratchfs/etc/ssl/cacert.pem.sha256 https://curl.se/ca/cacert.pem.sha256
cd /scratchfs/etc/ssl
sha256sum -c /scratchfs/etc/ssl/cacert.pem.sha256
rm /scratchfs/etc/ssl/cacert.pem.sha256

# Populate /scratchfs directories and permissions
mkdir -p \
	/scratchfs/etc/nginx \
	/scratchfs/run \
	/scratchfs/tmp \
	/scratchfs/var/cache/nginx \
	/scratchfs/var/lib/nginx/html \
	/scratchfs/var/lib/nginx/tmp \
	/scratchfs/var/log/nginx \
	/scratchfs/usr/sbin

chmod 1777 /scratchfs/run /scratchfs/tmp

chown -R "${UID}:0" \
	/scratchfs/etc/nginx \
	/scratchfs/var/cache/nginx \
	/scratchfs/var/lib/nginx/tmp \
	/scratchfs/var/log/nginx

chmod -R g+w \
	/scratchfs/etc/nginx \
	/scratchfs/var/cache/nginx \
	/scratchfs/var/lib/nginx/tmp \
	/scratchfs/var/log/nginx

cp /etc/nginx/mime.types /scratchfs/etc/nginx/
cp /usr/src/nginx/html/* /scratchfs/var/lib/nginx/html/
cp /usr/sbin/nginx /scratchfs/usr/sbin/

ln -sf /dev/stdout /scratchfs/var/log/nginx/access.log
ln -sf /dev/stderr /scratchfs/var/log/nginx/error.log

echo "root:x:0:" > /scratchfs/etc/group
echo "nginx:x:${GID}:" >> /scratchfs/etc/group

echo "root:x:0:0:root:/root:/dev/null" > /scratchfs/etc/passwd
echo "nginx:x:${UID}:${GID}:nginx:/etc/nginx:/dev/null" >> /scratchfs/etc/passwd
EOF

FROM scratch

ARG UID=1000

COPY --from=builder /scratchfs /

EXPOSE 8080/tcp 8443/tcp 8443/udp
STOPSIGNAL SIGQUIT

USER ${UID}
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-e", "/var/log/nginx/error.log", "-g", "daemon off;"]
