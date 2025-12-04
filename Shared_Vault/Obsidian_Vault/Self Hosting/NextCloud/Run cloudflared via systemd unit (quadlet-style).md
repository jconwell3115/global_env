---
title: Run cloudflared via systemd unit (quadlet-style)
tags:
  - Self-Hosting
  - NextCloud
  - Podman
  - podman-compose
  - Cloudflare
  - Quadlet
created: 2025-12-03
published:
status: draft
---
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
sudo systemctl status cloudflared.service
sudo journalctl -u cloudflared.service -f
sudo journalctl -b | grep -i quadlet -n || true
sudo journalctl -b | grep -i podman -n || true
```


