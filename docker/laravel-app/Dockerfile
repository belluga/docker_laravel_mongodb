FROM php:8.4.10-fpm AS builder

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    zip unzip curl git libonig-dev libzip-dev libssl-dev \
    && docker-php-ext-install pdo pdo_mysql mbstring zip \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# --- CHANGES START HERE ---

# 1. Copy your Laravel application code from your local machine into the image
COPY ./laravel-app /var/www

# 2. Set the correct permissions on storage and cache directories during the build
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache && \
    chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# --- CHANGES END HERE ---

# Copy and set executable the entrypoint script
COPY docker/laravel-app/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]