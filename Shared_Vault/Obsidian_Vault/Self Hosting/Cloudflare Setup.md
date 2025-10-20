GitHub Copilot Chat Assistant.

Below is a concise, Fedora-specific, step‑by‑step guide to:
- add your domain to Cloudflare,
- install and authenticate cloudflared on your Fedora Budgie (Atomic) host,
- create a named tunnel,
- map multiple subdomains via ingress,
- create DNS records that route through the tunnel,
- run cloudflared as a systemd service.

Replace example.com, my-tunnel, and service ports with your real domain, tunnel name, and local service ports.

1) Add your domain to Cloudflare
- Sign in to dashboard.cloudflare.com → Sites → Add site.
- Enter your domain (example.com), choose plan, follow prompts.
- Cloudflare will provide two nameservers. At your domain registrar, update the domain’s nameservers to the ones Cloudflare gave.
- Wait for verification (minutes to a few hours).

2) Install cloudflared on Fedora
Option A — download and install the binary (recommended if no repo available):
sudo curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo chmod +x /usr/local/bin/cloudflared

Option B — install the RPM from releases (if you prefer rpm):
sudo dnf install -y https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.rpm

Verify:
cloudflared --version

3) Authenticate cloudflared with your Cloudflare account
- Run:
cloudflared tunnel login
- A browser window will open to authorize. This stores an account cert at ~/.cloudflared/cert.pem for the user who ran the command.

4) Create a named tunnel
- Create a tunnel (run as the same user who ran login):
cloudflared tunnel create my-tunnel
- Output includes the tunnel UUID and the credentials file path (e.g., /home/youruser/.cloudflared/<UUID>.json). Note the UUID and tunnel name.

5) Move credentials and create config directory (system usage)
sudo mkdir -p /etc/cloudflared
sudo cp /home/youruser/.cloudflared/<TUNNEL-UUID>.json /etc/cloudflared/
sudo cp /home/youruser/.cloudflared/cert.pem /etc/cloudflared/
sudo chown -R root:root /etc/cloudflared
sudo chmod 640 /etc/cloudflared/<TUNNEL-UUID>.json
(You can keep the files in your home dir if you prefer, but systemd setups often use /etc/cloudflared.)

6) Create ingress config mapping multiple subdomains
Create /etc/cloudflared/config.yml with content (example):
tunnel: <TUNNEL-UUID>
credentials-file: /etc/cloudflared/<TUNNEL-UUID>.json

ingress:
  - hostname: example.com
    service: http://localhost:8080
  - hostname: app.example.com
    service: http://localhost:3000
  - hostname: api.example.com
    service: http://localhost:4000
  - service: http_status:404

Notes:
- The last rule is the default fallback.
- Use http://localhost:PORT for services bound locally. You can use unix:// socket URLs in some setups.
- For wildcard hostnames (e.g., *.example.com) Cloudflare plan and settings may restrict usage.

7) Route DNS hostnames to the tunnel (creates CNAMEs)
For each hostname you want served through the tunnel:
cloudflared tunnel route dns my-tunnel example.com
cloudflared tunnel route dns my-tunnel app.example.com
cloudflared tunnel route dns my-tunnel api.example.com

What this does:
- Creates the necessary Cloudflare DNS entries (CNAME -> <TUNNEL-UUID>.cfargotunnel.com).
- For the apex, Cloudflare will handle flattening so the domain will resolve at the edge.

(If you prefer manual DNS, create CNAME records in Cloudflare: host -> <TUNNEL-UUID>.cfargotunnel.com. For apex, use Cloudflare’s CNAME flattening or let cloudflared route dns handle it.)

8) Run the tunnel interactively (test)
cloudflared tunnel run my-tunnel --config /etc/cloudflared/config.yml

Open https://example.com, https://app.example.com, etc. Requests should reach your local services through Cloudflare.

9) Install cloudflared as a systemd service (recommended)
- Create a dedicated user:
sudo useradd -r -s /usr/sbin/nologin cloudflared || true
sudo chown -R cloudflared:cloudflared /etc/cloudflared

- Create systemd template /etc/systemd/system/cloudflared@.service with:
[Unit]
Description=cloudflared tunnel %i
After=network.target

[Service]
User=cloudflared
Group=cloudflared
ExecStart=/usr/local/bin/cloudflared tunnel run %i --config /etc/cloudflared/config.yml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target

(If you installed via RPM, adjust ExecStart path to /usr/bin/cloudflared.)

- Reload systemd and enable/start:
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared@my-tunnel

- Check logs:
sudo journalctl -u cloudflared@my-tunnel -f

10) Verify DNS & connectivity
- Check CNAME created for subdomains:
dig CNAME app.example.com +short
-> should show <TUNNEL-UUID>.cfargotunnel.com

- Check HTTP(S) externally:
curl -I https://app.example.com

- In Cloudflare dashboard → DNS you should see the CNAMEs and a proxy (orange cloud) enabled.

11) Permissions & security
- Keep /etc/cloudflared/<UUID>.json readable only by the cloudflared system user:
sudo chown cloudflared:cloudflared /etc/cloudflared/<TUNNEL-UUID>.json
sudo chmod 640 /etc/cloudflared/<TUNNEL-UUID>.json

12) TLS / origin cert notes
- Cloudflare terminates TLS at the edge. If you want end-to-end encryption, either:
  - use Cloudflare Origin CA certificate on your local service (Cloudflare can create a cert tied to your domain), or
  - use a valid public cert on the origin and set Cloudflare SSL mode to Full (strict recommended).
- For most setups, Cloudflare edge TLS + HTTP on localhost is fine.

13) Managing routes and removal
- To remove a DNS route:
cloudflared tunnel route dns my-tunnel app.example.com --delete
(or remove the CNAME in the Cloudflare dashboard)

- To delete a tunnel:
cloudflared tunnel delete my-tunnel

Troubleshooting tips
- If DNS changes not visible, verify registrar nameservers are set to Cloudflare’s.
- If CNAME creation fails, ensure cloudflared was logged in with an account that has permissions for the Cloudflare zone.
- Check outbound firewall: cloudflared opens outbound connections to Cloudflare; ensure host can reach the internet (no blocking of Cloudflare IP ranges if strict).
- Check cloudflared logs for ingress mapping errors.
