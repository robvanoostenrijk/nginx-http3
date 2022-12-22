VERSION 0.6

clean:
	LOCALLY
	RUN rm -f -R ./dist

openssl:
	FROM DOCKERFILE . --SSL_LIBRARY=openssl

libressl:
	FROM DOCKERFILE . --SSL_LIBRARY=libressl

package:
	FROM +build

	RUN set -x \
&&		mkdir -p /build/dist \
&&		XZ_OPT=-9 tar -C /usr/sbin -Jcvf /build/dist/nginx-http3.tar.xz nginx

	SAVE ARTIFACT /build/dist/nginx-http3.tar.xz AS LOCAL ./dist/nginx-http3.tar.xz

all:
	BUILD +clean
	BUILD +openssl
