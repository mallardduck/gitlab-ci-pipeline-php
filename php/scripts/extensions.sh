#!/usr/bin/env bash

set -euo pipefail

export extensions=" \
    bcmath \
    bz2 \
    calendar \
    exif \
    gmp \
    intl \
    mysqli \
    opcache \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    soap \
    xsl \
    zip
    "

export buildDeps=" \
    default-libmysqlclient-dev \
    libbz2-dev \
    libsasl2-dev \
    pkg-config \
    "

export runtimeDeps=" \
    imagemagick \
    libfreetype6-dev \
    libgmp-dev \
    libicu-dev \
    libjpeg-dev \
    libkrb5-dev \
    libldap2-dev \
    libmagickwand-dev \
    libmemcached-dev \
    libmemcachedutil2 \
    libpng-dev \
    libpq-dev \
    librabbitmq-dev \
    libssl-dev \
    libuv1-dev \
    libwebp-dev \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    "


apt-get update \
  && apt --fix-broken install \
  && apt-get install -yq $buildDeps \
  && apt-get install -yq $runtimeDeps \
  && rm -rf /var/lib/apt/lists/* \
  && docker-php-ext-install -j$(nproc) $extensions

docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
  && docker-php-ext-install -j$(nproc) gd \
  && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
  && docker-php-ext-install -j$(nproc) ldap \
  && PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
  && docker-php-ext-install -j$(nproc) imap \
  && docker-php-source delete

docker-php-source extract \
  && git clone https://github.com/php-memcached-dev/php-memcached /usr/src/php/ext/memcached/ \
  && docker-php-ext-install memcached \
  && docker-php-ext-enable memcached \
  && docker-php-source delete

pecl channel-update pecl.php.net \
  && pecl install redis apcu xdebug \
  && docker-php-ext-enable redis apcu xdebug

#AMQP
docker-php-source extract \
  && mkdir /usr/src/php/ext/amqp \
  && curl -L https://github.com/php-amqp/php-amqp/archive/master.tar.gz | tar -xzC /usr/src/php/ext/amqp --strip-components=1 \
  && docker-php-ext-install amqp \
  && docker-php-source delete

#Imagick
cd /usr/local/src \
  && git clone https://github.com/Imagick/imagick \
  && cd imagick \
  && phpize \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && rm -rf imagick \
  && docker-php-ext-enable imagick

#XMLRPC
mkdir /usr/local/src/xmlrpc \
  && cd /usr/local/src/xmlrpc \
  && curl -L https://pecl.php.net/get/xmlrpc-1.0.0RC3.tgz | tar -xzC /usr/local/src/xmlrpc --strip-components=1 \
  && phpize \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && rm -rf xmlrpc \
  && docker-php-ext-enable xmlrpc

{ \
    echo 'opcache.enable=1'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=192'; \
    echo 'opcache.max_wasted_percentage=10'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.fast_shutdown=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

{ \
    echo 'apc.shm_segments=1'; \
    echo 'apc.shm_size=1024M'; \
    echo 'apc.num_files_hint=7000'; \
    echo 'apc.user_entries_hint=4096'; \
    echo 'apc.ttl=7200'; \
    echo 'apc.user_ttl=7200'; \
    echo 'apc.gc_ttl=3600'; \
    echo 'apc.max_file_size=100M'; \
    echo 'apc.stat=1'; \
} > /usr/local/etc/php/conf.d/apcu-recommended.ini

echo 'memory_limit=1024M' > /usr/local/etc/php/conf.d/zz-conf.ini

# https://xdebug.org/docs/upgrade_guide#changed-xdebug.coverage_enable
echo 'xdebug.mode=coverage' > /usr/local/etc/php/conf.d/20-xdebug.ini

apt-get purge -yqq --auto-remove $buildDeps
