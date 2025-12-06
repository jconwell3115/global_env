---
title: Create Nextcloud stack podman-compose
tags:
  - Self-Hosting
  - NextCloud
  - podman-compose
  - Podman
created: 2025-12-03
published:
status: draft
---
This deploys `mariadb`, `redis`, `nextcloud`, and `adminer` (adminer optional).
```yaml
# /srv/nextcloud/docker-compose.yml
version: "3.7"

services:
  db:
    container_name: nextcloud_db
    image: docker.io/library/mariadb:10.11
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      MYSQL_DATABASE: "${MYSQL_DATABASE}"
      MYSQL_USER: "${MYSQL_USER}"
      MYSQL_PASSWORD: "${MYSQL_PASSWORD}"
    volumes:
      - db_data:/var/lib/mysql:Z
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    container_name: nextcloud_redis
    image: docker.io/redis:7-alpine
    restart: always
    command: ["redis-server", "--save", "", "--appendonly", "no"]
    volumes:
      - redis_data:/data:Z
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  nextcloud:
    container_name: nextcloud_app
    image: docker.io/nextcloud:latest
    restart: always
    ports:
      - "8080:80"     # HTTP access
      - "8443:443"    # HTTPS access (if you configure SSL in Nextcloud)
      #  - "127.0.0.1:8080:80"    # bind to localhost; public access via Cloudflare Tunnel
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      MYSQL_HOST: db
      MYSQL_DATABASE: "${MYSQL_DATABASE}"
      MYSQL_USER: "${MYSQL_USER}"
      MYSQL_PASSWORD: "${MYSQL_PASSWORD}"
      MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
      NEXTCLOUD_ADMIN_USER: "${NEXTCLOUD_ADMIN_USER}"
      NEXTCLOUD_ADMIN_PASSWORD: "${NEXTCLOUD_ADMIN_PASSWORD}"
      NEXTCLOUD_TRUSTED_DOMAINS: "${NEXTCLOUD_TRUSTED_DOMAIN}"
      REDIS_HOST: "nextcloud_redis"
      REDIS_HOST_PORT: "6379"
    volumes:
      - nextcloud_data:/var/www/html/data:Z
      - nextcloud_config:/var/www/html/config:Z
      - nextcloud_apps:/var/www/html/apps:Z
    labels:
      - "io.containers.autoupdate=registry"
    healthcheck:
	  test: ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 4

  adminer:
    container_name: nextcloud_adminer
    image: docker.io/adminer:latest
    restart: "no"
    ports:
      - "127.0.0.1:8081:8080"
    environment:
      ADMINER_DEFAULT_SERVER: db
    # adminer is optional: accessible only on localhost for convenience when debugging DB

volumes:
  db_data:
  redis_data:
  nextcloud_data:
  nextcloud_config:
  nextcloud_apps:
```

Notes:
- Binding Nextcloud to `127.0.0.1:8080` keeps it inaccessible publicly except through the Cloudflare Tunnel. Adjust if you prefer a different setup.  
- `:Z` relabels mounts for SELinux. Use `:z` if you want shared labeling instead.  
- Pin images to specific tags (recommended) for controlled upgrades.

