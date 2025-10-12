Here is a comprehensive how-to guide for installing Nginx Proxy Manager with Portainer and setting up your first proxy host.

## How to Install Nginx Proxy Manager with Portainer and Setup Your First Host

---

## Step 1: Prerequisites

- Have a VPS or server running Linux (Ubuntu/Debian recommended).
    
- Docker and Docker Compose installed on your server.
    
- Portainer installed for easy Docker management. (Portainer UI usually accessible on port 9000)
    
- Have a domain or subdomain ready for proxy host setup.
    
- Ensure ports 80 (HTTP), 443 (HTTPS), and 81 (default NPM UI) are available or properly forwarded.
    

---

## Step 2: Install Portainer (if not installed)

1. Create a directory for Portainer and navigate into it:
    
    text
    
    `mkdir -p ~/managers/portainer && cd ~/managers/portainer`
    
2. Create a docker-compose.yml file with the following content to install Portainer with Docker socket access:
    
    text
    
    `version: "3" services:   portainer:     container_name: portainer     image: portainer/portainer-ce:latest     restart: unless-stopped     ports:       - "9000:9000"     volumes:       - /var/run/docker.sock:/var/run/docker.sock       - ./portainer_data:/data`
    
3. Run the stack:
    
    text
    
    `docker compose up -d`
    
4. Access Portainer via your server's IP on port 9000: `http://<server-ip>:9000` and complete the initial setup.
    

---

## Step 3: Install Nginx Proxy Manager via Portainer

1. Log in to Portainer UI.
    
2. Go to "Stacks" and click "Add stack" to create a new stack.
    
3. Name the stack, e.g., `nginx-proxy-manager`.
    
4. Use the following docker-compose contents for Nginx Proxy Manager:
    
    text
    
    `version: "3" services:   app:     image: 'jc21/nginx-proxy-manager:latest'     restart: unless-stopped     ports:       - "81:81"    # Admin Web UI       - "80:80"    # HTTP       - "443:443"  # HTTPS     environment:       DB_MYSQL_HOST: "db"       DB_MYSQL_PORT: 3306       DB_MYSQL_USER: "npm"       DB_MYSQL_PASSWORD: "npm_password_here"       DB_MYSQL_NAME: "npm"     volumes:       - ./data:/data       - ./letsencrypt:/etc/letsencrypt   db:     image: jc21/mariadb-aria:latest     restart: unless-stopped     environment:       MYSQL_ROOT_PASSWORD: "root_password_here"       MYSQL_DATABASE: "npm"       MYSQL_USER: "npm"       MYSQL_PASSWORD: "npm_password_here"     volumes:       - ./data/mysql:/var/lib/mysql`
    
5. Deploy the stack.
    

---

## Step 4: Access Nginx Proxy Manager UI

- Open a browser and navigate to `http://<server-ip>:81`.
    
- Log in with default credentials:
    
    - Email: `admin@example.com`
        
    - Password: `changeme`
        
- Change the password immediately after login.
    

---

## Step 5: Setup Your First Proxy Host

1. In the Nginx Proxy Manager dashboard, go to "Proxy Hosts" and click "Add Proxy Host."
    
2. Enter the domain/subdomain name you want to use for this host.
    
3. Set the Forward Hostname/IP to the internal Docker service you want to proxy (e.g., `portainer` if you want to access Portainer).
    
4. Set the Forward Port (e.g., `9000` for Portainer).
    
5. Enable "Websockets Support" if needed.
    
6. Tick "Block Common Exploits."
    
7. Switch to the SSL tab, enable SSL, and request a new Let's Encrypt certificate by providing your email.
    
8. Enable "Force SSL" and "HTTP/2 Support."
    
9. Save the proxy host.
    

---

## Step 6: Verify Your Setup

- Access your proxy host domain in the browser, e.g., `https://portainer.yourdomain.com`.
    
- You should see the proxied service (Portainer in this case) securely accessible.
    

---
Here is a quick cheatsheet for setting up a proxy host in Nginx Proxy Manager:Nginx Proxy Manager Proxy Host Setup CheatsheetGo to: Proxy Hosts → Click "Add Proxy Host"Domain Names: Enter the domain(s) (e.g., example.com, sub.example.com)Scheme: Choose HTTP or HTTPS (usually HTTP if you're proxying local services)Forward Hostname/IP: Enter the internal IP or Docker service name (e.g., 192.168.1.100 or Docker container name like portainer)Forward Port: Enter the port the service listens on (e.g., 9000 for Portainer)Options:Enable Websockets Support if neededTick Block Common Exploits for basic securityOptional: Enable access list or Advanced Custom Config if necessarySSL Tab:Enable SSLRequest a new SSL certificate using Let's Encrypt (enter your email)Check Force SSL to redirect HTTP to HTTPSEnable HTTP/2 Support for performance(Optional) Enable HSTS for security headerSaveVerify by browsing to your domain with HTTPS; the proxy should forward to the target serviceThis cheatsheet helps quickly set up proxy hosts to expose your internal services securely via Nginx Proxy Manager ���.