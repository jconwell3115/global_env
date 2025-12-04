---
title: Pre-Flight Checks and Setup
tags:
  - Self-Hosting
  - NextCloud
  - Podman
  - podman-compose
created: 2025-12-03
published:
status: draft
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


