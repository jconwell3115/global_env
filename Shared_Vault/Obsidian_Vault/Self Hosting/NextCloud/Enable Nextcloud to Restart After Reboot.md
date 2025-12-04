---
title: Enable Nextcloud to Restart After Reboot
tags:
  - Self-Hosting
  - NextCloud
  - Podman
  - podman-compose
  - systemd
created: 2025-12-03
published:
status: draft
---
> Quadlets are not recommended for Nextcloud
1. Create the Unit
```bash
cd /srv/nextcloud  # Ensure you're in the compose directory
sudo podman-compose systemd -a create-unit
```

2. Register the service
```bash
# From the project directory
podman-compose systemd -a register
```

3. Use systemd commands like enable, start, stop, status, cat all without `sudo` like this:
```
systemctl --user enable --now 'podman-compose@nextcloud'
systemctl --user status 'podman-compose@nextcloud'
journalctl --user -xeu 'podman-compose@nextcloud'
```

4. Use podman commands like:
```bash
podman pod ps
podman pod stats 'pod_nextcloud'
podman pod logs --tail=10 -f 'pod_nextcloud'
```



