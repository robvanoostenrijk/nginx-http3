VERSION 0.6

clean:
	LOCALLY
	RUN rm -f -R ./dist

build:
	ARG --required SSL_LIBRARY
	FROM DOCKERFILE . --SSL_LIBRARY=$SSL_LIBRARY

package:
	ARG --required SSL_LIBRARY
	FROM +build --SSL_LIBRARY=$SSL_LIBRARY

	RUN set -x \
&&		mkdir -p /build/dist \
&&		XZ_OPT=-9 tar -C /usr/sbin -Jcvf /build/dist/nginx-http3.tar.xz nginx

	SAVE ARTIFACT /build/dist/nginx-http3.tar.xz AS LOCAL ./dist/nginx-http3.tar.xz

all:
	ARG SSL_LIBRARY=openssl

	BUILD +clean
	BUILD +package --SSL_LIBRARY=$SSL_LIBRARY
