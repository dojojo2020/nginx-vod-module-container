FROM alpine:3.12.0 AS base_image

FROM base_image AS build

ARG UID=101
ARG GID=101

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g $GID -S nginx \
    && adduser -S -D -H -u $UID -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apk add --no-cache curl build-base openssl openssl-dev zlib-dev linux-headers pcre-dev ffmpeg ffmpeg-dev
RUN mkdir nginx nginx-vod-module

ARG NGINX_VERSION=1.16.1
ARG VOD_MODULE_VERSION=399e1a0ecb5b0007df3a627fa8b03628fc922d5e

RUN curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -C /nginx --strip 1 -xz
RUN curl -sL https://github.com/kaltura/nginx-vod-module/archive/${VOD_MODULE_VERSION}.tar.gz | tar -C /nginx-vod-module --strip 1 -xz
WORKDIR /nginx
RUN ./configure --prefix=/var/cache/nginx \
	--add-module=../nginx-vod-module \
	--with-http_ssl_module \
	--with-file-aio \
	--with-threads \
	--with-cc-opt='-O3'

RUN make \
    && make install
RUN rm -rf /var/cache/nginx/html /var/cache/nginx/conf/*.default


# implement changes required to run NGINX as an unprivileged user
RUN ##sed -i 's,listen       80;,listen       8080;,' /var/cache/nginx/conf.d/default.conf \
    sed -i '/user  nginx;/d' /var/cache/nginx/conf/nginx.conf \
    && sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /var/cache/nginx/conf/nginx.conf \
    && sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /var/cache/nginx/conf/nginx.conf \
# nginx user must own the cache and etc directory to write cache and tweak the nginx config
RUN chown -R $UID:0 /var/cache/nginx \
    && chmod -R g+w /var/cache/nginx 
##    && chown -R $UID:0 /etc/nginx \
##    && chmod -R g+w /etc/nginx

USER $UID


FROM base_image
RUN apk add --no-cache ca-certificates openssl pcre zlib ffmpeg
COPY --from=build /var/cache/nginx /var/cache/nginx


ENTRYPOINT ["/var/cache/nginx/sbin/nginx"]
CMD ["-g", "daemon off;"]
