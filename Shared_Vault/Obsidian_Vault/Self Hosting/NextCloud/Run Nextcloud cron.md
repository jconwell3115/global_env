---
title: Run Nextcloud cron
tags:
  - Self-Hosting
  - NextCloud
  - Podman
  - podman-compose
created: 2025-12-03
published:
status: draft
---
Nextcloud requires a cron job every 5 minutes to run background jobs. Use a systemd timer that runs `podman exec` into the `nextcloud` container.

1. Create directories
```bash
mkdir -p ~/bin ~/.config/systemd/user
```

2. Create shell script to apply best practices for safe running `~/bin/nextcloud-cron-run`
```bash
# ~/bin/nextcloud-cron-run
#!/usr/bin/env bash
set -euo pipefail
XDG_RUNTIME_DIR="/run/user/$(id -u)"
CONTAINER="nextcloud_app"
PODMAN="/usr/bin/podman"
TIMEOUT="/usr/bin/timeout"
if XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" "$PODMAN" exec -u www-data "$CONTAINER" pgrep -f cron.php >/dev/null 2>&1; then
  echo "nextcloud cron already running, exiting"
  exit 0
fi
XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" "$TIMEOUT" 90s "$PODMAN" exec -u www-data "$CONTAINER" php -f /var/www/html/cron.php
```

3. Make the shell script executable
```bash
chmod +x ~/bin/nextcloud-cron-run
```

4. Create service `~/.config/systemd/user/nextcloud-cron.service:
```ini
# ~/.config/systemd/user/nextcloud-cron.service
[Unit]
Description=Nextcloud cron job (runs php cron.php)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c '! /usr/bin/podman exec nextcloud_app pgrep -f "/var/www/html/cron.php" >/dev/null 2>&1 && /usr/bin/podman exec -u www-data nextcloud_app php -d memory_limit=768M -f /var/www/html/cron.php || exit 0'
StandardOutput=journal
StandardError=journal
Restart=no

[Install]
WantedBy=default.target
```

5. Create timer
```ini
# ~/.config/systemd/user/nextcloud-cron.timer
[Unit]
Description=Run Nextcloud cron every 5 minutes

[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
Persistent=true

[Install]
WantedBy=timers.target
```

6. Enable user linger so the user systemd instance runs even when not logged in
```bash
sudo loginctl enable-linger rhlabs
```

7. reload user daemon, enable and start timer
```bash
# reload user daemon, enable and start timer
systemctl --user daemon-reload
systemctl --user enable --now nextcloud-cron.timer
```

8. Check Timer Status
```bash 
# Check if the timer is active and when it will run next
systemctl --user status nextcloud-cron.timer

# List all timers and find yours
# Shows time since last run and time until next run
systemctl --user list-timers --all | grep nextcloud-cron

# Show detailed timer information
systemctl --user show nextcloud-cron.timer
```

9. Check Service Execution
```bash
# Check the last execution of the service
systemctl --user status nextcloud-cron.service

# View recent logs from the service
journalctl --user -u nextcloud-cron.service -n 50 --no-pager

# Follow logs in real-time (wait for next execution)
journalctl --user -u nextcloud-cron.service -f
```

10. Check Within Nextcloud
```bash
# Check background job mode (should show "cron")
podman exec -u www-data nextcloud_app php /var/www/html/occ config:app:get core backgroundjobs_mode

# Check last cron execution time
podman exec -u www-data nextcloud_app php /var/www/html/occ config:app:get core lastcron

# View background job status
podman exec -u www-data nextcloud_app php /var/www/html/occ background-job:list

# View Top in the container
podman top nextcloud_app
```
