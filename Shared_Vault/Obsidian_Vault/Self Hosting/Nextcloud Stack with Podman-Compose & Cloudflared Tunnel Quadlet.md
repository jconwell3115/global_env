---
title: Nextcloud Stack with Podman-Compose & Cloudflared Tunnel Quadlet
tags:
  - Self-Hosting
  - Podman
  - podman-compose
  - Cloudflare
  - Nextcloud
  - Quadlet
created: 2025-11-25
published:
status: draft
---

# Nextcloud (base) + MariaDB + Redis on Podman-compose with Cloudflare Tunnel (cloudflared)
A complete, practical how‑to to run the Nextcloud "base" image together with MariaDB and Redis using `podman-compose` on a single host, and to expose it via a Cloudflare Tunnel with `cloudflared`. Includes an alternative to run `cloudflared` as a systemd-managed unit (quadlet-style), SELinux notes, backups, and an extended troubleshooting section.

---

## High level summary (what you’ll end up with)
- A `podman-compose` stack: `nextcloud` (official image), `mariadb`, `redis`, and optionally `adminer` for DB debug.  
- A private container network so `cloudflared` (container or systemd container) can talk to the Nextcloud service (no public host ports open).  
- A Cloudflare Tunnel routing your public hostname (e.g. `nextcloud.example.com`) to the Nextcloud HTTP service inside the podman network; TLS handled by Cloudflare.  
- A systemd timer to run Nextcloud cron tasks.  
- Guidance on trusted proxies, `overwrite.cli.url`, Redis locking, SELinux labeling, backups, and troubleshooting.

---

## Prerequisites
- Linux host with Podman >= 4.x and `podman-compose` installed.  
- `systemd` (for cron and optional cloudflared unit).  
- Cloudflare account and a domain managed by Cloudflare (to create a Cloudflare Tunnel).  
- Familiarity with the shell as root or a user with podman permissions (examples use rootless Podman where reasonable).  
- At least 1–2 GB RAM for a small install (more for multiple users).

---

## Suggested directory layout
Create a working directory (example `/srv/nextcloud`) with:
- `/srv/nextcloud/.env`
- `/srv/nextcloud/docker-compose.yml`
- `/srv/nextcloud/cloudflared/config.yml` + tunnel credentials JSON
- `/srv/nextcloud/data` (Nextcloud data)
- `/srv/nextcloud/db` (MariaDB data)
- `/srv/nextcloud/config` (optional preseeded `config.php`)

Create directories and set ownership for rootless Podman:
```bash
sudo mkdir -p /srv/nextcloud/{data,db,config,cloudflared}
sudo chown $USER:$USER /srv/nextcloud -R   # for rootless podman use your user; if running podman as root adjust accordingly
```

---

## Files to create

### 1) .env — put secrets here (do NOT commit)
```bash
# /srv/nextcloud/.env
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=ChangeMeStrongPassword!
MYSQL_ROOT_PASSWORD=ChangeDbRootPass!
MYSQL_PASSWORD=nextcloudpass
MYSQL_DATABASE=nextcloud
MYSQL_USER=ncuser
NEXTCLOUD_TRUSTED_DOMAIN=nextcloud.example.com
PODMAN_PROJECT=nextcloud
```

---

### 2) docker-compose.yml (podman-compose compatible)
This deploys `mariadb`, `redis`, `nextcloud`, and `adminer` (adminer optional).
```yaml
# /srv/nextcloud/docker-compose.yml
version: "3.7"

services:
  db:
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
    image: docker.io/nextcloud:latest
    restart: always
    ports:
      - "127.0.0.1:8080:80"    # bind to localhost; public access via Cloudflare Tunnel
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
    volumes:
      - nextcloud_data:/var/www/html/data:Z
      - nextcloud_config:/var/www/html/config:Z
      - nextcloud_apps:/var/www/html/apps:Z
    labels:
      - "io.containers.autoupdate=registry"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/ || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 4

  adminer:
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

---

### 3) cloudflared config.yml (Cloudflare Tunnel)
Put at `/srv/nextcloud/cloudflared/config.yml` (replace placeholders).
```yaml
# /srv/nextcloud/cloudflared/config.yml
tunnel: TUNNEL-UUID-OR-NAME
credentials-file: /home/user/.cloudflared/TUNNEL-UUID.json

ingress:
  - hostname: nextcloud.example.com
    service: http://nextcloud:80
  - service: http_status:404
```

Notes:
- `credentials-file` is created by `cloudflared tunnel create <name>` and is a JSON you must copy into the mounted directory. For rootless Podman, store it under `/home/youruser/.cloudflared` and mount the folder.

---

## Running cloudflared

Two options:

### Option A: Run cloudflared as part of podman-compose
Append a service to `docker-compose.yml`:
```yaml
  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    volumes:
      - ./cloudflared:/home/nonroot/.cloudflared:Z
    command: ["tunnel", "--config", "/home/nonroot/.cloudflared/config.yml", "run"]
    networks:
      - default
    # no ports exposed
```
- Ensure credentials and config are present in `./cloudflared` and owned appropriately.

### Option B (recommended): Run cloudflared via systemd unit (quadlet-style)
Run `cloudflared` as a separately managed Podman container under systemd for independent lifecycle and resilience.

Create systemd unit `/etc/systemd/system/cloudflared.service`:
```ini
# /etc/systemd/system/cloudflared.service
[Unit]
Description=Cloudflare Tunnel (cloudflared) container via Podman
Wants=network-online.target
After=network-online.target

[Service]
Restart=always
RestartSec=5
# If running rootless cloudflared as your user, set User=youruser and proper HOME
User=root
Environment=HOME=/root
ExecStartPre=-/usr/bin/podman rm -f cloudflared
ExecStart=/usr/bin/podman run --name cloudflared \
  --network nextcloud_default \
  -v /srv/nextcloud/cloudflared:/home/nonroot/.cloudflared:Z \
  -u 0 \
  docker.io/cloudflare/cloudflared:latest tunnel --no-autoupdate --config /home/nonroot/.cloudflared/config.yml run
ExecStop=/usr/bin/podman stop -t 10 cloudflared
ExecStopPost=/usr/bin/podman rm -f cloudflared

[Install]
WantedBy=multi-user.target
```

Notes:
- `--network nextcloud_default` is the default network name created by `podman-compose` if your project name is `nextcloud`. To be explicit, create and use a named network:
```bash
sudo podman network create nextcloud_net
```
Then in `docker-compose.yml` add:
```yaml
networks:
  default:
    external:
      name: nextcloud_net
```
And use `--network nextcloud_net` in the unit.

---

## Bring up the podman-compose stack
From `/srv/nextcloud`:
```bash
podman-compose up -d
```
Check status:
```bash
podman ps -a
podman logs nextcloud
```

---

## Initial Nextcloud setup
- If the DB env vars are correct, Nextcloud should perform initial setup automatically on first boot. You can visit `http://localhost:8080` locally or the public hostname via Cloudflare once the Tunnel is active.
- After initial install you MUST configure trusted proxies and overwrite settings so Nextcloud knows its external URL and trusts the tunnel.

---

## Configure trusted proxy, overwrite URL, and Redis locking

1. Find `cloudflared` container IP (if running in container):
```bash
podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cloudflared
```

2. Add `cloudflared` to trusted proxies (replace `X.X.X.X` with the appropriate IP; or use `127.0.0.1` if cloudflared accesses via localhost):
```bash
podman exec -it nextcloud /bin/sh -c "cd /var/www/html && php occ config:system:set trusted_proxies 1 --value='X.X.X.X'"
```

3. Set `overwrite.cli.url` and `overwriteprotocol`:
```bash
podman exec -it nextcloud /bin/sh -c "cd /var/www/html && php occ config:system:set overwrite.cli.url --value='https://nextcloud.example.com'"
podman exec -it nextcloud /bin/sh -c "cd /var/www/html && php occ config:system:set overwriteprotocol --value='https'"
```

4. Configure Redis for memcache and file locking:
- Enable the Redis app:
```bash
podman exec -it nextcloud /bin/sh -c "cd /var/www/html && php occ app:enable redis"
```
- Configure memcache/locking in `config.php`. You can edit `config.php` or use occ where possible. Example (editing `config.php` programmatically is error‑prone; prefer manual editing or occ helpers):
```bash
# Example (illustrative only) — prefer safe editing/methods described in Nextcloud docs
podman exec -it nextcloud /bin/sh -c "cd /var/www/html && php -r \"\$config = include 'config/config.php'; \$config['memcache.locking'] = '\\\\OC\\\\Memcache\\\\Redis'; \$config['memcache.local'] = '\\\\OC\\\\Memcache\\\\APCu'; \$config['redis'] = ['host' => 'redis', 'port' => 6379]; file_put_contents('config/config.php', '<?php\\nreturn '.var_export(array_merge(\$config), true).';\\n');\""
```
Safer: log into Nextcloud web UI as admin → Settings → Admin → enable Redis via documented steps, or follow Nextcloud docs for `occ` commands to set memcache and locking.

---

## Run Nextcloud cron
Nextcloud requires a cron job every 5 minutes. Use a systemd timer that runs `podman exec` into the `nextcloud` container.

Create `/etc/systemd/system/nextcloud-cron.service`:
```ini
# /etc/systemd/system/nextcloud-cron.service
[Unit]
Description=Nextcloud cron job (runs php cron.php)
After=network.target

[Service]
Type=oneshot
User=root
# Run as root so podman can run container exec; adjust User if using rootless podman and run as that user.
ExecStart=/usr/bin/podman exec -it nextcloud php -f /var/www/html/cron.php
```

Create `/etc/systemd/system/nextcloud-cron.timer`:
```ini
# /etc/systemd/system/nextcloud-cron.timer
[Unit]
Description=Run Nextcloud cron every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nextcloud-cron.timer
```

---

## Backups & disaster recovery
- Files: backup `/srv/nextcloud/data` (volume `nextcloud_data`) regularly (tar/rsync to external storage).  
- DB: run `mysqldump` from the mariadb container:
```bash
podman exec -it db sh -c 'exec mysqldump --databases nextcloud -u root -p"${MYSQL_ROOT_PASSWORD}"' > /path/to/backups/nextcloud-db-$(date +%F).sql
```
- Backup `cloudflared` credentials JSON and `config.yml` (`/srv/nextcloud/cloudflared`).  
- Backup Nextcloud `config` (`/srv/nextcloud/config`) and `config.php` if customized.  
- For faster restores, consider filesystem snapshots (LVM, BTRFS, ZFS).  
- Regularly test restores.

---

## Cloudflare Tunnel creation (quick steps)
1. Install `cloudflared` on your workstation or run temporarily in a container and authenticate:
```bash
cloudflared tunnel login
```
This opens a browser and creates the initial cert; writes to `~/.cloudflared`.

2. Create a named tunnel:
```bash
cloudflared tunnel create nextcloud
```
Writes a credentials JSON to `~/.cloudflared/<tunnel-uuid>.json`.

3. Route DNS:
```bash
cloudflared tunnel route dns nextcloud nextcloud.example.com
```

4. Copy credentials JSON and the `config.yml` to `/srv/nextcloud/cloudflared` and ensure the container/systemd unit mounts that directory.

---

## Security & production considerations
- Remove automatic admin credentials from `.env` after initial setup, or rotate them immediately.  
- Harden MariaDB with a strong root password and restrict it to internal access only. Consider a managed DB for larger deployments.  
- Always test backups by restoring them.  
- Use Cloudflare "Full (strict)" TLS mode for best security (requires certificate validation on the origin). Options:
  - Use Cloudflare Origin certificate or self-signed cert on the Nextcloud container and configure Cloudflare to use Full (strict).  
  - Alternatively, allow `cloudflared` to connect via HTTP internally and rely on Cloudflare TLS externally (simpler, but the internal link isn't encrypted—acceptable if everything runs on the same host and network).  
- Pin Nextcloud image tags and plan upgrades in maintenance windows.  
- Monitor disk, memory, CPU; Nextcloud with many users requires more resources (PHP workers & DB memory).

---

## SELinux and file permissions
- If SELinux is enforcing, use the `:Z` mount option to relabel bind mounts (as used in `docker-compose.yml`).  
- Ensure Nextcloud files are owned by `www-data:www-data` inside the container. If using host bind mounts, adjust host ownership or run:
```bash
podman exec -it nextcloud chown -R www-data:www-data /var/www/html/data
```

---

## Debugging & troubleshooting (extended)

### Check container/service status & logs
```bash
podman ps -a
podman logs nextcloud
podman logs db
podman logs cloudflared   # if cloudflared is a container
systemctl status cloudflared   # if using systemd unit
```

### Common problems and fixes

1) 502/524/520 via Cloudflare / blank page / proxy error  
- Symptom: Cloudflare returns 502/524, page blank.  
- Causes:
  - Nextcloud container not running or failing healthcheck.  
  - Wrong `ingress` in `cloudflared` config (ensure `service` points to `http://nextcloud:80` or `http://127.0.0.1:8080` depending on networking).  
  - Trusted proxies not configured in Nextcloud.  
- Fix: Ensure Nextcloud is healthy, confirm ingress mapping, add `cloudflared` IP (or `127.0.0.1`) to `trusted_proxies` via `occ`.

2) Login loop or HTTP↔HTTPS redirects  
- Symptom: Login redirects back to login page.  
- Cause: Nextcloud thinks requests are HTTP when Cloudflare serves HTTPS.  
- Fix: Set `overwriteprotocol = 'https'` and `overwrite.cli.url = 'https://nextcloud.example.com'` using `occ`.

3) File uploads failing, thumbnails/previews missing  
- Symptom: Upload fails or previews are not generated.  
- Fixes:
  - Permissions: ensure `/var/www/html/data` is writable by `www-data`.  
  - Missing preview dependencies (ImageMagick, ffmpeg): extend the Nextcloud image (Dockerfile) to install those packages and use the built image.  
  - Increase `php memory_limit` if necessary.

4) DB connection refused or migrations failing  
- Symptom: Nextcloud can't connect to DB at startup.  
- Fixes:
  - Verify DB env vars in `.env`.  
  - Check MariaDB logs.  
  - Use healthchecks/depends_on to mitigate races.  
  - Confirm password values match.

5) Redis / file locking errors  
- Symptom: Concurrency issues, file updates not visible.  
- Fix: Configure Redis as `memcache.locking` and `memcache.local`, ensure Redis reachable (`podman exec -it nextcloud redis-cli -h redis ping`).

6) SELinux denials  
- Symptom: Denied operations in `audit.log`.  
- Fix: Use `:Z` on mounts, run `restorecon` on host paths as needed.

7) cloudflared tunnel issues (credentials/config)  
- Symptom: `cloudflared` logs errors about missing creds/unauthorized.  
- Fix:
  - Ensure tunnel credentials JSON from `cloudflared tunnel create` is mounted and path matches `credentials-file` in `config.yml`.  
  - Check that `cloudflared` container can read the files (ownership/permissions).

8) Cron not running / background jobs failing  
- Symptom: "Background jobs outdated" or slow behaviors.  
- Fix: Ensure systemd timer or host cron runs:
```bash
podman exec nextcloud php -f /var/www/html/cron.php
```
Check timer:
```bash
systemctl status nextcloud-cron.timer
systemctl list-timers
```

9) Upgrading Nextcloud issues  
- Symptom: After image update, `occ upgrade` errors.  
- Fixes:
  - Back up DB & files before upgrade.  
  - Stop or bring down service (`podman-compose down`), pull new image, and run `podman exec nextcloud php occ upgrade` inside the new container.  
  - Ensure required PHP extensions are present in the image.

---

## Operational best practices (recap)
- Use strong secrets; rotate them.  
- Keep backups and test restores.  
- Pin image tags and plan upgrades in maintenance windows.  
- Monitor logs & resources (consider Prometheus exporters if running more services).  
- For horizontal scaling later, consider using an object-store (S3) for file storage to simplify multi‑pod setups.  
- Enable Two Factor Auth for users.

---

## Next steps I can provide
- A Dockerfile that extends the Nextcloud image and installs preview packages (ImageMagick, ffmpeg).  
- Exact `occ` commands to configure Redis and `trusted_proxies` (non-destructive, using `occ` instead of manual `config.php` edits).  
- A migration checklist to move from `podman-compose` to Kubernetes (if you need HA later).

Would you like the Dockerfile for previews and exact `occ` commands next?