# nginx-http3
[![Build and publish container](https://github.com/robvanoostenrijk/nginx-http3/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/robvanoostenrijk/nginx-http3/actions/workflows/main.yml)

Static compiled [nginx-quic](https://hg.nginx.org/nginx-quic) (HTTP/3 support), with the option to compile against different SSL libraries supporting quick.

 - [BoringSSL](https://github.com/google/boringssl)
 - [Quictls](https://github.com/quictls/openssl) (OpenSSL+quic1)
 - [LibreSSL](https://github.com/libressl-portable/portable)

The compiled version enables the following optional nginx modules

 - [njs](https://nginx.org/en/docs/njs/)
 - [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
 - [echo-nginx-module](https://github.com/openresty/echo-nginx-module)
 - [nginx_fancyindex](https://github.com/aperezdc/ngx-fancyindex)
 - [nginx-module-vts](https://github.com/vozlt/nginx-module-vts)
 - [nginx_cookie_flag_module](https://github.com/AirisX/nginx_cookie_flag_module)

Additionally a patch is applied to enable HTTP/2 HPACK feature developed by [Cloudflare](https://blog.cloudflare.com/hpack-the-silent-killer-feature-of-http-2/).
