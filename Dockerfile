FROM php:7.1.20-fpm-alpine

ENV NGINX_VERSION 1.12.2

# Install packages for running application
RUN apk --no-cache add ca-certificates openssl pcre zlib libpng libjpeg libmcrypt icu libxml2 freetype libjpeg-turbo
RUN apk --no-cache add --virtual .phpize-deps $PHPIZE_DEPS
RUN apk --no-cache add --virtual .build-deps build-base linux-headers openssl-dev pcre-dev zlib-dev wget libmcrypt-dev libpng-dev icu-dev libxml2-dev g++ freetype-dev libjpeg-turbo-dev
RUN apk --no-cache add git curl nginx supervisor

RUN docker-php-ext-configure intl
RUN docker-php-ext-install mcrypt gd intl mbstring opcache pdo_mysql ctype session xml dom

# Instal Nginx with http_realip_module
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN tar zxvf nginx-${NGINX_VERSION}.tar.gz
RUN cd nginx-${NGINX_VERSION} \
  && ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-file-aio \
    --with-http_v2_module \
    --with-ipv6 \
    --with-stream_realip_module \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && sed -i -e 's/#access_log  logs\/access.log  main;/access_log \/dev\/stdout;/' -e 's/#error_log  logs\/error.log  notice;/error_log stderr notice;/' /etc/nginx/nginx.conf \
    && mkdir -p /var/cache/nginx \
    && apk del .build-deps \
    && rm -rf /tmp/*

RUN rm nginx-${NGINX_VERSION}.tar.gz && rm -rf nginx-${NGINX_VERSION}

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer