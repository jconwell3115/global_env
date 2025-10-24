Print those instructions again with privileged mode and sudo

Here is a **complete, updated set of instructions** for setting up **OpenVPN Access Server** rootfully under **Podman Compose** with `privileged` mode enabled — this ensures full VPN functionality, including access to `/dev/net/tun` for creating tunnel interfaces [8][2][6].

***

## 1. System preparation

Install Podman and Podman Compose if you haven’t already:

```bash
sudo dnf update -y
sudo dnf install podman podman-docker python3-pip -y
sudo pip3 install podman-compose
```

Verify installation:

```bash
podman --version
podman-compose --version
```

***

## 2. Create project folder

Set up the deployment directory:

```bash
sudo mkdir -p /opt/openvpn-as
cd /opt/openvpn-as
```

***

## 3. Create the Compose file

Create a file named `podman-compose.yml`:

```bash
sudo nano podman-compose.yml
```

Paste this content:

```yaml
version: "3.8"

services:
  openvpn-as:
    image: openvpn/openvpn-as:latest
    container_name: openvpn-as
    restart: unless-stopped
    privileged: true
    ports:
      - "943:943"          # Admin & Client Web UI
      - "9443:9443"        # TCP VPN connections
      - "1194:1194/udp"    # UDP VPN connections
    environment:
      - PGID=1000
      - PUID=1000
      - TZ=America/New_York
      - INTERFACE=eth0
    volumes:
      - ./config:/openvpn
```

Here:
- `privileged: true` gives the container full device and network access.
- VPN traffic ports (TCP 9443, UDP 1194) are opened.
- Persistent configuration is saved in `./config`.

***

## 4. Start the container rootfully

Run using **sudo** so Podman has full host access:

```bash
sudo podman-compose up -d
```

Check container status:

```bash
sudo podman ps
```

You should see `openvpn-as` running with required ports mapped.

***

## 5. Access the Web Interfaces

After startup (~1 min):

- **Admin UI:** `https://<your-server-ip>:943/admin`
- **Client UI:** `https://<your-server-ip>:943/`

Default admin username:  
```
openvpn
```

Set its password:

```bash
sudo podman exec -it openvpn-as passwd openvpn
```

***

## 6. Initial setup in the Web UI

1. Accept the EULA.  
2. Configure network interface and DNS.  
3. Enable NAT for connected clients.  
4. Create users and download `.ovpn` connection profiles for clients.  

All major configuration options are available under the **Admin Web UI → Configuration** page [8][3].

***

## 7. Verifying VPN operation

From a client device:
1. Download the profile from the Client UI.  
2. Import it into the OpenVPN Connect app.  
3. Connect and check your new remote IP.

You can verify tunneling with:

```bash
curl ifconfig.me
```

Client IP should now reflect your home server’s address.

***

## 8. Maintenance commands

Stop container:

```bash
sudo podman-compose down
```

View logs:

```bash
sudo podman logs -f openvpn-as
```

Backup configuration:

```bash
sudo tar -czvf openvpn_backup_$(date +%F).tar.gz ./config
```

***

### Summary
Using both **`privileged: true`** and **`sudo`** ensures:
- Full access to `/dev/net/tun` and kernel routing functions.  
- No SELinux or seccomp restrictions on network interfaces.  
- Reliable OpenVPN operation in Podman’s rootful environment [2][6].

This configuration replicates Docker’s `--privileged` behavior and is the most stable way to run OpenVPN Access Server for personal or self‑hosted cloud VPN setups.

Citations:
[1] Restricted environments - Podman Desktop https://podman-desktop.io/docs/proxy
[2] --privileged — Podman documentation https://docs.podman.io/en/v4.3/markdown/options/privileged.html
[3] OpenVPN Access Server Complete Setup - Easy and Secure VPN! https://www.youtube.com/watch?v=S5m70wmRvgA
[4] Connect to VPN with Podman - dockerfile - Stack Overflow https://stackoverflow.com/questions/57115336/connect-to-vpn-with-podman
[5] Rootless container (podman), non-privileged openvpn client and ... https://discussion.fedoraproject.org/t/rootless-container-podman-non-privileged-openvpn-client-and-selinux/112674
[6] How to use the --privileged flag with container engines - Red Hat https://www.redhat.com/en/blog/privileged-flag-container-engines
[7] Preferred way to set up a reverse proxy web server with Podman ... https://github.com/containers/podman/discussions/23845
[8] Official Docker VPN Server with Access Server | OpenVPN https://openvpn.net/as-docs/docker.html
