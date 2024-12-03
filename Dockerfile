ARG PHP_VERSION=8.4.1
FROM php:${PHP_VERSION}-apache-bookworm

LABEL org.opencontainers.image.authors="PERROUAS Thibault <thibaultperrouas8@gmail.com>"

ENV APACHE_DOCUMENT_ROOT=/var/www/public

# Configurer le document root d'Apache
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Installer les extensions et dépendances nécessaires
RUN set -eux; \
    apt-get update && apt-get -y upgrade; \
    apt-get install -y \
        libaio1 \
        wget \
        unzip \
        libicu-dev \
        libzip-dev \
        libyaml-dev \
        gettext \
        graphviz \
        libmagickwand-dev \
        librabbitmq-dev \
        libpq-dev \
        libxslt1-dev \
        libjpeg62-turbo \
        libpng16-16 \
        git \
        unzip \
        curl \
        && pecl install apcu yaml igbinary redis; \
    docker-php-ext-enable apcu yaml igbinary redis; \
    docker-php-ext-install -j$(nproc) iconv; \
    docker-php-ext-configure intl; \
    docker-php-ext-install -j$(nproc) intl; \
    docker-php-ext-install -j$(nproc) \
        exif \
        bcmath \
        xsl \
        gettext \
        opcache \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        pgsql \
        soap \
        zip \
        sockets; \
    curl -L https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions > /usr/local/bin/install-php-extensions; \
    chmod +x /usr/local/bin/install-php-extensions; \
    install-php-extensions gd amqp; \
    rm -f /usr/local/bin/install-php-extensions; \
    docker-php-source delete; \
    apt-get remove -y g++ wget; \
    apt-get autoremove --purge -y && apt-get autoclean -y && apt-get clean -y; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /tmp/* /var/tmp/*;

# Configurer la configuration PHP
RUN { \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    { \
        echo 'date.timezone=Asia/Dhaka'; \
        echo 'upload_max_filesize=256M'; \
        echo 'post_max_size=2048M'; \
        echo 'max_input_vars=10000'; \
        echo 'memory_limit=3504M'; \
        echo 'expose_php = off'; \
        echo 'max_execution_time = 300'; \
    } > /usr/local/etc/php/conf.d/00-override.ini; \
    { \
        echo 'error_reporting = E_ALL'; \
        echo 'display_errors = Off'; \
        echo 'display_startup_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'error_log = /dev/stderr'; \
        echo 'log_errors_max_len = 1024'; \
        echo 'ignore_repeated_errors = On'; \
        echo 'ignore_repeated_source = Off'; \
        echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini

# Augmenter la taille des champs de requête
RUN echo 'LimitRequestFieldSize 5242880' >> /etc/apache2/apache2.conf

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Activer le module rewrite d'Apache
RUN a2enmod rewrite

# Exposer le port 80
EXPOSE 80

# Démarrer Apache en mode premier plan
CMD ["apache2-foreground"]
