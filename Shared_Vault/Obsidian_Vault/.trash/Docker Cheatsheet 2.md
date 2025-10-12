Here's a **comprehensive Docker and Docker Compose cheatsheet** designed to help you quickly reference essential commands, concepts, and best practices.

---

## 🐳 **Docker Cheatsheet**

### 🔹 Basic Docker Commands

```bash
docker --version                 # Check Docker version
docker info                     # Display system-wide info
docker help                     # List Docker commands
```

### 🔹 Working with Images

```bash
docker build -t <name>:<tag> .  # Build image from Dockerfile
docker pull <image>:<tag>       # Pull image from registry
docker push <image>:<tag>       # Push image to registry
docker images                   # List local images
docker rmi <image>              # Remove image
```

### 🔹 Working with Containers

```bash
docker run <image>                      # Run container
docker run -it <image> bash             # Run with interactive shell
docker run -d <image>                   # Run in detached mode
docker run -p 8080:80 <image>           # Map ports
docker ps                               # List running containers
docker ps -a                            # List all containers
docker stop <container>                 # Stop container
docker start <container>                # Start container
docker restart <container>              # Restart container
docker rm <container>                   # Remove container
```

### 🔹 Container Management

```bash
docker exec -it <container> bash        # Access running container
docker logs <container>                 # View logs
docker inspect <container>              # Detailed info
docker top <container>                  # Running processes
docker stats                            # Resource usage
```

### 🔹 Volumes & Networks

```bash
docker volume create <name>             # Create volume
docker volume ls                        # List volumes
docker volume rm <name>                 # Remove volume

docker network create <name>            # Create network
docker network ls                       # List networks
docker network rm <name>                # Remove network
```

### 🔹 Dockerfile Essentials

```Dockerfile
FROM node:18
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD ["npm", "start"]
```

---

## ⚙️ **Docker Compose Cheatsheet**

### 🔹 Basic Commands

```bash
docker-compose up                      # Start services
docker-compose up -d                   # Detached mode
docker-compose down                    # Stop and remove containers
docker-compose build                   # Build services
docker-compose ps                      # List containers
docker-compose logs                    # View logs
docker-compose exec <service> bash     # Exec into service
```

### 🔹 `docker-compose.yml` Structure

```yaml
version: '3.8'

services:
  web:
    build: .
    ports:
      - "8080:80"
    volumes:
      - .:/app
    environment:
      - NODE_ENV=production
    depends_on:
      - db

  db:
    image: postgres:14
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb

volumes:
  db_data:
```

### 🔹 Useful Options

- **`build:`** Build from Dockerfile
- **`image:`** Use existing image
- **`ports:`** Map host:container ports
- **`volumes:`** Mount host/container paths
- **`environment:`** Set env variables
- **`depends_on:`** Define service dependencies
- **`networks:`** Define custom networks

---

## 🧠 Tips & Best Practices

- Use `.dockerignore` to exclude files from builds.
- Tag images with meaningful versions.
- Use multi-stage builds to optimize image size.
- Keep containers stateless; use volumes for persistence.
- Use healthchecks to monitor container health.
- Use secrets for sensitive data in production.

---
