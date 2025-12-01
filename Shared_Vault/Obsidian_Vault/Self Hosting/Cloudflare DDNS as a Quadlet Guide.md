---
title: Cloudflare DDNS as a Quadlet Guide
tags:
  - Self-Hosting
  - Cloudflare
  - Quadlet
  - Podman
created: 2025-11-25
published:
status: draft
---
# Complete How-To: Running timothymiller/cloudflare-ddns as a Podman Quadlet

This comprehensive guide will walk you through setting up qdm12/cloudflare-ddns as a systemd-managed Podman container using Quadlet, following best practices for security, reliability, and maintainability.

## Overview

**What you'll build:**
- A systemd-managed Podman container running qdm12/cloudflare-ddns
- Secure API token handling via Podman secrets
- Automatic restart on failure with proper health checks
- Full logging to journald
- Clean boot-time startup with network dependency handling

**Prerequisites:**
- Podman installed (version 4.4+ for full Quadlet support)
- systemd-based Linux distribution
- Cloudflare account with a zone/domain
- Root or sudo access

---

## Step 1: Create Cloudflare API Token

- [x] Generate a scoped API token (recommended over global API key)

1. Log in to Cloudflare Dashboard
2. Go to **My Profile** → **API Tokens** → **Create Token**
3.  Use the **Edit zone DNS** template or create custom token with:
   - **Permissions:** Zone → DNS → Edit
   - **Zone Resources:** Include → Specific zone → `yourdomain.com`
4. Create the token and **copy it immediately** (you won't see it again)

**Security note:** Never use your Global API Key — always use scoped tokens with minimal permissions.

---

## Step 2: Prepare Host Directories and Secrets

### Create directory structure

```bash
# Create config directory
mkdir -p /srv/cloudflare-ddns
chmod 700 /srv/cloudflare-ddns
```

### Store the API token securely

```bash
# Create token file (replace YOUR_TOKEN_HERE with your actual token)
printf '%s' "YOUR_TOKEN_HERE" | tee /srv/cloudflare-ddns/cf_token >/dev/null
chmod 600 /srv/cloudflare-ddns/cf_token
```

### Create a Podman secret

```bash
# Import the token as a Podman secret
podman secret create cloudflare_ddns_token /srv/cloudflare-ddns/cf_token

# Verify the secret was created
podman secret ls
```

**Why use secrets? ** Podman secrets are mounted as read-only tmpfs inside containers and are never written to disk in the container filesystem, reducing exposure. 

---

## Step 3: Create the config.json
> Remove the comments that start with //, JSON can't parse comments.  They are here for informational purposes

/srv/cloudflare-ddns/config.json

```json
{
  "cloudflare": [
    {
      "authentication": {
        "api_token": "ZpgjtWEcPbGy4wLuD-5f-PYGhmEStz_SaEnZR9vA"
      },
      "zone_id": "b5c8331a20c341189d455d63e6c809c6",  
      "subdomains": [
        {
          "name": "@",  // Subdomain to update (or "@" for root)
          "proxied": true,  // Set true to enable Cloudflare proxying
          "ttl": 300  // Time to live in seconds
        },
        {
          "name": "nextcloud",  // Subdomain to update (or "@" for root)
          "proxied": true,  // Set true to enable Cloudflare proxying
          "ttl": 300  // Time to live in seconds
        },
        {
          "name": "vpn",  // Subdomain to update (or "@" for root)
          "proxied": false,  // Set true to enable Cloudflare proxying
          "ttl": 300  // Time to live in seconds
        }
      ]
    }
  ],
  "a": true,  // Update A records (IPv4)
  "aaaa": true,  // Update AAAA records (IPv6)
  "purgeUnknownRecords": false,  // Optional: Remove unknown records
  "ttl": 300  // Default TTL
}
```

### Create a Podman secret

```bash
# Import the token as a Podman secret
podman secret create cloudflare_ddns_token /srv/cloudflare-ddns/config.json

# Verify the secret was created
podman secret ls
```

**Why use secrets? ** Podman secrets are mounted as read-only tmpfs inside containers and are never written to disk in the container filesystem, reducing exposure. 

Delete the config.json for security after the secret is confirmed created.

---

## Step 4: Create the Quadlet Container Unit

### Create the systemd container unit file

```bash
# ~/.config/containers/systemd/cloudflare-ddns.container

[Unit]
Description=Cloudflare DDNS updater
Documentation=https://github.com/timothymiller/cloudflare-ddns
Wants=network-online.target
After=network-online.target

[Container]
# Image
Image=docker.io/timothyjmiller/cloudflare-ddns:latest
Pull=newer

# Container name
ContainerName=cloudflare-ddns

# Environment (adjust PUID/PGID/UMASK as you like; leave root if you want fully rootful)
# If you prefer running as root inside the container, omit PUID/PGID
Environment=CF_DDNS_API_TOKEN=/run/secrets/cloudflare-api-token
Environment=PUID=1000
Environment=PGID=1000
Environment=TZ=America/New_York
Network=host

# Persist the container configuration and PKI
Volume=/srv/cloudflare-ddns/config.json:/config.json:ro

# Auto-update (requires podman-auto-update. timer)
AutoUpdate=registry

# Security options
ReadOnly=true
NoNewPrivileges=true
SecurityLabelDisable=true

# Resource limits (optional but recommended)
Memory=128M

# Logging
LogDriver=journald

[Service]
# Allow systemd to manage the service
TimeoutStartSec=60
Restart=on-failure
RestartSec=10s
RestartMaxAttempts=5

[Install]
WantedBy=multi-user.target default.target
```

**Important path note:** Quadlet units should be placed in:
- System-wide: `/etc/containers/systemd/` (recommended for root services)
- User-specific: `~/.config/containers/systemd/`

---

## Step 5: Enable and Start the Service

### Reload systemd and start

```bash
# Reload systemd to discover the new Quadlet unit
systemctl --user daemon-reload

# Start the service now
systemctl --user start cloudflare-ddns.service

# Check status
systemctl --user status cloudflare-ddns.service
```

**Note:** Quadlet automatically converts `. container` files to systemd service units. The service will be named `cloudflare-ddns. service`. 

---

## Step 6: Verify Operation

### Check service status

```bash
# Full status
sudo systemctl status cloudflare-ddns.service

# Should show "active (running)"
```

### View logs

```bash
# Follow logs in real-time
journalctl --user -u cloudflare-ddns.service -f

# View recent logs
journalctl --user -u cloudflare-ddns.service -n 50

# Logs since last boot
journalctl --user -u cloudflare-ddns.service  -b

# Quadlet specific logs
journalctl --user -b | grep -i quadlet

# Ultra detailed logs
journalctl --user -xeu cloudflare-ddns.service
```

### Check container status

```bash
# List running containers
sudo podman ps | grep cloudflare-ddns

# Inspect the container
sudo podman inspect cloudflare-ddns

# Check health (if healthcheck is configured)
sudo podman healthcheck run cloudflare-ddns
```

### Verify DNS update

```bash
# Query your DNS record
dig +short home.example.com

# Or use nslookup
nslookup home.example.com

# Check in Cloudflare Dashboard
# Go to DNS → Records and verify the A/AAAA record shows your current IP
```

---

## Step 7: Enable Auto-Updates (Optional but Recommended)

### Enable Podman auto-update timer

```bash
# Enable the auto-update timer (checks for new images daily)
systemctl --user enable --now podman-auto-update.timer

# Check timer status
systemctl --user status podman-auto-update.timer

# Manually trigger an update check
podman auto-update

# View auto-update logs
journalctl -u podman-auto-update.service
```

The `AutoUpdate=registry` line in the Quadlet unit tells Podman to pull newer images and restart the container when updates are available.

---

## Troubleshooting Guide

### Problem: Service fails to start

**Symptoms:**
```
● cloudflare-ddns.service - Cloudflare DDNS updater
     Loaded: loaded
     Active: failed (Result: exit-code)
```

**Solutions:**

1. **Check logs for error messages:**
   ```bash
   sudo journalctl -u cloudflare-ddns.service -n 100 --no-pager
   ```

2. **Common causes:**
   - **Invalid API token:** Verify token in `/etc/cloudflare-ddns/cf_token`
   - **Wrong zone/subdomain:** Check `ZONE` and `SUBDOMAIN` match your Cloudflare setup
   - **Network not ready:** Ensure `network-online.target` is enabled:
     ```bash
     sudo systemctl enable systemd-networkd-wait-online.service
     ```
   - **Secret not found:** Verify secret exists:
     ```bash
     sudo podman secret ls
     ```

3. **Test the container manually:**
   ```bash
   # Run interactively to see errors
   sudo podman run --rm -it \
     --secret cloudflare_ddns_token,type=env,target=CF_API_TOKEN \
     -e ZONE=example.com \
     -e SUBDOMAIN=home \
     -e LOG_LEVEL=debug \
     docker.io/qmcgaw/cloudflare-ddns:latest
   ```

---

### Problem: DNS record not updating

**Symptoms:**
- Service running but DNS record shows old IP

**Solutions:**

1. **Increase log verbosity:**
   ```bash
   # Edit the unit file
   nano ~/.config/containers/systemd/cloudflare-ddns.container
   # Change: Environment=LOG_LEVEL=debug
   
   systemctl --user daemon-reload
   systemctl --user restart cloudflare-ddns.service
   journalctl --user -u cloudflare-ddns.service -f
   ```

2. **Verify API token permissions:**
   - Log in to Cloudflare
   - Check token has Zone → DNS → Edit for the correct zone
   - Regenerate token if needed and update secret:
     ```bash
     printf '%s' "NEW_TOKEN" | tee /srv/cloudflare-ddns/cf_token >/dev/null
     podman secret rm cloudflare_ddns_token
     podman secret create cloudflare_ddns_token /srv/cloudflare-ddns/cf_token
     systemctl --user restart cloudflare-ddns.service
     ```

3. **Check IP detection:**
   - The container needs to detect your public IP
   - If behind NAT/firewall, ensure outbound HTTP/HTTPS is allowed
   - Check logs for IP detection errors

4. **Verify Cloudflare API access:**
   ```bash
   # Test API manually (replace TOKEN and ZONE_ID)
   curl -X GET "https://api.cloudflare. com/client/v4/zones/ZONE_ID/dns_records" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Content-Type: application/json"
   ```

---

### Problem: Container keeps restarting

**Symptoms:**
```
podman ps -a
# Shows container repeatedly restarting
```

**Solutions:**

1. **Check restart count and reason:**
   ```bash
   podman inspect cloudflare-ddns | grep -A 5 "State"
   journalctl --user -u cloudflare-ddns.service | grep -i error
   ```

2. **Common causes:**
   - **Missing required env vars:** Ensure ZONE and SUBDOMAIN are set
   - **Invalid configuration:** Check all environment variables for typos
   - **Health check failing:** If using HealthCmd, verify the endpoint works

3. **Disable restart temporarily for debugging:**
   ```bash
   # Edit unit file, change Restart=on-failure to Restart=no
   systemctl --user daemon-reload
   systemctl --user restart cloudflare-ddns.service
   # Check logs without auto-restart interference
   ```

---

### Problem: Service not starting at boot

**Symptoms:**
- Service works when started manually but doesn't start after reboot

**Solutions:**

1. **Verify service is enabled:**
   ```bash
   systemctl --user is-enabled cloudflare-ddns.service
   # Should show "enabled"
   ```

2. **Enable if not enabled:**
```bash
systemctl --user enable cloudflare-ddns.service
```

3. **Check dependencies:**
   ```bash
   # Ensure network-online.target is reached
   systemctl --user status network-online.target
   
   # Enable network wait service if needed
   systemctl --user enable systemd-networkd-wait-online.service
   ```

4. **Check boot logs:**
   ```bash
   journalctl --user -u cloudflare-ddns.service -b
   ```

---

### Problem: Can't view logs or service not found

**Symptoms:**
```
Failed to start cloudflare-ddns.service: Unit cloudflare-ddns.service not found. 
```

**Solutions:**

1.  **Verify Quadlet file location:**
   ```bash
   ls -la /etc/containers/systemd/cloudflare-ddns.container
   ```

2. **Reload systemd daemon:**
   ```bash
   systemctl --user daemon-reload
   ```

3. **Check for syntax errors:**
   ```bash
   # Quadlet should generate the unit; check for errors
   /usr/libexec/podman/quadlet --dryrun
   # Or on some systems:
   /usr/lib/podman/quadlet --dryrun
   ```

4.  **Verify Podman Quadlet support:**
   ```bash
   podman --version
   # Should be 4.4. 0 or higher
   
   # Check if quadlet generator exists
   ls -la /usr/lib/systemd/system-generators/*quadlet*
   ```

---

## Security Best Practices Checklist

- ✅ Use API tokens (not Global API Key)
- ✅ Scope token to minimum permissions (Zone DNS Edit only)
- ✅ Store token in Podman secret (not plaintext in unit file)
- ✅ Set file permissions to 600 on token file
- ✅ Use `ReadOnly=true` for container filesystem
- ✅ Use `NoNewPrivileges=true` to prevent privilege escalation
- ✅ Set memory limits to prevent resource exhaustion
- ✅ Use `LogDriver=journald` for centralized logging
- ✅ Enable auto-updates to get security patches
- ✅ Run as non-root user in container (qdm12 image should do this by default)

---

## Maintenance Tasks

### Update the image manually

```bash
# Pull latest image
podman pull docker.io/qmcgaw/cloudflare-ddns:latest

# Restart service (Quadlet will use new image)
systemctl --user restart cloudflare-ddns.service
```

### Rotate API token

```bash
# Create new token in Cloudflare Dashboard
# Update secret
printf '%s' "NEW_TOKEN" | tee /srv/cloudflare-ddns/cf_token >/dev/null
podman secret rm cloudflare_ddns_token
podman secret create cloudflare_ddns_token /srv/cloudflare-ddns/cf_token

# Restart service
systemctl --user restart cloudflare-ddns.service
```

### Backup configuration

```bash
# Backup the Quadlet unit and token
sudo tar czf cloudflare-ddns-backup.tar.gz \
  ~/.config/containers/systemd/cloudflare-ddns.container \
  /srv/cloudflare-ddns/
```

### Remove/uninstall

```bash
# Stop and disable service
systemctl --user stop cloudflare-ddns.service
systemctl --user disable cloudflare-ddns.service

# Remove Quadlet unit
rm ~/.config/containers/systemd/cloudflare-ddns.container

# Remove secret
podman secret rm cloudflare_ddns_token

# Remove config directory
rm -rf /srv/cloudflare-ddns/

# Remove container and image
podman rm -f cloudflare-ddns
podman rmi docker.io/qmcgaw/cloudflare-ddns:latest

# Reload systemd
systemctl --user daemon-reload
```

---

## Quick Reference Commands

```bash
# View status
systemctl --user status cloudflare-ddns.service

# View logs (live)
journalctl --user -u cloudflare-ddns.service -f

# Restart service
systemctl --user restart cloudflare-ddns.service

# Stop service
systemctl --user stop cloudflare-ddns.service

# Start service
systemctl --user start cloudflare-ddns.service

# Disable service (don't start at boot)
systemctl --user disable cloudflare-ddns.service

# Enable service (start at boot)
systemctl --user enable cloudflare-ddns.service

# Check container stats
podman stats cloudflare-ddns

# Execute command in running container
podman exec -it cloudflare-ddns /bin/sh

# View environment variables
podman inspect cloudflare-ddns | grep -A 20 "Env"

# Test auto-update
podman auto-update --dry-run
```

---

## Summary

You now have a production-ready Cloudflare DDNS service running as a systemd-managed Podman container with:

- ✅ Automatic startup at boot with proper network dependencies
- ✅ Secure token handling via Podman secrets
- ✅ Health checks and automatic restart on failure
- ✅ Centralized logging to journald
- ✅ Automatic image updates
- ✅ Resource limits and security hardening
- ✅ Easy maintenance and troubleshooting

The service will now keep your DNS records updated automatically, restart on failures, survive reboots, and update itself when new versions are available. 

**Next steps:**
- Monitor the service for the first 24-48 hours to ensure stable operation
- Set up alerting (optional) if the service fails
- Consider adding this configuration to your infrastructure-as-code or dotfiles repo

If you encounter any issues not covered in the troubleshooting section, check the qdm12/cloudflare-ddns GitHub repository for updated documentation and known issues. 
