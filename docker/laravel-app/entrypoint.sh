#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# If vendor directory doesn't exist, run composer install
if [ ! -f "vendor/autoload.php" ]; then
    echo ">>> Installing Laravel dependencies..."
    composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# If .env file doesn't exist, copy it and generate the key
if [ ! -f ".env" ]; then
    cp .env.example .env
    php artisan key:generate
    php artisan config:cache
fi

# Execute the main command passed from docker-compose (php-fpm)
exec "$@"