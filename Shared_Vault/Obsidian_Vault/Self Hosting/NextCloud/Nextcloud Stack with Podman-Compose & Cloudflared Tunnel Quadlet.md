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

## Setup Workflow
1.  [[Pre-Flight Checks and Setup ]]
2.  [[Create Nextcloud stack podman-compose]]
3.  [[Cloudflare Tunnel creation (quick steps)]]
4. [[ Run cloudflared via systemd unit (quadlet-style)]]
5.  [[Initial Nextcloud setup]]
6.  [[Configure Redis Memcache and Locking]]
7.  [[Run Nextcloud cron]]
8.  [[Enable Nextcloud to Restart After Reboot]]

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
- If SELinux is enforcing, use the `:Z` mount option to relabel bind mounts (as used in podman-compose.yml`).  
- Ensure Nextcloud files are owned by `www-data:www-data` inside the container. If using host bind mounts, adjust host ownership or run:
```bash
podman exec -it nextcloud_app chown -R www-data:www-data /var/www/html/data
```

---

## Debugging & troubleshooting (extended)

### Check container/service status & logs
```bash
podman ps -a
podman logs nextcloud_app
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
