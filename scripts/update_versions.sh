
#!/bin/sh

# Retrieve latest version number tag from a github repository
get_latest_tag()
{
	curl -s "https://api.github.com/repos/${1}/tags" | jq -r --arg v "${2}" 'first(.[] | select(.name | startswith($v))).name' | tr -d -c '0-9.'
}

# Generate versions.env (shell env format)
cat <<- EOF > versions.env
	AWS_LC_TAG=v$(get_latest_tag aws/aws-lc v)
	LIBRESSL_TAG=v$(get_latest_tag libressl/portable v)
	OPENSSL_TAG=openssl-$(get_latest_tag openssl/openssl openssl)
	MODULE_NGINX_COOKIE_FLAG=v$(get_latest_tag AirisX/nginx_cookie_flag_module v)
	MODULE_NGINX_DEVEL_KIT=v$(get_latest_tag vision5/ngx_devel_kit v)
	MODULE_NGINX_ECHO=v$(get_latest_tag openresty/echo-nginx-module v)
	MODULE_NGINX_HEADERS_MORE=v$(get_latest_tag openresty/headers-more-nginx-module v)
	MODULE_NGINX_MISC=v$(get_latest_tag openresty/set-misc-nginx-module v)
	MODULE_NGINX_NJS=$(get_latest_tag nginx/njs)
	MODULE_NGINX_VTS=v$(get_latest_tag vozlt/nginx-module-vts v)
	NGINX=$(get_latest_tag nginx/nginx release)
EOF
