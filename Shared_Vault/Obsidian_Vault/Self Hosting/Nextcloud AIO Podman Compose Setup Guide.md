# Nextcloud AIO Podman Compose Setup Guide

This guide will walk you through deploying Nextcloud All-In-One (AIO) using `podman-compose`, including step-by-step installation and configuration.

---

## Prerequisites

- **Linux** machine (Ubuntu, Debian, Fedora, etc.)
- **Root** or a user in the `podman` group
- **Podman** and **podman-compose** installed
- **docker.io** or **podman** container runtime

**Passphrase**  
voltage unstaffed culpable pummel majorette knelt dumpling commodore

### Notes
1. Enable 8080 and 8443 through the FW
```shell
	   sudo firewall-cmd --permanent --add-port=8080/tcp && sudo firewall-cmd --permanent --add-port=8443/tcp && sudo firewall-cmd --reload
```
2. Create volume manually to avoid podman prefix
```shell
podman volume create nextcloud_aio_mastercontainer
```

### 1. Install Podman and Podman-Compose

#### On Fedora
```bash
sudo dnf install podman podman-compose -y
```

#### On Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y podman python3-pip
pip3 install --user podman-compose
# Make sure ~/.local/bin is in your PATH
```

#### Check Versions
```bash
podman --version
podman-compose --version
```

---

### 2. Prepare Folders

Create a directory for your Nextcloud AIO deployment:
```bash
mkdir -p ~/nextcloud-aio
cd ~/nextcloud-aio
```

---

### 3. Create `podman-compose.yml` File

Create a file named `podman-compose.yml` in your `~/nextcloud-aio` directory with the following content:

```yaml
version: "3.7"

services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer
    restart: always
    privileged: true
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
      - /run/user/1000/podman/podman.sock:/var/run/docker.sock:Z  # Adjust UID if needed (run `id -u` to check)
    ports:
      - "8080:8080"    # AIO interface
      - "8443:8443"    # Nextcloud HTTPS
    environment:
      - APACHE_PORT=11000
      - NEXTCLOUD_DATADIR=/mnt/ncdata
      # Optional: add more environment settings as needed
    labels:
      - "com.centurylinklabs.watchtower.enable=false" # Optional

volumes:
  nextcloud_aio_mastercontainer:
    external: true  # Prevents Podman Compose from prefixing the volume name
  # data and backup volumes will be created per-AIO UI by default
```

**Notes:**
- You may adjust ports as necessary.
- The `privileged: true` option is required for AIO, as it manages additional containers.
- The `/var/run/podman/podman.sock:/var/run/docker.sock:Z` path is a compatibility workaround to let AIO's internal logic manage containers via the Docker-compatible API.

---

### 4. Start the Nextcloud AIO Container

```bash
cd ~/nextcloud-aio
podman-compose up -d
```

---

### 5. Access Nextcloud AIO Setup UI

- Open your browser and navigate to:  
  `http://<your-server-ip>:8080`
- Follow the on-screen wizard, including:
  - Downloading the helper script if requested
  - Setting up the admin password
  - Letting the AIO master container deploy the required sub-containers

---

### 6. (Optional) Expose via SSL/Let’s Encrypt

- AIO supports Let’s Encrypt out-of-the-box in the setup wizard.
- Make sure port 80 and 443 are open (`firewall-cmd` or `ufw`).

---

### 7. Data Storage

- Nextcloud AIO creates and manages its own volumes for Nextcloud, database, etc.
- For custom locations, you can map additional host volumes in e.g. `/mnt/ncdata:/mnt/ncdata`.

---

### 8. Stopping & Updating

```bash
# Stop services
podman-compose down

# To update
cd ~/nextcloud-aio
podman-compose pull
podman-compose up -d
```

---

### TROUBLESHOOTING

- If the AIO fails to manage containers, check that `/var/run/podman/podman.sock` is accessible and mapped as `/var/run/docker.sock`.
- Disable SELinux/AppArmor or allow access as needed.
- For persistent data, review the [official Nextcloud AIO documentation](https://github.com/nextcloud/all-in-one).

---
### Copilot said: Yes, you can set up Nextcloud (from

Yes, you can set up Nextcloud (from your AIO Podman setup) behind a Cloudflare Tunnel. This allows you to access it securely over the internet without exposing ports directly on your server. Note that Cloudflare Tunnels use **CNAME records** (not A records) for the subdomain, as they route traffic through Cloudflare's edge network. An A record for the root domain (`rhlabs.org`) can coexist if you have other services, but the tunnel handles the subdomain.

I'll assume Nextcloud is running locally on your server (e.g., port 8443 from the Podman compose). If it's on a different port, adjust accordingly.

### Prerequisites

- Cloudflare account with `rhlabs.org` set up.
- `cloudflared` installed on your server (where Podman/Nextcloud runs).
- Nextcloud AIO running via Podman.

### Step 1: Install and Authenticate Cloudflared

1. **Install cloudflared** (on your Linux server):
    
    bash
    

- ```
    # Download and install
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb
    
    # Or for RPM-based (Fedora):
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
    sudo rpm -i cloudflared-linux-x86_64.rpm
    ```
    
- **Authenticate**:
    
    bash
    

1. ```
    cloudflared tunnel login
    ```
    
    - This opens a browser to log in to Cloudflare. Select your account and authorize.

### Step 2: Create a Tunnel

1. **Create the tunnel** (replace `nextcloud-tunnel` with a name):
    
    bash
    

- ```
    cloudflared tunnel create nextcloud-tunnel
    ```
    
    - This generates a tunnel UUID (e.g., `abc123-def456`). Note it down.
- **Configure the tunnel** to point to your local Nextcloud:
    
    - Create/edit `~/.cloudflared/config.yaml`:
        
        YAML
        

- ```
    tunnel: nextcloud-tunnel  # Your tunnel name
    credentials-file: ~/.cloudflared/tunnel.json  # Auto-generated
    
    ingress:
      - hostname: nextcloud.rhlabs.org  # Your chosen subdomain
        service: http://localhost:8443  # Port where Nextcloud listens (adjust if different)
      - service: http_status:404  # Default for unmatched traffic
    ```
    
- Run the tunnel in the background:
    
    bash
    

1. - ```
        cloudflared tunnel run nextcloud-tunnel &
        ```
        

### Step 3: Set Up DNS in Cloudflare

1. **Add a CNAME record** in Cloudflare DNS:
    
    - Log in to Cloudflare dashboard > **DNS** > **Records** > **Add record**.
    - Type: **CNAME**
    - Name: `nextcloud` (creates `nextcloud.rhlabs.org`)
    - Target: The tunnel UUID (e.g., `abc123-def456.tunnels.cloudflare.com`) — this is auto-generated and shows in your tunnel list (`cloudflared tunnel list`).
    - Proxy status: **Proxied** (orange cloud on) — enables Cloudflare features like SSL.
    - TTL: Auto.
    - Save.
2. **Verify**:
    
    - Run `cloudflared tunnel list` to confirm the tunnel.
    - Test: `curl https://nextcloud.rhlabs.org` (should reach your local Nextcloud).

### Step 4: Secure and Test

- **SSL**: Cloudflare handles HTTPS automatically (use `https://nextcloud.rhlabs.org`).
- **Firewall**: Keep your server firewall closed for external access—Cloudflare Tunnel bypasses it.
- **Restart on boot**: Add `cloudflared tunnel run nextcloud-tunnel` to a systemd service or cron for persistence.
- **Troubleshoot**:
    - If errors: Check logs with `cloudflared tunnel logs nextcloud-tunnel`.
    - DNS propagation: 5-10 minutes.
    - Port conflict: Ensure no other service uses port 8443 locally.

This setup exposes Nextcloud securely. If you need the root domain (`rhlabs.org`) for something else, keep its A record as-is. Let me know if you run into issues!
## References

- [Nextcloud AIO GitHub](https://github.com/nextcloud/all-in-one)
- [Podman Compose Docs](https://github.com/containers/podman-compose)