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

### Create .env — put secrets here (do NOT commit)
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

### Create Nextcloud stack podman-compose
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


---
### Cloudflare Tunnel creation (quick steps)
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

4. Create config.yml 
```yaml
# /srv/nextcloud/cloudflared/config.yml
tunnel: d6c14af6-3e9d-4230-898f-b94460442695
credentials-file: /home/nonroot/.cloudflared/d6c14af6-3e9d-4230-898f-b94460442695.json

ingress:
  - hostname: nextcloud.rhlabs.org
    service: http://127.0.0.1:8080
  - service: http_status:404
```

5. Copy credentials JSON, cert.pem and the `config.yml` to `/srv/nextcloud/cloudflared` and ensure the container/systemd unit mounts that directory.

---
### Run cloudflared via systemd unit (quadlet-style)
Run `cloudflared` as a separately managed Podman container under systemd for independent lifecycle and resilience.

Create systemd unit `/etc/containers/systemd/cloudflared.service`:
```ini
# /etc/containers/systemd/cloudflared.service
[Unit]
Description=cloudflared Tunnel (quadlet)
After=network-online.target
Wants=network-online.target

[Container]
ContainerName=cloudflared-tunnel
Image=docker.io/cloudflare/cloudflared:latest
Network=host

# Use root in the container
User=0

# Use Volumes for mounts (quadlet maps this to podman --volume)
# Replace 'rhlabs' if your home path is different.
Volume=/srv/nextcloud/cloudflared:/home/nonroot/.cloudflared:Z

# Ensure cloudflared finds the credentials and config at /home/nonroot/.cloudflared
Environment=HOME=/home/nonroot

# Run the tunnel by name (tunnel must already be created and the JSON present in the bound dir)
Exec=tunnel run d6c14af6-3e9d-4230-898f-b94460442695

[Service]
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

### Enable the systemd unit

```shell
# Reload Quadlets -> systemd units
sudo systemctl daemon-reload

# Enable at boot and start now
sudo systemctl enable cloudflared.service
sudo systemctl start cloudflared.service

# Check status/logs
systemctl status cloudflared.service
journalctl -u cloudflared.service -f
sudo journalctl -b | grep -i quadlet -n || true
sudo journalctl -b | grep -i podman -n || true
```

---

### Bring up the Nextcloud podman-compose stack
From `/srv/nextcloud`:
```bash
cd /srv/nextcloud && podman-compose up -d
```
Check status:
```bash
podman ps -a
podman logs nextcloud
```

---

### Initial Nextcloud setup
- If the DB env vars are correct, Nextcloud should perform initial setup automatically on first boot. You can visit `http://localhost:8080` locally or the public hostname via Cloudflare once the Tunnel is active.
- After initial install you MUST configure trusted proxies and overwrite settings so Nextcloud knows its external URL and trusts the tunnel.
#### Nextcloud Untrusted Domain Setup
-  Nextcloud blocks connections from domains/IPs that aren't in the trusted domains list. 

1. Add Trusted Domain
```bash
podman exec -u www-data nextcloud_app php occ config:system:set trusted_domains 1 --value='YOUR_DOMAIN_OR_IP'
```
- Replace `YOUR_DOMAIN_OR_IP` with what you're using to access it. 

2. Add Multiple Domains
```bash
podman exec -u www-data nextcloud_app php occ config:system:set trusted_domains 1 --value='localhost:8080'
podman exec -u www-data nextcloud_app php occ config:system:set trusted_domains 2 --value='192.168.0.100:8080'
podman exec -u www-data nextcloud_app php occ config:system:set trusted_domains 3 --value='nextcloud.rhlabs.org'
```

3. Add trusted proxy (cloudflared connects from localhost)
```bash
podman exec -u www-data nextcloud_app php occ config:system:set trusted_proxies 0 --value='127.0.0.1'
```

4. Ensure HTTPS URLs and host
```bash
podman exec -u www-data nextcloud_app php occ config:system:set overwriteprotocol --value='https'
podman exec -u www-data nextcloud_app php occ config:system:set overwritehost --value='nextcloud.rhlabs.org'
podman exec -u www-data nextcloud_app php occ config:system:set overwrite.cli.url --value='https://nextcloud.rhlabs.org'
```

5. Verify Configuration
```bash
podman exec -u www-data nextcloud_app php occ config:system:get trusted_domains
podman exec -u www-data nextcloud_app php occ config:system:get trusted_proxies
podman exec -u www-data nextcloud_app php occ config:system:get overwriteprotocol
podman exec -u www-data nextcloud_app php occ config:system:get overwritehost
podman exec -u www-data nextcloud_app php occ config:system:get overwrite.cli.url
```

After adding the domain, refresh your browser. 

---

### Configure Redis Memcache and Locking

1. Nano isn't installed in the Nextcloud container by default
```bash
# Inside the container (you're already in: root@ae6edd369331:/var/www/html#)
apt-get update && apt-get install -y nano
```

2. Backup config/config.php 
```bash
cp -pr config/config.php config/config.php.bak
```

3. Open the config/cofnig.php file for editing:
```bash
nano config/config.php
```

4. Configure Redis for memcache and file locking:
```php
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'redis',
    'port' => 6379,
    'password' => '',
    'dbindex' => 0,
  )
```

5. Whole file show for clarity
```php
<?php
$CONFIG = array (
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.distributed' => '\\OC\\Memcache\\Redis',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'redis' => 
  array (
    'host' => 'redis',
    'port' => 6379,
    'password' => '',
    'dbindex' => 0,
  ),
  'apps_paths' =>
  array (
    0 =>
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 =>
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
  'upgrade.disable-web' => true,
  'passwordsalt' => 'aV1egjinEjJUdh1E2C+DVYJmtMBZB9',
  'secret' => 'aIJMjMDbeY6wpZMA1dlwShdaLmUogHYz+Tyatz0xJ8P4tML1',
  'trusted_domains' =>
  array (
    0 => 'localhost',
    1 => 'localhost:8080',
    2 => '192.168.0. 100:8080',
    3 => 'nextcloud.rhlabs.org',
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'mysql',
  'version' => '32.0. 2.2',
  'overwrite.cli.url' => 'https://nextcloud.rhlabs.org',
  'dbname' => 'nextcloud',
  'dbhost' => 'db',
  'dbtableprefix' => 'oc_',
  'mysql. utf8mb4' => true,
  'dbuser' => 'ncuser',
  'dbpassword' => 'nextcloudpass',
  'installed' => true,
  'instanceid' => 'ocqvk4uwtw3q',
  'overwritehost' => 'nextcloud.rhlabs.org',
  'overwriteprotocol' => 'https',
  'trusted_proxies' =>
  array (
    0 => '127.0.0.1',
  ),
);
```

---

### Run Nextcloud cron
Nextcloud requires a cron job every 5 minutes to run background jobs. Use a systemd timer that runs `podman exec` into the `nextcloud` container.

1. Create `/etc/systemd/system/nextcloud-cron.service`:
```ini
# /etc/systemd/system/nextcloud-cron.service
[Unit]
Description=Nextcloud cron job (runs php cron.php)
After=network.target

[Service]
Type=oneshot
User=root
# Run as root so podman can run container exec; adjust User if using rootless podman and run as that user.
ExecStart=/usr/bin/podman exec -u www-data nextcloud_app php -f /var/www/html/cron.php
```

2. Create `/etc/systemd/system/nextcloud-cron.timer`:
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

3. Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nextcloud-cron.timer
```

4. Check Timer Status
```bash 
# Check if the timer is active and when it will run next
sudo systemctl status nextcloud-cron.timer

# List all timers and find yours
# Shows time since last run and time until next run
sudo systemctl list-timers | grep nextcloud

# Show detailed timer information
systemctl show nextcloud-cron. timer
```

5. Check Service Execution
```bash
# Check the last execution of the service
sudo systemctl status nextcloud-cron.service

# View recent logs from the service
sudo journalctl -u nextcloud-cron.service -n 50

# Follow logs in real-time (wait for next execution)
sudo journalctl -u nextcloud-cron.service -f
```

6. Check Within Nextcloud

```bash
# Check background job mode (should show "cron")
podman exec -u www-data nextcloud_app php /var/www/html/occ config:app:get core backgroundjobs_mode

# Check last cron execution time
podman exec -u www-data nextcloud_app php /var/www/html/occ config:app:get core lastcron

# View background job status
podman exec -u www-data nextcloud_app php /var/www/html/occ background:job:list
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