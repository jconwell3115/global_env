

---

### 🖥️ **Main PC Services**

- **Fedora Budgie** (base OS)
- **Cloudflare Tunnel** → connects to Cloudflare Domain
- **Docker Management** (Portainer/Dockge)
- **Nginx Proxy Manager** → reverse proxy for services
- **Monitoring** (Beszel/Uptime Kuma)
- **Dozzle** → logs/alerts
- **Cloudflare DDNS Container**
- **OpenVPN** (Kyle/Manna)
- **Homarr** → dashboard for services
- **Home Assistant** → smart home
- **Habitica** → habit tracker
- **Meetily** → AI note transcription
- **n8n** → automation

---

### 🖥️ **2nd PC Services**

- **Nextcloud AIO** → replaces Office 365
- **Actual** → budget management
- **Paperless NGX** → document management

---

### 🌐 **Cloudflare**

- **Domain Name**
- **Tunnel**
- **DDNS**

---

### 🔄 **Interactions**

- **Nginx Proxy Manager** routes traffic to all services
- **Homarr** aggregates dashboards from all services
- **Monitoring tools** (Uptime Kuma, Dozzle) observe all services
- **Automation (n8n)** can interact with Nextcloud, Home Assistant, etc.
- **OpenVPN** provides secure remote access

---

Now I’ll generate a **visual interaction flow diagram** to represent this.

Here’s the **visual interaction flow diagram** based on your infrastructure setup:

![Infrastructure Interaction Flow Diagram](https://api.asm.skype.com/v1/objects/0-cus-d4-0d0e040be9c87f6ad5eede065140f366/views/original/generated_image.png)

You can also download the full diagram as a file here:  
📁 [Download interaction_flow_diagram.png](https://api.asm.skype.com/v1/objects/0-cus-d7-5cf115b05707f1e1679a9d65c304d997/views/original/interaction_flow_diagram)

---

### 🔍 Highlights:

- **Main PC** hosts most services including Docker, Nginx Proxy Manager, monitoring tools, and automation.
- **2nd PC** handles heavier apps like Nextcloud, Actual, and Paperless NGX.
- **Cloudflare** components (Tunnel, DDNS, Domain) manage external access.
- **Nginx Proxy Manager** routes traffic to all services.
- **Homarr** aggregates dashboards.
- **Monitoring tools** (Uptime Kuma, Dozzle) observe all services.
- **n8n** automates workflows between services.
- **OpenVPN** secures remote access to the main PC.