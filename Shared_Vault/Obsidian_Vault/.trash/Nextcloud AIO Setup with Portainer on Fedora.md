Setting up **Nextcloud AIO with Portainer on Fedora Budgie** is very similar to other Linux distributions, but there are a few Fedora-specific steps to keep in mind. Here's a tailored guide for your setup:

---

## 🧰 Prerequisites

- Fedora Budgie installed and updated
- Root or sudo access
- Internet connection
- Optional: Domain name for HTTPS

---

## ⚙️ Step-by-Step Instructions

### 1. 🔄 Update Fedora

```bash
sudo dnf update -y
```

---

### 2. 📦 Install Docker

Fedora uses `dnf` instead of `apt`.

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
```

Enable and start Docker:

```bash
sudo systemctl enable --now docker
```

---

### 3. 🛠️ Install Portainer

```bash
docker volume create portainer_data

docker run -d -p 9000:9000 -p 8000:8000 \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce
```

Access Portainer at: `http://<your-fedora-ip>:9000`

---

### 4. 📁 Create Nextcloud AIO Volume

```bash
docker volume create nextcloud_aio_mastercontainer
```

---

### 5. 🚀 Deploy Nextcloud AIO Master Container

```bash
docker run -d \
  --name nextcloud-aio-mastercontainer \
  --restart always \
  -p 80:80 -p 443:443 \
  -v nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  nextcloud/all-in-one
```

---

### 6. 🌐 Access Nextcloud Setup

- Go to `http://<your-fedora-ip>` in your browser
- Follow the Nextcloud AIO setup wizard

---

### 7. 🔒 Optional: HTTPS with Domain

If you have a domain:

- Point it to your Fedora Budgie IP
- Nextcloud AIO will automatically request a Let's Encrypt certificate during setup

---

### 🧹 Post-Setup Tips

- Use Portainer to monitor and manage containers
- Schedule backups using Portainer or external tools
- Keep Docker and containers updated

---

Would you like me to generate a **Fedora-specific automation script** or a **downloadable `.sh` file** for this setup?