FROM nginx:stable-alpine

RUN apk update && apk add --no-cache gettext openssl

RUN mkdir -p /etc/nginx/project

RUN mkdir -p /etc/nginx/certs/local \
    && openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
      -subj "/CN=localhost" \
      -addext "subjectAltName=DNS:localhost,IP:127.0.0.1" \
      -keyout /etc/nginx/certs/local/privkey.pem \
      -out /etc/nginx/certs/local/fullchain.pem

COPY ./prod.conf.template /etc/nginx/templates/
COPY ./local.conf.template /etc/nginx/templates/
COPY ./entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
