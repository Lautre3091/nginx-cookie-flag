FROM nginx:1.17.0-alpine AS builder

# nginx:alpine contains NGINX_VERSION environment variable, like so:
ENV NGINX_VERSION 1.17.0

# Our NGINX_COOKIE_FLAG version
ENV NGINX_COOKIE_FLAG 1.1.0

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
  wget "https://github.com/AirisX/nginx_cookie_flag_module/archive/v${NGINX_COOKIE_FLAG}.tar.gz" -O nginx_cookie_flag.tar.gz

# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN apk add --no-cache --virtual .build-deps \
                    gcc \
                    libc-dev \
                    make \
                    openssl-dev \
                    pcre-dev \
                    zlib-dev \
                    linux-headers \
                    libxslt-dev \
                    gd-dev \
                    geoip-dev \
                    perl-dev \
                    libedit-dev \
                    mercurial \
                    bash \
                    alpine-sdk \
                    findutils

# Reuse same cli arguments as the nginx:alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    mkdir -p /usr/src && \
	tar -zxC /usr/src -f nginx.tar.gz && \
	tar -xzvf "/nginx_cookie_flag.tar.gz" && \
	NGINX_COOKIE_FLAGDIR="/nginx_cookie_flag_module-${NGINX_COOKIE_FLAG}" && \
	cd /usr/src/nginx-$NGINX_VERSION && \
	./configure --with-compat $CONFARGS --add-dynamic-module=$NGINX_COOKIE_FLAGDIR && \
	make && make install

FROM nginx:1.17.0-alpine
# Extract the dynamic module NGINX_COOKIE_FLAG from the builder image
COPY --from=builder /usr/local/nginx/modules/ngx_http_cookie_flag_filter_module.so /etc/nginx/modules/ngx_http_cookie_flag_filter_module.so
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
