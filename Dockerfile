# syntax=docker/dockerfile:1.4
##################################################
# Nginx with Quiche (HTTP/3), Brotli, Headers More
##################################################
FROM alpine:latest AS builder

ARG SSL_LIBRARY=openssl

ENV OPENSSL_QUIC_TAG=openssl-3.0.8-quic1 \
    LIBRESSL_TAG=v3.8.0 \
    BORINGSSL_COMMIT=b0a026f8541c551854efd617021bb276f1fe5c23 \
    CLOUDFLARE_ZLIB_COMMIT=d20bdfcd0efbdd72cb9d857e098ceac1bad41432 \
    MODULE_NGINX_HEADERS_MORE=v0.34 \
    MODULE_NGINX_ECHO=v0.63 \
    MODULE_NGINX_FANCYINDEX=v0.5.2 \
    MODULE_NGINX_VTS=v0.2.2 \
    MODULE_NGINX_COOKIE_FLAG=v1.1.0 \
    MODULE_NGINX_HTTP_AUTH_DIGEST=v1.0.0 \
    MODULE_NGINX_NJS=0.7.12 \
    NGINX_QUIC_COMMIT=8eae1b4f1c55

COPY --link ["nginx.patch", "/usr/src/nginx.patch"]
COPY --link ["njs.patch", "/usr/src/njs.patch"]
COPY --link ["scratchfs", "/scratchfs"]

RUN <<EOF

set -x
echo "Compiling for SSL_LIBRARY: ${SSL_LIBRARY}"
apk update
apk upgrade
apk add --no-cache ca-certificates openssl tar xz
apk add --no-cache --virtual .build-deps \
  autoconf \
  automake \
  cargo \
  clang \
  cmake \
  curl \
  file \
  git \
  go \
  libtool \
  libxslt-dev \
  linux-headers \
  make \
  patch \
  pcre2-dev \
  rust \
  samurai

#
# Prepare destination scratchfs
#
# Create self-signed certificate
openssl req -x509 -newkey rsa:4096 -nodes -keyout /scratchfs/etc/ssl/private/localhost.key -out /scratchfs/etc/ssl/localhost.pem -days 365 -sha256 -subj "/CN=localhost"
chown 1000:1000 /scratchfs/etc/ssl/private/localhost.key /scratchfs/var/run/nginx /scratchfs/var/lib/nginx/logs /scratchfs/var/lib/nginx/tmp

#
# Mozilla CA cert bundle
#
curl --silent --location --compressed --output /scratchfs/etc/ssl/cacert.pem https://curl.haxx.se/ca/cacert.pem || exit 1
curl --silent --location --compressed --output /scratchfs/etc/ssl/cacert.pem.sha256 https://curl.haxx.se/ca/cacert.pem.sha256 || exit 1
cd /scratchfs/etc/ssl
sha256sum -c /scratchfs/etc/ssl/cacert.pem.sha256 || exit 1
rm /scratchfs/etc/ssl/cacert.pem.sha256

mkdir -p /usr/src
#
# OpenSSL library (with QUIC support)
#
if [ "${SSL_LIBRARY}" = "openssl" ]; then curl --silent --location https://github.com/quictls/openssl/archive/refs/tags/${OPENSSL_QUIC_TAG}.tar.gz | tar xz -C /usr/src --one-top-level=openssl --strip-components=1 || exit 1; fi

#
# LibreSSL
#
if [ "${SSL_LIBRARY}" = "libressl" ]; then curl --silent --location https://github.com/libressl-portable/portable/archive/refs/tags/${LIBRESSL_TAG}.tar.gz | tar xz -C /usr/src --one-top-level=libressl --strip-components=1 || exit 1; fi

#
# BoringSSL
#
if [ "${SSL_LIBRARY}" = "boringssl" ]; then curl --silent --location https://api.github.com/repos/google/boringssl/tarball/${BORINGSSL_COMMIT} | tar xz -C /usr/src --one-top-level=boringssl --strip-components=1 || exit 1; fi

#
# Cloudflare enhanced zlib
#
curl --silent --location https://api.github.com/repos/cloudflare/zlib/tarball/${CLOUDFLARE_ZLIB_COMMIT} | tar xz -C /usr/src --one-top-level=zlib --strip-components=1 || exit 1

#
# Module: ngx_brotli
#
git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli /usr/src/ngx_brotli || exit 1

#
# Module: headers-more-nginx-module
#
curl --silent --location https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/${MODULE_NGINX_HEADERS_MORE}.tar.gz | tar xz -C /usr/src --one-top-level=headers-more-nginx-module --strip-components=1 || exit 1

#
# Module: echo-nginx-module
#
curl --silent --location https://github.com/openresty/echo-nginx-module/archive/refs/tags/${MODULE_NGINX_ECHO}.tar.gz | tar xz -C /usr/src --one-top-level=echo-nginx-module --strip-components=1 || exit 1

#
# Module: ngx-fancyindex
#
curl --silent --location https://github.com/aperezdc/ngx-fancyindex/archive/refs/tags/${MODULE_NGINX_FANCYINDEX}.tar.gz | tar xz -C /usr/src --one-top-level=ngx-fancyindex --strip-components=1 || exit 1

#
# Module: nginx-module-vts
#
curl --silent --location https://github.com/vozlt/nginx-module-vts/archive/refs/tags/${MODULE_NGINX_VTS}.tar.gz | tar xz -C /usr/src --one-top-level=nginx-module-vts --strip-components=1 || exit 1

#
# Module: nginx_cookie_flag_module
#
curl --silent --location https://github.com/AirisX/nginx_cookie_flag_module/archive/refs/tags/${MODULE_NGINX_COOKIE_FLAG}.tar.gz | tar xz -C /usr/src --one-top-level=nginx_cookie_flag_module --strip-components=1 || exit 1

#
# Module: ngx_http_substitutions_filter_module
#
curl --silent --location https://github.com/yaoweibin/ngx_http_substitutions_filter_module/tarball/master | tar xz -C /usr/src --one-top-level=ngx_http_substitutions_filter_module --strip-components=1 || exit 1

#
# Module: nginx-http-auth-digest
#
curl --silent --location https://github.com/atomx/nginx-http-auth-digest/archive/refs/tags/${MODULE_NGINX_HTTP_AUTH_DIGEST}.tar.gz | tar xz -C /usr/src --one-top-level=nginx_http_auth_digest --strip-components=1 || exit 1

#
# Module: njs
#
curl --silent --location https://github.com/nginx/njs/archive/refs/tags/${MODULE_NGINX_NJS}.tar.gz | tar xz -C /usr/src --one-top-level=njs --strip-components=1 || exit 1

#
# nginx QUIC branch
#
curl --silent --location https://hg.nginx.org/nginx-quic/archive/${NGINX_QUIC_COMMIT}.tar.gz | tar xz -C /usr/src --one-top-level=nginx-quic --strip-components=1 || exit 1

#
# brotli cargo compile settings
#
mkdir -p /root/.cargo
echo $'[net]\ngit-fetch-with-cli = true' > /root/.cargo/config.toml

#
# OpenSSL+quic1
#
if [ "${SSL_LIBRARY}" = "openssl" ]; then
  cd /usr/src/openssl
  CC=clang ./Configure no-shared no-tests linux-generic64
  make -j$(getconf _NPROCESSORS_ONLN) && make install_sw || exit 1
  SSL_COMMIT="openssl+quic1-${OPENSSL_QUIC_TAG}"
fi

#
# LibreSSL
#
if [ "${SSL_LIBRARY}" = "libressl" ]; then
  cd /usr/src/libressl
  ./autogen.sh
  CC=clang CXX=clang++ ./configure \
    --disable-shared \
    --disable-tests \
    --enable-static
  make -j$(getconf _NPROCESSORS_ONLN) install || exit 1
  SSL_COMMIT="libressl-${LIBRESSL_TAG}"
fi

#
# BoringSSL
#
if [ "${SSL_LIBRARY}" = "boringssl" ]; then
  cd /usr/src/boringssl
  mkdir -p .openssl/lib .openssl/include
  ln -sf /usr/src/boringssl/include/openssl /usr/src/boringssl/.openssl/include/openssl
  touch /usr/src/boringssl/.openssl/include/openssl/ssl.h
  CC=clang CXX=clang++ cmake -GNinja -DCMAKE_BUILD_TYPE=RelWithDebInfo .
  ninja || exit 1
  cp crypto/libcrypto.a ssl/libssl.a .openssl/lib
  SSL_COMMIT="boringssl-${BORINGSSL_COMMIT:0:7}"
fi

#
# zlib-cloudflare
#
cd /usr/src/zlib
./configure --static

#
# njs-patch
#
cd /usr/src/njs
patch -p1 < /usr/src/njs.patch || exit 1

#
# nginx-quic
#
cd /usr/src/nginx-quic
patch -p1 < /usr/src/nginx.patch || exit 1
NJS_LIBXSLT=NO CC=/usr/bin/clang CXX=/usr/bin/clang++ auto/configure \
   --build="nginx-http3-${NGINX_QUIC_COMMIT} ${SSL_COMMIT} ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) headers-more-nginx-module-${MODULE_NGINX_HEADERS_MORE} echo-nginx-module-${MODULE_NGINX_ECHO} ngx-fancyindex-${MODULE_NGINX_FANCYINDEX} nginx-module-vts-${MODULE_NGINX_VTS} nginx_cookie_flag_module-${MODULE_NGINX_COOKIE_FLAG} nginx_http_auth_digest-${MODULE_NGINX_HTTP_AUTH_DIGEST} njs-${MODULE_NGINX_NJS} ngx_http_substitutions_filter_module-latest" \
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
   --add-module=/usr/src/nginx_http_auth_digest \
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
make -j$(getconf _NPROCESSORS_ONLN) || exit 1
make -j$(getconf _NPROCESSORS_ONLN) install || exit 1

file /usr/sbin/nginx
/usr/sbin/nginx -vv

# Populate /scratchfs
cp /etc/nginx/mime.types /scratchfs/etc/nginx/
cp /usr/src/nginx-quic/docs/html/* /scratchfs/var/lib/nginx/html/
cp /usr/sbin/nginx /scratchfs/usr/sbin/

EOF

FROM scratch

COPY --from=builder /scratchfs /

EXPOSE 8080/tcp 8443/tcp 8443/udp
STOPSIGNAL SIGQUIT

USER nginx
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
