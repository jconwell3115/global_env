Here’s a **complete and comprehensive Ansible Cheat Sheet** designed to help you quickly reference key concepts, commands, modules, and best practices. It’s ideal for both beginners and experienced users.

---

## 🧠 **Core Concepts**

- **Ansible**: Agentless automation tool using SSH (or WinRM for Windows).
- **Inventory**: List of hosts managed by Ansible (`/etc/ansible/hosts` or custom).
- **Playbook**: YAML file describing automation tasks.
- **Module**: Unit of work (e.g., `copy`, `yum`, `service`).
- **Task**: A single module invocation.
- **Role**: Reusable set of tasks, variables, templates, etc.
- **Facts**: System information gathered from hosts.

---

## 📁 **Directory Structure**

```bash
project/
├── inventory/
│   └── hosts.ini
├── playbooks/
│   └── site.yml
├── roles/
│   └── webserver/
│       ├── tasks/
│       ├── handlers/
│       ├── templates/
│       ├── files/
│       ├── vars/
│       └── defaults/
```

---

## ⚙️ **Common Commands**

```bash
ansible all -m ping                      # Ping all hosts
ansible web -m shell -a "uptime"        # Run shell command
ansible-playbook site.yml               # Run playbook
ansible-playbook -i inventory/hosts.ini site.yml
ansible-doc -l                          # List all modules
ansible-doc copy                        # Show module documentation
```

---

## 📜 **Playbook Structure**

```yaml
- name: Install and start Apache
  hosts: web
  become: yes
  tasks:
    - name: Install Apache
      yum:
        name: httpd
        state: present

    - name: Start Apache
      service:
        name: httpd
        state: started
```

---

## 📦 **Popular Modules**

| Module | Purpose | |------------|----------------------------------| | `ping` | Test connectivity | | `command` | Run commands (no shell features) | | `shell` | Run shell commands | | `copy` | Copy files to remote | | `template` | Deploy Jinja2 templates | | `yum` | Install packages (RHEL/CentOS) | | `apt` | Install packages (Debian/Ubuntu) | | `service` | Manage services | | `user` | Manage users | | `file` | Manage file properties | | `git` | Clone repositories |

---

## 🧩 **Variables**

```yaml
vars:
  http_port: 80

tasks:
  - name: Print port
    debug:
      msg: "Port is {{ http_port }}"
```

- **Variable sources**: `vars`, `defaults`, `group_vars`, `host_vars`, facts, extra vars.

---

## 🧪 **Conditionals & Loops**

### Conditionals

```yaml
when: ansible_os_family == "RedHat"
```

### Loops

```yaml
with_items:
  - nginx
  - apache2
```

---

## 🔁 **Handlers**

```yaml
handlers:
  - name: restart apache
    service:
      name: httpd
      state: restarted

tasks:
  - name: Update config
    copy:
      src: httpd.conf
      dest: /etc/httpd/conf/httpd.conf
    notify: restart apache
```

---

## 🔐 **Vault (Secrets Management)**

```bash
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
ansible-playbook --ask-vault-pass site.yml
```

---

## 📊 **Facts**

```yaml
- name: Show OS
  debug:
    msg: "{{ ansible_distribution }}"
```

Use `setup` module to gather facts:

```bash
ansible all -m setup
```

---

## 🧱 **Roles**

Create a role:

```bash
ansible-galaxy init myrole
```

Use in playbook:

```yaml
roles:
  - myrole
```

---

## 🌐 **Inventory Formats**

### INI

```ini
[web]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11
```

### YAML

```yaml
all:
  hosts:
    web1:
      ansible_host: 192.168.1.10
```

---

## 🧮 **Jinja2 Filters**

```yaml
{{ var | default('value') }}
{{ list | length }}
{{ dict | to_json }}
```

---

## 🧰 **Best Practices**

- Use roles for modularity.
- Keep secrets in Vault.
- Use `group_vars` and `host_vars`.
- Validate playbooks with `--check`.
- Use `tags` to run specific tasks.

---

Would you like this cheat sheet exported as a **PDF**, **Markdown file**, or **image** for easier reference?