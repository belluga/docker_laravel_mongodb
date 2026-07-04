# Boilerplate Flutter & Laravel com Docker

Este repositório agora usa a topologia root/docker vNext extraída do Belluga
Now, mas sem manter identidade Belluga hardcoded na base genérica.

## O que a base espera

- `laravel-app/`: código do backend Laravel.
- `web-app/`: shell web estático já publicado para servir via NGINX.
- `project/`: overlays downstream-owned (`nginx/`, `laravel/`, `well-known/`).

O container root não compila mais o frontend dentro do `docker compose`. A base
assume que o projeto downstream já entrega o shell web em `web-app/`.

## Topologia

- `app`, `worker` e `scheduler` compartilham o mesmo runtime Laravel.
- `nginx` serve o backend PHP e o shell web estático.
- `mongo` + `mongo-init` são opcionais via profile `local-db`.
- `cloudflared` é opcional via profile `local-tunnel`.
- `certbot` continua restrito ao profile `production`.

## Setup rápido

1. Copie o ambiente base:

```bash
cp .env.example .env
```

2. Ajuste pelo menos `PROJECT_NAME`, `PROJECT_PREFIX`, `DOMAIN` e `CERTBOT_EMAIL`.

3. Garanta que o downstream já forneça `laravel-app/` e `web-app/`.

Na lane atual deste repositório, a validação Belluga ainda pode fornecer esses
inputs por `docker-compose.validation-belluga.yml` + `BELLUGA_VALIDATION_ROOT`.
Fora desse override temporário, a base continua exigindo um `web-app/`
materializado localmente.

4. Se precisar de túnel local, crie o arquivo local de segredo:

```bash
cp .env.local.tunnel.example .env.local.tunnel
```

`CLOUDFLARE_TUNNEL_TOKEN` fica apenas em `.env.local.tunnel`, não em `.env.example`.

## Execução local

Com Mongo local:

```bash
APP_ENV=local COMPOSE_PROFILES=local-db docker compose up -d --build
```

Sem Mongo local:

```bash
APP_ENV=local COMPOSE_PROFILES= docker compose up -d --build
```

Com túnel local:

```bash
APP_ENV=local COMPOSE_PROFILES=local-db,local-tunnel \
docker compose --env-file .env --env-file .env.local.tunnel up -d --build
```

Comandos úteis:

```bash
docker compose ps
docker compose logs -f --tail=200
docker compose exec app php artisan <comando>
docker compose exec app composer install
```

## Contratos de CI locais

O runner root de contratos fica em:

```bash
bash tools/ci/run_contract.sh --list --profile stage-full
```

Superfícies atuais:

- `stage-full`: broadest local CI Equivalent at the current root/docker boundary; ele agrega invariantes root-owned, preflight de imagens runtime e o overlay explícito de validação Belluga project-owned, sem alegar paridade de successor fronts web/flutter/browser.
- `stage-full` falha fechado se os inputs Laravel/web shell da validation-owner lane não estiverem materializados antes do `compose config`.
- `main-proof`: separate production-lane semantic guard; ele permanece fail-closed enquanto `docker-compose.validation-belluga.yml` continuar sendo a surface dona da validação local, então não é prova promotable hoje.

Execução:

```bash
bash tools/ci/run_contract.sh --profile stage-full
bash tools/ci/run_contract.sh --profile main-proof
```

## Produção

```bash
APP_ENV=production COMPOSE_PROFILES=production docker compose up -d --build
```

`DOMAIN` e `CERTBOT_EMAIL` devem apontar para o domínio real de produção.

## Overlays downstream-owned

Use `project/` para manter identidade específica fora da base compartilhada:

- `project/nginx/routes.conf.example`: famílias extras de rota antes do fallback SPA.
- `project/laravel/required_runtime_classes.example.txt`: classes críticas para a
  verificação de autoload no entrypoint.
- `project/well-known/*.example.json`: exemplos de payload para App Links /
  Universal Links.

Se `project/nginx/` estiver vazio, o `include /etc/nginx/project/*.conf` é no-op.

## Validação Belluga

`docker-compose.validation-belluga.yml` existe apenas para validar esta extração
contra inputs Belluga fixados por SHA. Ele não é promotable canon.

O proof autoritativo de `stage-full` agora exige que `BELLUGA_VALIDATION_ROOT`
aponte para um checkout Git Belluga congelado exatamente nos SHAs declarados em
`docker-compose.validation-belluga.yml`. O exemplo recomendado desta missão é
`../belluga_now_docker-freeze`; use o sibling default `../belluga_now_docker`
só se ele também estiver limpo e exatamente no ref congelado
`origin/main@1273902de61b158f98c221772e7d41424ce8beb9`.

Esse checkout precisa ser verificável por `git`, estar limpo, e manter os
inputs filhos `laravel-app/` e `web-app/` materializados exatamente nos SHAs
congelados do overlay.

Uso:

```bash
BELLUGA_VALIDATION_ROOT=../belluga_now_docker-freeze \
APP_ENV=local COMPOSE_PROFILES=local-db \
docker compose -f docker-compose.yml -f docker-compose.validation-belluga.yml up -d --build
```

Com checkout Belluga materializado em outro caminho:

```bash
BELLUGA_VALIDATION_ROOT=/caminho/para/belluga_now_docker-freeze \
APP_ENV=local COMPOSE_PROFILES=local-db \
docker compose -f docker-compose.yml -f docker-compose.validation-belluga.yml up -d --build
```

Com túnel:

```bash
APP_ENV=local COMPOSE_PROFILES=local-db,local-tunnel \
docker compose --env-file .env --env-file .env.local.tunnel \
  -f docker-compose.yml -f docker-compose.validation-belluga.yml up -d --build
```

Enquanto esse override existir, a lane continua local-validation-only.
