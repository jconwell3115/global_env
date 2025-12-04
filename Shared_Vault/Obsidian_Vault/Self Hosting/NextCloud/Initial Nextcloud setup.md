---
title: Initial Nextcloud setup
tags:
  - Self-Hosting
  - NextCloud
  - Podman
  - podman-compose
created: 2025-12-03
published:
status: draft
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

