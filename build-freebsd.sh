#!/bin/sh

BASE_DIR="$(cd "$(dirname "$0")"; pwd)";
echo "[i] BASE_DIR => $BASE_DIR"

AWS_LC_TAG=v1.33.0
MODULE_NGINX_HEADERS_MORE=v0.37
MODULE_NGINX_ECHO=v0.63
MODULE_NGINX_VTS=v0.2.2
MODULE_NGINX_COOKIE_FLAG=v1.1.0
MODULE_NGINX_NJS=0.8.4
NGINX=1.27.0

find /usr/src -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} \;

#
# AWS-LC
#
echo "[i] Downloading: AWS-LC"
curl --silent --location https://github.com/aws/aws-lc/archive/refs/tags/${AWS_LC_TAG}.tar.gz | gtar xz -C /usr/src --one-top-level=aws-lc --strip-components=1 || exit 1

#
# Module: ngx_brotli
#
echo "[i] Downloading: nginx_brotli"
git clone --depth=1 --recursive --shallow-submodules https://github.com/google/ngx_brotli /usr/src/ngx_brotli || exit 1

#
# Module: headers-more-nginx-module
#
echo "[i] Downloading: headers-more-nginx-module"
curl --silent --location https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/${MODULE_NGINX_HEADERS_MORE}.tar.gz | gtar xz -C /usr/src --one-top-level=headers-more-nginx-module --strip-components=1 || exit 1

#
# Module: echo-nginx-module
#
echo "[i] Downloading: echo-nginx-module"
curl --silent --location https://github.com/openresty/echo-nginx-module/archive/refs/tags/${MODULE_NGINX_ECHO}.tar.gz | gtar xz -C /usr/src --one-top-level=echo-nginx-module --strip-components=1 || exit 1

#
# Module: nginx-module-vts
#
echo "[i] Downloading: nginx-module-vts"
curl --silent --location https://github.com/vozlt/nginx-module-vts/archive/refs/tags/${MODULE_NGINX_VTS}.tar.gz | gtar xz -C /usr/src --one-top-level=nginx-module-vts --strip-components=1 || exit 1

#
# Module: nginx_cookie_flag_module
#
echo "[i] Downloading: nginx_cookie_flag_module"
curl --silent --location https://github.com/AirisX/nginx_cookie_flag_module/archive/refs/tags/${MODULE_NGINX_COOKIE_FLAG}.tar.gz | gtar xz -C /usr/src --one-top-level=nginx_cookie_flag_module --strip-components=1 || exit 1

#
# Module: ngx_http_substitutions_filter_module
#
echo "[i] Downloading: ngx_http_substitutions_filter_module"
curl --silent --location https://github.com/yaoweibin/ngx_http_substitutions_filter_module/tarball/master | gtar xz -C /usr/src --one-top-level=ngx_http_substitutions_filter_module --strip-components=1 || exit 1

#
# Module: njs
#
echo "[i] Downloading: njs"
curl --silent --location https://github.com/nginx/njs/archive/refs/tags/${MODULE_NGINX_NJS}.tar.gz | gtar xz -C /usr/src --one-top-level=njs --strip-components=1 || exit 1

#
# nginx
#
echo "[i] Downloading: nginx"
curl --silent --location https://nginx.org/download/nginx-${NGINX}.tar.gz | gtar xz -C /usr/src --one-top-level=nginx --strip-components=1 || exit 1
curl --silent --location -o /usr/src/aws-lc-nginx.patch https://raw.githubusercontent.com/aws/aws-lc/main/tests/ci/integration/nginx_patch/aws-lc-nginx.patch || exit 1

#
# AWS-LC
#
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
mkdir -p /usr/src/aws-lc/install/.openssl/lib /usr/src/aws-lc/install/.openssl/include
ln -sf /usr/src/aws-lc/install/include/openssl /usr/src/aws-lc/install/.openssl/include/openssl
cp /usr/src/aws-lc/install/lib/libcrypto.a /usr/src/aws-lc/install/lib/libssl.a /usr/src/aws-lc/install/.openssl/lib
SSL_COMMIT="AWS-LC-${AWS_LC_TAG}"

#
# ngx_brotli
#
echo "[i] Compiling: nginx_brotli"
cd /usr/src/ngx_brotli/deps/brotli
mkdir out && cd out
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_FLAGS="-Ofast -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections" \
    -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections" \
    -DCMAKE_INSTALL_PREFIX=./installed \
    ..
cmake \
     --build . \
     --config Release \
     --target brotlienc

#
# nginx
#
echo "[i] Compiling: nginx"
cd /usr/src/nginx
patch -p1 < /usr/src/aws-lc-nginx.patch || exit 1
CC=/usr/bin/clang \
CXX=/usr/bin/clang++ \
./configure \
   --build="${SSL_COMMIT} ngx_brotli-$(git --git-dir=/usr/src/ngx_brotli/.git rev-parse --short HEAD) headers-more-nginx-module-${MODULE_NGINX_HEADERS_MORE} echo-nginx-module-${MODULE_NGINX_ECHO} nginx-module-vts-${MODULE_NGINX_VTS} nginx_cookie_flag_module-${MODULE_NGINX_COOKIE_FLAG} njs-${MODULE_NGINX_NJS} ngx_http_substitutions_filter_module-latest" \
   --prefix=/usr/local/etc/nginx \
   --sbin-path=/usr/local/sbin/nginx \
   --modules-path=/usr/lib/nginx/modules \
   --conf-path=/usr/local/etc/nginx/nginx.conf \
   --pid-path=/var/run/nginx.pid \
   --http-log-path=/var/log/nginx/access.log \
   --error-log-path=/var/log/nginx/error.log \
   --lock-path=/run/nginx/nginx.lock \
   --http-client-body-temp-path=/var/tmp/nginx/client_body_temp \
   --http-proxy-temp-path=/var/tmp/nginx/proxy_temp \
   --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi_temp \
   --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi_temp \
   --http-scgi-temp-path=/var/tmp/nginx/scgi_temp \
   --user=www \
   --group=www \
   --with-cc-opt="-I /usr/src/libxml2 -I /usr/src/aws-lc/install/include -I /usr/local/include" \
   --with-ld-opt="-L /usr/src/aws-lc/install/lib -L /usr/src/libxml2 -L /usr/local/lib" \
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
   --with-poll_module \
   --with-select_module \
   --with-zlib-asm=CPU \
   --with-zlib-opt="-O3" \
   --add-module=/usr/src/echo-nginx-module \
   --add-module=/usr/src/headers-more-nginx-module \
   --add-module=/usr/src/nginx_cookie_flag_module \
   --add-module=/usr/src/nginx-module-vts \
   --add-module=/usr/src/ngx_brotli \
   --add-module=/usr/src/ngx_http_substitutions_filter_module \
   --add-module=/usr/src/njs/nginx \
   --without-http_browser_module \
   --without-http_grpc_module \
   --without-http_mirror_module \
   --without-http_scgi_module \
   --without-http_uwsgi_module || cat objs/autoconf.err
make -j$(getconf _NPROCESSORS_ONLN) || exit 1

ls -lh /usr/src/nginx/objs/nginx
file /usr/src/nginx/objs/nginx
/usr/src/nginx/objs/nginx -vv

tar -C /usr/src/nginx/objs -Jcvf ${BASE_DIR}/nginx-http3-aws-lc-freebsd-amd64.tar.xz nginx
