# syntax=docker/dockerfile:1.4
##################################################
# Nginx with Quiche (HTTP/3), Brotli, Headers More
##################################################
FROM alpine:latest AS builder

ARG SSL_LIBRARY

ENV OPENSSL_QUIC_TAG=openssl-3.0.7+quic1 \
    LIBRESSL_TAG=v3.6.1 \
    BORINGSSL_COMMIT=01d195bd03bfff54dc99c0df0858197c71d35417 \
    CLOUDFLARE_ZLIB_COMMIT=885674026394870b7e7a05b7bf1ec5eb7bd8a9c0 \
    MODULE_NGINX_HEADERS_MORE=v0.34 \
    MODULE_NGINX_ECHO=v0.63 \
    MODULE_NGINX_FANCYINDEX=v0.5.2 \
    MODULE_NGINX_VTS=v0.2.1 \
    MODULE_NGINX_COOKIE_FLAG=v1.1.0 \
    MODULE_NGINX_NJS=0.7.9 \
    NGINX_QUIC_COMMIT=987bee4363d1

COPY ["nginx.patch", "/usr/src/nginx.patch"]

RUN <<EOF

set -x
echo "Compiling for SSL_LIBRARY: ${SSL_LIBRARY}"
apk update
apk upgrade
apk add --no-cache ca-certificates openssl xz
apk add --no-cache --virtual .build-deps \
  clang \
  curl \
  linux-headers \
  make \
  pcre2-dev

apk add --no-cache --virtual .brotli-build-deps \
  autoconf \
  automake \
  cargo \
  cmake \
  git \
  go \
  libtool \
  samurai \
  patch \
  rust

mkdir -p /usr/src
#
# OpenSSL library (with QUIC support)
#
if [ "${SSL_LIBRARY}" = "openssl" ]; then curl --location https://github.com/quictls/openssl/archive/refs/tags/${OPENSSL_QUIC_TAG}.tar.gz | tar xz -C /usr/src --one-top-level=openssl --strip-components=1; fi

#
# LibreSSL
#
if [ "${SSL_LIBRARY}" = "libressl" ]; then curl --location https://github.com/libressl-portable/portable/archive/refs/tags/${LIBRESSL_TAG}.tar.gz | tar xz -C /usr/src --one-top-level=libressl --strip-components=1; fi

#
# BoringSSL
#
if [ "${SSL_LIBRARY}" = "boringssl" ]; then curl --location https://api.github.com/repos/google/boringssl/tarball/${BORINGSSL_COMMIT} | tar xz -C /usr/src --one-top-level=boringssl --strip-components=1; fi

#
# Cloudflare enhanced zlib
#
curl --location https://api.github.com/repos/cloudflare/zlib/tarball/${CLOUDFLARE_ZLIB_COMMIT} | tar xz -C /usr/src --one-top-level=zlib --strip-components=1

#
# Module: ngx_brotli
#
git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli /usr/src/ngx_brotli

#
# Module: headers-more-nginx-module
#
curl --location https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/${MODULE_NGINX_HEADERS_MORE}.tar.gz | tar xz -C /usr/src --one-top-level=headers-more-nginx-module --strip-components=1

#
# Module: echo-nginx-module
#
curl --location https://github.com/openresty/echo-nginx-module/archive/refs/tags/${MODULE_NGINX_ECHO}.tar.gz | tar xz -C /usr/src --one-top-level=echo-nginx-module --strip-components=1

#
# Module: ngx-fancyindex
#
curl --location https://github.com/aperezdc/ngx-fancyindex/archive/refs/tags/${MODULE_NGINX_FANCYINDEX}.tar.gz | tar xz -C /usr/src --one-top-level=ngx-fancyindex --strip-components=1

#
# Module: nginx-module-vts
#
curl --location https://github.com/vozlt/nginx-module-vts/archive/refs/tags/${MODULE_NGINX_VTS}.tar.gz | tar xz -C /usr/src --one-top-level=nginx-module-vts --strip-components=1

#
# Module: nginx_cookie_flag_module
#
curl --location https://github.com/AirisX/nginx_cookie_flag_module/archive/refs/tags/${MODULE_NGINX_COOKIE_FLAG}.tar.gz | tar xz -C /usr/src --one-top-level=nginx_cookie_flag_module --strip-components=1

#
# Module: ngx_http_substitutions_filter_module
#
curl --location https://github.com/yaoweibin/ngx_http_substitutions_filter_module/tarball/master | tar xz -C /usr/src --one-top-level=ngx_http_substitutions_filter_module --strip-components=1

#
# Module: njs
#
curl --location https://github.com/nginx/njs/archive/refs/tags/${MODULE_NGINX_NJS}.tar.gz | tar xz -C /usr/src --one-top-level=njs --strip-components=1

#
# nginx QUIC branch
#
curl --location https://hg.nginx.org/nginx-quic/archive/${NGINX_QUIC_COMMIT}.tar.gz | tar xz -C /usr/src --one-top-level=nginx-quic --strip-components=1

#
# brotli cargo compile settings
#
mkdir -p /root/.cargo
echo $'[net]\ngit-fetch-with-cli = true' > /root/.cargo/config.toml

#
# OpenSSL+quic1
#
cd /usr/src/openssl
if [ "${SSL_LIBRARY}" = "openssl" ]; then
  ./Configure no-shared no-tests linux-generic64
  make -j$(getconf _NPROCESSORS_ONLN) && make install_sw
  SSL_COMMIT="openssl+quic1-${OPENSSL_QUIC_TAG}"
fi

#
# LibreSSL
#
cd /usr/src/libressl
if [ "${SSL_LIBRARY}" = "libressl" ]; then
  ./autogen.sh
  CC=clang CXX=clang++ ./configure \
    --disable-shared \
    --disable-tests \
    --enable-static
  make -j$(getconf _NPROCESSORS_ONLN) install
  SSL_COMMIT="libressl-${LIBRESSL_TAG}"
fi

#
# BoringSSL
#
cd /usr/src/boringssl
if [ "${SSL_LIBRARY}" = "boringssl" ]; then
  mkdir -p .openssl/lib .openssl/include
  ln -sf /usr/src/boringssl/include/openssl /usr/src/boringssl/.openssl/include/openssl
  touch /usr/src/boringssl/.openssl/include/openssl/ssl.h
  CC=clang CXX=clang++ cmake -GNinja -DCMAKE_BUILD_TYPE=RelWithDebInfo .
  ninja
  cp crypto/libcrypto.a ssl/libssl.a .openssl/lib
  SSL_COMMIT="boringssl-${BORINGSSL_COMMIT:0:7}"
fi

#
# zlib-cloudflare
#
cd /usr/src/zlib
./configure --static

#
# nginx-quic
#
cd /usr/src/nginx-quic
patch -p1 < /usr/src/nginx.patch
CC=/usr/bin/clang CXX=/usr/bin/clang++ auto/configure \
   --build="nginx-http3-${NGINX_QUIC_COMMIT} ${SSL_COMMIT} ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) headers-more-nginx-module-${MODULE_NGINX_HEADERS_MORE} echo-nginx-module-${MODULE_NGINX_ECHO} ngx-fancyindex-${MODULE_NGINX_FANCYINDEX} nginx-module-vts-${MODULE_NGINX_VTS} nginx_cookie_flag_module-${MODULE_NGINX_COOKIE_FLAG} njs-${MODULE_NGINX_NJS} ngx_http_substitutions_filter_module-latest" \
   --prefix=/var/lib/nginx \
   --sbin-path=/usr/sbin/nginx \
   --modules-path=/usr/lib/nginx/modules \
   --conf-path=/etc/nginx/nginx.conf \
   --pid-path=/run/nginx/nginx.pid \
   --lock-path=/run/nginx/nginx.lock \
   --http-client-body-temp-path=/var/lib/nginx/tmp/client_body \
   --http-proxy-temp-path=/var/lib/nginx/tmp/proxy \
   --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi \
   --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi \
   --http-scgi-temp-path=/var/lib/nginx/tmp/scgi \
   --user=nginx \
   --group=nginx \
   --with-cc-opt="-O3 -static -Wno-sign-compare -Wno-conditional-uninitialized -Wno-unused-but-set-variable -I/usr/src/boringssl/.openssl/include" \
   --with-compat \
   --with-file-aio \
   --with-http_addition_module \
   --with-http_auth_request_module \
   --with-http_gunzip_module \
   --with-http_gzip_static_module \
   --with-http_realip_module \
   --with-http_slice_module \
   --with-http_ssl_module \
   --with-http_stub_status_module \
   --with-http_sub_module \
   --with-http_v2_hpack_enc \
   --with-http_v2_module \
   --with-http_v3_module \
   --with-ld-opt="-w -s -L/usr/src/boringssl/.openssl/lib -static" \
   --with-pcre-jit \
   --with-pcre-opt="-O3" \
   --with-poll_module \
   --with-select_module \
   --with-threads \
   --with-zlib-asm=CPU \
   --with-zlib-opt="-O3" \
   --with-zlib=/usr/src/zlib \
   --add-module=/usr/src/echo-nginx-module \
   --add-module=/usr/src/headers-more-nginx-module \
   --add-module=/usr/src/nginx_cookie_flag_module \
   --add-module=/usr/src/nginx-module-vts \
   --add-module=/usr/src/ngx_brotli \
   --add-module=/usr/src/ngx_http_substitutions_filter_module \
   --add-module=/usr/src/ngx-fancyindex \
   --add-module=/usr/src/njs/nginx \
   --without-http_browser_module \
   --without-http_grpc_module \
   --without-http_mirror_module \
   --without-http_scgi_module \
   --without-http_uwsgi_module
make -j$(getconf _NPROCESSORS_ONLN)
make -j$(getconf _NPROCESSORS_ONLN) install

# Create /build distribution folder
mkdir -p /build /build/etc/ssl/private /build/usr/sbin /build/var/run/nginx /build/etc/nginx/conf.d /build/var/lib/nginx/html /build/var/lib/nginx/logs /build/var/lib/nginx/tmp
cp /usr/sbin/nginx /build/usr/sbin/
cp -r /etc/nginx/* /build/etc/nginx
cp -r /usr/src/nginx-quic/docs/html /build/var/lib/nginx

# Create self-signed certificate
openssl req -x509 -newkey rsa:4096 -nodes -keyout /build/etc/ssl/private/localhost.key -out /build/etc/ssl/localhost.pem -days 365 -sha256 -subj "/CN=localhost"
chown 1000:1000 /build/etc/ssl/private/localhost.key /build/var/run/nginx /build/var/lib/nginx/logs /build/var/lib/nginx/tmp

#
# Mozilla CA cert bundle
#
curl --location --compressed --output /build/etc/ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem
curl --location --compressed --output /build/etc/ssl/cacert.pem.sha256 https://curl.haxx.se/ca/cacert.pem.sha256
cd /build/etc/ssl
sha256sum -c /build/etc/ssl/cacert.pem.sha256
rm /build/etc/ssl/cacert.pem.sha256

# Clean up
apk del .brotli-build-deps
apk del .build-deps
rm -rf /root/.cargo
rm -rf /var/cache/apk/*
rm -rf /usr/src

EOF

FROM busybox

RUN <<EOF

set -x
echo "nginx:x:1000:1000:nginx:/bin:/bin/false" >> /etc/passwd
echo "nginx:x:1000:" >> /etc/group

EOF

COPY --from=builder /build /
COPY ["include", "/"]

EXPOSE 80/tcp 443/tcp 443/udp

USER nginx
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
