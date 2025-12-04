---
title: Cloudflare Tunnel creation (quick steps)
tags:
  - Self-Hosting
  - NextCloud
  - Podman
  - podman-compose
created: 2025-12-03
published:
status: draft
---
1. Install `cloudflared` on your workstation:
```bash
sudo curl -L -o /usr/local/bin/cloudflared \
  "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
sudo chmod +x /usr/local/bin/cloudflared
```

2. Authenticate to Cloudflare
```bash
cloudflared tunnel login
```
This opens a browser and creates the initial cert; writes to `~/.cloudflared`.

3. Create a named tunnel:
```bash
cloudflared tunnel create nextcloud
```
Writes a credentials JSON to `~/.cloudflared/<tunnel-uuid>.json`.

4. Route DNS:
```bash
cloudflared tunnel route dns nextcloud nextcloud.example.com
```

5. Create config.yml 
```yaml
# /srv/nextcloud/cloudflared/config.yml
tunnel: d6c14af6-3e9d-4230-898f-b94460442695
credentials-file: /home/nonroot/.cloudflared/d6c14af6-3e9d-4230-898f-b94460442695.json

ingress:
  - hostname: nextcloud.rhlabs.org
    service: http://127.0.0.1:8080
  - service: http_status:404
```

6. Copy credentials JSON, cert.pem and the `config.yml` to `/srv/nextcloud/cloudflared` and ensure the container/systemd unit mounts that directory.

