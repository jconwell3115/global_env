---
title: OpenVPN-as Quadlet
tags:
  - Self-Hosting
  - OpenVPN
  - Podman
  - Quadlet
created: 2025-11-25
published:
status: draft
---
# OpenVPN Access Server with Podman Quadlet (Rootful) — Complete Setup

------------------------------------------------------------
## 1) Create the Quadlet file

#### Path: /etc/containers/systemd/openvpn-as.container
> Rootful systemd (system scope) + host networking + NET_ADMIN + TUN device + persistence
```bash
cat << 'EOF' | sudo tee /etc/containers/systemd/openvpn-as.container
# /etc/containers/systemd/openvpn-as.container
[Unit]
Description=OpenVPN Access Server (Podman Quadlet)
Wants=network-online.target
After=network-online.target

[Container]
ContainerName=openvpn-as
# Choose your image. linuxserver/openvpn-as is popular and maintained.
# Image=lscr.io/linuxserver/openvpn-as:latest
# If you prefer the official OpenVPN Inc. image instead, use:
Image=openvpn/openvpn-as:latest

# Rootful + host net to avoid slirp quirks and preserve routing semantics.
Network=host

# Required for VPN routing + iptables operations inside the container
AddCapability=NET_ADMIN
AddCapability=NET_RAW

# Ensure the TUN device is available in the container
AddDevice=/dev/net/tun

# Persist the AS configuration and PKI
Volume=/home/rhlabs/podman/volumes/openvpn-config:/openvpn:z

# (Optional) auto-update at reboot if you want
# AutoUpdate=registry

# Environment (adjust PUID/PGID/UMASK as you like; leave root if you want fully rootful)
# If you prefer running as root inside the container, omit PUID/PGID
Environment=PUID=0
Environment=PGID=0
Environment=TZ=America/New_York

# If you need to accept EULA non-interactively with the linuxserver image:
# Environment=INTERACTIVE=false
# Environment=EULA=accept


# Open Ports
PublishPort=943:943
PublishPort=9443:9443
PublishPort=1194:1194/udp

# (Optional) if your host uses nftables backbone, you can allow legacy iptables in the container:
# Environment=OVPN_AS_USE_LEGACY_IPTABLES=1

[Service]
# Ensure the tun module exists before the container starts
ExecStartPre=/usr/sbin/modprobe tun

# Make it resilient
Restart=always
RestartSec=5s
TimeoutStartSec=0

# If your host needs IP forwarding at container start, you can uncomment:
ExecStartPre=/usr/bin/sysctl -w net.ipv4.ip_forward=1
# ExecStartPre=/usr/bin/sysctl -w net.ipv6.conf.all.forwarding=1

[Install]
WantedBy=multi-user.target
EOF
```
> Why host networking?
OpenVPN-AS manipulates routing/iptables and expects to bind its ports directly (TCP 943/9443 and UDP 1194 by default). Host net avoids slirp4netns quirks and user-defined bridge NAT differences that often break VPN routing.

------------------------------------------------------------


## 2) Prepare host directories & enable the unit

```bash
sudo mkdir -p /home/rhlabs/podman/volumes/openvpn-config
sudo chown -R root:root /home/rhlabs/podman/volumes/openvpn-config

# Reload Quadlets -> systemd units
sudo systemctl daemon-reload

# Enable at boot and start now
sudo systemctl enable openvpn-as.service
sudo systemctl start openvpn-as.service

# Check status/logs
systemctl status openvpn-as.service
journalctl -u openvpnas.service -f
```

------------------------------------------------------------


## 3) Ensure host kernel/network prerequisites

> OpenVPN-AS needs IP forwarding and will commonly rely on iptables/nftables
```bash
# Persistently enable IP forwarding (recommended for routing to work)
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-openvpn.conf
echo "net.ipv6.conf.all.forwarding=1" | sudo tee -a /etc/sysctl.d/99-openvpn.conf
sudo sysctl --system
```
> If your distribution defaults to nftables while the container expects iptables-legacy, either:
> - Install iptables-nft inside the container (most images already use it), or
> - Set OVPN_AS_USE_LEGACY_IPTABLES=1 (see commented env var) and make sure legacy backend is available on host.

------------------------------------------------------------


## 4) Ports & access

> With Network=host, ports are bound directly on the host:
> Admin UI: https://host:943/admin
> Client UI: https://host:943/
> Web services: :9443/tcp
> OpenVPN data channel (default): :1194/udp

**If your host firewall is active, allow those ports:**

```bash
# firewalld example:
sudo firewall-cmd --add-port=943/tcp --add-port=9443/tcp --add-port=1194/udp --permanent
sudo firewall-cmd --reload
```

------------------------------------------------------------


## 5) Using a custom bridge network instead (optional)

> If you must avoid host networking, create a rootful Podman network that mimics Compose behavior:
```bash
sudo podman network create \
  --driver=bridge \
  --subnet=172.28.0.0/16 \
  --gateway=172.28.0.1 \
  openvpn-net
```
> Then change the Quadlet:
```
# Replace [Container] section in Quadlet with:
cat << 'EOF'
[Container]
Image=lscr.io/linuxserver/openvpn-as:latest
Network=openvpn-net
PublishPort=943:943/tcp
PublishPort=9443:9443/tcp
PublishPort=1194:1194/udp
CapAdd=NET_ADMIN
CapAdd=NET_RAW
Device=/dev/net/tun
Volume=/srv/openvpnas/config:/config:z
Environment=PUID=0
Environment=PGID=0
Environment=TZ=America/New_York
EOF
```
> Note: You’ll still need host IP forwarding and correctly ordered firewall rules. In many environments, host networking remains simpler and more reliable for VPN routing.

```bash
# Reload and restart:
sudo systemctl daemon-reload
sudo systemctl restart openvpnas.service
```

------------------------------------------------------------


## 6) Troubleshooting checklist

1. Network mode
    * Quadlet with Network=host usually avoids slirp/bridge quirks and mimics bare-metal services.
    * If using a bridge, ensure the subnet/gateway and published ports match your Compose setup.
2. Capabilities
    * NET_ADMIN (and often NET_RAW) are required. Confirm they’re present in the Quadlet.
3. TUN device
    * Device=/dev/net/tun plus ExecStartPre=/usr/sbin/modprobe tun ensures availability.
4. IP forwarding
    * Confirm it’s active:
    * sysctl net.ipv4.ip_forward -> 1
    * sysctl net.ipv6.conf.all.forwarding -> 1
5. Firewall backend / iptables vs nft
    * Modern images use iptables-nft; some environments need legacy behavior. If rules don’t take, try OVPN_AS_USE_LEGACY_IPTABLES=1 and verify host support.
6. Logs
    * Service logs: journalctl -u openvpnas.service -f
    * Container logs/files: inside /srv/openvpnas/config/log/ (linuxserver image) or /srv/openvpnas/data/log/ (official image if you switch).

------------------------------------------------------------

## 7) Access URLs
> Admin UI: https://<host>:943/admin
> Client UI: https://<host>:943/

