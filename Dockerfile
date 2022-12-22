##################################################
# Nginx with Quiche (HTTP/3), Brotli, Headers More
##################################################
FROM alpine:latest

ARG SSL_LIBRARY

ENV OPENSSL_QUIC_TAG=openssl-3.0.7+quic1 \
    LIBRESSL_TAG=v3.6.1 \
    CLOUDFLARE_ZLIB_COMMIT=885674026394870b7e7a05b7bf1ec5eb7bd8a9c0 \
    MODULE_NGINX_HEADERS_MORE=v0.34 \
    MODULE_NGINX_ECHO=v0.63 \
    MODULE_NGINX_FANCYINDEX=v0.5.2 \
    MODULE_NGINX_VTS=v0.2.1 \
    MODULE_NGINX_COOKIE_FLAG=v1.1.0 \
    MODULE_NGINX_NJS=0.7.9

COPY ["nginx.patch", "/usr/src/nginx.patch"]

RUN set -x \
  && addgroup -S nginx \
  && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
  && apk update \
  && apk upgrade \
  && apk add --no-cache ca-certificates xz \
  && apk add --no-cache --virtual .build-deps \
  clang \
  curl \
  make \
  pcre2-dev \
  linux-headers \
  && apk add --no-cache --virtual .brotli-build-deps \
  autoconf \
  libtool \
  automake \
  git \
  cmake \
  go \
  rust \
  cargo \
  patch \
#
# OpenSSL library (with QUIC support)
#
  && mkdir -p /usr/src/openssl \
  && curl --location https://github.com/quictls/openssl/archive/refs/tags/${OPENSSL_QUIC_TAG}.tar.gz | tar xz -C /usr/src/openssl --strip-components=1 \
#
# LibreSSL
#
  && mkdir /usr/src/libressl \
  && curl --location https://github.com/libressl-portable/portable/archive/refs/tags/${LIBRESSL_TAG}.tar.gz | tar xz -C /usr/src/libressl --strip-components=1 \
#
# Cloudflare enhanced zlib
#
  && mkdir -p /usr/src/zlib \
  && curl --location https://api.github.com/repos/cloudflare/zlib/tarball/${CLOUDFLARE_ZLIB_COMMIT} | tar xz -C /usr/src/zlib --strip-components=1 \
#
# Module: ngx_brotli
#
  && git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli /usr/src/ngx_brotli \
#
# Module: headers-more-nginx-module
#
  && mkdir -p /usr/src/headers-more-nginx-module \
  && curl --location https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/${MODULE_NGINX_HEADERS_MORE}.tar.gz | tar xz -C /usr/src/headers-more-nginx-module --strip-components=1 \
#
# Module: echo-nginx-module
#
  && mkdir -p /usr/src/echo-nginx-module \
  && curl --location https://github.com/openresty/echo-nginx-module/archive/refs/tags/${MODULE_NGINX_ECHO}.tar.gz | tar xz -C /usr/src/echo-nginx-module --strip-components=1 \
#
# Module: ngx-fancyindex
#
  && mkdir -p /usr/src/ngx-fancyindex \
  && curl --location https://github.com/aperezdc/ngx-fancyindex/archive/refs/tags/${MODULE_NGINX_FANCYINDEX}.tar.gz | tar xz -C /usr/src/ngx-fancyindex --strip-components=1 \
#
# Module: nginx-module-vts
#
  && mkdir -p /usr/src/nginx-module-vts \
  && curl --location https://github.com/vozlt/nginx-module-vts/archive/refs/tags/${MODULE_NGINX_VTS}.tar.gz | tar xz -C /usr/src/nginx-module-vts --strip-components=1 \
#
# Module: nginx_cookie_flag_module
#
  && mkdir -p /usr/src/nginx_cookie_flag_module \
  && curl --location https://github.com/AirisX/nginx_cookie_flag_module/archive/refs/tags/${MODULE_NGINX_COOKIE_FLAG}.tar.gz | tar xz -C /usr/src/nginx_cookie_flag_module --strip-components=1 \
#
# Module: ngx_http_substitutions_filter_module
#
  && mkdir -p /usr/src/ngx_http_substitutions_filter_module \
  && curl --location https://github.com/yaoweibin/ngx_http_substitutions_filter_module/tarball/master | tar xz -C /usr/src/ngx_http_substitutions_filter_module --strip-components=1 \
#
# Module: njs
#
  && mkdir -p /usr/src/njs \
  && curl --location https://github.com/nginx/njs/archive/refs/tags/${MODULE_NGINX_NJS}.tar.gz | tar xz -C /usr/src/njs --strip-components=1 \
#
# nginx QUIC branch
#
  && mkdir -p /usr/src/nginx-quic \
  && curl --location https://hg.nginx.org/nginx-quic/archive/quic.tar.gz | tar xz -C /usr/src/nginx-quic --strip-components=1 \
#
# brotli cargo compile settings
#
  && mkdir -p /root/.cargo \
  && echo $'[net]\ngit-fetch-with-cli = true' > /root/.cargo/config.toml \
#
# OpenSSL+quic1
#
  && cd /usr/src/openssl \
  && if [ "${SSL_LIBRARY}" = "openssl" ]; then ./Configure no-shared no-tests linux-generic64; fi \
  && if [ "${SSL_LIBRARY}" = "openssl" ]; then make -j$(getconf _NPROCESSORS_ONLN) && make install_sw; fi \
#
# LibreSSL
#
  && cd /usr/src/libressl \
  && if [ "${SSL_LIBRARY}" = "libressl" ]; then ./autogen.sh; fi \
  && if [ "${SSL_LIBRARY}" = "libressl" ]; then CC=/usr/bin/clang CXX=/usr/bin/clang++ ./configure \
      --disable-shared \
      --disable-tests \
      --enable-static; fi \
  && if [ "${SSL_LIBRARY}" = "libressl" ]; then make -j$(getconf _NPROCESSORS_ONLN) install; fi \
#
# zlib-cloudflare
#
  && cd /usr/src/zlib \
  && ./configure --static
#
# nginx-quic
#
RUN  set -x \
  && cd /usr/src/nginx-quic \
  && patch -p1 < /usr/src/nginx.patch \
  && CC=/usr/bin/clang CXX=/usr/bin/clang++ auto/configure \
     --build="nginx-http3-$(date -u +'%Y-%m-%dT%H:%M:%SZ') ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) headers-more-nginx-module-${MODULE_NGINX_HEADERS_MORE} echo-nginx-module-${MODULE_NGINX_ECHO} ngx-fancyindex-${MODULE_NGINX_FANCYINDEX} nginx-module-vts-${MODULE_NGINX_VTS} nginx_cookie_flag_module-${MODULE_NGINX_COOKIE_FLAG} njs-${MODULE_NGINX_NJS} ngx_http_substitutions_filter_module-latest" \
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
     --with-cc-opt="-O3 -Wno-sign-compare -Wno-conditional-uninitialized -Wno-unused-but-set-variable" \
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
     --with-ld-opt="-w -s" \
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
     --without-http_uwsgi_module \
  && make -j$(getconf _NPROCESSORS_ONLN) \
  && make -j$(getconf _NPROCESSORS_ONLN) install \
  && rm -rf /etc/nginx/html/ \
  && mkdir /etc/nginx/conf.d/ \
  && mkdir -p /usr/share/nginx/html/ \
  && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
  && strip /usr/sbin/nginx* \
  && rm -rf /etc/nginx/*.default /etc/nginx/*.so \
  && rm -rf /usr/src \
  && runDeps="$( \
  scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so \
  | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
  | sort -u \
  | xargs -r apk info --installed \
  | sort -u \
  )" \
  && apk add --no-cache --virtual .nginx-rundeps $runDeps \
  && apk del .brotli-build-deps \
  && apk del .build-deps \
  && rm -rf /root/.cargo \
  && rm -rf /var/cache/apk/*
