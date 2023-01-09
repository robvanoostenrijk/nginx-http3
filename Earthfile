VERSION 0.6

clean:
	LOCALLY
	RUN rm -f -R ./dist

build:
	ARG --required SSL_LIBRARY
	FROM DOCKERFILE . --SSL_LIBRARY=$SSL_LIBRARY

package:
	ARG --required PLATFORM
	ARG --required SSL_LIBRARY
	FROM +build --SSL_LIBRARY=$SSL_LIBRARY

	RUN set -x \
&&		mkdir -p /tmp/dist \
&&		tar -C /usr/sbin -zcvf /tmp/dist/nginx-http3.tar.gz nginx

	SAVE ARTIFACT /tmp/dist/nginx-http3.tar.gz AS LOCAL ./dist/nginx-http3-${PLATFORM}.tar.gz

all:
	ARG SSL_LIBRARY=boringssl

	BUILD +clean
	BUILD --platform=linux/amd64 +package --PLATFORM=amd64 --SSL_LIBRARY=$SSL_LIBRARY
	BUILD --platform=linux/arm64 +package --PLATFORM=arm64 --SSL_LIBRARY=$SSL_LIBRARY
