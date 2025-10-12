Here’s a **complete and comprehensive guide** to installing **Portainer using Docker Compose on Fedora Budgie**, including **SELinux configuration** to ensure compatibility and security.

---

## 🧰 Prerequisites

- Fedora Budgie installed and updated
- Sudo/root access
- Internet connection
- Basic terminal knowledge

---

## ⚙️ Step-by-Step Installation Guide

### 1. 🔄 Update Your System

```bash
sudo dnf update -y
```

---

### 2. 📦 Install Docker

Add the Docker repository:

```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
```

Install Docker:

```bash
sudo dnf install -y docker-ce docker-ce-cli containerd.io
```

Enable and start Docker:

```bash
sudo systemctl enable --now docker
```

Verify Docker:

```bash
docker --version
```

---

### 3. 🧱 Install Docker Compose

Fedora supports Docker Compose via the CLI plugin:

```bash
sudo dnf install docker-compose
```

Verify:

```bash
docker compose version
```

---

### 4. 📁 Create Portainer Directory

```bash
mkdir ~/portainer && cd ~/portainer
```

---

### 5. 📝 Create `docker-compose.yml`

Create a file named `docker-compose.yml`:

```yaml
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce
    container_name: portainer
    restart: always
    ports:
      - "9000:9000"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
```

---

### 6. 🔐 Configure SELinux (Important for Fedora)

Fedora uses SELinux by default, which can block container access to volumes. Run:

```bash
sudo chcon -Rt svirt_sandbox_file_t /var/lib/docker/volumes/portainer_data
```

This sets the correct SELinux context so Portainer can access its data volume.

---

### 7. 🚀 Deploy Portainer

Run:

```bash
docker compose up -d
```

This will pull the image, create the volume, and start the container.

---

### 8. 🌐 Access Portainer

Open your browser and go to:

```
http://<your-fedora-ip>:9000
```

You’ll be prompted to:

- Create an admin account
- Select the Docker environment to manage

---

## 🔧 Optional: Firewall Configuration

If using `firewalld`, open the necessary ports:

```bash
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

---

## 🧹 Post-Installation Tips

- **Update Portainer**:
    
    ```bash
    docker compose pull
    docker compose up -d
    ```
    
- **Stop Portainer**:
    
    ```bash
    docker compose down
    ```
    
- **View logs**:
    
    ```bash
    docker compose logs -f
    ```
    

---

Would you like me to generate a **downloadable script** or `.yml` file to automate this setup?