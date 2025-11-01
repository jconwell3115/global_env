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
Here’s a **Docker Compose file** you can use to deploy **Nextcloud AIO as a stack in Portainer**. This setup assumes you're using ports `80` and `443`, and includes a volume for persistent configuration.

---

### 📄 `docker-compose.yml`

```yaml
version: '3.8'

services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one
    container_name: nextcloud-aio-mastercontainer
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config
    environment:
      NEXTCLOUD_ADMIN_USER: admin
      NEXTCLOUD_ADMIN_PASSWORD: your_secure_password
      NEXTCLOUD_DATADIR: /mnt/ncdata
      NEXTCLOUD_DOMAIN: yourdomain.com  # Optional, for HTTPS setup

volumes:
  nextcloud_aio_mastercontainer:
```

---

### 🧭 How to Use in Portainer

1. Go to **Portainer > Stacks**
2. Click **Add Stack**
3. Name it something like `nextcloud-aio`
4. Paste the above YAML into the **Web editor**
5. Click **Deploy the stack**

---

### 🔐 Notes

- Replace `your_secure_password` and `yourdomain.com` with your actual credentials and domain.
- Make sure ports `80` and `443` are not used by other services.
- If you're using SELinux (common on Fedora), you may need to adjust volume permissions:
    
    ```bash
    sudo chcon -Rt svirt_sandbox_file_t /var/lib/docker/volumes/nextcloud_aio_mastercontainer
    ```
    

---

Would you like me to generate this as a downloadable `docker-compose.yml` file for you?