---
tags:
  - Docker
  - Self-Hosting
created: 2025-09-07
---


---

## 🧱 1. **Dockerfile Best Practices for Self-Hosted Apps**

### 🔹 Use Lightweight & Secure Base Images

- Prefer `alpine`, `slim`, or official images:
    
    ```Dockerfile
    FROM nginx:alpine
    ```
    
- Avoid bloated images unless necessary (e.g., for GUI apps or full OS emulation).

### 🔹 Multi-Stage Builds

- Reduce image size and isolate build tools:
    
    ```Dockerfile
    FROM node:18 AS builder
    WORKDIR /app
    COPY . .
    RUN npm run build
    
    FROM nginx:alpine
    COPY --from=builder /app/dist /usr/share/nginx/html
    ```
    

### 🔹 Avoid Root User

- Run apps as non-root for security:
    
    ```Dockerfile
    RUN adduser -D appuser
    USER appuser
    ```
    

### 🔹 Use `.dockerignore`

- Prevent copying unnecessary files:
    
    ```
    node_modules
    .git
    *.log
    ```
    

---

## 🧩 2. **Docker Compose Best Practices for Self-Hosting**

### 🔹 Use `.env` for Configuration

- Centralize secrets and config:
    
    ```
    MYSQL_ROOT_PASSWORD=supersecret
    ```
    
    ```yaml
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
    ```
    

### 🔹 Named Volumes for Persistence

- Avoid data loss on container recreation:
    
    ```yaml
    volumes:
      - db_data:/var/lib/mysql
    ```
    

### 🔹 Health Checks

- Ensure services are running properly:
    
    ```yaml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    ```
    

### 🔹 Restart Policies

- Keep services running after crashes or reboots:
    
    ```yaml
    restart: unless-stopped
    ```
    

### 🔹 Network Isolation

- Use custom networks for security:
    
    ```yaml
    networks:
      backend:
        driver: bridge
    ```
    

---

## 🔐 3. **Security Best Practices for Self-Hosting**

### 🔹 Firewall & Port Management

- Only expose necessary ports:
    
    ```yaml
    ports:
      - "80:80"
      - "443:443"
    ```
    
- Use tools like **UFW**, **iptables**, or **Cloudflare Tunnel**.

### 🔹 TLS/SSL

- Use **Let's Encrypt** with **Traefik** or **NGINX**:
    - Traefik auto-renews certificates.
    - NGINX can use Certbot.

### 🔹 Secrets Management

- Avoid hardcoding passwords in Compose files.
- Use `.env`, Docker secrets (Swarm), or external vaults.

### 🔹 Container Hardening

- Drop capabilities:
    
    ```yaml
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE
    ```
    
- Use read-only filesystem:
    
    ```yaml
    read_only: true
    ```
    

---

## 📦 4. **Data Management & Backups**

### 🔹 Use Named Volumes

```yaml
volumes:
  db_data:
```

### 🔹 Backup Strategy

- Automate backups using:
    - **Restic**, **Duplicati**, **BorgBackup**
    - Cron jobs + `docker exec` to dump databases

### 🔹 Volume Mounts for Configs

```yaml
volumes:
  - ./nginx.conf:/etc/nginx/nginx.conf:ro
```

---

## 🛠️ 5. **Monitoring & Maintenance**

### 🔹 Logging

- Use centralized logging:
    - **Promtail + Grafana Loki**
    - **Fluentd**, **Logrotate**

### 🔹 Monitoring

- Use **Prometheus + Grafana** or **Netdata**.
- Monitor container health, CPU, memory, disk usage.

### 🔹 Updates

- Use **Watchtower** for automatic image updates:
    
    ```yaml
    watchtower:
      image: containrrr/watchtower
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
      restart: unless-stopped
    ```
    

---

## 🚀 6. **Deployment & Automation**

### 🔹 Systemd Integration

- Enable Docker Compose on boot:
    
    ```ini
    [Unit]
    Description=MyApp
    After=docker.service
    Requires=docker.service
    
    [Service]
    Restart=always
    ExecStart=/usr/local/bin/docker-compose -f /home/user/app/docker-compose.yml up
    ExecStop=/usr/local/bin/docker-compose -f /home/user/app/docker-compose.yml down
    
    [Install]
    WantedBy=multi-user.target
    ```
    

### 🔹 CI/CD for Self-Hosted Apps

- Use GitHub Actions or GitLab CI to:
    - Build and push images
    - SSH into server and deploy
    - Trigger `docker-compose pull && up -d`

---

## 🧰 7. **Recommended Tools for Self-Hosting**

| Tool | Purpose | |-----------------|----------------------------------| | **Portainer** | Web UI for Docker management | | **Watchtower** | Auto-update containers | | **Traefik** | Reverse proxy + SSL | | **Netdata** | Real-time monitoring | | **Restic** | Backup tool | | **Uptime Kuma** | Self-hosted uptime monitoring | | **Vaultwarden** | Self-hosted password manager |

---

## 📚 Resources

- Selfhosted subreddit
- Awesome-Selfhosted
- Docker Docs
- Traefik Docs
- Portainer Docs

---

Would you like this guide as a **PDF**, or a **starter template repo** with Docker Compose files for common self-hosted apps like Nextcloud, Vaultwarden, Jellyfin, etc.?