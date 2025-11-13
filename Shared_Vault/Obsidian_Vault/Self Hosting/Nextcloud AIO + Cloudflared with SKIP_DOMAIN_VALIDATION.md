---
tags:
  - Self-Hosting
  - Cloudflare
  - Podman
  - podman-compose
---
# Nextcloud AIO + Cloudflared with SKIP_DOMAIN_VALIDATION

This guide demonstrates how to run Nextcloud AIO and cloudflared using podman-compose, routing a Cloudflare-managed domain to your private Nextcloud instance via a secure tunnel. SKIP_DOMAIN_VALIDATION is included so you can set up your instance without requiring a public DNS name to resolve directly to your server during initial configuration.

---

## Prerequisites

- Cloudflare account and domain, added and verified
- Podman & podman-compose installed
- Host with internet access
- Access to required ports (e.g., 8080 for Nextcloud default HTTP inside container)

---

## 1. Cloudflare Domain & Tunnel Preparation

1. Sign up, add your domain in [Cloudflare Dashboard](https://dashboard.cloudflare.com), change registrar’s nameservers if needed, and wait for verification.
    
2. Install `cloudflared` binary locally or plan to use the `cloudflare/cloudflared` container for all authentication and tunnel creation steps.
    

---

## 2. Install Podman and Podman-Compose

```bash
`sudo dnf install -y podman podman-compose`
```
_Or with pip if unavailable:_

```bash
`sudo dnf install -y python3-pip sudo pip3 install podman-compose`
```
---

## 3. Directory Structure

```bash
`mkdir -p ~/nextcloud-cloudflared/cloudflared cd ~/nextcloud-cloudflared`
```
---

## 4. Authenticate Cloudflared and Create Tunnel

```bash
# Login to Cloudflare and authorize the session:
podman run --rm -it \
  -v "$(pwd)/cloudflared:/home/user/.cloudflared:z" \
  -e HOME=/home/user \
  cloudflare/cloudflared:latest \
  tunnel login

# Create your tunnel (replace my-tunnel with your tunnel name):
podman run --rm -it \
  -v "$(pwd)/cloudflared:/home/user/.cloudflared:z" \
  -e HOME=/home/user \
  cloudflare/cloudflared:latest \
  tunnel create my-tunnel

```

_Record the tunnel ID and credentials file name for later._

---

## 5. Create and Edit Configuration Files

## `podman-compose.yml`

```yaml
version: "3.8"
services:
  nextcloud-aio:
    image: nextcloud/all-in-one:latest
    container_name: nextcloud-aio
    restart: unless-stopped
    ports:
      - "8080:8080" # Expose if you want direct local access
    environment:
      - TZ=UTC
      - SKIP_DOMAIN_VALIDATION=true   # <-- THIS IS CRITICAL
    networks:
      - ncnet
    volumes:
      - nextcloud_aio_data:/var/lib/nextcloud
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 1m
      timeout: 10s
      retries: 3

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run --config /etc/cloudflared/config.yml
    networks:
      - ncnet
    depends_on:
      - nextcloud-aio
    volumes:
      - ./cloudflared:/etc/cloudflared:Z

networks:
  ncnet:
    driver: bridge

volumes:
  nextcloud_aio_data:

```

## `cloudflared/config.yml`

In `./cloudflared/config.yml`:

```yaml
tunnel: <TUNNEL-UUID>
credentials-file: /etc/cloudflared/<TUNNEL-UUID>.json

ingress:
  - hostname: nextcloud.example.com
    service: http://nextcloud-aio:8080
  - service: http_status:404

no-autoupdate: true
```

_Replace `<TUNNEL-UUID>` and `nextcloud.example.com` with your values._

---

## 6. Permissions

```bash
chmod 640 cloudflared/<TUNNEL-UUID>.json
chmod 640 cloudflared/cert.pem
```

---

## 7. Create Cloudflare DNS Routing

You can automate via cloudflared:

```bash
podman run --rm -it \
  -v "$(pwd)/cloudflared:/home/user/.cloudflared:z" \
  -e HOME=/home/user \
  cloudflare/cloudflared:latest \
  tunnel route dns my-tunnel nextcloud.example.com
```

Or set manual DNS record (CNAME) in Cloudflare dashboard for your subdomain.

---

## 8. Start the Stack

```bash
`podman-compose up -d`
```
Verify service health:

```bash
podman ps
podman logs cloudflared
podman exec -it cloudflared curl -v http://nextcloud-aio:8080/`
```
---

## 9. Access Nextcloud via Your Cloudflare Domain

Once DNS has propagated, open:

```text
`https://nextcloud.example.com`
```
---

## 10. Manage Stack with systemd (Optional)

Create `/etc/systemd/system/nextcloud-podman-compose.service`:

```text
[Unit]
Description=Nextcloud AIO + cloudflared (podman-compose)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
WorkingDirectory=/home/youruser/nextcloud-cloudflared
ExecStart=/usr/bin/podman-compose up -d
ExecStop=/usr/bin/podman-compose down
RemainAfterExit=yes
User=youruser
Group=youruser

[Install]
WantedBy=multi-user.target
```

Enable and start on boot:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nextcloud-podman-compose.service
```
---

## Key Notes

- The environment variable `SKIP_DOMAIN_VALIDATION=true` in the Nextcloud AIO service allows easy setup without needing a live DNS record during initialization.
- All configuration for tunnel and credentials remains in your project folder for ease of management and backup.
- Use Cloudflare dashboard and Access/Gateway features for additional security as needed.
- Make sure both containers use the same bridged network (`ncnet` in this example).


## Automation Script
```bash
#!/bin/bash
set -e

# ---- CONFIGURE THESE VALUES ----
PROJECT_ROOT="$HOME/nextcloud-cloudflared"
CFD_DIR="$PROJECT_ROOT/cloudflared"
TUNNEL_NAME="my-tunnel"                   # Your Cloudflare tunnel name
NEXTCLOUD_DOMAIN="nextcloud.example.com"  # Your public domain (Cloudflare)
TIMEZONE="UTC"
# --------------------------------

# 1. Install dependencies (Fedora)
sudo dnf install -y podman podman-compose python3-pip || sudo pip3 install podman-compose

# 2. Prepare directories
mkdir -p "$CFD_DIR"
cd "$PROJECT_ROOT"

# 3. Authenticate Cloudflared
podman run --rm -it -v "$CFD_DIR:/home/user/.cloudflared:z" -e HOME=/home/user cloudflare/cloudflared:latest tunnel login

# 4. Create Tunnel
podman run --rm -it -v "$CFD_DIR:/home/user/.cloudflared:z" -e HOME=/home/user cloudflare/cloudflared:latest tunnel create "$TUNNEL_NAME"

# 5. Derive TUNNEL_UUID from .json file
TUNNEL_UUID=$(ls $CFD_DIR/*.json | head -n1 | xargs basename | cut -d. -f1)

# 6. Generate podman-compose.yml
cat > "$PROJECT_ROOT/podman-compose.yml" <<EOF
version: "3.8"
services:
  nextcloud-aio:
    image: nextcloud/all-in-one:latest
    container_name: nextcloud-aio
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - TZ=${TIMEZONE}
      - SKIP_DOMAIN_VALIDATION=true
    networks:
      - ncnet
    volumes:
      - nextcloud_aio_data:/var/lib/nextcloud
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 1m
      timeout: 10s
      retries: 3

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run --config /etc/cloudflared/config.yml
    networks:
      - ncnet
    depends_on:
      - nextcloud-aio
    volumes:
      - ./cloudflared:/etc/cloudflared:Z

networks:
  ncnet:
    driver: bridge

volumes:
  nextcloud_aio_data:
EOF

# 7. Generate cloudflared config.yml
cat > "$CFD_DIR/config.yml" <<EOF
tunnel: ${TUNNEL_UUID}
credentials-file: /etc/cloudflared/${TUNNEL_UUID}.json

ingress:
  - hostname: ${NEXTCLOUD_DOMAIN}
    service: http://nextcloud-aio:8080
  - service: http_status:404

no-autoupdate: true
EOF

# 8. File permissions
chmod 700 "$CFD_DIR"
chmod 640 "$CFD_DIR"/*.json
chmod 640 "$CFD_DIR"/cert.pem 2>/dev/null || true

# 9. Create Cloudflare DNS route
podman run --rm -it -v "$CFD_DIR:/home/user/.cloudflared:z" -e HOME=/home/user cloudflare/cloudflared:latest tunnel route dns "$TUNNEL_NAME" "$NEXTCLOUD_DOMAIN"

# 10. Start the stack
cd "$PROJECT_ROOT"
podman-compose up -d

echo "✅ Nextcloud AIO and cloudflared setup complete."
echo "Check logs with: podman ps && podman logs cloudflared"
echo "Once DNS propagates, access: https://${NEXTCLOUD_DOMAIN}"
```


## cloudflare-ddns
## `podman-compose.yml`

```yaml
version: "3.8"
services:
  cloudflare-ddns:
    image: timothyjmiller/cloudflare-ddns:latest
    container_name: cloudflare-ddns
    restart: unless-stopped
    volumes:
      - ./config.json:/config.json:ro
    environment:
      - INTERVAL=300 # Interval in seconds between updates (optional)
    network_mode: host

```

---

## `config.json`

```json
{
  "api": {
    "token": "YOUR_CLOUDFLARE_API_TOKEN"
  },
  "zones": [
    {
      "zone": "example.com",
      "name": "subdomain",
      "proxied": false
    }
  ]
}

```

- Replace `YOUR_CLOUDFLARE_API_TOKEN` with a Cloudflare API token that has DNS edit permissions.
- Set `"zone"` to your Cloudflare domain (e.g., `example.com`).
- Set `"name"` to your desired subdomain.
- Set `"proxied"` to `true` to enable CF proxy, or `false` for direct DNS mode.

---

**To start:**  
Place both files in a directory (e.g., `~/cloudflare-ddns`), edit `config.json` as needed, then run:

```bash
`cd ~/cloudflare-ddns podman-compose up -d`
```
This setup will keep your DNS record current with your public IP automatically.