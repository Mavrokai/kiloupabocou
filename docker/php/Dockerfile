FROM php:8.2-fpm


RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*


RUN docker-php-ext-install pdo_mysql pdo mbstring exif pcntl bcmath gd


COPY --from=composer:latest /usr/bin/composer /usr/bin/composer


RUN mkdir -p /var/log/php && \
    chmod 777 /var/log/php


RUN echo "error_log = /var/log/php/php_errors.log" >> /usr/local/etc/php/conf.d/docker-php-log.ini && \
    echo "log_errors = On" >> /usr/local/etc/php/conf.d/docker-php-log.ini

WORKDIR /var/www/html


RUN usermod -u 1000 www-data && \
    groupmod -g 1000 www-data

USER www-data

