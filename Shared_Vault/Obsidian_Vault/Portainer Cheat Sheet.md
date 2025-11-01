Here's a **complete and comprehensive Portainer cheat sheet** based on the official documentation and community resources [1](https://docs.portainer.io/):

---

## 🧭 **Portainer Overview**

Portainer is a lightweight management UI for Docker, Docker Swarm, Kubernetes, Podman, and Azure ACI. It simplifies container management by abstracting CLI complexities.

---

## 🚀 **Installation**

### Docker (CE/BE)

```bash
docker volume create portainer_data
docker run -d -p 9443:9443 --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

### Kubernetes (via Helm)

```bash
helm repo add portainer https://portainer.github.io/k8s/
helm install portainer portainer/portainer \
  --namespace portainer --create-namespace \
  --set service.type=NodePort
```

---

## 🧱 **Core Concepts**

- **Stacks**: Group of services defined via Docker Compose or Kubernetes manifests.
- **Containers**: Individual running instances.
- **Images**: Templates used to create containers.
- **Volumes**: Persistent storage.
- **Networks**: Communication layer between containers.
- **Endpoints**: Docker/Kubernetes environments managed by Portainer.

---

## 🔐 **Access Control**

- **Users & Teams**: Assign roles and permissions.
- **RBAC (BE only)**: Fine-grained access control.
- **Registries**: Add private/public registries with credentials.

---

## 🛠️ **Common Tasks**

### Create a Container

1. Go to **Containers** → **Add Container**
2. Fill in image name, ports, volumes, etc.
3. Click **Deploy the container**

### Deploy a Stack

1. Go to **Stacks** → **Add Stack**
2. Paste Docker Compose YAML or upload file
3. Click **Deploy the stack**

### Manage Volumes

- Create: **Volumes** → **Add Volume**
- Inspect/Delete: Click volume name → Actions

### Update Portainer

```bash
docker pull portainer/portainer-ce:latest
docker stop portainer
docker rm portainer
docker run ... (same as install)
```

---

## 📊 **Monitoring & Logs**

- View container stats: **Containers** → Click container → **Stats**
- View logs: **Containers** → Click container → **Logs**

---

## 🔧 **CLI Configuration Options**

- `--admin-password`: Set admin password hash
- `--ssl`: Enable SSL
- `--host`: Specify Docker host

---

## 📡 **Edge Agent Setup**

Used for remote environments:

```bash
docker run -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /etc/hostname:/etc/hostname \
  -v /etc/localtime:/etc/localtime:ro \
  portainer/agent
```

---

## 📚 **Useful Resources**

- [Official Docs](https://docs.portainer.io/) [1](https://docs.portainer.io/)
- [GitHub Cheat Sheet](https://github.com/Pandemonium1986/cheatsheet/blob/master/Portainer.md)
- [Advanced Cheat Sheet](https://github.com/doctorfree/cheat-sheets-plus/blob/main/infra/portainer.md)

---

Would you like this cheat sheet exported as a PDF or Markdown file for easier reference?