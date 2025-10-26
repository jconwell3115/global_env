---
title: "Top 10 Automation Scripts Every Home Lab Should Have in 2025"
source: "https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/"
author:
  - "[[Brandon Lee]]"
published: 2025-10-24
created: 2025-10-24
description: "Master automation scripts for home lab setups in 2025, everything From Docker cleanup Proxmox backups, NUT server, service healing and more"
tags:
  - "clippings"
---
![10 scripts you need 2](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/10/10-Scripts-You-Need-2.png.webp)

If you want to take your home lab to a home lab 2.0, it’s all about automation. The more of your environment you can have self-manage, the more time you have to build and experiment with many other cool things. Scripts are part of the “secret sauce” of a very efficient home lab. If you are managing containers, virtual machines, or managing a Ceph cluster, there are several automation scripts for home lab to run to keep things smooth and consistent. Let’s go over ten automation scripts that every home lab should have in 2025.

## Do scripts have to be complicated?

Short answer, no they don’t! You are going to see the scripts below are very few lines of bash code for the most part. You can start out scripting by just putting the normal bash commands that you would type and enter by hand into a.sh file and executing it. It is that simple.

Now, with the help of AI, you don’t have to have any scripting experience. You can just vibe out what you want the script to do and AI will write it for you. Keep that in mind. Often our barrier to entry is our own mindset.

Now, on to the scripts!

## 1\. Docker Cleanup Script

I love running Docker containers in my [home lab](https://www.virtualizationhowto.com/home-lab/), but they create clutter on your Docker hosts. Over time, you will accumulate stale images from stopped containers, dangling volumes, and unused networks. If you are using Docker containers on multiple hosts or you have a Swarm cluster running, this unused data will add up and eat disk space quickly.

![Docker cleanup script for all your docker hosts](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%201280%20720'%3E%3C/svg%3E)

Docker cleanup script for all your docker hosts

A simple cleanup script that can reclaim tons of space might look like something like this:

```
#!/bin/bash

# Log output with timestamp
LOG_FILE="/var/log/docker-cleanup.log"
echo "=== Docker Cleanup: $(date) ===" | tee -a "$LOG_FILE"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running" | tee -a "$LOG_FILE"
    exit 1
fi

# Show disk usage before cleanup
echo "Disk usage before:" | tee -a "$LOG_FILE"
df -h / | tail -1 | tee -a "$LOG_FILE"

# Perform cleanup
echo "Running cleanup..." | tee -a "$LOG_FILE"
docker system prune -a -f --volumes 2>&1 | tee -a "$LOG_FILE"

# Show disk usage after cleanup
echo "Disk usage after:" | tee -a "$LOG_FILE"
df -h / | tail -1 | tee -a "$LOG_FILE"

echo "Cleanup complete" | tee -a "$LOG_FILE"
```

If you want a less aggressive version, you might go for something like the below that won’t remove images from stopped containers that you might want to restart later:

```
#!/bin/bash
docker system prune -f --volumes  
docker image prune -f  # Only removes dangling images
```

You can run either of these manually or set it as a cron job to execute weekly. If you’re using Ansible or GitLab pipelines (which I highly recommend), you can trigger this command before running your updates. It’s one of those small automations that keeps the “cabs running” and helps prevent a situation where you have a Docker host that has completely run out of space.

## 2\. Proxmox Backup automation

If you run [Proxmox Backup Server (PBS)](https://www.proxmox.com/en/products/proxmox-backup-server/overview) and you should if you have Proxmox, you are probably already familiar with how well it works. But, even without Proxmox [Backup Server](https://www.virtualizationhowto.com/2023/06/top-5-home-lab-server-backup-solutions/), you can use scripting to create backups. Instead of manually creating snapshots or running backup jobs in the Proxmox GUI, you can use a script to take care of this.

![Proxmox backup server](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%201215%20793'%3E%3C/svg%3E)

Proxmox backup server

With Proxmox Backup Server take a look at the following automation scripts for home lab:

```
#!/bin/bash
vms=$(qm list | awk 'NR>1 {print $1}')
for vm in $vms; do
  vzdump $vm --mode snapshot --storage pbs-backup --compress zstd
done
```

Without Proxmox Backup Server:

```
#!/bin/bash
vms=$(qm list | awk 'NR>1 {print $1}')
for vm in $vms; do
  vzdump $vm --mode snapshot --storage nfs-backups --compress zstd
done
```

## 3\. Ceph or MicroCeph health check script

If you delve into running [Ceph](https://ceph.io/en/) in Proxmox or Microceph like I have done with my Kubernetes nodes and Docker Swarm nodes, you want to be able to have a good overall view of the health of your software-defined storage. The below script checks cluster health and alerts you if there is something going on with your Ceph environment.

![Ceph health automation scripts for home lab](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%20735%20492'%3E%3C/svg%3E)

Ceph health automation scripts for home lab

This check includes the status in the alert. It adds the hostname for multi-cluster environments, and it only shows the health detail when there is a problem.

```
#!/bin/bash

HEALTH=$(ceph health)
STATUS=$(echo "$HEALTH" | awk '{print $1}')

# Show details for troubleshooting
if [ "$STATUS" != "HEALTH_OK" ]; then
    echo "=== Ceph Health Issue Detected ==="
    ceph health detail
    
    # Send alert with actual status
    curl -X POST -H "Content-Type: application/json" \
      --max-time 10 \
      -d "{\"text\":\"Ceph cluster on $(hostname) is *${STATUS}*\n\\`\\`\\`${HEALTH}\\`\\`\\`\"}" \
      https://hooks.slack.com/services/XXXX || \
      echo "ERROR: Failed to send Slack notification" >&2
    
    exit 1
fi

echo "Ceph cluster is healthy"
exit 0
```

You can tie this into Discord, Teams, or any webhook that you want to use for alerting. In MicroCeph, this can also be executed from a crontab on one node to monitor the entire cluster.

## 4\. Automated SSL certificate expiration monitoring

Even if you are using [Let’s Encrypt certificates](https://letsencrypt.org/) for your home lab (and you should be to secure services), auto-renewal can sometimes fail or something may go wrong in the process. A certificate expiration checker script can help you keep an eye on things before your services go down to the certificate errors.

![Generating lets encrypt certificates](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%202471%20768'%3E%3C/svg%3E)

Generating lets encrypt certificates

The below script helps you catch autorenewal failures before the certificate expires. You can run this daily with a CRON job or in a small Docker container.

```
#!/bin/bash

DOMAINS=("jellyfin.homelab.local" "nextcloud.homelab.local")
WEBHOOK="https://ntfy.sh/mylab"

for domain in "${DOMAINS[@]}"; do
    # Get cert expiration date
    expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | \
             openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    
    if [ -n "$expiry" ]; then
        expiry_epoch=$(date -d "$expiry" +%s)
        now_epoch=$(date +%s)
        days_left=$(( ($expiry_epoch - $now_epoch) / 86400 ))
        
        if [ $days_left -lt 7 ]; then
            curl -d "Certificate for $domain expires in $days_left days!" "$WEBHOOK"
        fi
        
        echo "$domain: $days_left days until expiration"
    else
        echo "ERROR: Could not check $domain"
    fi
done
```

## 5\. Home lab inventory script

You don’t have to have fancy enterprise software to create a very detailed inventory of your networks. All you need is [nmap installed](https://nmap.org/) and then you can run an inventory script that calls nmap to inventory your network. It will report hostnames, IP addresses, and open ports.

![Running nmap automation scripts for home lab](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%201116%20629'%3E%3C/svg%3E)

Running nmap automation scripts for home lab

You can decide how you want to handle the outp. You can output the data to a JSON, CSV file, TXT, or something else. If you use NetBox or phpIPAM, the same script can push updates directly into their APIs.

Just replace with your network range in the script.

```
#!/bin/bash

SUBNET="192.168.1.0/24"
OUTPUT="inventory_$(date +%Y%m%d).txt"

echo "Home Lab Inventory - $(date)" > "$OUTPUT"
echo "================================" >> "$OUTPUT"

nmap -sn "$SUBNET" -oG - | grep "Up" | awk '{print $2, $3}' | while read ip hostname; do
    echo "Scanning $ip ($hostname)..."
    ports=$(nmap -p 22,80,443,445,3000,8006,8080,9090 --open "$ip" | grep "^[0-9]" | awk '{print $1}')
    
    echo "$ip | $hostname | $ports" >> "$OUTPUT"
done

echo "Inventory saved to $OUTPUT"
cat "$OUTPUT"
```

## 6\. Container auto-update script

I highly recommend running something like [Watchtower](https://github.com/containrrr/watchtower) for your container updates. You can also use Portainer if run this, or [Shepherd](https://github.com/containrrr/shepherd) for Docker Swarm. However, again, you don’t have to have a specialized solution for this. You can run container updates yourself using a BASH script. Take a look at the script below.

![Watchtower docker configuration](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%20744%20415'%3E%3C/svg%3E)

Watchtower docker configuration

The below script:

- Only updates containers that have actually changed
- It cleans up old images automatically
- It can notify when updates happen
```
#!/bin/bash

# Container Auto-Update Script with Safety Checks
COMPOSE_DIR="/opt/docker/services"
LOG_FILE="/var/log/docker-updates.log"
WEBHOOK="https://ntfy.sh/homelab-updates"  # Optional notification

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

cd "$COMPOSE_DIR" || exit 1

log "Starting container update check..."

# Pull new images
docker compose pull 2>&1 | tee -a "$LOG_FILE"

# Check if any images were updated
if docker compose pull --dry-run 2>&1 | grep -q "Downloaded newer image"; then
    log "Updates found, applying changes..."
    
    # Recreate only containers with new images
    docker compose up -d 2>&1 | tee -a "$LOG_FILE"
    
    # Clean up old images to save space
    docker image prune -f >> "$LOG_FILE" 2>&1
    
    # Send notification (optional)
    curl -d "🔄 Docker containers updated on homelab" "$WEBHOOK" 2>/dev/null
    
    log "Update complete"
else
    log "No updates available"
fi

# Show what's currently running
docker compose ps >> "$LOG_FILE"
```

Run this script nightly or weekly, depending on how often your containers receive updates. It’s an easy way to stay current without manual intervention. In Docker Swarm or Portainer, you can trigger this through a webhook to ensure rolling updates happen safely.

## 7\. Snapshot cleanup script

This one is one for the VMware vSphere folks. Snapshots often get overused. While they are great to use when you need them, they are often left on indefinitely, killing performance overall. While vSphere has a lot of intelligence built in now with vCenter to schedule rolling snapshots back off, you can also schedule a script to do this for you.

```
# Remove snapshots older than 3 days
$SnapshotAge = (Get-Date).AddDays(-3)

Get-VM | Get-Snapshot | Where-Object {$_.Created -lt $SnapshotAge} | ForEach-Object {
    Write-Host "Removing snapshot: $($_.Name) on $($_.VM) (Created: $($_.Created))"
    Remove-Snapshot -Snapshot $_ -Confirm:$false
}
```

## 8\. Ansible patch management playbook

Patching multiple Linux systems doesn’t have to be a chore. You can use [Ansible](https://docs.ansible.com/) to get this automated without any issues. Even if you have only 3-4 Linux VMs, this can save you a ton of time.

![Ansible can be used for automation scripts for home lab](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%201113%20626'%3E%3C/svg%3E)

Ansible can be used for automation scripts for home lab

First a simple inventory file (something like ~/homelab/inventory.ini):

```
[webservers]
nginx01 ansible_host=192.168.1.10
nginx02 ansible_host=192.168.1.11

[databases]
postgres ansible_host=192.168.1.20

[all:vars]
ansible_user=your-user
ansible_become=yes
```

The below script will allow you to update both Debian and RHEL based systems. It checks for reboots that might be required and gives you a report of what happened with the updates. You can schedule this weekly with CRON and you’ll never have to manually connect to your boxes and run updates again!

```
---
- name: Update all systems
  hosts: all
  tasks:
    - name: Update apt packages (Debian/Ubuntu)
      apt:
        upgrade: dist
        update_cache: yes
      when: ansible_os_family == "Debian"
    
    - name: Update yum packages (RHEL/Rocky)
      yum:
        name: '*'
        state: latest
      when: ansible_os_family == "RedHat"
    
    - name: Check if reboot required
      stat:
        path: /var/run/reboot-required
      register: reboot_required
    
    - name: Notify if reboot needed
      debug:
        msg: "{{ inventory_hostname }} needs a reboot!"
      when: reboot_required.stat.exists
```

## 9\. UPS-triggered graceful shutdown script

If your home lab runs on a UPS which is a great idea to do, you can trigger automated shutdowns to prevent data corruption when a server just dies when the UPS battery is exhausted. [Network UPS Tools (NUT Server)](https://networkupstools.org/) can trigger a script to shut down your systems in the right order and help protect your data.

![Network ups tools](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/www.w3.org/2000/svg'%20viewBox='0%200%20658%20108'%3E%3C/svg%3E)

Network ups tools

First install NUT:

```
apt install nut
```

Next, is the shutdown script. You can create this and store it as something like **/usr/local/bin/ups-shutdown.sh**.

```
#!/bin/bash

LOG="/var/log/ups-shutdown.log"

log() {
    echo "[$(date)] $1" | tee -a "$LOG"
}

log "UPS battery low - initiating graceful shutdown"

# Shutdown VMs/containers first
log "Shutting down VMs..."
ssh proxmox1 "qm list | awk 'NR>1 {print \$1}' | xargs -I {} qm shutdown {}"
sleep 30

# Shutdown application servers
log "Shutting down app servers..."
ssh docker01 "shutdown -h +1"

# Wait for everything to stop
sleep 60

# Shutdown storage LAST (Ceph, NAS, etc)
log "Shutting down storage..."
ssh storage01 "shutdown -h now"

# Finally shutdown this host
log "Shutting down UPS monitoring host"
shutdown -h now
\`\`\`

**Configure NUT to call it** (\`/etc/nut/upsmon.conf\`):
\`\`\`
NOTIFYCMD /usr/local/bin/ups-shutdown.sh
NOTIFYFLAG ONBATT SYSLOG+EXEC
```

This makes sure your storage systems are the last to go down and helps you to prevent filesystem corruption. You can test the script by unplugging your UPS and then just make sure your ready for the shutdown sequence.

## 10\. Self-healing service monitor

Services can crash and containers can stop when you least expect it. A self-healing service monitor by way of a script can check if services are actually running and responsive and then it can restart them automatically to “self-heal” the issue without you having to constantly babysit and make sure things are running.

Even the most reliable services crash occasionally. Instead of manually restarting them, you can use a small self-healing script to monitor and automatically restart stopped services or containers.

```
#!/bin/bash

WEBHOOK="https://ntfy.sh/homelab-alerts"

check_and_heal() {
    local name=$1
    local check_cmd=$2
    local heal_cmd=$3
    
    if ! eval "$check_cmd" &>/dev/null; then
        echo "[$(date)] $name is down, attempting restart..."
        eval "$heal_cmd"
        sleep 5
        
        # Verify it came back up
        if eval "$check_cmd" &>/dev/null; then
            curl -d "Successfully restarted $name" "$WEBHOOK" 2>/dev/null
        else
            curl -d "Failed to restart $name - needs manual intervention!" "$WEBHOOK" 2>/dev/null
        fi
    fi
}

# Check if containers are running AND responding
check_and_heal "Nginx" \
    "curl -f http://localhost:80" \
    "docker restart nginx"

check_and_heal "Jellyfin" \
    "curl -f http://localhost:8096" \
    "docker restart jellyfin"

check_and_heal "Portainer" \
    "curl -fk https://localhost:9443" \
    "docker restart portainer"

# Check systemd services
check_and_heal "SSH" \
    "systemctl is-active sshd" \
    "systemctl restart sshd"
```

Then you can schedule it with CRON for every 5 minutes like the following:

```
*/5 * * * * /usr/local/bin/service-monitor.sh
```

The good thing about this service monitor script is that it actually makes sure the services are **responding** and not just that they are running. It will also notify if the healing fails so you know if you need to manually intervene and get things going.

## Build yourself a library of home lab scripts

I highly recommend for anyone that they create a Git repo for their scripts. Add each script as a separate file and then have a short README in markdown explaining what the script is and what it does. Version control in Git will help you keep track of any changes or improvements you want to make.

If you are running something like GitLab or Gitea you can use pipelines to automate your scripts and scheduling these to run. This is how you can evolve your [home lab setup](https://www.virtualizationhowto.com/2023/09/mini-pc-server-things-to-know-before-you-buy/) from a few basic scripts into a full DevOps playground. Over a bit of time, you will have a complete automation library that you can build upon in other projects. This helps so much with learning.

## Wrapping up

Hopefully these 10 practical automation scripts we have highlighted here will give you some ideas of just how powerful automation and scripting can be in your home lab. What I like to tell people is start small. Start with a problem, challenge, or just a manual task you want to automate and then work on a script to do it. This type of project-based learning is something I am a huge advocate of. Actually solve a problem with your learning.

What scripts are you using? Are there scripts you would like to share with the community? Please leave them in the comments with the code blocks you can post them there!