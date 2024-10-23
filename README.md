# nginx-http3
[![Build and publish container](https://github.com/robvanoostenrijk/nginx-http3/actions/workflows/main.yml/badge.svg)](https://github.com/robvanoostenrijk/nginx-http3/actions/workflows/main.yml)

Static compiled [nginx](https://nginx.org/) with HTTP/3 support, compiled against different SSL libraries supporting QUIC.

 - [AWS-LC ](https://github.com/aws/aws-lc/)
 - [OpenSSL](https://github.com/openssl/openssl)
 - [LibreSSL](https://github.com/libressl-portable/portable)

The compiled version enables the following optional nginx modules

 - [njs](https://nginx.org/en/docs/njs/)
 - [headers-more-nginx-module](https://github.com/openresty/headers-more-nginx-module)
 - [echo-nginx-module](https://github.com/openresty/echo-nginx-module)
 - [nginx_fancyindex](https://github.com/aperezdc/ngx-fancyindex)
 - [nginx-module-vts](https://github.com/vozlt/nginx-module-vts)
 - [nginx_cookie_flag_module](https://github.com/AirisX/nginx_cookie_flag_module)
 - [nginx_set_misc_module](https://github.com/openresty/set-misc-nginx-module)
