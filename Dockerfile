# syntax=docker/dockerfile:1.4
##################################################
# Nginx with Quiche (HTTP/3), Brotli, Headers More
##################################################
FROM alpine:latest AS builder

ARG SSL_LIBRARY=openssl

ENV OPENSSL_TAG=openssl-3.4.0 \
    LIBRESSL_TAG=v3.9.2 \
    AWS_LC_TAG=v1.37.0 \
    MODULE_NGINX_COOKIE_FLAG=v1.1.0 \
    MODULE_NGINX_DEVEL_KIT=v0.3.3 \
    MODULE_NGINX_ECHO=v0.63 \
    MODULE_NGINX_HEADERS_MORE=v0.37 \
    MODULE_NGINX_MISC=v0.33 \
    MODULE_NGINX_NJS=0.8.7 \
    MODULE_NGINX_VTS=v0.2.2 \
    NGINX=1.27.2

COPY --link ["nginx_dynamic_tls_records.patch", "/usr/src/nginx_dynamic_tls_records.patch"]
COPY --link ["use_openssl_md5_sha1.patch", "/usr/src/use_openssl_md5_sha1.patch"]
COPY --link ["scratchfs", "/scratchfs"]

RUN <<EOF

set -x
echo "Compiling for SSL_LIBRARY: ${SSL_LIBRARY}"
sed -i -r 's/v\d+\.\d+/edge/g' /etc/apk/repositories
apk update
apk upgrade --no-interactive --latest
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
  linux-headers \
  libxml2-dev \
  libxml2-static \
  libxslt-dev \
  libxslt-static \
  m4 \
  make \
  patch \
  perl \
  pcre2-dev \
  samurai \
  xz-static \
  zlib-static

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
if [ "${SSL_LIBRARY}" = "openssl" ]; then curl --silent --location https://github.com/openssl/openssl/archive/refs/tags/${OPENSSL_TAG}.tar.gz | tar xz -C /usr/src --one-top-level=openssl --strip-components=1 || exit 1; fi

#
# LibreSSL
#
if [ "${SSL_LIBRARY}" = "libressl" ]; then curl --silent --location https://github.com/libressl-portable/portable/archive/refs/tags/${LIBRESSL_TAG}.tar.gz | tar xz -C /usr/src --one-top-level=libressl --strip-components=1 || exit 1; fi

#
# AWS-LC
#
if [ "${SSL_LIBRARY}" = "aws-lc" ]; then curl --silent --location https://github.com/aws/aws-lc/archive/refs/tags/${AWS_LC_TAG}.tar.gz | tar xz -C /usr/src --one-top-level=aws-lc --strip-components=1; fi

#
# Cloudflare enhanced zlib
#
curl --silent --location https://github.com/cloudflare/zlib/tarball/gcc.amd64 | tar xz -C /usr/src --one-top-level=zlib --strip-components=1 || exit 1

#
# Module: ngx_brotli
#
git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli /usr/src/ngx_brotli || exit 1

#
# Module: nginx_cookie_flag_module
#
curl --silent --location https://github.com/AirisX/nginx_cookie_flag_module/archive/refs/tags/${MODULE_NGINX_COOKIE_FLAG}.tar.gz | tar xz -C /usr/src --one-top-level=nginx_cookie_flag_module --strip-components=1 || exit 1

#
# Module: ngx_devel_kit
#
curl --silent --location https://github.com/vision5/ngx_devel_kit/archive/refs/tags/${MODULE_NGINX_DEVEL_KIT}.tar.gz | tar xz -C /usr/src --one-top-level=ngx_devel_kit --strip-components=1 || exit 1

#
# Module: echo-nginx-module
#
curl --silent --location https://github.com/openresty/echo-nginx-module/archive/refs/tags/${MODULE_NGINX_ECHO}.tar.gz | tar xz -C /usr/src --one-top-level=echo-nginx-module --strip-components=1 || exit 1

#
# Module: headers-more-nginx-module
#
curl --silent --location https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/${MODULE_NGINX_HEADERS_MORE}.tar.gz | tar xz -C /usr/src --one-top-level=headers-more-nginx-module --strip-components=1 || exit 1

#
# Module: set-misc-nginx-module
#
curl --silent --location https://github.com/openresty/set-misc-nginx-module/archive/refs/tags/${MODULE_NGINX_MISC}.tar.gz | tar xz -C /usr/src --one-top-level=set-misc-nginx-module --strip-components=1 || exit 1

#
# Module: nginx-module-vts
#
curl --silent --location https://github.com/vozlt/nginx-module-vts/archive/refs/tags/${MODULE_NGINX_VTS}.tar.gz | tar xz -C /usr/src --one-top-level=nginx-module-vts --strip-components=1 || exit 1

#
# Module: ngx_http_substitutions_filter_module
#
curl --silent --location https://github.com/yaoweibin/ngx_http_substitutions_filter_module/tarball/master | tar xz -C /usr/src --one-top-level=ngx_http_substitutions_filter_module --strip-components=1 || exit 1

#
# Module: njs
#
curl --silent --location https://github.com/nginx/njs/archive/refs/tags/${MODULE_NGINX_NJS}.tar.gz | tar xz -C /usr/src --one-top-level=njs --strip-components=1 || exit 1

#
# nginx
#
curl --silent --location https://nginx.org/download/nginx-${NGINX}.tar.gz | tar xz -C /usr/src --one-top-level=nginx --strip-components=1 || exit 1
curl --silent --location -o /usr/src/aws-lc-nginx.patch https://raw.githubusercontent.com/aws/aws-lc/main/tests/ci/integration/nginx_patch/aws-lc-nginx.patch || exit 1

#
# brotli cargo compile settings
#
#mkdir -p /root/.cargo
#echo $'[net]\ngit-fetch-with-cli = true' > /root/.cargo/config.toml

#
# OpenSSL
#
if [ "${SSL_LIBRARY}" = "openssl" ]; then
  cd /usr/src/openssl
  CC=clang ./Configure no-shared no-tests linux-generic64
  make -j$(getconf _NPROCESSORS_ONLN) && make install_sw || exit 1
  SSL_COMMIT="${OPENSSL_TAG}"
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
# AWS-LC
#
if [ "${SSL_LIBRARY}" = "aws-lc" ]; then
  mkdir -p /usr/src/aws-lc/build
  cd /usr/src/aws-lc/build
  CC=clang CXX=clang++ cmake \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=../install \
    ..
  cmake --build .
  cmake --install .
  SSL_COMMIT="AWS-LC-${AWS_LC_TAG}"
fi

#
# zlib-cloudflare
#
cd /usr/src/zlib
./configure --static

#
# ngx_brotli
#
cd /usr/src/ngx_brotli/deps/brotli
mkdir out && cd out
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-Ofast -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -ffat-lto-objects -Wl,--gc-sections" \
    -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -ffat-lto-objects -Wl,--gc-sections" \
    -DCMAKE_INSTALL_PREFIX=./installed \
    ..
cmake \
     --build . \
     --config Release \
     --target brotlienc

#
# nginx
#
cd /usr/src/nginx
patch -p1 < /usr/src/nginx_dynamic_tls_records.patch || exit 1
patch -p1 < /usr/src/use_openssl_md5_sha1.patch || exit 1
patch -p1 < /usr/src/aws-lc-nginx.patch || exit 1
CC=/usr/bin/clang \
CXX=/usr/bin/clang++ \
./configure \
   --build="${SSL_COMMIT} ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) ngx-devel-kit-${MODULE_NGINX_DEVEL_KIT} headers-more-nginx-module-${MODULE_NGINX_HEADERS_MORE} echo-nginx-module-${MODULE_NGINX_ECHO} nginx-module-vts-${MODULE_NGINX_VTS} nginx-cookie-flag-module-${MODULE_NGINX_COOKIE_FLAG} set-misc-nginx-module-${MODULE_NGINX_MISC} njs-${MODULE_NGINX_NJS} ngx-http-substitutions-filter-module-latest" \
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
   --with-cc-opt="-I/usr/include/libxml2 -I/usr/src/aws-lc/install/include -O3 -static -Wno-sign-compare -Wno-conditional-uninitialized -Wno-unused-but-set-variable" \
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
   --with-http_slice_module \
   --with-http_stub_status_module \
   --with-http_sub_module \
   --with-http_v2_module \
   --with-http_v3_module \
   --with-http_xslt_module \
   --with-ld-opt="-L/usr/src/aws-lc/install/lib -w -s -static -lexslt -lxslt -lxml2 -lz -llzma" \
   --with-pcre-jit \
   --with-pcre-opt="-O3" \
   --with-poll_module \
   --with-select_module \
   --with-threads \
   --with-zlib-asm=CPU \
   --with-zlib-opt="-O3" \
   --with-zlib=/usr/src/zlib \
   --add-module=/usr/src/ngx_devel_kit \
   --add-module=/usr/src/echo-nginx-module \
   --add-module=/usr/src/headers-more-nginx-module \
   --add-module=/usr/src/nginx_cookie_flag_module \
   --add-module=/usr/src/nginx-module-vts \
   --add-module=/usr/src/ngx_brotli \
   --add-module=/usr/src/ngx_http_substitutions_filter_module \
   --add-module=/usr/src/njs/nginx \
   --add-module=/usr/src/set-misc-nginx-module \
   --without-http_browser_module \
   --without-http_grpc_module \
   --without-http_mirror_module \
   --without-http_scgi_module \
   --without-http_uwsgi_module || cat objs/autoconf.err
make -j$(getconf _NPROCESSORS_ONLN) || exit 1
make -j$(getconf _NPROCESSORS_ONLN) install || exit 1

ls -lh /usr/sbin/nginx
file /usr/sbin/nginx
/usr/sbin/nginx -v

# Populate /scratchfs
cp /etc/nginx/mime.types /scratchfs/etc/nginx/
cp /usr/src/nginx/html/* /scratchfs/var/lib/nginx/html/
cp /usr/sbin/nginx /scratchfs/usr/sbin

EOF

FROM scratch

COPY --from=builder /scratchfs /

EXPOSE 8080/tcp 8443/tcp 8443/udp
STOPSIGNAL SIGQUIT

USER nginx
ENTRYPOINT ["/usr/sbin/nginx"]
CMD ["-g", "daemon off;"]
