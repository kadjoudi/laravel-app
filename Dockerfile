################################################################################################
### BASE: shared setup for dev & prod
################################################################################################
FROM serversideup/php:8.4-fpm-nginx-alpine-v3.5.1 AS base

USER root

# Install system and PHP dependencies
RUN apk add --no-cache libpq-dev git \
 && install-php-extensions \
    pgsql \
    pdo_pgsql \
    xml \
    soap \
    apcu \
    intl \
    opcache \
    zip \
    protobuf \
    amqp \
    opentelemetry
################################################################################################
### PROD: final image for App Runner
################################################################################################
FROM base AS prod

# App Runner uses port 8080 by default
ENV AUTORUN_ENABLED="true" \
    AUTORUN_LARAVEL_MIGRATION_ISOLATION="false" \
    AUTORUN_LARAVEL_VIEW_CACHE="false" \
    AUTORUN_LARAVEL_CONFIG_CACHE="false" \
    PHP_OPCACHE_ENABLE="1" \
    OTEL_PHP_AUTOLOAD_ENABLED=true \
    OTEL_SERVICE_NAME=my-laravel-app \
    OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp-gateway-prod-eu-west-2.grafana.net/otlp \
    OTEL_EXPORTER_OTLP_HEADERS="Authorization= <key> \
    OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
    OTEL_TRACES_EXPORTER=otlp \
    OTEL_LOG_LEVEL=debug

WORKDIR /var/www/html
# Copy Laravel app source
COPY ./src /var/www/html

# Remove default Nginx HTTP config to avoid conflict
RUN rm -f /etc/nginx/site-opts.d/http.conf

# Copy your full server block to proper Nginx config location
COPY ./nginx/server.conf /etc/nginx/site-confs.d/server.conf

# Set correct permissions for Laravel folders
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public /var/www/html/database \
 && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public /var/www/html/database

# Add entrypoint scripts (e.g., for Laravel scheduler)
COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/

USER www-data

