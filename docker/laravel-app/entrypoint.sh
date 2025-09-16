#!/bin/bash
set -e

if [ ! -f "vendor/autoload.php" ]; then
    echo ">>> Installing Laravel dependencies..."
    composer install --no-interaction --prefer-dist --optimize-autoloader
fi

if [ ! -f ".env" ]; then
    cp .env.example .env
    php artisan key:generate
    php artisan config:cache
fi

if [ ! -L "public/storage" ]; then
    echo ">>> Creating storage symlink..."
    php artisan storage:link --relative
fi

exec "$@"