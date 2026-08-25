#!/bin/sh
set -e

if [ "$APP_ENV" = "production" ]; then
  TEMPLATE_FILE=/etc/nginx/templates/prod.conf.template
  until [ -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ]; do
    echo "Waiting for SSL certificate for ${DOMAIN}..."
    sleep 5
  done
else
  TEMPLATE_FILE=/etc/nginx/templates/local.conf.template
fi

envsubst '${DOMAIN}' < $TEMPLATE_FILE > /etc/nginx/conf.d/default.conf

echo "NGINX configuration generated for environment: $APP_ENV"

exec nginx -g 'daemon off;'
