#!/bin/sh
set -e

if [ "$APP_ENV" = "production" ]; then
  TEMPLATE_FILE=/etc/nginx/templates/prod.conf.template
else
  TEMPLATE_FILE=/etc/nginx/templates/local.conf.template
fi

envsubst '${DOMAIN}' < $TEMPLATE_FILE > /etc/nginx/conf.d/default.conf
echo "NGINX configuration generated for environment: $APP_ENV"

# Garante que o usuário 'nginx' seja o dono da pasta do Flutter.
chown -R nginx:nginx /var/www/flutter

exec nginx -g 'daemon off;'