---
title: "15 Troubleshooting Commands Every Linux Home Lab Admin Should Know"
source: "https://www.virtualizationhowto.com/2025/11/15-troubleshooting-commands-every-linux-home-lab-admin-should-know/"
author:
  - "[[Brandon Lee]]"
published: 2025-11-21
created: 2025-11-22
description: "Learn 15 Linux troubleshooting commands every home lab admin needs to diagnose system issues with tools for logs, performance, storage, & networking"
tags:
  - "clippings"
---
![Best linux troubleshooting commands](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/Best-Linux-troubleshooting-commands.png.webp)

Running your own self-hosted environment usually means you are going to be running Linux servers at some point (or you should be). [Linux](https://www.virtualizationhowto.com/2021/06/linux-devops-tools-building-linux-infrastructure-as-code-workstation/) provides one of the most robust and stable hosting platforms that you can run. However, when things break (and they will), you need to know how to troubleshoot things effectively. Thankfully, Linux has a ton of really great troubleshooting commands that every home lab admin should know. Let’s dive in and look closer at 15 commands should be on your short list.

## journalctl

The first tool on the list is **journalctl**. This is the tool you use to look at [systemd’s](https://www.virtualizationhowto.com/2025/10/top-10-automation-scripts-every-home-lab-should-have-in-2025/) journal log. When a service won’t start, it crashes, or has some type of strange behavior, journalctl is one of the first places you should look. Note the examples below.

![Journalctl linux troubleshooting command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/journalctl-linux-troubleshooting-command-1.png.webp)

Journalctl linux troubleshooting command

If you want to view the entire system log:

```
journalctl -xe
```

Also, you can view logs for a specific service:

```
journalctl -u nginx
journalctl -u ssh
journalctl -u kubelet
```

If you want to see continual updates to the log:

```
journalctl -u docker -f
```

![Journalctl linux troubleshooting command viewing docker logs](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/journalctl-linux-troubleshooting-command-viewing-docker-logs-1.png.webp)

Journalctl linux troubleshooting command viewing docker logs

Journalctl is one of my go to commands that is extremely useful on modern distros like [Ubuntu](https://www.virtualizationhowto.com/2024/04/proxmox-packer-template-for-ubuntu-24-04/), Debian, Fedora, Rocky, and even your Proxmox nodes. If you only learn one log command, learn this one and learn it well. It will come in handy often.

## systemctl

There is another tool that is often used when you need to troubleshoot services in particular. The tool is **systemctl**. With a service that refuses to start or crash for some reason

If a service is misbehaving, failing to restart, or not running on boot, systemctl shows you the truth. It also handles manual restarts for quick troubleshooting.

Check the status of any service:

```
systemctl status nginx
systemctl status pvedaemon
systemctl status docker
```

![Using systemctl to view the docker service in linux](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/using-systemctl-to-view-the-docker-service-in-linux-1.png.webp)

Using systemctl to view the docker service in linux

Start, stop, or restart the service:

```
systemctl restart nginx
systemctl start docker
systemctl stop grafana-server
```

Enable a service to auto start on boot:

```
systemctl enable prometheus
```

## top, htop, and btop

These tools are really great for seeing your resource usage in Linux, or even something like your [Proxmox host](https://www.virtualizationhowto.com/2025/11/proxmox-ve-9-1-launches-with-oci-image-support-vtpm-snapshots-and-big-sdn-upgrades/): top, htop, and btop. If you want to see resources from the command line, this is the way to do it. When you think about it, on a Linux server, you don’t have a GUI to take a look at resources, so these tools are really needed to do that.

Problems with resources can cause a lot of problems in a home lab, especially when we are dealing with overloaded hardware or trying to run a lot of different workloads on the same hardware, maybe even nested installations.

Use **top** for the built in tool that is included in most distros.

```
top
```

![Top command for linux troubleshooting](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/top-command-for-linux-troubleshooting-1.png.webp)

Top command for linux troubleshooting

If you want a better visual interface, you can use **htop**.

```
htop
```

![Htop linux troubleshooting command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/htop-linux-troubleshooting-command-1.png.webp)

Htop linux troubleshooting command

Finally, use **btop** for what is arguably the best resource dashboard in the terminal interface for seeing everything and making sense of the information it displays. However, this is one that you will need to install most likely as it isn’t included by default. On Ubuntu Server, you can use:

```
snap install btop
apt install btop
```

After installing, just type the command:

```
btop
```

Below, you can see the really nice output that you get from btop and the information it gives you.

![Btop linux troubleshooting command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/btop-linux-troubleshooting-command-1.png.webp)

Btop linux troubleshooting command

These commands reveal CPU steal time, memory exhaustion, overloaded threads, runaway processes, and load averages. If something is slow, this is where you look first.

## dmesg

The purpose of the **dmesg** command is to show kernel messages. The kernel messages log is where things like hardware issues will show up. If you want to know why a hard drive vanished from the config, or why something like a PCIe GPU didn’t initialize, why a kernel module didn’t load, this is what will help show the reason why.

![Dmesg command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/dmesg-command-1.png.webp)

Dmesg command

View all messages:

```
dmesg
```

View only error messages:

```
dmesg --level=err
```

Follow messages in real time:

```
dmesg -w
```

On Proxmox nodes, dmesg is a great tool for troubleshooting things like ZFS problems, drive failures, [GPU passthrough](https://www.virtualizationhowto.com/2023/10/proxmox-gpu-passthrough-step-by-step-guide/) issues, etc.

## lsblk

One of the common issues that comes up in Linux troubleshooting in the home lab is storage mapping issues. When you install a new NVMe drive, or pass through disks to [virtual machines](https://www.virtualizationhowto.com/2024/03/ceph-storage-best-practices-for-ultimate-performance-in-proxmox-ve/), you will need to confirm what your system sees. This is where **lsblk** comes into play.

You can use the following command to list all the block devices on your system:

```
lsblk
```

![Lsblk storage troubleshooting linux command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/lsblk-storage-troubleshooting-linux-command-1.png.webp)

Lsblk storage troubleshooting linux command

If you want to show the file system types on the mount points, use the following:

```
lsblk -f
```

Check major and minor device numbers for advanced troubleshooting as well:

```
lsblk -o NAME,MAJ:MIN,FSTYPE,SIZE,MOUNTPOINT
```

Every time you expand your storage or add new disks, this is the command to start with just for high-level checks, but just know it can also be used for deeper troubleshooting as well.

## df -h

Disk space issues are some of the more common issues with storage in the home lab or production environments. A full disk can cause major issues and cause corruption as well. One of the best go to tools to use is the **df** command.

Check overall storage use across your mount points in a human readable format:

```
df -h
```

![Df h command for diskspace troubleshooting in linux](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/df-h-command-for-diskspace-troubleshooting-in-linux-1.png.webp)

Df h command for diskspace troubleshooting in linux

This is also a handy command if you need to check the [storage inside a container](https://www.virtualizationhowto.com/2024/10/cephfs-for-docker-container-storage/), you can exec in and do that with the following:

```
docker exec -it containername df -h
```

If you need to check your ZFS pools specifically for Proxmox, use the following:

```
df -h /rpool
```

## du -sh \*

In Linux when you know the disk is full from the above “df” command, how do you know what is taking up the space? That is where the **du -sh \*** command comes into play. I can’t tell you how many times I have used the du -sh \* command or a variation to track down which folder is consuming all the disk space on a particular mount point.

The du command gives you a simple way to track down storage usage. For example, to find the largest directories in the current folder:

```
du -sh *
```

![Du sh command for disk space troubleshooting tracing in linux](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/du-sh-command-for-disk-space-troubleshooting-tracing-in-linux-1.png.webp)

Du sh command for disk space troubleshooting tracing in linux

Find large files recursively:

```
du -sh /var/* | sort -h
```

This is a command line that I have saved from using it many times. This command gives you the output in 1G format and sorts the top 20 folders from largest to smallest:

```
du -ah --block-size=1G / | sort -rh | head -n 20
```

## free -h

Don’t forget about memory pressure. [Memory pressure can cause system](https://www.virtualizationhowto.com/2025/02/use-intel-optane-ssd-cheat-your-system-memory-for-proxmox-or-vmware/) performance to come to a crawl, container failures, and extreme swap usage and disk activity. The **free** [command line](https://www.virtualizationhowto.com/2023/01/docker-rename-container-from-the-command-line-and-gui/) tool is the tool that allows you to easily see the overall memory footprint on the system and how much is “free.

![Linux command to find the free memory on your system](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/linux-command-to-find-the-free-memory-on-your-system.png.webp)

Linux command to find the free memory on your system

To get a very human readable output, use the command:

```
free -h
```

Look for things like:

- Low available memory
- High swap usage
- Buffer cache growing too large

Combine **free** with **htop** to get a full picture of RAM behavior and what is causing the memory pressure.

## ss -tulpn

I have used the netstat command for a LONG time across both Linux and Windows. However, in the Linux world, there is a newer tool that replaces the old netstat tool. This is the **ss** tool and it shows exactly what ports are listening, what processes are bound to those ports, and what connections are active.

![Ss tulpn command for troubleshooting linux networking problems](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/ss-tulpn-command-for-troubleshooting-linux-networking-problems-1.png.webp)

Ss tulpn command for troubleshooting linux networking problems

Note the following parameters you can use to get valuable output from the ss tool. To list the listening ports:

```
ss -tulpn
```

List all connections:

```
ss -tunap
```

You can search for a specific port by combining it with grep:

```
ss -tulpn | grep 8080
```

This is essential when debugging container networking, Kubernetes services, reverse proxies, or failed TCP services.

## ps

The **ps** tool

Sometimes a process gets stuck, runs away with CPU usage, or refuses to shut down. If you run **ps** by itself, it gives you all the processes running for your user. The **ps aux** command shows you **all running processes** and their resource consumption:

```
ps aux
```

![Ps aux](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/ps-aux-1.png.webp)

Ps aux

You can also filter by process:

```
ps aux | grep nginx
```

Combine it with the kill command to kill a specific process. After getting the PID from the ps command, feed this into “kill”.

```
kill -9 PID
```

Ps aux is also helpful when containers leave zombie processes or Kubernetes pods spawn unexpected child processes and you need to have visibility to these.

## nginx -t

If you run Nginx reverse proxies, Nginx Proxy Manager, or custom configs for services, configuration errors are common. Before restarting Nginx, always test the configuration.

```
nginx -t
```

If you are using Docker:

```
docker exec -it nginxcontainer nginx -t
```

![Getting nginx configuration using the nginx troubleshooting command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/getting-nginx-configuration-using-the-nginx-troubleshooting-command-1.png.webp)

Getting nginx configuration using the nginx troubleshooting command

If Nginx fails to load, your entire home lab may appear to be offline. This command prevents that.

## kubectl get events

If there is one solution that you WILL BE troubleshooting it is Kubernetes 🙂 There is a helpful command to memorize with the **kubectl** command and that is the **kubectl get events** command. K8s nodes and pods throw a lot of errors when things break. The events will tell you [things you need to know](https://www.virtualizationhowto.com/2025/09/5-things-you-should-know-about-opnsense-before-you-install-it/) when pods fail to schedule, containers crash, or services cannot mount storage.

The events log will help tell you why:

```
kubectl get events --sort-by=.metadata.creationTimestamp
```

![Kubectl get events troubleshooting command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/kubectl-get-events-troubleshooting-command-1.png.webp)

Kubectl get events troubleshooting command

Check events for a specific namespace:

```
kubectl get events -n kube-system
```

Check events for a pod:

```
kubectl describe pod podname
```

This is one of the most valuable commands for anyone running a Kubernetes cluster in the home lab

## zfs list and zpool status

The **zfs list** and **zpool status** commands are great commands to know if you use Proxmox with ZFS or you are running something like TrueNAS SCALE. If you run ZFS long enough it is likely you will at some point need to troubleshoot pool issues. These commands help you to see pool health, dataset sizes, available space, and other types of failures.

![Zfs list linux troubleshooting command](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/zfs-list-linux-troubleshooting-command-1.png.webp)

Zfs list linux troubleshooting command

List datasets and usage:

```
zfs list
```

[Check your pool health](https://www.virtualizationhowto.com/2020/02/what-is-the-vsphere-distributed-switch-health-check/):

```
zpool status
```

Zpool status troubleshooting

Look for things like:

- Degraded pools
- Failed disks
- Rebuild progress
- SMART errors bubbling up from underlying hardware

ZFS provides more detail about underlying disks than almost any other filesystem.

## pveperf

The **pveperf** tool is a really helpful tool that helps with spotting Proxmox performance issues. It is not made for synthetic testing but instead of that, it helps you spot slow storage, swap, or issues with the CPU.

```
pveperf
```

![Pveperf proxmox performance troubleshooting](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/pveperf-proxmox-performance-troubleshooting-1.png.webp)

Pveperf proxmox performance troubleshooting

You will see measurements for:

- FSYNCS per second
- L1/L2 cache performance
- Disk throughput
- Storage latency

If VMs feel sluggish out of nowhere, pveperf is a great place to begin comparing historical performance.

## smartctl

The **smartctl** tool helps you diagnose disk failures or slow performance based on SMART data. This tools helps surface SMART errors on SSDs, NVMe drives, or spinning disks before an all out failure happens.

![Smartctl troubleshooting disk failure or slow performance](https://www.virtualizationhowto.com/wp-content/smush-webp/2025/11/smartctl-troubleshooting-disk-failure-or-slow-performance-1.png.webp)

Smartctl troubleshooting disk failure or slow performance

Check smart information on a particular drive.

```
smartctl -a /dev/sda
```

Check NVMe drives:

```
smartctl -a /dev/nvme0n1
```

Run a drive self test:

```
smartctl -t short /dev/sda
```

If you experience I/O waits, slow ZFS rebuilds, or strange kernel logs, always check smartctl.

## Wrapping up

Troubleshooting in the home lab I can guarantee is one of the best “skill multipliers” that you can use to level-up your expertise. When you know how to quickly diagnose issues using the right Linux commands, you will know more than most other engineers know to be honest. Before someone can Google or pull up their favorite [AI chat interface](https://www.virtualizationhowto.com/2023/06/chatpad-ai-self-hosted-secure-chatgpt-app-in-docker/), you will be able to run 1-3 commands and be getting close to a root cause. These 15 commands are ones that will get you through almost any issue you face running Linux in a home lab or even production environment in 2025 and beyond. I use one of these at least every day when working with Linux machines, troubleshooting, configuring, etc. What about you. What commands do you include on your must-know troubleshooting commands for Linux?