### **Summary: Portainer Setup with Podman on Fedora Atomic**

1. **Install Podman (if not already installed)**
```bash
sudo rpm-ostree install podman
```

2. **Install pip (if not already installed)**
```bash
sudo rpm-ostree install python3-pip
```
- **Reboot or re-login if needed**

3. **Install podman-compose**
```bash
pip install --user podman-compose
```

4. Add `~/.local/bin` to your `PATH` if not already:
```bash
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
```

5. **Enable and start the Podman socket**
```bash
systemctl --user enable podman.socket
systemctl --user start podman.socket
```

6. **Create a project directory and podman-compose file**
```bash
mkdir ~/Containers/portainer-podman
cd ~/Containers/portainer-podman
```

7. **Create `podman-compose.yaml` with persistent and restart settings:**
```yaml
# filepath: ~/portainer-podman/podman-compose.yaml
version: "3.8"
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    privileged: true
    userns_mode: keep-id
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /run/user/${UID}/podman/podman.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
```

8. **Create the persistent volume for Portainer data**
```bash
podman volume create portainer_data
```

9. **Start Portainer using podman-compose**
```bash
podman-compose up -d
```

10. **Access Portainer**
	- Open your browser to [http://localhost:9000](vscode-file://vscode-app/app/extra/vscode/resources/app/out/vs/code/electron-browser/workbench/workbench.html) and complete the setup.

**Notes:**

- The container will restart automatically unless explicitly stopped.
- No need to install Docker; Podman and its socket are sufficient.
- If you encounter permission issues, check SELinux status and socket permissions.